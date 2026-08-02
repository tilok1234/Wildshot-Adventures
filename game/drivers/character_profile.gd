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
		"armor_item_id": "",
		"unique_mask": 0,
		"quests_done_mask": 0,
		"quests_taken": [],
		"quest_progress": {},
		"starhook_level": 1,
		"starhook_xp": 0,
		"starhook_rod": "rod_cane",
		"starhook_skins": 0,
		"starhook_catches": 0,
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
	# S1 seam 2/3: profiles key equipment items BY ID — items[] evolves
	# chapter by chapter and a raw index would silently re-point saves.
	# The sim keeps integer indexes (serialization unchanged).
	p.ring_index = _items_index_for(world, "ring", String(d.get("ring_id", "")))
	p.armor_item_index = _items_index_for(world, "armor", String(d.get("armor_item_id", "")))
	p.unique_mask = int(d.get("unique_mask", 0))
	# sl-0112: quest state — done mask by index (append-only list, the
	# unique_mask precedent); TAKEN quests + per-quest progress key BY
	# ID (multi-active). A pre-interact-era active_quest_id migrates
	# into the taken set for free via the same lookup.
	p.quests_done_mask = int(d.get("quests_done_mask", 0))
	p.quests_taken_mask = 0
	p.quest_progress_arr = PackedInt32Array()
	p.quest_progress_arr.resize(world.quest_defs.size())
	var taken_ids: Array = d.get("quests_taken", [])
	var legacy_active := String(d.get("active_quest_id", ""))
	if not legacy_active.is_empty() and not taken_ids.has(legacy_active):
		taken_ids = taken_ids + [legacy_active]
	var prog: Dictionary = (
		d.get("quest_progress", {}) if d.get("quest_progress") is Dictionary else {}
	)
	for tid in taken_ids:
		var qi := _quest_index_for(world, String(tid))
		if qi >= 0:
			p.quests_taken_mask |= 1 << qi
			p.quest_progress_arr[qi] = int(prog.get(String(tid), 0))
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
	d.ring_id = _items_id_for(world, p.ring_index)
	d.armor_item_id = _items_id_for(world, p.armor_item_index)
	d.unique_mask = p.unique_mask
	d.quests_done_mask = p.quests_done_mask
	var taken_ids: Array = []
	var prog: Dictionary = {}
	for qi in world.quest_defs.size():
		if (p.quests_taken_mask & (1 << qi)) == 0:
			continue
		var qid := String(world.quest_defs[qi].id)
		taken_ids.append(qid)
		if qi < p.quest_progress_arr.size():
			prog[qid] = p.quest_progress_arr[qi]
	d.quests_taken = taken_ids
	d.quest_progress = prog
	d.erase("active_quest_id")
	d.ability_index = maxi(0, world.ability_defs.find(world.ability_def))


## Item id <-> stat-frame items[] index (S1 seams 2/3): the profile's
## stable key is the ID; the sim's serialized fields stay indexes.
static func _items_index_for(world: RefCounted, slot: String, item_id: String) -> int:
	if item_id.is_empty():
		return -1
	var items: Array = world.stat_frame.get("items", [])
	for i in items.size():
		var it: Dictionary = items[i]
		if String(it.get("slot", "")) == slot and String(it.get("id", "")) == item_id:
			return i
	return -1


static func _items_id_for(world: RefCounted, index: int) -> String:
	var items: Array = world.stat_frame.get("items", [])
	if index < 0 or index >= items.size():
		return ""
	return String(items[index].get("id", ""))


static func _quest_index_for(world: RefCounted, quest_id: String) -> int:
	if quest_id.is_empty():
		return -1
	for i in world.quest_defs.size():
		if String(world.quest_defs[i].id) == quest_id:
			return i
	return -1


## ---- STARHOOK (S1 seam 6, sl-0105). The RIFTER = a fixed
## mini-class row on the stat frame's starhook block, riding the
## LEGACY lane in rift worlds (class_id -1: no recompute, direct
## stats; the loop XP curve levels it — "no new progression
## system"). Gold starts at ZERO in the rift (the pot IS the catch);
## harvest_rift adds it to the MAIN wallet. Line-snap death simply
## never harvests — the rift world discards whole.

const ROD_PATHS := {
	"rod_cane": "res://data/weapons/rod_cane.tres",
	"rod_splitwillow": "res://data/weapons/rod_splitwillow.tres",
}


static func apply_to_rift(world: RefCounted, d: Dictionary) -> void:
	if world.players.is_empty():
		return
	var p: RefCounted = world.players[0]
	var sh: Dictionary = world.stat_frame.get("starhook", {})
	var rifter: Dictionary = sh.get("rifter", {})
	var lvl := maxi(1, int(d.get("starhook_level", 1)))
	p.class_id = -1
	p.level = lvl
	p.xp = int(d.get("starhook_xp", 0))
	p.max_hp = maxi(
		1, int(rifter.get("base_hp", 60)) + int(rifter.get("hp_per_level", 8)) * (lvl - 1)
	)
	p.hp = p.max_hp
	p.move_speed = float(rifter.get("speed_tiles", 3.6))
	p.gold = 0
	# The rod IS the rifter's class: newest unlock auto-equips [T]
	# (a swap UI is a designer round).
	var rod_id := String(d.get("starhook_rod", "rod_cane"))
	for rod: Dictionary in sh.get("rods", []):
		if lvl >= int(rod.get("unlock_level", 99)):
			rod_id = String(rod.get("id", rod_id))
	world.set_weapons([load(String(ROD_PATHS.get(rod_id, ROD_PATHS.rod_cane)))])
	p.weapon_tiers = PackedInt32Array([1])
	p.equipped_weapon = 0
	# The starlit cosmetic mask rides in so the rare catch's unique
	# pickup can't double-grant.
	if (int(d.get("starhook_skins", 0)) & 1) != 0:
		p.unique_mask |= 1 << 2


## Rift-exit harvest (the line snap never calls this): gold pot to
## the MAIN wallet, level/xp back to the starhook lane, the catch
## counter ONLY on a won fight, and any cosmetic bit.
static func harvest_rift(world: RefCounted, d: Dictionary, won: bool) -> void:
	if world.players.is_empty():
		return
	var p: RefCounted = world.players[0]
	d.gold = int(d.get("gold", 0)) + p.gold
	d.starhook_level = p.level
	d.starhook_xp = p.xp
	if won:
		d.starhook_catches = int(d.get("starhook_catches", 0)) + 1
	if (p.unique_mask & (1 << 2)) != 0:
		d.starhook_skins = int(d.get("starhook_skins", 0)) | 1
	var sh: Dictionary = world.stat_frame.get("starhook", {})
	for rod: Dictionary in sh.get("rods", []):
		if p.level >= int(rod.get("unlock_level", 99)):
			d.starhook_rod = String(rod.get("id", d.get("starhook_rod", "rod_cane")))


## Normal-mode death: percentage of CARRIED gold ([T] rate from
## progression data). Returns the gold lost, for the death toast.
static func apply_death_cost(d: Dictionary, progression: Resource) -> int:
	var pct := 25
	if progression != null:
		pct = int(progression.death_gold_pct)
	var lost := int(d.get("gold", 0)) * pct / 100
	d.gold = int(d.get("gold", 0)) - lost
	return lost
