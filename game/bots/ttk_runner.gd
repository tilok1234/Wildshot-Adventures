extends SceneTree
## Headless TTKBot runner (M7 §2.11). Loads the core dynamically so a
## compile failure exits loudly instead of idling forever (the
## bot_runner guard pattern — a silently hanging --script run is a
## parse error).
##
## Run: godot --headless --path . --script game/bots/ttk_runner.gd -- \
##   [--seed=7] [--out=res://reports/ttk_matrix.json]

const BootArgs := preload("res://autoload/boot_args.gd")


func _init() -> void:
	var core: GDScript = load("res://game/bots/ttk_bot.gd")
	if core == null or not core.can_instantiate():
		printerr("ttk_runner: ttk_bot.gd failed to compile/load")
		quit(3)
		return
	var code: int = core.run_from_args(BootArgs.parse_user_args())
	quit(code)
