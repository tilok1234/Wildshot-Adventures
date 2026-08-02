## One-shot WINDOWED render probe (slice S0 seam 4): the stationed NPC
## crowd must actually DRAW at the harbor capital — sheets imported,
## frames built, y-sort space accepted them. Replicates main's
## construction (world_builder + ActorSortSpace) + the real NpcView.
## Captures reports/npc_render_audit_capital.png (the settlement crowd
## around the spawn) — committed evidence, read by eyes before the
## seam ships (gotcha 13: headless gates cannot see render bugs).
## Run WITHOUT --headless:
##   godot_console --path . --script tests/wiring/npc_render_probe.gd
extends SceneTree

const WorldBuilder := preload("res://game/arena/world_builder.gd")
const RenderLayers := preload("res://game/render_layers.gd")
const AssemblerLibrary := preload("res://game/views/assembler_library.gd")
const NpcView := preload("res://game/views/npc_view.gd")
const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")

const PACK := "res://assets/worldforge-packs/wildshot-overworld-pack-dusk/"
const CONTENT := "res://assets/wildshot-overworld-pack-dusk-content/"
const TILE := 32
const SPAWN := Vector2(109.5, 182.5)
const ZOOM := 2.5


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
	actor_space.name = "ActorSortSpace"
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
	print("npc_render_probe: %d stations" % npcs.station_count())
	var cam := Camera2D.new()
	cam.position = SPAWN * TILE
	cam.zoom = Vector2(ZOOM, ZOOM)
	root.add_child(cam)

	await process_frame
	cam.make_current()
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/npc_render_audit_capital.png"))
	print("npc_render_probe: wrote reports/npc_render_audit_capital.png")
	# sl-0132 desync readout: the crowd must NOT breathe in lockstep —
	# count distinct (frame, progress-bucket) pairs and speed scales
	# across the stationed sprites. All-identical = the lockstep bug.
	var phases := {}
	var speeds := {}
	var sprites := 0
	for c: Node in npcs.get_children():
		if c is AnimatedSprite2D:
			sprites += 1
			var sp := c as AnimatedSprite2D
			phases["%d:%d" % [sp.frame, int(sp.frame_progress * 8.0)]] = true
			speeds["%.3f" % sp.speed_scale] = true
	print(
		(
			"npc_render_probe: desync spread — %d sprites, %d distinct phases, %d distinct speeds"
			% [sprites, phases.size(), speeds.size()]
		)
	)
	if sprites > 4 and (phases.size() < 3 or speeds.size() < 3):
		printerr("npc_render_probe: crowd reads LOCKSTEP — desync regressed")
		quit(1)
		return
	quit(0)
