extends RefCounted
## WorldForge world consumption (the 2026-07-28 generated-test-arena
## ruling): validates a game pack (worldforge_pack.gd — hash chain,
## walkability, flood) and renders its RESOLVED TMJ layers into
## TileMapLayers against the game's own TileForge package. The pack's
## pinned package identity MUST match the imported tileforge package
## (checked here: sourceCommit+seed vs tileforge.packageId) — resolved
## gids are meaningless against a different atlas build.
##
## v0 limitations (testbed class, deliberate): animated families held at
## frame 0 (the pixel_match rule); POIs/settlements/minimap unconsumed.
## Semantics come from world.json ONLY when that half lands — resolved
## layers are rendering-only (multi-game rule).
##
## CITIES-OPEN ruling (2026-07-29): structure/prop/fence/wall layers
## y-sort against actors in main's ActorSortSpace (returned as
## sort_layers for reparenting). Structures sort as whole BUILDINGS —
## connected cells share the component's base row via alternative tiles
## carrying y_sort_origin — so walking the reopened between-house gaps
## reads as depth (in front = over you, behind = under you) instead of
## sprites sliding across rooftops. Floor-class layers stay FLOOR band;
## overhang stays CANOPY; combat bands sit above the space untouched.

const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const RenderLayers := preload("res://game/render_layers.gd")

const TILE := 32


## Returns {def: {width, height}, bitgrid, spawn: Vector2i, placements}
## or {} on failure (every failure is loud).
static func build_world_arena(root: Node2D, pack_src: String) -> Dictionary:
	var t0 := Time.get_ticks_msec()
	var report := WorldforgePack.validate(pack_src)
	for line: String in report.log:
		if report.ok:
			print("world_builder: ", line)
		else:
			push_error("world_builder: " + line)
	if not report.ok:
		return {}

	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://tileforge/tileforge-manifest.json")
	)
	var tileset: TileSet = load("res://tileforge/tileforge.tres")
	if manifest == null or tileset == null:
		push_error("world_builder: tileforge package missing")
		return {}
	pack_src = WorldforgePack.resolve_src(pack_src)
	var pack_manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(pack_src + "manifest.json")
	)
	var pinned := String(pack_manifest.tileforge.packageId)
	var ours := (
		"%s-%s-seed%d"
		% [
			String(pack_manifest.tileforge.theme),
			String(manifest.sourceCommit),
			int(manifest.projectSeed),
		]
	)
	if pinned != ours:
		push_error(
			(
				"world_builder: pack pinned to '%s' but the imported package is '%s' — refusing to render against a different atlas build"
				% [pinned, ours]
			)
		)
		return {}

	var tmj: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(pack_src + "resolved/resolved-map.tmj")
	)
	# Family lookup by tsj/image basename + per-family source id, columns,
	# frames (frame-0 snap for animated families).
	var by_base := {}
	var index := 0
	for fam_key: String in manifest.families:
		var fam: Dictionary = manifest.families[fam_key]
		var base_key := String(fam.image).get_basename()
		by_base[base_key] = {
			"sid": tileset.get_source_id(index),
			"columns": int(fam.atlas.get("columns", 12)),
			"frames": int(fam.get("frames", 1)),
		}
		index += 1
	var sets: Array = []
	for ts: Dictionary in tmj.tilesets:
		var base := String(ts.source).get_basename()
		if not by_base.has(base):
			push_error("world_builder: tmj tileset '%s' not in the tileforge package" % base)
			return {}
		sets.append({"first": int(ts.firstgid), "base": base})
	sets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.first > b.first)

	var width := int(report.width)
	var height := int(report.height)
	var placements := 0
	var sort_layers: Array = []
	for layer_def: Dictionary in tmj.layers:
		if not layer_def.has("data"):
			continue
		var lname := String(layer_def.get("name", "layer"))
		var layer := TileMapLayer.new()
		layer.name = lname
		layer.tile_set = tileset
		# Overhang-class layers (awnings, eaves — pack naming convention)
		# ride the CANOPY band: their cells are WALKABLE by design (54%
		# in the dusk pack), so the player walks UNDER them and must be
		# occluded, exactly like forest crowns (arena_builder precedent).
		# Threat bands all sit above CANOPY — Law 1 is untouched by
		# construction (render band asserts cover it at boot). This
		# consumes the pack's canopy z one world early; pull-forward
		# recorded in the planning log 2026-07-28.
		if lname.contains("overhang"):
			layer.z_index = RenderLayers.CANOPY
		root.add_child(layer)
		var data: Array = layer_def.data
		if lname == "structures":
			# Whole-building sort (cities-open ruling): see header note.
			layer.y_sort_enabled = true
			layer.z_index = RenderLayers.ACTORS
			placements += _place_structures(layer, data, width, tileset, sets, by_base)
			sort_layers.append(layer)
			continue
		if lname in ["props", "fence", "wall"]:
			# Single-cell verticals sort per cell (default center origin).
			layer.y_sort_enabled = true
			layer.z_index = RenderLayers.ACTORS
			sort_layers.append(layer)
		for i in data.size():
			var gid := int(data[i])
			if gid == 0:
				continue
			var t := _resolve_gid(gid, sets, by_base)
			if t.is_empty():
				continue
			@warning_ignore("integer_division")
			var cell := Vector2i(i % width, i / width)
			layer.set_cell(cell, int(t.sid), t.coords)
			placements += 1

	print(
		(
			"world_builder: '%s' rendered — %d placements across %d layers in %d ms"
			% [
				String(pack_manifest.world),
				placements,
				tmj.layers.size(),
				Time.get_ticks_msec() - t0,
			]
		)
	)
	return {
		"def": {"width": width, "height": height},
		"bitgrid": report.bitgrid,
		"spawn": report.spawn,
		"placements": placements,
		"sort_layers": sort_layers,
	}


## Resolve a TMJ gid against the package tilesets: {sid, coords} or {}.
static func _resolve_gid(gid: int, sets: Array, by_base: Dictionary) -> Dictionary:
	for s: Dictionary in sets:
		if gid >= int(s.first):
			var fam: Dictionary = by_base[s.base]
			var local := gid - int(s.first)
			var frames := int(fam.frames)
			if frames > 1:
				local -= local % frames
			var cols := int(fam.columns)
			@warning_ignore("integer_division")
			var coords := Vector2i(local % cols, local / cols)
			return {"sid": int(fam.sid), "coords": coords}
	return {}


## Alternative-tile ids per (source, coords, sort offset) — process-wide
## so scene reloads (T reset) reuse alternatives instead of duplicating
## them on the shared tileforge TileSet resource.
static var _alt_cache: Dictionary = {}


static func _sorted_alt(tileset: TileSet, sid: int, coords: Vector2i, offset_px: int) -> int:
	if offset_px == 0:
		return 0
	var key := "%d/%d,%d/%d" % [sid, coords.x, coords.y, offset_px]
	if _alt_cache.has(key):
		return int(_alt_cache[key])
	var src := tileset.get_source(sid) as TileSetAtlasSource
	if src == null:
		return 0
	var alt := src.create_alternative_tile(coords)
	src.get_tile_data(coords, alt).y_sort_origin = offset_px
	_alt_cache[key] = alt
	return alt


## Structures place as y-sorted BUILDINGS: connected cells (4-neighbor)
## form one building; every cell's sort origin drops to the component's
## BASE row via _sorted_alt, so a whole facade draws as one depth object
## and actors weave the between-house gaps with correct occlusion.
static func _place_structures(
	layer: TileMapLayer, data: Array, width: int, tileset: TileSet, sets: Array, by_base: Dictionary
) -> int:
	var present := {}
	for i in data.size():
		if int(data[i]) != 0:
			present[i] = true
	var base_row := {}
	var seen := {}
	for i: int in present:
		if seen.has(i):
			continue
		var comp: Array[int] = []
		var queue: Array[int] = [i]
		seen[i] = true
		var base := 0
		while not queue.is_empty():
			var c: int = queue.pop_back()
			comp.append(c)
			@warning_ignore("integer_division")
			base = maxi(base, c / width)
			for n: int in [c - 1, c + 1, c - width, c + width]:
				if not present.has(n) or seen.has(n):
					continue
				if absi((n % width) - (c % width)) > 1:
					continue  # row-wrap guard for the c±1 neighbors
				seen[n] = true
				queue.append(n)
		for c: int in comp:
			base_row[c] = base
	var placed := 0
	for i: int in present:
		var t := _resolve_gid(int(data[i]), sets, by_base)
		if t.is_empty():
			continue
		@warning_ignore("integer_division")
		var row := i / width
		var alt := _sorted_alt(tileset, int(t.sid), t.coords, (int(base_row[i]) - row) * TILE)
		layer.set_cell(Vector2i(i % width, row), int(t.sid), t.coords, alt)
		placed += 1
	return placed
