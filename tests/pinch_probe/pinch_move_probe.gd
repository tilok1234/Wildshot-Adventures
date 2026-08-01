extends SceneTree
## sl-0070 movement-behavior probe (diagnosis only): drives the REAL
## shared Kinematics.move_circle at the REAL TERRAIN_RADIUS through
## synthetic pinch/corner/lane geometry at lowest intended speed
## (3.0 t/s, dt 1/60) and reports slide-vs-hard-stop facts.
## Run: godot_console --headless --path . --script tests/pinch_probe/pinch_move_probe.gd
## (on-demand diagnosis probe, not a fixed gate — map_overlay_probe
## precedent; re-run with tools/diag_pinch.py after any fix lever)

const Kinematics := preload("res://sim/systems/kinematics.gd")
const PlayerMove := preload("res://sim/systems/player_move.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")

const R := PlayerMove.TERRAIN_RADIUS
const SPEED := 3.0
const DT := 1.0 / 60.0
const TICKS := 240


func _grid(solids: Array) -> RefCounted:
	var g: RefCounted = Bitgrid.new()
	g.setup(16, 16)
	for s: Vector2i in solids:
		g.set_solid(s.x, s.y)
	return g


## Walk from start pressing unit direction dir for TICKS; returns facts.
func _walk(g: RefCounted, start: Vector2, dir: Vector2, target_cell: Vector2i) -> Dictionary:
	var pos := start
	var crossed_tick := -1
	var trail: Array[Vector2] = []
	for t in TICKS:
		pos = Kinematics.move_circle(g, pos, R, dir.normalized() * SPEED * DT)
		trail.append(pos)
		if crossed_tick < 0 and Vector2i(int(floorf(pos.x)), int(floorf(pos.y))) == target_cell:
			crossed_tick = t + 1
	var late_move := 0.0
	for i in range(TICKS - 60, TICKS):
		late_move += trail[i].distance_to(trail[i - 1])
	return {
		"crossed": crossed_tick >= 0,
		"ticks": crossed_tick,
		"final": pos,
		"net": start.distance_to(pos),
		"late_move_60": late_move,
	}


func _report(name: String, r: Dictionary) -> void:
	print(
		(
			"%s: crossed=%s ticks=%d final=(%.3f,%.3f) net=%.3f late60=%.4f"
			% [name, str(r.crossed), int(r.ticks), r.final.x, r.final.y, r.net, r.late_move_60]
		)
	)


func _init() -> void:
	print("probe: r=%.2f speed=%.1f t/s dt=1/60 ticks=%d" % [R, SPEED, TICKS])

	# A: corner-touch pinch — solids (7,7)+(8,8), opens (8,7)+(7,8).
	# Press the exact desired diagonal from the NE open cell to the SW
	# open cell (through the shared corner point (8,8)).
	var g_pinch := _grid([Vector2i(7, 7), Vector2i(8, 8)])
	_report(
		"A  pinch diagonal press", _walk(g_pinch, Vector2(8.5, 7.5), Vector2(-1, 1), Vector2i(7, 8))
	)

	# A2: slide INTO the pinch along the face of (7,7) pressing south —
	# does the wedge rest hold still (no shiver, honest stop)?
	_report(
		"A2 pinch face-slide entry",
		_walk(g_pinch, Vector2(8.35, 6.5), Vector2(-0.2, 1), Vector2i(7, 8))
	)

	# B: LONE corner, same press — corner slip should curl the body
	# around the single corner and cross.
	var g_lone := _grid([Vector2i(7, 7)])
	_report(
		"B  lone-corner same press",
		_walk(g_lone, Vector2(8.5, 7.5), Vector2(-1, 1), Vector2i(7, 8))
	)

	# C: 1-wide lane, centered entry, straight press east through it.
	var lane_solids: Array = []
	for x in range(6, 10):
		lane_solids.append(Vector2i(x, 6))
		lane_solids.append(Vector2i(x, 8))
	var g_lane := _grid(lane_solids)
	_report(
		"C  1-wide lane centered", _walk(g_lane, Vector2(5.5, 7.5), Vector2(1, 0), Vector2i(10, 7))
	)

	# C2: 1-wide lane, MISALIGNED entry (center 0.4 below the lane
	# axis) — does the slip funnel the body in, and at what cost?
	_report(
		"C2 1-wide lane misaligned",
		_walk(g_lane, Vector2(5.5, 7.9), Vector2(1, 0), Vector2i(10, 7))
	)

	# D: open-ground baselines for the same displacements.
	var g_open := _grid([])
	_report(
		"D  open diagonal baseline",
		_walk(g_open, Vector2(8.5, 7.5), Vector2(-1, 1), Vector2i(7, 8))
	)
	_report(
		"D2 open straight baseline",
		_walk(g_open, Vector2(5.5, 7.5), Vector2(1, 0), Vector2i(10, 7))
	)

	quit(0)
