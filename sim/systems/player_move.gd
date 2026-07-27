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


static func run(world: RefCounted) -> void:
	var frames: Array = world.current_frames
	var grid: RefCounted = world.bitgrid
	var dt: float = world.DT
	for i in world.players.size():
		var p: RefCounted = world.players[i]
		# Unconditional: the view interpolates every player every tick (§2.9).
		p.prev_pos = p.pos
		if p.dead:
			continue
		if i >= frames.size() or frames[i] == null:
			continue
		var mv: Vector2 = frames[i].move_vector()
		if mv == Vector2.ZERO:
			continue
		var step: Vector2 = mv * p.move_speed * dt
		p.pos = Kinematics.move_circle(grid, p.pos, p.radius, step)
