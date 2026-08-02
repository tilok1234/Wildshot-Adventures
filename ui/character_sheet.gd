extends PanelContainer
## THE CHARACTER SHEET + QUEST LOG (sl-0106 + sl-0112's log; seam B).
## Read-only; docs/22's "every number visible" gets its surface. The
## rows come from PURE MODEL functions over live player state — the
## screen==recompute parity is EXACT by construction (state IS
## recompute's output; the sheet re-derives NOTHING) and test-pinned.
## Item lines speak the one grammar (item_text). Toggled by the
## char_sheet action (C [T]); read-only — never pauses, never
## captures input beyond its key.

const ItemText := preload("res://game/views/item_text.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const DropKinds := preload("res://sim/drop_kinds.gd")

## Fixed screen placement [T: centered] — sl-0119. The panel sizes
## from the ui-scale theme and clamps inside the viewport; errand
## overflow SCROLLS in the label [T] (fit_content grew the panel past
## the screen — the offscreen bug's second half).
const BASE_SIZE := Vector2(320.0, 330.0)
const SCREEN_MARGIN := 4.0

var world: RefCounted = null
## The persistent profile dict (starhook lane lives there).
var character: Dictionary = {}

var _label: RichTextLabel = null
var _accum := 0.0


func _ready() -> void:
	visible = false
	_label = RichTextLabel.new()
	_label.bbcode_enabled = false
	_label.fit_content = false
	_label.scroll_active = true
	add_child(_label)
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
