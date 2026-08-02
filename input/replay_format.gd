extends RefCounted
## The .wsr replay format (docs/12 §2.4): header {build id, scenario id,
## seed, data-definitions hash, config snapshot incl. movement speed,
## initial state hash} + the InputFrame stream + 30-tick hash checkpoints.
## A replay is initial state + inputs; the initial-state hash catches ANY
## drift in scenario construction (arena edits, spawn changes), and the
## data hash catches weapon-definition drift — golden replays fail loudly
## instead of silently re-recording history.

const MAGIC := 0x31525357  # "WSR1"
## 2 since sl-0112: the interact verb joined the recorded frame
## (SERIALIZED_SIZE 15 -> 16). Version-1 replays refuse loudly —
## history is never silently reinterpreted.
const VERSION := 2
## Checkpoint cadence in ticks (§2.4).
const HASH_EVERY := 30


## FNV-1a over a canonical serialization of the weapon definitions — the
## replay header's data-definitions hash. Field order is fixed; extending
## WeaponFrame/ShotDef extends this serialization too.
static func weapons_data_hash(weapon_frames: Array) -> int:
	var buf := StreamPeerBuffer.new()
	buf.put_u32(weapon_frames.size())
	for wf: Resource in weapon_frames:
		buf.put_utf8_string(String(wf.id))
		buf.put_32(int(wf.pattern_id))
		buf.put_32(int(wf.cadence_ticks))
		var shots: Array = wf.shots
		buf.put_u32(shots.size())
		for shot: Resource in shots:
			buf.put_double(float(shot.angle_offset_deg))
			buf.put_double(float(shot.speed))
			buf.put_double(float(shot.radius))
			buf.put_32(int(shot.damage))
			buf.put_32(int(shot.ttl_ticks))
			buf.put_32(int(shot.program))
			buf.put_double(float(shot.prog_a))
			buf.put_double(float(shot.prog_b))
			buf.put_double(float(shot.prog_c))
			buf.put_32(int(shot.max_passes))
			buf.put_double(float(shot.spawn_offset))
	return _fnv1a_64(buf.data_array)


static func write_header(
	buf: StreamPeerBuffer, build_id: String, scenario_id: String, world: RefCounted
) -> void:
	buf.put_u32(MAGIC)
	buf.put_u16(VERSION)
	buf.put_u8(1 if world.replay_dirty else 0)
	buf.put_utf8_string(build_id)
	buf.put_utf8_string(scenario_id)
	buf.put_64(world.run_seed)
	buf.put_64(weapons_data_hash(world.weapon_frames))
	buf.put_u32(world.players.size())
	for p: RefCounted in world.players:
		buf.put_double(p.move_speed)
	buf.put_64(world.state_hash())


## Returns the parsed header, or {} on a malformed file. Leaves the buffer
## positioned at the frame stream.
static func read_header(buf: StreamPeerBuffer) -> Dictionary:
	if buf.get_u32() != MAGIC:
		return {}
	var version := buf.get_u16()
	if version != VERSION:
		return {}
	var dirty := buf.get_u8() == 1
	var build_id := buf.get_utf8_string()
	var scenario_id := buf.get_utf8_string()
	var seed_v := buf.get_64()
	var data_hash := buf.get_64()
	var player_count := buf.get_u32()
	var speeds: Array[float] = []
	for i in player_count:
		speeds.append(buf.get_double())
	var initial_hash := buf.get_64()
	return {
		"version": version,
		"replay_dirty": dirty,
		"build_id": build_id,
		"scenario_id": scenario_id,
		"seed": seed_v,
		"data_hash": data_hash,
		"player_count": player_count,
		"move_speeds": speeds,
		"initial_state_hash": initial_hash,
	}


static func _fnv1a_64(bytes: PackedByteArray) -> int:
	var h := -3750763034362895579
	for b in bytes:
		h = (h ^ b) * 1099511628211
	return h
