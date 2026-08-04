## sl-0218 EVIDENCE probe (windowed): the quest activity indicators
## on real b77 ground over a REAL slice world — the meadow camp
## (108.5,138.5; prowler-only, so BANDITS wear the mark beside
## unmarked ranged kin: the discrimination is the evidence) woken by
## the real leash, mobs rendered from the assembler library, marks
## from the live model. Quest staging rides the REAL world's player
## (class lane + cull/west_road/provisions carried) AFTER the sim
## steps — pure view state, the sim never reads it.
##
## Captures (committed, read by eyes):
##   reports/quest_activity_marks_amber_base.png    (style 0, ships)
##   reports/quest_activity_marks_green_base.png    (style 1 option)
##   reports/quest_activity_marks_chevron_base.png  (style 2 option)
##   reports/quest_activity_map_corner_base.png     (region + corner)
##   reports/quest_activity_map_full_base.png       (regions + markers)
##   reports/quest_activity_desktop.png             (screen crop,
##     shipped style + corner map; signature-guarded per gotcha 42)
## Run WITHOUT --headless:
##   godot_console --path . --script tests/quest_activity/quest_activity_probe.gd
extends SceneTree

const WorldBuilder := preload("res://game/arena/world_builder.gd")
const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const RenderLayers := preload("res://game/render_layers.gd")
const AssemblerLibrary := preload("res://game/views/assembler_library.gd")
const EnemyActorsView := preload("res://game/views/enemy_actors_view.gd")
const HpBarView := preload("res://game/views/hp_bar_view.gd")
const QuestMobMarks := preload("res://game/views/quest_mob_marks.gd")
const MapOverlay := preload("res://game/dev/map_overlay.gd")
const InputFrame := preload("res://sim/input_frame.gd")

const PACK := "res://assets/worldforge-packs/wildshot-overworld-pack-dusk/"
const TILE := 32.0
const CAMP := Vector2(108.5, 138.5)
const STAND := Vector2(108.5, 144.5)

var fails: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails.append(msg)


func _init() -> void:
	_run()


func _run() -> void:
	var scenario: Resource = load("res://data/scenarios/slice_overworld.tres")
	var wf := WorldforgePack.validate(PACK)
	_check(bool(wf.ok), "b77 validates")
	var world: RefCounted = ScenarioLoader.build_world(scenario, 100, wf.bitgrid)
	var p: RefCounted = world.players[0]
	p.pos = STAND
	p.prev_pos = STAND
	# Step the LEGACY world: the leash wakes the camp, the pack spawns
	# and starts pressing — live composition for honest captures.
	var idle: RefCounted = InputFrame.new()
	for i in 60:
		world.step([idle])
	var live := 0
	for e: RefCounted in world.enemies:
		if e.hp > 0:
			live += 1
	_check(live >= 3, "the meadow camp woke (%d live)" % live)
	# View staging AFTER the steps: class lane + carried errands (cull
	# + west_road + provisions). The sim never advances again.
	p.class_id = 1
	p.quests_taken_mask = 0b01101
	p.quest_progress_arr = PackedInt32Array([0, 0, 0, 0, 0])
	var marked: Dictionary = QuestMobMarks.marked_defs(world)
	_check(marked.has(9) and marked.has(11) and marked.has(21), "cull+west_road mark 9/11/21")
	var live_marked := 0
	for e: RefCounted in world.enemies:
		if e.hp > 0 and marked.has(e.def_index):
			live_marked += 1
	_check(live_marked >= 1, "at least one live camp mob wears the mark (%d)" % live_marked)
	_check(live_marked < live, "and at least one does NOT (the discrimination shows)")

	var root := Node2D.new()
	get_root().add_child(root)
	var arena := WorldBuilder.build_world_arena(root, PACK)
	_check(not arena.is_empty(), "b77 world arena built")
	var actor_space := Node2D.new()
	actor_space.y_sort_enabled = true
	actor_space.z_index = RenderLayers.ACTORS
	root.add_child(actor_space)
	for layer: Node in arena.sort_layers:
		layer.get_parent().remove_child(layer)
		actor_space.add_child(layer)
	var lib := AssemblerLibrary.new()
	_check(lib.load_manifest(), "assembler library loads")
	var enemy_actors := EnemyActorsView.new()
	enemy_actors.world = world
	enemy_actors.lib = lib
	enemy_actors.sheet_map = load("res://data/actor_sheet_map.tres")
	enemy_actors.y_sort_enabled = true
	actor_space.add_child(enemy_actors)
	var bars := HpBarView.new()
	bars.world = world
	root.add_child(bars)
	var marks: Node2D = QuestMobMarks.new()
	marks.world = world
	root.add_child(marks)

	var hud := CanvasLayer.new()
	get_root().add_child(hud)
	var overlay: Control = MapOverlay.new()
	overlay.world = world
	overlay.mouse_tile = func() -> Vector2: return p.pos + Vector2(6.0, 0.0)
	overlay.grid_size = Vector2i(int(arena.def.width), int(arena.def.height))
	_check(overlay.load_minimap(PACK + "minimap.png"), "b77 minimap loads")
	hud.add_child(overlay)

	var cam := Camera2D.new()
	# Frames the settled pack with headroom: the marked bandit keeps
	# range near the camp ring (~138.7) — its bar + mark need the
	# ~20 world-px above its head inside the frame at zoom 2.
	cam.position = Vector2(108.5, 139.5) * TILE
	cam.zoom = Vector2(2.0, 2.0)
	root.add_child(cam)

	await process_frame
	# gotcha 41: the Config autoload NODE exists under --script — the
	# designer's live tracked_quest must never steer a capture.
	overlay._cfg = null
	marks._cfg = null
	cam.make_current()
	DisplayServer.window_set_size(Vector2i(640, 360))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))

	# The style option sheet [T — the designer's eyes pick].
	var style_names := {0: "amber", 1: "green", 2: "chevron"}
	for style: int in [0, 1, 2]:
		marks.style = style
		for i in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		var shot := get_root().get_texture().get_image()
		shot.save_png(
			ProjectSettings.globalize_path(
				"res://reports/quest_activity_marks_%s_base.png" % style_names[style]
			)
		)
	marks.style = 0

	# Corner map: the cull region's disc sits at THIS camp — the map
	# hint and the marked mobs tell one story in one frame.
	overlay.cycle()  # corner
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot_corner := get_root().get_texture().get_image()
	shot_corner.save_png(
		ProjectSettings.globalize_path("res://reports/quest_activity_map_corner_base.png")
	)
	overlay.cycle()  # fullscreen: three regions + giver bangs + dot
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot_full := get_root().get_texture().get_image()
	shot_full.save_png(
		ProjectSettings.globalize_path("res://reports/quest_activity_map_full_base.png")
	)
	overlay.cycle()  # off
	overlay.cycle()  # corner again for the desktop leg

	# Desktop leg (the quest_pull pattern verbatim): screen crop,
	# windowed 1440x1080 (2x integer scale, out of toast land),
	# two-point signature guard on STATIC pixels.
	var sig_map := shot_corner.get_pixel(620, 30)
	var sig_ground := shot_corner.get_pixel(20, 340)
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
		var s := floorf(minf(crop.get_width() / 640.0, crop.get_height() / 360.0))
		var off := Vector2i(
			int((crop.get_width() - 640.0 * s) * 0.5), int((crop.get_height() - 360.0 * s) * 0.5)
		)
		var got_map := crop.get_pixel(off.x + int(620.0 * s) + 1, off.y + int(30.0 * s) + 1)
		var got_ground := crop.get_pixel(off.x + int(20.0 * s) + 1, off.y + int(340.0 * s) + 1)
		if _off(got_map, sig_map) or _off(got_ground, sig_ground):
			printerr("quest_activity_probe: desktop crop signature mismatch — NOT written")
		else:
			crop.save_png(
				ProjectSettings.globalize_path("res://reports/quest_activity_desktop.png")
			)
			print("quest_activity_probe: wrote quest_activity_desktop.png")
	else:
		printerr("quest_activity_probe: screen_get_image unavailable — desktop NOT captured")

	if fails.is_empty():
		print("quest_activity_probe: PASS — wrote 3 style + 2 map base captures")
		quit(0)
	else:
		for m: String in fails:
			printerr("quest_activity_probe FAIL: " + m)
		quit(1)


static func _off(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) > 0.12 or absf(a.g - b.g) > 0.12 or absf(a.b - b.b) > 0.12
