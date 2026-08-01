extends RefCounted
## Ordered system: player kinematics (docs/12 §2.3) — circle body,
## axis-separated slide against the solid-tile bitgrid via the shared
## Kinematics helper (enemies move on the same math, M5). Movement is the
## whole defensive kit (CORE-33): no dash/roll/blink verbs exist here,
## deliberately. Firing state never modifies movement (CORE-32
## independence) — this system reads only the frame's move channel.
##
## `world` is duck-typed SimWorld (typing it would preload-cycle with
## sim_world.gd, which preloads this system).

const Kinematics := preload("res://sim/systems/kinematics.gd")

## Locomotion radius vs terrain (2026-07-28 walk-close feel; RETUNED
## 2026-08-01 by THE FIT RULE, sl-0078 designer-directed: "if there is
## more then enough for the character sprite to go between it it
## should be able to go between it"): the body IS the character
## sprite's visible feet — ranger frame 0 rows 19-22 measure exactly
## 10 px wide, so the radius is 5/32 tiles, art-exact. The 0.35
## HURTBOX (ActorState.radius) is untouched everywhere it matters —
## projectile/hazard/contact hits, the hitbox indicator, recaps —
## this constant governs terrain sliding only. DodgeBot walks with
## the same value (one locomotion truth, bot honesty §2.8).
const TERRAIN_RADIUS := 0.15625


static func run(world: RefCounted) -> void:
	var frames: Array = world.current_frames
	var dt: float = world.DT
	for i in world.players.size():
		var p: RefCounted = world.players[i]
		# Unconditional: the view interpolates every player every tick (§2.9).
		p.prev_pos = p.pos
		var before: Vector2 = p.pos
		if not p.dead and i < frames.size() and frames[i] != null:
			var mv: Vector2 = frames[i].move_vector()
			if mv != Vector2.ZERO:
				var step: Vector2 = mv * p.move_speed * dt
				# sl-0078: players walk the fit-rule truth (walk_grid +
				# art-matched prop discs); enemies stay on the full grid.
				p.pos = Kinematics.move_circle(
					world.walk_grid, p.pos, TERRAIN_RADIUS, step, world.prop_discs
				)
		# Serialized applied velocity (SERIAL 10): post-slide truth, every
		# tick — intercept aim must see a wall-pinned player as stationary.
		p.vel = (p.pos - before) / dt
