extends SceneTree
## Golden-replay generator (docs/12 §2.4/§4 M3): records one .wsr per
## weapon frame on the golden_ring_v1 scenario with a deterministic input
## script — movement legs, aim sweep, hold phases, tap clusters, and an
## autofire-latch window, weapon selected at tick 0. Regenerating after a
## DELIBERATE weapon/scenario change produces new goldens; verify_replays
## failing after an ACCIDENTAL change is the CORE-32 regression alarm.
##
## Run: godot --headless --path . --script tests/replay_fixtures/record_goldens.gd

const InputFrame := preload("res://sim/input_frame.gd")
const ReplayRecorder := preload("res://input/replay_recorder.gd")
const ReplayScenarios := preload("res://tests/replay_fixtures/replay_scenarios.gd")

const TICKS := 1200
const SCENARIO := "golden_ring_v1"
## Stable build id so regenerated goldens differ only when content does.
const BUILD_ID := "golden"

const MOVE_X: Array[int] = [1, 1, 0, -1, -1, -1, 0, 1]
const MOVE_Y: Array[int] = [0, 1, 1, 1, 0, -1, -1, -1]

const WEAPONS := {
	"longbolt": {"select": 1, "seed": 101, "sweep": 0.019},
	"scattercast": {"select": 2, "seed": 202, "sweep": 0.023},
	"wheelblade": {"select": 3, "seed": 303, "sweep": 0.011},
}


func _init() -> void:
	var failed := false
	for weapon_name: String in WEAPONS:
		var cfg: Dictionary = WEAPONS[weapon_name]
		var world: RefCounted = ReplayScenarios.build(SCENARIO, int(cfg.seed))
		if world == null:
			failed = true
			continue
		var rec := ReplayRecorder.new()
		rec.begin(world)
		for t in TICKS:
			var frame := _scripted_frame(t, cfg)
			rec.record_frames([frame])
			world.step([frame])
			rec.after_step()
		var path := "res://tests/replay_fixtures/golden_%s.wsr" % weapon_name
		if rec.save_wsr(path, BUILD_ID, SCENARIO):
			print("record_goldens: %s (%d ticks, final tick %d)" % [path, TICKS, world.tick])
		else:
			failed = true
	quit(1 if failed else 0)


## Deterministic per-weapon input script: hold fire for the first 600
## ticks, three taps at 700/760/820, autofire latched 900..1100 — all
## while the aim sweeps and movement walks the 8-leg pattern.
static func _scripted_frame(t: int, cfg: Dictionary) -> RefCounted:
	var frame := InputFrame.new()
	var leg := (t / 60) % 8
	frame.move_x = MOVE_X[leg]
	frame.move_y = MOVE_Y[leg]
	frame.normalized = true
	var q := InputFrame.quantize_aim(Vector2.RIGHT.rotated(t * float(cfg.sweep)))
	frame.aim_x = q.x
	frame.aim_y = q.y
	if t == 0:
		frame.weapon_select = int(cfg.select)
	frame.fire_held = t < 600 or t in [700, 760, 820]
	frame.autofire_toggle_edge = t == 900 or t == 1100
	return frame
