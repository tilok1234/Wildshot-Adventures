extends RefCounted
## Forage-spot derivation (S1 seam 6, sl-0104/0105): the FORAGE cell
## mask for the foraging verb, derived from the WorldForge pack's OWN
## prop data — WYSIWYG, like collision: forage where gather species
## RENDER (stump / fallen_log / bush / mushrooms — the sl-0063
## walkable-carpet arc's own vocabulary; prop chunk values are
## 1-based indexes into propTypes). Pure reads; returns a Bitgrid the
## sim consumes as DEFINITIONS (excluded from serialize — the replay
## header's data hash covers the pack). Arena scenarios never call
## this: the mask stays null and the verb is inert.
## (Starhook rift NODES are authored scenario data, not derived —
## sl-0105; the fishing-era water derivation retired with fishing.)

const Bitgrid := preload("res://sim/collision/bitgrid.gd")

const FORAGE_SPECIES: Array[String] = [
	"prop.stump", "prop.fallen_log", "prop.bush", "prop.mushrooms"
]


## Returns {ok, forage, forage_cells}; ok=false logs loudly (a
## missing pack must never quietly produce a dead verb).
static func derive(src: String) -> Dictionary:
	var world_json: Variant = JSON.parse_string(FileAccess.get_file_as_string(src + "world.json"))
	if not world_json is Dictionary:
		push_error("gather_grids: pack unreadable at " + src)
		return {"ok": false}
	var dims: Dictionary = world_json.get("dimensions", {})
	var w := int(dims.get("width", 256))
	var h := int(dims.get("height", 256))
	var chunk_size := int(dims.get("chunkSize", 32))
	var forage: RefCounted = Bitgrid.new()
	forage.setup(w, h)
	var species := PackedInt32Array()
	var ptypes: Array = world_json.get("propTypes", [])
	for i in ptypes.size():
		if String(ptypes[i]) in FORAGE_SPECIES:
			species.append(i + 1)
	var forage_cells := 0
	for chunk: Dictionary in world_json.get("chunks", []):
		var coord: Array = chunk.coord
		var base_x := int(coord[0]) * chunk_size
		var base_y := int(coord[1]) * chunk_size
		var prop_rows: Array = chunk.layers.get("prop", [])
		for ry in prop_rows.size():
			var row: Array = prop_rows[ry]
			for rx in row.size():
				if int(row[rx]) in species:
					var cx := base_x + rx
					var cy := base_y + ry
					if cx < w and cy < h and not forage.is_solid(cx, cy):
						forage.set_solid(cx, cy)
						forage_cells += 1
	print("gather_grids: %d forage cells (%s)" % [forage_cells, ", ".join(FORAGE_SPECIES)])
	return {"ok": true, "forage": forage, "forage_cells": forage_cells}
