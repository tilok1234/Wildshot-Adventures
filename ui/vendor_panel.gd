extends Control
## THE VENDOR (sl-0131 v1, REBUILT by the menu pass — vendor_v2 + the
## sl-0145/0147 station rule): opens on F INTERACT at a vendor body —
## NEVER walk-over anymore (leaving the radius still closes). Panel2
## chrome with the TRADER plaque; gold in the head rule; two SHELF
## columns — the static catalog (click the price to buy) and the bag
## (click the price to sell) — icon + name + stat sub-line + a
## gold-framed price chip per row, all lines in the one grammar,
## every trade a RECORDED bag op (radius + gold guarded sim-side).
## sell 50% / buy 200% [T]; the catalog is fixed. Overflow scrolls.
## View-only.

const ItemText := preload("res://game/views/item_text.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")
const MenuPalette := preload("res://ui/menu_palette.gd")
const Panel2 := preload("res://ui/panel2.gd")
const ItemSlot := preload("res://ui/item_slot.gd")
const IconAtlas := preload("res://ui/icon_atlas.gd")
const ItemIcons := preload("res://game/views/item_icons.gd")

const BASE_SIZE := Vector2(450.0, 300.0)

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
	_panel.title = "TRADER"
	_panel.title_icon = "currency.gold"
	_panel.show_close = true
	_panel.close_requested.connect(station_close)
	add_child(_panel)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 3)
	_panel.content.add_child(_body)


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
	if p.class_id < 0 or p.dead or BagStep.nearest_vendor(world, p) < 0:
		_open = false
	if not _open:
		visible = false
		_sig = ""
		return
	visible = true
	var buys := buy_rows(world)
	var sells := sell_rows(world)
	var sig := str(buys) + "|" + str(sells) + "|" + str(p.gold)
	if sig == _sig:
		return
	_sig = sig
	_rebuild(p, buys, sells)


func _rebuild(p: RefCounted, buys: Array, sells: Array) -> void:
	for c in _body.get_children():
		(c as CanvasItem).visible = false
		c.queue_free()
	var k := maxf(get_theme_default_base_scale(), 1.0)
	var p_class := int(p.class_id)
	_body.add_child(_rule("— vendor —  (your gold: %d)" % p.gold))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(scroll)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 8)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(cols)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	left.add_child(_rule("for sale  (click to buy)"))
	if buys.is_empty():
		left.add_child(_rule("(nothing for sale)"))
	for row: Dictionary in buys:
		left.add_child(_shelf_row(row, p_class, k))
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 2)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	right.add_child(_rule("your bag  (click to sell)"))
	if sells.is_empty():
		right.add_child(_rule("(the bag is empty)"))
	for row: Dictionary in sells:
		right.add_child(_shelf_row(row, p_class, k))
	var foot := Label.new()
	foot.text = "sell 50% · buy 200% · the catalog is fixed"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_color_override("font_color", MenuPalette.TEXT_DIM)
	_body.add_child(foot)
	var w := BASE_SIZE.x * k
	var h := BASE_SIZE.y * k
	_panel.position = (size - Vector2(w, h)) * 0.5
	_panel.size = Vector2(w, h)


## One shelf row: icon slot + name/stat lines + the gold price chip
## (the chip is the button — the affordance the capture shows).
func _shelf_row(row: Dictionary, p_class: int, k: float) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var slot := ItemSlot.new()
	slot.cell_px = 22.0
	var it: Dictionary = row.item
	slot.icon_tex = IconAtlas.icon(ItemIcons.icon_id(world, it, p_class))
	slot.tooltip_text = String(row.tip)
	box.add_child(slot)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(col)
	var line := String(row.line)
	var name_l := Label.new()
	name_l.text = line.get_slice(" — ", 0)
	name_l.add_theme_color_override("font_color", MenuPalette.TEXT_BRIGHT)
	col.add_child(name_l)
	if line.contains(" — "):
		var sub := Label.new()
		sub.text = line.get_slice(" — ", 1)
		sub.add_theme_color_override("font_color", MenuPalette.TEXT_BASE)
		col.add_child(sub)
	var chip := Button.new()
	chip.text = String(row.price_text)
	chip.tooltip_text = String(row.tip)
	chip.add_theme_stylebox_override("normal", _chip_box())
	chip.add_theme_stylebox_override("hover", _chip_box())
	chip.add_theme_color_override("font_color", MenuPalette.GOLD_BRIGHT)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var op := int(row.op)
	chip.pressed.connect(_queue_op.bind(op))
	box.add_child(chip)
	return box


static func _chip_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = MenuPalette.PLAQUE_BOTTOM
	sb.border_color = MenuPalette.GOLD_DIM
	sb.set_border_width_all(1)
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 1.0
	sb.content_margin_bottom = 1.0
	return sb


func _rule(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", MenuPalette.TEXT_DIM)
	return l


func _queue_op(op: int) -> void:
	if bag_op_sink.is_valid():
		bag_op_sink.call(op)


## ---- PURE MODELS (grammar lines + prices + recorded op codes + the
## item triple for the icon lookup).


static func buy_rows(world: RefCounted) -> Array:
	var out: Array = []
	var p: RefCounted = world.players[0]
	var vi := BagStep.nearest_vendor(world, p)
	if vi < 0 or vi >= world.vendor_stock.size():
		return out
	var stock: PackedInt32Array = world.vendor_stock[vi]
	var n := mini(stock.size() / 3, BagStep.BUY_ROW_MAX)
	for row in n:
		var kind := stock[row * 3]
		var a := stock[row * 3 + 1]
		var b := stock[row * 3 + 2]
		var line := ItemText.drop_line(world, {"kind": kind, "a": a, "b": b})
		var price := BagStep.buy_price(world, kind, a, b)
		(
			out
			. append(
				{
					"line": line,
					"tip": line + "\n(click to buy for %d gold)" % price,
					"op": BagStep.OP_BUY_BASE + row,
					"item": {"kind": kind, "a": a, "b": b},
					"price_text": "%dg" % price,
				}
			)
		)
	return out


static func sell_rows(world: RefCounted) -> Array:
	var out: Array = []
	var p: RefCounted = world.players[0]
	for slot in BagStep.bag_count(p):
		var it: Dictionary = BagStep.bag_item(p, slot)
		var line := ItemText.drop_line(world, it)
		var price := BagStep.sell_price(world, int(it.kind), int(it.a), int(it.b))
		(
			out
			. append(
				{
					"line": line,
					"tip": line + "\n(click to sell for %d gold)" % price,
					"op": BagStep.OP_SELL_BASE + slot,
					"item": it,
					"price_text": "+%dg" % price,
				}
			)
		)
	return out
