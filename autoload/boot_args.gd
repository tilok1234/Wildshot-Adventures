extends Node
## BootArgs autoload (docs/12 §2.5 — autoload 3 of 4; §2.11): parses the
## user CLI args after "--" into {flag: value}. Holds NO gameplay state
## (the autoload contract); consumers read strings and own their parsing.
## Also usable statically from SceneTree scripts, where autoloads never
## instantiate.

var args: Dictionary = {}


func _init() -> void:
	args = parse_user_args()


func get_arg(key: String, default := "") -> String:
	return String(args.get(key, default))


static func parse_user_args() -> Dictionary:
	var out := {}
	for a: String in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			continue
		var eq := a.find("=")
		if eq > 0:
			out[a.substr(2, eq - 2)] = a.substr(eq + 1)
		else:
			out[a.substr(2)] = "1"
	return out
