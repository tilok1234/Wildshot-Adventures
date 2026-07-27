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
var speed_label: Label


func _process(_delta: float) -> void:
	# §2.9 prev/curr render toggle (F7) — view-side only, replay-irrelevant.
	if view_clock != null and Input.is_action_just_pressed("interp_toggle"):
		view_clock.interp_enabled = not view_clock.interp_enabled
		print("render interpolation: ", "ON" if view_clock.interp_enabled else "OFF (snap)")
	if world == null or world.players.is_empty():
		return
	# M2 movement-speed editor: presets + 0.1 steps, routed through the sim
	# command queue (band-clamped and replay-dirty-stamped sim-side, §3.2).
	var cur: float = world.players[0].move_speed
	if Input.is_action_just_pressed("debug_speed_lowest"):
		_set_speed(3.0)
	elif Input.is_action_just_pressed("debug_speed_baseline"):
		_set_speed(4.0)
	elif Input.is_action_just_pressed("debug_speed_down"):
		_set_speed(snappedf(cur - 0.1, 0.1))
	elif Input.is_action_just_pressed("debug_speed_up"):
		_set_speed(snappedf(cur + 0.1, 0.1))
	speed_label.text = ("speed %.1f t/s%s" % [cur, "   REPLAY-DIRTY" if world.replay_dirty else ""])


func _set_speed(speed: float) -> void:
	world.enqueue_command({"type": SimWorld.Command.SET_MOVE_SPEED, "player": 0, "speed": speed})
	print(
		(
			"speed editor: requested %.1f t/s (band %.1f-%.1f; run now replay-dirty)"
			% [speed, SimWorld.MOVE_SPEED_MIN, SimWorld.MOVE_SPEED_MAX]
		)
	)


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
	speed_label = Label.new()
	speed_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	var hud := CanvasLayer.new()
	hud.add_child(pause_label)
	hud.add_child(speed_label)
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
