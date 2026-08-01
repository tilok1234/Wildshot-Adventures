extends RefCounted
## WorldForge world consumption (the 2026-07-28 generated-test-arena
## ruling): validates a game pack (worldforge_pack.gd — hash chain,
## walkability, flood) and renders its RESOLVED TMJ layers into
## TileMapLayers against the game's own TileForge package. The pack's
## pinned package identity MUST match an imported tileforge package
## from TILEFORGE_PACKAGES (checked here: sourceCommit+seed vs
## tileforge.packageId) — resolved gids are meaningless against a
## different atlas build.
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

## Imported TileForge package registry, one dir per package BUILD —
## multiple builds stay imported side by side because committed packs
## pin different builds (b65-era packs pin the M1 dusk-ae1eecb import
## at res://tileforge/; the b76 paired drop, sl-0061, pins
## dusk-9b8b2a2-seed103991). Resolution scans this list for the pack's
## pinned identity; a pin nothing matches refuses loudly, exactly as
## the single-package check always did. Future package intakes append
## one line here (import via addons/tileforge_importer/run_import.gd
## --package=<dir>).
const TILEFORGE_PACKAGES: Array[String] = [
	"res://tileforge/",
	"res://tileforge_packages/dusk-9b8b2a2-seed103991/",
]


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

	pack_src = WorldforgePack.resolve_src(pack_src)
	var pack_manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(pack_src + "manifest.json")
	)
	var pkg := resolve_package(pack_manifest)
	if pkg.is_empty():
		return {}
	var manifest: Variant = pkg.manifest
	var tileset: TileSet = pkg.tileset
	print("world_builder: tileforge package '%s' resolved" % String(pkg.pinned))

	var tmj: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(pack_src + "resolved/resolved-map.tmj")
	)
	var tables := gid_tables(manifest, tileset, tmj)
	if tables.is_empty():
		return {}
	var by_base: Dictionary = tables.by_base
	var sets: Array = tables.sets

	var width := int(report.width)
	var height := int(report.height)
	var placements := 0
	var per_layer := {}
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
			# Whole-building sort (cities-open ruling): the flat layer is
			# replaced by ONE container of per-building mini-layers, each
			# sorted as a single node at its base row — see the helper.
			layer.free()
			var buildings := Node2D.new()
			buildings.name = "structures"
			buildings.y_sort_enabled = true
			buildings.z_index = RenderLayers.ACTORS
			root.add_child(buildings)
			var built := _place_structures(buildings, data, width, tileset, sets, by_base)
			placements += built
			per_layer[lname] = built
			sort_layers.append(buildings)
			continue
		if lname in ["props", "fence", "wall"]:
			# Single-cell verticals sort per cell (default center origin).
			layer.y_sort_enabled = true
			layer.z_index = RenderLayers.ACTORS
			sort_layers.append(layer)
		var placed := 0
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
			placed += 1
		placements += placed
		per_layer[lname] = placed

	# Per-layer counts stay loud at every load: a layer whose data resolves
	# to zero placements is a finding, never silence (sl-0047 lesson — the
	# road layer's absence was invisible in the roll-up total).
	var counts := ""
	for k: String in per_layer:
		counts += "%s=%d " % [k, int(per_layer[k])]
	print("world_builder: layer placements: " + counts.strip_edges())
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


## Resolve the pack's pinned TileForge package from the registry:
## {manifest, tileset, pinned} or {} (loud refusal on a pin nothing
## matches — rendering against a different atlas build is meaningless).
## Extracted at sl-0078 so prop_colliders shares the exact resolution.
static func resolve_package(pack_manifest: Variant) -> Dictionary:
	var pinned := String(pack_manifest.tileforge.packageId)
	var theme := String(pack_manifest.tileforge.theme)
	var manifest: Variant = null
	var tileset: TileSet = null
	var available: Array[String] = []
	for pkg_dir: String in TILEFORGE_PACKAGES:
		var m: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(pkg_dir + "tileforge-manifest.json")
		)
		if m == null:
			continue
		var id := "%s-%s-seed%d" % [theme, String(m.sourceCommit), int(m.projectSeed)]
		available.append(id)
		if id == pinned and manifest == null:
			manifest = m
			tileset = load(pkg_dir + "tileforge.tres")
	if manifest == null or tileset == null:
		push_error(
			(
				"world_builder: pack pinned to '%s' but the imported packages are %s — refusing to render against a different atlas build"
				% [pinned, str(available)]
			)
		)
		return {}
	return {"manifest": manifest, "tileset": tileset, "pinned": pinned}


## Family lookup by tsj/image basename + per-family source id, columns,
## frames (frame-0 snap for animated families), plus the tmj tileset
## ranges sorted for gid resolution: {by_base, sets} or {}.
static func gid_tables(manifest: Variant, tileset: TileSet, tmj: Variant) -> Dictionary:
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
	return {"by_base": by_base, "sets": sets}


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


## Structures place as y-sorted BUILDINGS: connected cells (4-neighbor)
## form one building, rendered as its own mini TileMapLayer positioned
## so the NODE's y = the building's base-row bottom edge. The parent
## container y-sorts whole nodes, so a facade draws as one depth object
## and actors weave the between-house gaps with correct occlusion.
## (No alternative tiles, no shared-tileset mutation — plain layers.)
static func _place_structures(
	container: Node2D, data: Array, width: int, tileset: TileSet, sets: Array, by_base: Dictionary
) -> int:
	var present := {}
	for i in data.size():
		if int(data[i]) != 0:
			present[i] = true
	var placed := 0
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
		var building := TileMapLayer.new()
		building.tile_set = tileset
		# Sort anchor: the bottom edge of the base row. Cells are indexed
		# relative to that anchor so world pixels land unchanged.
		var anchor_row := base + 1
		building.position = Vector2(0, anchor_row * TILE)
		for c: int in comp:
			var t := _resolve_gid(int(data[c]), sets, by_base)
			if t.is_empty():
				continue
			@warning_ignore("integer_division")
			var row := c / width
			building.set_cell(Vector2i(c % width, row - anchor_row), int(t.sid), t.coords)
			placed += 1
		container.add_child(building)
	return placed
