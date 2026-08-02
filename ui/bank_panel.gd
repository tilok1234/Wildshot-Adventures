extends PanelContainer
## THE BANK PANEL (sl-0130): walk up to the settlement stash (the
## stash keeper's station) and the panel shows — no press to open
## (the loot-panel walk-over language; the ask's [T] station call).
## Two lists: the BANK (click a row to withdraw) and the BAG (click
## a row to deposit). All moves are RECORDED bag ops through the
## sampler — replay-honest; deposit/withdraw refuse beyond the bank
## radius sim-side regardless of what the view shows. Death never
## touches the bank. Tooltips speak the one grammar.

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
	if p.class_id < 0 or p.dead or not BagStep.at_bank(world, p):
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
	for c in _box.get_children():
		c.queue_free()
	var head := Label.new()
	head.text = "— bank %d/%d —  (click to withdraw)" % [BagStep.bank_count(p), BagStep.BANK_CAP]
	_box.add_child(head)
	if bank.is_empty():
		var empty := Label.new()
		empty.text = "(the stash is empty)"
		_box.add_child(empty)
	for row: Dictionary in bank:
		_box.add_child(_row_button(row))
	var bag_head := Label.new()
	bag_head.text = "— bag %d/%d —  (click to deposit)" % [BagStep.bag_count(p), BagStep.BAG_CAP]
	_box.add_child(bag_head)
	if bag.is_empty():
		var bempty := Label.new()
		bempty.text = "(the bag is empty)"
		_box.add_child(bempty)
	for row: Dictionary in bag:
		_box.add_child(_row_button(row))
	# Fixed centered rect from the row count (right of screen center
	# would cover the keeper — center reads cleanly at 640x360).
	var rows_n := (
		bank.size() + bag.size() + (1 if bank.is_empty() else 0) + (1 if bag.is_empty() else 0)
	)
	var h := 30.0 + 20.0 * float(rows_n + 2)
	offset_left = -130.0
	offset_right = 130.0
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


## ---- PURE MODELS (grammar lines + recorded op codes).


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
				}
			)
		)
	return out
