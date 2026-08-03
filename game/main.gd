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
const CharacterSheet := preload("res://ui/character_sheet.gd")
const QuestOffer := preload("res://ui/quest_offer.gd")
const QuestTracker := preload("res://ui/quest_tracker.gd")
const QuestGiverIcons := preload("res://game/views/quest_giver_icons.gd")
const LootBagPanel := preload("res://ui/loot_bag_panel.gd")
const BankPanel := preload("res://ui/bank_panel.gd")
const VendorPanel := preload("res://ui/vendor_panel.gd")
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
const CrosshairStyles := preload("res://ui/crosshair_styles.gd")
const Core50Verify := preload("res://game/dev/core50_verify.gd")
const MapOverlay := preload("res://game/dev/map_overlay.gd")
const NpcView := preload("res://game/views/npc_view.gd")
const ContentImporter := preload("res://game/arena/content_importer.gd")
const IconAtlas := preload("res://ui/icon_atlas.gd")
const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const DebugConsole := preload("res://ui/debug_console.gd")
const BuildInfo := preload("res://build_info.gd")
const HitboxView := preload("res://game/views/hitbox_view.gd")
const SimEvents := preload("res://sim/events.gd")
const ItemText := preload("res://game/views/item_text.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")
const MenuPalette := preload("res://ui/menu_palette.gd")

## S1 seam 4 (sl-0104): dungeon doors — a LIVING character in a
## persistent world walking onto a door cell transitions via the
## scenario-reset path (profile harvested first; arrival spawns sit
## off the doors so return trips cannot ping-pong). The Warren's
## mouth is the ACCESS CELL of the content pack's LOCKED green
## dungeon binding (194,240 — the binding cell 193,239 is the
## giant-skeleton POI itself, solid by WYSIWYG); the ladder up is
## warren cell 2,2, landing back one cell east of the mouth.
## Player-facing (both profiles) — the dungeon IS content, not a
## dev tool.
const RIFT_EXIT_DOOR := {
	"cell": Vector2(1.5, 6.5),
	"to": "res://data/scenarios/slice_overworld.tres",
	"spawn": "",
	"label": "back through the rift to the shore...",
}
const DUNGEON_DOORS := {
	&"slice_overworld":
	[
		{
			"cell": Vector2(194.5, 240.5),
			"to": "res://data/scenarios/the_warren.tres",
			"spawn": "",
			"label": "descending into the Warren...",
		}
	],
	&"the_warren":
	[
		{
			"cell": Vector2(2.5, 2.5),
			"to": "res://data/scenarios/slice_overworld.tres",
			"spawn": "196.5,240.5",
			"label": "climbing back to daylight...",
		}
	],
	# STARHOOK (sl-0105; v2 by sl-0115): the rift's exit — the mouth
	# at (1,6) is the FLEE path (a won dive ends on the kill and
	# auto-returns); the spawn is dynamic (back where you cast;
	# rift_return). Six biome x rarity arenas share the one shape.
	&"rift_nebula_common": [RIFT_EXIT_DOOR],
	&"rift_nebula_rare": [RIFT_EXIT_DOOR],
	&"rift_void_common": [RIFT_EXIT_DOOR],
	&"rift_void_rare": [RIFT_EXIT_DOOR],
	&"rift_comet_common": [RIFT_EXIT_DOOR],
	&"rift_comet_rare": [RIFT_EXIT_DOOR],
}
const DOOR_RADIUS := 0.7
const RenderLayers := preload("res://game/render_layers.gd")
const AssemblerLibrary := preload("res://game/views/assembler_library.gd")
const AnimatedActor := preload("res://game/views/animated_actor.gd")
const ProjectileSprites := preload("res://game/views/projectile_sprites.gd")

const ViewClock := preload("res://game/views/view_clock.gd")
const CameraRig := preload("res://game/views/camera_rig.gd")
const RiftView := preload("res://game/views/rift_view.gd")
const RiftNodesView := preload("res://game/views/rift_nodes_view.gd")
const RiftWorldPane := preload("res://game/views/rift_world_pane.gd")
const RiftStep := preload("res://sim/systems/rift_step.gd")
const ProjectileView := preload("res://game/views/projectile_view.gd")
const StandinView := preload("res://game/views/standin_view.gd")
const EnemyActorsView := preload("res://game/views/enemy_actors_view.gd")
const HpBarView := preload("res://game/views/hp_bar_view.gd")
const DodgeProof := preload("res://game/bots/dodge_proof.gd")
const AuditSampler := preload("res://game/bots/audit_sampler.gd")

const TILE := 32.0

## Seam 4 [P]: class weapon archetype -> icon-pack glyph family (the
## tier suffix .tN completes the id). Families match the
## balance_frame sample items (arming sword / recurve bow /
## longstaff).
const ICON_WEAPON_FAMILIES := {
	"slow_heavy": "item.weapon.sword.arming",
	"fast_light": "item.weapon.bow.recurve",
	"long_reach": "item.weapon.staff.longstaff",
}

var bitgrid: RefCounted
var world: SimWorld
var driver: RealtimeDriver
var view_clock: ViewClock
var speed_label: Label
var autofire_icon: TextureRect
var weapon_label: Label
## Seam 4: the equipped weapon's icon-pack tier glyph (class lane).
var weapon_icon: TextureRect
var _weapon_icon_key := ""
var hp_bar: StatBar
var mana_bar: StatBar
var ability_label: Label
## Loop v1 HUD line: level/xp/gold + the minimal equip surface.
var loot_label: Label
var options_menu: Control
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
## CORE-43 (seam 3): whether the ACTIVE scenario is a persistent
## world — cached for the creation-screen path, which arms
## world.persistent_respawn after the class/mode choice.
var _scenario_persistent := false
## Active scenario id (S1 seam 4) — the door table keys on it.
var _scenario_id: StringName = &""
## STARHOOK (S1 seam 6, sl-0105; v2 by sl-0115): rift-fight flags.
var _scenario_rift := false
var _rift_won := false
## Tick the catch landed — the dive auto-ends after the linger
## (correction #7: the win is the kill; no walk to the door).
var _rift_won_tick := 0
const RIFT_WIN_LINGER_TICKS := 150
const RIFT_BIOME_KEYS: Array[String] = ["nebula", "void", "comet"]
## sl-0125: the world/galaxy split ratio is [T] and LIVE-FLIPPABLE —
## an options cycle row (both profiles, [ui] rift_split persisted).
## THE ARENA CELLS STAY IDENTICAL: only the pane anchors + the rift
## camera's fit change; the interior always fills its pane (Law 1 by
## construction at either ratio). The designer flips it in play and
## rules; the INDEX amends when they pick.
const RIFT_SPLIT_RATIOS: Array[float] = [0.5, 2.0 / 3.0]
const RIFT_SPLIT_NAMES: Array = ["half & half", "two-thirds galaxy"]
## Live refs for the re-anchor (empty outside rift scenarios).
var _rift_panes := {}
var _rift_cam: CameraRig = null
## The world frame captured at cast — the split-screen's world pane
## (presentation only; survives the scene reload).
static var _rift_capture: Image = null
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
## Seam B (sl-0109): the short top-right hp/mana stack.
var bars_stack: VBoxContainer
## Seam B (sl-0106): the read-only character sheet + quest log panel.
var char_sheet: Control = null
var quest_offer: Control = null
## sl-0121: the at-a-glance errand tracker (top-right, under the
## bars/minimap stack [T]); the C sheet stays THE one log.
var quest_tracker: Label = null
## sl-0129: the walk-over loot-bag panel (bottom-center).
var loot_panel: Control = null
## sl-0130: the walk-up bank panel (settlement stash).
var bank_panel: Control = null
## sl-0131: the walk-up vendor panel.
var vendor_panel: Control = null
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
## sl-0077 player options ([ui] crosshair_style / crosshair_size):
## applied cursor state, sentinel -1 so the first apply always fires.
## core50_verify asserts these against the injected profile.
var _crosshair_style := -1
var _crosshair_size := -1


func _notification(what: int) -> void:
	# Loop v1: clean-quit character save (alive only — the death flow
	# already saved the cost-applied profile).
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not character.is_empty():
		if world != null and not world.players.is_empty() and not world.players[0].dead:
			CharacterProfile.harvest(world, character)
			CharacterProfile.save_profile(character)
	if what == NOTIFICATION_EXIT_TREE:
		# 4.6.2 retains the applied custom cursor in two engine holders
		# that outlive RenderingServer teardown — every windowed close
		# then prints ~ImageTexture errors and leaks 2 Texture RIDs
		# (reproduced in an empty project on this exact binary; clearing
		# first exits clean). Tree teardown precedes server teardown on
		# every quit path, so this is the release window. Headless
		# no-ops.
		Input.set_custom_mouse_cursor(null)


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
		# sl-0128: the C pane sanctions mouse — while the cursor rides
		# the OPEN sheet (or the sl-0129 loot panel), gameplay input
		# suppresses (a pane click must never also fire the weapon;
		# the typing-box precedent).
		var over_pane: bool = (
			(char_sheet != null and char_sheet.wants_suppress())
			or (quest_offer != null and quest_offer.wants_suppress())
			or (loot_panel != null and loot_panel.wants_suppress())
			or (bank_panel != null and bank_panel.wants_suppress())
			or (vendor_panel != null and vendor_panel.wants_suppress())
		)
		driver.sampler.suppress = typing or over_pane
	# §2.9 prev/curr render toggle — view-side only, replay-irrelevant.
	if not typing and view_clock != null and Input.is_action_just_pressed("interp_toggle"):
		view_clock.interp_enabled = not view_clock.interp_enabled
		print("render interpolation: ", "ON" if view_clock.interp_enabled else "OFF (snap)")
	# Seam B (sl-0109): pause + options = ONE menu on BOTH O and Esc.
	# The driver still owns the pause bit (CORE-31: pause always legal,
	# pause_locked owners keep priority); the menu rides pause_changed.
	if (
		not typing
		and options_menu != null
		and driver != null
		and not driver.pause_locked
		and Input.is_action_just_pressed("options_toggle")
	):
		# Menu pass (sl-0145): O closes the topmost open menu FIRST —
		# same law as Esc (the driver's esc_intercept covers the
		# pause key; this covers O). Nothing open = the pause menu.
		if not _close_topmost_menu():
			driver.paused = not driver.paused
			driver.pause_changed.emit(driver.paused)
	# Menu pass (sl-0150/0152): C opens THE menu (two tabs, last-used
	# tab); the quest_log action (L [T]) deep-links the log tab.
	# Never pauses. Opening any menu closes the others (one surface).
	if not typing and char_sheet != null and Input.is_action_just_pressed("char_sheet"):
		char_sheet.toggle()
		if char_sheet.visible:
			_menus_exclusive(char_sheet)
	if not typing and char_sheet != null and Input.is_action_just_pressed("quest_log"):
		char_sheet.open_tab(1)
		if char_sheet.visible:
			_menus_exclusive(char_sheet)
	# Menu pass F router (sl-0144/0145/0147): while the offer dialogue
	# is open the press IS the accept decision; otherwise STATIONS
	# answer it — bank/vendor menus open on F, never walk-over (loot
	# bags stay walk-over by the designer's own word). The same press
	# still reaches the sim (recorded): pickups, turn-ins, offers and
	# rift casts resolve there; seam H walks the whole surface.
	if not typing and Input.is_action_just_pressed("interact"):
		if quest_offer != null and quest_offer.visible:
			quest_offer.confirm_accept()
		elif world != null and not world.players.is_empty():
			var p0: RefCounted = world.players[0]
			if p0.class_id >= 0 and not p0.dead:
				if bank_panel != null and BagStep.at_bank(world, p0):
					bank_panel.station_toggle()
					if bank_panel.is_open():
						_menus_exclusive(bank_panel)
				elif vendor_panel != null and BagStep.nearest_vendor(world, p0) >= 0:
					vendor_panel.station_toggle()
					if vendor_panel.is_open():
						_menus_exclusive(vendor_panel)
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
			# sl-0112: the busy-giver hint retired WITH the walk-up era
			# — givers answer the interact press now. A gentle [F]
			# prompt near interactables is seam-B polish.
			# S1 seam 4: dungeon doors (walk-on transition; the same
			# walk-over language as loot). Profile harvests FIRST so
			# nothing since the last beat is lost on the stairs.
			# S1 seam 6: rift exits harvest the STARHOOK lane instead
			# (gold pot to the main wallet, level/xp/skins to the
			# starhook fields) and land back where you cast.
			if _scenario_persistent or _scenario_rift:
				var doors: Array = DUNGEON_DOORS.get(_scenario_id, [])
				for door: Dictionary in doors:
					var dc: Vector2 = door.cell
					var at_door: bool = world.players[0].pos.distance_to(dc) <= DOOR_RADIUS
					# sl-0115: a WON dive ends on its own after the
					# linger — the loot is banked, the rift closes.
					var won_out: bool = (
						_scenario_rift
						and _rift_won
						and world.tick - _rift_won_tick >= RIFT_WIN_LINGER_TICKS
					)
					if at_door or won_out:
						var spawn := String(door.spawn)
						if _scenario_rift:
							CharacterProfile.harvest_rift(world, character, _rift_won)
							spawn = String(Config.get_setting("dev", "rift_return", ""))
						else:
							CharacterProfile.harvest(world, character)
						CharacterProfile.save_profile(character)
						Config.set_setting("dev", "scenario", String(door.to))
						Config.set_setting("dev", "door_spawn", spawn)
						print(String(door.label))
						get_tree().reload_current_scene()
						return
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
	# Seam B (sl-0109): the debug readout tucks behind a toggle [T]
	# (options row; default off — the countryside is not a profiler).
	speed_label.visible = bool(Config.get_setting("ui", "debug_line", false))
	if speed_label.visible:
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
	# Bars read the player's real maxes (class curves move them —
	# docs/22 block 5; the old /100 was the v0 sheet's constant).
	hp_bar.value = p.hp / maxf(1.0, float(p.max_hp))
	mana_bar.value = p.mana / maxf(1.0, float(p.max_mana))
	var adef: Resource = world.ability_def
	if adef != null:
		var affordable: bool = p.mana >= int(adef.mana_cost)
		ability_label.text = "[Space] %s %dmp" % [String(adef.display_name), int(adef.mana_cost)]
		ability_label.modulate = Color.WHITE if affordable else Color(0.6, 0.55, 0.75)
	rec_label.visible = gif_recorder != null and gif_recorder.armed
	if not world.weapon_frames.is_empty():
		weapon_label.text = String(world.weapon_frames[p.equipped_weapon].display_name)
		# Icon pack glyph: class archetype x tier (seam 4). Cached by
		# key — the atlas cut runs only when the slot actually changes.
		var icon_key := ""
		if p.class_id >= 0:
			var arch := String(world.weapon_frames[p.equipped_weapon].archetype)
			var glyph_family: String = ICON_WEAPON_FAMILIES.get(arch, "")
			if not glyph_family.is_empty():
				var tier := clampi(int(p.weapon_tiers[p.equipped_weapon]), 1, 5)
				icon_key = "%s.t%d" % [glyph_family, tier]
		if icon_key != _weapon_icon_key:
			_weapon_icon_key = icon_key
			if icon_key.is_empty():
				weapon_icon.visible = false
			else:
				weapon_icon.texture = IconAtlas.icon(icon_key)
				weapon_icon.visible = weapon_icon.texture != null
	# Level/xp/gold + the minimal equip surface. Class lane (docs/22):
	# class name + its one weapon slot; legacy lane keeps the lab trio.
	var xp_next: int = Progress.xp_to_next(world, p.level, p.class_id)
	var xp_part := (
		"lv %d  xp %d/%d" % [p.level, p.xp, xp_next] if xp_next > 0 else "lv %d  MAX" % p.level
	)
	if _scenario_rift:
		# STARHOOK v2 (sl-0115): the bait fighter's readout — the hp
		# bar IS line stability; lives are the three lines; the rod is
		# the class ([R] swaps among unlocked).
		var pips := ""
		for li in 3:
			pips += "●" if li < p.line_lives else "○"
		(
			loot_label
			. set_text(
				(
					"BAIT FIGHTER lv %d  xp %d\nlines %s · %s [R] · pot %d gold"
					% [
						p.level,
						p.xp,
						pips,
						String(world.weapon_frames[p.equipped_weapon].display_name),
						p.gold,
					]
				)
			)
		)
	elif p.class_id >= 0:
		# sl-0121: the top-right TRACKER carries the at-a-glance
		# errand lines now [T]; this readout keeps the bare count.
		# The full log stays the C sheet.
		var quest_part := ""
		var carried := 0
		for qi in world.quest_defs.size():
			if (p.quests_taken_mask & (1 << qi)) == 0:
				continue
			if (p.quests_done_mask & (1 << qi)) != 0:
				continue
			carried += 1
		if carried > 0:
			quest_part = "\nerrands %d" % carried
		(
			loot_label
			. set_text(
				(
					"%s  gold %d\n%s T%d · armor T%d%s"
					% [
						xp_part,
						p.gold,
						String(world.weapon_frames[p.equipped_weapon].display_name),
						p.weapon_tiers[p.equipped_weapon],
						p.armor_tier,
						quest_part,
					]
				)
			)
		)
	else:
		(
			loot_label
			. set_text(
				(
					"%s  gold %d\nbolt T%d · scatter T%d · wheel T%d · armor T%d"
					% [
						xp_part,
						p.gold,
						p.weapon_tiers[0],
						p.weapon_tiers[1],
						p.weapon_tiers[2],
						p.armor_tier,
					]
				)
			)
		)
	# Loop moments worth a toast: level-ups, pickups (S1 seam 2: every
	# equipment pickup speaks the ONE item-text grammar; gold stays
	# silent — the HUD counter is its readout), and the CORE-43
	# death/respawn beats (persistent worlds, seam 3).
	for lev: Dictionary in driver.frame_events:
		match int(lev.type):
			SimEvents.Type.LEVEL_UP:
				_show_toast("LEVEL %d" % int(lev.level))
			SimEvents.Type.LOOT_PICKED:
				if int(lev.kind) != SimWorld.DROP_GOLD:
					var line := ItemText.drop_line(
						world, {"kind": int(lev.kind), "a": int(lev.a), "b": int(lev.b)}
					)
					if not line.is_empty():
						_show_toast(line)
			SimEvents.Type.PLAYER_RESPAWNED:
				if recap_panel != null:
					recap_panel.visible = false
				_show_toast("back at the settlement — the walk out is yours")
			SimEvents.Type.QUEST_ACCEPTED:
				var qa := int(lev.quest)
				if qa >= 0 and qa < world.quest_defs.size():
					var qd: Resource = world.quest_defs[qa]
					_show_toast("[%s] %s" % [String(qd.reason), String(qd.text)])
			SimEvents.Type.QUEST_DONE:
				_show_toast("quest done — +%d gold, +%d xp" % [int(lev.gold), int(lev.xp)])
			SimEvents.Type.QUEST_ABANDONED:
				# sl-0154: the errand went back to its giver — available
				# again through the normal offer, no cooldown.
				_show_toast("errand returned to its giver")
			SimEvents.Type.QUEST_OFFERED:
				# sl-0144: the press found an available errand — the
				# dialogue opens; accept is the recorded-op decision.
				if quest_offer != null:
					quest_offer.offer(int(lev.quest))
					_menus_exclusive(quest_offer)
			SimEvents.Type.GATHERED:
				_show_toast("foraged +%d gold" % int(lev.gold))
			SimEvents.Type.CAST_COMPLETE:
				# STARHOOK v2 (sl-0115): the cast is INSTANT — the line
				# sinks into the rift the moment you press. Capture the
				# world frame for the left pane, remember the shore AND
				# the portal cell (the line draws INTO it), harvest the
				# MAIN lane, and descend into the biome's arena.
				if not character.is_empty():
					_rift_capture = get_viewport().get_texture().get_image()
					var cpos: Vector2 = world.players[0].pos
					var npos: Vector2 = lev.pos
					Config.set_setting("dev", "rift_return", "%.1f,%.1f" % [cpos.x, cpos.y])
					Config.set_setting("dev", "rift_node", "%.2f,%.2f" % [npos.x, npos.y])
					CharacterProfile.harvest(world, character)
					CharacterProfile.save_profile(character)
					var biome := clampi(int(lev.get("biome", 0)), 0, 2)
					var target := (
						"res://data/scenarios/rift_%s_%s.tres"
						% [RIFT_BIOME_KEYS[biome], "rare" if bool(lev.rare) else "common"]
					)
					Config.set_setting("dev", "scenario", target)
					Config.set_setting("dev", "door_spawn", "")
					print("the line sinks into the rift...")
					get_tree().reload_current_scene()
					return
			SimEvents.Type.PHASE_CHANGED:
				# Rift phase titles (prototype flavor; the telegraphs
				# stay the real warning — Law 4).
				if _scenario_rift:
					var ph := int(lev.get("phase", 0))
					if ph == 1:
						_show_toast("THE COIL")
					elif ph == 2:
						_show_toast("THE THRASH")
			SimEvents.Type.LINE_SNAPPED:
				# One of the three lives burned — the line re-spools.
				var left := int(lev.get("lives_left", 0))
				_show_toast(
					(
						"THE LINE SNAPPED — %s left"
						% ("two lines" if left == 2 else "ONE LINE" if left == 1 else "%d" % left)
					)
				)
			SimEvents.Type.CATCH_LANDED:
				# STARHOOK v2 win beat (correction #7): the win IS the
				# kill — the loot lands, the dive ends on its own.
				if _scenario_rift and not _rift_won:
					_rift_won = true
					_rift_won_tick = world.tick
					_show_toast(
						(
							"THE CATCH IS YOURS — %s%s"
							% [
								_rift_fish_name(
									int(lev.get("biome", 0)),
									int(lev.get("fish", 0)),
									bool(lev.get("rare", false))
								),
								" ★" if bool(lev.get("rare", false)) else "",
							]
						)
					)
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
		bars_stack,
		char_sheet,
		quest_offer,
		quest_tracker,
		loot_panel,
		bank_panel,
		vendor_panel,
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
	# sl-0149: bars sit top-LEFT; the autofire indicator rides beside
	# them (ui-scale-aware inset).
	autofire_icon.position = Vector2(4.0 + 64.0 * k + 6.0, 4.0)
	# The right corner is the world-info cluster now: minimap under
	# the weapon row, tracker beneath the minimap slot [T].
	var stack_top := 4.0 + 16.0 * k + 4.0
	if map_overlay != null:
		map_overlay.corner_top_inset = stack_top
	# sl-0121: the errand tracker rides beneath the minimap slot when
	# the overlay exists (dev), else directly under the weapon row.
	if quest_tracker != null:
		quest_tracker.set_top(stack_top + (96.0 + 4.0 if map_overlay != null else 0.0))


func _apply_crosshair_scale() -> void:
	# The uikit crosshair is a HARDWARE cursor: drawn at native pixel
	# size in window space, so it never inherits the integer viewport
	# stretch and reads as a speck at gameplay scale. Scale the texture
	# by the live content scale instead (nearest-neighbor, hotspot at
	# the true center pixel) and re-apply whenever the window scale
	# changes. sl-0077: the base bitmap now comes from the player's
	# style + size options ([ui]); style 0 at size 11 IS the ratified
	# kit bitmap verbatim, so the default reproduces the sl-0042 pass
	# exactly. Render-only: aim math reads the viewport mouse position
	# and never touches the cursor bitmap.
	var win := get_window()
	var base_w := float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var base_h := float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var k := maxi(1, int(minf(float(win.size.x) / base_w, float(win.size.y) / base_h)))
	var style := CrosshairStyles.clamp_style(
		int(Config.get_setting("ui", "crosshair_style", CrosshairStyles.DEFAULT_STYLE))
	)
	var size := CrosshairStyles.clamp_size(
		int(Config.get_setting("ui", "crosshair_size", CrosshairStyles.DEFAULT_SIZE))
	)
	if k == _crosshair_scale and style == _crosshair_style and size == _crosshair_size:
		return
	_crosshair_scale = k
	_crosshair_style = style
	_crosshair_size = size
	var img := CrosshairStyles.build_base_image(style, size)
	var center := (img.get_width() - 1) / 2
	img.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	var pad := floorf(float(k - 1) * 0.5)
	var hot := float(center) * float(k) + pad
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


## ESC-CLOSES-MENU-FIRST (sl-0145): one close per press, topmost
## first — the sheet's drop confirm, then the offer dialogue, then
## the menu itself, then open stations. False = nothing was open
## (the press means pause). The walk-over loot readout is exempt
## (not a menu). Fed to the driver as esc_intercept; the O handler
## calls it too.
func _close_topmost_menu() -> bool:
	if char_sheet != null and char_sheet.close_topmost():
		return true
	if quest_offer != null and quest_offer.visible:
		quest_offer.dismiss()
		return true
	if bank_panel != null and bank_panel.is_open():
		bank_panel.station_close()
		return true
	if vendor_panel != null and vendor_panel.is_open():
		vendor_panel.station_close()
		return true
	return false


## ONE SURFACE AT A TIME (menu pass standing rule): opening any menu
## closes the others; pass the one to keep.
func _menus_exclusive(keep: Control) -> void:
	if char_sheet != null and char_sheet != keep and char_sheet.visible:
		char_sheet.visible = false
	if quest_offer != null and quest_offer != keep and quest_offer.visible:
		quest_offer.dismiss()
	if bank_panel != null and bank_panel != keep and bank_panel.is_open():
		bank_panel.station_close()
	if vendor_panel != null and vendor_panel != keep and vendor_panel.is_open():
		vendor_panel.station_close()


func _refresh_hints() -> void:
	var parts: Array[String] = []
	# sl-0115: the rod hint only where rods exist (rift arenas).
	if _scenario_rift:
		parts.append("%s rod" % Config.binding_text("rod_swap"))
	for entry: Array in [
		["interact", "interact"],
		["loot_all", "loot"],
		["char_sheet", "sheet"],
		["quest_log", "log"],
		["options_toggle", "menu"],
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
		func(hardcore: bool, cls: String) -> void:
			character = CharacterProfile.create(hardcore, cls)
			character.runs = 1
			CharacterProfile.save_profile(character)
			CharacterProfile.apply_to_world(world, character)
			world.persistent_respawn = _scenario_persistent and not hardcore
			driver.pause_locked = false
			driver.paused = false
			character_panel.queue_free()
			character_panel = null
	)


## sl-0125: apply the LIVE split ratio — pane anchors + the rift
## camera's fit. THE ARENA CELLS STAY IDENTICAL; only the render
## changes. Interior = 10x11 t (320x352 px) centered at (192, 208)
## world-px in the 12x13 arena; zoom = min(pane_w/320, 360/352) so
## the whole interior is ALWAYS inside the galaxy pane (Law 1 at
## either ratio); the world pane keeps the line + body + portal
## readable at 1/3 width (the overlay reads its live pane width).
func _apply_rift_split() -> void:
	if _rift_cam == null:
		return
	var idx := clampi(
		int(Config.get_setting("ui", "rift_split", 0)), 0, RIFT_SPLIT_RATIOS.size() - 1
	)
	var r: float = RIFT_SPLIT_RATIOS[idx]
	var world_frac := 1.0 - r
	var pane_w := 640.0 * r
	var zoom_v := minf(pane_w / 320.0, 360.0 / 352.0)
	var pane_center_x := 640.0 - 320.0 * r
	var cam_x := 192.0 - (pane_center_x - 320.0) / zoom_v
	_rift_cam.setup_fixed(Vector2(cam_x, 208.0), zoom_v)
	if _rift_panes.is_empty():
		return
	var wpane: TextureRect = _rift_panes.wpane
	wpane.anchor_left = 0.0
	wpane.anchor_right = world_frac
	var overlay: Control = _rift_panes.overlay
	overlay.anchor_left = 0.0
	overlay.anchor_right = world_frac
	overlay.pane_w = 640.0 * world_frac
	var hold: Label = _rift_panes.hold
	hold.anchor_left = 0.0
	hold.anchor_right = world_frac
	var title: Label = _rift_panes.title
	title.anchor_left = world_frac
	title.anchor_right = 1.0
	var seam: ColorRect = _rift_panes.seam
	seam.anchor_left = world_frac
	seam.anchor_right = world_frac


## Fish display name from the balance frame's biome tables (sl-0115).
func _rift_fish_name(biome: int, fish: int, rare: bool) -> String:
	var biomes: Array = world.stat_frame.get("starhook", {}).get("biomes", [])
	if biome < 0 or biome >= biomes.size():
		return "the catch"
	var b: Dictionary = biomes[biome]
	if rare:
		return String(b.get("rare", {}).get("name", "the rare catch"))
	var table: Array = b.get("fish", [])
	if fish >= 0 and fish < table.size():
		return String(table[fish].get("name", "the catch"))
	return "the catch"


## Death bookkeeping — once per death, on the recap. Hardcore: the
## character file dies with the character and the reset key lands on
## the new-character screen. PERSISTENT WORLD (CORE-43, seam 3): the
## SIM already took the gold slice at the death tick — harvest the
## post-cost profile and save; the sim's settlement respawn owns the
## comeback (no run framing). Legacy loop worlds: profile-side cost +
## the one-key retry, unchanged.
func _on_player_death() -> void:
	if character.is_empty():
		return
	# STARHOOK (sl-0105) — THE LINE SNAPS [T]: death in a rift fight
	# is never a character death (hardcore stake untouched, no gold
	# cost): the un-harvested rift world discards whole — you lose
	# the catch and whatever the fight had paid, nothing else. Back
	# to the shore you cast from.
	if _scenario_rift:
		Config.set_setting("dev", "scenario", "res://data/scenarios/slice_overworld.tres")
		Config.set_setting(
			"dev", "door_spawn", String(Config.get_setting("dev", "rift_return", ""))
		)
		print("the third snap — the dive is lost...")
		get_tree().reload_current_scene()
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
	if world.persistent_respawn:
		CharacterProfile.harvest(world, character)
		character.deaths = int(character.get("deaths", 0)) + 1
		CharacterProfile.save_profile(character)
		var gold_lost := 0
		for ev: Dictionary in driver.frame_events:
			if int(ev.type) == SimEvents.Type.ENTITY_KILLED and bool(ev.get("player", false)):
				gold_lost = int(ev.get("gold_lost", 0))
		_show_toast(
			"death: %d gold lost — you wake at the settlement. [Space] wakes you now." % gold_lost
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
	# docs/22: the stat frame is load-bearing for the slice — a build
	# where balance_frame.json failed to load must fail the boot gate
	# loudly, never quietly fall back to the legacy lane.
	if world.stat_frame.is_empty():
		push_error("main: stat frame missing — balance_frame.json failed to load")

	# Loop v1 (docs/19): the persistent character rides every world the
	# player actually plays; audit/verify runs stay profile-free. Applied
	# BEFORE the recorder snapshots initial state, so replay headers are
	# honest about what actually ran.
	_scenario_persistent = bool(scenario.persistent_world)
	_scenario_id = scenario.id
	_scenario_rift = bool(scenario.starhook_rift)
	_rift_won = false
	if not (audit_mode or verify_mode):
		character = CharacterProfile.load_profile()
		if not character.is_empty() and _scenario_rift:
			# STARHOOK (sl-0105): rift worlds get the RIFTER shape —
			# the mini-class row on the stat frame, riding the legacy
			# lane; the rod is the class. Never the main apply.
			CharacterProfile.apply_to_rift(world, character)
		elif not character.is_empty():
			CharacterProfile.apply_to_world(world, character)
			character.runs = int(character.get("runs", 0)) + 1
			CharacterProfile.save_profile(character)
			# S1 seam 4: a door transition lands the player at the
			# door's authored arrival, not the scenario spawn (one-shot;
			# consumed before the recorder snapshot so replays carry the
			# true initial state). The CORE-43 respawn cell stays the
			# scenario's own spawn.
			var door_spawn := String(Config.get_setting("dev", "door_spawn", ""))
			if not door_spawn.is_empty():
				Config.set_setting("dev", "door_spawn", "")
				var dparts := door_spawn.split(",")
				if dparts.size() == 2 and not world.players.is_empty():
					world.players[0].pos = Vector2(float(dparts[0]), float(dparts[1]))
			# CORE-43 (seam 3): a NORMAL-mode character in a
			# persistent-world scenario dies the overworld way —
			# in-sim gold slice + settlement respawn. Hardcore keeps
			# dead-in-place (the file is the stake).
			world.persistent_respawn = (
				_scenario_persistent and not bool(character.get("hardcore", false))
			)

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

	# STARHOOK split (sl-0115; ratio [T] + live-flippable by sl-0125 —
	# PRESENTATION ONLY): LEFT = the world at the moment of the cast
	# (captured frame, dimmed; your body at the rift, the line sinking
	# INTO it — the living overlay draws that half of the two-portal
	# topology). RIGHT = the galaxy view (the live scene; the fixed
	# rift camera FITS the whole interior in the pane at either ratio
	# — Law 1 by construction). The divider is a glowing seam.
	# Anchors/camera land in _apply_rift_split (after the camera
	# mounts below).
	if _scenario_rift and _rift_capture != null:
		var pane_layer := CanvasLayer.new()
		pane_layer.layer = 40
		add_child(pane_layer)
		var wpane := TextureRect.new()
		wpane.texture = ImageTexture.create_from_image(_rift_capture)
		wpane.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wpane.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		wpane.anchor_top = 0.0
		wpane.anchor_bottom = 1.0
		wpane.modulate = Color(0.62, 0.62, 0.72, 1.0)
		pane_layer.add_child(wpane)
		# The living overlay: line into the portal + portal pulse.
		var overlay := RiftWorldPane.new()
		overlay.world = world
		overlay.deep_x = RiftStep.deep_edge_x(world)
		overlay.biome_rim = RiftNodesView.BIOME_RIMS[clampi(int(scenario.rift_biome), 0, 2)]
		var rr := String(Config.get_setting("dev", "rift_return", "")).split(",")
		var rn := String(Config.get_setting("dev", "rift_node", "")).split(",")
		if rr.size() == 2 and rn.size() == 2:
			overlay.portal_offset = (
				Vector2(float(rn[0]) - float(rr[0]), float(rn[1]) - float(rr[1])) * TILE
			)
		overlay.anchor_top = 0.0
		overlay.anchor_bottom = 1.0
		pane_layer.add_child(overlay)
		var hold_label := Label.new()
		hold_label.text = "THE LINE HOLDS"
		hold_label.modulate = Color(0.66, 0.71, 0.85, 0.8)
		hold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hold_label.offset_top = 4.0
		pane_layer.add_child(hold_label)
		var title := Label.new()
		title.text = (
			"%sRIFT CATCH — %s"
			% [
				"★ RARE " if bool(scenario.rift_rare) else "",
				RiftNodesView.BIOME_NAMES[clampi(int(scenario.rift_biome), 0, 2)],
			]
		)
		title.modulate = (
			Color(1.0, 0.82, 0.31) if bool(scenario.rift_rare) else Color(0.96, 0.92, 0.85)
		)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.offset_top = 4.0
		pane_layer.add_child(title)
		var seam_line := ColorRect.new()
		seam_line.color = Color(0.9, 0.85, 0.6, 0.85)
		seam_line.anchor_top = 0.0
		seam_line.anchor_bottom = 1.0
		seam_line.offset_left = -1.0
		seam_line.offset_right = 1.0
		pane_layer.add_child(seam_line)
		_rift_panes = {
			"wpane": wpane,
			"overlay": overlay,
			"hold": hold_label,
			"title": title,
			"seam": seam_line
		}

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
	# sl-0115: rift arenas render their own actors — THE BAIT FIGHTER
	# (a small simple sprite; corrections #1/#2) and the star-fish
	# catch — via the rift view below; the ranger and the assembler
	# enemy view stay out of the galaxy.
	var lib := AssemblerLibrary.new()
	var lib_ok := lib.load_manifest()
	var sheet_map: Resource = load("res://data/actor_sheet_map.tres")
	if _scenario_rift:
		var rift_view := RiftView.new()
		rift_view.world = world
		rift_view.clock = view_clock
		rift_view.biome = clampi(int(scenario.rift_biome), 0, 2)
		rift_view.rare = bool(scenario.rift_rare)
		rift_view.arena_w = int(def.width)
		rift_view.arena_h = int(def.height)
		add_child(rift_view)
	elif lib_ok and sheet_map != null and lib.has_actor(String(sheet_map.map.player)):
		var av := AnimatedActor.new()
		av.sprite_frames = lib.build_sprite_frames(String(sheet_map.map.player))
		av.actor = world.players[0]
		av.clock = view_clock
		av.render_scale = lib.render_scale()
		av.play("idle-down")
		actor_space.add_child(av)
	else:
		push_error("main: player sheet unavailable — run the assembler importer")
	# World-side rift portals (sl-0115): wherever nodes or ambient
	# spawns exist, the portals draw with their biomes + the cast cue.
	if not scenario.rift_nodes.is_empty() or bool(scenario.rift_ambient):
		var nodes_view := RiftNodesView.new()
		nodes_view.world = world
		add_child(nodes_view)

	# Real enemies: assembler sheets + overhead HP bars (M5; CORE-35 —
	# general presentation, no targeting anything).
	if lib_ok and not _scenario_rift:
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
	# NPC presence (slice S0 seam 4, W-8): the 32 pack looks stationed
	# at giver slots + the settlement crowd — pure view inside the same
	# y-sort space, only where a content pack rides the scenario.
	if not String(scenario.content_pack).is_empty():
		var lib_npc := AssemblerLibrary.new()
		lib_npc.manifest_path = "res://npcs/manifest.json"
		lib_npc.sheet_root = "res://npcs/"
		if lib_npc.load_manifest():
			var npcs := NpcView.new()
			npcs.y_sort_enabled = true
			npcs.setup(
				lib_npc,
				ContentImporter.resolve_src(String(scenario.content_pack)),
				bitgrid,
				scenario.player_spawn
			)
			actor_space.add_child(npcs)

	var hp_bars := HpBarView.new()
	hp_bars.world = world
	hp_bars.clock = view_clock
	add_child(hp_bars)

	# sl-0121: overhead giver icons — two states over the authored
	# giver cells (pure view; rift arenas carry no givers; the model
	# is inert for legacy-lane players, so labs/proofs draw nothing).
	if not _scenario_rift:
		var giver_icons := QuestGiverIcons.new()
		giver_icons.world = world
		add_child(giver_icons)

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
	if _scenario_rift:
		# sl-0115/sl-0125: fixed framing at the LIVE split ratio — the
		# interior FITS its pane at either ratio (no follow, no
		# off-screen bullets, ever — Law 1 by construction).
		_rift_cam = camera
		_apply_rift_split()
	else:
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
	# sl-0149: beside the left-corner bars (re-fed ui-scale-aware in
	# _apply_ui_scale).
	autofire_icon.position = Vector2(74.0, 4.0)
	weapon_label = Label.new()
	# Icon pack (seam 4): the equipped weapon's tier glyph rides beside
	# the name — class lane only (lab frames keep text-only).
	weapon_icon = TextureRect.new()
	weapon_icon.custom_minimum_size = Vector2(16.0, 16.0)
	weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	weapon_icon.visible = false
	var weapon_row := HBoxContainer.new()
	weapon_row.add_theme_constant_override("separation", 4)
	weapon_row.add_child(weapon_icon)
	weapon_row.add_child(weapon_label)
	weapon_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	weapon_row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	weapon_row.offset_right = -4.0
	weapon_row.offset_top = 4.0
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
	# Menu pass (sl-0149, the designer's word): the hp+mana stack
	# lives in the LEFT corner now [T exact placement — 4,4 inset,
	# Law 6 + the ui-scale inset discipline]; the autofire indicator
	# shifts to ride beside it (position fed ui-scale-aware). The
	# right corner keeps the world-info cluster (weapon, minimap,
	# tracker) — the tracker STAYS right by this session's call [T].
	bars_stack = VBoxContainer.new()
	bars_stack.add_theme_constant_override("separation", 2)
	bars_stack.add_child(hp_bar)
	bars_stack.add_child(mana_bar)
	bars_stack.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	bars_stack.offset_left = 4.0
	bars_stack.offset_top = 4.0
	hud_stack = VBoxContainer.new()
	hud_stack.add_theme_constant_override("separation", 2)
	hud_stack.add_child(ability_label)
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
	# Menu pass (seam F): the toast line rides a gold-on-dark chip
	# (the workbench toast surface, built from its spec — the capture
	# is absent by the accepted workbench limitation).
	var toast_box := StyleBoxFlat.new()
	toast_box.bg_color = MenuPalette.PLAQUE_BOTTOM
	toast_box.border_color = MenuPalette.GOLD_DIM
	toast_box.set_border_width_all(1)
	toast_box.content_margin_left = 8.0
	toast_box.content_margin_right = 8.0
	toast_box.content_margin_top = 2.0
	toast_box.content_margin_bottom = 2.0
	toast_label.add_theme_stylebox_override("normal", toast_box)
	toast_label.add_theme_color_override("font_color", MenuPalette.GOLD_BRIGHT)
	toast_label.visible = false
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_top = 24.0
	options_menu = OptionsMenu.new()
	# Menu pass chrome rule (sl-0145): the menu's close button IS
	# unpausing — same meaning as Esc/O with nothing else open.
	options_menu.close_requested.connect(
		func() -> void:
			if driver != null and driver.paused and not driver.pause_locked:
				driver.paused = false
				driver.pause_changed.emit(false)
	)
	# Live key-hint line: reads the ACTUAL InputMap, so it stays correct
	# after remaps.
	hints_label = Label.new()
	hints_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hints_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var hud := CanvasLayer.new()
	hud.add_child(pause_label)
	hud.add_child(hud_stack)
	hud.add_child(bars_stack)
	hud.add_child(autofire_icon)
	hud.add_child(weapon_row)
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
	# Seam B (sl-0106): the character sheet + quest log — read-only,
	# both profiles, under the options/recap layers.
	char_sheet = CharacterSheet.new()
	char_sheet.world = world
	char_sheet.character = character
	char_sheet.toast_requested.connect(_show_toast)
	quest_offer = QuestOffer.new()
	quest_offer.world = world
	quest_offer.toast_requested.connect(_show_toast)
	if driver != null and driver.sampler != null:
		quest_offer.bag_op_sink = Callable(driver.sampler, "queue_bag_op")
	hud.add_child(quest_offer)
	# sl-0145: the pause key runs menu-first through the driver (the
	# driver keeps the CORE-31 pause bit; this gates one press's
	# MEANING, never the ability to pause).
	if driver != null:
		driver.esc_intercept = Callable(self, "_close_topmost_menu")
	# sl-0116/0128: pane clicks queue RECORDED bag ops on the sampler —
	# the sim mutation rides the input stream, replay-honest.
	if driver != null and driver.sampler != null:
		char_sheet.bag_op_sink = Callable(driver.sampler, "queue_bag_op")
	hud.add_child(char_sheet)
	quest_tracker = QuestTracker.new()
	quest_tracker.world = world
	hud.add_child(quest_tracker)
	# sl-0129: the walk-over loot panel (rows loot by recorded ops).
	loot_panel = LootBagPanel.new()
	loot_panel.world = world
	if driver != null and driver.sampler != null:
		loot_panel.bag_op_sink = Callable(driver.sampler, "queue_bag_op")
	hud.add_child(loot_panel)
	# sl-0130: the bank panel (walk up to the stash keeper).
	bank_panel = BankPanel.new()
	bank_panel.world = world
	if driver != null and driver.sampler != null:
		bank_panel.bag_op_sink = Callable(driver.sampler, "queue_bag_op")
	hud.add_child(bank_panel)
	# sl-0131: the vendor panel (walk up to a vendor body).
	vendor_panel = VendorPanel.new()
	vendor_panel.world = world
	if driver != null and driver.sampler != null:
		vendor_panel.bag_op_sink = Callable(driver.sampler, "queue_bag_op")
	hud.add_child(vendor_panel)
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
	# Seam B (sl-0109): the menu RIDES pause — Esc (the driver's own
	# pause key) and O land in the same place; closing resumes.
	driver.pause_changed.connect(
		func(p: bool) -> void:
			pause_label.visible = p
			if options_menu.visible != p:
				options_menu.toggle()
			_refresh_hints()
	)
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
	# Seam B (sl-0109): the fps/spikes readout behind a toggle [T].
	options_menu.add_cycle_row(
		"debug readout",
		["off", "on"],
		1 if bool(Config.get_setting("ui", "debug_line", false)) else 0,
		func(i: int) -> void: Config.set_setting("ui", "debug_line", i == 1)
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
	# sl-0077 crosshair style + size (player-facing, both profiles):
	# shapes differ by silhouette, never hue (CORE-50); "classic" = the
	# ratified kit crosshair, untouched default. Applies live.
	options_menu.add_cycle_row(
		"crosshair style",
		CrosshairStyles.STYLE_NAMES,
		CrosshairStyles.clamp_style(
			int(Config.get_setting("ui", "crosshair_style", CrosshairStyles.DEFAULT_STYLE))
		),
		func(i: int) -> void:
			Config.set_setting("ui", "crosshair_style", i)
			_apply_crosshair_scale()
	)
	var xhair_sizes: Array = []
	for s: int in CrosshairStyles.SIZES:
		xhair_sizes.append("%d px" % s)
	options_menu.add_cycle_row(
		"crosshair size",
		xhair_sizes,
		CrosshairStyles.SIZES.find(
			CrosshairStyles.clamp_size(
				int(Config.get_setting("ui", "crosshair_size", CrosshairStyles.DEFAULT_SIZE))
			)
		),
		func(i: int) -> void:
			Config.set_setting("ui", "crosshair_size", CrosshairStyles.SIZES[i])
			_apply_crosshair_scale()
	)
	# sl-0125: the starhook split ratio [T] — live-flippable in play
	# (both profiles; applies instantly inside a rift, remembered for
	# the next dive everywhere else). The designer flips it and rules.
	options_menu.add_cycle_row(
		"rift split",
		RIFT_SPLIT_NAMES,
		clampi(int(Config.get_setting("ui", "rift_split", 0)), 0, RIFT_SPLIT_RATIOS.size() - 1),
		func(i: int) -> void:
			Config.set_setting("ui", "rift_split", i)
			_apply_rift_split()
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
			# Persistent worlds keep RUNNING through your death (the
			# world does not wait — sl-0098); the recap still shows
			# (Law 8) and hides itself on the settlement respawn.
			# Everywhere else: pause + one-key retry, unchanged.
			if not world.persistent_respawn:
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
