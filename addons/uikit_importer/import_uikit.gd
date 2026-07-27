extends SceneTree
## UI kit importer, phase 1 (planning docs/13 §6): validates the raw drop
## (assets/uikit — gdignored) against its manifest and copies every listed
## piece + font + manifest into project-visible res://uikit/. Manifest-
## driven, never guesses. Phase 2 (build_theme.gd) runs AFTER
## `godot --headless --path . --import` so the copied textures exist as
## resources.
##
## Usage: godot --headless --path . --script addons/uikit_importer/import_uikit.gd

const SRC := "res://assets/uikit/"
const DST := "res://uikit/"


func _init() -> void:
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(SRC + "manifest.json"))
	if manifest == null:
		push_error("import_uikit: cannot read %smanifest.json" % SRC)
		quit(1)
		return

	var failed := false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DST))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DST + "font"))

	for piece: Dictionary in manifest.pieces:
		var file := String(piece.file)
		var img := Image.load_from_file(SRC + file)
		if img == null:
			push_error("import_uikit: missing or unreadable piece: %s" % file)
			failed = true
			continue
		match String(piece.kind):
			"icon", "texture", "cursor", "tile":
				var want: Array = piece.size
				if img.get_width() != int(want[0]) or img.get_height() != int(want[1]):
					push_error(
						(
							"import_uikit: %s is %dx%d, manifest says %dx%d"
							% [
								file,
								img.get_width(),
								img.get_height(),
								int(want[0]),
								int(want[1]),
							]
						)
					)
					failed = true
			"nineslice":
				var m: Array = piece.margins
				if (
					img.get_width() <= int(m[0]) + int(m[2])
					or img.get_height() <= int(m[1]) + int(m[3])
				):
					push_error("import_uikit: %s smaller than its 9-slice margins" % file)
					failed = true
		_copy(SRC + file, DST + file)

	var font_file := String(manifest.font.file)
	if not FileAccess.file_exists(SRC + font_file):
		push_error("import_uikit: font missing: %s" % font_file)
		failed = true
	else:
		_copy(SRC + font_file, DST + font_file)
	if FileAccess.file_exists(SRC + "font/LICENSE"):
		_copy(SRC + "font/LICENSE", DST + "font/LICENSE")
	else:
		push_error("import_uikit: font LICENSE missing (doc-13 §1.7)")
		failed = true

	var mf := FileAccess.open(DST + "manifest.json", FileAccess.WRITE)
	mf.store_string(JSON.stringify(manifest, "\t"))
	mf.close()

	if failed:
		quit(1)
		return
	print(
		(
			"import_uikit: %d pieces -> %s (run --import, then build_theme.gd)"
			% [manifest.pieces.size(), DST]
		)
	)
	quit(0)


func _copy(src: String, dst: String) -> void:
	var bytes := FileAccess.get_file_as_bytes(src)
	var f := FileAccess.open(dst, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()
