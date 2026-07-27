extends SceneTree
## Offline compositor for arena defs: renders an arena json through
## arena_builder's resolve_placements() — the exact tile choices the runtime
## scene applies — into two PNGs beside this script:
##   arena_preview.png            the arena as it renders
##   arena_preview_collision.png  same image with solid bitgrid cells tinted
##                                red, to eyeball collision == visuals
## Usage: godot --headless --path . --script tests/pixel_match/arena_preview.gd \
##        [-- --arena=res://data/arena_forest.json]

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const BootArgs := preload("res://autoload/boot_args.gd")

const PKG := "res://tileforge/"
const OUT := "res://tests/pixel_match/"
const TILE := 32


func _init() -> void:
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(PKG + "tileforge-manifest.json")
	)
	var args := BootArgs.parse_user_args()
	var def := ArenaBuilder.load_def(String(args.get("arena", "res://data/arena_lab.json")))
	if manifest == null or def.is_empty():
		push_error("arena_preview: missing manifest or arena def")
		quit(1)
		return

	var width := int(def.width)
	var height := int(def.height)
	var canvas := Image.create(width * TILE, height * TILE, false, Image.FORMAT_RGBA8)
	var cache := {}

	var by_layer := {}
	for p: Dictionary in ArenaBuilder.resolve_placements(def, manifest):
		if not by_layer.has(p.layer):
			by_layer[p.layer] = []
		by_layer[p.layer].append(p)

	for layer_name: String in ArenaBuilder.LAYERS:
		for p: Dictionary in by_layer.get(layer_name, []):
			var fam: Dictionary = manifest.families[p.fam]
			var img: Image = cache.get(fam.image)
			if img == null:
				img = Image.load_from_file(PKG + String(fam.image))
				img.convert(Image.FORMAT_RGBA8)
				cache[fam.image] = img
			var cell: Vector2i = p.cell
			canvas.blend_rect(
				img,
				Rect2i(p.atlas_px, Vector2i(TILE, TILE)),
				Vector2i(cell.x * TILE, cell.y * TILE)
			)

	canvas.save_png(OUT + "arena_preview.png")

	var tinted: Image = canvas.duplicate()
	for c: Vector2i in ArenaBuilder.solid_cells(def, manifest):
		for dy in TILE:
			for dx in TILE:
				var px := Vector2i(c.x * TILE + dx, c.y * TILE + dy)
				var base: Color = tinted.get_pixelv(px)
				tinted.set_pixelv(px, base.lerp(Color.RED, 0.35))
	tinted.save_png(OUT + "arena_preview_collision.png")

	print("arena_preview: wrote arena_preview.png + arena_preview_collision.png")
	quit(0)
