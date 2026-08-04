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
		DropKinds.FORAGE:
			# sl-0198: forage kin — plain overworld names (the cosmic
			# rail is starhook-lane-only); picks up into the WALLET.
			return "%d %s" % [maxi(1, int(d.b)), forage_species_name(world, int(d.a))]
		DropKinds.UNIQUE:
			var ui := int(d.a)
			if ui >= 0 and ui < world.unique_defs.size():
				var ud: Resource = world.unique_defs[ui]
				var base := "UNIQUE: %s" % String(ud.display_name)
				# Items-mapped uniques (S1 seam 3) publish their numbers
				# like everything else — armor uniques read def/hp/cost.
				var uid := String(ud.items_id)
				if not uid.is_empty():
					var items: Array = world.stat_frame.get("items", [])
					for it: Dictionary in items:
						if (
							String(it.get("id", "")) == uid
							and String(it.get("slot", "")) == "armor"
						):
							return (
								"%s — +%d def, +%d hp / −%d spd"
								% [
									base,
									int(it.get("defense", 0)),
									int(it.get("hp", 0)),
									int(it.get("speed_cost", 0)),
								]
							)
				return base
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


## ---- THE TACKLE GRAMMAR (sl-0177/0178): rods speak like weapons,
## chest/helm like armor — same shape, every number visible.


## "T3 Heavyline — 16 dmg @ 0.7/s" / "T2 Splitwillow — 3x4 dmg @ 1.7/s".
static func rod_line(rod_row: Dictionary, frame_res: Resource) -> String:
	var tier := int(rod_row.get("tier", 0))
	var name := String(rod_row.get("name", rod_row.get("id", "rod")))
	if frame_res == null:
		return "T%d %s" % [tier, name]
	var shots: Array = frame_res.shots
	var cad := int(frame_res.cadence_ticks)
	if shots.is_empty() or cad <= 0:
		return "T%d %s" % [tier, name]
	var dmg := int(shots[0].damage)
	var count := shots.size()
	var dmg_text := "%d" % dmg if count == 1 else "%dx%d" % [count, dmg]
	return "T%d %s — %s dmg @ %s/s" % [tier, name, dmg_text, String.num(60.0 / cad, 1)]


## "T2 Rift Chest — +16 hp" / "T2 Rift Helm — +5 def".
static func tackle_item_line(row: Dictionary) -> String:
	var tier := int(row.get("tier", 0))
	var name := String(row.get("name", row.get("id", "gear")))
	if String(row.get("slot", "")) == "chest":
		return "T%d %s — +%d hp" % [tier, name, int(row.get("hp", 0))]
	return "T%d %s — +%d def" % [tier, name, int(row.get("defense", 0))]


## Fish price: "2 Emberwisp Koi + 1 Silence Carp" (species NAMES from
## the biome tables; ids fall through so an unnamed species never
## renders blank).
static func fish_price_text(frame: Dictionary, price: Dictionary) -> String:
	var names := {}
	for biome: Dictionary in frame.get("starhook", {}).get("biomes", []):
		for fr: Dictionary in biome.get("fish", []) as Array:
			names[String(fr.get("id", ""))] = String(fr.get("name", fr.get("id", "")))
		var rare: Dictionary = biome.get("rare", {})
		names[String(rare.get("id", ""))] = String(rare.get("name", rare.get("id", "")))
	var parts: Array[String] = []
	for sp: String in price:
		parts.append("%d %s" % [int(price[sp]), String(names.get(sp, sp))])
	return " + ".join(parts)


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


## sl-0198: forage species display name from the world's derived
## vocabulary ("fallen_log" -> "fallen log"); plain overworld words.
static func forage_species_name(world: RefCounted, species: int) -> String:
	var ids: Array = world.forage_species_ids
	if species >= 0 and species < ids.size():
		return String(ids[species]).replace("_", " ")
	return "forage kin"
