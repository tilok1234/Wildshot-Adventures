extends Control
## THE C MENU (menu pass v2, sl-0150/0152 final shape): ONE menu, TWO
## TABS on the drawn panel2 chrome — tab CHARACTER (portrait + bigbars
## + statchips + dollslots + the bag as a SLOT GRID) and tab QUEST LOG
## (quest cards + parchment detail with proper info + per-quest
## TRACKED + ABANDON). Stats stay READ-ONLY pure-model rows
## (screen==recompute parity by construction, test-pinned); slots are
## the interactive region (the sl-0128 sanction): click equips /
## de-equips, right-click drops through the CONFIRM + toast flow. Ops
## ride the RECORDED bag_op byte (bag_op_sink -> sampler queue ->
## bag_step/quest_step) so every sim mutation is replay-honest; this
## panel never touches sim state directly. C opens it (last-used tab),
## the quest_log action (L [T]) deep-links the log tab, tabs click.
## Never pauses. While the mouse rides the open menu (or a confirm is
## up) main suppresses gameplay input. Tracked choice + last tab
## persist VIEW-SIDE ([ui], options-style); autoload access is
## defensive so probes/tests run without Config. Drag-to-move is
## DEFERRED (a gesture never grows the recorded format) — the hint
## line states only what ships.

signal toast_requested(msg: String)

const ItemText := preload("res://game/views/item_text.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const DropKinds := preload("res://sim/drop_kinds.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")
const TackleCatalog := preload("res://sim/tackle_catalog.gd")
const QuestDef := preload("res://data/quest_def.gd")
const MenuPalette := preload("res://ui/menu_palette.gd")
const Panel2 := preload("res://ui/panel2.gd")
const ItemSlot := preload("res://ui/item_slot.gd")
const IconAtlas := preload("res://ui/icon_atlas.gd")
const ItemIcons := preload("res://game/views/item_icons.gd")
const ConfirmDialog := preload("res://ui/confirm_dialog.gd")
const QuestTracker := preload("res://ui/quest_tracker.gd")
const StatBar := preload("res://ui/stat_bar.gd")

## Fixed screen placement [T: centered] — sl-0119 law carried; the
## c_menu_v2 spec stage (500x336 of 640x360), ui-scale aware, clamped.
const BASE_SIZE := Vector2(500.0, 336.0)
const SCREEN_MARGIN := 4.0
const TAB_CHARACTER := 0
const TAB_ERRANDS := 1

var world: RefCounted = null
## The persistent profile dict (starhook lane lives there).
var character: Dictionary = {}
## Queues one recorded op (main injects the sampler's queue).
var bag_op_sink := Callable()

var _tab := TAB_CHARACTER
var _sel_qi := -1
var _tracked_id := ""
var _panel: Panel2 = null
var _tab_btns: Array[Button] = []
var _char_scroll: ScrollContainer = null
var _errand_scroll: ScrollContainer = null
var _char_root: HBoxContainer = null
var _errand_root: HBoxContainer = null
var _confirm: ConfirmDialog = null
var _pending_drop_op := -1
var _accum := 0.0
var _sig := ""
var _cfg: Node = null


func _ready() -> void:
	visible = false
	_cfg = get_node_or_null("/root/Config")
	_tracked_id = String(_cfg_get("ui", "tracked_quest", ""))
	_tab = clampi(int(_cfg_get("ui", "menu_tab", TAB_CHARACTER)), 0, 1)
	_panel = Panel2.new()
	_panel.show_close = true
	_panel.close_requested.connect(func() -> void: visible = false)
	add_child(_panel)
	for label: String in ["character", "errands"]:
		var b := Button.new()
		b.text = label
		b.focus_mode = Control.FOCUS_NONE
		var ti := _tab_btns.size()
		b.pressed.connect(func() -> void: _set_tab(ti))
		add_child(b)
		_tab_btns.append(b)
	# Overflow SCROLLS (the sl-0119 errand law, generalized): at CORE-50
	# x2 on the 640x360 base the content minimums exceed the clamped
	# panel — containers never clip, so each tab rides a scroll.
	_char_scroll = ScrollContainer.new()
	_panel.content.add_child(_char_scroll)
	_char_root = HBoxContainer.new()
	_char_root.add_theme_constant_override("separation", 10)
	_char_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_char_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_char_scroll.add_child(_char_root)
	_errand_scroll = ScrollContainer.new()
	_panel.content.add_child(_errand_scroll)
	_errand_root = HBoxContainer.new()
	_errand_root.add_theme_constant_override("separation", 8)
	_errand_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_errand_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_errand_scroll.add_child(_errand_root)
	_confirm = ConfirmDialog.new()
	_confirm.confirmed.connect(_on_drop_confirmed)
	_confirm.canceled.connect(func() -> void: _pending_drop_op = -1)
	add_child(_confirm)
	_fit_to_screen()
	get_viewport().size_changed.connect(_fit_to_screen)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_inside_tree():
		_fit_to_screen()
		_sig = ""


func _cfg_get(section: String, key: String, default: Variant) -> Variant:
	if _cfg != null:
		return _cfg.get_setting(section, key, default)
	return default


func _cfg_set(section: String, key: String, value: Variant) -> void:
	if _cfg != null:
		_cfg.set_setting(section, key, value)


## SCREEN-anchored, never player-anchored (sl-0119). The tab strip
## rides the panel's top edge; the panel fills the rest.
func _fit_to_screen() -> void:
	var k: float = maxf(get_theme_default_base_scale(), 1.0)
	var vp: Vector2 = get_viewport_rect().size
	var w: float = minf(BASE_SIZE.x * k, vp.x - SCREEN_MARGIN * 2.0)
	var h: float = minf(BASE_SIZE.y * k, vp.y - SCREEN_MARGIN * 2.0)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -w * 0.5
	offset_right = w * 0.5
	offset_top = -h * 0.5
	offset_bottom = h * 0.5
	var tab_h := 14.0 * k
	if _panel != null:
		_panel.position = Vector2(0.0, tab_h - 2.0 * k)
		_panel.size = Vector2(w, h - tab_h + 2.0 * k)
	var tx := 8.0 * k
	for b: Button in _tab_btns:
		b.position = Vector2(tx, 0.0)
		b.size = Vector2(b.get_combined_minimum_size().x, tab_h)
		tx += b.size.x + 2.0 * k


func toggle() -> void:
	visible = not visible
	if visible:
		_set_tab(clampi(int(_cfg_get("ui", "menu_tab", _tab)), 0, 1))
		_sig = ""
		_refresh()


## The quest_log deep-link (L [T]): closed -> open on the log tab;
## open elsewhere -> switch; already open on the log -> close (toggle
## feel, one key one meaning).
func open_tab(tab: int) -> void:
	if visible and _tab == tab:
		visible = false
		return
	visible = true
	_set_tab(tab)
	_sig = ""
	_refresh()


func _set_tab(tab: int) -> void:
	_tab = clampi(tab, 0, 1)
	_cfg_set("ui", "menu_tab", _tab)
	_sig = ""
	_refresh()


## Esc-first support (sl-0145): the drop confirm closes before the
## menu itself; false = nothing was open here.
func close_topmost() -> bool:
	if not visible:
		return false
	if _confirm != null and _confirm.visible:
		_confirm.visible = false
		_pending_drop_op = -1
		return true
	visible = false
	return true


## Main polls this: gameplay input suppresses while the mouse rides
## the open menu, and ALWAYS while a confirm decision is up (a modal
## click must never also fire the weapon).
func wants_suppress() -> bool:
	if not visible:
		return false
	if _confirm != null and _confirm.visible:
		return true
	return get_global_rect().has_point(get_global_mouse_position())


func _process(delta: float) -> void:
	if not visible:
		return
	_accum += delta
	if _accum >= 0.25:
		_accum = 0.0
		_refresh()


func _refresh() -> void:
	if world == null or world.players.is_empty() or _panel == null:
		return
	for i in _tab_btns.size():
		var sel := i == _tab
		var box := _tab_box(sel)
		_tab_btns[i].add_theme_stylebox_override("normal", box)
		_tab_btns[i].add_theme_stylebox_override("hover", box)
		_tab_btns[i].add_theme_stylebox_override("pressed", box)
		_tab_btns[i].add_theme_color_override(
			"font_color", MenuPalette.TEXT_BRIGHT if sel else MenuPalette.TEXT_DIM
		)
		_tab_btns[i].add_theme_color_override("font_hover_color", MenuPalette.TEXT_BRIGHT)
		_tab_btns[i].add_theme_color_override("font_pressed_color", MenuPalette.TEXT_BRIGHT)
	_char_scroll.visible = _tab == TAB_CHARACTER
	_errand_scroll.visible = _tab == TAB_ERRANDS
	var cards := quest_cards(world)
	# Selection normalizes BEFORE the signature (a mid-build mutation
	# would flip the sig every pass and ghost-rebuild forever).
	if _tab == TAB_ERRANDS:
		var valid := false
		for cd: Dictionary in (cards.carried as Array) + (cards.available as Array):
			if int(cd.qi) == _sel_qi:
				valid = true
		if not valid:
			_sel_qi = -1
			if not (cards.carried as Array).is_empty():
				_sel_qi = int(((cards.carried as Array)[0] as Dictionary).qi)
			elif not (cards.available as Array).is_empty():
				_sel_qi = int(((cards.available as Array)[0] as Dictionary).qi)
	var sig := (
		str(sheet_rows(world, character))
		+ "|"
		+ str(equipment_rows(world))
		+ "|"
		+ str(bag_rows(world))
		+ "|"
		+ str(cards)
		+ "|%d|%d|%s" % [_tab, _sel_qi, _tracked_id]
	)
	if sig == _sig:
		return
	_sig = sig
	if _tab == TAB_CHARACTER:
		_build_character_tab()
	else:
		_build_errands_tab(cards)


## ---- tab CHARACTER (c_menu_v2).


func _build_character_tab() -> void:
	for c in _char_root.get_children():
		(c as CanvasItem).visible = false
		c.queue_free()
	var p: RefCounted = world.players[0]
	var k: float = maxf(get_theme_default_base_scale(), 1.0)
	var rows := sheet_rows(world, character)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(175.0 * k, 0.0)
	left.add_theme_constant_override("separation", 3)
	_char_root.add_child(left)
	# Portrait row: class emblem in a slot + name / class-lv / xp.
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 6)
	left.add_child(prow)
	var portrait := ItemSlot.new()
	portrait.cell_px = 36.0
	if p.class_id >= 0:
		portrait.icon_tex = IconAtlas.icon(ItemIcons.class_emblem(p.class_id))
	prow.add_child(portrait)
	var pcol := VBoxContainer.new()
	pcol.add_theme_constant_override("separation", 1)
	prow.add_child(pcol)
	pcol.add_child(_label(String(character.get("name", "the wildshot")), MenuPalette.TEXT_BRIGHT))
	pcol.add_child(_label(_row_value(rows, "class"), MenuPalette.TEXT_DIM))
	var xp_line := _row_value(rows, "xp")
	if not xp_line.is_empty():
		pcol.add_child(_label("xp " + xp_line, MenuPalette.TEXT_DIM))
	# Bigbars: hp + mana with exact values.
	left.add_child(
		_bar_row(
			"hp", float(p.hp) / maxf(float(p.max_hp), 1.0), "%d/%d" % [p.hp, p.max_hp], true, k
		)
	)
	left.add_child(
		_bar_row(
			"mana",
			float(p.mana) / maxf(float(p.max_mana), 1.0),
			"%d/%d" % [p.mana, p.max_mana],
			false,
			k
		)
	)
	left.add_child(_rule("— stats —"))
	var chips := GridContainer.new()
	chips.columns = 2
	chips.add_theme_constant_override("h_separation", 4)
	chips.add_theme_constant_override("v_separation", 3)
	left.add_child(chips)
	var chip_rows: Array = [
		["speed", _row_value(rows, "speed")],
		["armor", _row_value(rows, "armor")],
		["dmg", _row_value(rows, "dmg mod")],
		["atk", _row_value(rows, "atk spd")],
		["range", _row_value(rows, "range")],
		["gold", _row_value(rows, "gold")],
	]
	if p.class_id >= 0:
		chip_rows.append(["bag", "%d/%d" % [BagStep.bag_count(p), BagStep.BAG_CAP]])
	var sh := _row_value(rows, "starhook")
	if not sh.is_empty():
		chip_rows.append(["starhook", sh.get_slice("  ", 0)])
	for cr: Array in chip_rows:
		chips.add_child(_chip(String(cr[0]), String(cr[1]), k))
	# RIGHT: dollslots + the bag grid.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 3)
	_char_root.add_child(right)
	right.add_child(_rule("— equipped —"))
	var p_class := int(p.class_id)
	for row: Dictionary in equipment_rows(world):
		right.add_child(_dollslot(row, p_class, k))
	var bag_head := "— bag — (—)"
	if p.class_id >= 0:
		bag_head = "— bag %d/%d —" % [BagStep.bag_count(p), BagStep.BAG_CAP]
	right.add_child(_rule(bag_head))
	var grid := GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	right.add_child(grid)
	var brows := bag_rows(world)
	for slot in BagStep.BAG_CAP:
		var cell := ItemSlot.new()
		if slot < brows.size():
			var br: Dictionary = brows[slot]
			var it: Dictionary = BagStep.bag_item(p, slot)
			cell.icon_tex = IconAtlas.icon(ItemIcons.icon_id(world, it, p_class))
			cell.tooltip_text = String(br.tip)
			var equip_op := int(br.equip_op)
			var drop_op := int(br.drop_op)
			var line := String(br.line)
			cell.slot_clicked.connect(_on_bag_slot.bind(equip_op, drop_op, line))
		grid.add_child(cell)
	right.add_child(_label("click equips · right-click drops", MenuPalette.TEXT_DIM))
	if p.class_id >= 0:
		# THE CONSTELLATION rides directly under the bag (sl-0181:
		# "fish should be added to inventory" — the catch is VISIBLE
		# where the inventory lives; RENAMED from "creel" by the
		# sl-0182 naming ruling: starhook names ride the COSMIC rail,
		# fishing-metaphor words fail it — your caught star-fish ARE
		# a constellation). The species counts stay THE one pricing
		# truth; fish occupy zero bag capacity by construction.
		var crows := creel_rows(world)
		right.add_child(_rule("— constellation — (caught fish · priced at the tackle keeper)"))
		if crows.is_empty():
			right.add_child(_label("(cast a rift line)", MenuPalette.TEXT_DIM))
		else:
			var cgrid := GridContainer.new()
			cgrid.columns = 10
			cgrid.add_theme_constant_override("h_separation", 2)
			cgrid.add_theme_constant_override("v_separation", 2)
			right.add_child(cgrid)
			for crow: Dictionary in crows:
				var ccell := ItemSlot.new()
				ccell.icon_tex = IconAtlas.icon(String(crow.icon_id))
				ccell.badge = "x%d" % int(crow.count)
				ccell.tooltip_text = String(crow.tip)
				cgrid.add_child(ccell)
	# THE RIFTER PANEL (sl-0181): rod/chest/helm doll slots over the
	# LIVE sim gear (SERIAL 26 fields); a click wears the NEXT owned
	# piece via the recorded equip op (legal anywhere since the
	# sl-0181 re-pin — the tackle keeper stays the buy surface). The
	# rod row is informational: R swaps rods IN the rift.
	if p.class_id >= 0:
		right.add_child(_rule("— rifter —"))
		for rrow: Dictionary in rifter_rows(world, character):
			var rbox := HBoxContainer.new()
			rbox.add_theme_constant_override("separation", 6)
			var rslot := ItemSlot.new()
			rslot.cell_px = 28.0
			rslot.icon_tex = IconAtlas.icon(String(rrow.icon_id))
			rslot.tooltip_text = String(rrow.tip)
			rslot.selected = String(rrow.line) != "—"
			var rop := int(rrow.op)
			if rop > 0:
				rslot.slot_clicked.connect(
					func(button_index: int) -> void:
						if button_index == MOUSE_BUTTON_LEFT:
							_queue_op(rop)
				)
			rbox.add_child(rslot)
			var rcol := VBoxContainer.new()
			rcol.add_theme_constant_override("separation", 1)
			rcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rbox.add_child(rcol)
			rcol.add_child(_label(String(rrow.label), MenuPalette.TEXT_DIM))
			var rline := String(rrow.line)
			if rline == "—":
				rcol.add_child(_label(String(rrow.empty_note), MenuPalette.TEXT_DIM))
			else:
				rcol.add_child(_label(rline.get_slice(" — ", 0), MenuPalette.TEXT_BRIGHT))
				if rline.contains(" — "):
					rcol.add_child(_label(rline.get_slice(" — ", 1), MenuPalette.TEXT_BASE))
			right.add_child(rbox)


func _on_bag_slot(button_index: int, equip_op: int, drop_op: int, line: String) -> void:
	if button_index == MOUSE_BUTTON_LEFT:
		_queue_op(equip_op)
	elif button_index == MOUSE_BUTTON_RIGHT:
		_pending_drop_op = drop_op
		_confirm.ask("drop this on the ground?\n%s" % line, "drop it", "keep it")


func _on_drop_confirmed() -> void:
	if _pending_drop_op < 0:
		return
	_queue_op(_pending_drop_op)
	_pending_drop_op = -1
	toast_requested.emit("dropped — [F] picks it back up")


func _dollslot(row: Dictionary, p_class: int, k: float) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var slot := ItemSlot.new()
	slot.cell_px = 28.0
	var line := String(row.line)
	var op := int(row.op)
	if line != "—":
		var it := _worn_item_for(String(row.label))
		if not it.is_empty():
			slot.icon_tex = IconAtlas.icon(ItemIcons.icon_id(world, it, p_class))
		slot.selected = true
	slot.tooltip_text = String(row.tip)
	if op > 0:
		slot.slot_clicked.connect(
			func(button_index: int) -> void:
				if button_index == MOUSE_BUTTON_LEFT:
					_queue_op(op)
		)
	box.add_child(slot)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(col)
	col.add_child(_label(String(row.label), MenuPalette.TEXT_DIM))
	if line == "—":
		col.add_child(
			_label(
				(
					"equip one from the bag"
					if String(row.label) == "ring"
					else "equip some from the bag"
				),
				MenuPalette.TEXT_DIM
			)
		)
	else:
		var name_part := line.get_slice(" — ", 0)
		col.add_child(_label(name_part, MenuPalette.TEXT_BRIGHT))
		if line.contains(" — "):
			col.add_child(_label(line.get_slice(" — ", 1), MenuPalette.TEXT_BASE))
	return box


## The worn item triple for a dollslot label (icon lookup only — the
## LINE/tip stay the pure-model grammar).
func _worn_item_for(label: String) -> Dictionary:
	var p: RefCounted = world.players[0]
	match label:
		"weapon":
			var tier := 1
			if p.weapon_tiers.size() > 0:
				tier = int(p.weapon_tiers[p.equipped_weapon])
			return {"kind": DropKinds.WEAPON, "a": p.equipped_weapon, "b": tier}
		"armor":
			if p.armor_item_index >= 0:
				var ui := _unique_for_items(world, p.armor_item_index)
				if ui >= 0:
					return {"kind": DropKinds.UNIQUE, "a": ui, "b": 0}
			if p.armor_tier > 0:
				return {"kind": DropKinds.ARMOR, "a": p.armor_tier, "b": 0}
		"ring":
			if p.ring_index >= 0:
				return {"kind": DropKinds.RING, "a": p.ring_index, "b": 0}
	return {}


## ---- tab QUEST LOG (errands_v2: cards + parchment detail).


func _build_errands_tab(cards: Dictionary) -> void:
	for c in _errand_root.get_children():
		(c as CanvasItem).visible = false
		c.queue_free()
	var carried: Array = cards.carried
	var avail: Array = cards.available
	var k: float = maxf(get_theme_default_base_scale(), 1.0)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(178.0 * k, 0.0)
	left.add_theme_constant_override("separation", 3)
	_errand_root.add_child(left)
	left.add_child(_rule("— carried %d/%d —" % [int(cards.carried_count), 5]))
	for cd: Dictionary in carried:
		left.add_child(_quest_card(cd, false, k))
	left.add_child(_rule("— givers have work —"))
	if avail.is_empty():
		left.add_child(_label("(no work waiting)", MenuPalette.TEXT_DIM))
	for cd: Dictionary in avail:
		left.add_child(_quest_card(cd, true, k))
	var pad := Control.new()
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(pad)
	left.add_child(
		_label(
			"hands: %d/5 · done: %d" % [int(cards.carried_count), int(cards.done)],
			MenuPalette.TEXT_DIM
		)
	)
	# RIGHT: the parchment detail pane.
	var parch := PanelContainer.new()
	parch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = MenuPalette.PARCHMENT
	sb.border_color = MenuPalette.PARCHMENT_EDGE
	sb.set_border_width_all(int(1.0 * k))
	sb.set_content_margin_all(8.0 * k)
	parch.add_theme_stylebox_override("panel", sb)
	_errand_root.add_child(parch)
	var det := VBoxContainer.new()
	det.add_theme_constant_override("separation", 4)
	parch.add_child(det)
	var d := quest_detail(world, _sel_qi)
	if d.is_empty():
		det.add_child(_label("select an errand", MenuPalette.PARCHMENT_DIM))
		return
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 4)
	det.add_child(head)
	var qicon := TextureRect.new()
	qicon.texture = IconAtlas.icon("access.quest.letter" if bool(d.carried) else "quest.available")
	qicon.custom_minimum_size = Vector2(16.0, 16.0) * k
	qicon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(qicon)
	head.add_child(_label(String(d.title), MenuPalette.PARCHMENT_INK))
	var hpad := Control.new()
	hpad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hpad)
	head.add_child(_label("[%s]" % String(d.reason), MenuPalette.PARCHMENT_DIM))
	var body := _label(String(d.text), MenuPalette.PARCHMENT_INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	det.add_child(body)
	var dpad := Control.new()
	dpad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	det.add_child(dpad)
	det.add_child(_label(String(d.objective), MenuPalette.PARCHMENT_DIM))
	var bar := ColorRect.new()
	bar.color = MenuPalette.PARCHMENT_EDGE
	bar.custom_minimum_size = Vector2(0.0, 6.0 * k)
	det.add_child(bar)
	var fill := ColorRect.new()
	fill.color = MenuPalette.GOLD_DIM
	var frac: float = 0.0
	if int(d.count) > 0:
		frac = clampf(float(int(d.prog)) / float(int(d.count)), 0.0, 1.0)
	fill.anchor_right = frac
	fill.anchor_bottom = 1.0
	bar.add_child(fill)
	det.add_child(
		_label(
			"reward  %d gold · %d xp on turn-in" % [int(d.reward_gold), int(d.reward_xp)],
			MenuPalette.GOLD_DIM
		)
	)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 6)
	det.add_child(btns)
	if bool(d.carried) and not bool(d.done):
		var tracked := _tracked_id == String(d.id)
		var tbtn := Button.new()
		tbtn.text = "★ tracked" if tracked else "☆ track"
		tbtn.pressed.connect(_on_track.bind(String(d.id)))
		btns.add_child(tbtn)
		var abtn := Button.new()
		abtn.text = "abandon"
		var qi := int(d.qi)
		abtn.pressed.connect(_on_abandon.bind(qi, String(d.id)))
		btns.add_child(abtn)
	elif not bool(d.carried):
		det.add_child(_label("speak to the giver to accept — [F]", MenuPalette.PARCHMENT_DIM))


func _quest_card(cd: Dictionary, available: bool, k: float) -> Control:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	var qi := int(cd.qi)
	var star := "★ " if not available and _tracked_id == String(cd.id) else ""
	if available:
		b.text = "%s   new" % String(cd.title)
	else:
		b.text = "%s%s   %d/%d" % [star, String(cd.title), int(cd.prog), int(cd.count)]
	if qi == _sel_qi:
		b.add_theme_color_override("font_color", MenuPalette.GOLD_BRIGHT)
	b.custom_minimum_size = Vector2(0.0, 18.0 * k)
	b.pressed.connect(
		func() -> void:
			_sel_qi = qi
			_sig = ""
			_refresh()
	)
	return b


func _on_track(id: String) -> void:
	_tracked_id = "" if _tracked_id == id else id
	_cfg_set("ui", "tracked_quest", _tracked_id)
	_sig = ""
	_refresh()


func _on_abandon(qi: int, id: String) -> void:
	_queue_op(BagStep.OP_ABANDON_BASE + qi)
	if _tracked_id == id:
		_tracked_id = ""
		_cfg_set("ui", "tracked_quest", "")
	_sig = ""


## ---- small builders.


func _label(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	return l


func _rule(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", MenuPalette.TEXT_DIM)
	return l


func _chip(label: String, value: String, k: float) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = MenuPalette.INSET_BG
	sb.border_color = MenuPalette.SLOT_EDGE
	sb.set_border_width_all(int(1.0 * k))
	sb.content_margin_left = 4.0 * k
	sb.content_margin_right = 4.0 * k
	sb.content_margin_top = 2.0 * k
	sb.content_margin_bottom = 2.0 * k
	pc.add_theme_stylebox_override("panel", sb)
	pc.custom_minimum_size = Vector2(84.0 * k, 0.0)
	var row := HBoxContainer.new()
	pc.add_child(row)
	var l := _label(label, MenuPalette.TEXT_DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(_label(value, MenuPalette.TEXT_BRIGHT))
	return pc


func _bar_row(label: String, frac: float, value: String, is_hp: bool, k: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var l := _label(label, MenuPalette.TEXT_DIM)
	l.custom_minimum_size = Vector2(28.0 * k, 0.0)
	row.add_child(l)
	var bar := StatBar.new()
	bar.fill_tex = load("res://uikit/bar_fill_hp.png" if is_hp else "res://uikit/bar_fill_mana.png")
	bar.frame_box = _bar_frame_box()
	bar.value = frac
	bar.custom_minimum_size = Vector2(96.0 * k, 8.0 * k)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	row.add_child(_label(value, MenuPalette.TEXT_BASE))
	return row


static var _bar_box: StyleBoxTexture = null


static func _bar_frame_box() -> StyleBoxTexture:
	if _bar_box == null:
		_bar_box = StyleBoxTexture.new()
		_bar_box.texture = load("res://uikit/bar_frame.png")
		_bar_box.texture_margin_left = 2.0
		_bar_box.texture_margin_right = 2.0
		_bar_box.texture_margin_top = 2.0
		_bar_box.texture_margin_bottom = 2.0
	return _bar_box


static func _row_value(rows: Array, label: String) -> String:
	for r: Array in rows:
		if String(r[0]) == label:
			return String(r[1])
	return ""


func _queue_op(op: int) -> void:
	if bag_op_sink.is_valid():
		bag_op_sink.call(op)


## Tab-strip styleboxes (workbench look: selected merges into the
## panel body, unselected sits darker).
static func _tab_box(sel: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = MenuPalette.TAB_SEL_TOP if sel else MenuPalette.TAB_BG
	sb.border_color = MenuPalette.EDGE_DARK
	sb.set_border_width_all(1)
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	return sb


## ---- PURE MODELS (the parity test pins these against live state).


## [label, value] rows over player 0 + the profile. Every value is a
## direct read of sim state or the profile — zero re-derivation.
static func sheet_rows(world: RefCounted, character: Dictionary) -> Array:
	var p: RefCounted = world.players[0]
	var rows: Array = []
	if p.class_id >= 0 and p.class_id < StatFrame.CLASS_IDS.size():
		rows.append(["class", "%s  lv %d" % [String(StatFrame.CLASS_IDS[p.class_id]), p.level]])
		var xp_next: int = StatFrame.xp_to_next(world, p.level)
		rows.append(["xp", "%d / %d" % [p.xp, xp_next] if xp_next > 0 else "MAX"])
	else:
		rows.append(["class", "—  lv %d" % p.level])
	rows.append(["hp", "%d / %d" % [p.hp, p.max_hp]])
	rows.append(["mana", "%d / %d" % [p.mana, p.max_mana]])
	rows.append(["speed", "%.2f t/s" % p.move_speed])
	rows.append(["armor", str(p.armor)])
	rows.append(["dmg mod", "%+d" % p.damage_mod])
	rows.append(["atk spd", str(p.attack_speed_stat)])
	rows.append(["range", str(p.range_stat)])
	var wline := (
		ItemText
		. drop_line(
			world,
			{
				"kind": DropKinds.WEAPON,
				"a": p.equipped_weapon,
				"b": p.weapon_tiers[p.equipped_weapon] if p.weapon_tiers.size() > 0 else 1,
			}
		)
	)
	rows.append(["weapon", wline])
	if p.armor_item_index >= 0:
		var items: Array = world.stat_frame.get("items", [])
		if p.armor_item_index < items.size():
			rows.append(["worn", String(items[p.armor_item_index].get("name", "unique armor"))])
	elif p.armor_tier > 0:
		rows.append(
			[
				"worn",
				ItemText.drop_line(world, {"kind": DropKinds.ARMOR, "a": p.armor_tier, "b": 0})
			]
		)
	else:
		rows.append(["worn", "—"])
	if p.ring_index >= 0:
		rows.append(
			["ring", ItemText.drop_line(world, {"kind": DropKinds.RING, "a": p.ring_index, "b": 0})]
		)
	else:
		rows.append(["ring", "—"])
	rows.append(["gold", str(p.gold)])
	if not character.is_empty():
		(
			rows
			. append(
				[
					"starhook",
					(
						"lv %d  rod %s  catches %d%s%s"
						% [
							int(character.get("starhook_level", 1)),
							String(character.get("starhook_rod", "rod_cane")).trim_prefix("rod_"),
							int(character.get("starhook_catches", 0)),
							(
								"  ✦starlit"
								if (int(character.get("starhook_skins", 0)) & 1) != 0
								else ""
							),
							# sl-0177: the worn rift gear, BY ID (empty
							# slots stay silent — the row reads clean
							# pre-gear).
							(
								""
								if (
									String(character.get("starhook_chest", "")).is_empty()
									and String(character.get("starhook_helm", "")).is_empty()
								)
								else (
									"  gear %s/%s"
									% [
										(
											String(character.get("starhook_chest", ""))
											if not (
												String(character.get("starhook_chest", ""))
												. is_empty()
											)
											else "—"
										),
										(
											String(character.get("starhook_helm", ""))
											if not (
												String(character.get("starhook_helm", ""))
												. is_empty()
											)
											else "—"
										),
									]
								)
							),
						]
					),
				]
			)
		)
	return rows


## One line per TAKEN quest ("[reason] text (n/m)" or "done"), then
## the capacity line. Direct reads of sim state.
static func quest_rows(world: RefCounted) -> Array:
	var p: RefCounted = world.players[0]
	var rows: Array = []
	var carried := 0
	var done := 0
	for qi in world.quest_defs.size():
		var taken: bool = (p.quests_taken_mask & (1 << qi)) != 0
		var is_done: bool = (p.quests_done_mask & (1 << qi)) != 0
		if is_done:
			done += 1
		if not taken or is_done:
			continue
		carried += 1
		var q: Resource = world.quest_defs[qi]
		var prog: int = p.quest_progress_arr[qi] if qi < p.quest_progress_arr.size() else 0
		rows.append("[%s] %s (%d/%d)" % [String(q.reason), String(q.text), prog, int(q.count)])
	if rows.is_empty():
		rows.append("no errands — givers have work ([F] to talk)")
	rows.append("hands: %d/5 · done: %d" % [carried, done])
	return rows


## THE LOG MODEL (errands_v2): carried cards + givers-have-work cards
## + counts. Direct reads; selection/tracked stay view state.
static func quest_cards(world: RefCounted) -> Dictionary:
	var p: RefCounted = world.players[0]
	var carried: Array = []
	var available: Array = []
	var done := 0
	for qi in world.quest_defs.size():
		var q: Resource = world.quest_defs[qi]
		var taken: bool = (p.quests_taken_mask & (1 << qi)) != 0
		var is_done: bool = (p.quests_done_mask & (1 << qi)) != 0
		if is_done:
			done += 1
			continue
		var title := QuestTracker.short_name(String(q.id))
		if taken:
			var prog: int = p.quest_progress_arr[qi] if qi < p.quest_progress_arr.size() else 0
			(
				carried
				. append(
					{
						"qi": qi,
						"id": String(q.id),
						"title": title,
						"prog": prog,
						"count": int(q.count),
					}
				)
			)
		else:
			available.append({"qi": qi, "id": String(q.id), "title": title})
	return {
		"carried": carried,
		"available": available,
		"carried_count": carried.size(),
		"done": done,
	}


## THE DETAIL MODEL (proper info, sl-0143/0144): everything the
## parchment pane shows for one quest. Empty dict = no such quest.
## Objective wording is generic per kind [T — designer voice pending].
static func quest_detail(world: RefCounted, qi: int) -> Dictionary:
	if qi < 0 or qi >= world.quest_defs.size():
		return {}
	var p: RefCounted = world.players[0]
	var q: Resource = world.quest_defs[qi]
	var taken: bool = (p.quests_taken_mask & (1 << qi)) != 0
	var is_done: bool = (p.quests_done_mask & (1 << qi)) != 0
	var prog: int = p.quest_progress_arr[qi] if qi < p.quest_progress_arr.size() else 0
	var objective := ""
	match int(q.kind):
		QuestDef.Kind.KILL:
			objective = "slay them — %d/%d" % [prog, int(q.count)]
		QuestDef.Kind.VISIT:
			objective = "see the place — %d/%d" % [prog, int(q.count)]
		QuestDef.Kind.COLLECT:
			objective = "gather anything — %d/%d" % [prog, int(q.count)]
	return {
		"qi": qi,
		"id": String(q.id),
		"title": QuestTracker.short_name(String(q.id)),
		"reason": String(q.reason),
		"text": String(q.text),
		"carried": taken,
		"done": is_done,
		"prog": prog,
		"count": int(q.count),
		"objective": objective,
		"reward_gold": int(q.reward_gold),
		"reward_xp": int(q.reward_xp),
	}


## WORN slots (sl-0128 pane): {label, line, tip, op} — op = the
## recorded de-equip code (0 = not actionable: the weapon is
## replace-only [T: bare hands aren't a build], empty slots inert).
## Lines/tips speak the one grammar — tooltip parity is test-pinned.
static func equipment_rows(world: RefCounted) -> Array:
	var p: RefCounted = world.players[0]
	var rows: Array = []
	if p.class_id < 0:
		return rows
	var wline := (
		ItemText
		. drop_line(
			world,
			{
				"kind": DropKinds.WEAPON,
				"a": p.equipped_weapon,
				"b": p.weapon_tiers[p.equipped_weapon] if p.weapon_tiers.size() > 0 else 1,
			}
		)
	)
	(
		rows
		. append(
			{
				"label": "weapon",
				"line": wline,
				"tip": wline + "\n(replace-only: equip another from the bag)",
				"op": 0,
			}
		)
	)
	if p.armor_item_index >= 0:
		var items: Array = world.stat_frame.get("items", [])
		var uline := ItemText.drop_line(
			world,
			{"kind": DropKinds.UNIQUE, "a": _unique_for_items(world, p.armor_item_index), "b": 0}
		)
		if p.armor_item_index < items.size():
			(
				rows
				. append(
					{
						"label": "armor",
						"line": String(items[p.armor_item_index].get("name", "unique armor")),
						"tip": uline + "\n(click to de-equip into the bag)",
						"op": BagStep.OP_DEEQUIP_ARMOR,
					}
				)
			)
	elif p.armor_tier > 0:
		var aline := ItemText.drop_line(world, {"kind": DropKinds.ARMOR, "a": p.armor_tier, "b": 0})
		(
			rows
			. append(
				{
					"label": "armor",
					"line": aline,
					"tip": aline + "\n(click to de-equip into the bag)",
					"op": BagStep.OP_DEEQUIP_ARMOR,
				}
			)
		)
	else:
		rows.append({"label": "armor", "line": "—", "tip": "no armor worn", "op": 0})
	if p.ring_index >= 0:
		var rline := ItemText.drop_line(world, {"kind": DropKinds.RING, "a": p.ring_index, "b": 0})
		(
			rows
			. append(
				{
					"label": "ring",
					"line": rline,
					"tip": rline + "\n(click to de-equip into the bag)",
					"op": BagStep.OP_DEEQUIP_RING,
				}
			)
		)
	else:
		rows.append({"label": "ring", "line": "—", "tip": "no ring worn", "op": 0})
	return rows


## BAG rows: {line, tip, equip_op, drop_op} — line/tip = the one
## grammar (tooltip==drop_line, test-pinned); ops = the recorded
## codes for this slot.
static func bag_rows(world: RefCounted) -> Array:
	var p: RefCounted = world.players[0]
	var rows: Array = []
	if p.class_id < 0:
		return rows
	for slot in BagStep.bag_count(p):
		var it: Dictionary = BagStep.bag_item(p, slot)
		var line := ItemText.drop_line(world, it)
		(
			rows
			. append(
				{
					"line": line,
					"tip": line + "\n(click to equip · right-click to drop)",
					"equip_op": BagStep.OP_EQUIP_BASE + slot,
					"drop_op": BagStep.OP_DROP_BASE + slot,
				}
			)
		)
	return rows


## THE CREEL (sl-0181): per-species fish stacks composed from the
## IN-SIM wallet (p.fish, SERIAL 26) — the ONE truth that prices the
## tackle shop; zero bag-capacity interaction by construction. Only
## nonzero species render; glyphs = the icon pack's fish set by
## species index (placeholder-sanctioned).
static func creel_rows(world_ref: RefCounted) -> Array:
	var p: RefCounted = world_ref.players[0]
	var rows: Array = []
	if p.class_id < 0:
		return rows
	var frame: Dictionary = world_ref.stat_frame
	for si in p.fish.size():
		if p.fish[si] <= 0:
			continue
		var nm := TackleCatalog.species_name(frame, si)
		(
			rows
			. append(
				{
					"species_index": si,
					"count": p.fish[si],
					"name": nm,
					"icon_id": "collect.fish.f%02d" % mini(si + 1, 18),
					"tip":
					"%d %s\n(species-currency — spend it at the tackle keeper)" % [p.fish[si], nm],
				}
			)
		)
	return rows


## THE RIFTER PANEL rows (sl-0181): rod (informational — R swaps in
## the rift; the profile's choice shows) + chest/helm (live sim
## equips; op = wear the NEXT owned piece of the slot via the
## recorded tackle-equip op, 0 when nothing else is owned).
static func rifter_rows(world_ref: RefCounted, character_d: Dictionary) -> Array:
	var p: RefCounted = world_ref.players[0]
	var rows: Array = []
	if p.class_id < 0:
		return rows
	var frame: Dictionary = world_ref.stat_frame
	var rod_id := String(character_d.get("starhook_rod", "rod_cane"))
	var rod_line := "—"
	for rod: Dictionary in TackleCatalog.rods(frame):
		if String(rod.get("id", "")) == rod_id:
			var res: Resource = load("res://data/weapons/%s.tres" % rod_id)
			rod_line = ItemText.rod_line(rod, res)
	(
		rows
		. append(
			{
				"label": "rod",
				"line": rod_line,
				"empty_note": "the cane rod waits at the shore",
				"icon_id": "map.fishing",
				"op": 0,
				"tip": rod_line + "\n(R swaps rods IN the rift; the shop sells more)",
			}
		)
	)
	var ilist := TackleCatalog.items(frame)
	for slot_def: Array in [["chest", p.tackle_chest], ["helm", p.tackle_helm]]:
		var slot_name := String(slot_def[0])
		var worn := int(slot_def[1])
		var owned: Array[int] = []
		for ii in ilist.size():
			if (
				(p.tackle_owned_mask & (1 << ii)) != 0
				and String((ilist[ii] as Dictionary).get("slot", "")) == slot_name
			):
				owned.append(ii)
		var line := "—"
		var tier := 1
		if worn >= 0 and worn < ilist.size():
			line = ItemText.tackle_item_line(ilist[worn])
			tier = int((ilist[worn] as Dictionary).get("tier", 1))
		var op := 0
		if owned.size() >= 1:
			var pos := owned.find(worn)
			var next_i: int = owned[(pos + 1) % owned.size()]
			if next_i != worn:
				op = BagStep.OP_TACKLE_EQUIP_BASE + next_i
		var glyph := (
			"item.armor.sword.bulwark.t%d" % clampi(tier, 1, 5)
			if slot_name == "chest"
			else "item.armor.sword.skirmish.t%d" % clampi(tier, 1, 5)
		)
		var tip := line
		if op > 0:
			tip += "\n(click wears the next owned piece)"
		elif line == "—":
			tip = "nothing owned — the tackle keeper sells %s pieces" % slot_name
		(
			rows
			. append(
				{
					"label": "rift %s" % slot_name,
					"line": line,
					"empty_note": "buy one at the tackle keeper",
					"icon_id": glyph,
					"op": op,
					"tip": tip,
				}
			)
		)
	return rows


static func _unique_for_items(world: RefCounted, items_index: int) -> int:
	var items: Array = world.stat_frame.get("items", [])
	if items_index < 0 or items_index >= items.size():
		return -1
	var iid := String(items[items_index].get("id", ""))
	for ui in world.unique_defs.size():
		if String(world.unique_defs[ui].items_id) == iid:
			return ui
	return -1
