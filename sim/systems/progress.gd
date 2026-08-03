extends RefCounted
## Progression math, TWO LANES since the stat frame entered the sim
## (docs/22, slice S0 seam 1):
## - LEGACY LANE (class_id -1, every pre-slice scenario and bot world):
##   Loop v1 math from data/progression.tres, byte-identical to SERIAL
##   13/14 behavior — the proof battery and loop_test pin it.
## - CLASS LANE (class_id >= 0, the slice character): docs/22 blocks —
##   stepped XP, class curve growth, tier-table weapon damage, THE
##   damage formula. balance_frame.json is the single tuning source
##   (world.stat_frame, loaded by scenario_loader).
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const SimEvents := preload("res://sim/events.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")


## XP needed to go from `level` to `level + 1`. Legacy: linear ramp
## from progression.tres. Class lane (pass the player's class_id):
## flat per zone, stepping at zone borders (docs/22 block 5).
static func xp_to_next(world: RefCounted, level: int, class_id := -1) -> int:
	if class_id >= 0:
		return StatFrame.xp_to_next(world, level)
	var prog: Resource = world.progression
	return int(prog.xp_base) + int(prog.xp_step) * (level - 1)


## Award kill XP; resolve any level-ups immediately. Both lanes refill
## on level-up ([T], docs/19 feel-first — dying to a fight you just
## leveled in stays a readable death). Class lane: growth = class HP +
## class mana + 1 skill point (derived, level-1), NO automatic damage
## (docs/22 block 5); XP stops at the level cap.
static func award_xp(world: RefCounted, p: RefCounted, amount: int) -> void:
	if amount <= 0 or p.dead or world.progression == null:
		return
	if p.class_id >= 0:
		if p.level >= StatFrame.LEVEL_CAP:
			return
		p.xp += amount
		while p.level < StatFrame.LEVEL_CAP and p.xp >= StatFrame.xp_to_next(world, p.level):
			p.xp -= StatFrame.xp_to_next(world, p.level)
			p.level += 1
			StatFrame.recompute(world, p)
			p.hp = p.max_hp
			p.mana = p.max_mana
			(
				world
				. events
				. append(
					{
						"type": SimEvents.Type.LEVEL_UP,
						"tick": world.tick,
						"player": p.id,
						"level": p.level,
					}
				)
			)
		if p.level >= StatFrame.LEVEL_CAP:
			p.xp = 0
		return
	var prog: Resource = world.progression
	p.xp += amount
	while p.xp >= xp_to_next(world, p.level):
		p.xp -= xp_to_next(world, p.level)
		p.level += 1
		p.max_hp += int(prog.max_hp_per_level)
		p.max_mana += int(prog.mana_per_level)
		p.hp = p.max_hp
		p.mana = p.max_mana
		(
			world
			. events
			. append(
				{
					"type": SimEvents.Type.LEVEL_UP,
					"tick": world.tick,
					"player": p.id,
					"level": p.level,
				}
			)
		)


## Per-shot damage. Class lane firing a slice archetype frame: the
## docs/22 tier table + gear damage mod (tier_damage). Everything else:
## Loop v1 tier/level multipliers on the shot's authored base. Still a
## pure function of player state — the fire path stays RNG-free and
## enemy-blind.
static func shot_damage(world: RefCounted, p: RefCounted, base: int) -> int:
	var prog: Resource = world.progression
	if prog == null:
		return base  # identity for bare test worlds without tables
	if p.class_id >= 0 and not world.weapon_frames.is_empty():
		var wf: Resource = world.weapon_frames[p.equipped_weapon]
		var table_damage := StatFrame.tier_damage(world, p, wf)
		if table_damage >= 0:
			return table_damage
	var tier: int = p.weapon_tiers[p.equipped_weapon]
	var tmult: float = float(prog.tier_damage_mult[tier - 1])
	var lmult: float = 1.0 + float(prog.damage_pct_per_level) * float(p.level - 1) / 100.0
	return roundi(float(base) * tmult * lmult)


## Mitigation for a friendly target (the §2.11 test schedule bypasses
## at the damage path). Class lane: THE docs/22 formula on the derived
## armor VALUE. Legacy lane: the Loop v1 flat table, floor 1 —
## byte-frozen for retired-with-honor content. GEAR SEAM RIDER
## (sl-0177): a legacy-lane actor with a real armor VALUE (the RIFTER
## wearing a helm — apply_to_rift sets p.armor; no other legacy actor
## ever writes it) mitigates through THE formula; armor 0 keeps every
## pre-gear world byte-identical structurally.
static func mitigate(world: RefCounted, a: RefCounted, amount: int) -> int:
	if a.class_id >= 0:
		return StatFrame.taken(amount, a.armor)
	if a.armor > 0:
		return StatFrame.taken(amount, a.armor)
	var at: int = a.armor_tier
	if at <= 0 or world.progression == null:
		return amount
	return maxi(1, amount - int(world.progression.armor_flat_per_tier[at]))
