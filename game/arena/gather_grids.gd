extends RefCounted
## Forage CANDIDATE-POOL derivation (S1 seam 6, sl-0104/0105; REBUILT
## by sl-0198 THE FORAGING BUILD): every gather-species prop cell in
## the WorldForge pack — WYSIWYG, like collision: a forage node can
## only ever sit ON a real stump / fallen log / bush / mushrooms prop
## (the sl-0063 walkable-carpet arc's own vocabulary; prop chunk
## values are 1-based indexes into propTypes). Pure reads; returns
## parallel cell/species arrays in DETERMINISTIC pack order (chunk
## array order, then row-major) — the sim consumes them as
## DEFINITIONS (excluded from serialize; the replay header's data
## hash covers the pack). The pool is CANDIDACY, never simultaneity:
## the ambient spawner (gather_step, rng_misc) surfaces a capped [T]
## handful of live nodes on it. Arena scenarios never call this: the
## pool stays empty and the verb is inert.
## SPECIES IDS derive from the prop names themselves (zero authoring;
## PLAIN overworld names — the cosmic naming rail is
## starhook-lane-only and does NOT apply here). APPEND-ONLY order:
## profile keys ride the id strings, the wallet index space rides
## this list.
## (Starhook rift NODES are authored scenario data, not derived —
## sl-0105; the fishing-era water derivation retired with fishing.)

const FORAGE_SPECIES: Array[String] = [
	"prop.stump", "prop.fallen_log", "prop.bush", "prop.mushrooms"
]


## The derived species vocabulary: "prop.stump" -> "stump" (plain
## overworld ids; display swaps "_" for " " view-side).
static func species_ids() -> Array[String]:
	var ids: Array[String] = []
	for pname in FORAGE_SPECIES:
		ids.append(pname.trim_prefix("prop."))
	return ids


## Returns {ok, cells: PackedVector2Array (centers), species:
## PackedInt32Array (parallel; indexes species_ids()), species_ids,
## forage_cells: int}; ok=false logs loudly (a missing pack must
## never quietly produce a dead verb).
static func derive(src: String) -> Dictionary:
	var world_json: Variant = JSON.parse_string(FileAccess.get_file_as_string(src + "world.json"))
	if not world_json is Dictionary:
		push_error("gather_grids: pack unreadable at " + src)
		return {"ok": false}
	var dims: Dictionary = world_json.get("dimensions", {})
	var w := int(dims.get("width", 256))
	var h := int(dims.get("height", 256))
	var chunk_size := int(dims.get("chunkSize", 32))
	# propTypes index (1-based in chunk data) -> species index.
	var species_of: Dictionary = {}
	var ptypes: Array = world_json.get("propTypes", [])
	for i in ptypes.size():
		var si := FORAGE_SPECIES.find(String(ptypes[i]))
		if si >= 0:
			species_of[i + 1] = si
	var cells := PackedVector2Array()
	var species := PackedInt32Array()
	var seen: Dictionary = {}
	for chunk: Dictionary in world_json.get("chunks", []):
		var coord: Array = chunk.coord
		var base_x := int(coord[0]) * chunk_size
		var base_y := int(coord[1]) * chunk_size
		var prop_rows: Array = chunk.layers.get("prop", [])
		for ry in prop_rows.size():
			var row: Array = prop_rows[ry]
			for rx in row.size():
				if not species_of.has(int(row[rx])):
					continue
				var cx := base_x + rx
				var cy := base_y + ry
				if cx >= w or cy >= h:
					continue
				var key := cy * w + cx
				if seen.has(key):
					continue
				seen[key] = true
				cells.append(Vector2(float(cx) + 0.5, float(cy) + 0.5))
				species.append(int(species_of[int(row[rx])]))
	print("gather_grids: %d forage pool cells (%s)" % [cells.size(), ", ".join(FORAGE_SPECIES)])
	return {
		"ok": true,
		"cells": cells,
		"species": species,
		"species_ids": species_ids(),
		"forage_cells": cells.size(),
	}
