extends Node2D
## M2 600-projectile stress rig (docs/12 §4 M2): holds ~600 live SoA
## projectiles + 24 actor stand-ins in the REAL arena with the real driver,
## sampler, player sheet, and MultiMesh renderer; measures 1-second windows
## of frame/sim time after warmup; writes reports/stress_m2.json and prints
## the spatial-hash / C#-escape-hatch verdict (§2.2/§2.3). That verdict is
## due AT M2 and must not drift. Vsync is disabled so the numbers are raw
## throughput, not display-capped.
##
## Run windowed: godot --path . res://game/stress/stress_rig.tscn

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const SimWorld := preload("res://sim/sim_world.gd")
const ActorState := preload("res://sim/actor_state.gd")
const RealtimeDriver := preload("res://game/drivers/realtime_driver.gd")
const HumanSampler := preload("res://input/human_sampler.gd")
const InputMapDefaults := preload("res://input/input_map_defaults.gd")
const ViewClock := preload("res://game/views/view_clock.gd")
const CameraRig := preload("res://game/views/camera_rig.gd")
const ProjectileView := preload("res://game/views/projectile_view.gd")
const ActorLibrary := preload("res://game/views/actor_library.gd")
const AnimatedActor := preload("res://game/views/animated_actor.gd")

const TILE := 32.0
const RUN_SEED := 7
const TARGET_LIVE := 600
const STANDIN_COUNT := 24
const WARMUP_S := 5.0
const WINDOW_S := 1.0
const WINDOW_COUNT := 30
const SPAWN_CAP_PER_FRAME := 48
const REPORT_PATH := "res://reports/stress_m2.json"
const BUDGET_FRAME_MS := 1000.0 / 60.0

var world: SimWorld
var driver: RealtimeDriver
var clock: ViewClock
var fps_label: Label

var _center := Vector2.ZERO
var _spawn_i := 0
var _last_topup_tick := -1
var _warmup_left := WARMUP_S
var _win := {}
var _windows: Array[Dictionary] = []
var _done := false


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	InputMapDefaults.register()
	var arena := ArenaBuilder.build_arena(self)
	if arena.is_empty():
		get_tree().quit(1)
		return
	_center = Vector2(int(arena.def.width) / 2.0, int(arena.def.height) / 2.0)

	world = SimWorld.new()
	world.setup(RUN_SEED, arena.bitgrid)
	world.add_player(_center)
	for i in STANDIN_COUNT:
		var ang := TAU * i / STANDIN_COUNT
		world.add_enemy_standin(_center + Vector2(cos(ang), sin(ang)) * 12.0)

	driver = RealtimeDriver.new()
	driver.world = world
	driver.sampler = HumanSampler.new()
	driver.mouse_tile_provider = func() -> Vector2: return get_global_mouse_position() / TILE
	add_child(driver)
	clock = ViewClock.new()
	clock.driver = driver

	_add_standin_markers()

	var lib := ActorLibrary.new()
	var sheet_map: Resource = load("res://data/actor_sheet_map.tres")
	if lib.load_manifest() and sheet_map != null:
		var av := AnimatedActor.new()
		av.sprite_frames = lib.build_sprite_frames(String(sheet_map.map.player))
		av.actor = world.players[0]
		av.clock = clock
		av.play("idle-down")
		add_child(av)

	var pv := ProjectileView.new()
	pv.world = world
	pv.clock = clock
	add_child(pv)

	var camera := CameraRig.new()
	camera.world = world
	camera.clock = clock
	add_child(camera)
	camera.setup(int(arena.def.width), int(arena.def.height))

	fps_label = Label.new()
	fps_label.text = "warmup..."
	var hud := CanvasLayer.new()
	hud.add_child(fps_label)
	add_child(hud)

	_reset_win()
	print("stress_rig: warmup %.0fs, then %d x %.0fs windows" % [WARMUP_S, WINDOW_COUNT, WINDOW_S])


func _process(delta: float) -> void:
	if _done:
		return
	_top_up()
	if _warmup_left > 0.0:
		_warmup_left -= delta
		return
	_win.time += delta
	_win.frames += 1
	var ms := delta * 1000.0
	_win.frame_ms_sum += ms
	_win.frame_ms_max = maxf(_win.frame_ms_max, ms)
	var sim_ms: float = driver.frame_sim_usec / 1000.0
	_win.sim_ms_sum += sim_ms
	_win.sim_ms_max = maxf(_win.sim_ms_max, sim_ms)
	_win.live_sum += world.projectiles.live_count
	if _win.time >= WINDOW_S:
		_close_win()


## Keep the pool at TARGET_LIVE: hostile shots spiral out of the stand-in
## ring (golden-angle spread), friendly shots spiral out of the player.
## Deterministic function of the spawn index — no RNG anywhere. Tick-gated:
## commands drain once per tick, so enqueueing more often than the sim
## ticks (uncapped fps = many frames per tick) would overshoot the target
## against a stale live_count.
func _top_up() -> void:
	if world.tick == _last_topup_tick:
		return
	_last_topup_tick = world.tick
	var need: int = TARGET_LIVE - world.projectiles.live_count
	var n := mini(need, SPAWN_CAP_PER_FRAME)
	for k in n:
		_spawn_i += 1
		var ang := fmod(_spawn_i * 2.399963, TAU)
		var dir := Vector2(cos(ang), sin(ang))
		if _spawn_i % 4 == 0:
			(
				world
				. enqueue_command(
					{
						"type": SimWorld.Command.SPAWN_PROJECTILE,
						"pos": _center,
						"vel": dir * 11.0,
						"radius": 0.15,
						"ttl": 200,
						"faction": ActorState.FACTION_FRIENDLY,
					}
				)
			)
		else:
			var src: RefCounted = world.enemies[_spawn_i % STANDIN_COUNT]
			(
				world
				. enqueue_command(
					{
						"type": SimWorld.Command.SPAWN_PROJECTILE,
						"pos": src.pos,
						"vel": dir * 6.0,
						"radius": 0.18,
						"ttl": 260,
						"faction": ActorState.FACTION_HOSTILE,
					}
				)
			)


func _reset_win() -> void:
	_win = {
		"time": 0.0,
		"frames": 0,
		"frame_ms_sum": 0.0,
		"frame_ms_max": 0.0,
		"sim_ms_sum": 0.0,
		"sim_ms_max": 0.0,
		"live_sum": 0,
	}


func _close_win() -> void:
	var frames: int = _win.frames
	var w := {
		"fps": snappedf(frames / _win.time, 0.1),
		"avg_frame_ms": snappedf(_win.frame_ms_sum / frames, 0.001),
		"max_frame_ms": snappedf(_win.frame_ms_max, 0.001),
		"avg_sim_ms": snappedf(_win.sim_ms_sum / frames, 0.001),
		"max_sim_ms": snappedf(_win.sim_ms_max, 0.001),
		"avg_live": _win.live_sum / frames,
	}
	_windows.append(w)
	fps_label.text = (
		"window %d/%d: %.0f fps, frame %.2f ms, sim %.2f ms, live %d"
		% [_windows.size(), WINDOW_COUNT, w.fps, w.avg_frame_ms, w.avg_sim_ms, w.avg_live]
	)
	print("stress_rig: ", fps_label.text)
	_reset_win()
	if _windows.size() >= WINDOW_COUNT:
		_finish()


func _finish() -> void:
	_done = true
	var min_fps := 1.0e9
	var fps_sum := 0.0
	var worst_frame := 0.0
	var worst_avg_frame := 0.0
	var worst_avg_sim := 0.0
	var live_avg := 0
	for w: Dictionary in _windows:
		min_fps = minf(min_fps, w.fps)
		fps_sum += w.fps
		worst_frame = maxf(worst_frame, w.max_frame_ms)
		worst_avg_frame = maxf(worst_avg_frame, w.avg_frame_ms)
		worst_avg_sim = maxf(worst_avg_sim, w.avg_sim_ms)
		live_avg += int(w.avg_live)
	live_avg /= _windows.size()
	# 60 FPS sustained = every window's AVERAGE inside the frame budget;
	# isolated spikes are reported, not verdict-fatal.
	var pass_verdict := worst_avg_frame <= BUDGET_FRAME_MS and min_fps >= 60.0

	var report := {
		"test": "stress_m2",
		"date": Time.get_date_string_from_system(),
		"scope": "dev machine, vsync disabled, windowed",
		"target_live": TARGET_LIVE,
		"standins": STANDIN_COUNT,
		"warmup_s": WARMUP_S,
		"windows": _windows,
		"summary":
		{
			"min_window_fps": min_fps,
			"avg_fps": snappedf(fps_sum / _windows.size(), 0.1),
			"worst_window_avg_frame_ms": worst_avg_frame,
			"worst_single_frame_ms": worst_frame,
			"worst_window_avg_sim_ms": worst_avg_sim,
			"avg_live": live_avg,
			"budget_frame_ms": snappedf(BUDGET_FRAME_MS, 0.001),
			"verdict": "PASS" if pass_verdict else "FAIL",
		},
	}
	var f := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t"))
	f.close()

	print("stress_rig: report -> ", REPORT_PATH)
	if pass_verdict:
		print(
			(
				(
					"VERDICT: PASS — min %d fps, worst window frame %.2f ms (sim %.2f ms) at %d live. "
					% [int(min_fps), worst_avg_frame, worst_avg_sim, live_avg]
				)
				+ "GDScript holds the 600 ceiling; spatial hash and the C#/GDExtension "
				+ "escape hatch STAY DEFERRED (§2.2/§2.3)."
			)
		)
	else:
		print(
			(
				(
					"VERDICT: FAIL — min %.1f fps, worst window frame %.2f ms (sim %.2f ms). "
					% [min_fps, worst_avg_frame, worst_avg_sim]
				)
				+ "Escalation order: multimesh buffer write path, spatial hash, then the "
				+ "sim-confined C# port (§2.2). Decide NOW — this may not drift past M2."
			)
		)
	get_tree().quit(0 if pass_verdict else 1)


func _add_standin_markers() -> void:
	var mmi := MultiMeshInstance2D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	mm.mesh = quad
	mm.instance_count = STANDIN_COUNT
	for i in world.enemies.size():
		var e: RefCounted = world.enemies[i]
		var sc: float = e.radius * TILE
		mm.set_instance_transform_2d(
			i, Transform2D(Vector2(sc, 0.0), Vector2(0.0, sc), e.pos * TILE)
		)
	mmi.multimesh = mm
	mmi.modulate = Color(0.55, 0.3, 0.3)
	add_child(mmi)
