extends PanelContainer
## Quake-style debug console (docs/12 §2.10, M4). Toggled by
## console_toggle (default `). Owns display + line parsing only —
## execution runs through the callable main injects, so sim-access rules
## live in one place. The event console (`events on`) tails the driver
## relay here.

signal line_submitted(line: String)

const MAX_LINES := 14

var _log := Label.new()
var _input := LineEdit.new()
var _lines: Array[String] = []


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	var vbox := VBoxContainer.new()
	_log.text = ""
	vbox.add_child(_log)
	_input.placeholder_text = "help for commands"
	_input.text_submitted.connect(_on_submit)
	vbox.add_child(_input)
	add_child(vbox)


func toggle() -> void:
	visible = not visible
	if visible:
		_input.grab_focus()
	else:
		_input.release_focus()


func println(s: String) -> void:
	_lines.append(s)
	while _lines.size() > MAX_LINES:
		_lines.pop_front()
	_log.text = "\n".join(_lines)


func _on_submit(text: String) -> void:
	_input.clear()
	if text.strip_edges().is_empty():
		return
	println("> " + text)
	line_submitted.emit(text)
