extends PanelContainer
## THE CHARACTER SHEET + QUEST LOG + EQUIPMENT PANE (sl-0106 +
## sl-0112's log; seam B; the sl-0116/0128 bag era). Stats stay
## READ-ONLY pure-model rows (screen==recompute parity EXACT by
## construction, test-pinned); the EQUIPMENT PANE is the one
## interactive region (sl-0128 sanction): worn gear by slot + the
## bag list, hover tooltips in the one grammar (every number
## visible — tooltip==drop_line, test-pinned), click to equip/
## de-equip, right-click to drop. Ops ride the RECORDED bag_op byte
## (bag_op_sink -> sampler queue -> bag_step) so the sim mutation is
## replay-honest; this panel never touches sim state directly.
## Toggled by the char_sheet action (C [T]); never pauses. While the
## mouse is OVER the open panel, main suppresses gameplay input
## (wants_suppress — a pane click must not also fire the weapon).

const ItemText := preload("res://game/views/item_text.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const DropKinds := preload("res://sim/drop_kinds.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")

## Fixed screen placement [T: centered] — sl-0119. The panel sizes
## from the ui-scale theme and clamps inside the viewport; errand
## overflow SCROLLS in the label [T] (fit_content grew the panel past
## the screen — the offscreen bug's second half). Widened for the
## equipment pane (sl-0128).
const BASE_SIZE := Vector2(500.0, 336.0)
const SCREEN_MARGIN := 4.0

var world: RefCounted = null
## The persistent profile dict (starhook lane lives there).
var character: Dictionary = {}
## Queues one recorded bag op (main injects the sampler's queue).
var bag_op_sink := Callable()

var _label: RichTextLabel = null
var _pane: VBoxContainer = null
var _accum := 0.0
var _pane_sig := ""


func _ready() -> void:
	visible = false
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 8)
	add_child(split)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = false
	_label.fit_content = false
	_label.scroll_active = true
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.size_flags_stretch_ratio = 1.15
	split.add_child(_label)
	var pane_scroll := ScrollContainer.new()
	pane_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pane_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(pane_scroll)
	_pane = VBoxContainer.new()
	_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pane.add_theme_constant_override("separation", 2)
	pane_scroll.add_child(_pane)
	_fit_to_screen()
	get_viewport().size_changed.connect(_fit_to_screen)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_inside_tree():
		_fit_to_screen()


## SCREEN-anchored, never player-anchored (sl-0119): explicit center
## anchors + offsets from the computed size. The old zero-size
## PRESET_CENTER call in _ready put the panel's TOP-LEFT at screen
## center — the camera keeps the player there, so it read as
## player-anchored and grew past the viewport bottom-right.
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


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()


## Main polls this: gameplay input suppresses while the mouse rides
## the open panel (a pane click must never also fire the weapon).
func wants_suppress() -> bool:
	return visible and get_global_rect().has_point(get_global_mouse_position())


func _process(delta: float) -> void:
	if not visible:
		return
	_accum += delta
	if _accum >= 0.25:
		_accum = 0.0
		_refresh()


func _refresh() -> void:
	if world == null or world.players.is_empty():
		return
	var lines: Array[String] = []
	for row: Array in sheet_rows(world, character):
		lines.append("%s  %s" % [String(row[0]).rpad(10), String(row[1])])
	lines.append("")
	lines.append("— errands —")
	for ql: String in quest_rows(world):
		lines.append(ql)
	_label.text = "\n".join(lines)
	_rebuild_pane()


## The pane rebuilds only when its model changes (tooltips survive
## hover; no per-frame widget churn).
func _rebuild_pane() -> void:
	var worn := equipment_rows(world)
	var bag := bag_rows(world)
	var sig := str(worn) + "|" + str(bag)
	if sig == _pane_sig:
		return
	_pane_sig = sig
	for c in _pane.get_children():
		c.queue_free()
	var head := Label.new()
	head.text = "— equipment —"
	_pane.add_child(head)
	for row: Dictionary in worn:
		var b := Button.new()
		b.text = "%s: %s" % [String(row.label), String(row.line)]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.tooltip_text = String(row.tip)
		b.clip_text = true
		var op := int(row.op)
		if op > 0:
			b.pressed.connect(_queue_op.bind(op))
		else:
			b.disabled = true
		_pane.add_child(b)
	var p: RefCounted = world.players[0]
	var bag_head := Label.new()
	if p.class_id >= 0:
		bag_head.text = "— bag %d/%d —" % [BagStep.bag_count(p), BagStep.BAG_CAP]
	else:
		bag_head.text = "— bag — (—)"
	_pane.add_child(bag_head)
	for row: Dictionary in bag:
		var b := Button.new()
		b.text = String(row.line)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.tooltip_text = String(row.tip)
		b.clip_text = true
		b.pressed.connect(_queue_op.bind(int(row.equip_op)))
		b.gui_input.connect(_bag_gui_input.bind(int(row.drop_op)))
		_pane.add_child(b)
	if bag.is_empty():
		var empty := Label.new()
		empty.text = "(empty — [F] picks loot into the bag)"
		_pane.add_child(empty)


func _bag_gui_input(event: InputEvent, drop_op: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_queue_op(drop_op)


func _queue_op(op: int) -> void:
	if bag_op_sink.is_valid():
		bag_op_sink.call(op)


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
						"lv %d  rod %s  catches %d%s"
						% [
							int(character.get("starhook_level", 1)),
							String(character.get("starhook_rod", "rod_cane")).trim_prefix("rod_"),
							int(character.get("starhook_catches", 0)),
							(
								"  ✦starlit"
								if (int(character.get("starhook_skins", 0)) & 1) != 0
								else ""
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


static func _unique_for_items(world: RefCounted, items_index: int) -> int:
	var items: Array = world.stat_frame.get("items", [])
	if items_index < 0 or items_index >= items.size():
		return -1
	var iid := String(items[items_index].get("id", ""))
	for ui in world.unique_defs.size():
		if String(world.unique_defs[ui].items_id) == iid:
			return ui
	return -1
