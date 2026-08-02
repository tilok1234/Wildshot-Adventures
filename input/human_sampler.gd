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

## GUI text entry (the M8 comments box) suppresses gameplay input:
## neutral frames go to the sim while device state keeps being tracked,
## so no stale autofire/ability edge fires when typing ends.
var suppress := false

var _prev_autofire := false
var _prev_ability := false
var _prev_interact := false
var _prev_rod_swap := false
var _last_aim := Vector2.RIGHT
## sl-0116: the C-pane queues ONE bag op; the next sampled frame
## carries it (exactly once — an edge by construction). Rides even
## suppressed frames: the pane click IS the suppressor.
var _queued_bag_op := 0


func queue_bag_op(code: int) -> void:
	_queued_bag_op = code


## mouse_tile: mouse position in world TILE coordinates (view converts);
## player_pos: the sampled player's sim position, tiles.
## equipped/rod_count (sl-0115): the live rod slot + how many rods the
## rifter's LEVEL has unlocked — the R edge emits weapon_select as the
## next unlocked slot, riding the byte the stream always carried (zero
## format change; the sim gate in player_fire stays the authority).
## rod_count 0 = not a rift world; R is inert.
func sample(mouse_tile: Vector2, player_pos: Vector2, equipped := 0, rod_count := 0) -> InputFrame:
	if suppress:
		var nf := InputFrame.new()
		nf.normalized = true
		var qs := InputFrame.quantize_aim(_last_aim)
		nf.aim_x = qs.x
		nf.aim_y = qs.y
		nf.bag_op = _queued_bag_op
		_queued_bag_op = 0
		_prev_autofire = Input.is_action_pressed("autofire_toggle")
		_prev_ability = Input.is_action_pressed("ability")
		_prev_interact = Input.is_action_pressed("interact")
		_prev_rod_swap = Input.is_action_pressed("rod_swap")
		return nf
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
	var ia := Input.is_action_pressed("interact")
	f.interact_pressed = ia and not _prev_interact
	_prev_interact = ia
	for i in 4:
		if Input.is_action_pressed("weapon_%d" % (i + 1)):
			f.weapon_select = i + 1
	var rs := Input.is_action_pressed("rod_swap")
	if rs and not _prev_rod_swap and rod_count > 0:
		f.weapon_select = (equipped + 1) % rod_count + 1
	_prev_rod_swap = rs
	f.bag_op = _queued_bag_op
	_queued_bag_op = 0
	return f
