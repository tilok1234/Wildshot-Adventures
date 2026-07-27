extends RefCounted
## Builds the Phase A lab arena from data/arena_lab.json.
##
## The single source of truth for tile selection: resolve_placements() computes
## every (layer, cell, atlas position) from the definition + manifest. The
## runtime scene (game/main.gd) and the offline preview compositor
## (tests/pixel_match/arena_preview.gd) both consume that list, and the
## collision bitgrid derives from the same definition — so visuals, preview,
## and collision agree by construction (docs/12 §2.3).
##
## Art contract subset used here (TileForge GAME-GUIDE §2):
## - seamless floor: fill.<key> on the underlay layer, variant by position hash
## - net16 walls: 4-bit port mask from same-layer cardinal neighbors,
##   out-of-world does NOT connect (§2.8)
## - structures (metatiles, §2.9) are supported for pillar_structure +
##   pillar_blocks defs but unused by the current arena: every 2x2 obstacle
##   option underfilled its blocked footprint (see the def's comment), so the
##   obstacles are straight wall stubs instead

const TILE := 32

const LAYERS: Array[String] = ["underlay", "wall", "structures"]


static func load_def(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func wall_cells(def: Dictionary) -> Dictionary:
	var cells := {}
	for seg: Dictionary in def.wall_segments:
		for dy in int(seg.h):
			for dx in int(seg.w):
				cells[Vector2i(int(seg.x) + dx, int(seg.y) + dy)] = true
	return cells


static func pillar_size(def: Dictionary, manifest: Dictionary) -> Vector2i:
	var name := String(def.get("pillar_structure", ""))
	if name.is_empty():
		return Vector2i(1, 1)
	for st_id: String in manifest.mappings.structures:
		var st: Dictionary = manifest.mappings.structures[st_id]
		if String(st.name) == name:
			return Vector2i(int(st.w), int(st.h))
	push_error("arena_builder: structure '%s' not in mappings.structures" % name)
	return Vector2i(1, 1)


static func pillar_cells(def: Dictionary, manifest: Dictionary) -> Array[Vector2i]:
	var size := pillar_size(def, manifest)
	var cells: Array[Vector2i] = []
	for block: Dictionary in def.get("pillar_blocks", []):
		for dy in size.y:
			for dx in size.x:
				cells.append(Vector2i(int(block.x) + dx, int(block.y) + dy))
	return cells


static func solid_cells(def: Dictionary, manifest: Dictionary) -> Dictionary:
	var solids := wall_cells(def)
	for c in pillar_cells(def, manifest):
		solids[c] = true
	return solids


## Deterministic position hash for variant picks (GAME-GUIDE §2.4; the exact
## hash is free — any stable per-position choice is seam-safe). Not RNG.
static func variant_hash(x: int, y: int) -> int:
	var h := x * 374761393 + y * 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return (h ^ (h >> 16)) & 0x7FFFFFFF


## net16 port mask: N=1 E=2 S=4 W=8; out-of-world neighbors do not connect.
static func net16_mask(cells: Dictionary, c: Vector2i) -> int:
	var mask := 0
	if cells.has(c + Vector2i(0, -1)):
		mask |= 1
	if cells.has(c + Vector2i(1, 0)):
		mask |= 2
	if cells.has(c + Vector2i(0, 1)):
		mask |= 4
	if cells.has(c + Vector2i(-1, 0)):
		mask |= 8
	return mask


## One placement: {layer: String, cell: Vector2i, fam: String, atlas_px: Vector2i}
## atlas_px is the pixel position of the 32x32 tile inside the family atlas.
static func resolve_placements(def: Dictionary, manifest: Dictionary) -> Array[Dictionary]:
	var placements: Array[Dictionary] = []
	var floor_fam := String(def.floor_family)
	var wall_fam := String(def.wall_family)
	var structure := String(def.get("pillar_structure", ""))

	var fill_tiles := _tiles_by_prefix(manifest, floor_fam, "fill.%s.variant_" % floor_fam)
	var wall_by_mask := _net_tiles_by_mask(manifest, wall_fam)

	var width := int(def.width)
	var height := int(def.height)
	for y in height:
		for x in width:
			var tile: Dictionary = fill_tiles[variant_hash(x, y) % fill_tiles.size()]
			placements.append(_placement("underlay", Vector2i(x, y), floor_fam, tile))

	var walls := wall_cells(def)
	for c: Vector2i in walls:
		var mask := net16_mask(walls, c)
		var variants: Array = wall_by_mask[mask]
		var tile: Dictionary = variants[variant_hash(c.x, c.y) % variants.size()]
		placements.append(_placement("wall", c, wall_fam, tile))

	if structure.is_empty():
		return placements

	var size := pillar_size(def, manifest)
	for block: Dictionary in def.get("pillar_blocks", []):
		var anchor := Vector2i(int(block.x), int(block.y))
		for cy in size.y:
			for cx in size.x:
				var cell_tiles := _tiles_by_prefix(
					manifest, "meta", "structure.%s_%d.variant_" % [structure, cy * size.x + cx]
				)
				# Every cell of the footprint uses the ANCHOR cell's variant (§2.9).
				var tile: Dictionary = cell_tiles[
					variant_hash(anchor.x, anchor.y) % cell_tiles.size()
				]
				placements.append(_placement("structures", anchor + Vector2i(cx, cy), "meta", tile))

	return placements


static func _placement(layer: String, cell: Vector2i, fam: String, tile: Dictionary) -> Dictionary:
	return {
		"layer": layer,
		"cell": cell,
		"fam": fam,
		"atlas_px": Vector2i(int(tile.atlas[0]), int(tile.atlas[1])),
	}


static func _tiles_by_prefix(manifest: Dictionary, fam_key: String, prefix: String) -> Array:
	var out := []
	for t: Dictionary in manifest.families[fam_key].tiles:
		if String(t.id).begins_with(prefix):
			out.append(t)
	if out.is_empty():
		push_error("arena_builder: no tiles matching '%s' in family '%s'" % [prefix, fam_key])
	return out


static func _net_tiles_by_mask(manifest: Dictionary, fam_key: String) -> Dictionary:
	var by_mask := {}
	for t: Dictionary in manifest.families[fam_key].tiles:
		var mask := int(t.mask)
		if not by_mask.has(mask):
			by_mask[mask] = []
		by_mask[mask].append(t)
	return by_mask


## Family key -> {sid, pad} for TileMapLayer application. Atlas sources were
## added in manifest.families insertion order by the shipped importer.
static func family_sources(manifest: Dictionary, tileset: TileSet) -> Dictionary:
	var out := {}
	var index := 0
	for fam_key: String in manifest.families:
		out[fam_key] = {
			"sid": tileset.get_source_id(index),
			"pad": int(manifest.families[fam_key].atlas.get("padding", 0)),
		}
		index += 1
	return out


static func atlas_coords(atlas_px: Vector2i, pad: int) -> Vector2i:
	var cell := TILE + pad * 2
	return Vector2i(int((atlas_px.x - pad) / float(cell)), int((atlas_px.y - pad) / float(cell)))
