extends RefCounted
## THE STAT FRAME (docs/22 blocks 1-8, designer-ruled 2026-08-01; entered
## the sim at slice build S0 seam 1, sl-0100). data/balance_frame.json is
## the SINGLE tuning source — this module turns it into sim effects for
## CLASS-BACKED players (PlayerState.class_id >= 0). class_id -1 is the
## pre-slice legacy lane: every derived stat sits at its identity default
## and the loop-era progression math applies unchanged, so bare test
## scenarios and the proof battery are byte-identical by construction.
##
## Game-side conventions [P] (planning sweeps these, docs/22 untouched):
## - SPEED ANCHOR: speed stat 100 (sword, the floor) == 3.0 tiles/s — the
##   CORE-53 proof floor every battery row is stamped with. Bases
##   100/105/110 => 3.0/3.15/3.3 t/s; the ruled +15% HARD CAP (115) =>
##   3.45 t/s, enforced in the movement integrator (player_move.gd),
##   never in item data. The designer's ruled revisit ("look at it later
##   after we tried it some") is this one constant + a proof re-run.
## - THE damage formula is integer-exact: ceil(attack * 0.2) computed as
##   (attack*20 + 99)/100 — floats would mis-round exact multiples.
## - Class ids 0/1/2 = sword/staff/bow (balance_frame.json "classes"
##   key order); the class's weapon frame archetype maps per the json.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

## Class id order — index into this array IS PlayerState.class_id.
const CLASS_IDS: Array[StringName] = [&"sword", &"staff", &"bow"]

## docs/22 block 2 — THE formula's 20% floor as an exact rational.
## load_frame() REFUSES a json whose floor_fraction drifts from this.
const FLOOR_NUM := 20
const FLOOR_DEN := 100

## docs/22 block 6 — the ruled numbers, asserted against the json at
## load. The cap lives HERE and in the integrator, never in item data.
const SPEED_HARD_CAP := 115
const SPEED_TILES_PER_100 := 3.0
const CAP_TILES_PER_S := SPEED_TILES_PER_100 * float(SPEED_HARD_CAP) / 100.0

## Slice level cap (docs/22 block 5; brackets end at 30).
const LEVEL_CAP := 30

## The seven-stat trade vocabulary (docs/22 block 7). Every armor/ring
## stat line is ONE sanctioned up/down pair over these keys.
const TRADE_KEYS: Array[String] = [
	"damage", "defense", "speed", "hp", "mana", "range", "attack_speed"
]


## Parse + shape-check data/balance_frame.json. Returns {} (with a loud
## error) on any drift from the ruled frame — the balance calculator
## gates the file in CI; this guards the runtime read end.
static func load_frame(path := "res://data/balance_frame.json") -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("stat_frame: missing or empty " + path)
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("stat_frame: " + path + " is not a JSON object")
		return {}
	var f: Dictionary = parsed
	for key: String in [
		"formula", "classes", "weapon_tiers", "armor_slot", "xp", "brackets", "speed_rules", "items"
	]:
		if not f.has(key):
			push_error("stat_frame: json missing ruled key '" + key + "'")
			return {}
	var formula: Dictionary = f.formula
	var ff := float(formula.get("floor_fraction", -1.0))
	if absf(ff - float(FLOOR_NUM) / float(FLOOR_DEN)) > 0.0001:
		push_error("stat_frame: floor_fraction drifted from the ruled 0.2 — REFUSED")
		return {}
	var speed_rules: Dictionary = f.speed_rules
	if int(speed_rules.get("hard_cap", -1)) != SPEED_HARD_CAP:
		push_error("stat_frame: speed hard_cap drifted from the ruled 115 — REFUSED")
		return {}
	var classes: Dictionary = f.classes
	for cn: StringName in CLASS_IDS:
		if not classes.has(String(cn)):
			push_error("stat_frame: class '" + String(cn) + "' missing — REFUSED")
			return {}
	return f


## docs/22 block 2 — THE damage formula:
## taken = max(attack - armor, ceil(attack * 0.2)). One rounding step,
## ceil in the attacker's favor, integer-exact. 1 defense = 1 less
## damage; no hit ever zeroes; no armor ever makes immune.
static func taken(attack: int, armor: int) -> int:
	return maxi(attack - armor, (attack * FLOOR_NUM + FLOOR_DEN - 1) / FLOOR_DEN)


## Class table for a class id ({} when the frame is absent/legacy).
static func class_data(world: RefCounted, class_id: int) -> Dictionary:
	var f: Dictionary = world.stat_frame
	if f.is_empty() or class_id < 0 or class_id >= CLASS_IDS.size():
		return {}
	var classes: Dictionary = f.classes
	return classes.get(String(CLASS_IDS[class_id]), {})


## docs/22 block 5 — XP to go from `level` to `level + 1`: flat per
## zone, stepping at zone borders, keyed by the DESTINATION level's
## bracket (sums to 20,600 at cap 30). 0 at/after the cap.
static func xp_to_next(world: RefCounted, level: int) -> int:
	var f: Dictionary = world.stat_frame
	if f.is_empty() or level >= LEVEL_CAP:
		return 0
	var dest := level + 1
	var brackets: Array = f.brackets
	var xp: Dictionary = f.xp
	var per_level: Dictionary = xp.per_level
	for b: Dictionary in brackets:
		var levels: Array = b.levels
		if dest >= int(levels[0]) and dest <= int(levels[1]):
			return int(per_level.get(String(b.zone), 0))
	return 0


## docs/22 blocks 3/4 — per-shot damage for a class-backed player firing
## a slice archetype frame: the tier table value plus gear damage mod
## (never below 1). Returns -1 when the frame has no archetype (lab
## frames) — the caller falls back to the legacy lane.
static func tier_damage(world: RefCounted, p: RefCounted, wf: Resource) -> int:
	var arch := String(wf.archetype)
	if arch.is_empty():
		return -1
	var f: Dictionary = world.stat_frame
	if f.is_empty():
		return -1
	var wt: Dictionary = f.weapon_tiers
	var frames: Dictionary = wt.frames
	if not frames.has(arch):
		return -1
	var frame_row: Dictionary = frames[arch]
	var table: Array = frame_row.damage
	var tier: int = clampi(int(p.weapon_tiers[p.equipped_weapon]), 1, table.size())
	return maxi(1, int(table[tier - 1]) + p.damage_mod)


## Recompute every derived stat for a class-backed player from class
## curve x level + armor slot + ring trade (docs/22 blocks 1/4/6/7).
## Called at profile apply, level-up, and equip changes — never per
## tick. Skill points are DERIVED (level - 1 earned, block 5); spend
## state arrives with the slice trees.
static func recompute(world: RefCounted, p: RefCounted) -> void:
	var cls := class_data(world, p.class_id)
	if cls.is_empty():
		return
	var f: Dictionary = world.stat_frame
	var lvl: int = clampi(p.level, 1, LEVEL_CAP)
	# One sanctioned-pair trade sheet (block 7): armor archetypes and
	# rings write into the same seven keys.
	var trades := {}
	for k: String in TRADE_KEYS:
		trades[k] = 0
	if p.ring_index >= 0:
		var items: Array = f.items
		if p.ring_index < items.size():
			var ring: Dictionary = items[p.ring_index]
			if String(ring.get("slot", "")) == "ring" and ring.has("trade"):
				_apply_trade(trades, ring.trade)
	var armor_v := 0
	var armor_hp := 0
	if p.armor_tier > 0:
		var slot: Dictionary = f.armor_slot
		var defense: Array = slot.defense
		var hp_table: Array = slot.hp
		var at: int = clampi(p.armor_tier, 1, defense.size())
		armor_v = int(defense[at - 1])
		armor_hp = int(hp_table[at - 1])
	p.max_hp = maxi(
		1, int(cls.base_hp) + int(cls.hp_per_level) * (lvl - 1) + armor_hp + int(trades.hp)
	)
	p.max_mana = maxi(
		0, int(cls.base_mana) + int(cls.mana_per_level) * (lvl - 1) + int(trades.mana)
	)
	p.armor = maxi(0, armor_v + int(trades.defense))
	p.damage_mod = int(trades.damage)
	p.attack_speed_stat = maxi(10, 100 + int(trades.attack_speed))
	p.range_stat = maxi(10, 100 + int(trades.range))
	# Block 6: gear speed is a STAT trade; the hard cap counts
	# everything combined. The integrator re-applies the cap in t/s so
	# no later write can leak past it.
	var speed_stat: int = mini(int(cls.base_speed) + int(trades.speed), SPEED_HARD_CAP)
	p.move_speed = SPEED_TILES_PER_100 * float(speed_stat) / 100.0
	p.hp = mini(p.hp, p.max_hp)
	p.mana = mini(p.mana, p.max_mana)


static func _apply_trade(trades: Dictionary, t: Dictionary) -> void:
	var up := String(t.get("up", ""))
	var down := String(t.get("down", ""))
	if trades.has(up):
		trades[up] = int(trades[up]) + int(t.get("up_amount", 0))
	if trades.has(down):
		trades[down] = int(trades[down]) - int(t.get("down_amount", 0))
