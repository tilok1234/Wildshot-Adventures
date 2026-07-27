extends SceneTree
## Golden-replay verifier — the standing CORE-32 regression test (docs/12
## §2.4): every .wsr in tests/replay_fixtures/ is rebuilt from its
## scenario id + seed, checked against the recorded initial-state hash and
## data-definitions hash, then stepped through its full input stream with
## every 30-tick checkpoint compared. The M3 acceptance line runs the
## whole set 10 consecutive times. Any mismatch names the tick.
## Dirty-flagged replays are rejected outright — an edited run can never
## become golden evidence.
##
## Windows-scope job (§2.4): never run on Linux runners.
## Run: godot --headless --path . --script tests/replay_fixtures/verify_replays.gd

const ReplaySource := preload("res://input/replay_source.gd")
const ReplayFormat := preload("res://input/replay_format.gd")
const ReplayScenarios := preload("res://tests/replay_fixtures/replay_scenarios.gd")

const RUNS := 10
const FIXTURE_DIR := "res://tests/replay_fixtures"


func _init() -> void:
	var paths: Array[String] = []
	for f in DirAccess.get_files_at(FIXTURE_DIR):
		if f.ends_with(".wsr"):
			paths.append(FIXTURE_DIR + "/" + f)
	if paths.is_empty():
		printerr("FAIL: no .wsr fixtures found — run record_goldens.gd")
		quit(1)
		return

	var failed := false
	for run_i in RUNS:
		for path in paths:
			if not _verify_one(path):
				failed = true
	if failed:
		quit(1)
		return
	print(
		"PASS: %d replay(s) x %d consecutive runs, all checkpoints identical" % [paths.size(), RUNS]
	)
	quit(0)


func _verify_one(path: String) -> bool:
	var src := ReplaySource.new()
	if not src.load_file(path):
		return false
	if bool(src.header.replay_dirty):
		printerr("FAIL: %s is replay-dirty — not verifiable evidence" % path)
		return false
	var world: RefCounted = ReplayScenarios.build(
		String(src.header.scenario_id), int(src.header.seed)
	)
	if world == null:
		return false
	if ReplayFormat.weapons_data_hash(world.weapon_frames) != int(src.header.data_hash):
		printerr(
			"FAIL: %s data-definitions hash mismatch — weapon defs changed since recording" % path
		)
		return false
	for i in world.players.size():
		world.players[i].move_speed = src.header.move_speeds[i]
	if world.state_hash() != int(src.header.initial_state_hash):
		printerr("FAIL: %s initial-state drift — scenario reconstruction differs" % path)
		return false
	var next_cp := 0
	var checkpoints: Array[Dictionary] = src.checkpoints
	for t in src.tick_count:
		world.step(src.frames_for_tick(t))
		if next_cp < checkpoints.size() and world.tick == int(checkpoints[next_cp].tick):
			if world.state_hash() != int(checkpoints[next_cp].hash):
				printerr("FAIL: %s checkpoint mismatch at tick %d" % [path, world.tick])
				return false
			next_cp += 1
	if next_cp != checkpoints.size():
		printerr("FAIL: %s consumed %d/%d checkpoints" % [path, next_cp, checkpoints.size()])
		return false
	return true
