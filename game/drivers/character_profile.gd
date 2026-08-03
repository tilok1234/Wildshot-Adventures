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
const DropKinds := preload("res://sim/drop_kinds.gd")
const TackleCatalog := preload("res://sim/tackle_catalog.gd")

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
		"bag": [],
		"bank": [],
		"unique_mask": 0,
		"quests_done_mask": 0,
		"quests_taken": [],
		"quest_progress": {},
		"starhook_level": 1,
		"starhook_xp": 0,
		"starhook_rod": "rod_cane",
		"starhook_skins": 0,
		"starhook_catches": 0,
		"starhook_fish": {},
		"starhook_rods": [],
		"starhook_tackle": [],
		"starhook_chest": "",
		"starhook_helm": "",
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
	# sl-0116: THE BAG — carried items BY ID/kind (absent key reads as
	# empty, the active_quest_id-migration read-tolerance precedent);
	# unresolvable rows skip honestly as items[] evolves.
	p.bag = PackedInt32Array()
	var bag_rows: Array = d.get("bag", []) if d.get("bag") is Array else []
	for row_v: Variant in bag_rows:
		if not row_v is Dictionary:
			continue
		var row: Dictionary = row_v
		var triple := _bag_triple_for(world, row)
		if triple.size() == 3:
			p.bag.append(triple[0])
			p.bag.append(triple[1])
			p.bag.append(triple[2])
	# sl-0130: the bank rides the same encoder (by id/kind).
	p.bank = PackedInt32Array()
	var bank_rows: Array = d.get("bank", []) if d.get("bank") is Array else []
	for row_v: Variant in bank_rows:
		if not row_v is Dictionary:
			continue
		var row: Dictionary = row_v
		var triple := _bag_triple_for(world, row)
		if triple.size() == 3:
			p.bank.append(triple[0])
			p.bank.append(triple[1])
			p.bank.append(triple[2])
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
	# THE GEAR SEAM (sl-0177/0178): the tackle lane loads on the
	# OVERWORLD player too — the fish wallet must be in-sim where the
	# tackle vendor trades (recorded, deterministic spends).
	_tackle_apply(world, p, d)
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
	var bag_rows: Array = []
	for bi in p.bag.size() / 3:
		var row := _bag_row_for(world, p.bag[bi * 3], p.bag[bi * 3 + 1], p.bag[bi * 3 + 2])
		if not row.is_empty():
			bag_rows.append(row)
	d.bag = bag_rows
	var bank_rows: Array = []
	for ki in p.bank.size() / 3:
		var krow := _bag_row_for(world, p.bank[ki * 3], p.bank[ki * 3 + 1], p.bank[ki * 3 + 2])
		if not krow.is_empty():
			bank_rows.append(krow)
	d.bank = bank_rows
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
	_tackle_harvest(world, p, d)


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


## Bag row (profile json) <-> sim triple (kind, a, b). Weapons/armor
## persist by frame+tier (the class loadout), rings by items[] id,
## uniques by def uid, abilities by index (recorded lean).
static func _bag_row_for(world: RefCounted, kind: int, a: int, b: int) -> Dictionary:
	match kind:
		DropKinds.WEAPON:
			return {"kind": "weapon", "frame": a, "tier": b}
		DropKinds.ARMOR:
			return {"kind": "armor", "tier": a}
		DropKinds.ABILITY:
			return {"kind": "ability", "index": a}
		DropKinds.UNIQUE:
			if a >= 0 and a < world.unique_defs.size():
				return {"kind": "unique", "uid": String(world.unique_defs[a].uid)}
			return {}
		DropKinds.RING:
			var iid := _items_id_for(world, a)
			return {"kind": "ring", "id": iid} if not iid.is_empty() else {}
	return {}


static func _bag_triple_for(world: RefCounted, row: Dictionary) -> PackedInt32Array:
	match String(row.get("kind", "")):
		"weapon":
			return PackedInt32Array(
				[DropKinds.WEAPON, int(row.get("frame", 0)), int(row.get("tier", 1))]
			)
		"armor":
			return PackedInt32Array([DropKinds.ARMOR, int(row.get("tier", 1)), 0])
		"ability":
			return PackedInt32Array([DropKinds.ABILITY, int(row.get("index", 0)), 0])
		"unique":
			var uid := String(row.get("uid", ""))
			for ui in world.unique_defs.size():
				if String(world.unique_defs[ui].uid) == uid:
					return PackedInt32Array([DropKinds.UNIQUE, ui, 0])
			return PackedInt32Array()
		"ring":
			var ri := _items_index_for(world, "ring", String(row.get("id", "")))
			if ri >= 0:
				return PackedInt32Array([DropKinds.RING, ri, 0])
			return PackedInt32Array()
	return PackedInt32Array()


static func _quest_index_for(world: RefCounted, quest_id: String) -> int:
	if quest_id.is_empty():
		return -1
	for i in world.quest_defs.size():
		if String(world.quest_defs[i].id) == quest_id:
			return i
	return -1


## ---- STARHOOK (S1 seam 6, sl-0105; v2 by sl-0115). The RIFTER —
## the designer's BAIT FIGHTER — is a fixed mini-class row on the
## stat frame's starhook block, riding the LEGACY lane in rift
## worlds (class_id -1: no recompute, direct stats; the loop XP
## curve levels it — "no new progression system"). Gold starts at
## ZERO in the rift (the pot IS the catch); harvest_rift adds it to
## the MAIN wallet. A lost dive (three snaps) simply never harvests
## — the rift world discards whole. The rod LADDER is installed by
## scenario_loader (the one construction path); this only equips
## the profile's choice, level-gated.


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
	# THE GEAR SEAM: the tackle lane loads BEFORE the rod pick (the
	# owned mask gates purchasable rods) and the worn chest/helm land
	# as rift-side stats — chest raises the line's capacity, the helm
	# mitigates BULLET strain via THE formula (the drains never
	# mitigate; overworld combat untouched by construction).
	_tackle_apply(world, p, d)
	var titems: Array = TackleCatalog.items(world.stat_frame)
	if p.tackle_chest >= 0 and p.tackle_chest < titems.size():
		p.max_hp += int((titems[p.tackle_chest] as Dictionary).get("hp", 0))
	if p.tackle_helm >= 0 and p.tackle_helm < titems.size():
		p.armor = int((titems[p.tackle_helm] as Dictionary).get("defense", 0))
	p.hp = p.max_hp
	# The rod IS the rifter's class; R swaps among unlocked rods
	# (sl-0115). Entry equips the profile's rod when its level gate
	# holds, else the highest unlocked (never a locked rod; sl-0177:
	# purchasable rods also need their owned bit).
	var rod_id := String(d.get("starhook_rod", "rod_cane"))
	var rods: Array = sh.get("rods", [])
	var equip := 0
	for ri in rods.size():
		var rod: Dictionary = rods[ri]
		if lvl < int(rod.get("unlock_level", 99)):
			continue
		if rod.has("price") and (p.rods_owned_mask & (1 << ri)) == 0:
			continue
		if String(rod.get("id", "")) == rod_id:
			equip = ri
			break
		equip = ri
	p.equipped_weapon = equip
	# The starlit cosmetic mask rides in so the rare catch's unique
	# pickup can't double-grant.
	if (int(d.get("starhook_skins", 0)) & 1) != 0:
		p.unique_mask |= 1 << 2


## Rift-exit harvest (a LOST dive never calls this): gold pot to the
## MAIN wallet, level/xp back to the starhook lane, the equipped rod
## persists BY ID (the R choice carries), the catch counter on a won
## fight, landed FISH banked PER-SPECIES (species-currency, deck tap
## shk2ctch — vendors price in fish someday), and any cosmetic bit.
static func harvest_rift(world: RefCounted, d: Dictionary, won: bool) -> void:
	if world.players.is_empty():
		return
	var p: RefCounted = world.players[0]
	d.gold = int(d.get("gold", 0)) + p.gold
	d.starhook_level = p.level
	d.starhook_xp = p.xp
	# THE GEAR SEAM: ownership/equips fold back BY ID first (a rare
	# catch may have dropped a piece mid-dive); the fish sync is a
	# no-op here (no rift spends) and the catch fold below adds onto
	# the synced bank.
	_tackle_harvest(world, p, d)
	if won:
		d.starhook_catches = int(d.get("starhook_catches", 0)) + 1
	var sh: Dictionary = world.stat_frame.get("starhook", {})
	var rods: Array = sh.get("rods", [])
	if p.equipped_weapon >= 0 and p.equipped_weapon < rods.size():
		d.starhook_rod = String(rods[p.equipped_weapon].get("id", "rod_cane"))
	var fish_bank: Dictionary = (
		d.get("starhook_fish", {}) if d.get("starhook_fish") is Dictionary else {}
	)
	var biomes: Array = sh.get("biomes", [])
	for catch: Dictionary in world.rift_catches:
		var bi := int(catch.biome)
		if bi >= biomes.size():
			continue
		var b: Dictionary = biomes[bi]
		var species := ""
		if bool(catch.rare):
			species = String(b.get("rare", {}).get("id", ""))
		else:
			var table: Array = b.get("fish", [])
			var fi := int(catch.fish)
			if fi < table.size():
				species = String(table[fi].get("id", ""))
		if species.is_empty():
			continue
		fish_bank[species] = int(fish_bank.get(species, 0)) + 1
	d.starhook_fish = fish_bank
	if (p.unique_mask & (1 << 2)) != 0:
		d.starhook_skins = int(d.get("starhook_skins", 0)) | 1


## ---- THE GEAR SEAM (sl-0177/0178): the tackle lane, BOTH world
## shapes, always BY ID (the seam-2 doctrine — lists evolve, saves
## never silently re-point). Fish: the profile's id-keyed bank loads
## into the run's species-index array; harvest writes CURRENT-table
## species back and PRESERVES unknown keys (the fish-first word: a
## species re-roster never eats the designer's fish).


static func _tackle_apply(world: RefCounted, p: RefCounted, d: Dictionary) -> void:
	var frame: Dictionary = world.stat_frame
	var ids := TackleCatalog.species_ids(frame)
	p.fish = PackedInt32Array()
	p.fish.resize(ids.size())
	var bank: Dictionary = (
		d.get("starhook_fish", {}) if d.get("starhook_fish") is Dictionary else {}
	)
	for i in ids.size():
		p.fish[i] = clampi(int(bank.get(ids[i], 0)), 0, 65535)
	p.rods_owned_mask = 0
	var rlist := TackleCatalog.rods(frame)
	var owned_rods: Array = d.get("starhook_rods", []) if d.get("starhook_rods") is Array else []
	for rid_v: Variant in owned_rods:
		for ri in rlist.size():
			if String((rlist[ri] as Dictionary).get("id", "")) == String(rid_v):
				p.rods_owned_mask |= 1 << ri
	p.tackle_owned_mask = 0
	var ilist := TackleCatalog.items(frame)
	var owned_items: Array = (
		d.get("starhook_tackle", []) if d.get("starhook_tackle") is Array else []
	)
	for tid_v: Variant in owned_items:
		for ii in ilist.size():
			if String((ilist[ii] as Dictionary).get("id", "")) == String(tid_v):
				p.tackle_owned_mask |= 1 << ii
	p.tackle_chest = _tackle_item_index(ilist, String(d.get("starhook_chest", "")), "chest")
	p.tackle_helm = _tackle_item_index(ilist, String(d.get("starhook_helm", "")), "helm")
	# An equip the profile claims but the owned list lost is worn
	# honestly only when owned (defensive: equips imply ownership).
	if p.tackle_chest >= 0 and (p.tackle_owned_mask & (1 << p.tackle_chest)) == 0:
		p.tackle_chest = -1
	if p.tackle_helm >= 0 and (p.tackle_owned_mask & (1 << p.tackle_helm)) == 0:
		p.tackle_helm = -1


static func _tackle_harvest(world: RefCounted, p: RefCounted, d: Dictionary) -> void:
	var frame: Dictionary = world.stat_frame
	var ids := TackleCatalog.species_ids(frame)
	var bank: Dictionary = (
		d.get("starhook_fish", {}) if d.get("starhook_fish") is Dictionary else {}
	)
	for i in ids.size():
		bank[ids[i]] = p.fish[i] if i < p.fish.size() else 0
	d.starhook_fish = bank
	var rlist := TackleCatalog.rods(frame)
	var owned_rods: Array = []
	for ri in rlist.size():
		if (p.rods_owned_mask & (1 << ri)) != 0:
			owned_rods.append(String((rlist[ri] as Dictionary).get("id", "")))
	d.starhook_rods = owned_rods
	var ilist := TackleCatalog.items(frame)
	var owned_items: Array = []
	for ii in ilist.size():
		if (p.tackle_owned_mask & (1 << ii)) != 0:
			owned_items.append(String((ilist[ii] as Dictionary).get("id", "")))
	d.starhook_tackle = owned_items
	d.starhook_chest = _tackle_item_id(ilist, p.tackle_chest)
	d.starhook_helm = _tackle_item_id(ilist, p.tackle_helm)


static func _tackle_item_index(ilist: Array, item_id: String, slot: String) -> int:
	if item_id.is_empty():
		return -1
	for ii in ilist.size():
		var row: Dictionary = ilist[ii]
		if String(row.get("id", "")) == item_id and String(row.get("slot", "")) == slot:
			return ii
	return -1


static func _tackle_item_id(ilist: Array, index: int) -> String:
	if index < 0 or index >= ilist.size():
		return ""
	return String((ilist[index] as Dictionary).get("id", ""))


## Normal-mode death: percentage of CARRIED gold ([T] rate from
## progression data). Returns the gold lost, for the death toast.
static func apply_death_cost(d: Dictionary, progression: Resource) -> int:
	var pct := 25
	if progression != null:
		pct = int(progression.death_gold_pct)
	var lost := int(d.get("gold", 0)) * pct / 100
	d.gold = int(d.get("gold", 0)) - lost
	return lost
