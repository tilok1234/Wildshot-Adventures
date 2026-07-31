## One-shot probe (b74 intake, sl-0051): the Overworld Walk picker row's
## pack path must validate as the b74 drop — addon validator, flood, spawn,
## behavior version. Not part of the battery; run ad hoc:
##   godot_console --headless --path . --script tests/worldforge_pack/b74_picker_probe.gd
extends SceneTree

const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")


func _init() -> void:
	var scenario: Resource = load("res://data/scenarios/overworld_walk.tres")
	var pack_path: String = scenario.get("worldforge_pack")
	print("picker row -> ", pack_path, " (", scenario.get("display_name"), ")")
	var result: Dictionary = WorldforgePack.validate(pack_path)
	if not result.ok:
		printerr("FAIL: pack did not validate:\n" + "\n".join(result.log))
		quit(1)
		return
	var manifest_text := FileAccess.get_file_as_string(pack_path + "manifest.json")
	var manifest: Dictionary = JSON.parse_string(manifest_text)
	var behavior: int = int(manifest["generator"]["behaviorVersion"])
	var flood: int = int(manifest["walkability"]["floodCount"])
	var spawn: Array = manifest["walkability"]["spawnCell"]
	print("validated: behavior=", behavior, " flood=", flood, " spawn=", spawn)
	if behavior != 74 or flood != 45137 or int(spawn[0]) != 109 or int(spawn[1]) != 182:
		printerr("FAIL: picker row does not load the b74 drop")
		quit(1)
		return
	print("PASS: Overworld Walk picker row loads the b74 overworld (flood 45137, spawn 109,182)")
	quit(0)
