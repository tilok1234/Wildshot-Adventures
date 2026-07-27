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
## - seamless floor: fill.<key> on the underlay layer, variant by position
##   hash; rectangular floor_patches override the fill family per cell
##   (last patch wins) — Law 6 judged on the preview, patches stay quiet
## - coverages: masked "on-soil" terrain (terrain.<x>_on_<base>.mask_NNN)
##   laid over the fill by the SAME net16 mask math as walls — organic
##   edges come from the tool's own autotile language, never reinvented.
##   Authored as rect unions minus holes.
## - net16 walls: 4-bit port mask from same-layer cardinal neighbors,
##   out-of-world does NOT connect (§2.8)
## - decals: isolated overlays (mask_000, frame 0) on their own layer
##   between floor and walls — cosmetic ONLY, never solid
## - props: single-cell prop.<name> tiles on the structures layer;
##   "solid": true blocks the cell (per the M1 honesty ruling, reserve it
##   for props whose art plausibly fills the cell — chunky crates/altars,
##   never slim braziers; the hitbox view shows every solid instantly).
##   "tree": true places prop.<name>_ground (ALWAYS solid) plus
##   prop.<name>_over one cell up on the canopy layer (CANOPY band:
##   crowns occlude bodies, never bars or threats).
## - tree_border: {"name", "thickness"} rings the map in solid forest —
##   every band cell gets a trunk (collision == visuals at cell
##   granularity), crowns overhang inward.
## - structures (metatiles, §2.9) are supported for pillar_structure +
##   pillar_blocks defs but unused by the current arena: every 2x2 obstacle
##   option underfilled its blocked footprint (see the def's comment), so the
##   obstacles are straight wall stubs instead

const TILE := 32

const LAYERS: Array[String] = ["underlay", "coverage", "decals", "wall", "structures", "canopy"]

const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const RenderLayers := preload("res://game/render_layers.gd")


## Assemble the full arena under `root`: TileMapLayers from the manifest +
## def, and the collision bitgrid baked from the SAME definition (visuals
## and collision agree by construction, §2.3). Returns
## {def, layers, bitgrid, placements} or {} on missing inputs.
static func build_arena(root: Node2D, def_path := "res://data/arena_lab.json") -> Dictionary:
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://tileforge/tileforge-manifest.json")
	)
	var def := load_def(def_path)
	var tileset: TileSet = load("res://tileforge/tileforge.tres")
	if manifest == null or def.is_empty() or tileset == null:
		push_error("arena_builder: missing manifest, arena def, or tileforge.tres")
		return {}

	var sources := family_sources(manifest, tileset)
	var layers := {}
	for layer_name: String in LAYERS:
		var layer := TileMapLayer.new()
		layer.name = layer_name
		layer.tile_set = tileset
		if layer_name == "canopy":
			layer.z_index = RenderLayers.CANOPY
		root.add_child(layer)
		layers[layer_name] = layer

	var placements := resolve_placements(def, manifest)
	for p: Dictionary in placements:
		var src: Dictionary = sources[p.fam]
		var coords := atlas_coords(p.atlas_px, int(src.pad))
		(layers[p.layer] as TileMapLayer).set_cell(p.cell, int(src.sid), coords)

	var grid := Bitgrid.new()
	grid.setup(int(def.width), int(def.height))
	for c: Vector2i in solid_cells(def, manifest):
		grid.set_solid(c.x, c.y)

	return {"def": def, "layers": layers, "bitgrid": grid, "placements": placements.size()}


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
	for pr: Dictionary in def.get("props", []):
		# Trees are always solid (a trunk you can walk through lies);
		# other props opt in per the M1 honesty ruling.
		if bool(pr.get("solid", false)) or bool(pr.get("tree", false)):
			solids[Vector2i(int(pr.x), int(pr.y))] = true
	for c in _border_cells(def):
		solids[c] = true
	return solids


## Every cell of the tree_border band (empty when the def has none).
static func _border_cells(def: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var border: Dictionary = def.get("tree_border", {})
	if border.is_empty():
		return cells
	var t := int(border.get("thickness", 2))
	var w := int(def.width)
	var h := int(def.height)
	for y in h:
		for x in w:
			if x < t or x >= w - t or y < t or y >= h - t:
				cells.append(Vector2i(x, y))
	return cells


## Coverage region: union of rects minus union of holes.
static func _coverage_cells(cov: Dictionary) -> Dictionary:
	var cells := {}
	for r: Dictionary in cov.get("rects", []):
		for dy in int(r.h):
			for dx in int(r.w):
				cells[Vector2i(int(r.x) + dx, int(r.y) + dy)] = true
	for r: Dictionary in cov.get("holes", []):
		for dy in int(r.h):
			for dx in int(r.w):
				cells.erase(Vector2i(int(r.x) + dx, int(r.y) + dy))
	return cells


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
	var patches: Array = def.get("floor_patches", [])
	var patch_tiles := {}
	for pt: Dictionary in patches:
		var pfam := String(pt.family)
		if not patch_tiles.has(pfam):
			patch_tiles[pfam] = _tiles_by_prefix(manifest, pfam, "fill.%s.variant_" % pfam)

	var width := int(def.width)
	var height := int(def.height)
	for y in height:
		for x in width:
			var fam := floor_fam
			var tiles: Array = fill_tiles
			for pt: Dictionary in patches:
				if (
					x >= int(pt.x)
					and x < int(pt.x) + int(pt.w)
					and y >= int(pt.y)
					and y < int(pt.y) + int(pt.h)
				):
					fam = String(pt.family)
					tiles = patch_tiles[fam]
			var tile: Dictionary = tiles[variant_hash(x, y) % tiles.size()]
			placements.append(_placement("underlay", Vector2i(x, y), fam, tile))

	# Coverages: masked on-base terrain laid over the fill. These families
	# ship the blob-47 autotile set (8-neighbor masks, corner bits only
	# when both adjacent edges connect) — the tool's own edge tiles
	# feather onto the fill underneath.
	for cov: Dictionary in def.get("coverages", []):
		var cfam := String(cov.family)
		var ccells := _coverage_cells(cov)
		var by_mask := {}
		for t: Dictionary in manifest.families[cfam].tiles:
			if int(t.get("frame", 0)) != 0:
				continue
			var tm := int(t.mask)
			if not by_mask.has(tm):
				by_mask[tm] = []
			by_mask[tm].append(t)
		for c: Vector2i in ccells:
			var mask := _blob47_mask(ccells, c)
			var cvariants: Array = by_mask.get(mask, [])
			if cvariants.is_empty():
				push_error("arena_builder: coverage '%s' missing blob mask %d" % [cfam, mask])
				continue
			var ctile: Dictionary = cvariants[variant_hash(c.x, c.y) % cvariants.size()]
			placements.append(_placement("coverage", c, cfam, ctile))

	# Decals: isolated (mask_000) frame-0 overlays, cosmetic only.
	var decal_tiles := {}
	for d: Dictionary in def.get("decals", []):
		var dfam := String(d.name)
		if not decal_tiles.has(dfam):
			var all := _tiles_by_prefix(manifest, dfam, "terrain.%s_decal.mask_000.variant_" % dfam)
			var frame0 := all.filter(
				func(t: Dictionary) -> bool: return String(t.id).ends_with(".frame_00")
			)
			decal_tiles[dfam] = frame0
		var dvariants: Array = decal_tiles[dfam]
		if dvariants.is_empty():
			push_error("arena_builder: decal family '%s' has no frame_00 variants" % dfam)
			continue
		var dcell := Vector2i(int(d.x), int(d.y))
		var dtile: Dictionary = dvariants[variant_hash(dcell.x, dcell.y) % dvariants.size()]
		placements.append(_placement("decals", dcell, dfam, dtile))

	# Props: single-cell prop.<name> tiles; solidity handled in solid_cells.
	# Trees ("tree": true) split into <name>_ground + <name>_over (canopy
	# one cell up, skipped at the map edge).
	var prop_tiles := {}
	for pr: Dictionary in def.get("props", []):
		if bool(pr.get("tree", false)):
			_place_tree(placements, prop_tiles, manifest, String(pr.name), int(pr.x), int(pr.y))
			continue
		var pname := String(pr.name)
		if not prop_tiles.has(pname):
			prop_tiles[pname] = _tiles_by_prefix(manifest, "prop", "prop.%s.variant_" % pname)
		var pvariants: Array = prop_tiles[pname]
		if pvariants.is_empty():
			continue
		var pcell := Vector2i(int(pr.x), int(pr.y))
		var ptile: Dictionary = pvariants[variant_hash(pcell.x, pcell.y) % pvariants.size()]
		placements.append(_placement("structures", pcell, "prop", ptile))

	# Tree border: a trunk on EVERY band cell (the whole band is solid, so
	# every blocked cell carries blocking art), crowns overhang inward.
	var border: Dictionary = def.get("tree_border", {})
	if not border.is_empty():
		var bname := String(border.name)
		for c: Vector2i in _border_cells(def):
			_place_tree(placements, prop_tiles, manifest, bname, c.x, c.y)

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


## One tree: <name>_ground on structures at (x,y), <name>_over on canopy
## at (x,y-1) — skipped when the crown would leave the map.
static func _place_tree(
	placements: Array[Dictionary],
	prop_tiles: Dictionary,
	manifest: Dictionary,
	name: String,
	x: int,
	y: int,
) -> void:
	var gkey := name + "_ground"
	var okey := name + "_over"
	if not prop_tiles.has(gkey):
		prop_tiles[gkey] = _tiles_by_prefix(manifest, "prop", "prop.%s.variant_" % gkey)
	if not prop_tiles.has(okey):
		prop_tiles[okey] = _tiles_by_prefix(manifest, "prop", "prop.%s.variant_" % okey)
	var gvariants: Array = prop_tiles[gkey]
	var ovariants: Array = prop_tiles[okey]
	if gvariants.is_empty():
		return
	var pick := variant_hash(x, y)
	placements.append(
		_placement("structures", Vector2i(x, y), "prop", gvariants[pick % gvariants.size()])
	)
	if y > 0 and not ovariants.is_empty():
		placements.append(
			_placement("canopy", Vector2i(x, y - 1), "prop", ovariants[pick % ovariants.size()])
		)


## Blob-47 mask (N=1 NE=2 E=4 SE=8 S=16 SW=32 W=64 NW=128): corner bits
## count only when both adjacent edges connect — the canonical reduction
## onto the 47 shipped shapes.
static func _blob47_mask(cells: Dictionary, c: Vector2i) -> int:
	var n := cells.has(c + Vector2i(0, -1))
	var e := cells.has(c + Vector2i(1, 0))
	var s := cells.has(c + Vector2i(0, 1))
	var w := cells.has(c + Vector2i(-1, 0))
	var mask := 0
	if n:
		mask |= 1
	if e:
		mask |= 4
	if s:
		mask |= 16
	if w:
		mask |= 64
	if n and e and cells.has(c + Vector2i(1, -1)):
		mask |= 2
	if e and s and cells.has(c + Vector2i(1, 1)):
		mask |= 8
	if s and w and cells.has(c + Vector2i(-1, 1)):
		mask |= 32
	if w and n and cells.has(c + Vector2i(-1, -1)):
		mask |= 128
	return mask


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
