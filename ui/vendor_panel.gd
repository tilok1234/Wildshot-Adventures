extends PanelContainer
## THE VENDOR PANEL (sl-0131 v1): walk up to a vendor body and the
## panel shows (the walk-up station language). BUY rows from the
## vendor's static catalog (price = value x buy multiplier [T]) and
## SELL rows from the bag (price = value x sell fraction [T]) — every
## trade is a RECORDED bag op; gold moves integer-exact sim-side; the
## sim refuses beyond the vendor radius regardless of the view.
## Tooltips speak the one grammar. Death/economy notes: selling is
## the loot->gold sink; fish-currency is explicitly FUTURE.

const ItemText := preload("res://game/views/item_text.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")

var world: RefCounted = null
var bag_op_sink := Callable()

var _box: VBoxContainer = null
var _accum := 0.0
var _sig := ""


func _ready() -> void:
	visible = false
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 1)
	add_child(_box)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5


func wants_suppress() -> bool:
	return visible and get_global_rect().has_point(get_global_mouse_position())


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
	for c in _box.get_children():
		c.queue_free()
	var head := Label.new()
	head.text = "— vendor —  (your gold: %d)" % p.gold
	_box.add_child(head)
	var buy_head := Label.new()
	buy_head.text = "for sale  (click to buy)"
	_box.add_child(buy_head)
	if buys.is_empty():
		var bempty := Label.new()
		bempty.text = "(nothing for sale)"
		_box.add_child(bempty)
	for row: Dictionary in buys:
		_box.add_child(_row_button(row))
	var sell_head := Label.new()
	sell_head.text = "your bag  (click to sell)"
	_box.add_child(sell_head)
	if sells.is_empty():
		var sempty := Label.new()
		sempty.text = "(the bag is empty)"
		_box.add_child(sempty)
	for row: Dictionary in sells:
		_box.add_child(_row_button(row))
	var rows_n := (
		buys.size() + sells.size() + (1 if buys.is_empty() else 0) + (1 if sells.is_empty() else 0)
	)
	var h := 30.0 + 20.0 * float(rows_n + 3)
	offset_left = -140.0
	offset_right = 140.0
	offset_top = -h * 0.5
	offset_bottom = h * 0.5


func _row_button(row: Dictionary) -> Button:
	var b := Button.new()
	b.text = String(row.line)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.tooltip_text = String(row.tip)
	b.clip_text = true
	b.pressed.connect(_queue_op.bind(int(row.op)))
	return b


func _queue_op(op: int) -> void:
	if bag_op_sink.is_valid():
		bag_op_sink.call(op)


## ---- PURE MODELS (grammar lines + prices + recorded op codes).


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
					"line": "%s — %dg" % [line, price],
					"tip": line + "\n(click to buy for %d gold)" % price,
					"op": BagStep.OP_BUY_BASE + row,
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
					"line": "%s — +%dg" % [line, price],
					"tip": line + "\n(click to sell for %d gold)" % price,
					"op": BagStep.OP_SELL_BASE + slot,
				}
			)
		)
	return out
