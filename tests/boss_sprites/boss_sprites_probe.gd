## One-shot WINDOWED render probe (sl-0122): the boss looks on real
## renderers — KING GRUBB on the 48px boss:goblin-war-crown sheet
## (rebind), OLD TUSK on boar:blood at the per-def render scale [T
## 1.25], a plain goblin + the ranger beside them for scale truth,
## overhead HP bars at the UNCHANGED sim radius (the 24px-hurtbox
## honesty note stays visible). Static lineup — the world is never
## stepped. Captures (committed, read by eyes; desktop = screen crop
## per the rift_split discipline):
##   reports/boss_sprites_audit_base.png
##   reports/boss_sprites_audit_desktop.png
## Run WITHOUT --headless:
##   godot_console --path . --script tests/boss_sprites/boss_sprites_probe.gd
extends SceneTree

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const DodgeProof := preload("res://game/bots/dodge_proof.gd")
const AssemblerLibrary := preload("res://game/views/assembler_library.gd")
const EnemyActorsView := preload("res://game/views/enemy_actors_view.gd")
const AnimatedActor := preload("res://game/views/animated_actor.gd")
const HpBarView := preload("res://game/views/hp_bar_view.gd")

const TILE := 32.0


func _init() -> void:
	_run()


func _run() -> void:
	var scenario: Resource = load("res://data/scenarios/lab_default.tres")
	var grid: RefCounted = DodgeProof._build_bitgrid(String(scenario.arena))
	var world: RefCounted = ScenarioLoader.build_world(scenario, 1, grid)
	world.players[0].pos = Vector2(19.4, 13.5)
	world.players[0].prev_pos = world.players[0].pos
	# The lineup, in the proven-open lab pocket: goblin / plain boar
	# (the 1.0 control) / OLD TUSK (scaled 1.25) / KING GRUBB
	# (war-crown 48px).
	world.add_enemy(9, Vector2(21.0, 12.5))
	world.add_enemy(10, Vector2(22.8, 12.5))
	world.add_enemy(22, Vector2(25.0, 12.5))
	world.add_enemy(23, Vector2(27.6, 12.5))

	var root := Node2D.new()
	get_root().add_child(root)
	var arena := ArenaBuilder.build_arena(root, String(scenario.arena))
	if arena.is_empty():
		printerr("FAIL: lab arena did not build")
		quit(1)
		return
	var lib := AssemblerLibrary.new()
	if not lib.load_manifest():
		printerr("FAIL: assembler manifest")
		quit(1)
		return
	var sheet_map: Resource = load("res://data/actor_sheet_map.tres")
	var lib_boss := AssemblerLibrary.new()
	lib_boss.manifest_path = "res://assembler_boss/manifest.json"
	lib_boss.sheet_root = "res://assembler_boss/"
	if not lib_boss.load_manifest():
		printerr("FAIL: boss manifest")
		quit(1)
		return
	var enemy_actors := EnemyActorsView.new()
	enemy_actors.world = world
	enemy_actors.lib = lib
	enemy_actors.sheet_map = sheet_map
	enemy_actors.lib_boss = lib_boss
	enemy_actors.y_sort_enabled = true
	root.add_child(enemy_actors)
	var ranger := AnimatedActor.new()
	ranger.sprite_frames = lib.build_sprite_frames(String(sheet_map.map.player))
	ranger.actor = world.players[0]
	ranger.render_scale = lib.render_scale()
	ranger.play("idle-down")
	root.add_child(ranger)
	var bars := HpBarView.new()
	bars.world = world
	root.add_child(bars)
	var cam := Camera2D.new()
	cam.position = Vector2(23.5, 12.8) * TILE
	cam.zoom = Vector2(2.0, 2.0)
	root.add_child(cam)

	await process_frame
	cam.make_current()
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/boss_sprites_audit_base.png"))
	print("boss_sprites_probe: wrote boss_sprites_audit_base.png")

	# Desktop leg: screen crop, topmost-forced, letterbox-aware
	# two-point signature guard on static floor pixels.
	# Signature points on empty floor — clear of the sprite band (the
	# idle frames ANIMATE between the two captures; a point on a body
	# is a false mismatch, learned live at this seam).
	var sig_a := shot.get_pixel(30, 50)
	var sig_b := shot.get_pixel(610, 310)
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
		var got_a := crop.get_pixel(off.x + int(30.0 * s) + 1, off.y + int(50.0 * s) + 1)
		var got_b := crop.get_pixel(off.x + int(610.0 * s) + 1, off.y + int(310.0 * s) + 1)
		if _off(got_a, sig_a) or _off(got_b, sig_b):
			printerr("boss_sprites_probe: desktop crop signature mismatch — NOT written")
		else:
			crop.save_png(
				ProjectSettings.globalize_path("res://reports/boss_sprites_audit_desktop.png")
			)
			print(
				(
					"boss_sprites_probe: wrote boss_sprites_audit_desktop.png (%dx%d)"
					% [crop.get_width(), crop.get_height()]
				)
			)
	else:
		printerr("boss_sprites_probe: screen_get_image unavailable — desktop NOT captured")
	quit(0)


static func _off(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) > 0.12 or absf(a.g - b.g) > 0.12 or absf(a.b - b.b) > 0.12
