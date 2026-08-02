## One-shot WINDOWED render probe (menu pass seam B): THE C MENU on
## the drawn panel2 chrome — tab CHARACTER (portrait/bigbars/statchips
## /dollslots/bag slot grid) and tab QUEST LOG (cards + parchment
## detail + tracked/abandon buttons) over a populated class world.
## Four committed captures (two tabs x two ui scales):
##   reports/menu_character_audit.png / menu_errands_audit.png
##   reports/menu_character_audit_scale2.png / menu_errands_audit_scale2.png
## Committed evidence, read by eyes (gotcha 13).
## Run WITHOUT --headless:
##   godot_console --path . --script tests/menu_v2/menu_probe.gd
extends SceneTree

const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")
const CharacterSheet := preload("res://ui/character_sheet.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")


func _init() -> void:
	_run()


func _run() -> void:
	var grid: RefCounted = Bitgrid.new()
	grid.setup(64, 32)
	var world: RefCounted = ScenarioLoader.build_world(
		load("res://data/scenarios/lab_default.tres"), 1, grid
	)
	var prof := CharacterProfile.create(false, "staff")
	prof.gold = 142
	prof.starhook_level = 3
	prof.starhook_catches = 4
	CharacterProfile.apply_to_world(world, prof)
	var p: RefCounted = world.players[0]
	p.hp = int(p.max_hp * 0.85)
	p.mana = int(p.max_mana * 0.6)
	p.armor_tier = 2
	# A stocked bag: weapon T2 / armor T2 / ring 0 (grammar + icons).
	p.bag = PackedInt32Array([1, 0, 2, 2, 2, 0, 5, 0, 0])
	# Two errands in hand, one progressed (the capture's shape).
	p.quests_taken_mask = 0b00011
	p.quest_progress_arr = PackedInt32Array()
	p.quest_progress_arr.resize(world.quest_defs.size())
	p.quest_progress_arr[0] = 4

	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.09, 0.14)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(bg)
	var hud := CanvasLayer.new()
	get_root().add_child(hud)
	var theme: Theme = load("res://ui/theme.tres")
	var sheet := CharacterSheet.new()
	sheet.world = world
	sheet.character = prof
	sheet.theme = theme
	hud.add_child(sheet)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	# Gotcha 37: _ready defers to the first frame in SceneTree scripts
	# (and sets visible = false) — settle once BEFORE feeding state.
	await _settle(1)
	# Probe determinism: the Config autoload DOES exist under --script
	# runs — null it so the probe neither reads the designer's real
	# settings nor writes menu_tab/tracked keys into them.
	sheet._cfg = null
	sheet._tab = 0
	sheet._tracked_id = "green_cull"
	# toggle() opens on the last-used tab (character by default — no
	# Config under --script); open_tab(0) here would CLOSE (same-tab
	# toggle feel), so don't.
	sheet.toggle()
	await _settle(10)
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/menu_character_audit.png"))
	sheet.open_tab(1)
	await _settle(10)
	var shot2 := get_root().get_texture().get_image()
	shot2.save_png(ProjectSettings.globalize_path("res://reports/menu_errands_audit.png"))

	# UI scale x2 (CORE-50): the menu must stay fully inside 640x360.
	var th2: Theme = theme.duplicate()
	th2.default_base_scale = 2.0
	th2.default_font_size = 20
	sheet.theme = th2
	sheet.open_tab(0)
	await _settle(14)
	var shot3 := get_root().get_texture().get_image()
	shot3.save_png(ProjectSettings.globalize_path("res://reports/menu_character_audit_scale2.png"))
	sheet.open_tab(1)
	await _settle(14)
	var shot4 := get_root().get_texture().get_image()
	shot4.save_png(ProjectSettings.globalize_path("res://reports/menu_errands_audit_scale2.png"))
	print("menu_probe: wrote menu_{character,errands}_audit(.png|_scale2.png)")
	quit(0)


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
