extends Control
## THE BANK (sl-0130, REBUILT by the menu pass — bank_v2 + the
## sl-0145/0147 station rule): the settlement stash opens on F
## INTERACT at the keeper — NEVER walk-over anymore (the designer's
## re-rule; leaving the radius still closes it). Panel2 chrome with
## the BANK VAULT plaque; two SLOT GRIDS — the bank (click to
## withdraw) and the bag (click to deposit) — capacities in the
## rules, tooltips in the one grammar, every move a RECORDED bag op
## (radius-guarded sim-side regardless of the view). Death never
## touches the bank. Drag is DEFERRED (no format bump for a gesture)
## — the hints state only what ships. View-only.

const ItemText := preload("res://game/views/item_text.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")
const MenuPalette := preload("res://ui/menu_palette.gd")
const Panel2 := preload("res://ui/panel2.gd")
const ItemSlot := preload("res://ui/item_slot.gd")
const IconAtlas := preload("res://ui/icon_atlas.gd")
const ItemIcons := preload("res://game/views/item_icons.gd")

const BASE_SIZE := Vector2(430.0, 192.0)

var world: RefCounted = null
var bag_op_sink := Callable()

var _open := false
var _panel: Panel2 = null
var _body: VBoxContainer = null
var _accum := 0.0
var _sig := ""


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = Panel2.new()
	_panel.title = "BANK VAULT"
	_panel.title_icon = "currency.gold"
	_panel.show_close = true
	_panel.close_requested.connect(station_close)
	add_child(_panel)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 3)
	_panel.content.add_child(_body)


## The F-interact station rule (sl-0145/0147): main opens on the
## press at the keeper; pressing again toggles closed.
func station_open() -> void:
	_open = true
	_sig = ""


func station_close() -> void:
	_open = false


func station_toggle() -> void:
	if _open:
		station_close()
	else:
		station_open()


func is_open() -> bool:
	return _open


func wants_suppress() -> bool:
	return visible and _panel.get_global_rect().has_point(get_global_mouse_position())


func _process(delta: float) -> void:
	_accum += delta
	if _accum < 0.15:
		return
	_accum = 0.0
	if world == null or world.players.is_empty():
		visible = false
		return
	var p: RefCounted = world.players[0]
	# Walking away closes for real (the radius stays the law).
	if p.class_id < 0 or p.dead or not BagStep.at_bank(world, p):
		_open = false
	if not _open:
		visible = false
		_sig = ""
		return
	visible = true
	var bank := bank_rows(world)
	var bag := deposit_rows(world)
	var sig := str(bank) + "|" + str(bag)
	if sig == _sig:
		return
	_sig = sig
	_rebuild(p, bank, bag)


func _rebuild(p: RefCounted, bank: Array, bag: Array) -> void:
	for c in _body.get_children():
		(c as CanvasItem).visible = false
		c.queue_free()
	var k := maxf(get_theme_default_base_scale(), 1.0)
	var p_class := int(p.class_id)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 6)
	_body.add_child(cols)
	# LEFT: the stash grid.
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	cols.add_child(left)
	left.add_child(
		_rule("— bank %d/%d —  (click to withdraw)" % [BagStep.bank_count(p), BagStep.BANK_CAP])
	)
	left.add_child(_grid(bank, BagStep.BANK_CAP, p, p_class, k))
	# CENTER: the exchange divider (visual only — click is the verb).
	var mid := VBoxContainer.new()
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	cols.add_child(mid)
	var arrows := Label.new()
	arrows.text = "⇄"
	arrows.add_theme_color_override("font_color", MenuPalette.GOLD)
	mid.add_child(arrows)
	# RIGHT: the bag grid.
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 2)
	cols.add_child(right)
	right.add_child(
		_rule("— bag %d/%d —  (click to deposit)" % [BagStep.bag_count(p), BagStep.BAG_CAP])
	)
	right.add_child(_grid(bag, BagStep.BAG_CAP, p, p_class, k))
	var foot := Label.new()
	foot.text = "death never touches the bank"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_color_override("font_color", MenuPalette.TEXT_DIM)
	_body.add_child(foot)
	var w := BASE_SIZE.x * k
	var h := BASE_SIZE.y * k
	_panel.position = (size - Vector2(w, h)) * 0.5
	_panel.size = Vector2(w, h)


## A capacity-sized slot grid: filled rows get icons + grammar
## tooltips + the recorded op on click; the rest sit empty.
func _grid(rows: Array, cap: int, p: RefCounted, p_class: int, _k: float) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	for slot in cap:
		var cell := ItemSlot.new()
		if slot < rows.size():
			var row: Dictionary = rows[slot]
			var it: Dictionary = row.item
			cell.icon_tex = IconAtlas.icon(ItemIcons.icon_id(world, it, p_class))
			cell.tooltip_text = String(row.tip)
			var op := int(row.op)
			cell.slot_clicked.connect(
				func(button_index: int) -> void:
					if button_index == MOUSE_BUTTON_LEFT:
						_queue_op(op)
			)
		grid.add_child(cell)
	return grid


func _rule(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", MenuPalette.TEXT_DIM)
	return l


func _queue_op(op: int) -> void:
	if bag_op_sink.is_valid():
		bag_op_sink.call(op)


## ---- PURE MODELS (grammar lines + recorded op codes + the item
## triple for the icon lookup).


static func bank_rows(world: RefCounted) -> Array:
	var out: Array = []
	var p: RefCounted = world.players[0]
	for slot in BagStep.bank_count(p):
		var it: Dictionary = BagStep.bank_item(p, slot)
		var line := ItemText.drop_line(world, it)
		(
			out
			. append(
				{
					"line": line,
					"tip": line + "\n(click to withdraw to the bag)",
					"op": BagStep.OP_WITHDRAW_BASE + slot,
					"item": it,
				}
			)
		)
	return out


static func deposit_rows(world: RefCounted) -> Array:
	var out: Array = []
	var p: RefCounted = world.players[0]
	for slot in BagStep.bag_count(p):
		var it: Dictionary = BagStep.bag_item(p, slot)
		var line := ItemText.drop_line(world, it)
		(
			out
			. append(
				{
					"line": line,
					"tip": line + "\n(click to deposit into the bank)",
					"op": BagStep.OP_DEPOSIT_BASE + slot,
					"item": it,
				}
			)
		)
	return out
