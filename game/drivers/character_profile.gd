extends RefCounted
## Loop v1 character profile (docs/19 §3, ask sl-0025): THE persistent
## character. Permadeath is chosen at creation (docs/19 ruling 1);
## gold/XP/level/equipment carry between runs in user://character.json,
## OUTSIDE the sim — the scenario build applies the profile to player
## state setup-phase, the death flow harvests it back. NORMAL death:
## a gold percentage cost (progression data, [T]) plus the run-back
## itself; equipment is NEVER taken. HARDCORE death: the file is
## deleted — the character is gone. Sim purity: nothing here runs
## inside step(); replays of profile runs verify only against the same
## profile state (initial-hash honesty — ledgered as a header-extension
## follow-up).

const PATH := "user://character.json"
const VERSION := 1


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func create(hardcore: bool) -> Dictionary:
	return {
		"version": VERSION,
		"hardcore": hardcore,
		"gold": 0,
		"xp": 0,
		"level": 1,
		"weapon_tiers": [1, 1, 1],
		"armor_tier": 0,
		"unique_mask": 0,
		"ability_index": 0,
		"deaths": 0,
		"runs": 0,
		"created_utc": Time.get_datetime_string_from_system(true),
	}


static func load_profile() -> Dictionary:
	var text := FileAccess.get_file_as_string(PATH)
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


## Setup-phase: land the profile on player 0 + the equipped ability.
## Max hp/mana recompute from level through the progression tables; a
## fresh run starts full (the run-back is the price, not attrition).
static func apply_to_world(world: RefCounted, d: Dictionary) -> void:
	if world.players.is_empty():
		return
	var p: RefCounted = world.players[0]
	p.gold = int(d.get("gold", 0))
	p.xp = int(d.get("xp", 0))
	p.level = maxi(1, int(d.get("level", 1)))
	var prog: Resource = world.progression
	if prog != null:
		p.max_hp = 100 + (p.level - 1) * int(prog.max_hp_per_level)
		p.max_mana = 100 + (p.level - 1) * int(prog.mana_per_level)
	p.hp = p.max_hp
	p.mana = p.max_mana
	var tiers: Array = d.get("weapon_tiers", [1, 1, 1])
	for i in mini(tiers.size(), p.weapon_tiers.size()):
		p.weapon_tiers[i] = clampi(int(tiers[i]), 1, 6)
	p.armor_tier = clampi(int(d.get("armor_tier", 0)), 0, 5)
	p.unique_mask = int(d.get("unique_mask", 0))
	var ai := int(d.get("ability_index", 0))
	if ai >= 0 and ai < world.ability_defs.size():
		world.ability_def = world.ability_defs[ai]


## Harvest live progress back into the profile (heartbeat, death, quit).
static func harvest(world: RefCounted, d: Dictionary) -> void:
	if world.players.is_empty():
		return
	var p: RefCounted = world.players[0]
	d.gold = p.gold
	d.xp = p.xp
	d.level = p.level
	var tiers: Array = []
	for wt in p.weapon_tiers:
		tiers.append(wt)
	d.weapon_tiers = tiers
	d.armor_tier = p.armor_tier
	d.unique_mask = p.unique_mask
	d.ability_index = maxi(0, world.ability_defs.find(world.ability_def))


## Normal-mode death: percentage of CARRIED gold ([T] rate from
## progression data). Returns the gold lost, for the death toast.
static func apply_death_cost(d: Dictionary, progression: Resource) -> int:
	var pct := 25
	if progression != null:
		pct = int(progression.death_gold_pct)
	var lost := int(d.get("gold", 0)) * pct / 100
	d.gold = int(d.get("gold", 0)) - lost
	return lost
