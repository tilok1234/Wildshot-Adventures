extends PanelContainer
## New-character screen (Loop v1 docs/19 ruling 1; CLASS CHOICE added at
## slice S0 — docs/23 class call: all three from the start). The
## PERMADEATH TOGGLE lives here and only here — chosen once at creation,
## never a setting. Shown over the paused arena whenever no character
## exists (first run, or the run after a hardcore death). The two start
## buttons are the only unpause path, like the onboarding screen.
##
## ALL COPY IS PLACEHOLDER — designer voice pending (Tier 1 pass).

signal chosen(hardcore: bool, cls: String)

const IconAtlas := preload("res://ui/icon_atlas.gd")

const COPY_TITLE := "NEW CHARACTER"
## Icon-pack T1 weapon glyphs as class emblems (seam 4 [P]).
const CLASS_ICONS := {
	"sword": "item.weapon.sword.arming.t1",
	"staff": "item.weapon.staff.longstaff.t1",
	"bow": "item.weapon.bow.recurve.t1",
}
const COPY_NORMAL := (
	"NORMAL - dying sends you back to a settlement and costs part of\n"
	+ "your carried gold. Your equipment is never taken."
)
const COPY_HARDCORE := "HARDCORE - dying deletes this character. Everything. Forever."

## Class rows: plain words for what each concretely does (docs/22
## block-5 identity: sword tanky-slow, staff mana-rich middle, bow
## fast-fragile). Order matches the deliberate default LAST-SELECTED =
## bow (the ranger you have been playing).
const CLASSES: Array[Array] = [
	["sword", "SWORD - heavy close swings that hit hardest. Most health, slowest feet."],
	["staff", "STAFF - long piercing shots. Biggest mana pool, middle speed."],
	["bow", "BOW - quick light shots. Fastest feet, least health."],
]

var _selected := "bow"
var _class_buttons: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(460.0, 0.0)

	var title := Label.new()
	title.text = COPY_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	for row: Array in CLASSES:
		var cls := String(row[0])
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		var emblem := TextureRect.new()
		emblem.custom_minimum_size = Vector2(20.0, 20.0)
		emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if IconAtlas.has_icon(String(CLASS_ICONS[cls])):
			emblem.texture = IconAtlas.icon(String(CLASS_ICONS[cls]))
		line.add_child(emblem)
		var pick := Button.new()
		pick.toggle_mode = true
		pick.text = cls
		pick.custom_minimum_size = Vector2(70.0, 0.0)
		pick.pressed.connect(_on_class_picked.bind(cls))
		_class_buttons[cls] = pick
		line.add_child(pick)
		var desc := Label.new()
		desc.text = String(row[1])
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(desc)
		box.add_child(line)
	_refresh_class_buttons()

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
	normal.pressed.connect(func() -> void: chosen.emit(false, _selected))
	row.add_child(normal)
	var hardcore := Button.new()
	hardcore.text = "start - hardcore"
	hardcore.pressed.connect(func() -> void: chosen.emit(true, _selected))
	row.add_child(hardcore)
	box.add_child(row)

	margin.add_child(box)
	add_child(margin)


func _on_class_picked(cls: String) -> void:
	_selected = cls
	_refresh_class_buttons()


func _refresh_class_buttons() -> void:
	for cls: String in _class_buttons:
		var b: Button = _class_buttons[cls]
		b.button_pressed = cls == _selected
