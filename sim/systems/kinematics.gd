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
##
## Ejection resolves to the TRUE constraint feature (2026-07-28, the
## M2-movement corner-shiver fix): a face contact ejects to the face
## plane exactly as before, but a CORNER-arc contact ejects to corner
## tangency — face -/+ sqrt(r^2 - dy^2), dy = the circle center's
## cross-axis gap to the tile's cross extent. The old code ejected
## corner contacts to the full face plane, over-ejecting past tangency
## by up to r - sqrt(r^2 - dy^2); the next tick freely re-approached,
## re-hit, re-ejected — a deterministic limit cycle felt as a 2-pixel
## shiver with ZERO net progress, trapped a visible gap away from any
## corner ("walking bugs out near structures and props"). The formula
## degenerates to the face plane at dy = 0, so face-slide behavior is
## byte-identical; multiple colliding tiles take the most restrictive
## tangent. At exact tangency the strict < in circle_hits_tile reports
## no hit, so the rest position is stable.
static func slide(
	grid: RefCounted, pos: Vector2, r: float, delta: float, axis: int, discs: Dictionary = {}
) -> float:
	return float(slide_ex(grid, pos, r, delta, axis, discs).coord)


## slide() plus bind metadata for the corner-slip pass: corner_bind is
## true when the axis was clamped and EVERY binding contact was a
## corner arc (dy > 0 — no face contact); escape_sign is the cross-axis
## direction away from the tightest binding corner.
##
## discs (sl-0078 fit rule): optional sub-cell prop colliders, keyed
## cell -> Array[Vector3(x, y, r)]. A disc contact is a CURVED contact
## by construction — same clamp discipline as the corner arc (most
## restrictive tangent wins, strict-inequality tangency rest), and it
## classifies corner-like for the slip pass unless dead-center on the
## cross axis (a head-on trunk press is an honest face-like stop).
## Empty dict = byte-identical legacy behavior (every enemy walker).
static func slide_ex(
	grid: RefCounted, pos: Vector2, r: float, delta: float, axis: int, discs: Dictionary = {}
) -> Dictionary:
	var along := pos.x if axis == AXIS_X else pos.y
	if delta == 0.0:
		return {"coord": along, "corner_bind": false, "escape_sign": 0.0}
	var cross := pos.y if axis == AXIS_X else pos.x
	var moved := along + delta
	var lead := moved + r if delta > 0.0 else moved - r
	var lead_tile := int(floorf(lead))
	var c0 := int(floorf(cross - r))
	var c1 := int(floorf(cross + r))
	var any_face := false
	var any_corner := false
	var escape := 0.0
	for c in range(c0, c1 + 1):
		var tx := lead_tile if axis == AXIS_X else c
		var ty := c if axis == AXIS_X else lead_tile
		if not grid.is_solid(tx, ty):
			continue
		var cx := moved if axis == AXIS_X else cross
		var cy := cross if axis == AXIS_X else moved
		if not circle_hits_tile(cx, cy, r, tx, ty):
			continue
		var cross_lo := float(ty) if axis == AXIS_X else float(tx)
		var dy := absf(cross - clampf(cross, cross_lo, cross_lo + 1.0))
		var allowed := sqrt(maxf(0.0, r * r - dy * dy))
		var before := moved
		if delta > 0.0:
			moved = minf(moved, float(lead_tile) - allowed)
		else:
			moved = maxf(moved, float(lead_tile) + 1.0 + allowed)
		if dy > 0.0:
			if moved != before or not any_corner:
				escape = -1.0 if cross < cross_lo else 1.0
			any_corner = true
		else:
			any_face = true
	if not discs.is_empty():
		# Any disc that can touch the swept circle has its center in the
		# 3x3 cell neighborhood of the candidate position (disc r <= 0.45
		# + body r + sub-tile step < 1 cell). Fixed y-then-x cell order,
		# fixed per-cell array order — deterministic.
		var nx := moved if axis == AXIS_X else cross
		var ny := cross if axis == AXIS_X else moved
		var ccx := int(floorf(nx))
		var ccy := int(floorf(ny))
		for cy2 in range(ccy - 1, ccy + 2):
			for cx2 in range(ccx - 1, ccx + 2):
				var arr: Array = discs.get(Vector2i(cx2, cy2), [])
				for dsc: Vector3 in arr:
					var disc_along := dsc.x if axis == AXIS_X else dsc.y
					var disc_cross := dsc.y if axis == AXIS_X else dsc.x
					var rr := r + dsc.z
					var dy2 := absf(cross - disc_cross)
					if dy2 >= rr:
						continue
					var cand := moved
					var da := cand - disc_along
					if da * da + dy2 * dy2 >= rr * rr:
						continue
					var allowed2 := sqrt(maxf(0.0, rr * rr - dy2 * dy2))
					var before2 := moved
					if delta > 0.0:
						moved = minf(moved, disc_along - allowed2)
					else:
						moved = maxf(moved, disc_along + allowed2)
					if dy2 > 0.0:
						if moved != before2 or not any_corner:
							escape = -1.0 if cross < disc_cross else 1.0
						any_corner = true
					else:
						any_face = true
	var clamped := moved != along + delta
	return {
		"coord": moved,
		"corner_bind": clamped and any_corner and not any_face,
		"escape_sign": escape,
	}


## Both-axes convenience: slide X then Y (the §2.3 order), returning the
## final position. Every walking body — player or enemy — moves through
## this, so corner behavior is identical by construction.
##
## CORNER SLIP (2026-07-28, designer-directed walk-close feel, [T]):
## when an axis is blocked ONLY by corner-arc contacts, its unused
## motion deflects into the cross axis AWAY from the binding corner —
## brushing past a corner curls you smoothly around it. The deflection
## never fights explicit input: pressing INTO the corner on the cross
## axis holds the honest tangent rest. Deterministic, pure function of
## (pos, step, grid); applies to every mover through this one path.
static func move_circle(
	grid: RefCounted, pos: Vector2, r: float, step: Vector2, discs: Dictionary = {}
) -> Vector2:
	var rx := slide_ex(grid, pos, r, step.x, AXIS_X, discs)
	var nx: float = rx.coord
	var ry := slide_ex(grid, Vector2(nx, pos.y), r, step.y, AXIS_Y, discs)
	var ny: float = ry.coord
	# X blocked purely by a corner: spend the unused X magnitude along Y
	# in the escape direction (unless Y input opposes it).
	var left_x: float = absf(step.x) - absf(nx - pos.x)
	if bool(rx.corner_bind) and left_x > 0.0001:
		var esc_x: float = rx.escape_sign
		if step.y == 0.0 or signf(step.y) == esc_x:
			ny = slide(grid, Vector2(nx, ny), r, left_x * esc_x, AXIS_Y, discs)
	# Y blocked purely by a corner: spend the unused Y magnitude along X.
	var left_y: float = absf(step.y) - absf(ny - pos.y)
	if bool(ry.corner_bind) and left_y > 0.0001:
		var esc_y: float = ry.escape_sign
		if step.x == 0.0 or signf(step.x) == esc_y:
			nx = slide(grid, Vector2(nx, ny), r, left_y * esc_y, AXIS_X, discs)
	return Vector2(nx, ny)


## Closest-point test: true circle-vs-tile, so grazing a tile corner the
## body's rounded edge doesn't reach is not a collision (no corner snag).
static func circle_hits_tile(cx: float, cy: float, r: float, tx: int, ty: int) -> bool:
	var qx := clampf(cx, float(tx), float(tx) + 1.0)
	var qy := clampf(cy, float(ty), float(ty) + 1.0)
	var dx := cx - qx
	var dy := cy - qy
	return dx * dx + dy * dy < r * r
