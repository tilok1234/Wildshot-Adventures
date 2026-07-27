extends Node2D
## Phase A lab main scene (M2 state): builds the arena from
## data/arena_lab.json, bakes the collision bitgrid from the same
## definition, then boots the sim — SimWorld + RealtimeDriver +
## HumanSampler — with a placeholder player view. Scenario picker and
## debug tooling land at M4.

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const SimWorld := preload("res://sim/sim_world.gd")
const RealtimeDriver := preload("res://game/drivers/realtime_driver.gd")
const HumanSampler := preload("res://input/human_sampler.gd")
const InputMapDefaults := preload("res://input/input_map_defaults.gd")
const PlayerView := preload("res://game/views/player_view.gd")

const ViewClock := preload("res://game/views/view_clock.gd")
const CameraRig := preload("res://game/views/camera_rig.gd")

const TILE := 32.0
## Fixed dev seed until the scenario picker (M4) supplies one; always logged.
const RUN_SEED := 1

var bitgrid: RefCounted
var world: SimWorld
var driver: RealtimeDriver
var view_clock: ViewClock


func _process(_delta: float) -> void:
	# §2.9 prev/curr render toggle (F7) — view-side only, replay-irrelevant.
	if view_clock != null and Input.is_action_just_pressed("interp_toggle"):
		view_clock.interp_enabled = not view_clock.interp_enabled
		print("render interpolation: ", "ON" if view_clock.interp_enabled else "OFF (snap)")


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

	InputMapDefaults.register()
	world = SimWorld.new()
	world.setup(RUN_SEED, bitgrid)
	world.add_player(Vector2(int(def.width) / 2.0, int(def.height) / 2.0))

	driver = RealtimeDriver.new()
	driver.world = world
	driver.sampler = HumanSampler.new()
	driver.mouse_tile_provider = func() -> Vector2: return get_global_mouse_position() / TILE
	add_child(driver)

	view_clock = ViewClock.new()
	view_clock.driver = driver

	var pview := PlayerView.new()
	pview.world = world
	pview.clock = view_clock
	add_child(pview)

	var camera := CameraRig.new()
	camera.world = world
	camera.clock = view_clock
	add_child(camera)
	camera.setup(int(def.width), int(def.height))

	var pause_label := Label.new()
	pause_label.text = "PAUSED"
	pause_label.visible = false
	pause_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var hud := CanvasLayer.new()
	hud.add_child(pause_label)
	add_child(hud)
	driver.pause_changed.connect(func(p: bool) -> void: pause_label.visible = p)

	print(
		(
			"arena ready: %dx%d, %d solid cells, %d placements, seed=%d"
			% [
				int(def.width),
				int(def.height),
				bitgrid.solid_count(),
				get_placement_count(layers),
				RUN_SEED,
			]
		)
	)


func get_placement_count(layers: Dictionary) -> int:
	var n := 0
	for layer_name: String in layers:
		n += (layers[layer_name] as TileMapLayer).get_used_cells().size()
	return n
