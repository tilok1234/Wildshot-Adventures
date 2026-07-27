extends RefCounted
## Code-registered InputMap defaults (docs/12 §2.8, CORE-50): every gameplay
## action exists as a named InputMap action from day one, so full remapping
## (M3 options UI + settings.cfg persistence) rebinds without touching code.
## Movement keys use PHYSICAL keycodes (WASD stays WASD-shaped on any
## layout). Registration is idempotent and never overrides an action that
## already exists (e.g. restored remaps).
##
## No aim-assist action exists and none may be added (CORE-50: zero
## aim-assist code).

const KEY_ACTIONS := {
	"move_up": KEY_W,
	"move_down": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"autofire_toggle": KEY_E,
	"ability": KEY_SPACE,
	"weapon_1": KEY_1,
	"weapon_2": KEY_2,
	"weapon_3": KEY_3,
	"pause_toggle": KEY_ESCAPE,
	"interp_toggle": KEY_F7,
}
const MOUSE_ACTIONS := {
	"fire": MOUSE_BUTTON_LEFT,
}


static func register() -> void:
	for action: String in KEY_ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_ACTIONS[action]
		InputMap.action_add_event(action, ev)
	for action: String in MOUSE_ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_ACTIONS[action]
		InputMap.action_add_event(action, ev)
