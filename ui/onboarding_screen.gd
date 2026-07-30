extends PanelContainer
## Tester onboarding screen (docs/12 §4 M8): shown ONCE per app run in the
## tester profile, over the paused arena — the "tester-facing start
## screen" the M8 accept list names, carrying the bundle-return step and
## the lowest-speed loadout selector (CORE-53: tester protocols include
## lowest-speed segments; the choice is a visible button, never a hidden
## setting). Dev profile never sees it; the arena stays visible behind it.
##
## ALL COPY BELOW IS PLACEHOLDER — designer voice pending (Tier 1 pass).
## Constraints on any rewrite (quiet-lab law, CORE-54/55): no coaching, no
## play instructions beyond raw controls, and NEVER a request to play for
## a target duration — re-engagement evidence must stay voluntary.

signal start_pressed(speed: float)

const COPY_INTRO := (
	"An early build of the real game: loot drops, levels grow,\n"
	+ "and dying costs. Play as much or as little as you like."
)
const COPY_CONTROLS := (
	"Move WASD - aim with the mouse - hold to fire.\n"
	+ "O opens options: remap any key, effects, audio, damage numbers."
)
const COPY_FEEDBACK := (
	"When you are done: O -> feedback -> save bundle.\n"
	+ "Send the zip back where you got this build, or just paste\n"
	+ "the short code it shows you."
)
const COPY_SPEED := (
	"Pick a movement speed for this session. Both are the real game;\n"
	+ "some sessions on the lowest speed help the test."
)

var build_id := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(440.0, 0.0)

	var title := Label.new()
	title.text = "WILDSHOT ADVENTURES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := Label.new()
	sub.text = "combat lab - build %s" % build_id
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(1, 1, 1, 0.7)
	box.add_child(sub)

	for copy: String in [COPY_INTRO, COPY_CONTROLS, COPY_FEEDBACK, COPY_SPEED]:
		var l := Label.new()
		l.text = copy
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var standard := Button.new()
	standard.text = "start - standard speed"
	standard.pressed.connect(func() -> void: start_pressed.emit(4.0))
	row.add_child(standard)
	var lowest := Button.new()
	lowest.text = "start - lowest speed"
	lowest.pressed.connect(func() -> void: start_pressed.emit(3.0))
	row.add_child(lowest)
	box.add_child(row)

	margin.add_child(box)
	add_child(margin)
