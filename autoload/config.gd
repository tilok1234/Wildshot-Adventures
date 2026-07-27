extends Node
## Config autoload — one of the exactly four allowed autoloads, holding
## ZERO gameplay state (docs/12 §2.5). Owns user://settings.cfg
## (ConfigFile, config_version int — §2.13) and applies persisted input
## remaps at startup, after code-registered defaults. M3 scope: remaps
## only. Every future key lands with its implementing milestone — no dead
## keys exist in the file by rule (§2.13).

const InputMapDefaults := preload("res://input/input_map_defaults.gd")

const SETTINGS_PATH := "user://settings.cfg"
const CONFIG_VERSION := 1

## Injectable for tests only — the persistence test must never touch the
## real settings file.
var settings_path := SETTINGS_PATH


func _ready() -> void:
	InputMapDefaults.register()
	apply_saved_remaps()


func apply_saved_remaps() -> void:
	var cf := ConfigFile.new()
	if cf.load(settings_path) != OK:
		return
	if not cf.has_section("input_remaps"):
		return
	for action: String in cf.get_section_keys("input_remaps"):
		if not InputMap.has_action(action):
			continue
		var ev := event_from_descriptor(cf.get_value("input_remaps", action))
		if ev == null:
			continue
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, ev)


## Rebind an action live AND persist it. The remap UI's one entry point.
func rebind(action: String, ev: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, ev)
	var cf := ConfigFile.new()
	cf.load(settings_path)  # missing file is fine — starting fresh
	cf.set_value("meta", "config_version", CONFIG_VERSION)
	cf.set_value("input_remaps", action, descriptor_from_event(ev))
	cf.save(settings_path)


## Generic persisted setting (feedback toggles, scaling, ...). Sections
## and keys exist only once their implementing milestone lands — no dead
## keys (§2.13).
func get_setting(section: String, key: String, default: Variant) -> Variant:
	var cf := ConfigFile.new()
	if cf.load(settings_path) != OK:
		return default
	return cf.get_value(section, key, default)


func set_setting(section: String, key: String, value: Variant) -> void:
	var cf := ConfigFile.new()
	cf.load(settings_path)  # missing file is fine
	cf.set_value("meta", "config_version", CONFIG_VERSION)
	cf.set_value(section, key, value)
	cf.save(settings_path)


static func descriptor_from_event(ev: InputEvent) -> Dictionary:
	if ev is InputEventKey:
		var code: Key = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
		return {"kind": "key", "code": int(code)}
	if ev is InputEventMouseButton:
		return {"kind": "mouse", "code": int(ev.button_index)}
	return {}


static func event_from_descriptor(d: Variant) -> InputEvent:
	if not d is Dictionary:
		return null
	match String(d.get("kind", "")):
		"key":
			var e := InputEventKey.new()
			e.physical_keycode = int(d.code) as Key
			return e
		"mouse":
			var m := InputEventMouseButton.new()
			m.button_index = int(d.code) as MouseButton
			return m
	return null


## Display text for an action's first binding.
static func binding_text(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "(unbound)"
	var ev := events[0]
	if ev is InputEventKey:
		var code: Key = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
		return OS.get_keycode_string(code)
	if ev is InputEventMouseButton:
		return "Mouse %d" % int(ev.button_index)
	return ev.as_text()
