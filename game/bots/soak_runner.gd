extends SceneTree
## Headless SoakBot runner (M7 §2.11). Loads the core dynamically so a
## compile failure exits loudly instead of idling forever (the
## bot_runner guard pattern).
##
## Run: godot --headless --path . --script game/bots/soak_runner.gd -- \
##   [--minutes=30] [--seed0=9000] [--policy=primary|reactive] [--out=...]

const BootArgs := preload("res://autoload/boot_args.gd")


func _init() -> void:
	var core: GDScript = load("res://game/bots/soak_bot.gd")
	if core == null or not core.can_instantiate():
		printerr("soak_runner: soak_bot.gd failed to compile/load")
		quit(3)
		return
	var code: int = core.run_from_args(BootArgs.parse_user_args())
	quit(code)
