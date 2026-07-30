extends PanelContainer
## Loop v1 new-character screen (docs/19 ruling 1): the PERMADEATH
## TOGGLE lives here and only here — chosen once at creation, never a
## setting. Shown over the paused arena whenever no character exists
## (first run, or the run after a hardcore death). The two buttons are
## the only unpause path, like the onboarding screen.
##
## ALL COPY IS PLACEHOLDER — designer voice pending (Tier 1 pass).

signal chosen(hardcore: bool)

const COPY_TITLE := "NEW CHARACTER"
const COPY_NORMAL := (
	"NORMAL - dying sends you back to town and costs part of your\n"
	+ "carried gold. Your equipment is never taken."
)
const COPY_HARDCORE := "HARDCORE - dying deletes this character. Everything. Forever."


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(420.0, 0.0)

	var title := Label.new()
	title.text = COPY_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	for copy: String in [COPY_NORMAL, COPY_HARDCORE]:
		var l := Label.new()
		l.text = copy
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var normal := Button.new()
	normal.text = "start - normal"
	normal.pressed.connect(func() -> void: chosen.emit(false))
	row.add_child(normal)
	var hardcore := Button.new()
	hardcore.text = "start - hardcore"
	hardcore.pressed.connect(func() -> void: chosen.emit(true))
	row.add_child(hardcore)
	box.add_child(row)

	margin.add_child(box)
	add_child(margin)
