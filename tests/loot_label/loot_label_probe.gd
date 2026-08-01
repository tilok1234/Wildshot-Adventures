## One-shot WINDOWED render probe (S1 seam 2): ground drops of every
## kind + the ONE-GRAMMAR label on the nearest drop must actually DRAW.
## Builds a minimal world with one drop of each kind around the player
## and the real DropView, captures reports/loot_label_audit.png —
## committed evidence, read by eyes before the seam ships (headless
## gates cannot see render bugs).
## Run WITHOUT --headless:
##   godot_console --path . --script tests/loot_label/loot_label_probe.gd
extends SceneTree

const SimWorld := preload("res://sim/sim_world.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const DropView := preload("res://game/views/drop_view.gd")

const TILE := 32


func _init() -> void:
	_run()


func _run() -> void:
	var world: RefCounted = SimWorld.new()
	world.setup(1, null)
	world.set_progression(load("res://data/progression.tres"))
	world.set_stat_frame(StatFrame.load_frame())
	world.set_weapons([load("res://data/weapons/class_bow.tres")])
	world.set_uniques([load("res://data/uniques/reliquary_coil.tres")])
	world.add_player(Vector2(20.0, 12.0))
	# One of each kind in a readable row; the ring sits nearest so the
	# label proves the grammar line end-to-end.
	world.spawn_drop(Vector2(19.0, 13.2), world.DROP_GOLD, 12)
	world.spawn_drop(Vector2(21.0, 13.2), world.DROP_WEAPON, 0, 1)
	world.spawn_drop(Vector2(22.0, 12.0), world.DROP_ARMOR, 1)
	world.spawn_drop(Vector2(18.0, 12.0), world.DROP_ABILITY, 0)
	world.spawn_drop(Vector2(20.0, 10.8), world.DROP_UNIQUE, 0)
	var items: Array = world.stat_frame.items
	var haste := -1
	for ii in items.size():
		if String(items[ii].get("id", "")) == "t1-ring-of-haste":
			haste = ii
	world.spawn_drop(Vector2(20.0, 13.0), world.DROP_RING, haste)

	var root := Node2D.new()
	get_root().add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.14, 0.12)
	bg.size = Vector2(4000, 4000)
	bg.position = Vector2(-2000, -2000)
	root.add_child(bg)
	var dv := DropView.new()
	dv.world = world
	root.add_child(dv)
	var cam := Camera2D.new()
	cam.position = Vector2(20.0, 12.0) * TILE
	cam.zoom = Vector2(3.0, 3.0)
	root.add_child(cam)

	await process_frame
	cam.make_current()
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/loot_label_audit.png"))
	print("loot_label_probe: wrote reports/loot_label_audit.png")
	quit(0)
