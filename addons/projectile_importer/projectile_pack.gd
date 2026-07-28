extends RefCounted
## Projectile-pack logic: validation + map-filtered copy, shared by the
## CLI importer and the CI test (the assembler-pack pattern). The raw
## drop at assets/projectile-pack/ carries five styles; only sprites the
## data/projectile_map.tres actually names are copied into
## res://projectiles/ — the scope tripwire, forge-style.


## Returns {ok, log}. Validates the manifest (UTF-8 no BOM, valid JSON),
## every NEEDED entry's file + pixel dimensions + frame-strip math, and
## the Law-2/8 guard: every mapped HOSTILE shot must declare
## covers_hitbox (hostile visuals never under-render their hitboxes).
static func import(
	src: String, dst: String, needed: Array[String], hostile_shots: Array[String]
) -> Dictionary:
	var log: Array[String] = []
	var bytes := FileAccess.get_file_as_bytes(src + "manifest.json")
	if bytes.is_empty():
		return {"ok": false, "log": ["manifest.json missing at " + src]}
	if bytes.size() >= 3 and bytes[0] == 0xEF and bytes[1] == 0xBB and bytes[2] == 0xBF:
		return {"ok": false, "log": ["manifest.json has a UTF-8 BOM"]}
	var manifest: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if manifest == null:
		return {"ok": false, "log": ["manifest.json is not valid JSON"]}

	var by_id := {}
	for entry: Dictionary in manifest.sprites:
		by_id[String(entry.id)] = entry

	var ok := true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dst))
	var kept: Array = []
	for id: String in needed:
		if not by_id.has(id):
			log.append("mapped sprite '%s' not in pack manifest" % id)
			ok = false
			continue
		var entry: Dictionary = by_id[id]
		var file := String(entry.file)
		var img := Image.load_from_file(src + file)
		if img == null:
			log.append("sprite file missing: %s" % file)
			ok = false
			continue
		var canvas: Array = entry.canvas_px
		var frames := int(entry.get("frames", 1))
		var want_w := int(canvas[0])
		var want_h := int(canvas[1])
		if img.get_width() != want_w or img.get_height() != want_h:
			log.append(
				(
					"%s is %dx%d, manifest says %dx%d"
					% [file, img.get_width(), img.get_height(), want_w, want_h]
				)
			)
			ok = false
			continue
		if frames > 1 and want_w % frames != 0:
			log.append("%s: width %d not divisible by %d frames" % [file, want_w, frames])
			ok = false
			continue
		if id in hostile_shots and not bool(entry.get("covers_hitbox", false)):
			log.append("hostile shot '%s' does not cover its hitbox (Law 2/8)" % id)
			ok = false
			continue
		_copy(src + file, dst + file)
		kept.append(entry)

	if ok:
		var out := {
			"pack": manifest.get("pack", ""),
			"version": manifest.get("version", ""),
			"px_per_tile": int(manifest.get("px_per_tile", 32)),
			"sprites": kept,
		}
		var mf := FileAccess.open(dst + "manifest.json", FileAccess.WRITE)
		mf.store_string(JSON.stringify(out, "\t"))
		mf.close()
		log.append("%d sprites -> %s" % [kept.size(), dst])
	return {"ok": ok, "log": log}


## The sprite ids the current projectile_map.tres needs, deduplicated,
## plus which of them are hostile SHOT mappings (the Law-2/8 subset).
static func needed_from_map(pmap: Resource) -> Dictionary:
	var needed: Array[String] = []
	var hostile_shots: Array[String] = []
	for pid in pmap.shots:
		var sid := String(pmap.shots[pid])
		if not needed.has(sid):
			needed.append(sid)
		if int(pid) >= 10 and not hostile_shots.has(sid):
			hostile_shots.append(sid)
	for pid in pmap.alts:
		var sid := String(pmap.alts[pid])
		if not needed.has(sid):
			needed.append(sid)
	for pid in pmap.zones:
		var sid := String(pmap.zones[pid])
		if not needed.has(sid):
			needed.append(sid)
	if not String(pmap.arm_strip).is_empty() and not needed.has(String(pmap.arm_strip)):
		needed.append(String(pmap.arm_strip))
	var ring := String(pmap.nova_ring)
	if not ring.is_empty() and not needed.has(ring):
		needed.append(ring)
	needed.sort()
	hostile_shots.sort()
	return {"needed": needed, "hostile_shots": hostile_shots}


static func _copy(src_path: String, dst_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dst_path.get_base_dir()))
	var bytes := FileAccess.get_file_as_bytes(src_path)
	var f := FileAccess.open(dst_path, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()
