extends RefCounted
## Item -> icon-atlas glyph id (menu pass; view-only, the one mapping
## point). The wired wildshot-icons-proto vocabulary is richer than the
## game's item set, so canonical per-class styles are PICKED here [T —
## cosmetic, the designer's later polish re-maps in one place]:
## weapons sword/arming, staff/longstaff, bow/recurve (matching the
## balance-frame catalog names); armor = bulwark; rings/uniques by
## flavor map with safe fallbacks. The sl-0123 never-bind pin stands:
## the retired glyph word may not appear ANYWHERE in sources — the
## wiring test REDs on any reference, comments included (it caught
## this file's own header naming it; textual by design).

const DropKinds := preload("res://sim/drop_kinds.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")

const WEAPON_STYLE := {"sword": "arming", "staff": "longstaff", "bow": "recurve"}
const ABILITY_STYLE := {"sword": "blade_nova", "staff": "arc_bolt", "bow": "blast_arrow"}
const RING_STYLE := {
	"t1-ring-of-haste": "featherweight",
	"t1-ring-of-claws": "duelist_seal",
	"t2-ring-of-reach": "anchor",
	"t3-ring-of-fangs": "grudge_band",
}
const UNIQUE_STYLE := {
	"u-old-tusks-hide": "item.unique.hearthplate",
	"u-reliquary-coil": "item.unique.thornreel",
}


static func class_key(class_id: int) -> String:
	if class_id >= 0 and class_id < StatFrame.CLASS_IDS.size():
		return String(StatFrame.CLASS_IDS[class_id])
	return "sword"


static func class_emblem(class_id: int) -> String:
	return "emblem.class.%s" % class_key(class_id)


## Glyph id for an item triple {kind, a, b}; class_id flavors the
## class-styled families. Always returns a REAL atlas id.
static func icon_id(world: RefCounted, item: Dictionary, class_id: int) -> String:
	var cls := class_key(class_id)
	match int(item.kind):
		DropKinds.GOLD:
			return "currency.gold"
		DropKinds.WEAPON:
			return (
				"item.weapon.%s.%s.t%d"
				% [cls, String(WEAPON_STYLE[cls]), clampi(int(item.b), 1, 5)]
			)
		DropKinds.ARMOR:
			return "item.armor.%s.bulwark.t%d" % [cls, clampi(int(item.a), 1, 5)]
		DropKinds.RING:
			var items: Array = world.stat_frame.get("items", [])
			var ri := int(item.a)
			if ri >= 0 and ri < items.size():
				var row: Dictionary = items[ri]
				var style := String(RING_STYLE.get(String(row.get("id", "")), "spark_loop"))
				return "item.ring.%s.t%d" % [style, clampi(int(row.get("tier", 1)), 1, 5)]
			return "item.ring.spark_loop.t1"
		DropKinds.UNIQUE:
			var ui := int(item.a)
			if ui >= 0 and ui < world.unique_defs.size():
				var iid := String(world.unique_defs[ui].items_id)
				return String(UNIQUE_STYLE.get(iid, "item.unique.patience"))
			return "item.unique.patience"
		DropKinds.ABILITY:
			return "item.ability.%s.%s" % [cls, String(ABILITY_STYLE[cls])]
	return "quest.available"
