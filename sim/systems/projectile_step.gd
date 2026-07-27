extends RefCounted
## Ordered system: projectile motion programs + ttl + terrain collision +
## the ONE damage-resolution path (docs/12 §2.1/§2.3/§2.6). Iteration is
## slot-ascending and actor-array-ordered — stable order, never
## dictionary-order (§2.4). Pure overlap = hit; no rolls anywhere (CORE-31).
##
## Motion programs are pure functions of ticks-since-spawn and authored
## params — never of entity positions (CORE-32; the dodge bot's closed-form
## projection depends on this). Terrain: circle-vs-bitgrid at the new
## position — per-tick travel (≤14 t/s = 0.234 t) plus radius stays under
## one tile, so no swept test is needed to prevent tunneling. Pierce
## weapons damage through the hit registry: one pass per contact ENTRY
## (the in-contact bit), at most max_passes per target, deterministic
## registry_full overflow (§2.6).
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const ActorState := preload("res://sim/actor_state.gd")
const SimEvents := preload("res://sim/events.gd")
const ProjectilePool := preload("res://sim/projectile_pool.gd")

const REG_SLOTS := ProjectilePool.REG_SLOTS


static func run(world: RefCounted) -> void:
	var pool: RefCounted = world.projectiles
	var dt: float = world.DT
	var t: int = world.tick
	# Snapshot prev positions for view interpolation (§2.9); assignment
	# shares storage in 4.6, so a real copy needs duplicate().
	pool.prev_x = pool.pos_x.duplicate()
	pool.prev_y = pool.pos_y.duplicate()
	var px: PackedFloat32Array = pool.pos_x
	var py: PackedFloat32Array = pool.pos_y
	var vx: PackedFloat32Array = pool.vel_x
	var vy: PackedFloat32Array = pool.vel_y
	var dx_: PackedFloat32Array = pool.dir_x
	var dy_: PackedFloat32Array = pool.dir_y
	var rad: PackedFloat32Array = pool.radius
	var ttl: PackedInt32Array = pool.ttl
	var fac: PackedByteArray = pool.faction
	var act: PackedByteArray = pool.active
	var dmg: PackedInt32Array = pool.damage
	var pat: PackedInt32Array = pool.pattern_id
	var prog: PackedByteArray = pool.program
	var pa: PackedFloat32Array = pool.prog_a
	var pb: PackedFloat32Array = pool.prog_b
	var pc: PackedFloat32Array = pool.prog_c
	var st: PackedInt32Array = pool.spawn_tick
	var mp: PackedByteArray = pool.max_passes
	var reg_id: PackedInt64Array = pool.reg_id
	var reg_pass: PackedByteArray = pool.reg_pass
	var reg_count: PackedByteArray = pool.reg_count
	var grid: RefCounted = world.bitgrid
	var players: Array = world.players
	var enemies: Array = world.enemies
	var events: Array[Dictionary] = world.events
	var capacity: int = pool.CAPACITY

	for s in capacity:
		if act[s] == 0:
			continue
		var life: int = ttl[s] - 1
		if life <= 0:
			pool.despawn(s)
			(
				events
				. append(
					{
						"type": SimEvents.Type.PROJECTILE_DESPAWNED,
						"tick": t,
						"slot": s,
						"reason": SimEvents.DespawnReason.TTL,
					}
				)
			)
			continue
		ttl[s] = life

		# Motion program: velocity from age + params only.
		var age := float(t - st[s])
		match prog[s]:
			ProjectilePool.Program.DECELERATE:
				var speed := maxf(0.0, pa[s] - pb[s] * age * dt)
				vx[s] = dx_[s] * speed
				vy[s] = dy_[s] * speed
			ProjectilePool.Program.SINE:
				# forward pa, sideways amplitude pb, angular freq pc (rad/s)
				var sway := pb[s] * sin(age * dt * pc[s])
				vx[s] = dx_[s] * pa[s] + -dy_[s] * sway
				vy[s] = dy_[s] * pa[s] + dx_[s] * sway
			ProjectilePool.Program.BOOMERANG:
				# out for pa ticks at pb t/s, then home at pc t/s (CORE-32:
				# returns along its axis, never toward any entity)
				if age < pa[s]:
					vx[s] = dx_[s] * pb[s]
					vy[s] = dy_[s] * pb[s]
				else:
					vx[s] = -dx_[s] * pc[s]
					vy[s] = -dy_[s] * pc[s]

		var x := px[s] + vx[s] * dt
		var y := py[s] + vy[s] * dt
		px[s] = x
		py[s] = y
		var r := rad[s]

		# Terrain (§2.3): projectiles collide predictably with visible
		# solid tiles; out-of-world is solid, so nothing escapes the arena.
		var cell := _terrain_cell(grid, x, y, r)
		if cell >= 0:
			pool.despawn(s)
			(
				events
				. append(
					{
						"type": SimEvents.Type.PROJECTILE_DESPAWNED,
						"tick": t,
						"slot": s,
						"reason": SimEvents.DespawnReason.TERRAIN,
						"cell": Vector2i(cell % 65536 - 32768, cell / 65536 - 32768),
						"pos": Vector2(x, y),
						"pattern": pat[s],
					}
				)
			)
			continue

		var targets: Array = players if fac[s] == ActorState.FACTION_HOSTILE else enemies
		if mp[s] == 0:
			# Non-pierce: first overlap damages and despawns.
			for a: RefCounted in targets:
				var apos: Vector2 = a.pos
				var ddx := x - apos.x
				var ddy := y - apos.y
				var rr: float = r + a.radius
				if ddx * ddx + ddy * ddy < rr * rr:
					_apply_damage(events, t, s, pat[s], a, dmg[s])
					pool.despawn(s)
					(
						events
						. append(
							{
								"type": SimEvents.Type.PROJECTILE_DESPAWNED,
								"tick": t,
								"slot": s,
								"reason": SimEvents.DespawnReason.HIT,
							}
						)
					)
					break
		else:
			_step_pierce(
				events, t, s, pat[s], targets, x, y, r, dmg[s], mp[s], reg_id, reg_pass, reg_count
			)

	# Death sweep — the resolution path's tail: emit kills, then compact.
	# Player death handling (recap, respawn) is M4; players are never
	# removed here.
	var any_dead := false
	for e: RefCounted in enemies:
		if e.hp <= 0:
			any_dead = true
			events.append({"type": SimEvents.Type.ENTITY_KILLED, "tick": t, "id": e.id})
	if any_dead:
		world.enemies = enemies.filter(func(e: RefCounted) -> bool: return e.hp > 0)


## Pierce path (§2.6): damage each overlapped target once per contact
## entry, at most max_passes per target, through the 8-slot registry.
## Registry full ⇒ unregistered targets take no damage (DamageBlocked).
## The projectile never despawns on hits.
static func _step_pierce(
	events: Array[Dictionary],
	t: int,
	s: int,
	pattern: int,
	targets: Array,
	x: float,
	y: float,
	r: float,
	damage_amt: int,
	passes_max: int,
	reg_id: PackedInt64Array,
	reg_pass: PackedByteArray,
	reg_count: PackedByteArray,
) -> void:
	var base := s * REG_SLOTS
	var overlapped: Array[int] = []
	for a: RefCounted in targets:
		var apos: Vector2 = a.pos
		var ddx := x - apos.x
		var ddy := y - apos.y
		var rr: float = r + a.radius
		if ddx * ddx + ddy * ddy >= rr * rr:
			continue
		overlapped.append(a.id)
		var found := -1
		for k in reg_count[s]:
			if reg_id[base + k] == a.id:
				found = k
				break
		if found >= 0:
			var entry := reg_pass[base + found]
			var passes := entry & 0x7F
			var was_contact := (entry & 0x80) != 0
			if not was_contact and passes < passes_max:
				passes += 1
				_apply_damage(events, t, s, pattern, a, damage_amt)
			reg_pass[base + found] = 0x80 | passes
		elif reg_count[s] >= REG_SLOTS:
			(
				events
				. append(
					{
						"type": SimEvents.Type.DAMAGE_BLOCKED,
						"tick": t,
						"slot": s,
						"target": a.id,
						"reason": SimEvents.BlockReason.REGISTRY_FULL,
					}
				)
			)
		else:
			var k := int(reg_count[s])
			reg_id[base + k] = a.id
			reg_pass[base + k] = 0x80 | 1
			reg_count[s] = k + 1
			_apply_damage(events, t, s, pattern, a, damage_amt)
	# Contact bits: clear for registry entries not overlapped this tick, so
	# the next overlap counts as a new pass.
	for k in reg_count[s]:
		if not overlapped.has(reg_id[base + k]):
			reg_pass[base + k] = reg_pass[base + k] & 0x7F


static func _apply_damage(
	events: Array[Dictionary], t: int, slot: int, pattern: int, a: RefCounted, amount: int
) -> void:
	a.hp -= amount
	(
		events
		. append(
			{
				"type": SimEvents.Type.HIT_LANDED,
				"tick": t,
				"slot": slot,
				"target": a.id,
				"damage": amount,
				"pattern": pattern,
			}
		)
	)
	(
		events
		. append(
			{
				"type": SimEvents.Type.DAMAGE_APPLIED,
				"tick": t,
				"target": a.id,
				"amount": amount,
				"hp": a.hp,
				"pattern": pattern,
			}
		)
	)


## Circle-vs-solid-tiles over the cells the circle's AABB overlaps, using
## the closest-point test (a grazing corner the rounded edge misses is not
## a hit). Returns an encoded cell (x+32768) + (y+32768)*65536, or -1.
static func _terrain_cell(grid: RefCounted, x: float, y: float, r: float) -> int:
	var tx0 := int(floorf(x - r))
	var tx1 := int(floorf(x + r))
	var ty0 := int(floorf(y - r))
	var ty1 := int(floorf(y + r))
	for tyy in range(ty0, ty1 + 1):
		for txx in range(tx0, tx1 + 1):
			if not grid.is_solid(txx, tyy):
				continue
			var qx := clampf(x, float(txx), float(txx) + 1.0)
			var qy := clampf(y, float(tyy), float(tyy) + 1.0)
			var ddx := x - qx
			var ddy := y - qy
			if ddx * ddx + ddy * ddy < r * r:
				return (txx + 32768) + (tyy + 32768) * 65536
	return -1
