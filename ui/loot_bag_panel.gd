extends PanelContainer
## THE WALK-OVER LOOT PANEL (sl-0129): standing on a ground loot bag
## displays its contents — no press to open. Rows speak the one
## grammar; CLICK a row to loot that item, [B] loots all (both are
## RECORDED bag ops through the sampler — replay-honest; the panel
## never touches sim state). Bottom-center, quiet; gameplay input
## suppresses while the mouse rides the panel (the C-pane rule).

const ItemText := preload("res://game/views/item_text.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")

var world: RefCounted = null
var bag_op_sink := Callable()

var _rows_box: VBoxContainer = null
var _accum := 0.0
var _sig := ""


func _ready() -> void:
	visible = false
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 1)
	add_child(_rows_box)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0


func wants_suppress() -> bool:
	return visible and get_global_rect().has_point(get_global_mouse_position())


func _process(delta: float) -> void:
	_accum += delta
	if _accum < 0.12:
		return
	_accum = 0.0
	if world == null or world.players.is_empty():
		visible = false
		return
	var rows := panel_rows(world)
	if rows.is_empty():
		visible = false
		_sig = ""
		return
	visible = true
	var sig := str(rows)
	if sig == _sig:
		return
	_sig = sig
	for c in _rows_box.get_children():
		c.queue_free()
	var head := Label.new()
	head.text = "— loot bag —"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rows_box.add_child(head)
	for row: Dictionary in rows:
		var b := Button.new()
		b.text = String(row.line)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.tooltip_text = String(row.line) + "\n(click to loot this)"
		b.clip_text = true
		b.pressed.connect(_queue_op.bind(int(row.op)))
		_rows_box.add_child(b)
	var cap := Label.new()
	cap.text = "[B] loot all"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.modulate = Color(0.85, 0.83, 0.72, 0.9)
	_rows_box.add_child(cap)
	# Fixed bottom-center rect from the row count (no grow games).
	var h := 22.0 + 20.0 * float(rows.size() + 2)
	offset_left = -120.0
	offset_right = 120.0
	offset_bottom = -34.0
	offset_top = -34.0 - h


func _queue_op(op: int) -> void:
	if bag_op_sink.is_valid():
		bag_op_sink.call(op)


## ---- PURE MODEL: the nearest in-reach bag's rows (grammar lines +
## the recorded loot-row op per row; capped at the op range).
static func panel_rows(world: RefCounted) -> Array:
	var out: Array = []
	var p: RefCounted = world.players[0]
	if p.dead:
		return out
	var bi := BagStep.nearest_bag(world, p)
	if bi < 0:
		return out
	var items: PackedInt32Array = world.loot_bags[bi].items
	var n := mini(items.size() / 3, BagStep.LOOT_ROW_MAX)
	for row in n:
		var line := ItemText.drop_line(
			world, {"kind": items[row * 3], "a": items[row * 3 + 1], "b": items[row * 3 + 2]}
		)
		out.append({"line": line, "op": BagStep.OP_LOOT_ROW_BASE + row})
	return out
