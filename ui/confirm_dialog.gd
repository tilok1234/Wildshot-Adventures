extends Control
## Small modal confirm (menu pass — the specs load-bear on it: the
## right-click drop flow asks "drop this on the ground?"). Kit-chrome
## popup centered over its owner; two buttons, confirm emits and
## closes, cancel just closes. While visible the OWNER's
## wants_suppress must return true (a modal decision never leaks a
## click into gameplay — callers already poll suppress). View-only.

signal confirmed
signal canceled

const MenuPalette := preload("res://ui/menu_palette.gd")
const Panel2 := preload("res://ui/panel2.gd")

var _panel: Panel2 = null
var _msg: Label = null
var _ok: Button = null
var _cancel: Button = null


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_panel = Panel2.new()
	_panel.show_close = false
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.content.add_child(box)
	_msg = Label.new()
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_msg)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	_ok = Button.new()
	_ok.pressed.connect(
		func() -> void:
			visible = false
			confirmed.emit()
	)
	row.add_child(_ok)
	_cancel = Button.new()
	_cancel.pressed.connect(
		func() -> void:
			visible = false
			canceled.emit()
	)
	row.add_child(_cancel)


## Show centered with the given words. One decision at a time — a
## second ask replaces the first (the old signals stay unfired).
func ask(message: String, ok_label := "yes", cancel_label := "keep it") -> void:
	_msg.text = message
	_ok.text = ok_label
	_cancel.text = cancel_label
	visible = true
	var k := maxf(get_theme_default_base_scale(), 1.0)
	var w := 250.0 * k
	var h := 64.0 * k
	_panel.position = (size - Vector2(w, h)) * 0.5
	_panel.size = Vector2(w, h)


func _gui_input(event: InputEvent) -> void:
	# Clicks outside the popup cancel (never fall through to gameplay).
	if event is InputEventMouseButton and event.pressed:
		if not _panel.get_rect().has_point((event as InputEventMouseButton).position):
			visible = false
			canceled.emit()
		accept_event()
