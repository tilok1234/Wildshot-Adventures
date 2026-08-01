extends RefCounted
## THE persistent character (Loop v1 docs/19 ruling 1; CLASS-BACKED
## since the stat frame entered the sim — docs/22, slice S0 seam 1).
## Permadeath is chosen at creation; class is chosen at creation
## (docs/23 class call: all three from the start). gold/XP/level/
## equipment carry in user://character.json, OUTSIDE the sim — the
## scenario build applies the profile to player state setup-phase, the
## death flow harvests it back. NORMAL death: a gold percentage cost
## (progression data, [T]) plus the walk back; equipment is NEVER
## taken. HARDCORE death: the file is deleted.
##
## VERSION 2 (slice era): adds class + ring; weapon_tiers is sized to
## the CLASS loadout (one archetype frame in S0). Version-1 loop-era
## profiles deliberately do NOT migrate — the slice character starts
## fresh on the new curves, and the creation screen owns the class
## choice (the b65 test character retired with its loop).
## Sim purity: nothing here runs inside step(); replays of profile
## runs refuse verification honestly (ledger #16 — class/ring fields
## join that recorded gap).

const StatFrame := preload("res://sim/systems/stat_frame.gd")

const PATH := "user://character.json"
const VERSION := 2

## Class name -> the class's slice weapon frame (docs/22 block-5
## identity riding block-3 frames; the [P] mapping in the json).
const CLASS_FRAMES := {
	"sword": "res://data/weapons/class_sword.tres",
	"staff": "res://data/weapons/class_staff.tres",
	"bow": "res://data/weapons/class_bow.tres",
}


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func create(hardcore: bool, cls := "bow") -> Dictionary:
	if not CLASS_FRAMES.has(cls):
		cls = "bow"
	return {
		"version": VERSION,
		"class": cls,
		"hardcore": hardcore,
		"gold": 0,
		"xp": 0,
		"level": 1,
		"weapon_tiers": [1],
		"armor_tier": 0,
		"ring_id": "",
		"unique_mask": 0,
		"ability_index": 0,
		"deaths": 0,
		"runs": 0,
		"created_utc": Time.get_datetime_string_from_system(true),
	}


## Version gate: anything but the current VERSION reads as "no
## character" (the v1 loop-era profile deliberately starts fresh on
## the slice curves). `path` parameter exists for the stat-frame test.
static func load_profile(path := PATH) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary or int(parsed.get("version", -1)) != VERSION:
		return {}
	return parsed


static func save_profile(d: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d, "\t"))
		f.close()


static func delete_profile() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


## Setup-phase: land the profile on player 0 + the equipped ability +
## the CLASS LOADOUT (the class's slice frame replaces the lab trio —
## setup-phase definition swap, before the recorder snapshot). Derived
## stats come from StatFrame.recompute; a fresh run starts full (the
## walk back is the price, not attrition).
static func apply_to_world(world: RefCounted, d: Dictionary) -> void:
	if world.players.is_empty():
		return
	var p: RefCounted = world.players[0]
	var cls := String(d.get("class", "bow"))
	if not CLASS_FRAMES.has(cls):
		cls = "bow"
	world.set_weapons([load(String(CLASS_FRAMES[cls]))])
	p.class_id = StatFrame.CLASS_IDS.find(StringName(cls))
	p.gold = int(d.get("gold", 0))
	p.xp = int(d.get("xp", 0))
	p.level = clampi(int(d.get("level", 1)), 1, StatFrame.LEVEL_CAP)
	var tiers: Array = d.get("weapon_tiers", [1])
	var wt := PackedInt32Array()
	wt.resize(world.weapon_frames.size())
	for i in wt.size():
		wt[i] = clampi(int(tiers[i]) if i < tiers.size() else 1, 1, 5)
	p.weapon_tiers = wt
	p.equipped_weapon = 0
	p.armor_tier = clampi(int(d.get("armor_tier", 0)), 0, 5)
	# S1 seam 2: profiles key the ring BY ID — items[] evolves chapter
	# by chapter and a raw index would silently re-point saved rings.
	# The sim keeps the integer index (serialization unchanged).
	p.ring_index = _ring_index_for(world, String(d.get("ring_id", "")))
	p.unique_mask = int(d.get("unique_mask", 0))
	StatFrame.recompute(world, p)
	p.hp = p.max_hp
	p.mana = p.max_mana
	var ai := int(d.get("ability_index", 0))
	if ai >= 0 and ai < world.ability_defs.size():
		world.ability_def = world.ability_defs[ai]


## Harvest live progress back into the profile (heartbeat, death, quit).
static func harvest(world: RefCounted, d: Dictionary) -> void:
	if world.players.is_empty():
		return
	var p: RefCounted = world.players[0]
	if p.class_id >= 0 and p.class_id < StatFrame.CLASS_IDS.size():
		d["class"] = String(StatFrame.CLASS_IDS[p.class_id])
	d.gold = p.gold
	d.xp = p.xp
	d.level = p.level
	var tiers: Array = []
	for wt in p.weapon_tiers:
		tiers.append(wt)
	d.weapon_tiers = tiers
	d.armor_tier = p.armor_tier
	d.ring_id = _ring_id_for(world, p.ring_index)
	d.unique_mask = p.unique_mask
	d.ability_index = maxi(0, world.ability_defs.find(world.ability_def))


## Ring id <-> stat-frame items[] index (S1 seam 2): the profile's
## stable key is the ID; the sim's serialized field stays the index.
static func _ring_index_for(world: RefCounted, ring_id: String) -> int:
	if ring_id.is_empty():
		return -1
	var items: Array = world.stat_frame.get("items", [])
	for i in items.size():
		var it: Dictionary = items[i]
		if String(it.get("slot", "")) == "ring" and String(it.get("id", "")) == ring_id:
			return i
	return -1


static func _ring_id_for(world: RefCounted, ring_index: int) -> String:
	var items: Array = world.stat_frame.get("items", [])
	if ring_index < 0 or ring_index >= items.size():
		return ""
	return String(items[ring_index].get("id", ""))


## Normal-mode death: percentage of CARRIED gold ([T] rate from
## progression data). Returns the gold lost, for the death toast.
static func apply_death_cost(d: Dictionary, progression: Resource) -> int:
	var pct := 25
	if progression != null:
		pct = int(progression.death_gold_pct)
	var lost := int(d.get("gold", 0)) * pct / 100
	d.gold = int(d.get("gold", 0)) - lost
	return lost
