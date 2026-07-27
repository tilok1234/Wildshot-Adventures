extends SceneTree
## Actor-sheet slice test (docs/12 §2.14): every lab-roster actor's IMPORTED
## sheet must match its manifest declaration — width = max row frames × cell
## px, height = row count × cell px — and every rig row the lab plays must
## have non-empty pixels in its first frame. Manifest-driven, never
## hard-coded: the polish pass or future rig additions cannot silently
## break this test.
##
## Run: godot --headless --path . --script tests/actor_sheet_slice/actor_sheet_slice.gd

## Row-label prefixes the lab actually plays (§2.14); civic rows (sit/work/
## carry/lean) are exempt from the content check until hubs exist.
const LAB_ROW_PREFIXES: Array[String] = ["idle-", "walk-", "attack-", "cast-", "hurt", "death"]


func _init() -> void:
	var sheet_map: Resource = load("res://data/actor_sheet_map.tres")
	if sheet_map == null or sheet_map.map.is_empty():
		printerr("FAIL: data/actor_sheet_map.tres missing or empty")
		quit(1)
		return
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://spriteforge/manifest.json")
	)
	if manifest == null:
		printerr("FAIL: spriteforge/manifest.json missing — run the importer")
		quit(1)
		return
	var by_id := {}
	for entry: Dictionary in manifest.actors:
		by_id[String(entry.id)] = entry

	var failed := false
	var checked := 0
	for role: String in sheet_map.map:
		var id := String(sheet_map.map[role])
		if not by_id.has(id):
			# Transition (§2.14 Amendment v2): assembler-sourced ids are
			# validated by tests/assembler_pack; this test covers only
			# what still maps to the spriteforge fallback. Remove this
			# test entirely when the fallback pack is retired at M5.
			print("skip: '%s' (%s) is not spriteforge-sourced" % [id, role])
			continue
		var entry: Dictionary = by_id[id]
		var img := Image.load_from_file("res://spriteforge/" + String(entry.sheet))
		if img == null:
			printerr("FAIL: %s: sheet unreadable: %s" % [id, entry.sheet])
			failed = true
			continue
		var cell := int(entry.cell) * int(entry.scale)
		var rows: Array = entry.rows
		var max_frames := 0
		for row: Dictionary in rows:
			max_frames = maxi(max_frames, int(row.frames))
		if img.get_width() != max_frames * cell or img.get_height() != rows.size() * cell:
			printerr(
				(
					"FAIL: %s: sheet %dx%d != declared %dx%d (max %d frames x %d rows x %d px)"
					% [
						id,
						img.get_width(),
						img.get_height(),
						max_frames * cell,
						rows.size() * cell,
						max_frames,
						rows.size(),
						cell,
					]
				)
			)
			failed = true
			continue
		for row_i in rows.size():
			var label := String(rows[row_i].label)
			if int(rows[row_i].frames) < 1:
				printerr("FAIL: %s: row '%s' declares zero frames" % [id, label])
				failed = true
			if not _is_lab_row(label):
				continue
			var frame0 := img.get_region(Rect2i(0, row_i * cell, cell, cell))
			if frame0.is_invisible():
				printerr("FAIL: %s: lab row '%s' frame 0 is fully transparent" % [id, label])
				failed = true
		checked += 1
		print(
			(
				"ok: %s (%s) %dx%d, %d rows, cell %d"
				% [id, entry.sheet, img.get_width(), img.get_height(), rows.size(), cell]
			)
		)

	if failed:
		quit(1)
		return
	print("PASS: %d roster actor sheet(s) match their manifest declarations" % checked)
	quit(0)


static func _is_lab_row(label: String) -> bool:
	for prefix: String in LAB_ROW_PREFIXES:
		if label.begins_with(prefix):
			return true
	return false
