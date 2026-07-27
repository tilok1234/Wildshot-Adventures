extends RefCounted
## Ordered system: the M4 debug hostile emitter (docs/12 §4 M4) — a fixed
## turret that telegraphs, then fires an aimed radial volley, so the
## death recap is testable before real enemies exist. Aiming at the
## player list is legitimate ENEMY behavior (§2.7 reads world state);
## the volley itself is deterministic — no RNG. Hard-coded shape; real
## PatternDef resources replace this at M5. Pattern id 100.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const ActorState := preload("res://sim/actor_state.gd")
const SimEvents := preload("res://sim/events.gd")

const PATTERN_ID := 100
const TELEGRAPH_TICKS := 30
const VOLLEY := 8
const SHOT_SPEED := 6.0
const SHOT_RADIUS := 0.18
const SHOT_TTL := 90


static func run(world: RefCounted) -> void:
	if not world.emitter_on:
		return
	var t: int = world.tick
	if t == world.emitter_next_fire - TELEGRAPH_TICKS:
		(
			world
			. events
			. append(
				{
					"type": SimEvents.Type.TELEGRAPH_STARTED,
					"tick": t,
					"id": -100,
					"pos": world.emitter_pos,
					"radius": 0.6,
					"faction": ActorState.FACTION_HOSTILE,
					"arm_at_tick": world.emitter_next_fire,
					"pattern": PATTERN_ID,
				}
			)
		)
	if t < world.emitter_next_fire:
		return
	world.emitter_next_fire = t + world.emitter_cadence
	# Aimed ring: first shot toward players[0], rest fanned evenly.
	var aim := Vector2.RIGHT
	if not world.players.is_empty():
		var to_player: Vector2 = world.players[0].pos - world.emitter_pos
		if to_player.length_squared() > 0.0001:
			aim = to_player.normalized()
	(
		world
		. events
		. append(
			{
				"type": SimEvents.Type.ATTACK_STARTED,
				"tick": t,
				"player": -100,
				"pattern": PATTERN_ID,
				"pos": world.emitter_pos,
				"aim": aim,
			}
		)
	)
	for i in VOLLEY:
		var dir := aim.rotated(TAU * i / VOLLEY)
		world.spawn_projectile(
			world.emitter_pos,
			dir * SHOT_SPEED,
			SHOT_RADIUS,
			SHOT_TTL,
			ActorState.FACTION_HOSTILE,
			world.emitter_damage,
			PATTERN_ID
		)
