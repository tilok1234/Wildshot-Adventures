extends RefCounted
## Ordered system: player kinematics (docs/12 §2.3) — circle body,
## axis-separated slide against the solid-tile bitgrid. Movement is the whole
## defensive kit (CORE-33): no dash/roll/blink verbs exist here, deliberately.
## Firing state never modifies movement (CORE-32 independence) — this system
## reads only the frame's move channel.
##
## `world` is duck-typed SimWorld (typing it would preload-cycle with
## sim_world.gd, which preloads this system).

const AXIS_X := 0
const AXIS_Y := 1


static func run(world: RefCounted) -> void:
	var frames: Array = world.current_frames
	var grid: RefCounted = world.bitgrid
	var dt: float = world.DT
	for i in world.players.size():
		var p: RefCounted = world.players[i]
		# Unconditional: the view interpolates every player every tick (§2.9).
		p.prev_pos = p.pos
		if i >= frames.size() or frames[i] == null:
			continue
		var mv: Vector2 = frames[i].move_vector()
		if mv == Vector2.ZERO:
			continue
		var step: Vector2 = mv * p.move_speed * dt
		var r: float = p.radius
		var nx := _slide(grid, p.pos, r, step.x, AXIS_X)
		var ny := _slide(grid, Vector2(nx, p.pos.y), r, step.y, AXIS_Y)
		p.pos = Vector2(nx, ny)


## Move along one axis, clamped so the circle never enters a solid tile.
## Per-tick moves (<= 5.5/60 tiles) are far below one tile, so only the tile
## row/column at the leading edge can newly collide. Returns the new
## coordinate on the moved axis.
static func _slide(grid: RefCounted, pos: Vector2, r: float, delta: float, axis: int) -> float:
	var along := pos.x if axis == AXIS_X else pos.y
	if delta == 0.0:
		return along
	var cross := pos.y if axis == AXIS_X else pos.x
	var moved := along + delta
	var lead := moved + r if delta > 0.0 else moved - r
	var lead_tile := int(floorf(lead))
	var c0 := int(floorf(cross - r))
	var c1 := int(floorf(cross + r))
	for c in range(c0, c1 + 1):
		var tx := lead_tile if axis == AXIS_X else c
		var ty := c if axis == AXIS_X else lead_tile
		if not grid.is_solid(tx, ty):
			continue
		var cx := moved if axis == AXIS_X else cross
		var cy := cross if axis == AXIS_X else moved
		if not _circle_hits_tile(cx, cy, r, tx, ty):
			continue
		moved = float(lead_tile) - r if delta > 0.0 else float(lead_tile) + 1.0 + r
	return moved


## Closest-point test: true circle-vs-tile, so grazing a tile corner the
## body's rounded edge doesn't reach is not a collision (no corner snag).
static func _circle_hits_tile(cx: float, cy: float, r: float, tx: int, ty: int) -> bool:
	var qx := clampf(cx, float(tx), float(tx) + 1.0)
	var qy := clampf(cy, float(ty), float(ty) + 1.0)
	var dx := cx - qx
	var dy := cy - qy
	return dx * dx + dy * dy < r * r
