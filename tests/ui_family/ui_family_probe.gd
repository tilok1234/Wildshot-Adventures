## One-shot WINDOWED render probe (seam B, sl-0106 + sl-0109): the
## HUD relayout geometry — SHORT hp/mana bars top-right with the
## corner-minimap slot beneath them (Law 1: the corner is FOR this),
## text readouts bottom-left, hints bottom-right — and the REAL
## character sheet + quest log panel over a populated world. Two
## captures: reports/hud_relayout_audit.png (sheet closed) +
## reports/character_sheet_audit.png (sheet open). Committed
## evidence, read by eyes.
## Run WITHOUT --headless:
##   godot_console --path . --script tests/ui_family/ui_family_probe.gd
extends SceneTree

const SimWorld := preload("res://sim/sim_world.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")
const CharacterSheet := preload("res://ui/character_sheet.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const StatBar := preload("res://ui/stat_bar.gd")


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
	p.quests_taken_mask = 0b00011
	p.quest_progress_arr = PackedInt32Array()
	p.quest_progress_arr.resize(world.quest_defs.size())
	p.quest_progress_arr[0] = 3
	p.hp = int(p.max_hp * 0.7)
	p.mana = int(p.max_mana * 0.4)

	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.15, 0.12)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(bg)
	var hud := CanvasLayer.new()
	get_root().add_child(hud)

	# The relayout geometry, replicated from main (seam B): bars
	# top-right, minimap slot beneath, text bottom-left.
	var theme: Theme = load("res://ui/theme.tres")
	var bars := VBoxContainer.new()
	bars.add_theme_constant_override("separation", 2)
	var hp_bar := StatBar.new()
	hp_bar.fill_tex = load("res://uikit/bar_fill_hp.png")
	hp_bar.custom_minimum_size = Vector2(64.0, 8.0)
	hp_bar.value = 0.7
	var mana_bar := StatBar.new()
	mana_bar.fill_tex = load("res://uikit/bar_fill_mana.png")
	mana_bar.custom_minimum_size = Vector2(64.0, 8.0)
	mana_bar.value = 0.4
	bars.add_child(hp_bar)
	bars.add_child(mana_bar)
	bars.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	bars.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bars.offset_right = -4.0
	bars.offset_top = 4.0
	hud.add_child(bars)
	var mini := ColorRect.new()
	mini.color = Color(0.2, 0.28, 0.2, 0.8)
	mini.custom_minimum_size = Vector2(96, 96)
	mini.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	mini.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	mini.offset_right = -4.0
	mini.offset_top = 28.0
	mini.offset_left = -100.0
	mini.offset_bottom = 124.0
	hud.add_child(mini)
	var text := Label.new()
	text.theme = theme
	text.text = ("[Space] Nova 30mp\nlv 7  xp 379/400  gold 142\nStaff T2 · armor T2\nerrands 2 — [zone_hub] Cull the roads (3/8)")
	text.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	text.grow_vertical = Control.GROW_DIRECTION_BEGIN
	text.offset_left = 4.0
	text.offset_bottom = -4.0
	hud.add_child(text)
	var hints := Label.new()
	hints.theme = theme
	hints.text = "F interact  C sheet  O menu  Esc menu"
	hints.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hints.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hints.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hints.offset_right = -4.0
	hints.offset_bottom = -4.0
	hud.add_child(hints)
	var sheet := CharacterSheet.new()
	sheet.world = world
	sheet.character = prof
	sheet.theme = theme
	hud.add_child(sheet)

	await process_frame
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/hud_relayout_audit.png"))
	sheet.toggle()
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot2 := get_root().get_texture().get_image()
	shot2.save_png(ProjectSettings.globalize_path("res://reports/character_sheet_audit.png"))
	print("ui_family_probe: wrote hud_relayout_audit.png + character_sheet_audit.png")
	quit(0)
