extends RefCounted
## Replay recorder (docs/12 §2.4): captures the InputFrame stream + 30-tick
## hash checkpoints against a live SimWorld. Driver-agnostic — the
## RealtimeDriver feeds it during play and headless scripts feed it
## directly. Call begin() BEFORE the first step (it snapshots the initial
## state hash, seed, and speed config), record_frames() with exactly what
## step() receives, after_step() after every step, then save_wsr(). A null
## frame is recorded as a zeroed frame (sim-equivalent: no movement, no
## fire, no edges).

const InputFrame := preload("res://sim/input_frame.gd")
const ReplayFormat := preload("res://input/replay_format.gd")

var _world: RefCounted = null
var _frames := StreamPeerBuffer.new()
var _checkpoints := StreamPeerBuffer.new()
var _tick_count := 0
var _checkpoint_count := 0
var _initial_hash := 0
var _initial_speeds: Array[float] = []
var _seed := 0


func begin(world: RefCounted) -> void:
	_world = world
	_frames = StreamPeerBuffer.new()
	_checkpoints = StreamPeerBuffer.new()
	_tick_count = 0
	_checkpoint_count = 0
	_initial_hash = world.state_hash()
	_seed = world.run_seed
	_initial_speeds.clear()
	for p: RefCounted in world.players:
		_initial_speeds.append(p.move_speed)


func record_frames(frames: Array) -> void:
	for i in _world.players.size():
		var f: RefCounted = frames[i] if i < frames.size() else null
		if f == null:
			f = InputFrame.new()
		f.serialize_into(_frames)
	_tick_count += 1


func after_step() -> void:
	if (_world.tick % ReplayFormat.HASH_EVERY) == 0:
		_checkpoints.put_64(_world.tick)
		_checkpoints.put_64(_world.state_hash())
		_checkpoint_count += 1


func save_wsr(path: String, build_id: String, scenario_id: String) -> bool:
	var buf := StreamPeerBuffer.new()
	buf.put_u32(ReplayFormat.MAGIC)
	buf.put_u16(ReplayFormat.VERSION)
	buf.put_u8(1 if _world.replay_dirty else 0)
	buf.put_utf8_string(build_id)
	buf.put_utf8_string(scenario_id)
	buf.put_64(_seed)
	buf.put_64(ReplayFormat.weapons_data_hash(_world.weapon_frames))
	buf.put_u32(_initial_speeds.size())
	for s in _initial_speeds:
		buf.put_double(s)
	buf.put_64(_initial_hash)
	buf.put_u32(_tick_count)
	buf.put_data(_frames.data_array)
	buf.put_u32(_checkpoint_count)
	buf.put_data(_checkpoints.data_array)
	var dir := path.get_base_dir()
	if not dir.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("replay_recorder: cannot write %s" % path)
		return false
	f.store_buffer(buf.data_array)
	f.close()
	return true
