extends RefCounted
## Icon-pack atlas reader (slice S0 seam 4; wiring cleared by sl-0098):
## id -> AtlasTexture over the ONE consumed res://icons/atlas.png,
## regions from atlas.json. All 470 glyphs reachable through two files;
## a missing id errors loudly and returns null (callers request FIXED
## ids — a typo must never ship silent). View/UI-side only.

const ATLAS_PNG := "res://icons/atlas.png"
const ATLAS_JSON := "res://icons/atlas.json"

static var _tex: Texture2D = null
static var _frames: Dictionary = {}
static var _loaded := false


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ATLAS_JSON))
	if not parsed is Dictionary:
		push_error("icon_atlas: %s missing/unreadable — run tools/import_icons.py" % ATLAS_JSON)
		return
	var data: Dictionary = parsed
	_frames = data.get("frames", {})
	_tex = load(ATLAS_PNG)
	if _tex == null:
		push_error("icon_atlas: %s not imported" % ATLAS_PNG)


static func has_icon(id: String) -> bool:
	_ensure_loaded()
	return _tex != null and _frames.has(id)


static func icon(id: String) -> Texture2D:
	_ensure_loaded()
	if _tex == null or not _frames.has(id):
		push_error("icon_atlas: unknown icon id '%s'" % id)
		return null
	var f: Dictionary = _frames[id]
	var at := AtlasTexture.new()
	at.atlas = _tex
	at.region = Rect2(float(f.x), float(f.y), float(f.w), float(f.h))
	return at
