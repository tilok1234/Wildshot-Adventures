extends RefCounted
## Ordered system: the player fire path (docs/12 §2.4/§2.8, CORE-32).
## Tap fires once, hold fires at cadence, autofire is a SIM-SIDE latch
## toggled by the frame's toggle edge — all three unify on one cadence
## gate, and autofire follows current free aim (including into empty
## space) because this system reads ONLY the frame's aim channel. No
## enemy awareness is possible here by construction: this module sees no
## entity lists. THE FIRE PATH CALLS NO RNG — spawn position, angle, and
## formation are a pure function of (aim vector, player sim position,
## weapon resource, volley index, tick). Firing writes no movement state
## of any kind (CORE-32 independence), and ordinary attacks consume no
## resource, ever.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const ActorState := preload("res://sim/actor_state.gd")
const SimEvents := preload("res://sim/events.gd")
const Progress := preload("res://sim/systems/progress.gd")

## Tap buffer: a tap that lands during cooldown fires when the gate opens
## if it was held within this many ticks (~67 ms) — without it, taps mid-
## cooldown are silently eaten, which reads as unresponsive firing. Still
## strictly cadence-gated: one volley per gate opening, never early.
const TAP_BUFFER_TICKS := 4


static func run(world: RefCounted) -> void:
	var frames: Array = world.current_frames
	var weapons: Array = world.weapon_frames
	for i in world.players.size():
		if i >= frames.size() or frames[i] == null:
			continue
		var p: RefCounted = world.players[i]
		if p.dead:
			continue
		var frame: RefCounted = frames[i]
		if frame.autofire_toggle_edge:
			p.autofire_on = not p.autofire_on
		if frame.weapon_select > 0 and frame.weapon_select <= weapons.size():
			# sl-0115 rod gating: in a rift arena the loadout is the
			# full rod ladder and starhook LEVEL gates use — a select
			# of a locked rod is refused (kept current), so bot and
			# replay streams stay deterministic whatever they emit.
			var unlocks: PackedInt32Array = world.rift_rod_unlocks
			var wi: int = frame.weapon_select - 1
			if wi >= unlocks.size() or p.level >= unlocks[wi]:
				p.equipped_weapon = wi
		if weapons.is_empty():
			continue
		if frame.fire_held:
			p.last_fire_held_tick = world.tick
		var buffered: bool = world.tick - p.last_fire_held_tick <= TAP_BUFFER_TICKS
		if not (frame.fire_held or p.autofire_on or buffered):
			continue
		if world.tick < p.next_fire_tick:
			continue
		var wf: Resource = weapons[p.equipped_weapon]
		var aim: Vector2 = frame.aim_vector()
		if aim == Vector2.ZERO:
			aim = Vector2.RIGHT
		aim = aim.normalized()
		# Attack-speed stat (docs/22 block 1/7): scales the frame's
		# cadence; the != 100 gate makes identity STRUCTURAL for the
		# legacy lane (no float ever runs at the default).
		var cadence := int(wf.cadence_ticks)
		if p.attack_speed_stat != 100:
			cadence = maxi(1, roundi(float(cadence) * 100.0 / float(p.attack_speed_stat)))
		# Quickdraw (ledger #2): hard-coded 2/3 cadence while buffed —
		# +50% attack speed, no stat pipeline.
		if world.tick < p.quickdraw_until_tick:
			cadence = maxi(1, (cadence * 2 + 2) / 3)
		p.next_fire_tick = world.tick + cadence
		(
			world
			. events
			. append(
				{
					"type": SimEvents.Type.ATTACK_STARTED,
					"tick": world.tick,
					"player": p.id,
					"pattern": int(wf.pattern_id),
					"pos": p.pos,
					"aim": aim,
				}
			)
		)
		var shots: Array = wf.shots
		for si in shots.size():
			var shot: Resource = shots[si]
			var dir := aim.rotated(deg_to_rad(float(shot.angle_offset_deg)))
			# Range stat (docs/22 block 1/7) scales shot lifetime —
			# reach = speed x ttl; structural identity at 100.
			var ttl := int(shot.ttl_ticks)
			if p.range_stat != 100:
				ttl = maxi(1, roundi(float(ttl) * float(p.range_stat) / 100.0))
			# Damage: docs/22 tier table for the class lane, Loop v1
			# tier/level multipliers for legacy — still a pure function
			# of player state, RNG-free (Progress.shot_damage).
			world.spawn_projectile(
				p.pos + dir * float(shot.spawn_offset),
				dir * float(shot.speed),
				float(shot.radius),
				ttl,
				ActorState.FACTION_FRIENDLY,
				Progress.shot_damage(world, p, int(shot.damage)),
				int(wf.pattern_id),
				int(shot.program),
				float(shot.prog_a),
				float(shot.prog_b),
				float(shot.prog_c),
				int(shot.max_passes)
			)
