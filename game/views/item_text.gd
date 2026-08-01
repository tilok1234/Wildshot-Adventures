extends RefCounted
## THE ONE ITEM-TEXT GRAMMAR (S1 seam 2; docs/22 standing constraint:
## "every number visible on the tooltip", block 7: "every tooltip in
## the game reads the same way"). Every surface that names a drop —
## pickup toasts, ground labels, future inventory — composes its line
## HERE, so the grammar cannot fork. View-side only; reads sim state,
## never mutates.

const DropKinds := preload("res://sim/drop_kinds.gd")

const STAT_SHORT := {
	"damage": "dmg",
	"defense": "def",
	"speed": "spd",
	"hp": "hp",
	"mana": "mana",
	"range": "range",
	"attack_speed": "atk-spd",
}


## One line for a ground drop {kind, a, b}. Empty string = no label
## (unknown/out-of-range data never crashes a view).
static func drop_line(world: RefCounted, d: Dictionary) -> String:
	match int(d.kind):
		DropKinds.GOLD:
			return "%d gold" % int(d.a)
		DropKinds.WEAPON:
			return _weapon_line(world, int(d.a), int(d.b))
		DropKinds.ARMOR:
			return _armor_line(world, int(d.a))
		DropKinds.ABILITY:
			var idx := int(d.a)
			if idx >= 0 and idx < world.ability_defs.size():
				return String(world.ability_defs[idx].display_name)
			return ""
		DropKinds.RING:
			return _ring_line(world, int(d.a))
		DropKinds.UNIQUE:
			var ui := int(d.a)
			if ui >= 0 and ui < world.unique_defs.size():
				return "UNIQUE: %s" % String(world.unique_defs[ui].display_name)
			return ""
	return ""


static func _weapon_line(world: RefCounted, frame: int, tier: int) -> String:
	if frame < 0 or frame >= world.weapon_frames.size():
		return ""
	var wf: Resource = world.weapon_frames[frame]
	var arch := String(wf.archetype)
	if arch.is_empty():
		return "T%d %s" % [tier, String(wf.display_name)]
	var frames: Dictionary = world.stat_frame.get("weapon_tiers", {}).get("frames", {})
	var row: Dictionary = frames.get(arch, {})
	var table: Array = row.get("damage", [])
	if tier < 1 or tier > table.size():
		return "T%d %s" % [tier, String(wf.display_name)]
	return (
		"T%d %s — %d dmg @ %s/s"
		% [
			tier,
			String(wf.display_name),
			int(table[tier - 1]),
			String.num(float(row.get("shots_per_sec", 0.0)), 1)
		]
	)


static func _armor_line(world: RefCounted, tier: int) -> String:
	var slot: Dictionary = world.stat_frame.get("armor_slot", {})
	var defense: Array = slot.get("defense", [])
	var hp: Array = slot.get("hp", [])
	if tier < 1 or tier > defense.size() or tier > hp.size():
		return "T%d Armor" % tier
	return "T%d Armor — +%d def, +%d hp" % [tier, int(defense[tier - 1]), int(hp[tier - 1])]


static func _ring_line(world: RefCounted, items_index: int) -> String:
	var items: Array = world.stat_frame.get("items", [])
	if items_index < 0 or items_index >= items.size():
		return ""
	var it: Dictionary = items[items_index]
	if String(it.get("slot", "")) != "ring":
		return ""
	var name := String(it.get("name", String(it.get("id", "ring")).capitalize()))
	var t: Dictionary = it.get("trade", {})
	if t.is_empty():
		return name
	return (
		"%s — +%d %s / −%d %s"
		% [
			name,
			int(t.get("up_amount", 0)),
			String(STAT_SHORT.get(String(t.get("up", "")), String(t.get("up", "")))),
			int(t.get("down_amount", 0)),
			String(STAT_SHORT.get(String(t.get("down", "")), String(t.get("down", "")))),
		]
	)
