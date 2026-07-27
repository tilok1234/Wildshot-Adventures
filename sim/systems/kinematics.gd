extends RefCounted
## Shared circle-body kinematics vs the solid-tile bitgrid (docs/12 §2.3):
## axis-separated slide, closest-point circle-vs-tile test. Extracted from
## player_move at M5 so enemies move on the EXACT same math — one slide
## implementation, one corner behavior, forever (the M5 plan's "extract
## shared helper" line). Pure statics; no state, no RNG.

const AXIS_X := 0
const AXIS_Y := 1


## Move along one axis, clamped so the circle never enters a solid tile.
## Per-tick moves (<= 5.5/60 tiles) are far below one tile, so only the tile
## row/column at the leading edge can newly collide. Returns the new
## coordinate on the moved axis.
static func slide(grid: RefCounted, pos: Vector2, r: float, delta: float, axis: int) -> float:
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
		if not circle_hits_tile(cx, cy, r, tx, ty):
			continue
		moved = float(lead_tile) - r if delta > 0.0 else float(lead_tile) + 1.0 + r
	return moved


## Both-axes convenience: slide X then Y (the §2.3 order), returning the
## final position. Every walking body — player or enemy — moves through
## this, so corner behavior is identical by construction.
static func move_circle(grid: RefCounted, pos: Vector2, r: float, step: Vector2) -> Vector2:
	var nx := slide(grid, pos, r, step.x, AXIS_X)
	var ny := slide(grid, Vector2(nx, pos.y), r, step.y, AXIS_Y)
	return Vector2(nx, ny)


## Closest-point test: true circle-vs-tile, so grazing a tile corner the
## body's rounded edge doesn't reach is not a collision (no corner snag).
static func circle_hits_tile(cx: float, cy: float, r: float, tx: int, ty: int) -> bool:
	var qx := clampf(cx, float(tx), float(tx) + 1.0)
	var qy := clampf(cy, float(ty), float(ty) + 1.0)
	var dx := cx - qx
	var dy := cy - qy
	return dx * dx + dy * dy < r * r
