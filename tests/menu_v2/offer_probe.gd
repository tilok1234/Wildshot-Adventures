## One-shot WINDOWED render probe (menu pass seam C): THE QUEST OFFER
## DIALOGUE (quest_offer_v2 — plaque title, reread text, objective,
## reward row, Accept primary + Later; NO Decline by sl-0154) plus the
## log detail after an accept. Committed captures, read by eyes:
##   reports/quest_offer_audit.png / quest_offer_audit_scale2.png
##   reports/quest_offer_accepted_log.png
## The sim law lives in quest_test — this probe feeds view state
## directly (masks/pos), never steps the world.
## Run WITHOUT --headless:
##   godot_console --path . --script tests/menu_v2/offer_probe.gd
extends SceneTree

const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")
const CharacterSheet := preload("res://ui/character_sheet.gd")
const QuestOffer := preload("res://ui/quest_offer.gd")
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
	CharacterProfile.apply_to_world(world, prof)
	var p: RefCounted = world.players[0]
	p.quest_progress_arr = PackedInt32Array()
	p.quest_progress_arr.resize(world.quest_defs.size())
	# Stand AT the west-road giver so the walk-away close stays quiet
	# (pure data — the world never steps in this probe).
	var q: Resource = world.quest_defs[2]
	p.pos = q.giver_cell

	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.09, 0.14)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(bg)
	var hud := CanvasLayer.new()
	get_root().add_child(hud)
	var theme: Theme = load("res://ui/theme.tres")
	var offer := QuestOffer.new()
	offer.world = world
	offer.theme = theme
	hud.add_child(offer)
	var sheet := CharacterSheet.new()
	sheet.world = world
	sheet.character = prof
	sheet.theme = theme
	hud.add_child(sheet)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	await _settle(1)
	sheet._cfg = null
	sheet._tab = 0
	offer.offer(2)
	await _settle(10)
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/quest_offer_audit.png"))

	var th2: Theme = theme.duplicate()
	th2.default_base_scale = 2.0
	th2.default_font_size = 20
	offer.theme = th2
	offer.offer(2)
	await _settle(14)
	var shot2 := get_root().get_texture().get_image()
	shot2.save_png(ProjectSettings.globalize_path("res://reports/quest_offer_audit_scale2.png"))

	# After the accept (mask fed directly — the op law is quest_test's):
	# the window self-dismisses and the log carries the errand.
	offer.theme = theme
	p.quests_taken_mask |= 1 << 2
	await _settle(4)
	var offer_closed := not offer.visible
	sheet._tracked_id = String(world.quest_defs[2].id)
	sheet._sel_qi = 2
	sheet.open_tab(1)
	await _settle(10)
	var shot3 := get_root().get_texture().get_image()
	shot3.save_png(ProjectSettings.globalize_path("res://reports/quest_offer_accepted_log.png"))
	if not offer_closed:
		printerr("offer_probe: window did NOT self-dismiss on accept")
		quit(1)
		return
	print("offer_probe: wrote quest_offer_audit(.png|_scale2.png) + quest_offer_accepted_log.png")
	quit(0)


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
