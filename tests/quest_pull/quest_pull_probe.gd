## One-shot WINDOWED render probe (sl-0121; sl-0175/0176 findings
## pass): the quest-pull kit on real b77 ground — overhead giver
## icons in BOTH states (available riding the waystation farmer's
## head via the body-anchor map; turn-in at the bodiless capital
## slot), the HUD tracker lines, and the THREE map marker kinds
## (available bang + turn-in ring + objective diamond) on the corner
## minimap AND the fullscreen map. Quest state is staged on a stub
## world over the REAL quest defs; the icon/tracker/marker models
## only read that state. Captures (committed, read by eyes; desktop
## = screen crop per the rift_split_probe discipline):
##   reports/quest_pull_audit_waystation_base.png
##   reports/quest_pull_audit_capital_base.png
##   reports/quest_pull_audit_full_map.png
##   reports/quest_pull_audit_capital_desktop.png
## Run WITHOUT --headless:
##   godot_console --path . --script tests/quest_pull/quest_pull_probe.gd
extends SceneTree

const WorldBuilder := preload("res://game/arena/world_builder.gd")
const RenderLayers := preload("res://game/render_layers.gd")
const AssemblerLibrary := preload("res://game/views/assembler_library.gd")
const NpcView := preload("res://game/views/npc_view.gd")
const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const MapOverlay := preload("res://game/dev/map_overlay.gd")
const QuestGiverIcons := preload("res://game/views/quest_giver_icons.gd")
const NpcNameplates := preload("res://game/views/npc_nameplates.gd")
const QuestTracker := preload("res://ui/quest_tracker.gd")

const PACK := "res://assets/worldforge-packs/wildshot-overworld-pack-dusk/"
const CONTENT := "res://assets/wildshot-overworld-pack-dusk-content/"
const TILE := 32.0
const SPAWN := Vector2(109.5, 182.5)
const WAYSTATION := Vector2(91.5, 110.5)


class StubPlayer:
	var pos := Vector2.ZERO
	var class_id := 1
	var quests_taken_mask := 0
	var quests_done_mask := 0
	var quest_progress_arr := PackedInt32Array()


class StubWorld:
	var players: Array = []
	var quest_defs: Array = []


func _init() -> void:
	_run()


func _run() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	var arena := WorldBuilder.build_world_arena(root, PACK)
	if arena.is_empty():
		printerr("FAIL: b77 world did not build")
		quit(1)
		return
	var wf := WorldforgePack.validate(PACK)
	var actor_space := Node2D.new()
	actor_space.y_sort_enabled = true
	actor_space.z_index = RenderLayers.ACTORS
	root.add_child(actor_space)
	for layer: Node in arena.sort_layers:
		layer.get_parent().remove_child(layer)
		actor_space.add_child(layer)
	var lib := AssemblerLibrary.new()
	lib.manifest_path = "res://npcs/manifest.json"
	lib.sheet_root = "res://npcs/"
	if not lib.load_manifest():
		printerr("FAIL: npc manifest")
		quit(1)
		return
	var npcs := NpcView.new()
	npcs.y_sort_enabled = true
	if not npcs.setup(lib, CONTENT, wf.bitgrid, SPAWN):
		printerr("FAIL: npc_view setup")
		quit(1)
		return
	actor_space.add_child(npcs)

	# Staged quest state over the REAL defs: mud_pocket(1) complete →
	# turn-in at the capital (wins over cull's available); west_road(2)
	# active KILL 3/6 (tracker line, honest no-map-marker); far_field(4)
	# active VISIT → objective diamond at its target cell.
	var stub := StubWorld.new()
	var p := StubPlayer.new()
	p.pos = SPAWN
	p.quests_taken_mask = 0b10110
	p.quest_progress_arr = PackedInt32Array([0, 1, 3, 0, 0])
	stub.players = [p]
	for qp: String in [
		"res://data/quests/green_cull.tres",
		"res://data/quests/green_mud_pocket.tres",
		"res://data/quests/green_west_road.tres",
		"res://data/quests/green_provisions.tres",
		"res://data/quests/green_far_field.tres",
	]:
		stub.quest_defs.append(load(qp))

	var icons: Node2D = QuestGiverIcons.new()
	icons.world = stub
	# sl-0176: the same body-anchor wiring main performs.
	icons.cell_map = npcs.giver_map()
	root.add_child(icons)
	# sl-0190: the nameplates ride the same captures — role labels
	# over the interactable bodies (icon above name), crowd unlabeled.
	var plates: Node2D = NpcNameplates.new()
	plates.stations = npcs.stations()
	plates.names = NpcNameplates.load_name_table()
	root.add_child(plates)

	var hud := CanvasLayer.new()
	get_root().add_child(hud)
	var overlay: Control = MapOverlay.new()
	overlay.world = stub
	overlay.mouse_tile = func() -> Vector2: return p.pos + Vector2(6.0, 0.0)
	overlay.grid_size = Vector2i(int(arena.def.width), int(arena.def.height))
	if not overlay.load_minimap(PACK + "minimap.png"):
		printerr("FAIL: b77 minimap.png did not load")
		quit(1)
		return
	hud.add_child(overlay)
	var tracker: Label = QuestTracker.new()
	tracker.world = stub
	tracker.theme = load("res://ui/theme.tres")
	hud.add_child(tracker)

	var cam := Camera2D.new()
	cam.position = WAYSTATION * TILE
	cam.zoom = Vector2(2.0, 2.0)
	root.add_child(cam)

	await process_frame
	# _ready fires on the first frame for SceneTree-script nodes —
	# feed the under-the-minimap inset AFTER it (the way main's
	# _apply_ui_scale runs post-ready). The overlay's Config hookup
	# gets NULLED the same way (gotcha 41: the autoload NODE exists
	# under --script — the designer's live tracked_quest setting must
	# never steer a committed capture).
	overlay._cfg = null
	tracker.set_top(34.0 + 96.0 + 4.0)
	cam.make_current()
	overlay.cycle()  # corner
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var shot := get_root().get_texture().get_image()
	shot.save_png(
		ProjectSettings.globalize_path("res://reports/quest_pull_audit_waystation_base.png")
	)

	cam.position = SPAWN * TILE
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot_cap := get_root().get_texture().get_image()
	shot_cap.save_png(
		ProjectSettings.globalize_path("res://reports/quest_pull_audit_capital_base.png")
	)

	overlay.cycle()  # fullscreen — markers + dot over the whole map
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot_full := get_root().get_texture().get_image()
	shot_full.save_png(
		ProjectSettings.globalize_path("res://reports/quest_pull_audit_full_map.png")
	)
	overlay.cycle()  # off
	overlay.cycle()  # corner again for the desktop leg

	# Desktop leg (the rift_split_probe pattern): the presented pixels
	# via screen crop, topmost-forced, with a two-point signature guard
	# against bystander-window crops. Signature points sit on STATIC
	# pixels (the corner map texture + far-corner ground) — NPC idle
	# frames animate between captures. Window stays 1440x1080 (2x
	# integer scale): OS notification banners own the screen's
	# bottom-right and render above even ALWAYS_ON_TOP — a live toast
	# rode into a committed 1920-wide capture once (sl-0175/0176
	# session); the narrower window keeps the crop out of toast land
	# and the guard cannot sample there (it is normally content).
	var sig_map := shot_cap.get_pixel(620, 30)
	var sig_ground := shot_cap.get_pixel(20, 340)
	# The window opens effectively maximized — set_size is ignored
	# until the mode is explicitly WINDOWED.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_position(Vector2i(0, 0))
	DisplayServer.window_set_size(Vector2i(1440, 1080))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_move_to_foreground()
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var screen := DisplayServer.screen_get_image(DisplayServer.window_get_current_screen())
	if screen != null:
		var wpos := DisplayServer.window_get_position()
		var wsize := DisplayServer.window_get_size()
		var rect := Rect2i(wpos, wsize).intersection(
			Rect2i(Vector2i.ZERO, Vector2i(screen.get_width(), screen.get_height()))
		)
		var crop := screen.get_region(rect)
		# The viewport-stretch content centers inside the client area
		# with letterbox bars at non-16:9 — map base px through the
		# integer scale PLUS the centering offset.
		var s := floorf(minf(crop.get_width() / 640.0, crop.get_height() / 360.0))
		var off := Vector2i(
			int((crop.get_width() - 640.0 * s) * 0.5), int((crop.get_height() - 360.0 * s) * 0.5)
		)
		var got_map := crop.get_pixel(off.x + int(620.0 * s) + 1, off.y + int(30.0 * s) + 1)
		var got_ground := crop.get_pixel(off.x + int(20.0 * s) + 1, off.y + int(340.0 * s) + 1)
		if _off(got_map, sig_map) or _off(got_ground, sig_ground):
			printerr("quest_pull_probe: desktop crop signature mismatch — NOT written")
		else:
			crop.save_png(
				ProjectSettings.globalize_path("res://reports/quest_pull_audit_capital_desktop.png")
			)
			print(
				(
					"quest_pull_probe: wrote quest_pull_audit_capital_desktop.png (%dx%d)"
					% [crop.get_width(), crop.get_height()]
				)
			)
	else:
		printerr("quest_pull_probe: screen_get_image unavailable — desktop NOT captured")
	print("quest_pull_probe: wrote waystation_base + capital_base + full_map captures")
	quit(0)


static func _off(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) > 0.12 or absf(a.g - b.g) > 0.12 or absf(a.b - b.b) > 0.12
