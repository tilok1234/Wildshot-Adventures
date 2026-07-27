extends SceneTree
## UI kit validation (planning docs/13 §6): every manifest piece exists in
## the IMPORTED res://uikit/ copy with the dimensions the manifest
## declares; 9-slice pieces exceed their margins; the font and its LICENSE
## ship (doc-13 §1.7). Manifest-driven, never hard-coded — a kit polish
## pass cannot silently break the theme.
##
## Run: godot --headless --path . --script tests/uikit/uikit_validate.gd

const KIT := "res://uikit/"


func _init() -> void:
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(KIT + "manifest.json"))
	if manifest == null:
		printerr("FAIL: %smanifest.json missing — run the uikit importer" % KIT)
		quit(1)
		return
	var failed := false
	var checked := 0
	for piece: Dictionary in manifest.pieces:
		var file := String(piece.file)
		var img := Image.load_from_file(KIT + file)
		if img == null:
			printerr("FAIL: piece missing: %s" % file)
			failed = true
			continue
		match String(piece.kind):
			"icon", "texture", "cursor", "tile":
				var want: Array = piece.size
				if img.get_width() != int(want[0]) or img.get_height() != int(want[1]):
					printerr(
						(
							"FAIL: %s is %dx%d, declared %dx%d"
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
					printerr("FAIL: %s smaller than its margins" % file)
					failed = true
		checked += 1
	if not FileAccess.file_exists(KIT + String(manifest.font.file)):
		printerr("FAIL: font missing")
		failed = true
	if not FileAccess.file_exists(KIT + "font/LICENSE"):
		printerr("FAIL: font LICENSE missing (doc-13 §1.7)")
		failed = true
	if not FileAccess.file_exists("res://ui/theme.tres"):
		printerr("FAIL: ui/theme.tres not built — run build_theme.gd")
		failed = true
	if failed:
		quit(1)
		return
	print("PASS: %d kit pieces match the manifest; font + license + theme present" % checked)
	quit(0)
