extends Node2D
## Phase A lab main scene (M3 state): arena + bitgrid from one definition,
## SimWorld with the three weapon frames and target-practice stand-ins,
## RealtimeDriver + HumanSampler, player rendering from its Sprite Forge
## sheet, per-faction projectile rendering, corner-snag logging, and the
## HUD's autofire/weapon/speed readouts. Scenario picker and the full
## debug layer land at M4.

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const SimWorld := preload("res://sim/sim_world.gd")
const RealtimeDriver := preload("res://game/drivers/realtime_driver.gd")
const CollisionLogger := preload("res://game/drivers/collision_logger.gd")
const HumanSampler := preload("res://input/human_sampler.gd")
const InputMapDefaults := preload("res://input/input_map_defaults.gd")
const ReplayRecorder := preload("res://input/replay_recorder.gd")
const OptionsMenu := preload("res://ui/options_menu.gd")
const ActorLibrary := preload("res://game/views/actor_library.gd")
const AnimatedActor := preload("res://game/views/animated_actor.gd")

const ViewClock := preload("res://game/views/view_clock.gd")
const CameraRig := preload("res://game/views/camera_rig.gd")
const ProjectileView := preload("res://game/views/projectile_view.gd")
const StandinView := preload("res://game/views/standin_view.gd")

const TILE := 32.0
## Fixed dev seed until the scenario picker (M4) supplies one; always logged.
const RUN_SEED := 1

var bitgrid: RefCounted
var world: SimWorld
var driver: RealtimeDriver
var view_clock: ViewClock
var speed_label: Label
var autofire_label: Label
var weapon_label: Label
var options_menu: PanelContainer


func _process(_delta: float) -> void:
	# §2.9 prev/curr render toggle (F7) — view-side only, replay-irrelevant.
	if view_clock != null and Input.is_action_just_pressed("interp_toggle"):
		view_clock.interp_enabled = not view_clock.interp_enabled
		print("render interpolation: ", "ON" if view_clock.interp_enabled else "OFF (snap)")
	if options_menu != null and Input.is_action_just_pressed("options_toggle"):
		options_menu.toggle()
	if world == null or world.players.is_empty():
		return
	# M2 movement-speed editor: presets + 0.1 steps, routed through the sim
	# command queue (band-clamped and replay-dirty-stamped sim-side, §3.2).
	var cur: float = world.players[0].move_speed
	if Input.is_action_just_pressed("debug_speed_lowest"):
		_set_speed(3.0)
	elif Input.is_action_just_pressed("debug_speed_baseline"):
		_set_speed(4.0)
	elif Input.is_action_just_pressed("debug_speed_down"):
		_set_speed(snappedf(cur - 0.1, 0.1))
	elif Input.is_action_just_pressed("debug_speed_up"):
		_set_speed(snappedf(cur + 0.1, 0.1))
	speed_label.text = ("speed %.1f t/s%s" % [cur, "   REPLAY-DIRTY" if world.replay_dirty else ""])
	var p: RefCounted = world.players[0]
	autofire_label.visible = p.autofire_on
	if not world.weapon_frames.is_empty():
		weapon_label.text = String(world.weapon_frames[p.equipped_weapon].display_name)
	# F10: dump the always-on session recording. NOTE: the main scene is a
	# hardcoded dev scenario until M4 — saved replays verify only against
	# the same build (no scenario id exists for it yet); golden fixtures
	# use the registered scenario path.
	if Input.is_action_just_pressed("replay_save") and driver.recorder != null:
		var path := "user://replays/session_%d.wsr" % world.tick
		if driver.recorder.save_wsr(path, "dev", "main_dev_scene"):
			print("replay saved: ", ProjectSettings.globalize_path(path))


func _set_speed(speed: float) -> void:
	world.enqueue_command({"type": SimWorld.Command.SET_MOVE_SPEED, "player": 0, "speed": speed})
	print(
		(
			"speed editor: requested %.1f t/s (band %.1f-%.1f; run now replay-dirty)"
			% [speed, SimWorld.MOVE_SPEED_MIN, SimWorld.MOVE_SPEED_MAX]
		)
	)


func _ready() -> void:
	var arena := ArenaBuilder.build_arena(self)
	if arena.is_empty():
		return
	var def: Dictionary = arena.def
	bitgrid = arena.bitgrid

	# InputMap defaults + saved remaps are applied by the Config autoload
	# before any scene _ready runs.
	world = SimWorld.new()
	world.setup(RUN_SEED, bitgrid)
	(
		world
		. set_weapons(
			[
				load("res://data/weapons/longbolt.tres"),
				load("res://data/weapons/scattercast.tres"),
				load("res://data/weapons/wheelblade.tres"),
			]
		)
	)
	var center := Vector2(int(def.width) / 2.0, int(def.height) / 2.0)
	world.add_player(center)
	# M3 target practice: a ring of inert stand-ins to shoot. The M4
	# scenario picker replaces this hardcoded setup with scenario .tres.
	for i in 8:
		var ang := TAU * i / 8.0
		world.add_enemy_standin(center + Vector2(cos(ang), sin(ang)) * 6.0)

	driver = RealtimeDriver.new()
	driver.world = world
	driver.sampler = HumanSampler.new()
	driver.mouse_tile_provider = func() -> Vector2: return get_global_mouse_position() / TILE
	driver.recorder = ReplayRecorder.new()
	driver.recorder.begin(world)
	add_child(driver)

	var snag_logger := CollisionLogger.new()
	snag_logger.driver = driver
	add_child(snag_logger)

	view_clock = ViewClock.new()
	view_clock.driver = driver

	var standins := StandinView.new()
	standins.world = world
	add_child(standins)

	var lib := ActorLibrary.new()
	var sheet_map: Resource = load("res://data/actor_sheet_map.tres")
	if lib.load_manifest() and sheet_map != null and lib.has_actor(String(sheet_map.map.player)):
		var av := AnimatedActor.new()
		av.sprite_frames = lib.build_sprite_frames(String(sheet_map.map.player))
		av.actor = world.players[0]
		av.clock = view_clock
		av.play("idle-down")
		add_child(av)
	else:
		push_error("main: player sheet unavailable — run the spriteforge importer")

	var pv := ProjectileView.new()
	pv.world = world
	pv.clock = view_clock
	add_child(pv)

	var camera := CameraRig.new()
	camera.world = world
	camera.clock = view_clock
	add_child(camera)
	camera.setup(int(def.width), int(def.height))

	var pause_label := Label.new()
	pause_label.text = "PAUSED"
	pause_label.visible = false
	pause_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	speed_label = Label.new()
	speed_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	# Autofire indicator reads SIM state (§2.8) — the latch, not the key.
	autofire_label = Label.new()
	autofire_label.text = "AUTOFIRE"
	autofire_label.visible = false
	autofire_label.modulate = Color(1.0, 0.5, 0.3)
	autofire_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	weapon_label = Label.new()
	weapon_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	options_menu = OptionsMenu.new()
	var hud := CanvasLayer.new()
	hud.add_child(pause_label)
	hud.add_child(speed_label)
	hud.add_child(autofire_label)
	hud.add_child(weapon_label)
	hud.add_child(options_menu)
	add_child(hud)
	driver.pause_changed.connect(func(p: bool) -> void: pause_label.visible = p)

	print(
		(
			"arena ready: %dx%d, %d solid cells, %d placements, seed=%d"
			% [
				int(def.width),
				int(def.height),
				bitgrid.solid_count(),
				int(arena.placements),
				RUN_SEED,
			]
		)
	)
