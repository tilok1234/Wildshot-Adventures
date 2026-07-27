extends RefCounted
## Assembler pack logic (docs/14): validation + roster-filtered copy, as
## a static library so the CLI importer and the fixture test share one
## implementation. Effects are always copied (M-FX curates from them);
## actors copy only when the roster names them (scope tripwire).
##
## Two pack manifest shapes are understood:
## - "actors": the docs/14 §3 flat list (pack v0 shipped this).
## - "variant_system": the full-enemy-catalog export — players[] in the
##   manifest, enemies as index records keyed "<family>:<variant>"
##   (pack IMPORT_GUIDE). Roster enemy ids ARE those keys, verbatim.
##   A roster miss fails loudly with the family default suggested; the
##   guide's silent default_variant fallback is for stale save data,
##   not a static roster under CI.
## Whatever the pack shape, the IMPORTED manifest is written roster-only
## in the flat "actors" shape — downstream consumers (assembler_library,
## slice checks) see exactly one format.

const LAB_CONTENT_ANIMS: Array[String] = ["idle", "walk", "attack"]


## Returns {ok: bool, log: Array[String]}. Validates per docs/14 §4:
## manifest sane (UTF-8 no BOM), sheet dims derive from frame_contract,
## frame 0 of the lab content anims non-empty, every roster id resolves.
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

	var by_id := _actors_by_id(manifest, src, log)
	if by_id.is_empty() and not log.is_empty():
		return {"ok": false, "log": log}

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
	var kept_actors: Array = []

	for id: String in roster:
		if not by_id.has(id):
			log.append("roster id '%s' not in pack manifest%s" % [id, _suggest(manifest, src, id)])
			ok = false
			continue
		var entry: Dictionary = by_id[id]
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
		kept_actors.append(entry)
		copied += 1

	var kept_effects: Array = []
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
		kept_effects.append(fx)
		copied += 1

	if ok:
		var out := {
			"pack": manifest.get("pack", ""),
			"version": manifest.get("version", 0),
			"generated": manifest.get("generated", ""),
			"tool_commit": manifest.get("tool_commit", ""),
			"cell": int(manifest.cell),
			"export_scale": int(manifest.get("export_scale", 1)),
			"frame_contract": contract,
			"actors": kept_actors,
			"effects": kept_effects,
		}
		var mf := FileAccess.open(dst + "manifest.json", FileAccess.WRITE)
		mf.store_string(JSON.stringify(out, "\t"))
		mf.close()
		log.append(
			(
				"%d sheets -> %s (contract: %s x %d dirs, cell %d)"
				% [copied, dst, "/".join(anim_ids), dirs.size(), cell]
			)
		)
	return {"ok": ok, "log": log}


## Flatten either pack shape to {id: entry} with normalized
## {id, category, sheet} entries (catalog enemies keep family/variant).
## Returns {} with a logged reason when the pack is unreadable.
static func _actors_by_id(manifest: Dictionary, src: String, log: Array[String]) -> Dictionary:
	var by_id := {}
	if manifest.has("actors"):
		for entry: Dictionary in manifest.actors:
			by_id[String(entry.id)] = entry
		return by_id
	if manifest.has("variant_system"):
		for p: Dictionary in manifest.get("players", []):
			by_id[String(p.id)] = p
		var vsys: Dictionary = manifest.variant_system
		var selector: Dictionary = vsys.selector
		var flat_path := String(selector.flat_index)
		var flat: Variant = JSON.parse_string(FileAccess.get_file_as_string(src + flat_path))
		if flat == null:
			log.append("variant flat index missing or invalid: " + flat_path)
			return {}
		for v: Dictionary in flat.variants:
			by_id[String(v.key)] = {
				"id": String(v.key),
				"category": "enemy",
				"family": String(v.family),
				"variant": String(v.variant),
				"name":
				String(v.get("family_name", "")) + " - " + String(v.get("variant_name", "")),
				"sheet": String(v.sheet),
			}
		return by_id
	log.append("manifest has neither 'actors' nor 'variant_system' — unknown pack shape")
	return {}


## On a catalog roster miss, name the family default so a renamed variant
## fails with an actionable message instead of a bare "not found".
static func _suggest(manifest: Dictionary, src: String, id: String) -> String:
	if not manifest.has("variant_system") or not id.contains(":"):
		return ""
	var vsys: Dictionary = manifest.variant_system
	var selector: Dictionary = vsys.selector
	var fam_json: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(src + String(selector.family_index))
	)
	if fam_json == null:
		return ""
	var fam_id := id.split(":")[0]
	for f: Dictionary in fam_json.families:
		if String(f.id) == fam_id:
			return (
				" (family '%s' exists; its default_variant is '%s')"
				% [fam_id, String(f.default_variant)]
			)
	return ""


static func _copy(src_path: String, dst_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dst_path.get_base_dir()))
	var bytes := FileAccess.get_file_as_bytes(src_path)
	var f := FileAccess.open(dst_path, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()
