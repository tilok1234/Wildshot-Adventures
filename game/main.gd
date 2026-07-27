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
const GifRecorder := preload("res://game/drivers/gif_recorder.gd")
const FlashView := preload("res://game/views/flash_view.gd")
const StatBar := preload("res://ui/stat_bar.gd")
const DensityMeter := preload("res://ui/density_meter.gd")
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
var autofire_icon: TextureRect
var weapon_label: Label
var hp_bar: StatBar
var mana_bar: StatBar
var options_menu: PanelContainer
var density_meter: PanelContainer
var hints_label: Label
var gif_recorder: Node
var rec_label: Label
var _af_on_tex: Texture2D = load("res://uikit/icon_autofire_on.png")
var _af_off_tex: Texture2D = load("res://uikit/icon_autofire_off.png")


## bar_frame stylebox from the kit manifest (margins 2,2,2,2).
static func _bar_frame_box() -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://uikit/bar_frame.png")
	sb.texture_margin_left = 2.0
	sb.texture_margin_top = 2.0
	sb.texture_margin_right = 2.0
	sb.texture_margin_bottom = 2.0
	return sb


func _process(_delta: float) -> void:
	# §2.9 prev/curr render toggle — view-side only, replay-irrelevant.
	if view_clock != null and Input.is_action_just_pressed("interp_toggle"):
		view_clock.interp_enabled = not view_clock.interp_enabled
		print("render interpolation: ", "ON" if view_clock.interp_enabled else "OFF (snap)")
	if options_menu != null and Input.is_action_just_pressed("options_toggle"):
		options_menu.toggle()
		_refresh_hints()
	if density_meter != null and Input.is_action_just_pressed("density_toggle"):
		density_meter.visible = not density_meter.visible
	# Alt+Enter: borderless fullscreen — windowed-mode compositing is a
	# known stutter source on Windows; this is the one-key A/B for it.
	if Input.is_action_just_pressed("fullscreen_toggle"):
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
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
	speed_label.text = (
		"%d fps   spikes %d   speed %.1f t/s%s"
		% [
			Engine.get_frames_per_second(),
			driver.spike_count,
			cur,
			"   REPLAY-DIRTY" if world.replay_dirty else "",
		]
	)
	var p: RefCounted = world.players[0]
	autofire_icon.texture = _af_on_tex if p.autofire_on else _af_off_tex
	hp_bar.value = p.hp / 100.0
	mana_bar.value = p.mana / 100.0
	rec_label.visible = gif_recorder != null and gif_recorder.armed
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


func _refresh_hints() -> void:
	var parts: Array[String] = []
	for entry: Array in [
		["options_toggle", "options"],
		["interp_toggle", "interp"],
		["debug_speed_lowest", "spd 3.0"],
		["debug_speed_baseline", "spd 4.0"],
		["gif_dump", "gif"],
		["replay_save", "replay"],
	]:
		parts.append("%s %s" % [Config.binding_text(entry[0]), entry[1]])
	hints_label.text = "  ".join(parts)


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

	gif_recorder = GifRecorder.new()
	add_child(gif_recorder)

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

	var flashes := FlashView.new()
	flashes.driver = driver
	add_child(flashes)

	density_meter = DensityMeter.new()
	density_meter.world = world
	density_meter.budgets = load("res://data/budgets.tres")
	density_meter.effects_counter = flashes.active_count
	density_meter.visible = false
	density_meter.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	density_meter.position += Vector2(-4.0, 16.0)

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
	speed_label.position.y -= 24.0
	# Autofire indicator reads SIM state (§2.8) — the latch, not the key.
	# Kit icons: ON/OFF differ by shape, not color (CORE-50).
	autofire_icon = TextureRect.new()
	autofire_icon.texture = load("res://uikit/icon_autofire_off.png")
	autofire_icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	autofire_icon.position = Vector2(4.0, 4.0)
	weapon_label = Label.new()
	weapon_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	# HP/mana bars (M4 HUD): kit frame + pattern-differentiated fills.
	hp_bar = StatBar.new()
	hp_bar.frame_box = _bar_frame_box()
	hp_bar.fill_tex = load("res://uikit/bar_fill_hp.png")
	hp_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hp_bar.position = Vector2(4.0, -22.0)
	hp_bar.size = Vector2(64.0, 8.0)
	mana_bar = StatBar.new()
	mana_bar.frame_box = _bar_frame_box()
	mana_bar.fill_tex = load("res://uikit/bar_fill_mana.png")
	mana_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	mana_bar.position = Vector2(4.0, -12.0)
	mana_bar.size = Vector2(64.0, 8.0)
	# GIF capture costs real frame time while armed — the indicator is
	# also the "why did fps dip" explanation.
	rec_label = Label.new()
	rec_label.text = "● REC (fps dips while capturing)"
	rec_label.visible = false
	rec_label.modulate = Color(1.0, 0.35, 0.35)
	rec_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	options_menu = OptionsMenu.new()
	# Live key-hint line: reads the ACTUAL InputMap, so it stays correct
	# after remaps.
	hints_label = Label.new()
	hints_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hints_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var hud := CanvasLayer.new()
	hud.add_child(pause_label)
	hud.add_child(speed_label)
	hud.add_child(autofire_icon)
	hud.add_child(weapon_label)
	hud.add_child(hp_bar)
	hud.add_child(mana_bar)
	hud.add_child(rec_label)
	hud.add_child(hints_label)
	hud.add_child(density_meter)
	hud.add_child(options_menu)
	add_child(hud)
	Input.set_custom_mouse_cursor(
		load("res://uikit/cursor_crosshair.png"), Input.CURSOR_ARROW, Vector2(5.0, 5.0)
	)
	driver.pause_changed.connect(func(p: bool) -> void: pause_label.visible = p)
	_refresh_hints()

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
