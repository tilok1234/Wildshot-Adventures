extends RefCounted
## Assembler pack logic (docs/14): validation + roster-filtered copy, as
## a static library so the CLI importer and the fixture test share one
## implementation. Effects are always copied (M-FX curates from them);
## actors copy only when the roster names them (scope tripwire).

const LAB_CONTENT_ANIMS: Array[String] = ["idle", "walk", "attack"]


## Returns {ok: bool, log: Array[String]}. Validates per docs/14 §4:
## manifest sane (UTF-8 no BOM), sheet dims derive from frame_contract,
## frame 0 of the lab content anims non-empty, no orphans either way.
static func import(src: String, dst: String, roster: Array[String]) -> Dictionary:
	var log: Array[String] = []
	var bytes := FileAccess.get_file_as_bytes(src + "manifest.json")
	if bytes.is_empty():
		return {"ok": false, "log": ["manifest.json missing at " + src]}
	if bytes.size() >= 3 and bytes[0] == 0xEF and bytes[1] == 0xBB and bytes[2] == 0xBF:
		return {"ok": false, "log": ["manifest.json has a UTF-8 BOM (docs/14 §4.5 forbids it)"]}
	var manifest: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if manifest == null:
		return {"ok": false, "log": ["manifest.json is not valid JSON"]}

	var contract: Dictionary = manifest.frame_contract
	var dirs: Array = contract.dirs
	var anims: Array = contract.anims
	var cell := int(manifest.cell) * int(manifest.get("export_scale", 1))
	var total_frames := 0
	var anim_ids: Array[String] = []
	for a: Dictionary in anims:
		total_frames += int(a.frames)
		anim_ids.append(String(a.id))
	var want_w := total_frames * cell
	var want_h := dirs.size() * cell

	var ok := true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dst))
	var copied := 0

	for entry: Dictionary in manifest.actors:
		var id := String(entry.id)
		if not roster.has(id):
			continue
		var sheet := String(entry.sheet)
		var img := Image.load_from_file(src + sheet)
		if img == null:
			log.append("roster sheet missing: %s" % sheet)
			ok = false
			continue
		if img.get_width() != want_w or img.get_height() != want_h:
			log.append(
				(
					"%s is %dx%d, contract says %dx%d"
					% [sheet, img.get_width(), img.get_height(), want_w, want_h]
				)
			)
			ok = false
			continue
		var col := 0
		for a: Dictionary in anims:
			if String(a.id) in LAB_CONTENT_ANIMS:
				var frame0 := img.get_region(Rect2i(col * cell, 0, cell, cell))
				if frame0.is_invisible():
					log.append("%s: anim '%s' frame 0 is empty" % [id, String(a.id)])
					ok = false
			col += int(a.frames)
		_copy(src + sheet, dst + sheet)
		copied += 1
	for id in roster:
		var found := false
		for entry: Dictionary in manifest.actors:
			if String(entry.id) == id:
				found = true
				break
		if not found:
			log.append("roster id '%s' not in pack manifest" % id)
			ok = false

	var effects: Array = manifest.get("effects", [])
	for fx: Dictionary in effects:
		var sheet := String(fx.sheet)
		var img := Image.load_from_file(src + sheet)
		if img == null:
			log.append("effect sheet missing: %s" % sheet)
			ok = false
			continue
		var fx_w := int(fx.frames) * cell
		if img.get_width() != fx_w or img.get_height() != cell:
			log.append(
				(
					"%s is %dx%d, expected %dx%d"
					% [sheet, img.get_width(), img.get_height(), fx_w, cell]
				)
			)
			ok = false
			continue
		_copy(src + sheet, dst + sheet)
		copied += 1

	if ok:
		var mf := FileAccess.open(dst + "manifest.json", FileAccess.WRITE)
		mf.store_string(JSON.stringify(manifest, "\t"))
		mf.close()
		log.append(
			(
				"%d sheets -> %s (contract: %s x %d dirs, cell %d)"
				% [copied, dst, "/".join(anim_ids), dirs.size(), cell]
			)
		)
	return {"ok": ok, "log": log}


static func _copy(src_path: String, dst_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dst_path.get_base_dir()))
	var bytes := FileAccess.get_file_as_bytes(src_path)
	var f := FileAccess.open(dst_path, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()
