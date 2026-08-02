## One-shot WINDOWED render probe (S1 seam 6, sl-0105): the STARHOOK
## split-screen geometry — the rift arena renders ENTIRELY left of
## the world-sliver line (Law 1 by construction: no fight pixel can
## hide under the sliver), the sliver mounts at the right ~1/4 with
## the seam line. Uses a synthetic world capture (presentation is
## presentation). Captures reports/rift_split_audit.png — committed
## evidence, read by eyes.
## Run WITHOUT --headless:
##   godot_console --path . --script tests/rift_split/rift_split_probe.gd
extends SceneTree

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")

const TILE := 32


func _init() -> void:
	_run()


func _run() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	var arena := ArenaBuilder.build_arena(root, "res://data/arena_rift.json")
	if arena.is_empty():
		printerr("FAIL: rift arena did not build")
		quit(1)
		return
	var cam := Camera2D.new()
	cam.position = Vector2(7.5, 6) * TILE
	root.add_child(cam)
	var sliver_layer := CanvasLayer.new()
	sliver_layer.layer = 40
	get_root().add_child(sliver_layer)
	var capture := Image.create(320, 640, false, Image.FORMAT_RGB8)
	capture.fill(Color(0.25, 0.32, 0.22))
	var sliver := TextureRect.new()
	sliver.texture = ImageTexture.create_from_image(capture)
	sliver.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sliver.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sliver.anchor_left = 0.75
	sliver.anchor_right = 1.0
	sliver.anchor_top = 0.0
	sliver.anchor_bottom = 1.0
	sliver.modulate = Color(0.55, 0.55, 0.65, 1.0)
	sliver_layer.add_child(sliver)
	var seam_line := ColorRect.new()
	seam_line.color = Color(0.9, 0.85, 0.6, 0.85)
	seam_line.anchor_left = 0.75
	seam_line.anchor_right = 0.75
	seam_line.anchor_top = 0.0
	seam_line.anchor_bottom = 1.0
	seam_line.offset_left = -1.0
	seam_line.offset_right = 2.0
	sliver_layer.add_child(seam_line)

	await process_frame
	cam.make_current()
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/rift_split_audit.png"))
	print("rift_split_probe: wrote reports/rift_split_audit.png")
	quit(0)
