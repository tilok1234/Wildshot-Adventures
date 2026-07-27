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
	# Dev/utility defaults deliberately avoid the F-row — the dev
	# machine's keyboard has no F1–F12 (designer constraint, recorded
	# 2026-07-27). Future debug keys (M4 console etc.) follow this rule.
	"interp_toggle": KEY_I,
	# M2 movement-speed editor (§3.2 presets; full stat editor lands M4):
	# [ = lowest-intended 3.0, ] = baseline 4.0, -/= step by 0.1.
	"debug_speed_lowest": KEY_BRACKETLEFT,
	"debug_speed_baseline": KEY_BRACKETRIGHT,
	"debug_speed_down": KEY_MINUS,
	"debug_speed_up": KEY_EQUAL,
	# M3 replay capture: dump the session recording to user://replays/.
	"replay_save": KEY_R,
	# M3 options panel (remap UI).
	"options_toggle": KEY_O,
	# M3 GIF ring buffer dump.
	"gif_dump": KEY_G,
}
## Modifier-key actions (registered separately): Alt+Enter fullscreen.
const ALT_KEY_ACTIONS := {
	"fullscreen_toggle": KEY_ENTER,
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
	for action: String in ALT_KEY_ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = ALT_KEY_ACTIONS[action]
		ev.alt_pressed = true
		InputMap.action_add_event(action, ev)
