## One-shot WINDOWED render probe (b77 intake, sl-0066's game-side check):
## the pack tmj's props-overhang layer must draw ABOVE the player, or
## walk-under canopy reads as standing on the treetop. Replicates main's
## exact construction: world_builder output (props-overhang gets the
## CANOPY band there), sort_layers reparented into a y-sorted ACTORS-band
## space (the ActorSortSpace contract), the player as an ACTORS-band
## sprite inside that space (character-ranger sheet, 24px cell). Site:
## walkable crown cell (110,176), seven cells from the b77 spawn, trunk
## solid at (110,177); a control ranger stands on open ground at
## (108,176). Captures:
##   reports/canopy_render_audit_b77_under.png      ranger AT the crown
##   reports/canopy_render_audit_b77_reference.png  same frame, crown
##                                                  ranger hidden
## The verdict is MECHANIZED by tools-side pixel diff (the crown tile's
## opaque mask must be byte-identical across both shots — the ranger
## under it changes nothing — while his out-of-mask pixels differ):
##   python <scratch>/canopy_mask_verdict.py   (committed evidence = the
## two PNGs; the verdict line goes in the intake record). Run WITHOUT
## --headless (windowed; needs the rendering server):
##   godot_console --path . --script tests/worldforge_pack/canopy_render_probe.gd
extends SceneTree

const WorldBuilder := preload("res://game/arena/world_builder.gd")
const RenderLayers := preload("res://game/render_layers.gd")

const PACK := "res://assets/worldforge-packs/wildshot-overworld-pack-dusk/"
const TILE := 32
const CROWN_CELL := Vector2(110.5, 176.5)
const OPEN_CELL := Vector2(108.5, 176.5)
const ZOOM := 5.0


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
	var actor_space := Node2D.new()
	actor_space.name = "ActorSortSpace"
	actor_space.y_sort_enabled = true
	actor_space.z_index = RenderLayers.ACTORS
	root.add_child(actor_space)
	for layer: Node in arena.sort_layers:
		layer.get_parent().remove_child(layer)
		actor_space.add_child(layer)
	var tex: Texture2D = load("res://assembler/players/character-ranger.png")
	var under := Sprite2D.new()
	under.texture = tex
	under.region_enabled = true
	under.region_rect = Rect2(0, 0, 24, 24)
	under.position = CROWN_CELL * TILE
	actor_space.add_child(under)
	var beside := Sprite2D.new()
	beside.texture = tex
	beside.region_enabled = true
	beside.region_rect = Rect2(0, 0, 24, 24)
	beside.position = OPEN_CELL * TILE
	actor_space.add_child(beside)
	var cam := Camera2D.new()
	cam.position = CROWN_CELL * TILE
	cam.zoom = Vector2(ZOOM, ZOOM)
	root.add_child(cam)

	await process_frame
	cam.make_current()
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var shot_a := get_root().get_texture().get_image()
	shot_a.save_png(
		ProjectSettings.globalize_path("res://reports/canopy_render_audit_b77_under.png")
	)

	under.visible = false
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot_b := get_root().get_texture().get_image()
	shot_b.save_png(
		ProjectSettings.globalize_path("res://reports/canopy_render_audit_b77_reference.png")
	)
	print(
		(
			"canopy render audit captured: reports/canopy_render_audit_b77_{under,reference}.png (crown cell 110,176 zoom %d; ACTORS %d < CANOPY %d)"
			% [int(ZOOM), RenderLayers.ACTORS, RenderLayers.CANOPY]
		)
	)
	quit(0)
