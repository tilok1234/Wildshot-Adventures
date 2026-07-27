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
					_fire(world, e, def, tpos, t)
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
		_:
			# ANCHOR holds ground; ORBIT/FLANKER land with their M6 roster
			# rows and anchor until then (enemy_def.gd note).
			dir = Vector2.ZERO
	if dir == Vector2.ZERO:
		return
	var step: Vector2 = dir * float(def.move_speed) * dt
	e.pos = Kinematics.move_circle(grid, e.pos, e.radius, step)


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


## Fire the winding slot: aim at the nearest player's CURRENT position
## (aimed, not predictive — Leadshot's intercept is an M6 aim mode), spawn
## the authored volley, close the cooldown gate, enter recovery.
static func _fire(world: RefCounted, e: RefCounted, def: Resource, tpos: Vector2, t: int) -> void:
	var es: Resource = def.emitters[e.winding_slot]
	var pattern: Resource = es.pattern
	var aim: Vector2 = tpos - e.pos
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
