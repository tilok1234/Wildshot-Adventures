extends Node2D
## Phase A lab main scene (M2 state): builds the arena from
## data/arena_lab.json, bakes the collision bitgrid from the same
## definition, then boots the sim — SimWorld + RealtimeDriver +
## HumanSampler — with the player rendering from its Sprite Forge sheet.
## Scenario picker and debug tooling land at M4.

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const SimWorld := preload("res://sim/sim_world.gd")
const RealtimeDriver := preload("res://game/drivers/realtime_driver.gd")
const HumanSampler := preload("res://input/human_sampler.gd")
const InputMapDefaults := preload("res://input/input_map_defaults.gd")
const ActorLibrary := preload("res://game/views/actor_library.gd")
const AnimatedActor := preload("res://game/views/animated_actor.gd")

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
	var arena := ArenaBuilder.build_arena(self)
	if arena.is_empty():
		return
	var def: Dictionary = arena.def
	bitgrid = arena.bitgrid

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

	var lib := ActorLibrary.new()
	var sheet_map: Resource = load("res://data/actor_sheet_map.tres")
	if lib.load_manifest() and sheet_map != null and lib.has_actor(String(sheet_map.map.player)):
		var av := AnimatedActor.new()
		av.sprite_frames = lib.build_sprite_frames(String(sheet_map.map.player))
		av.actor = world.players[0]
		av.clock = view_clock
		av.play("idle-down")
		add_child(av)
	else:
		push_error("main: player sheet unavailable — run the spriteforge importer")

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
				int(arena.placements),
				RUN_SEED,
			]
		)
	)
