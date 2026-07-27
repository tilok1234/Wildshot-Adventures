extends SceneTree
## TileForge GAME-GUIDE §4 step 1 — the M1 acceptance test.
## Renders map.tmj from its stored gids (layer order, offsets, gid math from
## FORMATS.md, animation held at frame 0) and pixel-diffs the result against
## map-reference.png. Zero differing pixels proves compositing, layer order,
## offsets and gid resolution. On failure writes out_render.png / out_diff.png
## beside this script for inspection.
## Usage: godot --headless --path . --script tests/pixel_match/pixel_match.gd

const PKG := "res://tileforge/"
const OUT := "res://tests/pixel_match/"
const TILE := 32


func _init() -> void:
	var ok := _run_test()
	quit(0 if ok else 1)


func _run_test() -> bool:
	var manifest: Dictionary = _load_json(PKG + "tileforge-manifest.json")
	var tmj: Dictionary = _load_json(PKG + "map.tmj")
	if manifest.is_empty() or tmj.is_empty():
		push_error("pixel_match: missing manifest or map.tmj")
		return false

	# Family lookup by image basename (tmj tileset sources are "<basename>.tsj").
	var fams := {}
	for fam_id: String in manifest.families:
		var fam: Dictionary = manifest.families[fam_id]
		var image_name := String(fam.image)
		fams[image_name.get_basename()] = {
			"image": image_name,
			"pad": int(fam.atlas.get("padding", 0)),
			"columns": int(fam.atlas.get("columns", 12)),
			"frames": int(fam.get("frames", 1)),
		}

	# Tilesets sorted by descending firstgid for greatest-firstgid-<=-gid lookup.
	var sets: Array = []
	for t: Dictionary in tmj.tilesets:
		sets.append({"first": int(t.firstgid), "base": String(t.source).get_basename()})
	sets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.first > b.first)

	var width := int(tmj.width)
	var height := int(tmj.height)
	var canvas := Image.create(width * TILE, height * TILE, false, Image.FORMAT_RGBA8)
	var atlas_cache := {}

	for layer: Dictionary in tmj.layers:
		var off := Vector2i(int(layer.get("offsetx", 0)), int(layer.get("offsety", 0)))
		var data: Array = layer.data
		for i in data.size():
			var gid := int(data[i])
			if gid == 0:
				continue
			if gid & 0xF0000000:
				push_error("pixel_match: flip bits set on gid %d (forbidden)" % gid)
				return false
			for s: Dictionary in sets:
				if gid >= int(s.first):
					var fam: Dictionary = fams[s.base]
					var local := gid - int(s.first)
					if int(fam.frames) > 1:
						local -= local % int(fam.frames)  # hold animation at frame 0
					var pad := int(fam.pad)
					var cell := TILE + pad * 2
					var src_pos := Vector2i(
						pad + (local % int(fam.columns)) * cell,
						pad + int(local / float(fam.columns)) * cell
					)
					var img: Image = _atlas(atlas_cache, String(fam.image))
					if img == null:
						return false
					var dst := Vector2i((i % width) * TILE, int(i / float(width)) * TILE) + off
					canvas.blend_rect(img, Rect2i(src_pos, Vector2i(TILE, TILE)), dst)
					break

	var reference := Image.load_from_file(PKG + "map-reference.png")
	if reference == null:
		push_error("pixel_match: cannot load map-reference.png")
		return false
	reference.convert(Image.FORMAT_RGBA8)
	if reference.get_size() != canvas.get_size():
		push_error(
			(
				"pixel_match: size mismatch render %s vs reference %s"
				% [canvas.get_size(), reference.get_size()]
			)
		)
		return false

	var diff_count := 0
	var diff := Image.create(canvas.get_width(), canvas.get_height(), false, Image.FORMAT_RGBA8)
	for y in canvas.get_height():
		for x in canvas.get_width():
			var a := canvas.get_pixel(x, y)
			var b := reference.get_pixel(x, y)
			# Compare RGB; alpha is composition-internal (reference may ship RGB).
			if a.r8 != b.r8 or a.g8 != b.g8 or a.b8 != b.b8:
				diff_count += 1
				diff.set_pixel(x, y, Color.RED)

	if diff_count > 0:
		canvas.save_png(OUT + "out_render.png")
		diff.save_png(OUT + "out_diff.png")
		push_error(
			"pixel_match: FAIL — %d differing pixels (artifacts in tests/pixel_match/)" % diff_count
		)
		return false
	print(
		(
			"pixel_match: PASS — 0 differing pixels across %dx%d"
			% [canvas.get_width(), canvas.get_height()]
		)
	)
	return true


func _atlas(cache: Dictionary, image_name: String) -> Image:
	if not cache.has(image_name):
		var img := Image.load_from_file(PKG + image_name)
		if img == null:
			push_error("pixel_match: cannot load atlas " + image_name)
			return null
		img.convert(Image.FORMAT_RGBA8)
		cache[image_name] = img
	return cache[image_name]


func _load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}
