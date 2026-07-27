extends SceneTree
## Headless DodgeBot proof runner (docs/12 §2.11): builds the scenario's
## SimWorld with NO presentation and steps flat-out under the movement-
## only policy. PASS = every seeded run lands ZERO hits on the player.
## Any hit dumps a .wsr repro for human adjudication. Reports (JSON, with
## near-miss distance and a coarse positional heatmap) land in reports/,
## labeled mechanical verification — no gate-tracking code reads them
## (TOOLING bot contract, CORE-53). Proofs are speed-stamped (§2.11).
##
## Run: godot --headless --path . --script game/bots/bot_runner.gd -- \
##   --scenario=proof_rusher --speed=3.0 --seeds=1,2,3,4,5 --ticks=3600 \
##   [--out=reports/dodge_proof_rusher.json]
## (--speed=lowest is an alias for 3.0. --runs=N with --seed=X expands to
##  seeds X..X+N-1 when --seeds is absent.)

const BootArgs := preload("res://autoload/boot_args.gd")


func _init() -> void:
	# Loaded dynamically so a compile failure in the proof core exits
	# loudly instead of erroring mid-_init and idling forever (no quit).
	var runner: GDScript = load("res://game/bots/dodge_proof.gd")
	if runner == null or not runner.can_instantiate():
		printerr("bot_runner: dodge_proof.gd failed to compile/load")
		quit(3)
		return
	var code: int = runner.run_from_args(BootArgs.parse_user_args())
	quit(code)
