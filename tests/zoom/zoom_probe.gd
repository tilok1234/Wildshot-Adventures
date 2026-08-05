## One-shot WINDOWED render probe (sl-0222/0223 — THE ZOOM OPTION):
## the three game-zoom levels through the REAL follow camera class on
## real arena ground + real actor sheets, captured at BOTH scales per
## level — the pixel-integrity side-by-side the designer's eyes rule
## on (2x = pixel-exact integer; 1.5x = nearest-neighbor fractional
## stepping, shipped honest; 1x = today's view). The LIVE option
## wiring (options row -> Config -> the camera) is proven separately
## by the core50 pair; this probe is the optics evidence.
## Captures: reports/zoom_option_{1x,15x,2x}_{base,desktop}.png
## Run WITHOUT --headless:
##   godot_console --path . --script tests/zoom/zoom_probe.gd
extends SceneTree

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const DodgeProof := preload("res://game/bots/dodge_proof.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")
const AssemblerLibrary := preload("res://game/views/assembler_library.gd")
const AnimatedActor := preload("res://game/views/animated_actor.gd")
const CameraRig := preload("res://game/views/camera_rig.gd")
const InputFrame := preload("res://sim/input_frame.gd")

const TILE := 32.0
const LEVELS: Array = [[1.0, "1x"], [1.5, "15x"], [2.0, "2x"]]

var _fails := 0


func _init() -> void:
	_run()


func _capture_pair(name: String) -> void:
	await process_frame
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/zoom_option_%s_base.png" % name))
	print("zoom_probe: wrote zoom_option_%s_base.png" % name)
	var sig_a := shot.get_pixel(24, 24)
	var sig_b := shot.get_pixel(616, 336)
	await RenderingServer.frame_post_draw
	var screen := DisplayServer.screen_get_image(DisplayServer.window_get_current_screen())
	if screen == null:
		printerr("zoom_probe: screen_get_image unavailable — desktop NOT captured")
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
		printerr("zoom_probe: %s desktop signature mismatch — NOT written" % name)
		_fails += 1
		return
	crop.save_png(ProjectSettings.globalize_path("res://reports/zoom_option_%s_desktop.png" % name))
	print(
		(
			"zoom_probe: wrote zoom_option_%s_desktop.png (%dx%d)"
			% [name, crop.get_width(), crop.get_height()]
		)
	)


static func _off(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) > 0.12 or absf(a.g - b.g) > 0.12 or absf(a.b - b.b) > 0.12


func _run() -> void:
	# Gotcha-42 recorded shape: forced WINDOWED 1440x1080 at (0,0).
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_position(Vector2i(0, 0))
	DisplayServer.window_set_size(Vector2i(1440, 1080))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_move_to_foreground()

	var scenario: Resource = load("res://data/scenarios/lab_default.tres")
	var grid: RefCounted = DodgeProof._build_bitgrid(String(scenario.arena))
	var world: RefCounted = ScenarioLoader.build_world(scenario, 1, grid)
	CharacterProfile.apply_to_world(world, CharacterProfile.create(false, "bow"))
	var p: RefCounted = world.players[0]
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
		# A wolf body one tile off — a second pixel-art silhouette for
		# the integrity comparison (edges are where 1.5x shows itself).
		var wolf_frames: SpriteFrames = lib.build_sprite_frames("wolf:gray")
		if wolf_frames != null:
			var wolf := AnimatedSprite2D.new()
			wolf.sprite_frames = wolf_frames
			wolf.scale = Vector2.ONE * lib.render_scale()
			wolf.position = Vector2(26.5, 12.5) * TILE
			wolf.play("idle-down")
			root.add_child(wolf)
	# The REAL follow camera class, zoomed exactly as main's
	# _apply_game_zoom does (main cannot compile under --script — the
	# live wiring is the core50 pair's proof).
	var cam := CameraRig.new()
	cam.world = world
	root.add_child(cam)
	cam.setup(48, 24)
	world.step([InputFrame.new()])

	await process_frame
	cam.make_current()

	for lv: Array in LEVELS:
		cam.zoom = Vector2.ONE * float(lv[0])
		await _capture_pair(String(lv[1]))

	if _fails > 0:
		printerr("zoom_probe: %d capture legs failed" % _fails)
		quit(1)
		return
	print("zoom_probe: all three levels captured at both scales")
	quit(0)
