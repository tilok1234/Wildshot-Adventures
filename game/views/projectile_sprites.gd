extends RefCounted
## View-side projectile-pack library: loads the imported
## res://projectiles/manifest.json and exposes per-id textures +
## metadata. Sprites are native 1x px (px_per_tile matches the world's
## TILE), nearest-filtered, and carry their own palette — views never
## tint mapped sprites (the pack owns the hostile signature per style).

const MANIFEST_PATH := "res://projectiles/manifest.json"
const ROOT := "res://projectiles/"

var px_per_tile := 32
var _by_id: Dictionary = {}


func load_manifest() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if parsed == null:
		push_error("projectile_sprites: %s missing — run the projectile importer" % MANIFEST_PATH)
		return false
	px_per_tile = int(parsed.get("px_per_tile", 32))
	for entry: Dictionary in parsed.sprites:
		var tex: Texture2D = load(ROOT + String(entry.file))
		if tex == null:
			push_error("projectile_sprites: sheet not imported: %s" % String(entry.file))
			continue
		var canvas: Array = entry.canvas_px
		_by_id[String(entry.id)] = {
			"tex": tex,
			"w": int(canvas[0]),
			"h": int(canvas[1]),
			"frames": int(entry.get("frames", 1)),
			"oriented": bool(entry.get("oriented", false)),
			"hitbox_d": int(entry.get("hitbox_diameter_px", 0)),
			"band": int(entry.get("band", 7)),
		}
	return not _by_id.is_empty()


func has_sprite(id: String) -> bool:
	return _by_id.has(id)


func entry(id: String) -> Dictionary:
	return _by_id.get(id, {})
