extends Control
## THE WALK-OVER LOOT PANEL (sl-0129, RESTYLED by the menu pass —
## loot_v2): standing on a ground loot bag displays its contents — NO
## press to open, BY THE DESIGNER'S OWN WORD (sl-0147: loot bags stay
## walk-over while stations go F-interact). Panel2 chrome with the
## LOOT plaque, icon + grammar-line rows (click to loot one), the
## gold-framed [B] loot-all primary. All ops RECORDED through the
## sampler; the panel never touches sim state. Bottom-center, quiet;
## gameplay input suppresses while the mouse rides it.

const ItemText := preload("res://game/views/item_text.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")
const MenuPalette := preload("res://ui/menu_palette.gd")
const Panel2 := preload("res://ui/panel2.gd")
const IconAtlas := preload("res://ui/icon_atlas.gd")
const ItemIcons := preload("res://game/views/item_icons.gd")

const BASE_W := 240.0

var world: RefCounted = null
var bag_op_sink := Callable()

var _panel: Panel2 = null
var _rows_box: VBoxContainer = null
var _accum := 0.0
var _sig := ""


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = Panel2.new()
	_panel.title = "LOOT"
	_panel.title_icon = "quest.turn_in"
	_panel.show_close = false
	add_child(_panel)
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 2)
	_panel.content.add_child(_rows_box)


func wants_suppress() -> bool:
	return visible and _panel.get_global_rect().has_point(get_global_mouse_position())


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
		(c as CanvasItem).visible = false
		c.queue_free()
	var k := maxf(get_theme_default_base_scale(), 1.0)
	var p: RefCounted = world.players[0]
	var p_class := int(p.class_id)
	for row: Dictionary in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 4)
		var icon := TextureRect.new()
		icon.texture = IconAtlas.icon(ItemIcons.icon_id(world, row.item, p_class))
		icon.custom_minimum_size = Vector2(16.0, 16.0) * k
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		line.add_child(icon)
		var b := Button.new()
		b.text = String(row.line)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.tooltip_text = String(row.line) + "\n(click to loot this)"
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_queue_op.bind(int(row.op)))
		line.add_child(b)
		_rows_box.add_child(line)
	var cap := Button.new()
	cap.text = "[%s] loot all" % _loot_key_name()
	cap.add_theme_stylebox_override("normal", _primary_box())
	cap.add_theme_stylebox_override("hover", _primary_box())
	cap.add_theme_color_override("font_color", MenuPalette.GOLD_BRIGHT)
	cap.pressed.connect(_queue_op.bind(BagStep.OP_LOOT_ALL))
	_rows_box.add_child(cap)
	# Bottom-center above the hints line (the loot_v2 dy placement).
	var w := BASE_W * k
	var h := (44.0 + 20.0 * float(rows.size())) * k
	_panel.position = Vector2((size.x - w) * 0.5, size.y - h - 34.0 * k)
	_panel.size = Vector2(w, h)


## The live loot-all binding for the caption (remap-honest).
func _loot_key_name() -> String:
	var cfg: Node = get_node_or_null("/root/Config")
	if cfg != null:
		return String(cfg.call("binding_text", "loot_all"))
	return "B"


static func _primary_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = MenuPalette.PLAQUE_BOTTOM
	sb.border_color = MenuPalette.GOLD
	sb.set_border_width_all(1)
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 1.0
	sb.content_margin_bottom = 1.0
	return sb


func _queue_op(op: int) -> void:
	if bag_op_sink.is_valid():
		bag_op_sink.call(op)


## ---- PURE MODEL: the nearest in-reach bag's rows (grammar lines +
## the recorded loot-row op per row + the item triple for the icon;
## capped at the op range).
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
		var it := {"kind": items[row * 3], "a": items[row * 3 + 1], "b": items[row * 3 + 2]}
		var line := ItemText.drop_line(world, it)
		out.append({"line": line, "op": BagStep.OP_LOOT_ROW_BASE + row, "item": it})
	return out
