extends RefCounted
## ReplaySource (docs/12 §2.8): the third InputSource. Loads a .wsr file
## and hands back the recorded InputFrames tick by tick — the sim cannot
## tell it from a human or a bot. Also exposes the header and checkpoints
## for verification (tests/replay_fixtures/verify_replays.gd).

const InputFrame := preload("res://sim/input_frame.gd")
const ReplayFormat := preload("res://input/replay_format.gd")

var header: Dictionary = {}
var tick_count: int = 0
## Array of {tick, hash} in file order.
var checkpoints: Array[Dictionary] = []

var _buf := StreamPeerBuffer.new()
var _frames_start := 0
var _player_count := 0


func load_file(path: String) -> bool:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		push_error("replay_source: cannot read %s" % path)
		return false
	_buf = StreamPeerBuffer.new()
	_buf.data_array = bytes
	header = ReplayFormat.read_header(_buf)
	if header.is_empty():
		push_error("replay_source: bad magic/version in %s" % path)
		return false
	_player_count = int(header.player_count)
	tick_count = _buf.get_u32()
	_frames_start = _buf.get_position()
	# Frames are fixed-size records; jump past them to the checkpoints.
	_buf.seek(_frames_start + tick_count * _player_count * InputFrame.SERIALIZED_SIZE)
	var n := _buf.get_u32()
	checkpoints.clear()
	for i in n:
		var t := _buf.get_64()
		var h := _buf.get_64()
		checkpoints.append({"tick": t, "hash": h})
	return true


## Frames for tick t (0-based from recording start), one per player.
## Returns [] past the end of the recording.
func frames_for_tick(t: int) -> Array:
	if t < 0 or t >= tick_count:
		return []
	_buf.seek(_frames_start + t * _player_count * InputFrame.SERIALIZED_SIZE)
	var out := []
	for i in _player_count:
		out.append(InputFrame.deserialize_from(_buf))
	return out
