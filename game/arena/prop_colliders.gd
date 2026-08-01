extends RefCounted
## sl-0078 THE FIT RULE (designer-directed collision change, the
## deliberate design act): "if there is more then enough for the
## character sprite to go between it it should be able to go between
## it." Solid PROP cells stop owning their full cell — each one gets a
## sub-cell disc measured from ITS OWN sprite's visible base (thin
## trunk, boulder base, cactus base), so the player threads wherever
## visible ground shows. Gaps are measured by SPRITE WIDTH, never
## cells.
##
## SEMANTICS (the ruling's line, restated where it binds): the cell
## bitgrid remains the CONSERVATIVE FLOOR — floods, porosity,
## world_walk, enemy walkers, spawn checks, and every upstream pack
## contract keep their meaning; b77 stays current, zero upstream work.
## Player passability is now art-true — MORE WYSIWYG than cells.
##
## ROUND-1 SCOPE: props only. Structures/fences/cliffs/water/rock/bog
## keep full cells (their chunk-layer or material cause wins over a
## coincident prop). Enemies stay grid-walkers (asymmetry accepted).
## Projectiles adopt the same footprint (coherence amendment).
##
## ONE CODE PATH: ScenarioLoader.attach() runs for main, DodgeBot,
## soak, and replay verification alike — the bot walks byte-the-same
## collision the player does (§2.8 honesty). Measurement is a pure
## function of the pack + pinned package bytes: deterministic, no RNG,
## no nodes. When in doubt, thinner (the designer's word): THIN scales
## every measured base down; MIN/MAX bound degenerate art.

const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const WorldBuilder := preload("res://game/arena/world_builder.gd")

const BASE_BAND_PX := 6
const THIN := 0.85
const MIN_R := 0.06
const MAX_R := 0.42


## Attach the fit-rule truth to a built world. Pack-less scenarios and
## any build failure keep the conservative default (walk_grid ==
## bitgrid) — loudly, never silently.
static func attach(world: RefCounted, scenario: Resource) -> void:
	var pack := String(scenario.worldforge_pack)
	if pack.is_empty():
		return
	var built := build(pack, world.bitgrid)
	if built.is_empty():
		print("prop_colliders: no discs for '%s' — conservative full-cell collision stands" % pack)
		return
	world.walk_grid = built.walk_grid
	world.prop_discs = built.discs


## {walk_grid, discs} or {} — walk_grid is a clone of the conservative
## grid with every measured prop cell opened; discs maps cell ->
## Array[Vector3(world_x, world_y, r)].
static func build(pack_src: String, grid: RefCounted) -> Dictionary:
	pack_src = WorldforgePack.resolve_src(pack_src)
	var pack_manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(pack_src + "manifest.json")
	)
	if pack_manifest == null:
		return {}
	var pkg := WorldBuilder.resolve_package(pack_manifest)
	if pkg.is_empty():
		return {}
	var tileset: TileSet = pkg.tileset
	var tmj: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(pack_src + "resolved/resolved-map.tmj")
	)
	if tmj == null:
		return {}
	var tables := WorldBuilder.gid_tables(pkg.manifest, tileset, tmj)
	if tables.is_empty():
		return {}
	var world_json: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(pack_src + "world.json")
	)
	if world_json == null or not world_json.has("chunks"):
		return {}

	var w := int(tmj.width)
	var h := int(tmj.height)
	var props_data: Array = []
	var cliff_data: Array = []
	for layer_def: Dictionary in tmj.layers:
		if not layer_def.has("data"):
			continue
		match String(layer_def.get("name", "")):
			"props":
				props_data = layer_def.data
			"cliff":
				cliff_data = layer_def.data
	if props_data.is_empty():
		return {}

	# Chunk layers -> per-cell cause guards (prop cells only convert
	# when the prop IS the sole visible blocker).
	var cw := int(world_json.dimensions.chunkWidth)
	var chh := int(world_json.dimensions.chunkHeight)
	var prop_l := PackedInt32Array()
	var structure_l := PackedInt32Array()
	var fence_l := PackedInt32Array()
	var river_l := PackedInt32Array()
	var material_l := PackedInt32Array()
	prop_l.resize(w * h)
	structure_l.resize(w * h)
	fence_l.resize(w * h)
	river_l.resize(w * h)
	material_l.resize(w * h)
	for ch: Dictionary in world_json.chunks:
		var cx := int(ch.coord[0])
		var cy := int(ch.coord[1])
		var layers: Dictionary = ch.layers
		for pair: Array in [
			["prop", prop_l],
			["structure", structure_l],
			["fence", fence_l],
			["river", river_l],
			["material", material_l],
		]:
			var rows: Array = layers.get(pair[0], [])
			var dest: PackedInt32Array = pair[1]
			for ly in rows.size():
				var row: Array = rows[ly]
				for lx in row.size():
					dest[(cy * chh + ly) * w + (cx * cw + lx)] = int(row[lx])
	var palette: Array = world_json.get("semanticPalette", [])
	var hard_mats := {}
	for mi in palette.size():
		if String(palette[mi]) in ["terrain.rock", "terrain.swamp", "water.deep", "water.shallow"]:
			hard_mats[mi] = true

	var walk: RefCounted = grid.clone()
	var discs := {}
	var cache := {}
	var opened := 0
	var tiles_measured := 0
	for y in h:
		for x in w:
			if not grid.is_solid(x, y):
				continue
			var i := y * w + x
			if prop_l[i] == 0:
				continue
			if structure_l[i] != 0 or fence_l[i] != 0 or river_l[i] != 0:
				continue
			if hard_mats.has(material_l[i]):
				continue
			if not cliff_data.is_empty() and int(cliff_data[i]) != 0:
				continue
			var gid := int(props_data[i])
			if gid == 0:
				continue  # solid prop cell without art stays conservative
			var t := WorldBuilder._resolve_gid(gid, tables.sets, tables.by_base)
			if t.is_empty():
				continue
			var key := "%d:%s" % [int(t.sid), str(t.coords)]
			if not cache.has(key):
				cache[key] = _measure_base(tileset, int(t.sid), t.coords)
				tiles_measured += 1
			var local: Variant = cache[key]
			if local == null:
				continue
			walk.set_open(x, y)
			opened += 1
			var lv: Vector3 = local
			var cell := Vector2i(x, y)
			if not discs.has(cell):
				discs[cell] = []
			(discs[cell] as Array).append(Vector3(float(x) + lv.x, float(y) + lv.y, lv.z))
	print(
		(
			"prop_colliders: fit rule active — %d prop cells opened to discs (%d distinct tiles measured, player r 5/32)"
			% [opened, tiles_measured]
		)
	)
	return {"walk_grid": walk, "discs": discs}


## Measure a tile's visible BASE footprint: lowest opaque rows (the
## band the object stands on) -> opaque width + centroid. Returns a
## cell-local Vector3(cx, cy, r) or null for empty art. Thinner bias
## per the ruling; bounds guard degenerate sprites.
static func _measure_base(tileset: TileSet, sid: int, coords: Vector2i) -> Variant:
	var src := tileset.get_source(sid) as TileSetAtlasSource
	if src == null:
		return null
	var img := src.texture.get_image()
	if img == null:
		return null
	var region := src.get_tile_texture_region(coords, 0)
	var tile := img.get_region(region)
	var size := tile.get_width()
	var low := -1
	for yy in range(tile.get_height() - 1, -1, -1):
		for xx in size:
			if tile.get_pixel(xx, yy).a > 0.5:
				low = yy
				break
		if low >= 0:
			break
	if low < 0:
		return null
	var y0 := maxi(0, low - BASE_BAND_PX + 1)
	var min_x := size
	var max_x := -1
	for yy in range(y0, low + 1):
		for xx in size:
			if tile.get_pixel(xx, yy).a > 0.5:
				min_x = mini(min_x, xx)
				max_x = maxi(max_x, xx)
	if max_x < 0:
		return null
	var wpx := float(max_x - min_x + 1)
	var r := clampf(wpx * 0.5 / float(size) * THIN, MIN_R, MAX_R)
	var cx := (float(min_x) + float(max_x) + 1.0) * 0.5 / float(size)
	var cy := clampf((float(low) + 1.0 - float(BASE_BAND_PX) * 0.5) / float(size), 0.0, 1.0)
	return Vector3(cx, cy, r)
