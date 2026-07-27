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
const HazardView := preload("res://game/views/hazard_view.gd")
const DamageNumberView := preload("res://game/views/damage_number_view.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const RecapTracker := preload("res://game/drivers/recap_tracker.gd")
const RecapPanel := preload("res://ui/recap_panel.gd")
const DebugConsole := preload("res://ui/debug_console.gd")
const HitboxView := preload("res://game/views/hitbox_view.gd")
const SimEvents := preload("res://sim/events.gd")
const ActorLibrary := preload("res://game/views/actor_library.gd")
const AnimatedActor := preload("res://game/views/animated_actor.gd")

const ViewClock := preload("res://game/views/view_clock.gd")
const CameraRig := preload("res://game/views/camera_rig.gd")
const ProjectileView := preload("res://game/views/projectile_view.gd")
const StandinView := preload("res://game/views/standin_view.gd")

const TILE := 32.0

var bitgrid: RefCounted
var world: SimWorld
var driver: RealtimeDriver
var view_clock: ViewClock
var speed_label: Label
var autofire_icon: TextureRect
var weapon_label: Label
var hp_bar: StatBar
var mana_bar: StatBar
var ability_label: Label
var options_menu: PanelContainer
var density_meter: PanelContainer
var hints_label: Label
var gif_recorder: Node
var rec_label: Label
var feedback_settings: Dictionary = {}
var recap_panel: PanelContainer
var console: PanelContainer
var hitboxes: Node2D
var hud_stack: VBoxContainer
var _console_events := "off"
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
	# One-key reseeding reset (§2.10): next seed persisted + logged, full
	# scene rebuild — no ref-swapping, no stale state.
	if world != null and Input.is_action_just_pressed("scenario_reset"):
		Config.set_setting("dev", "seed", world.run_seed + 1)
		print("scenario reset -> seed %d" % (world.run_seed + 1))
		get_tree().reload_current_scene()
		return
	# Alt+Enter: borderless fullscreen — windowed-mode compositing is a
	# known stutter source on Windows; this is the one-key A/B for it.
	# Choice persists (§2.13 window key).
	if Input.is_action_just_pressed("fullscreen_toggle"):
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
		Config.set_setting("ui", "fullscreen", not fs)
	if console != null and Input.is_action_just_pressed("console_toggle"):
		console.toggle()
	if hitboxes != null and Input.is_action_just_pressed("hitbox_toggle"):
		hitboxes.visible = not hitboxes.visible
		Config.set_setting("ui", "hitboxes", hitboxes.visible)
	# Event-console tail (§2.10): only while the console is open.
	if console != null and console.visible and _console_events != "off":
		for ev: Dictionary in driver.frame_events:
			var tname := String(SimEvents.Type.keys()[int(ev.type)])
			if (
				_console_events != "all"
				and tname in ["RESOURCE_REGEN", "PROJECTILE_SPAWNED", "PROJECTILE_DESPAWNED"]
			):
				continue
			var d := ev.duplicate()
			d.erase("type")
			d.erase("tick")
			console.println("[%d] %s %s" % [int(ev.tick), tname, str(d)])
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
	var adef: Resource = world.ability_def
	if adef != null:
		var affordable: bool = p.mana >= int(adef.mana_cost)
		ability_label.text = "[Space] %s %dmp" % [String(adef.display_name), int(adef.mana_cost)]
		ability_label.modulate = Color.WHITE if affordable else Color(0.6, 0.55, 0.75)
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


## CORE-50 UI/text scaling: integer multiples only (kit contract), applied
## live to every HUD surface via a scaled duplicate of the kit theme.
## World rendering is untouched — this scales UI, not the game.
func _apply_ui_scale(k: int) -> void:
	var th: Theme = load("res://ui/theme.tres").duplicate()
	th.default_base_scale = float(k)
	th.default_font_size = 10 * k
	for c: Control in [
		hud_stack,
		autofire_icon,
		weapon_label,
		rec_label,
		hints_label,
		density_meter,
		options_menu,
		recap_panel,
		console,
	]:
		if c != null:
			c.theme = th
	hp_bar.custom_minimum_size = Vector2(64.0 * k, 8.0 * k)
	mana_bar.custom_minimum_size = Vector2(64.0 * k, 8.0 * k)
	autofire_icon.scale = Vector2(float(k), float(k))


func _console_exec(line: String) -> void:
	var tokens := line.strip_edges().split(" ", false)
	if tokens.is_empty():
		return
	match String(tokens[0]).to_lower():
		"help":
			console.println("god | slowmo <1-10> | events <on|off|all> | emitter <on|off> | reset")
			console.println("verdict <dodgeability|feel> <rested-human|bot-proof> <text>")
		"god":
			var want: bool = not world.god_mode
			world.enqueue_command({"type": SimWorld.Command.SET_GOD, "on": want})
			console.println(
				(
					"god -> %s (replay-dirty; absorbed hits log DAMAGE_IMMUNE)"
					% ("ON" if want else "OFF")
				)
			)
		"slowmo":
			var d := clampf(float(tokens[1]) if tokens.size() > 1 else 1.0, 1.0, 10.0)
			driver.time_divisor = d
			console.println("slow-mo divisor %.1f (replay-valid; dt unchanged)" % d)
		"verdict":
			_console_verdict(tokens)
		"events":
			_console_events = String(tokens[1]) if tokens.size() > 1 else "on"
			console.println("event tail: " + _console_events)
		"emitter":
			var on: bool = tokens.size() > 1 and String(tokens[1]) == "on"
			world.enqueue_command(
				{"type": SimWorld.Command.TOGGLE_EMITTER, "on": on, "pos": Vector2(30.0, 12.0)}
			)
			console.println("emitter -> %s (replay-dirty)" % ("ON" if on else "OFF"))
		"reset":
			Config.set_setting("dev", "seed", world.run_seed + 1)
			get_tree().reload_current_scene()
		_:
			console.println("unknown: %s (try help)" % tokens[0])


## The fresh-hands split verdict command (§2.10, PLAN-fresh-hands):
## dodgeability accepts {rested-human, bot-proof}; feel accepts rested
## humans ONLY. Runtime edits or active slow-mo auto-stamp PROVISIONAL.
## Data, not willpower.
func _console_verdict(tokens: PackedStringArray) -> void:
	if tokens.size() < 4:
		console.println("usage: verdict <dodgeability|feel> <rested-human|bot-proof> <text>")
		return
	var vtype := String(tokens[1]).to_lower()
	var source := String(tokens[2]).to_lower()
	if not vtype in ["dodgeability", "feel"] or not source in ["rested-human", "bot-proof"]:
		console.println("usage: verdict <dodgeability|feel> <rested-human|bot-proof> <text>")
		return
	if vtype == "feel" and source == "bot-proof":
		console.println(
			"REJECTED: feel verdicts accept rested humans ONLY — bots verify mechanics, never feel."
		)
		return
	var provisional: bool = world.replay_dirty or driver.time_divisor != 1.0
	var text := " ".join(Array(tokens).slice(3))
	var entry := {
		"tick": world.tick,
		"type": vtype,
		"source": source,
		"text": text,
		"provisional": provisional,
		"replay_dirty": world.replay_dirty,
		"slowmo": driver.time_divisor,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://logs"))
	var f := FileAccess.open("user://logs/verdicts.jsonl", FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open("user://logs/verdicts.jsonl", FileAccess.WRITE)
	if f != null:
		f.seek_end()
		f.store_line(JSON.stringify(entry))
		f.close()
	console.println(
		(
			"verdict recorded%s: %s/%s — %s"
			% [" [PROVISIONAL: runtime edits this run]" if provisional else "", vtype, source, text]
		)
	)


func _refresh_hints() -> void:
	var parts: Array[String] = []
	for entry: Array in [
		["options_toggle", "options"],
		["interp_toggle", "interp"],
		["debug_speed_lowest", "spd 3.0"],
		["debug_speed_baseline", "spd 4.0"],
		["gif_dump", "gif"],
		["replay_save", "replay"],
		["scenario_reset", "reset"],
		["density_toggle", "meter"],
		["hitbox_toggle", "hitbox"],
		["console_toggle", "console"],
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
	# before any scene _ready runs. Scenario + seed + speed preset come
	# from persisted dev settings; T rebuilds with the next seed.
	var scenario: Resource = load(
		String(Config.get_setting("dev", "scenario", "res://data/scenarios/lab_default.tres"))
	)
	var seed_v := int(Config.get_setting("dev", "seed", scenario.default_seed))
	world = ScenarioLoader.build_world(scenario, seed_v, bitgrid)
	# Lowest-intended-speed loadout is a first-class preset (§2.10,
	# CORE-53): setup-phase config, never a replay-dirtying edit — it
	# lands in the replay header's speed snapshot.
	var preset := clampf(float(Config.get_setting("dev", "speed_preset", 4.0)), 3.0, 5.5)
	world.players[0].move_speed = preset

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

	var hazards_view := HazardView.new()
	hazards_view.world = world
	add_child(hazards_view)

	hitboxes = HitboxView.new()
	hitboxes.world = world
	hitboxes.visible = bool(Config.get_setting("ui", "hitboxes", false))
	add_child(hitboxes)

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

	feedback_settings = {
		"impact": bool(Config.get_setting("feedback", "impact", true)),
		"kill": bool(Config.get_setting("feedback", "kill", true)),
		"blocked": bool(Config.get_setting("feedback", "blocked", true)),
		"damage_numbers":
		int(Config.get_setting("feedback", "damage_numbers", DamageNumberView.Mode.FULL)),
	}

	var flashes := FlashView.new()
	flashes.driver = driver
	flashes.settings = feedback_settings
	add_child(flashes)

	var dmg_numbers := DamageNumberView.new()
	dmg_numbers.driver = driver
	dmg_numbers.settings = feedback_settings
	add_child(dmg_numbers)

	density_meter = DensityMeter.new()
	density_meter.world = world
	density_meter.budgets = load("res://data/budgets.tres")
	density_meter.effects_counter = func() -> int:
		return flashes.active_count() + dmg_numbers.active_count()
	density_meter.visible = false
	density_meter.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	# Right-anchored: must grow LEFT as content sizes it, or it runs off
	# the screen edge.
	density_meter.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	density_meter.offset_right = -4.0
	density_meter.offset_top = 16.0

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
	# Autofire indicator reads SIM state (§2.8) — the latch, not the key.
	# Kit icons: ON/OFF differ by shape, not color (CORE-50).
	autofire_icon = TextureRect.new()
	autofire_icon.texture = load("res://uikit/icon_autofire_off.png")
	autofire_icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	autofire_icon.position = Vector2(4.0, 4.0)
	weapon_label = Label.new()
	weapon_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	# Bottom-left HUD column: container-managed so nothing can clip off
	# the screen edge (a hand-offset label did exactly that once).
	hp_bar = StatBar.new()
	hp_bar.frame_box = _bar_frame_box()
	hp_bar.fill_tex = load("res://uikit/bar_fill_hp.png")
	hp_bar.custom_minimum_size = Vector2(64.0, 8.0)
	mana_bar = StatBar.new()
	mana_bar.frame_box = _bar_frame_box()
	mana_bar.fill_tex = load("res://uikit/bar_fill_mana.png")
	mana_bar.custom_minimum_size = Vector2(64.0, 8.0)
	ability_label = Label.new()
	hud_stack = VBoxContainer.new()
	hud_stack.add_theme_constant_override("separation", 2)
	hud_stack.add_child(ability_label)
	hud_stack.add_child(hp_bar)
	hud_stack.add_child(mana_bar)
	hud_stack.add_child(speed_label)
	hud_stack.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hud_stack.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hud_stack.offset_left = 4.0
	hud_stack.offset_bottom = -4.0
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
	hud.add_child(hud_stack)
	hud.add_child(autofire_icon)
	hud.add_child(weapon_label)
	hud.add_child(rec_label)
	hud.add_child(hints_label)
	hud.add_child(density_meter)
	hud.add_child(options_menu)
	recap_panel = RecapPanel.new()
	hud.add_child(recap_panel)
	console = DebugConsole.new()
	console.line_submitted.connect(_console_exec)
	hud.add_child(console)
	add_child(hud)
	Input.set_custom_mouse_cursor(
		load("res://uikit/cursor_crosshair.png"), Input.CURSOR_ARROW, Vector2(5.0, 5.0)
	)
	driver.pause_changed.connect(func(p: bool) -> void: pause_label.visible = p)
	options_menu.add_button_row(
		"ability",
		["Nova", "Quickdraw", "Rune"],
		func(i: int) -> void:
			world.enqueue_command({"type": SimWorld.Command.SET_ABILITY, "index": i})
	)
	options_menu.add_toggle_row(
		"impact flashes",
		bool(feedback_settings.impact),
		func(v: bool) -> void:
			feedback_settings.impact = v
			Config.set_setting("feedback", "impact", v)
	)
	options_menu.add_toggle_row(
		"kill flashes",
		bool(feedback_settings.kill),
		func(v: bool) -> void:
			feedback_settings.kill = v
			Config.set_setting("feedback", "kill", v)
	)
	options_menu.add_toggle_row(
		"blocked markers",
		bool(feedback_settings.blocked),
		func(v: bool) -> void:
			feedback_settings.blocked = v
			Config.set_setting("feedback", "blocked", v)
	)
	options_menu.add_cycle_row(
		"dmg numbers",
		["off", "reduced", "full"],
		int(feedback_settings.damage_numbers),
		func(i: int) -> void:
			feedback_settings.damage_numbers = i
			Config.set_setting("feedback", "damage_numbers", i)
	)
	options_menu.add_toggle_row(
		"debug emitter (shoots you)",
		false,
		func(v: bool) -> void:
			world.enqueue_command(
				{"type": SimWorld.Command.TOGGLE_EMITTER, "on": v, "pos": Vector2(30.0, 12.0)}
			)
	)
	options_menu.add_cycle_row(
		"speed preset (on reset)",
		["4.0 baseline", "3.0 lowest"],
		1 if is_equal_approx(preset, 3.0) else 0,
		func(i: int) -> void:
			Config.set_setting("dev", "speed_preset", 3.0 if i == 1 else 4.0)
			print("speed preset persisted; applies on reset (T)")
	)
	var ui_scale := clampi(int(Config.get_setting("ui", "scale", 1)), 1, 2)
	options_menu.add_cycle_row(
		"ui scale",
		["x1", "x2"],
		ui_scale - 1,
		func(i: int) -> void:
			Config.set_setting("ui", "scale", i + 1)
			_apply_ui_scale(i + 1)
	)
	_apply_ui_scale(ui_scale)
	# Persisted window mode (§2.13): fullscreen is the project default;
	# honor a saved windowed preference.
	if not bool(Config.get_setting("ui", "fullscreen", true)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_refresh_hints()

	var recap := RecapTracker.new()
	recap.driver = driver
	recap.world = world
	add_child(recap)
	recap.recap_ready.connect(
		func(r: Dictionary) -> void:
			driver.paused = true
			recap_panel.show_recap(r, Config.binding_text("scenario_reset"))
	)

	print(
		(
			"arena ready: %dx%d, %d solid cells, %d placements, scenario=%s seed=%d speed=%.1f"
			% [
				int(def.width),
				int(def.height),
				bitgrid.solid_count(),
				int(arena.placements),
				String(scenario.id),
				world.run_seed,
				world.players[0].move_speed,
			]
		)
	)
