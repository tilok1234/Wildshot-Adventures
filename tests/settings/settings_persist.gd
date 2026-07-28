extends SceneTree
## Remap persistence test (M3 acceptance: "remaps persist across restart").
## Simulates the restart cycle headless: register defaults, rebind W->J
## through Config, wipe the live InputMap, re-register defaults, re-apply
## saved remaps from disk, and assert the binding survived. Uses a test
## settings path — the designer's real settings.cfg is never touched.
##
## Run: godot --headless --path . --script tests/settings/settings_persist.gd

const InputMapDefaults := preload("res://input/input_map_defaults.gd")
const ConfigScript := preload("res://autoload/config.gd")

const TEST_PATH := "user://settings_test.cfg"


func _init() -> void:
	var config: Node = ConfigScript.new()
	config.settings_path = TEST_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))

	InputMapDefaults.register()
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_J
	config.rebind("move_up", ev)
	if ConfigScript.binding_text("move_up") != "J":
		printerr("FAIL: live rebind did not apply: %s" % ConfigScript.binding_text("move_up"))
		quit(1)
		return

	# "Restart": wipe the action, restore defaults, re-apply from disk.
	InputMap.action_erase_events("move_up")
	InputMap.erase_action("move_up")
	InputMapDefaults.register()
	if ConfigScript.binding_text("move_up") != "W":
		printerr("FAIL: default did not restore before re-apply")
		quit(1)
		return
	config.apply_saved_remaps()
	if ConfigScript.binding_text("move_up") != "J":
		printerr("FAIL: remap did not persist across the restart cycle")
		quit(1)
		return

	# config_version present per §2.13.
	var cf := ConfigFile.new()
	cf.load(TEST_PATH)
	if int(cf.get_value("meta", "config_version", -1)) != ConfigScript.CONFIG_VERSION:
		printerr("FAIL: config_version missing from settings file")
		quit(1)
		return

	# CORE-50 effect-scaler keys (M6 EffectLibrary pass): round-trip the
	# [effects] section through the generic setting path — the same
	# write/read cycle the options rows use.
	config.set_setting("effects", "density", 2)
	config.set_setting("effects", "opacity", 1)
	config.set_setting("effects", "flash_reduction", true)
	if int(config.get_setting("effects", "density", -1)) != 2:
		printerr("FAIL: effects/density did not persist")
		quit(1)
		return
	if int(config.get_setting("effects", "opacity", -1)) != 1:
		printerr("FAIL: effects/opacity did not persist")
		quit(1)
		return
	if not bool(config.get_setting("effects", "flash_reduction", false)):
		printerr("FAIL: effects/flash_reduction did not persist")
		quit(1)
		return

	# CORE-50 per-channel audio keys (M6 audio cue map): same round-trip.
	config.set_setting("audio", "keythreats", 1)
	if int(config.get_setting("audio", "keythreats", -1)) != 1:
		printerr("FAIL: audio/keythreats did not persist")
		quit(1)
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	config.free()
	print(
		"PASS: remap persisted across simulated restart (W->J on move_up); effects keys round-trip"
	)
	quit(0)
