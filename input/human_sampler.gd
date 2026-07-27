extends RefCounted
## HumanSampler (docs/12 §2.8): snapshots device state into one quantized
## InputFrame per tick. One of three equal InputSources (human, replay, bot)
## — the sim cannot tell them apart. Movement, aim, and fire are three
## independent channels end to end (CORE-32); aim is mouse-to-world,
## snapshotted per tick, quantized to 1/4096 at sample time.
##
## Edges are tick-accurate: tracked against the previously SAMPLED state,
## never Input.is_action_just_pressed — catch-up frames sample several ticks
## in one render frame and just_pressed is per-frame.

const InputFrame := preload("res://sim/input_frame.gd")

var _prev_autofire := false
var _prev_ability := false
var _last_aim := Vector2.RIGHT


## mouse_tile: mouse position in world TILE coordinates (view converts);
## player_pos: the sampled player's sim position, tiles.
func sample(mouse_tile: Vector2, player_pos: Vector2) -> InputFrame:
	var f := InputFrame.new()
	f.move_x = (
		int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	)
	f.move_y = (int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up")))
	f.normalized = true

	var aim := mouse_tile - player_pos
	if aim.length_squared() < 0.0001:
		aim = _last_aim  # mouse dead on the player: hold the last real aim
	else:
		aim = aim.normalized()
		_last_aim = aim
	var q := InputFrame.quantize_aim(aim)
	f.aim_x = q.x
	f.aim_y = q.y

	f.fire_held = Input.is_action_pressed("fire")
	var af := Input.is_action_pressed("autofire_toggle")
	f.autofire_toggle_edge = af and not _prev_autofire
	_prev_autofire = af
	var ab := Input.is_action_pressed("ability")
	f.ability_pressed = ab and not _prev_ability
	_prev_ability = ab
	for i in 3:
		if Input.is_action_pressed("weapon_%d" % (i + 1)):
			f.weapon_select = i + 1
	return f
