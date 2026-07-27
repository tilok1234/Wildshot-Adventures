extends Node2D
## Phase A lab main scene (M1 state): builds the arena from data/arena_lab.json
## into TileMapLayers and bakes the collision bitgrid from the same definition.
## Player, sim, and camera control arrive at M2.

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")

var bitgrid: RefCounted


func _ready() -> void:
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://tileforge/tileforge-manifest.json")
	)
	var def := ArenaBuilder.load_def("res://data/arena_lab.json")
	var tileset: TileSet = load("res://tileforge/tileforge.tres")
	if manifest == null or def.is_empty() or tileset == null:
		push_error("main: missing manifest, arena def, or tileforge.tres")
		return

	var sources := ArenaBuilder.family_sources(manifest, tileset)
	var layers := {}
	for layer_name: String in ArenaBuilder.LAYERS:
		var layer := TileMapLayer.new()
		layer.name = layer_name
		layer.tile_set = tileset
		add_child(layer)
		layers[layer_name] = layer

	for p: Dictionary in ArenaBuilder.resolve_placements(def, manifest):
		var src: Dictionary = sources[p.fam]
		var coords := ArenaBuilder.atlas_coords(p.atlas_px, int(src.pad))
		(layers[p.layer] as TileMapLayer).set_cell(p.cell, int(src.sid), coords)

	bitgrid = Bitgrid.new()
	bitgrid.setup(int(def.width), int(def.height))
	for c: Vector2i in ArenaBuilder.solid_cells(def, manifest):
		bitgrid.set_solid(c.x, c.y)

	var camera := Camera2D.new()
	camera.position = Vector2(int(def.width) * 16.0, int(def.height) * 16.0)
	add_child(camera)
	camera.make_current()

	print(
		(
			"arena ready: %dx%d, %d solid cells, %d placements"
			% [int(def.width), int(def.height), bitgrid.solid_count(), get_placement_count(layers)]
		)
	)


func get_placement_count(layers: Dictionary) -> int:
	var n := 0
	for layer_name: String in layers:
		n += (layers[layer_name] as TileMapLayer).get_used_cells().size()
	return n
