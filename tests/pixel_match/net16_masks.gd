extends SceneTree
## TileForge GAME-GUIDE §4 step 2, scoped to the net16 code path the arena
## builder uses: derive port masks for every network layer (road, pier, fence,
## wall, river) from map-data.json raw grids and compare against the masks
## stored in map.tmj's gids. Variant picks may differ from the forge; masks
## must not. Also verifies the per-cell type byte resolves to the family the
## stored gid actually uses.
## Rules (§2.8): same-layer cardinal neighbors connect regardless of type;
## out-of-world does NOT connect; river additionally connects to
## water/shallow/deep material cells; wall additionally connects to gate
## structure cells (type 7 and its state siblings via `base`).
## Usage: godot --headless --path . --script tests/pixel_match/net16_masks.gd

const PKG := "res://tileforge/"

const LAYER_TO_TYPES := {
	"road": "roadTypes", "pier": "pierTypes", "fence": "fenceTypes", "wall": "wallTypes"
}


func _init() -> void:
	quit(0 if _run_test() else 1)


func _run_test() -> bool:
	var manifest: Dictionary = _load_json(PKG + "tileforge-manifest.json")
	var tmj: Dictionary = _load_json(PKG + "map.tmj")
	var raw: Dictionary = _load_json(PKG + "map-data.json")
	if manifest.is_empty() or tmj.is_empty() or raw.is_empty():
		push_error("net16_masks: missing manifest, map.tmj, or map-data.json")
		return false

	var w := int(raw.mapW)
	var h := int(raw.mapH)
	var decoder := _build_gid_decoder(manifest, tmj)
	var mappings: Dictionary = manifest.mappings

	# Material ids whose family key is in the open-water group (river rule).
	var water_mats := {}
	for mat_id: String in mappings.materials:
		if String(mappings.materials[mat_id]) in ["water", "shallow", "deep"]:
			water_mats[int(mat_id)] = true

	# Structure type ids that count as gates for wall connection (7 + siblings).
	var gate_types := {}
	for st_id: String in mappings.structures:
		var st: Dictionary = mappings.structures[st_id]
		if int(st_id) == 7 or int(st.get("base", -1)) == 7:
			gate_types[int(st_id)] = true

	var mat: Array = raw.mat
	var meta: Array = raw.meta
	var errors := 0
	var checked := 0

	for layer_name: String in ["road", "pier", "fence", "wall", "river"]:
		var grid: Array = raw[layer_name]
		var stored: Array = _tmj_layer_data(tmj, layer_name)
		for i in grid.size():
			var type_byte := int(grid[i])
			if type_byte == 0:
				continue
			var x := i % w
			var y := int(i / float(w))
			var derived := 0
			var dirs := [
				[1, Vector2i(0, -1)], [2, Vector2i(1, 0)], [4, Vector2i(0, 1)], [8, Vector2i(-1, 0)]
			]
			for d: Array in dirs:
				var n: Vector2i = Vector2i(x, y) + d[1]
				if n.x < 0 or n.x >= w or n.y < 0 or n.y >= h:
					continue  # out-of-world never connects for networks
				var ni := n.y * w + n.x
				var connected := int(grid[ni]) != 0
				if not connected and layer_name == "river":
					connected = water_mats.has(int(mat[ni]))
				if not connected and layer_name == "wall":
					var code := int(meta[ni])
					connected = code != 0 and gate_types.has(int(code / 256.0))
				if connected:
					derived |= int(d[0])

			var gid := int(stored[i])
			if gid == 0:
				push_error(
					(
						"net16_masks: %s (%d,%d) typed %d but no stored gid"
						% [layer_name, x, y, type_byte]
					)
				)
				errors += 1
				continue
			var tile: Dictionary = decoder.call(gid)
			checked += 1
			if int(tile.mask) != derived:
				push_error(
					(
						"net16_masks: %s (%d,%d) derived mask %d != stored %d (%s)"
						% [layer_name, x, y, derived, int(tile.mask), String(tile.id)]
					)
				)
				errors += 1
			if LAYER_TO_TYPES.has(layer_name):
				var expected_fam := String(mappings[LAYER_TO_TYPES[layer_name]][str(type_byte)])
				if String(tile.fam) != expected_fam:
					push_error(
						(
							"net16_masks: %s (%d,%d) type %d expects family %s, stored gid is %s"
							% [layer_name, x, y, type_byte, expected_fam, String(tile.fam)]
						)
					)
					errors += 1

	if errors > 0:
		push_error("net16_masks: FAIL — %d mismatches across %d cells" % [errors, checked])
		return false
	print("net16_masks: PASS — %d network cells, derived masks all match stored" % checked)
	return true


## Returns a Callable(gid) -> {fam, id, mask} resolving through the tmj
## tilesets block and the manifest tile tables.
func _build_gid_decoder(manifest: Dictionary, tmj: Dictionary) -> Callable:
	var fams := {}
	for fam_key: String in manifest.families:
		var fam: Dictionary = manifest.families[fam_key]
		var pad := int(fam.atlas.get("padding", 0))
		var cell := 32 + pad * 2
		var columns := int(fam.atlas.get("columns", 12))
		var by_index := {}
		for t: Dictionary in fam.tiles:
			var col := int((int(t.atlas[0]) - pad) / float(cell))
			var row := int((int(t.atlas[1]) - pad) / float(cell))
			by_index[row * columns + col] = t
		fams[String(fam.image).get_basename()] = {
			"key": fam_key,
			"frames": int(fam.get("frames", 1)),
			"by_index": by_index,
		}
	var sets: Array = []
	for t: Dictionary in tmj.tilesets:
		sets.append({"first": int(t.firstgid), "base": String(t.source).get_basename()})
	sets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.first > b.first)

	return func(gid: int) -> Dictionary:
		for s: Dictionary in sets:
			if gid >= int(s.first):
				var fam: Dictionary = fams[s.base]
				var local := gid - int(s.first)
				if int(fam.frames) > 1:
					local -= local % int(fam.frames)
				var tile: Dictionary = fam.by_index[local]
				return {"fam": fam.key, "id": tile.id, "mask": int(tile.get("mask", 0))}
		return {"fam": "", "id": "", "mask": -1}


func _tmj_layer_data(tmj: Dictionary, layer_name: String) -> Array:
	for layer: Dictionary in tmj.layers:
		if String(layer.name) == layer_name:
			return layer.data
	return []


func _load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}
