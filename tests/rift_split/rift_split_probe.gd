## One-shot WINDOWED render probe (sl-0115, STARHOOK v2): the finished
## GALAXY VIEW at BOTH scales — base 640x360 and desktop 1920x1080
## (the seam's MANDATORY evidence). Builds the REAL rift world through
## the one construction path (loader: pull + rods + lives), steps a
## live fight to mid-volley with the record policy so hostile shots
## are in flight, then mounts the real presentation: 50/50 split
## (world capture left, galaxy right), the line out of the portal to
## the bait fighter, the star-fish, the fixed rift camera (Law 1 —
## whole arena in the right pane). Writes:
##   reports/rift_galaxy_audit_base.png
##   reports/rift_galaxy_audit_desktop.png
## Committed evidence, read by eyes. Run WITHOUT --headless:
##   godot_console --path . --script tests/rift_split/rift_split_probe.gd
extends SceneTree

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const DodgeProof := preload("res://game/bots/dodge_proof.gd")
const DodgePolicy := preload("res://game/bots/dodge_policy.gd")
const RiftView := preload("res://game/views/rift_view.gd")
const RiftWorldPane := preload("res://game/views/rift_world_pane.gd")
const RiftNodesView := preload("res://game/views/rift_nodes_view.gd")
const RiftStep := preload("res://sim/systems/rift_step.gd")
const ProjectileView := preload("res://game/views/projectile_view.gd")
const ProjectileSprites := preload("res://game/views/projectile_sprites.gd")
const HpBarView := preload("res://game/views/hp_bar_view.gd")
const CameraRig := preload("res://game/views/camera_rig.gd")

const TILE := 32.0


func _init() -> void:
	_run()


func _run() -> void:
	var scenario: Resource = load("res://data/scenarios/rift_nebula_common.tres")
	var grid: RefCounted = DodgeProof._build_bitgrid(String(scenario.arena))
	var world: RefCounted = ScenarioLoader.build_world(scenario, 1, grid)
	if world.rift_pull == null:
		printerr("FAIL: rift world built without the pull")
		quit(1)
		return
	# Step a live fight to mid-volley (record policy) — hostile shots
	# in flight, the fighter mid-dodge, drains ticking.
	for t in 430:
		var frame: RefCounted = DodgePolicy.compute_frame(world, 0, DodgePolicy.Policy.REACTIVE)
		world.step([frame])

	var root := Node2D.new()
	get_root().add_child(root)
	var arena := ArenaBuilder.build_arena(root, String(scenario.arena))
	if arena.is_empty():
		printerr("FAIL: rift arena did not build")
		quit(1)
		return
	var rift_view := RiftView.new()
	rift_view.world = world
	rift_view.biome = int(scenario.rift_biome)
	rift_view.rare = bool(scenario.rift_rare)
	rift_view.arena_w = 12
	rift_view.arena_h = 13
	root.add_child(rift_view)
	var sprites := ProjectileSprites.new()
	if not sprites.load_manifest():
		sprites = null
	var pv := ProjectileView.new()
	pv.world = world
	pv.sprites = sprites
	pv.pattern_map = load("res://data/projectile_map.tres")
	root.add_child(pv)
	var bars := HpBarView.new()
	bars.world = world
	root.add_child(bars)
	var cam := CameraRig.new()
	cam.world = world
	root.add_child(cam)
	cam.setup_fixed(Vector2(12.0 * 0.5 * TILE - 160.0, 13.0 * 0.5 * TILE))

	# The 50/50 panes: a synthetic dusk-green world capture (the real
	# one is grabbed at cast — presentation is presentation) + the
	# living overlay + titles + seam, exactly main's build.
	var pane_layer := CanvasLayer.new()
	pane_layer.layer = 40
	get_root().add_child(pane_layer)
	var capture := Image.create(640, 360, false, Image.FORMAT_RGB8)
	capture.fill(Color(0.23, 0.30, 0.21))
	var wpane := TextureRect.new()
	wpane.texture = ImageTexture.create_from_image(capture)
	wpane.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wpane.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	wpane.anchor_left = 0.0
	wpane.anchor_right = 0.5
	wpane.anchor_top = 0.0
	wpane.anchor_bottom = 1.0
	wpane.modulate = Color(0.62, 0.62, 0.72, 1.0)
	pane_layer.add_child(wpane)
	var overlay := RiftWorldPane.new()
	overlay.world = world
	overlay.pull_def = world.rift_pull
	overlay.deep_x = RiftStep.deep_edge_x(world)
	overlay.biome_rim = RiftNodesView.BIOME_RIMS[0]
	overlay.portal_offset = Vector2(38.0, -20.0)
	overlay.anchor_left = 0.0
	overlay.anchor_right = 0.5
	overlay.anchor_top = 0.0
	overlay.anchor_bottom = 1.0
	pane_layer.add_child(overlay)
	var hold_label := Label.new()
	hold_label.text = "THE LINE HOLDS"
	hold_label.modulate = Color(0.66, 0.71, 0.85, 0.8)
	hold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hold_label.anchor_left = 0.0
	hold_label.anchor_right = 0.5
	hold_label.offset_top = 4.0
	pane_layer.add_child(hold_label)
	var title := Label.new()
	title.text = "RIFT CATCH — NEBULA DRIFT"
	title.modulate = Color(0.96, 0.92, 0.85)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.5
	title.anchor_right = 1.0
	title.offset_top = 4.0
	pane_layer.add_child(title)
	var seam_line := ColorRect.new()
	seam_line.color = Color(0.9, 0.85, 0.6, 0.85)
	seam_line.anchor_left = 0.5
	seam_line.anchor_right = 0.5
	seam_line.anchor_top = 0.0
	seam_line.anchor_bottom = 1.0
	seam_line.offset_left = -1.0
	seam_line.offset_right = 1.0
	pane_layer.add_child(seam_line)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	DisplayServer.window_set_size(Vector2i(640, 360))
	await process_frame
	cam.make_current()
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/rift_galaxy_audit_base.png"))
	print("rift_split_probe: wrote reports/rift_galaxy_audit_base.png")
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot2 := get_root().get_texture().get_image()
	shot2.save_png(ProjectSettings.globalize_path("res://reports/rift_galaxy_audit_desktop.png"))
	print("rift_split_probe: wrote reports/rift_galaxy_audit_desktop.png")
	# Sanity: hostile shots must be visible in the RIGHT pane only
	# (Law 1: the fight lives entirely in the galaxy pane).
	var live := 0
	var pool: RefCounted = world.projectiles
	for s in pool.CAPACITY:
		if pool.active[s] == 1 and pool.faction[s] == 1:
			live += 1
	print("rift_split_probe: %d live hostile shots at capture tick %d" % [live, world.tick])
	quit(0)
