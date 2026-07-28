extends RefCounted
## Ordered system: the explicit 5-state enemy machine (docs/12 §2.7 —
## idle / reposition / windup / fire / recover). All timers in ticks;
## decisions read world state only (+ rng_enemy for authored variation —
## the M5 roster draws none). Movement runs on the shared Kinematics
## slide, so enemies and players corner identically by construction.
## Fire mirrors player_fire's ShotDef volley loop through
## world.spawn_projectile; contact damage flows through THE damage path.
## No targeting state exists anywhere (CORE-35): this system reads the
## players ARRAY (GDD-16), computes an aim vector at the fire tick, and
## remembers nothing about who it aimed at.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const ActorState := preload("res://sim/actor_state.gd")
const EnemyState := preload("res://sim/enemy_state.gd")
const EnemyDef := preload("res://data/enemy_def.gd")
const PatternDef := preload("res://data/pattern_def.gd")
const SimEvents := preload("res://sim/events.gd")
const Kinematics := preload("res://sim/systems/kinematics.gd")
const Damage := preload("res://sim/systems/damage.gd")

## Damage-source pattern id for body contact (namespace: pattern_def.gd).
const PATTERN_CONTACT := -3
## Windup telegraph ring reaches this far beyond the body (presentation
## sizing; the danger is the SHOT, telegraphed by the timing contract).
const WINDUP_RING_EXTRA := 0.25


static func run(world: RefCounted) -> void:
	var defs: Array = world.enemy_defs
	var t: int = world.tick
	var dt: float = world.DT
	var grid: RefCounted = world.bitgrid
	var players: Array = world.players
	for e: RefCounted in world.enemies:
		# Unconditional: the view interpolates every enemy every tick (§2.9).
		e.prev_pos = e.pos
		# Serialized applied velocity (SERIAL 10): zero unless _move runs
		# this tick — WINDUP/FIRE/RECOVER stand still and read as such.
		e.vel = Vector2.ZERO
		var def_index: int = e.def_index
		if def_index < 0 or e.hp <= 0:
			continue  # inert stand-in, or killed this tick awaiting sweep
		var def: Resource = defs[def_index]

		# Nearest living player: linear scan, first-wins ties (stable §2.4).
		var target: RefCounted = null
		var best := INF
		for p: RefCounted in players:
			if p.dead:
				continue
			var ppos: Vector2 = p.pos
			var d2: float = e.pos.distance_squared_to(ppos)
			if d2 < best:
				best = d2
				target = p
		if target == null:
			e.ai_state = EnemyState.AIState.IDLE
			continue
		var tpos: Vector2 = target.pos
		var dist := sqrt(best)

		# Contact damage: a body-touch attack on its own cooldown, state-free
		# (a Rusher pressed into you mid-recover still hurts).
		var contact := int(def.contact_damage)
		if contact > 0 and t >= e.next_contact_tick:
			var rr: float = e.radius + target.radius
			if best < rr * rr:
				Damage.apply(world, target, contact, PATTERN_CONTACT)
				e.next_contact_tick = t + int(def.contact_cooldown_ticks)

		match e.ai_state:
			EnemyState.AIState.IDLE:
				if dist <= float(def.aggro_range):
					e.ai_state = EnemyState.AIState.REPOSITION
			EnemyState.AIState.REPOSITION:
				_move(grid, e, def, tpos, dist, dt)
				var slot := _ready_slot(e, def, t, dist)
				if slot >= 0:
					var es: Resource = def.emitters[slot]
					e.ai_state = EnemyState.AIState.WINDUP
					e.winding_slot = slot
					e.state_until = t + int(es.telegraph_ticks)
					var pattern: Resource = es.pattern
					(
						world
						. events
						. append(
							{
								"type": SimEvents.Type.TELEGRAPH_STARTED,
								"tick": t,
								"id": e.id,
								"pos": e.pos,
								"radius": e.radius + WINDUP_RING_EXTRA,
								"faction": ActorState.FACTION_HOSTILE,
								"arm_at_tick": e.state_until,
								"pattern": int(pattern.pattern_id),
							}
						)
					)
			EnemyState.AIState.WINDUP:
				if t >= e.state_until:
					e.ai_state = EnemyState.AIState.FIRE
					_fire(world, e, def, target, t)
			EnemyState.AIState.FIRE:
				# The volley left on the WINDUP->FIRE transition tick; FIRE
				# persists one observable tick (explicit 5-state contract).
				e.ai_state = EnemyState.AIState.RECOVER
			EnemyState.AIState.RECOVER:
				if t >= e.state_until:
					e.ai_state = EnemyState.AIState.REPOSITION


## Movement policies (§2.7). WINDUP/FIRE/RECOVER stand still — telegraphs
## stay readable where they started (Law 4 honesty).
static func _move(
	grid: RefCounted, e: RefCounted, def: Resource, tpos: Vector2, dist: float, dt: float
) -> void:
	if dist < 0.0001:
		return
	var toward: Vector2 = (tpos - e.pos) / dist
	var dir := Vector2.ZERO
	match int(def.movement_policy):
		EnemyDef.MovementPolicy.CHASER:
			dir = toward
		EnemyDef.MovementPolicy.KEEP_RANGE:
			if dist < float(def.range_min):
				dir = -toward
			elif dist > float(def.range_max):
				dir = toward
		EnemyDef.MovementPolicy.FLANKER:
			# Orbit-in (M6 Leadshot, §2.7): spiral toward the band, then
			# circle-strafe inside it — never a straight radial approach.
			# Chirality from id parity: authored variation, zero RNG,
			# stable across serialization (id is serialized state).
			var tangent := Vector2(-toward.y, toward.x)
			if e.id % 2 == 1:
				tangent = -tangent
			if dist > float(def.range_max):
				dir = (toward + tangent).normalized()
			elif dist < float(def.range_min):
				dir = (tangent - toward).normalized()
			else:
				dir = tangent
		_:
			# ANCHOR holds ground; ORBIT lands with a roster row that
			# needs it and anchors until then (enemy_def.gd note).
			dir = Vector2.ZERO
	if dir == Vector2.ZERO:
		return
	var before: Vector2 = e.pos
	var step: Vector2 = dir * float(def.move_speed) * dt
	e.pos = Kinematics.move_circle(grid, e.pos, e.radius, step)
	e.vel = (e.pos - before) / dt


## First emitter slot whose cooldown gate is open (windup may begin
## telegraph_ticks before the fire gate: cooldown is fire-to-fire) and
## whose trigger range contains the nearest player. -1 = none.
static func _ready_slot(e: RefCounted, def: Resource, t: int, dist: float) -> int:
	var emitters: Array = def.emitters
	for k in emitters.size():
		var es: Resource = emitters[k]
		if t < e.cooldowns[k] - int(es.telegraph_ticks):
			continue
		if dist <= float(es.trigger_range):
			return k
	return -1


## Fire the winding slot: compute the aim vector per the pattern's aim
## mode (CURRENT = nearest player's position at the fire tick; INTERCEPT
## = closed-form lead on the target's serialized vel — M6 Leadshot),
## spawn the authored volley, close the cooldown gate, enter recovery.
static func _fire(
	world: RefCounted, e: RefCounted, def: Resource, target: RefCounted, t: int
) -> void:
	var es: Resource = def.emitters[e.winding_slot]
	var pattern: Resource = es.pattern
	var tpos: Vector2 = target.pos
	var aim: Vector2 = tpos - e.pos
	if int(pattern.aim_mode) == PatternDef.AimMode.INTERCEPT and not pattern.shots.is_empty():
		var tvel: Vector2 = target.vel
		var shot0: Resource = pattern.shots[0]
		aim = _intercept_aim(e.pos, tpos, tvel, float(shot0.speed))
	aim = aim.normalized() if aim.length_squared() > 0.0001 else Vector2.RIGHT
	(
		world
		. events
		. append(
			{
				"type": SimEvents.Type.ATTACK_STARTED,
				"tick": t,
				"enemy": e.id,
				"def_index": e.def_index,
				"pattern": int(pattern.pattern_id),
				"pos": e.pos,
				"aim": aim,
			}
		)
	)
	var shots: Array = pattern.shots
	for si in shots.size():
		var shot: Resource = shots[si]
		var dir := aim.rotated(deg_to_rad(float(shot.angle_offset_deg)))
		world.spawn_projectile(
			e.pos + dir * float(shot.spawn_offset),
			dir * float(shot.speed),
			float(shot.radius),
			int(shot.ttl_ticks),
			ActorState.FACTION_HOSTILE,
			int(shot.damage),
			int(pattern.pattern_id),
			int(shot.program),
			float(shot.prog_a),
			float(shot.prog_b),
			float(shot.prog_c),
			int(shot.max_passes)
		)
	e.cooldowns[e.winding_slot] = t + int(es.cooldown_ticks)
	e.state_until = t + int(es.recover_ticks)
	e.winding_slot = -1


## Closed-form intercept (M6, CORE-32-deterministic): solve
## |d + v*t| = s*t for the earliest positive t and aim at the future
## point. Reads the target's serialized vel — NEVER prev_pos (that is
## presentation-only). Falls back to the current position when no
## forward solution exists (target at or beyond shot speed). Returns an
## UNnormalized aim vector; the caller normalizes.
static func _intercept_aim(
	origin: Vector2, tpos: Vector2, tvel: Vector2, shot_speed: float
) -> Vector2:
	var d := tpos - origin
	var a := tvel.dot(tvel) - shot_speed * shot_speed
	var b := 2.0 * d.dot(tvel)
	var c := d.dot(d)
	var t_hit := -1.0
	if absf(a) < 0.0001:
		if absf(b) > 0.0001:
			t_hit = -c / b
	else:
		var disc := b * b - 4.0 * a * c
		if disc >= 0.0:
			var sq := sqrt(disc)
			var t1 := (-b - sq) / (2.0 * a)
			var t2 := (-b + sq) / (2.0 * a)
			var lo := minf(t1, t2)
			t_hit = lo if lo > 0.0 else maxf(t1, t2)
	if t_hit <= 0.0:
		return d
	return d + tvel * t_hit
