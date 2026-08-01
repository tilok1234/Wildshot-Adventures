## One-shot WINDOWED render probe (sl-0065): captures the dev map
## overlay's two modes over the b77 overworld so committed PNGs are
## the render evidence (headless boots cannot see render bugs).
## Replicates main's construction: world via world_builder, the REAL
## overlay on a CanvasLayer, a stub player at the pack spawn cell with
## a fixed east aim so captures are stable. NOT a fixed gate — run at
## seams that touch the overlay, then eyeball + commit the captures:
##   reports/dev_map_audit_b77_corner.png   corner minimap over town
##   reports/dev_map_audit_b77_full.png     fullscreen map + dot
## Run WITHOUT --headless (needs the rendering server):
##   godot_console --path . --script tests/dev_map/map_overlay_probe.gd
extends SceneTree

const WorldBuilder := preload("res://game/arena/world_builder.gd")
const MapOverlay := preload("res://game/dev/map_overlay.gd")

const PACK := "res://assets/worldforge-packs/wildshot-overworld-pack-dusk/"
const TILE := 32.0
const SPAWN := Vector2(109.5, 182.5)


class StubActor:
	var pos := Vector2.ZERO


class StubWorld:
	var players: Array = []


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
	var cam := Camera2D.new()
	cam.position = SPAWN * TILE
	cam.zoom = Vector2(1.5, 1.5)
	root.add_child(cam)

	var actor := StubActor.new()
	actor.pos = SPAWN
	var stub := StubWorld.new()
	stub.players = [actor]
	var overlay: Control = MapOverlay.new()
	overlay.world = stub
	overlay.mouse_tile = func() -> Vector2: return SPAWN + Vector2(6.0, 0.0)
	overlay.grid_size = Vector2i(int(arena.def.width), int(arena.def.height))
	if not overlay.load_minimap(PACK + "minimap.png"):
		printerr("FAIL: b77 minimap.png did not load")
		quit(1)
		return
	var hud := CanvasLayer.new()
	hud.add_child(overlay)
	get_root().add_child(hud)

	await process_frame
	cam.make_current()
	overlay.cycle()  # corner
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/dev_map_audit_b77_corner.png"))

	overlay.cycle()  # fullscreen
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	shot = get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/dev_map_audit_b77_full.png"))
	print(
		(
			"dev map audit captured: reports/dev_map_audit_b77_{corner,full}.png (spawn %s, grid %s)"
			% [str(SPAWN), str(overlay.grid_size)]
		)
	)
	quit(0)
