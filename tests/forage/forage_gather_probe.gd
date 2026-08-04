## One-shot WINDOWED render probe (sl-0198 — THE FORAGING BUILD): the
## GATHER SEQUENCE end to end on real machinery, captured at BOTH
## scales per stage (the walked-content evidence discipline — the new
## visible content is screen-checked, read by eyes):
##   1 shimmer  — a live forage node's WYSIWYG marker + the [F] prompt
##   2 bar      — mid-gather, the bar filling at the node
##   3 bag      — completion: the loot bag + the walk-over LOOT panel
##   4 inv      — after [B] loot-all: the C sheet's forage materials
##                tiles with the count badge
## Captures (committed, read by eyes; desktop = screen crop, gotcha-42
## shape: forced WINDOWED 1440x1080 at (0,0), letterbox-aware
## two-point signature guard on STATIC pixels):
##   reports/forage_gather_{shimmer,bar,bag,inv}_{base,desktop}.png
## Run WITHOUT --headless:
##   godot_console --path . --script tests/forage/forage_gather_probe.gd
extends SceneTree

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const DodgeProof := preload("res://game/bots/dodge_proof.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")
const AssemblerLibrary := preload("res://game/views/assembler_library.gd")
const AnimatedActor := preload("res://game/views/animated_actor.gd")
const ForageNodesView := preload("res://game/views/forage_nodes_view.gd")
const LootBagPanel := preload("res://ui/loot_bag_panel.gd")
const CharacterSheet := preload("res://ui/character_sheet.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")

const TILE := 32.0

var _world: RefCounted = null
var _fails := 0


func _init() -> void:
	_run()


func _frame(interact := false, bag_op := 0) -> RefCounted:
	var f: RefCounted = InputFrame.new()
	f.interact_pressed = interact
	f.bag_op = bag_op
	return f


func _capture_pair(name: String) -> void:
	await process_frame
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/forage_gather_%s_base.png" % name))
	print("forage_gather_probe: wrote forage_gather_%s_base.png" % name)
	# Desktop leg: screen crop of the presented window with the
	# letterbox-aware two-point signature guard on STATIC pixels
	# (arena floor corners — never the animated shimmer).
	var sig_a := shot.get_pixel(24, 24)
	var sig_b := shot.get_pixel(616, 336)
	await RenderingServer.frame_post_draw
	var screen := DisplayServer.screen_get_image(DisplayServer.window_get_current_screen())
	if screen == null:
		printerr("forage_gather_probe: screen_get_image unavailable — desktop NOT captured")
		_fails += 1
		return
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
	var got_a := crop.get_pixel(off.x + int(24.0 * s) + 1, off.y + int(24.0 * s) + 1)
	var got_b := crop.get_pixel(off.x + int(616.0 * s) + 1, off.y + int(336.0 * s) + 1)
	if _off(got_a, sig_a) or _off(got_b, sig_b):
		printerr("forage_gather_probe: %s desktop signature mismatch — NOT written" % name)
		_fails += 1
		return
	crop.save_png(
		ProjectSettings.globalize_path("res://reports/forage_gather_%s_desktop.png" % name)
	)
	print(
		(
			"forage_gather_probe: wrote forage_gather_%s_desktop.png (%dx%d)"
			% [name, crop.get_width(), crop.get_height()]
		)
	)


static func _off(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) > 0.12 or absf(a.g - b.g) > 0.12 or absf(a.b - b.b) > 0.12


func _run() -> void:
	# Gotcha-42 recorded shape FIRST: forced WINDOWED 1440x1080 at
	# (0,0), topmost — the 2x integer scale, out of toast land.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_position(Vector2i(0, 0))
	DisplayServer.window_set_size(Vector2i(1440, 1080))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_move_to_foreground()

	var scenario: Resource = load("res://data/scenarios/lab_default.tres")
	var grid: RefCounted = DodgeProof._build_bitgrid(String(scenario.arena))
	_world = ScenarioLoader.build_world(scenario, 1, grid)
	var prof := CharacterProfile.create(false, "bow")
	CharacterProfile.apply_to_world(_world, prof)
	var p: RefCounted = _world.players[0]
	p.pos = Vector2(24.5, 12.5)
	p.prev_pos = p.pos
	# The forage pool + ONE live node a tile east (in REACH), real
	# vocabulary — the shimmer, bar, bag, and tiles all read state.
	var ids: Array[String] = ["stump", "fallen_log", "bush", "mushrooms"]
	_world.set_forage_pool(PackedVector2Array([Vector2(25.5, 12.5)]), PackedInt32Array([2]), ids)
	_world.forage_nodes_pos.append(Vector2(25.5, 12.5))
	_world.forage_nodes_species.append(2)

	var root := Node2D.new()
	get_root().add_child(root)
	var arena := ArenaBuilder.build_arena(root, String(scenario.arena))
	if arena.is_empty():
		printerr("FAIL: lab arena did not build")
		quit(1)
		return
	var lib := AssemblerLibrary.new()
	var sheet_map: Resource = load("res://data/actor_sheet_map.tres")
	if lib.load_manifest():
		var ranger := AnimatedActor.new()
		ranger.sprite_frames = lib.build_sprite_frames(String(sheet_map.map.player))
		ranger.actor = p
		ranger.render_scale = lib.render_scale()
		ranger.play("idle-down")
		root.add_child(ranger)
	var forage_view := ForageNodesView.new()
	forage_view.world = _world
	root.add_child(forage_view)
	var cam := Camera2D.new()
	cam.position = p.pos * TILE
	cam.zoom = Vector2(2.0, 2.0)
	root.add_child(cam)
	var hud := CanvasLayer.new()
	get_root().add_child(hud)
	var loot_panel: Control = LootBagPanel.new()
	loot_panel.world = _world
	loot_panel.theme = load("res://ui/theme.tres")
	hud.add_child(loot_panel)

	await process_frame
	cam.make_current()

	# STAGE 1 — the shimmer (a live node, no gather yet).
	_world.step([_frame()])
	await _capture_pair("shimmer")

	# STAGE 2 — the bar mid-fill: press F, then hold still ~60%.
	_world.step([_frame(true)])
	var bar_ticks := int((_world.stat_frame.get("forage", {}) as Dictionary).get("bar_ticks", 45))
	for i in int(bar_ticks * 0.6):
		_world.step([_frame()])
	if p.forage_ticks <= 0:
		printerr("FAIL: the gather bar never armed")
		quit(1)
		return
	await _capture_pair("bar")

	# STAGE 3 — completion: the loot bag drops from the node; stand on
	# it so the walk-over LOOT panel shows.
	while _world.loot_bags.is_empty() and p.forage_ticks > 0:
		_world.step([_frame()])
	if _world.loot_bags.is_empty():
		printerr("FAIL: the gather never completed")
		quit(1)
		return
	p.pos = Vector2(25.5, 12.5)
	p.prev_pos = p.pos
	cam.position = p.pos * TILE
	_world.step([_frame()])
	await _capture_pair("bag")

	# STAGE 4 — [B] loot-all lands the kin in the wallet; the C sheet
	# shows the forage materials tiles with the count badge.
	_world.step([_frame(false, BagStep.OP_LOOT_ALL)])
	if p.forage_mats.is_empty() or p.forage_mats[2] < 1:
		printerr("FAIL: the kin never landed in the wallet")
		quit(1)
		return
	var sheet := CharacterSheet.new()
	sheet.world = _world
	sheet.character = prof
	sheet.theme = load("res://ui/theme.tres")
	hud.add_child(sheet)
	# Gotcha #41: null the Config handle — deterministic character tab,
	# never the designer's real last-tab (nor their settings.cfg).
	sheet._cfg = null
	sheet.open_tab(0)
	await _capture_pair("inv")

	if _fails > 0:
		printerr("forage_gather_probe: %d capture legs failed" % _fails)
		quit(1)
		return
	print("forage_gather_probe: all four stages captured at both scales")
	quit(0)
