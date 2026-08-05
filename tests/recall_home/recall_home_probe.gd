## One-shot WINDOWED render probe (sl-0221 — THE NIGHT SEAM): the home
## bind + the recall cast on real machinery, captured at BOTH scales
## per stage (the walked-content evidence discipline; the forage-probe
## precedent — lab ground + synthetic settlement tables, REAL view
## classes and REAL sim ops):
##   1 waypost — the waypost body (real npc sheet) + its "Waypost"
##               nameplate (real label derivation) + the player beside
##               it; the SET-HOME op binds and HOME_SET fires (sim
##               truth asserted in the log)
##   2 bar     — mid-recall: the RECALL cast bar + word over the
##               player's own head (recall_view), then the completion
##               teleport asserted
## The refusal line + HUD hint + toasts are main-owned surfaces —
## designer-eyes on the slice (main cannot compile under --script,
## the recorded limit).
## Captures: reports/recall_home_{waypost,bar}_{base,desktop}.png
## Run WITHOUT --headless:
##   godot_console --path . --script tests/recall_home/recall_home_probe.gd
extends SceneTree

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const DodgeProof := preload("res://game/bots/dodge_proof.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")
const AssemblerLibrary := preload("res://game/views/assembler_library.gd")
const AnimatedActor := preload("res://game/views/animated_actor.gd")
const RecallView := preload("res://game/views/recall_view.gd")
const NpcNameplates := preload("res://game/views/npc_nameplates.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")
const GatherStep := preload("res://sim/systems/gather_step.gd")
const SimEvents := preload("res://sim/events.gd")

const TILE := 32.0

var _world: RefCounted = null
var _fails := 0


func _init() -> void:
	_run()


func _frame(bag_op := 0) -> RefCounted:
	var f: RefCounted = InputFrame.new()
	f.bag_op = bag_op
	return f


func _capture_pair(name: String) -> void:
	await process_frame
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/recall_home_%s_base.png" % name))
	print("recall_home_probe: wrote recall_home_%s_base.png" % name)
	# Desktop leg: screen crop, letterbox-aware two-point signature
	# guard on STATIC pixels (arena floor corners — never the bar).
	var sig_a := shot.get_pixel(24, 24)
	var sig_b := shot.get_pixel(616, 336)
	await RenderingServer.frame_post_draw
	var screen := DisplayServer.screen_get_image(DisplayServer.window_get_current_screen())
	if screen == null:
		printerr("recall_home_probe: screen_get_image unavailable — desktop NOT captured")
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
		printerr("recall_home_probe: %s desktop signature mismatch — NOT written" % name)
		_fails += 1
		return
	crop.save_png(ProjectSettings.globalize_path("res://reports/recall_home_%s_desktop.png" % name))
	print(
		(
			"recall_home_probe: wrote recall_home_%s_desktop.png (%dx%d)"
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
	# Synthetic settlement tables on the lab ground (the gather_test
	# shape): the waypost one tile east of the player's stand.
	_world.settlement_ids = PackedStringArray(["capital", "waystation"])
	_world.settlement_cells = PackedVector2Array([Vector2(24.5, 12.5), Vector2(12.5, 12.5)])
	_world.waypost_cells = PackedVector2Array([Vector2(25.5, 12.5), Vector2(12.5, 13.5)])
	_world.respawn_cell = Vector2(24.5, 12.5)
	var p: RefCounted = _world.players[0]
	p.pos = Vector2(24.5, 12.5)
	p.prev_pos = p.pos

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
	# The waypost BODY: the real npc library sheet at the waypost cell
	# + the real nameplate class deriving the plain "Waypost" word.
	var lib_npc := AssemblerLibrary.new()
	lib_npc.manifest_path = "res://npcs/manifest.json"
	lib_npc.sheet_root = "res://npcs/"
	if lib_npc.load_manifest():
		var guard_frames: SpriteFrames = lib_npc.build_sprite_frames("capital-gate-guard")
		if guard_frames != null:
			var guard := AnimatedSprite2D.new()
			guard.sprite_frames = guard_frames
			guard.scale = Vector2.ONE * lib_npc.render_scale()
			guard.position = Vector2(25.5, 12.5) * TILE
			guard.play("idle-down")
			root.add_child(guard)
	var plates := NpcNameplates.new()
	var stations: Array[Dictionary] = [
		{
			"id": "capital-gate-guard",
			"cell": Vector2(25.5, 12.5),
			"def_cell": Vector2(25.5, 12.5),
		}
	]
	plates.stations = stations
	root.add_child(plates)
	var recall_view := RecallView.new()
	recall_view.world = _world
	root.add_child(recall_view)
	var cam := Camera2D.new()
	cam.position = p.pos * TILE
	cam.zoom = Vector2(2.0, 2.0)
	root.add_child(cam)

	await process_frame
	cam.make_current()

	# STAGE 1 — the waypost: body + plate on screen; the SET-HOME op
	# fires HOME_SET (sim truth — the player stands in radius; note
	# home starts 0 so we bind the OTHER waypost first to prove the
	# change, then bind THIS one for the shot).
	_world.step([_frame()])
	await _capture_pair("waypost")
	p.pos = Vector2(12.5, 13.5)
	_world.step([_frame(BagStep.OP_SET_HOME)])
	var bound := false
	for ev: Dictionary in _world.events:
		if int(ev.type) == SimEvents.Type.HOME_SET and int(ev.get("town", -1)) == 1:
			bound = true
	if not bound or int(p.home_town) != 1:
		printerr("FAIL: the SET-HOME op never bound the waystation")
		quit(1)
		return

	# STAGE 2 — the recall cast bar, mid-fill over the player's head.
	p.pos = Vector2(24.5, 12.5)
	p.prev_pos = p.pos
	_world.step([_frame(BagStep.OP_RECALL)])
	for i in 70:
		_world.step([_frame()])
	if p.forage_target != GatherStep.RECALL_TARGET or p.forage_ticks < 60:
		printerr("FAIL: the recall cast never armed")
		quit(1)
		return
	await _capture_pair("bar")

	# Completion truth: the teleport lands at the SET home.
	while p.forage_target == GatherStep.RECALL_TARGET:
		_world.step([_frame()])
	if p.pos != Vector2(12.5, 12.5):
		printerr("FAIL: the completed recall never landed home (pos %s)" % str(p.pos))
		quit(1)
		return
	print("recall_home_probe: HOME_SET + cast + teleport all truthed in-sim")

	if _fails > 0:
		printerr("recall_home_probe: %d capture legs failed" % _fails)
		quit(1)
		return
	print("recall_home_probe: both stages captured at both scales")
	quit(0)
