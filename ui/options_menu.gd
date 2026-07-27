extends PanelContainer
## Input remap panel (docs/12 §2.8, CORE-50 "full remapping from start" —
## honestly met at M3 with persistence). Toggled by the options_toggle
## action (default O). Every registered gameplay action is listed; click
## a binding, press the new key or mouse button, Esc cancels capture.
## Rebinds route through the Config autoload (live + persisted in one
## call). Duplicate bindings are permitted silently at M3 — the M4 UX
## pass adds conflict warnings.

const InputMapDefaults := preload("res://input/input_map_defaults.gd")

var _buttons: Dictionary = {}
var _capturing := ""
var _rows: VBoxContainer = null


## Persisted-feedback checkbox row; cb receives the new bool.
func add_toggle_row(title: String, initial: bool, cb: Callable) -> void:
	var c := CheckBox.new()
	c.text = title
	c.button_pressed = initial
	c.toggled.connect(cb)
	_rows.add_child(c)


## Multi-state cycle button (e.g. damage-number mode); cb receives index.
func add_cycle_row(title: String, names: Array, initial: int, cb: Callable) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = title
	row.add_child(lbl)
	var b := Button.new()
	var state: Array[int] = [initial]
	b.text = String(names[initial])
	b.pressed.connect(
		func() -> void:
			state[0] = (state[0] + 1) % names.size()
			b.text = String(names[state[0]])
			cb.call(state[0])
	)
	row.add_child(b)
	_rows.add_child(row)


## Extra control row (e.g. the M4 ability hot-swap). cb receives the
## pressed index.
func add_button_row(title: String, names: Array, cb: Callable) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = title
	row.add_child(lbl)
	for i in names.size():
		var b := Button.new()
		b.text = String(names[i])
		b.pressed.connect(cb.bind(i))
		row.add_child(b)
	_rows.add_child(row)


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(280.0, 300.0)
	var rows := VBoxContainer.new()
	_rows = rows
	var title := Label.new()
	title.text = "INPUT REMAPS — click, then press a key"
	rows.add_child(title)
	for action: String in _remappable_actions():
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = action
		name_label.custom_minimum_size = Vector2(160.0, 0.0)
		var btn := Button.new()
		btn.text = Config.binding_text(action)
		btn.pressed.connect(_begin_capture.bind(action))
		row.add_child(name_label)
		row.add_child(btn)
		rows.add_child(row)
		_buttons[action] = btn
	scroll.add_child(rows)
	add_child(scroll)


func toggle() -> void:
	visible = not visible
	if not visible:
		_capturing = ""


func _begin_capture(action: String) -> void:
	_capturing = action
	_buttons[action].text = "press a key..."


func _input(event: InputEvent) -> void:
	if _capturing.is_empty() or not visible:
		return
	if event is InputEventKey and event.pressed:
		get_viewport().set_input_as_handled()
		if event.physical_keycode == KEY_ESCAPE:
			_buttons[_capturing].text = Config.binding_text(_capturing)
			_capturing = ""
			return
		_apply(event)
	elif event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		_apply(event)


func _apply(event: InputEvent) -> void:
	Config.rebind(_capturing, event)
	_buttons[_capturing].text = Config.binding_text(_capturing)
	_capturing = ""


static func _remappable_actions() -> Array:
	var actions := InputMapDefaults.KEY_ACTIONS.keys()
	actions.append_array(InputMapDefaults.MOUSE_ACTIONS.keys())
	return actions
