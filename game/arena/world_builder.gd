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
## frame 0 (the pixel_match rule); all world layers draw in the FLOOR
## band in TMJ paint order (no overhead canopy z — actors render above
## the world, Forest-Walk-pre-canopy style); POIs/settlements/minimap
## unconsumed. Semantics come from world.json ONLY when that half lands
## — resolved layers are rendering-only (multi-game rule).

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
	for layer_def: Dictionary in tmj.layers:
		if not layer_def.has("data"):
			continue
		var layer := TileMapLayer.new()
		layer.name = String(layer_def.get("name", "layer"))
		layer.tile_set = tileset
		# Overhang-class layers (awnings, eaves — pack naming convention)
		# ride the CANOPY band: their cells are WALKABLE by design (54%
		# in the dusk pack), so the player walks UNDER them and must be
		# occluded, exactly like forest crowns (arena_builder precedent).
		# Threat bands all sit above CANOPY — Law 1 is untouched by
		# construction (render band asserts cover it at boot). This
		# consumes the pack's canopy z one world early; pull-forward
		# recorded in the planning log 2026-07-28.
		if String(layer_def.get("name", "")).contains("overhang"):
			layer.z_index = RenderLayers.CANOPY
		root.add_child(layer)
		var data: Array = layer_def.data
		for i in data.size():
			var gid := int(data[i])
			if gid == 0:
				continue
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
					var cell := Vector2i(i % width, i / width)
					layer.set_cell(cell, int(fam.sid), coords)
					placements += 1
					break

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
	}
