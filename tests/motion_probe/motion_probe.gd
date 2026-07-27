extends Node2D
## Motion-smoothness probe — mechanical instrumentation for judder triage
## and, later, the §6 item 1 interp-vs-snap A/B protocol. Drives the player
## under injected input (right, then diagonal) in both render modes and
## measures per-frame camera pixel steps and frame pacing. This measures
## MECHANICS; smoothness verdicts stay human and rested (fresh-hands rule).
##
## Run windowed: godot --path . res://tests/motion_probe/motion_probe.tscn
## Writes reports/motion_probe.json (diagnostic output, not committed).

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const SimWorld := preload("res://sim/sim_world.gd")
const RealtimeDriver := preload("res://game/drivers/realtime_driver.gd")
const HumanSampler := preload("res://input/human_sampler.gd")
const InputMapDefaults := preload("res://input/input_map_defaults.gd")
const ViewClock := preload("res://game/views/view_clock.gd")
const CameraRig := preload("res://game/views/camera_rig.gd")

const TILE := 32.0
const PHASE_S := 3.0
const WARM_S := 0.5
const REPORT_PATH := "res://reports/motion_probe.json"

## Legal open-floor spawn (arena open center is x16..31, y10..21 clear —
## data/arena_lab.json). Each phase gets a FRESH world here so its drive
## path stays inside the clear zone and phases can't contaminate each
## other. (The first probe version spawned at (10,10) — inside the west
## corridor wall row — and correctly measured a player pinned against a
## wall; spawn legality is scenario data's job, the probe's spawns must be
## legal by hand.)
const SPAWN := Vector2(17.0, 12.0)

var world: SimWorld
var driver: RealtimeDriver
var clock: ViewClock
var camera: CameraRig
var _bitgrid: RefCounted

var _phases: Array[Dictionary] = [
	{"name": "interp_right", "interp": true, "actions": ["move_right"]},
	{"name": "interp_diag", "interp": true, "actions": ["move_right", "move_down"]},
	{"name": "snap_right", "interp": false, "actions": ["move_right"]},
	{"name": "snap_diag", "interp": false, "actions": ["move_right", "move_down"]},
]
var _phase_i := -1
var _phase_t := 0.0
var _prev_cam := Vector2.ZERO
var _steps_x: Array[float] = []
var _steps_y: Array[float] = []
var _deltas: Array[float] = []
var _results: Array[Dictionary] = []


func _ready() -> void:
	InputMapDefaults.register()
	var arena := ArenaBuilder.build_arena(self)
	if arena.is_empty():
		get_tree().quit(1)
		return
	_bitgrid = arena.bitgrid

	driver = RealtimeDriver.new()
	driver.sampler = HumanSampler.new()
	driver.mouse_tile_provider = func() -> Vector2: return get_global_mouse_position() / TILE
	add_child(driver)
	clock = ViewClock.new()
	clock.driver = driver

	camera = CameraRig.new()
	camera.world = world
	camera.clock = clock
	add_child(camera)
	camera.setup(int(arena.def.width), int(arena.def.height))

	_next_phase()
	print(
		(
			"motion_probe: refresh=%.1f Hz, vsync_mode=%d, speed=%.1f t/s (%.0f px/s)"
			% [
				DisplayServer.screen_get_refresh_rate(),
				DisplayServer.window_get_vsync_mode(),
				world.players[0].move_speed,
				world.players[0].move_speed * TILE,
			]
		)
	)


func _process(delta: float) -> void:
	if _phase_i >= _phases.size():
		return
	_phase_t += delta
	var cam := camera.position
	if _phase_t > WARM_S:
		_steps_x.append(cam.x - _prev_cam.x)
		_steps_y.append(cam.y - _prev_cam.y)
		_deltas.append(delta)
	_prev_cam = cam
	if _phase_t >= PHASE_S + WARM_S:
		_close_phase()
		_next_phase()


func _next_phase() -> void:
	_phase_i += 1
	if _phase_i >= _phases.size():
		_finish()
		return
	var ph := _phases[_phase_i]
	# Fresh world per phase: same bitgrid, player back at SPAWN, so every
	# phase measures the same legal drive path.
	world = SimWorld.new()
	world.setup(1, _bitgrid)
	world.add_player(SPAWN)
	driver.world = world
	camera.world = world
	clock.interp_enabled = ph.interp
	for a: String in ["move_right", "move_down"]:
		Input.action_release(a)
	for a: String in ph.actions:
		Input.action_press(a)
	_phase_t = 0.0
	_steps_x.clear()
	_steps_y.clear()
	_deltas.clear()
	_prev_cam = camera.position


func _close_phase() -> void:
	var ph := _phases[_phase_i]
	var frames := _deltas.size()
	var time := 0.0
	for d in _deltas:
		time += d
	var fps := frames / time
	var hist := {}
	var stalls := 0
	var moved := 0.0
	for s in _steps_x:
		var key := int(roundf(s))
		hist[key] = int(hist.get(key, 0)) + 1
		if absf(s) < 0.5:
			stalls += 1
		moved += s
	var d_max := 0.0
	var d_sum := 0.0
	for d in _deltas:
		d_max = maxf(d_max, d)
		d_sum += d
	var d_avg := d_sum / frames
	var jitter := 0.0
	for d in _deltas:
		jitter += absf(d - d_avg)
	var r := {
		"phase": ph.name,
		"fps": snappedf(fps, 0.1),
		"ideal_px_per_frame": snappedf(moved / frames, 0.001),
		"step_hist_x": hist,
		"stall_frame_pct": snappedf(100.0 * stalls / frames, 0.1),
		"avg_frame_ms": snappedf(d_avg * 1000.0, 0.01),
		"max_frame_ms": snappedf(d_max * 1000.0, 0.01),
		"mean_abs_pacing_jitter_ms": snappedf(jitter / frames * 1000.0, 0.001),
	}
	_results.append(r)
	print("motion_probe: ", JSON.stringify(r))
	var p: RefCounted = world.players[0]
	print(
		(
			"  debug: tick=%d pos=(%.2f,%.2f) prev=(%.2f,%.2f) alpha=%.3f paused=%s right=%s cam=(%.0f,%.0f)"
			% [
				world.tick,
				p.pos.x,
				p.pos.y,
				p.prev_pos.x,
				p.prev_pos.y,
				clock.alpha(),
				driver.paused,
				Input.is_action_pressed("move_right"),
				camera.position.x,
				camera.position.y,
			]
		)
	)


func _finish() -> void:
	for a: String in ["move_right", "move_down"]:
		Input.action_release(a)
	var report := {
		"refresh_hz": DisplayServer.screen_get_refresh_rate(),
		"vsync_mode": DisplayServer.window_get_vsync_mode(),
		"px_per_s": world.players[0].move_speed * TILE,
		"phases": _results,
	}
	var f := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t"))
	f.close()
	print("motion_probe: report -> ", REPORT_PATH)
	get_tree().quit(0)
