extends Control
## The pause + options menu (docs/12 §2.8, CORE-50 "full remapping
## from start" — honestly met at M3 with persistence; RESTYLED by the
## menu pass onto the options_v2 panel2 chrome, EVERY existing row
## carried). Toggled by the options_toggle action (O) and the pause
## key through pause_changed. Every registered gameplay action is
## listed; click a binding, press the new key or mouse button, Esc
## cancels capture. Rebinds route through the Config autoload (live +
## persisted in one call). Duplicate bindings are permitted silently
## at M3 — the M4 UX pass adds conflict warnings. The close button
## emits close_requested — main resumes (closing the menu IS
## unpausing; the sl-0145 chrome rule).

signal close_requested

const InputMapDefaults := preload("res://input/input_map_defaults.gd")
const MenuPalette := preload("res://ui/menu_palette.gd")
const Panel2 := preload("res://ui/panel2.gd")

## The options_v2 stage [T].
const BASE_SIZE := Vector2(340.0, 324.0)

var _buttons: Dictionary = {}
var _capturing := ""
var _rows: VBoxContainer = null
var _panel: Panel2 = null
## Defensive autoload access (the char_sheet pattern): probes/tests
## run without the Config GLOBAL NAME compiling under --script — the
## node lookup keeps this file probe-able (sl-0065 lesson, re-earned
## by the seam-F options probe hang).
var _cfg: Node = null


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


## Free-text row (the M8 comments box): multi-line, returned so the
## caller can read .text at bundle time. Esc releases focus (the
## caller's typing suppression keys off has_focus).
func add_comment_row(title: String, placeholder: String) -> TextEdit:
	var lbl := Label.new()
	lbl.text = title
	_rows.add_child(lbl)
	var te := TextEdit.new()
	te.custom_minimum_size = Vector2(260.0, 64.0)
	te.placeholder_text = placeholder
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	te.gui_input.connect(
		func(e: InputEvent) -> void:
			if e is InputEventKey and e.pressed and e.physical_keycode == KEY_ESCAPE:
				te.release_focus()
				te.accept_event()
	)
	_rows.add_child(te)
	return te


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
	_cfg = get_node_or_null("/root/Config")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = Panel2.new()
	_panel.title = "OPTIONS"
	_panel.title_icon = "emblem.class.staff"
	_panel.show_close = true
	_panel.close_requested.connect(func() -> void: close_requested.emit())
	add_child(_panel)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows = rows
	scroll.add_child(rows)
	_panel.content.add_child(scroll)
	# The options_v2 order: option rows first, INPUT REMAPS below —
	# main wires its rows right after construction (same frame), so
	# the remap section builds DEFERRED to land beneath them.
	_build_remaps.call_deferred()
	_fit()
	get_viewport().size_changed.connect(_fit)


func _build_remaps() -> void:
	var title := Label.new()
	title.text = "INPUT REMAPS — click, then press a key"
	title.add_theme_color_override("font_color", MenuPalette.TEXT_DIM)
	_rows.add_child(title)
	for action: String in _remappable_actions():
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = action
		name_label.custom_minimum_size = Vector2(160.0, 0.0)
		var btn := Button.new()
		btn.text = _binding_text(action)
		btn.pressed.connect(_begin_capture.bind(action))
		row.add_child(name_label)
		row.add_child(btn)
		_rows.add_child(row)
		_buttons[action] = btn


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_inside_tree():
		_fit()


func _fit() -> void:
	if _panel == null:
		return
	var k := maxf(get_theme_default_base_scale(), 1.0)
	var vp := get_viewport_rect().size
	var w := minf(BASE_SIZE.x * k, vp.x - 8.0)
	var h := minf(BASE_SIZE.y * k, vp.y - 8.0)
	_panel.position = (vp - Vector2(w, h)) * 0.5
	_panel.size = Vector2(w, h)


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
			_buttons[_capturing].text = _binding_text(_capturing)
			_capturing = ""
			return
		_apply(event)
	elif event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		_apply(event)


func _apply(event: InputEvent) -> void:
	if _cfg != null:
		_cfg.call("rebind", _capturing, event)
	_buttons[_capturing].text = _binding_text(_capturing)
	_capturing = ""


func _binding_text(action: String) -> String:
	if _cfg != null:
		return String(_cfg.call("binding_text", action))
	return action


static func _remappable_actions() -> Array:
	var actions := InputMapDefaults.KEY_ACTIONS.keys()
	actions.append_array(InputMapDefaults.MOUSE_ACTIONS.keys())
	return actions
