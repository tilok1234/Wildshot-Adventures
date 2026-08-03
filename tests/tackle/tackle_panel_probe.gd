## One-shot WINDOWED render probe (sl-0177/0178): THE TACKLE PANEL —
## the fish wallet in the head, the tiered catalog with every row
## state on screen at once (level-grant spine, owned, worn, equip
## chip, affordable + unaffordable fish prices, gated-tier note).
## Captures (committed, read by eyes; desktop = screen crop per the
## rift_split discipline):
##   reports/tackle_panel_audit_base.png
##   reports/tackle_panel_audit_desktop.png
## Run WITHOUT --headless:
##   godot_console --path . --script tests/tackle/tackle_panel_probe.gd
extends SceneTree

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const DodgeProof := preload("res://game/bots/dodge_proof.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")
const AssemblerLibrary := preload("res://game/views/assembler_library.gd")
const AnimatedActor := preload("res://game/views/animated_actor.gd")
const TacklePanel := preload("res://ui/tackle_panel.gd")
const TackleCatalog := preload("res://sim/tackle_catalog.gd")

const TILE := 32.0


func _init() -> void:
	_run()


func _run() -> void:
	var scenario: Resource = load("res://data/scenarios/lab_default.tres")
	var grid: RefCounted = DodgeProof._build_bitgrid(String(scenario.arena))
	var world: RefCounted = ScenarioLoader.build_world(scenario, 1, grid)
	var prof := CharacterProfile.create(false, "bow")
	# A mid-journey rifter: starhook 3 (T1/T2 open, T3/T4 gated), one
	# rod owned, the T1 chest WORN, the T1 helm owned-not-worn (the
	# equip chip), a wallet that affords some shelves and not others —
	# every row state lands in the first screen.
	prof.starhook_level = 3
	prof.starhook_fish = {
		"emberwisp_koi": 4, "icetail_darter": 3, "hollow_angler": 2, "silence_carp": 1
	}
	prof.starhook_rods = ["rod_fan_t1"]
	prof.starhook_tackle = ["chest_t1", "helm_t1"]
	prof.starhook_chest = "chest_t1"
	CharacterProfile.apply_to_world(world, prof)
	var p: RefCounted = world.players[0]
	p.pos = Vector2(24.0, 12.5)
	p.prev_pos = p.pos
	world.tackle_cell = p.pos
	for srow: Dictionary in TackleCatalog.shelf_rows(world.stat_frame):
		var rd := TackleCatalog.row_data(world.stat_frame, srow)
		var price_idx := TackleCatalog.resolve_price(world.stat_frame, rd.get("price", {}))
		(
			world
			. tackle_shelf
			. append(
				{
					"row_kind": int(srow.row_kind),
					"index": int(srow.index),
					"tier": int(rd.get("tier", 0)),
					"price_idx": price_idx,
				}
			)
		)

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
	var cam := Camera2D.new()
	cam.position = p.pos * TILE
	cam.zoom = Vector2(2.0, 2.0)
	root.add_child(cam)
	var hud := CanvasLayer.new()
	get_root().add_child(hud)
	var panel: Control = TacklePanel.new()
	panel.world = world
	panel.character = prof
	panel.theme = load("res://ui/theme.tres")
	# Stations open on F (sl-0145) — the probe stands in for the press.
	panel.station_open()
	hud.add_child(panel)

	await process_frame
	cam.make_current()
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/tackle_panel_audit_base.png"))
	print("tackle_panel_probe: wrote tackle_panel_audit_base.png")

	var sig_a := shot.get_pixel(30, 30)
	var sig_b := shot.get_pixel(610, 330)
	DisplayServer.window_set_position(Vector2i(0, 0))
	DisplayServer.window_set_size(Vector2i(1920, 1080))
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
		var got_a := crop.get_pixel(off.x + int(30.0 * s) + 1, off.y + int(30.0 * s) + 1)
		var got_b := crop.get_pixel(off.x + int(610.0 * s) + 1, off.y + int(330.0 * s) + 1)
		if _off(got_a, sig_a) or _off(got_b, sig_b):
			printerr("tackle_panel_probe: desktop crop signature mismatch — NOT written")
		else:
			crop.save_png(
				ProjectSettings.globalize_path("res://reports/tackle_panel_audit_desktop.png")
			)
			print(
				(
					"tackle_panel_probe: wrote tackle_panel_audit_desktop.png (%dx%d)"
					% [crop.get_width(), crop.get_height()]
				)
			)
	else:
		printerr("tackle_panel_probe: screen_get_image unavailable — desktop NOT captured")
	quit(0)


static func _off(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) > 0.12 or absf(a.g - b.g) > 0.12 or absf(a.b - b.b) > 0.12
