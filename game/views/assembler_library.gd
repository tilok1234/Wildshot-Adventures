extends RefCounted
## View-side assembler-pack library (docs/14): builds SpriteFrames from
## the imported res://assembler/ manifest. Layout derives entirely from
## frame_contract (rows = dirs, columns = anim spans) — adding rows in
## pack v2 changes nothing here. Emits the same "<anim>-<dir>" animation
## names AnimatedActor already plays.
##
## MISSING-ANIM FALLBACKS (the "work without the new animations yet"
## contract): anims the lab plays but the pack doesn't ship yet are
## aliased — cast→attack→idle, death→hurt→idle — so gameplay code never
## cares which pack version is installed. When the designer's cast/death
## rows land, the aliases silently become the real thing.

const MANIFEST_PATH := "res://assembler/manifest.json"
const SHEET_ROOT := "res://assembler/"

const FALLBACKS := {
	"cast": ["attack", "idle"],
	"death": ["hurt", "idle"],
	"hurt": ["idle"],
}
const LOOP_ANIMS: Array[String] = ["idle", "walk"]

var _manifest: Dictionary = {}
var _by_id: Dictionary = {}


func load_manifest() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if parsed == null:
		push_error("assembler_library: %s missing — run the assembler importer" % MANIFEST_PATH)
		return false
	_manifest = parsed
	for entry: Dictionary in _manifest.actors:
		_by_id[String(entry.id)] = entry
	return true


func has_actor(id: String) -> bool:
	return _by_id.has(id)


func build_sprite_frames(id: String) -> SpriteFrames:
	var entry: Dictionary = _by_id[id]
	var tex: Texture2D = load(SHEET_ROOT + String(entry.sheet))
	if tex == null:
		push_error("assembler_library: sheet not imported: %s" % entry.sheet)
		return null
	var contract: Dictionary = _manifest.frame_contract
	var dirs: Array = contract.dirs
	var anims: Array = contract.anims
	var cell := int(_manifest.cell) * int(_manifest.get("export_scale", 1))

	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var have := {}
	for row_i in dirs.size():
		var dname := String(dirs[row_i])
		var col := 0
		for a: Dictionary in anims:
			var aname := String(a.id)
			var label := "%s-%s" % [aname, dname]
			frames.add_animation(label)
			frames.set_animation_speed(label, 1000.0 / float(a.ms))
			frames.set_animation_loop(label, aname in LOOP_ANIMS)
			for f in int(a.frames):
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2((col + f) * cell, row_i * cell, cell, cell)
				frames.add_frame(label, at)
			col += int(a.frames)
			have[aname] = true
	_add_fallback_aliases(frames, dirs, have)
	return frames


## Alias missing lab anims onto the best shipped substitute, per FALLBACKS.
static func _add_fallback_aliases(frames: SpriteFrames, dirs: Array, have: Dictionary) -> void:
	for want: String in FALLBACKS:
		if have.has(want):
			continue
		var substitute := ""
		for candidate: String in FALLBACKS[want]:
			if have.has(candidate):
				substitute = candidate
				break
		if substitute.is_empty():
			continue
		for d in dirs:
			var dst := "%s-%s" % [want, String(d)]
			var src := "%s-%s" % [substitute, String(d)]
			frames.add_animation(dst)
			frames.set_animation_speed(dst, frames.get_animation_speed(src))
			frames.set_animation_loop(dst, false)
			for f in frames.get_frame_count(src):
				frames.add_frame(dst, frames.get_frame_texture(src, f))


## Render scale so one logical pixel = one world pixel (24 px cells on
## 32 px tiles = RotMG-proportioned actors).
func render_scale() -> float:
	return 1.0 / float(_manifest.get("export_scale", 1))
