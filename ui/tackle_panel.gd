extends Control
## THE TACKLE KEEPER (sl-0177/0178 — the gear seam): the rifter's gear
## shop at the harbor capital's tackle cell. Opens on F INTERACT at the
## station (sl-0145 law; walking out closes). Panel2 chrome; the FISH
## WALLET in the head rule (species-currency, the money of the rift
## loop); the tiered catalog grouped by starhook tier — priced rows
## carry a fish-price chip (a RECORDED tackle-buy op; fish + ownership
## guarded sim-side), owned chest/helm rows carry an equip chip (a
## recorded equip op), the four level-grant spine rods show as dim info
## rows. Placeholder visuals by the designer's word — real stats, real
## slots, plain rows. View-only.

const ItemText := preload("res://game/views/item_text.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")
const TackleCatalog := preload("res://sim/tackle_catalog.gd")
const MenuPalette := preload("res://ui/menu_palette.gd")
const Panel2 := preload("res://ui/panel2.gd")

const BASE_SIZE := Vector2(430.0, 310.0)

var world: RefCounted = null
var bag_op_sink := Callable()
## The persistent profile (the starhook level gates read it live).
var character: Dictionary = {}

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
	_panel.title = "TACKLE"
	_panel.title_icon = "collect.fish.f01"
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
	if p.class_id < 0 or p.dead or not BagStep.at_tackle(world, p):
		_open = false
	if not _open:
		visible = false
		_sig = ""
		return
	visible = true
	var sig := (
		str(p.fish)
		+ "|%d|%d|%d|%d" % [p.rods_owned_mask, p.tackle_owned_mask, p.tackle_chest, p.tackle_helm]
	)
	if sig == _sig:
		return
	_sig = sig
	_rebuild(p)


func _rebuild(p: RefCounted) -> void:
	for c in _body.get_children():
		(c as CanvasItem).visible = false
		c.queue_free()
	var k := maxf(get_theme_default_base_scale(), 1.0)
	var frame: Dictionary = world.stat_frame
	_body.add_child(_rule(_wallet_line(frame, p)))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var lvl := int(character.get("starhook_level", 1))
	for tier in [1, 2, 3, 4]:
		var need := TackleCatalog.tier_level(frame, tier)
		var gate_note := "" if lvl >= need else "  (starhook %d needed — you are %d)" % [need, lvl]
		list.add_child(_rule("— tier %d · starhook %d+%s —" % [tier, need, gate_note]))
		for row: Dictionary in catalog_rows(world, p, tier):
			list.add_child(_catalog_row(row))
	var foot := Label.new()
	foot.text = "priced in fish · rare catches drop specials · rods swap in the rift"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_color_override("font_color", MenuPalette.TEXT_DIM)
	_body.add_child(foot)
	var w := BASE_SIZE.x * k
	var h := BASE_SIZE.y * k
	_panel.position = (size - Vector2(w, h)) * 0.5
	_panel.size = Vector2(w, h)


func _catalog_row(row: Dictionary) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(col)
	var line := String(row.line)
	var name_l := Label.new()
	name_l.text = line.get_slice(" — ", 0)
	name_l.add_theme_color_override(
		"font_color", MenuPalette.TEXT_BRIGHT if bool(row.bright) else MenuPalette.TEXT_DIM
	)
	col.add_child(name_l)
	if line.contains(" — "):
		var sub := Label.new()
		sub.text = line.get_slice(" — ", 1)
		sub.add_theme_color_override("font_color", MenuPalette.TEXT_BASE)
		col.add_child(sub)
	var chip_text := String(row.chip_text)
	if chip_text.is_empty():
		return box
	if int(row.op) == 0:
		var mark := Label.new()
		mark.text = chip_text
		mark.add_theme_color_override("font_color", MenuPalette.TEXT_DIM)
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		box.add_child(mark)
		return box
	var chip := Button.new()
	chip.text = chip_text
	chip.tooltip_text = String(row.tip)
	chip.add_theme_stylebox_override("normal", _chip_box())
	chip.add_theme_stylebox_override("hover", _chip_box())
	chip.add_theme_color_override(
		"font_color", MenuPalette.GOLD_BRIGHT if bool(row.afford) else MenuPalette.TEXT_DIM
	)
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


## ---- PURE MODELS (test-pinned: lines in the one grammar, ops from
## bag_step's recorded ranges, states from sim masks).


static func _wallet_line(frame: Dictionary, p: RefCounted) -> String:
	var parts: Array[String] = []
	for si in p.fish.size():
		if p.fish[si] > 0:
			parts.append("%d %s" % [p.fish[si], TackleCatalog.species_name(frame, si)])
	if parts.is_empty():
		return "— your fish: none yet (cast a rift line) —"
	return "— your fish: " + " · ".join(parts) + " —"


## Every catalog row at `tier`, display-ready: the free spine (info),
## priced rods/items (buy chip while unowned), owned chest/helm
## (equip/worn chip). Order: rods (rods-list order) then items.
static func catalog_rows(world_ref: RefCounted, p: RefCounted, tier: int) -> Array[Dictionary]:
	var frame: Dictionary = world_ref.stat_frame
	var out: Array[Dictionary] = []
	var shelf_by_key := {}
	for si in world_ref.tackle_shelf.size():
		var srow: Dictionary = world_ref.tackle_shelf[si]
		shelf_by_key["%d_%d" % [int(srow.row_kind), int(srow.index)]] = si
	var rlist := TackleCatalog.rods(frame)
	for ri in rlist.size():
		var rod: Dictionary = rlist[ri]
		if int(rod.get("tier", 0)) != tier:
			continue
		var res: Resource = load("res://data/weapons/%s.tres" % String(rod.get("id", "")))
		var line := ItemText.rod_line(rod, res)
		if not rod.has("price"):
			(
				out
				. append(
					{
						"line": line,
						"bright": false,
						"chip_text": "level-grant",
						"op": 0,
						"tip": "",
						"afford": false,
					}
				)
			)
			continue
		var owned: bool = (p.rods_owned_mask & (1 << ri)) != 0
		if owned:
			out.append(
				{
					"line": line,
					"bright": true,
					"chip_text": "owned",
					"op": 0,
					"tip": "",
					"afford": false
				}
			)
			continue
		out.append(
			_priced_row(
				world_ref, p, line, shelf_by_key.get("%d_%d" % [TackleCatalog.ROW_ROD, ri], -1), rod
			)
		)
	var ilist := TackleCatalog.items(frame)
	for ii in ilist.size():
		var item: Dictionary = ilist[ii]
		if int(item.get("tier", 0)) != tier:
			continue
		var iline := ItemText.tackle_item_line(item)
		var iowned: bool = (p.tackle_owned_mask & (1 << ii)) != 0
		if not iowned:
			out.append(
				_priced_row(
					world_ref,
					p,
					iline,
					shelf_by_key.get("%d_%d" % [TackleCatalog.ROW_ITEM, ii], -1),
					item
				)
			)
			continue
		var worn: bool = p.tackle_chest == ii or p.tackle_helm == ii
		if worn:
			out.append(
				{
					"line": iline,
					"bright": true,
					"chip_text": "worn",
					"op": 0,
					"tip": "",
					"afford": false
				}
			)
		else:
			(
				out
				. append(
					{
						"line": iline,
						"bright": true,
						"chip_text": "equip",
						"op": BagStep.OP_TACKLE_EQUIP_BASE + ii,
						"tip": iline + "\n(click to wear it)",
						"afford": true,
					}
				)
			)
	return out


static func _priced_row(
	world_ref: RefCounted, p: RefCounted, line: String, shelf_i: int, row: Dictionary
) -> Dictionary:
	var frame: Dictionary = world_ref.stat_frame
	var price: Dictionary = row.get("price", {})
	var price_text := ItemText.fish_price_text(frame, price)
	var afford := false
	if shelf_i >= 0 and shelf_i < world_ref.tackle_shelf.size():
		var srow: Dictionary = world_ref.tackle_shelf[shelf_i]
		afford = TackleCatalog.can_afford(p.fish, srow.get("price_idx", {}))
	return {
		"line": line,
		"bright": true,
		"chip_text": price_text,
		"op": BagStep.OP_TACKLE_BUY_BASE + shelf_i if shelf_i >= 0 else 0,
		"tip": line + "\n(click to buy for %s)" % price_text,
		"afford": afford,
	}
