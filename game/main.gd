extends Node2D
## Phase A lab main scene (M3 state): arena + bitgrid from one definition,
## SimWorld with the three weapon frames and target-practice stand-ins,
## RealtimeDriver + HumanSampler, player rendering from its Sprite Forge
## sheet, per-faction projectile rendering, corner-snag logging, and the
## HUD's autofire/weapon/speed readouts. Scenario picker and the full
## debug layer land at M4.

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const WorldBuilder := preload("res://game/arena/world_builder.gd")
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
const EffectLibrary := preload("res://game/views/effect_library.gd")
const AudioCueView := preload("res://game/views/audio_cue_view.gd")
const StatBar := preload("res://ui/stat_bar.gd")
const DensityMeter := preload("res://ui/density_meter.gd")
const HazardView := preload("res://game/views/hazard_view.gd")
const DamageNumberView := preload("res://game/views/damage_number_view.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const RecapTracker := preload("res://game/drivers/recap_tracker.gd")
const SessionLog := preload("res://game/drivers/session_log.gd")
const FeedbackBundle := preload("res://game/drivers/feedback_bundle.gd")
const RecapPanel := preload("res://ui/recap_panel.gd")
const DebugConsole := preload("res://ui/debug_console.gd")
const BuildInfo := preload("res://build_info.gd")
const HitboxView := preload("res://game/views/hitbox_view.gd")
const SimEvents := preload("res://sim/events.gd")
const RenderLayers := preload("res://game/render_layers.gd")
const AssemblerLibrary := preload("res://game/views/assembler_library.gd")
const AnimatedActor := preload("res://game/views/animated_actor.gd")
const ProjectileSprites := preload("res://game/views/projectile_sprites.gd")

const ViewClock := preload("res://game/views/view_clock.gd")
const CameraRig := preload("res://game/views/camera_rig.gd")
const ProjectileView := preload("res://game/views/projectile_view.gd")
const StandinView := preload("res://game/views/standin_view.gd")
const EnemyActorsView := preload("res://game/views/enemy_actors_view.gd")
const HpBarView := preload("res://game/views/hp_bar_view.gd")
const DodgeProof := preload("res://game/bots/dodge_proof.gd")
const AuditSampler := preload("res://game/bots/audit_sampler.gd")

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
var toast_label: Label
var _toast_gen := 0
var feedback_settings: Dictionary = {}
## EffectLibrary policy object (M6, ledger #9) — cosmetic/friendly
## channels only; hostile paths never hold a reference (§2.6 clamp).
var effects_lib: RefCounted = null

## Options presets for the CORE-50 effect scaler (index persisted).
const EFFECT_DENSITY_LEVELS: Array[float] = [1.0, 0.66, 0.33]
const EFFECT_OPACITY_LEVELS: Array[float] = [1.0, 0.7, 0.4]

## Per-channel audio (CORE-50: separate channels, key threats audible;
## Law 7). Linear levels per options index; audio/<bus> persists.
const AUDIO_LEVELS: Array[float] = [1.0, 0.7, 0.4, 0.0]
const AUDIO_BUSES: Array[String] = ["Master", "Sfx", "KeyThreats"]
var recap_panel: PanelContainer
var console: PanelContainer
var hitboxes: Node2D
var hud_stack: VBoxContainer
var _console_events := "off"
## §2.10 tester-profile gate (M7): tester exports carry the custom
## feature tag "tester" (export preset) and lose every sim-mutating dev
## tool through this ONE flag — debug console (god/slow-mo/verdict ride
## inside it), free speed steps, CLI bot/audit modes. Speed PRESETS
## ([ / ]) stay: lowest-speed is tester-facing by design (§2.10).
## Defense in depth: replay-dirty stamps + telemetry flags stay live
## regardless of the gate.
var dev_tools: bool = not OS.has_feature("tester")
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
	elif dev_tools and Input.is_action_just_pressed("debug_speed_down"):
		_set_speed(snappedf(cur - 0.1, 0.1))
	elif dev_tools and Input.is_action_just_pressed("debug_speed_up"):
		_set_speed(snappedf(cur + 0.1, 0.1))
	speed_label.text = (
		"%d fps   spikes %d   speed %.1f t/s%s%s"
		% [
			Engine.get_frames_per_second(),
			driver.spike_count,
			cur,
			"   REPLAY-DIRTY" if world.replay_dirty else "",
			"" if dev_tools else "   " + BuildInfo.BUILD_ID,
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


## Stress-density screenshot audit (M5 Laws 1/2; M6 9-row max + min
## variants): let the scripted run reach peak density — past the
## Blightcasters' first cast-arm cycle so armed zones sit under the VFX
## pile — then capture the frame to reports/. Legibility is judged by
## eyes on the PNG — this produces the evidence.
func _run_density_audit(out_name: String) -> void:
	while world.tick < 420:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	img.save_png(ProjectSettings.globalize_path("res://reports/" + out_name))
	print(
		(
			"density audit captured: reports/%s (tick %d, %d live hostiles)"
			% [out_name, world.tick, world.enemies.size()]
		)
	)
	get_tree().quit()


## Idempotent creation of the two named buses (Law 7 / CORE-50): Sfx and
## KeyThreats, both sending to Master. Code-created so headless runs and
## tests need no bus-layout resource.
func _ensure_audio_buses() -> void:
	for bus_name: String in ["Sfx", "KeyThreats"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")


func _apply_audio_level(bus_name: String, level_index: int) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var lin: float = AUDIO_LEVELS[clampi(level_index, 0, AUDIO_LEVELS.size() - 1)]
	AudioServer.set_bus_mute(idx, lin <= 0.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(lin, 0.0001)))


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
			console.println("god | slowmo <1-10> | events <on|off|all> | reset")
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


## Transient HUD notice (12 s); later calls replace earlier ones.
func _show_toast(text: String) -> void:
	_toast_gen += 1
	var gen := _toast_gen
	toast_label.text = text
	toast_label.visible = true
	get_tree().create_timer(12.0).timeout.connect(
		func() -> void:
			if _toast_gen == gen:
				toast_label.visible = false
	)


func _ready() -> void:
	# §2.11 bot mode: the documented CLI (godot --headless -- --bot=...)
	# runs the proof core with zero presentation built, then exits with
	# the proof's status code.
	if dev_tools and BootArgs.get_arg("bot") == "dodge_proof":
		get_tree().quit(DodgeProof.run_from_args(BootArgs.args))
		return
	# §2.5 load-time band assertions (M5): boot fails loudly on a Laws-1/2
	# ordering violation; the boot gate greps for the error.
	if not RenderLayers.assert_bands():
		push_error("main: render band audit FAILED")

	# InputMap defaults + saved remaps are applied by the Config autoload
	# before any scene _ready runs. Scenario + seed + speed preset come
	# from persisted dev settings; T rebuilds with the next seed. The
	# scenario names its arena (visuals + collision from one definition).
	# --audit=density (M5): fixed stress scenario + scripted max-VFX input
	# + a Laws-1/2 screenshot to reports/ — persisted settings untouched.
	# --audit=density_min (M6 9-row): the same run with every cosmetic/
	# friendly option forced to its LOWEST setting — the capture proves
	# hostile channels stay fully visible when the player dials down.
	var audit_arg := BootArgs.get_arg("audit")
	var audit_mode := dev_tools and (audit_arg == "density" or audit_arg == "density_min")
	# Gate carried locally so the lockdown lint can prove it by grep —
	# every use site also nests under audit_mode, but the flag itself
	# must not depend on that staying true.
	var audit_min := audit_mode and audit_arg == "density_min"
	var scenario: Resource = load(
		(
			"res://tests/bot_scenarios/audit_density.tres"
			if audit_mode
			else String(
				Config.get_setting("dev", "scenario", "res://data/scenarios/first_contact.tres")
			)
		)
	)
	var seed_v := int(Config.get_setting("dev", "seed", scenario.default_seed))
	if audit_mode:
		seed_v = int(scenario.default_seed)
	# Arena source: a WorldForge game pack when the scenario names one
	# (generated-test-arena ruling), else the arena-def builder.
	var arena: Dictionary
	if not String(scenario.worldforge_pack).is_empty():
		arena = WorldBuilder.build_world_arena(self, String(scenario.worldforge_pack))
	else:
		arena = ArenaBuilder.build_arena(self, String(scenario.arena))
	if arena.is_empty():
		return
	var def: Dictionary = arena.def
	bitgrid = arena.bitgrid
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

	# Projectile-pack sprites (M-FX curation): mapped patterns render
	# their pack art; everything else keeps the honest sphere fallback.
	var proj_sprites := ProjectileSprites.new()
	if not proj_sprites.load_manifest():
		proj_sprites = null
	var proj_map: Resource = load("res://data/projectile_map.tres")

	# EffectLibrary (M6 ledger #9): CORE-50 density/opacity/flash-
	# reduction on cosmetic + friendly channels only. Hostile views never
	# receive the reference (§2.6 structural clamp). The audit forces
	# full so Laws 1/2 are stressed against maximum player noise.
	effects_lib = EffectLibrary.new()
	if not audit_mode:
		var di := clampi(int(Config.get_setting("effects", "density", 0)), 0, 2)
		var oi := clampi(int(Config.get_setting("effects", "opacity", 0)), 0, 2)
		effects_lib.density = EFFECT_DENSITY_LEVELS[di]
		effects_lib.opacity = EFFECT_OPACITY_LEVELS[oi]
		effects_lib.flash_reduction = bool(Config.get_setting("effects", "flash_reduction", false))
	elif audit_min:
		# Minimum-density render pass (M6 9-row): everything the player
		# CAN dial down IS dialed down; the hostile clamp is what the
		# capture demonstrates.
		effects_lib.density = EFFECT_DENSITY_LEVELS[2]
		effects_lib.opacity = EFFECT_OPACITY_LEVELS[2]
		effects_lib.flash_reduction = true

	var standins := StandinView.new()
	standins.world = world
	add_child(standins)

	# §2.5 split (M6): friendly zones whole at FRIENDLY_GROUND; hostile
	# zones as fill (grounding) + rim/arm ring (the warning, Law 1).
	# Only the FRIENDLY instance holds the EffectLibrary reference — the
	# hostile fill/rim instances structurally cannot dim (§2.6).
	for hz_mode: int in [
		HazardView.Mode.FRIENDLY, HazardView.Mode.HOSTILE_FILL, HazardView.Mode.HOSTILE_RIM
	]:
		var hazards_view := HazardView.new()
		hazards_view.world = world
		hazards_view.sprites = proj_sprites
		hazards_view.pattern_map = proj_map
		hazards_view.mode = hz_mode
		if hz_mode == HazardView.Mode.FRIENDLY:
			hazards_view.effects = effects_lib
		add_child(hazards_view)

	hitboxes = HitboxView.new()
	hitboxes.world = world
	hitboxes.visible = bool(Config.get_setting("ui", "hitboxes", false))
	add_child(hitboxes)

	# Cities-open ruling (2026-07-29): actors and the world's vertical
	# layers (structures/props/fence/wall) share ONE y-sort space at the
	# ACTORS band — a house in front of you draws over you, one behind
	# draws behind — so the reopened between-house gaps read as depth.
	# CANOPY (32) and every combat band (40+) sit above the space; the
	# §2.5 ordering is untouched (boot asserts still govern).
	var actor_space := Node2D.new()
	actor_space.name = "ActorSortSpace"
	actor_space.y_sort_enabled = true
	add_child(actor_space)
	for sl: Node2D in arena.get("sort_layers", []):
		sl.reparent(actor_space)

	# Actor source: the assembler pack (§2.14 Amendment v2, docs/14).
	var lib := AssemblerLibrary.new()
	var lib_ok := lib.load_manifest()
	var sheet_map: Resource = load("res://data/actor_sheet_map.tres")
	if lib_ok and sheet_map != null and lib.has_actor(String(sheet_map.map.player)):
		var av := AnimatedActor.new()
		av.sprite_frames = lib.build_sprite_frames(String(sheet_map.map.player))
		av.actor = world.players[0]
		av.clock = view_clock
		av.render_scale = lib.render_scale()
		av.play("idle-down")
		actor_space.add_child(av)
	else:
		push_error("main: player sheet unavailable — run the assembler importer")

	# Real enemies: assembler sheets + overhead HP bars (M5; CORE-35 —
	# general presentation, no targeting anything).
	if lib_ok:
		var enemy_actors := EnemyActorsView.new()
		enemy_actors.world = world
		enemy_actors.clock = view_clock
		enemy_actors.driver = driver
		enemy_actors.lib = lib
		enemy_actors.sheet_map = sheet_map
		enemy_actors.y_sort_enabled = true
		actor_space.add_child(enemy_actors)
	var hp_bars := HpBarView.new()
	hp_bars.world = world
	hp_bars.clock = view_clock
	add_child(hp_bars)

	var pv := ProjectileView.new()
	pv.world = world
	pv.clock = view_clock
	pv.sprites = proj_sprites
	pv.pattern_map = proj_map
	pv.effects = effects_lib
	add_child(pv)

	feedback_settings = {
		"impact": bool(Config.get_setting("feedback", "impact", true)),
		"kill": bool(Config.get_setting("feedback", "kill", true)),
		"blocked": bool(Config.get_setting("feedback", "blocked", true)),
		"damage_numbers":
		int(Config.get_setting("feedback", "damage_numbers", DamageNumberView.Mode.FULL)),
	}
	if audit_mode:
		# The audit maxes every player-side channel (Laws 1/2 stress how
		# hostile fire reads ABOVE all of it) without touching settings.cfg.
		feedback_settings.impact = true
		feedback_settings.kill = true
		feedback_settings.blocked = true
		feedback_settings.damage_numbers = DamageNumberView.Mode.FULL
		if audit_min:
			# The everything-down accessibility configuration.
			feedback_settings.damage_numbers = DamageNumberView.Mode.REDUCED

	var flashes := FlashView.new()
	flashes.driver = driver
	flashes.world = world
	flashes.settings = feedback_settings
	flashes.effects = effects_lib
	flashes.sprites = proj_sprites
	flashes.pattern_map = proj_map
	add_child(flashes)

	# Law-7 audio: Sfx + KeyThreats buses (the eyes-closed threat channel
	# stays separate — CORE-50), saved per-channel volumes applied, cue
	# view consuming the same event relay as every other view.
	_ensure_audio_buses()
	for bi in AUDIO_BUSES.size():
		_apply_audio_level(
			AUDIO_BUSES[bi],
			clampi(int(Config.get_setting("audio", AUDIO_BUSES[bi].to_lower(), 0)), 0, 3)
		)
	var cue_view := AudioCueView.new()
	cue_view.driver = driver
	cue_view.world = world
	cue_view.cue_map = load("res://data/audio_cue_map.tres")
	cue_view.pattern_map = proj_map
	add_child(cue_view)

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
	# Transient notice line (bundle saved / summary code); auto-hides.
	toast_label = Label.new()
	toast_label.visible = false
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_top = 24.0
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
	hud.add_child(toast_label)
	hud.add_child(hints_label)
	hud.add_child(density_meter)
	hud.add_child(options_menu)
	recap_panel = RecapPanel.new()
	hud.add_child(recap_panel)
	if dev_tools:
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
	options_menu.add_cycle_row(
		"effect density",
		["full", "reduced", "minimal"],
		clampi(int(Config.get_setting("effects", "density", 0)), 0, 2),
		func(i: int) -> void:
			effects_lib.density = EFFECT_DENSITY_LEVELS[i]
			Config.set_setting("effects", "density", i)
	)
	options_menu.add_cycle_row(
		"effect opacity",
		["full", "dim", "faint"],
		clampi(int(Config.get_setting("effects", "opacity", 0)), 0, 2),
		func(i: int) -> void:
			effects_lib.opacity = EFFECT_OPACITY_LEVELS[i]
			Config.set_setting("effects", "opacity", i)
	)
	options_menu.add_toggle_row(
		"flash reduction",
		bool(effects_lib.flash_reduction),
		func(v: bool) -> void:
			effects_lib.flash_reduction = v
			Config.set_setting("effects", "flash_reduction", v)
	)
	for bus_name: String in AUDIO_BUSES:
		var bn := bus_name
		options_menu.add_cycle_row(
			"audio " + bn.to_lower(),
			["100%", "70%", "40%", "off"],
			clampi(int(Config.get_setting("audio", bn.to_lower(), 0)), 0, 3),
			func(i: int) -> void:
				_apply_audio_level(bn, i)
				Config.set_setting("audio", bn.to_lower(), i)
		)
	options_menu.add_cycle_row(
		"speed preset (on reset)",
		["4.0 baseline", "3.0 lowest"],
		1 if is_equal_approx(preset, 3.0) else 0,
		func(i: int) -> void:
			Config.set_setting("dev", "speed_preset", 3.0 if i == 1 else 4.0)
			print("speed preset persisted; applies on reset (T)")
	)
	# Scenario picker (§2.10): every .tres in data/scenarios, sorted for a
	# stable cycle order; choice persists and applies on reset (T).
	var scenario_paths: Array[String] = []
	var scenario_names: Array[String] = []
	for f in DirAccess.get_files_at("res://data/scenarios"):
		var fname := String(f).trim_suffix(".remap")
		if fname.ends_with(".tres"):
			scenario_paths.append("res://data/scenarios/" + fname)
	scenario_paths.sort()
	var scenario_idx := 0
	for i in scenario_paths.size():
		var sc: Resource = load(scenario_paths[i])
		scenario_names.append(String(sc.display_name))
		if String(sc.id) == String(scenario.id):
			scenario_idx = i
	options_menu.add_cycle_row(
		"scenario (on reset)",
		scenario_names,
		scenario_idx,
		func(i: int) -> void:
			Config.set_setting("dev", "scenario", scenario_paths[i])
			print("scenario persisted: %s; applies on reset (T)" % scenario_names[i])
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
	# M8 feedback return path (tester-facing, ungated): zip the evidence
	# to the Desktop, reveal it, and show the summary code for testers
	# who will paste a code instead of returning a file.
	options_menu.add_button_row(
		"feedback",
		["save bundle"],
		func(_i: int) -> void:
			var result := FeedbackBundle.save_bundle()
			if bool(result.ok):
				_show_toast(
					"feedback bundle saved to Desktop\nsummary code: %s" % String(result.code)
				)
				OS.shell_show_in_file_manager(String(result.path))
			else:
				_show_toast("bundle failed: %s" % String(result.error))
	)
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

	# M8 re-engagement evidence: session start/heartbeat/end lines with
	# build id + wall clock (view-side; the sim never sees the clock).
	var session := SessionLog.new()
	session.world = world
	session.dev_profile = dev_tools
	session.scenario_id = String(scenario.id)
	add_child(session)

	if audit_mode:
		driver.sampler = AuditSampler.new()
		# God keeps the player alive at ring center — absorbed hits log
		# DAMAGE_IMMUNE; the screenshot is the artifact, not the run.
		world.enqueue_command({"type": SimWorld.Command.SET_GOD, "on": true})
		density_meter.visible = true
		_run_density_audit("density_audit_m6_min.png" if audit_min else "density_audit_m6.png")

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
