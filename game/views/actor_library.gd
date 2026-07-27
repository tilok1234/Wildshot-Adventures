extends RefCounted
## View-side Sprite Forge actor library (docs/12 §2.14): reads the imported
## spriteforge/manifest.json and builds SpriteFrames per actor. Manifest-
## driven — row labels, frame counts, and cell size come from the manifest,
## never from code — so the polish pass swaps sheets under the same ids
## without touching this file.

const MANIFEST_PATH := "res://spriteforge/manifest.json"
const SHEET_ROOT := "res://spriteforge/"
## Pack rateMs is null throughout, so these dev defaults drive row rates.
## PROVISIONAL [T-ish]: walk runs faster than the rest so footfalls track
## ground speed (AnimatedActor additionally scales walk by live velocity);
## rested-session feel pass judges both numbers.
const DEFAULT_FPS := 8.0
const WALK_FPS := 12.0
## Looping is a label property: locomotion cycles, everything else one-shots.
const LOOP_PREFIXES: Array[String] = ["idle-", "walk-"]

var _by_id: Dictionary = {}


func load_manifest() -> bool:
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if manifest == null:
		push_error("actor_library: %s missing — run the spriteforge importer" % MANIFEST_PATH)
		return false
	for entry: Dictionary in manifest.actors:
		_by_id[String(entry.id)] = entry
	return true


func has_actor(id: String) -> bool:
	return _by_id.has(id)


func build_sprite_frames(id: String) -> SpriteFrames:
	var entry: Dictionary = _by_id[id]
	var tex: Texture2D = load(SHEET_ROOT + String(entry.sheet))
	if tex == null:
		push_error("actor_library: sheet not imported: %s" % entry.sheet)
		return null
	var cell := int(entry.cell) * int(entry.scale)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var rows: Array = entry.rows
	for row_i in rows.size():
		var label := String(rows[row_i].label)
		var fps := WALK_FPS if label.begins_with("walk-") else DEFAULT_FPS
		if entry.rateMs != null:
			fps = 1000.0 / float(entry.rateMs)
		frames.add_animation(label)
		frames.set_animation_speed(label, fps)
		frames.set_animation_loop(label, _is_looping(label))
		for col in int(rows[row_i].frames):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(col * cell, row_i * cell, cell, cell)
			frames.add_frame(label, at)
	return frames


static func _is_looping(label: String) -> bool:
	for prefix: String in LOOP_PREFIXES:
		if label.begins_with(prefix):
			return true
	return false
