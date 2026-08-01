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
const MusicView := preload("res://game/views/music_view.gd")
const DropView := preload("res://game/views/drop_view.gd")
const Progress := preload("res://sim/systems/progress.gd")
const StatBar := preload("res://ui/stat_bar.gd")
const DensityMeter := preload("res://ui/density_meter.gd")
const HazardView := preload("res://game/views/hazard_view.gd")
const DamageNumberView := preload("res://game/views/damage_number_view.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const RecapTracker := preload("res://game/drivers/recap_tracker.gd")
const SessionLog := preload("res://game/drivers/session_log.gd")
const FeedbackBundle := preload("res://game/drivers/feedback_bundle.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")
const CharacterCreate := preload("res://ui/character_create.gd")
const RecapPanel := preload("res://ui/recap_panel.gd")
const OnboardingScreen := preload("res://ui/onboarding_screen.gd")
const Core50Verify := preload("res://game/dev/core50_verify.gd")
const MapOverlay := preload("res://game/dev/map_overlay.gd")
const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
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
## Loop v1 HUD line: level/xp/gold + the minimal equip surface.
var loot_label: Label
var options_menu: PanelContainer
var density_meter: PanelContainer
var hints_label: Label
var gif_recorder: Node
var rec_label: Label
var toast_label: Label
var _toast_gen := 0
var onboarding: PanelContainer
var session_log: Node
## Once per app run, not per scene build — a T reset never re-shows it.
static var _onboarding_shown := false
var feedback_settings: Dictionary = {}
## M8 comments box (options menu): read at bundle time; focus drives
## typing suppression and the box-owned pause.
var comments_box: TextEdit = null
var _comments_paused := false
## Loop v1 persistent character (docs/19): {} = none — the creation
## screen owns the next step. Applied to the world setup-phase.
var character: Dictionary = {}
var character_panel: PanelContainer = null
var _char_save_accum := 0.0
## EffectLibrary policy object (M6, ledger #9) — cosmetic/friendly
## channels only; hostile paths never hold a reference (§2.6 clamp).
var effects_lib: RefCounted = null

## Options presets for the CORE-50 effect scaler (index persisted).
const EFFECT_DENSITY_LEVELS: Array[float] = [1.0, 0.66, 0.33]
const EFFECT_OPACITY_LEVELS: Array[float] = [1.0, 0.7, 0.4]

## Per-channel audio (CORE-50: separate channels, key threats audible;
## Law 7). Linear levels per options index; audio/<bus> persists.
## Music (M8) is its own channel like the rest — the duck lives in
## music_view, never in the bus level the user set. AttackSfx (M8,
## designer-ruled) carries fire feedback ONLY, so attack noise can go
## to off without losing hit/death feedback (Sfx) or threats.
const AUDIO_LEVELS: Array[float] = [1.0, 0.7, 0.4, 0.0]
const AUDIO_BUSES: Array[String] = ["Master", "Sfx", "KeyThreats", "Music", "AttackSfx"]
var recap_panel: PanelContainer
var console: PanelContainer
## sl-0065 dev world-map overlay (pack minimap + player dot). Null in
## tester builds (gated construction, lint-pinned) AND for scenarios
## whose pack ships no minimap.png — hidden by absence, not by flag.
var map_overlay: Control = null
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
var _crosshair_scale := 0


func _notification(what: int) -> void:
	# Loop v1: clean-quit character save (alive only — the death flow
	# already saved the cost-applied profile).
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not character.is_empty():
		if world != null and not world.players.is_empty() and not world.players[0].dead:
			CharacterProfile.harvest(world, character)
			CharacterProfile.save_profile(character)


## bar_frame stylebox from the kit manifest (margins 2,2,2,2).
static func _bar_frame_box() -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://uikit/bar_frame.png")
	sb.texture_margin_left = 2.0
	sb.texture_margin_top = 2.0
	sb.texture_margin_right = 2.0
	sb.texture_margin_bottom = 2.0
	return sb


## sl-0065: the active pack's own minimap.png, resolved pack-relative
## (same exe-relative fallback as every other pack read). Empty when
## the scenario is arena-built; a pack missing the file fails the
## overlay's load — hidden by absence either way. If minimap
## resolution ever proves insufficient on screen, that is a WorldForge
## ask, never a game-side upscale hack.
static func _scenario_minimap_path(scenario: Resource) -> String:
	var pack := String(scenario.worldforge_pack)
	return "" if pack.is_empty() else WorldforgePack.resolve_src(pack) + "minimap.png"


func _process(_delta: float) -> void:
	# M8 comments box: while it has keyboard focus, letter hotkeys and
	# gameplay input are suppressed — a 't' mid-sentence must never
	# reset the scene, WASD must not move the player (the sampler sends
	# neutral frames). Esc still reaches the driver's pause toggle by
	# design: leaving the box and resuming are the same key.
	var typing := comments_box != null and comments_box.has_focus()
	if driver != null and driver.sampler != null:
		driver.sampler.suppress = typing
	# §2.9 prev/curr render toggle — view-side only, replay-irrelevant.
	if not typing and view_clock != null and Input.is_action_just_pressed("interp_toggle"):
		view_clock.interp_enabled = not view_clock.interp_enabled
		print("render interpolation: ", "ON" if view_clock.interp_enabled else "OFF (snap)")
	if not typing and options_menu != null and Input.is_action_just_pressed("options_toggle"):
		options_menu.toggle()
		_refresh_hints()
	if not typing and density_meter != null and Input.is_action_just_pressed("density_toggle"):
		density_meter.visible = not density_meter.visible
	# One-key reseeding reset (§2.10): next seed persisted + logged, full
	# scene rebuild — no ref-swapping, no stale state.
	if not typing and world != null and Input.is_action_just_pressed("scenario_reset"):
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
	# Loop v1: periodic character save (30 s wall; death/quit save
	# elsewhere) — a crash costs at most the last beat. Never while dead:
	# the death flow already saved the COST-APPLIED profile, and a
	# harvest here would resurrect the pre-cost gold.
	if not character.is_empty() and world != null and not world.players.is_empty():
		if not world.players[0].dead:
			_char_save_accum += _delta
			if _char_save_accum >= 30.0:
				_char_save_accum = 0.0
				CharacterProfile.harvest(world, character)
				CharacterProfile.save_profile(character)
	if not typing and console != null and Input.is_action_just_pressed("console_toggle"):
		console.toggle()
	if not typing and hitboxes != null and Input.is_action_just_pressed("hitbox_toggle"):
		hitboxes.visible = not hitboxes.visible
		Config.set_setting("ui", "hitboxes", hitboxes.visible)
	# sl-0065 dev world map: one key cycles off -> corner minimap ->
	# fullscreen. The overlay only exists when the active pack ships a
	# minimap.png; on pack-less scenarios the key is quietly inert.
	if dev_tools and not typing and Input.is_action_just_pressed("map_toggle"):
		if map_overlay != null:
			map_overlay.cycle()
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
	if not typing and Input.is_action_just_pressed("debug_speed_lowest"):
		_set_speed(3.0)
	elif not typing and Input.is_action_just_pressed("debug_speed_baseline"):
		_set_speed(4.0)
	elif dev_tools and not typing and Input.is_action_just_pressed("debug_speed_down"):
		_set_speed(snappedf(cur - 0.1, 0.1))
	elif dev_tools and not typing and Input.is_action_just_pressed("debug_speed_up"):
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
	# Loop v1 HUD (docs/19): level/xp/gold + the minimal equip surface.
	(
		loot_label
		. set_text(
			(
				"lv %d  xp %d/%d  gold %d\nbolt T%d · scatter T%d · wheel T%d · armor T%d"
				% [
					p.level,
					p.xp,
					Progress.xp_to_next(world, p.level),
					p.gold,
					p.weapon_tiers[0],
					p.weapon_tiers[1],
					p.weapon_tiers[2],
					p.armor_tier,
				]
			)
		)
	)
	# Loop moments worth a toast: level-ups + unique pickups.
	for lev: Dictionary in driver.frame_events:
		match int(lev.type):
			SimEvents.Type.LEVEL_UP:
				_show_toast("LEVEL %d" % int(lev.level))
			SimEvents.Type.LOOT_PICKED:
				if int(lev.kind) == SimWorld.DROP_UNIQUE and int(lev.a) < world.unique_defs.size():
					var ud: Resource = world.unique_defs[int(lev.a)]
					_show_toast("UNIQUE: %s" % String(ud.display_name))
	# F10: dump the always-on session recording. NOTE: the main scene is a
	# hardcoded dev scenario until M4 — saved replays verify only against
	# the same build (no scenario id exists for it yet); golden fixtures
	# use the registered scenario path.
	if not typing and Input.is_action_just_pressed("replay_save") and driver.recorder != null:
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


## Idempotent creation of the four named buses (Law 7 / CORE-50): Sfx,
## KeyThreats, Music, and AttackSfx (M8), all sending to Master.
## Code-created so headless runs and tests need no bus-layout resource.
func _ensure_audio_buses() -> void:
	for bus_name: String in ["Sfx", "KeyThreats", "Music", "AttackSfx"]:
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


func _apply_crosshair_scale() -> void:
	# The uikit crosshair is a HARDWARE cursor: 11 px drawn at native
	# pixel size in window space, so it never inherits the integer
	# viewport stretch and reads as a speck at gameplay scale. Scale the
	# texture by the live content scale instead (nearest-neighbor, kit
	# hotspot 5,5 scaled to the same pixel center) and re-apply whenever
	# the window scale changes. Render-only: aim math reads the viewport
	# mouse position and never touches the cursor bitmap.
	var win := get_window()
	var base_w := float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var base_h := float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var k := maxi(1, int(minf(float(win.size.x) / base_w, float(win.size.y) / base_h)))
	if k == _crosshair_scale:
		return
	_crosshair_scale = k
	var tex := load("res://uikit/cursor_crosshair.png") as Texture2D
	var img := tex.get_image()
	img.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	var pad := floorf(float(k - 1) * 0.5)
	var hot := 5.0 * float(k) + pad
	Input.set_custom_mouse_cursor(
		ImageTexture.create_from_image(img), Input.CURSOR_ARROW, Vector2(hot, hot)
	)


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
	# sl-0065: the map hint only when the overlay actually exists (dev
	# profile + a pack that ships a minimap) — the hints line stays
	# honest on arena scenarios and in tester builds.
	if map_overlay != null:
		parts.append("%s map" % Config.binding_text("map_toggle"))
	hints_label.text = "  ".join(parts)


func _set_speed(speed: float) -> void:
	world.enqueue_command({"type": SimWorld.Command.SET_MOVE_SPEED, "player": 0, "speed": speed})
	print(
		(
			"speed editor: requested %.1f t/s (band %.1f-%.1f; run now replay-dirty)"
			% [speed, SimWorld.MOVE_SPEED_MIN, SimWorld.MOVE_SPEED_MAX]
		)
	)


## Loop v1 (docs/19 ruling 1): the new-character screen — the ONLY
## place permadeath is chosen. Buttons are the only unpause path
## (CORE-31 pause_locked, the onboarding pattern).
func _maybe_show_character_create(pl: Label) -> void:
	if not character.is_empty():
		return
	character_panel = CharacterCreate.new()
	hud_stack.get_parent().add_child(character_panel)
	driver.paused = true
	driver.pause_locked = true
	pl.visible = false
	# Member-held panel + self-capturing lambda only — a local capture
	# here makes a Callable/signal reference cycle that leaks at exit.
	character_panel.chosen.connect(
		func(hardcore: bool) -> void:
			character = CharacterProfile.create(hardcore)
			character.runs = 1
			CharacterProfile.save_profile(character)
			CharacterProfile.apply_to_world(world, character)
			driver.pause_locked = false
			driver.paused = false
			character_panel.queue_free()
			character_panel = null
	)


## Loop v1 death bookkeeping (docs/19 ruling 1) — once per death, on
## the recap. Hardcore: the character file dies with the character and
## the reset key lands on the new-character screen. Normal: harvest,
## gold percentage cost ([T]), save — equipment never taken. Retry
## stays ONE key; the run-back is the rest of the price.
func _on_player_death() -> void:
	if character.is_empty():
		return
	if bool(character.get("hardcore", false)):
		CharacterProfile.delete_profile()
		character = {}
		_show_toast(
			(
				"HARDCORE DEATH — character gone. %s starts a new one."
				% Config.binding_text("scenario_reset")
			)
		)
		return
	CharacterProfile.harvest(world, character)
	var lost: int = CharacterProfile.apply_death_cost(character, world.progression)
	character.deaths = int(character.get("deaths", 0)) + 1
	CharacterProfile.save_profile(character)
	_show_toast("death: %d gold lost. %s retries." % [lost, Config.binding_text("scenario_reset")])


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
	# CORE-50 runtime-verification CLI (M8): dev-gated like --audit. A
	# known profile repoints the Config autoload at an injected settings
	# file BEFORE any wiring reads it (the real settings.cfg is never
	# touched); the end of _ready asserts the wired state and quits.
	var verify_arg := BootArgs.get_arg("verify")
	var verify_mode := dev_tools and Core50Verify.inject_if_known(verify_arg)

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

	# Loop v1 (docs/19): the persistent character rides every world the
	# player actually plays; audit/verify runs stay profile-free. Applied
	# BEFORE the recorder snapshots initial state, so replay headers are
	# honest about what actually ran.
	if not (audit_mode or verify_mode):
		character = CharacterProfile.load_profile()
		if not character.is_empty():
			CharacterProfile.apply_to_world(world, character)
			character.runs = int(character.get("runs", 0)) + 1
			CharacterProfile.save_profile(character)

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

	# Loop v1 ground drops (docs/19): quiet shapes on the LOOT band.
	var drops_view := DropView.new()
	drops_view.world = world
	add_child(drops_view)

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
		# Loop v1 boss library (docs/19 ruling 4): same class, 48 px
		# manifest; consulted for actor ids the 24 px pack lacks.
		if FileAccess.file_exists("res://assembler_boss/manifest.json"):
			var lib_boss := AssemblerLibrary.new()
			lib_boss.manifest_path = "res://assembler_boss/manifest.json"
			lib_boss.sheet_root = "res://assembler_boss/"
			if lib_boss.load_manifest():
				enemy_actors.lib_boss = lib_boss
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

	# M8 music (designer-ruled 2026-07-30): queue-on-loop playlist on
	# the Music bus, ducking under KeyThreats cues so Law 7's threat
	# channel stays on top of the mix. The playlist is EMPTY until the
	# Resonance Forge pack intake fills it — silent no-op until then.
	var music := MusicView.new()
	music.playlist = load("res://data/music_playlist.tres")
	music.cue_view = cue_view
	add_child(music)

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
	loot_label = Label.new()
	hud_stack = VBoxContainer.new()
	hud_stack.add_theme_constant_override("separation", 2)
	hud_stack.add_child(ability_label)
	hud_stack.add_child(hp_bar)
	hud_stack.add_child(mana_bar)
	hud_stack.add_child(loot_label)
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
	# sl-0065 dev world-map overlay: the pack's own minimap.png + player
	# dot (raw texture, zero new art). Added BELOW options/recap/console
	# in the child order so a fullscreen map never buries an open menu
	# or a death recap. Scenarios without a pack minimap simply never
	# get the node (the map key stays inert); tester builds never
	# construct it (one-flag gate, lint-pinned like the console).
	if dev_tools:
		map_overlay = MapOverlay.new()
		map_overlay.world = world
		map_overlay.mouse_tile = driver.mouse_tile_provider
		map_overlay.grid_size = Vector2i(int(def.width), int(def.height))
		if map_overlay.load_minimap(_scenario_minimap_path(scenario)):
			hud.add_child(map_overlay)
		else:
			map_overlay.free()
			map_overlay = null
	hud.add_child(options_menu)
	recap_panel = RecapPanel.new()
	hud.add_child(recap_panel)
	if dev_tools:
		console = DebugConsole.new()
		console.line_submitted.connect(_console_exec)
		hud.add_child(console)
	add_child(hud)
	_apply_crosshair_scale()
	get_window().size_changed.connect(_apply_crosshair_scale)
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
	# M8 comments box (designer GO 2026-07-30): SUPPLEMENTARY side-notes
	# that ride inside the feedback bundle as comments.txt — quiet-lab
	# law says never CORE-54 evidence (that stays the unprompted
	# Discord/itch harvest). Focusing the box pauses the game (typing is
	# not a dodge test); leaving it releases only a pause the box itself
	# took — a recap or Esc pause is never stolen.
	comments_box = options_menu.add_comment_row(
		"comments (optional — saved with the bundle)", "anything you want the dev to read"
	)
	comments_box.focus_entered.connect(
		func() -> void:
			if not driver.paused:
				driver.paused = true
				_comments_paused = true
				pause_label.visible = true
	)
	comments_box.focus_exited.connect(
		func() -> void:
			if _comments_paused:
				_comments_paused = false
				if not driver.pause_locked:
					driver.paused = false
					pause_label.visible = false
	)
	# M8 feedback return path (tester-facing, ungated): zip the evidence
	# to the Desktop, reveal it, and show the summary code for testers
	# who will paste a code instead of returning a file.
	options_menu.add_button_row(
		"feedback",
		["save bundle"],
		func(_i: int) -> void:
			var result := FeedbackBundle.save_bundle(
				"", FeedbackBundle.SESSION_LOG, comments_box.text
			)
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
			_on_player_death()
	)

	# M8 re-engagement evidence: session start/heartbeat/end lines with
	# build id + wall clock (view-side; the sim never sees the clock).
	session_log = SessionLog.new()
	session_log.world = world
	session_log.dev_profile = dev_tools
	session_log.scenario_id = String(scenario.id)
	add_child(session_log)

	# M8 tester onboarding: once per app run, tester profile only — the
	# arena stays visible and fully paused behind it (CORE-31); Esc is
	# locked out until start so the overlay owns the only unpause path.
	if not dev_tools and not _onboarding_shown:
		onboarding = OnboardingScreen.new()
		onboarding.build_id = BuildInfo.BUILD_ID
		hud_stack.get_parent().add_child(onboarding)
		driver.paused = true
		driver.pause_locked = true
		pause_label.visible = false
		onboarding.start_pressed.connect(
			func(speed: float) -> void:
				_onboarding_shown = true
				_set_speed(speed)
				session_log.log_loadout(speed)
				driver.pause_locked = false
				driver.paused = false
				onboarding.queue_free()
				onboarding = null
				_maybe_show_character_create(pause_label)
		)

	# Loop v1 new-character screen (docs/19 ruling 1): whenever no
	# character exists — first boot, or the boot after a hardcore death.
	# Tester profile reaches it through the onboarding start press above.
	if not (audit_mode or verify_mode) and (dev_tools or _onboarding_shown):
		_maybe_show_character_create(pause_label)

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

	# The CORE-50 verification run asserts AFTER every option is wired
	# (last thing in _ready) and exits with the verdict.
	if verify_mode:
		var vfails := Core50Verify.verify(self, verify_arg)
		for msg: String in vfails:
			push_error("core50: " + msg)
		print("core50 verify (%s): %s" % [verify_arg, "PASS" if vfails.is_empty() else "FAIL"])
		get_tree().quit(0 if vfails.is_empty() else 1)
