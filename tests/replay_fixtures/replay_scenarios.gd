extends RefCounted
## Scenario builders for replay recording/playback. A replay reconstructs
## initial state by scenario id + seed; the header's initial-state hash
## then PROVES the reconstruction matches what was recorded — any drift in
## arena data, spawn layout, or defaults fails verification loudly.
## Scenario definitions move to data/*.tres at M4 (scenario picker); until
## then this code map is the scenario registry for replay tooling.

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const SimWorld := preload("res://sim/sim_world.gd")


static func build(scenario_id: String, seed_v: int) -> RefCounted:
	match scenario_id:
		"golden_ring_v1":
			return _golden_ring(seed_v)
	push_error("replay_scenarios: unknown scenario '%s'" % scenario_id)
	return null


## Player at arena center with the three weapon frames; two stand-in
## rings — inner inside Wheelblade's out-and-return, outer in Longbolt
## reach. The layout every golden replay records against.
static func _golden_ring(seed_v: int) -> RefCounted:
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://tileforge/tileforge-manifest.json")
	)
	var def := ArenaBuilder.load_def("res://data/arena_lab.json")
	var grid := Bitgrid.new()
	grid.setup(int(def.width), int(def.height))
	for c: Vector2i in ArenaBuilder.solid_cells(def, manifest):
		grid.set_solid(c.x, c.y)
	var world := SimWorld.new()
	world.setup(seed_v, grid)
	(
		world
		. set_weapons(
			[
				load("res://data/weapons/longbolt.tres"),
				load("res://data/weapons/scattercast.tres"),
				load("res://data/weapons/wheelblade.tres"),
			]
		)
	)
	world.add_player(Vector2(24.0, 16.0))
	for i in 6:
		var ang := TAU * i / 6.0
		world.add_enemy_standin(Vector2(24.0, 16.0) + Vector2(cos(ang), sin(ang)) * 3.0)
	for i in 6:
		var ang := TAU * (i + 0.5) / 6.0
		world.add_enemy_standin(Vector2(24.0, 16.0) + Vector2(cos(ang), sin(ang)) * 6.0)
	return world
