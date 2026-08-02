extends RefCounted
## Ordered system: projectile motion programs + ttl + terrain collision +
## hit detection, resolving through THE damage path (sim/systems/damage.gd)
## (docs/12 §2.1/§2.3/§2.6). Iteration is slot-ascending and
## actor-array-ordered — stable order, never dictionary-order (§2.4).
## Pure overlap = hit; no rolls anywhere (CORE-31).
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
const Damage := preload("res://sim/systems/damage.gd")
const RiftStep := preload("res://sim/systems/rift_step.gd")

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
	# sl-0078 projectile coherence: shots collide with the SAME terrain
	# truth the player walks (walk_grid + art-matched prop discs) — one
	# truth for walking and shooting, or shots die on invisible cell
	# corners exactly where the player now threads.
	var grid: RefCounted = world.walk_grid
	var discs: Dictionary = world.prop_discs
	var players: Array = world.players
	var enemies: Array = world.enemies
	var events: Array[Dictionary] = world.events
	var capacity: int = pool.CAPACITY
	# sl-0115: in a rift arena HOSTILE shots bend slightly with the
	# current (×0.15) — a per-tick displacement on top of the pure
	# motion program (velocity stays program-owned; DodgeBot's
	# projection integrates the same closed form). Friendly bolts fly
	# true: the player's aim is never perturbed (CORE-32).
	var rift_pull_step := Vector2.ZERO
	var rift_world: bool = world.rift_pull != null
	if rift_world:
		rift_pull_step = (RiftStep.pull_vec(world, t) * float(world.rift_pull.bullet_mult) * dt)

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
		if rift_world and fac[s] == ActorState.FACTION_HOSTILE:
			x += rift_pull_step.x
			y += rift_pull_step.y
		px[s] = x
		py[s] = y
		var r := rad[s]

		# Terrain (§2.3): projectiles collide predictably with visible
		# solid tiles; out-of-world is solid, so nothing escapes the arena.
		# Prop discs share the walk truth (sl-0078 coherence amendment).
		var cell := _terrain_cell(grid, x, y, r)
		if cell < 0:
			cell = _terrain_disc(discs, x, y, r)
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
				if a.dead:
					continue
				# sl-0115 hit grace: in a rift arena a just-hit (or
				# just-snapped) line ignores bullets for the grace
				# window — the shot passes through, prototype-exact.
				# Friendly targets only; the drains never pause.
				if (
					rift_world
					and a.faction == ActorState.FACTION_FRIENDLY
					and t < a.line_iframe_until
				):
					continue
				var apos: Vector2 = a.pos
				var ddx := x - apos.x
				var ddy := y - apos.y
				var rr: float = r + a.radius
				if ddx * ddx + ddy * ddy < rr * rr:
					Damage.apply(world, a, dmg[s], pat[s], s)
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
				world, s, pat[s], targets, x, y, r, dmg[s], mp[s], reg_id, reg_pass, reg_count
			)

	# Death sweep — the resolution path's tail: emit kills, then compact.
	# Player death handling (recap, respawn) is M4; players are never
	# removed here.
	Damage.sweep_dead_enemies(world)


## Pierce path (§2.6): damage each overlapped target once per contact
## entry, at most max_passes per target, through the 8-slot registry.
## Registry full ⇒ unregistered targets take no damage (DamageBlocked).
## The projectile never despawns on hits.
static func _step_pierce(
	world: RefCounted,
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
	var events: Array[Dictionary] = world.events
	var t: int = world.tick
	var base := s * REG_SLOTS
	var overlapped: Array[int] = []
	for a: RefCounted in targets:
		if a.dead:
			continue
		# sl-0115 hit grace (rift arenas, friendly targets) — the same
		# skip as the non-pierce path, one rule everywhere.
		if (
			world.rift_pull != null
			and a.faction == ActorState.FACTION_FRIENDLY
			and t < a.line_iframe_until
		):
			continue
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
				Damage.apply(world, a, damage_amt, pattern, s)
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
			Damage.apply(world, a, damage_amt, pattern, s)
	# Contact bits: clear for registry entries not overlapped this tick, so
	# the next overlap counts as a new pass.
	for k in reg_count[s]:
		if not overlapped.has(reg_id[base + k]):
			reg_pass[base + k] = reg_pass[base + k] & 0x7F


## Circle-vs-prop-disc over the 3x3 cell neighborhood (sl-0078): the
## same encoded owner cell as a tile hit, or -1. Fixed y-then-x cell
## order + fixed per-cell array order — deterministic.
static func _terrain_disc(discs: Dictionary, x: float, y: float, r: float) -> int:
	if discs.is_empty():
		return -1
	var ccx := int(floorf(x))
	var ccy := int(floorf(y))
	for cy in range(ccy - 1, ccy + 2):
		for cx in range(ccx - 1, ccx + 2):
			var arr: Array = discs.get(Vector2i(cx, cy), [])
			for dsc: Vector3 in arr:
				var ddx := x - dsc.x
				var ddy := y - dsc.y
				var rr := r + dsc.z
				if ddx * ddx + ddy * ddy < rr * rr:
					return (cx + 32768) + (cy + 32768) * 65536
	return -1


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
