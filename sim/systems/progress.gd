extends RefCounted
## Loop v1 progression math (docs/19 §3): kill XP → levels → lean-sheet
## growth, and the tier/level damage scaling the fire path applies. All
## curve numbers live in data/progression.tres ([T] — designer tunes in
## play); this module is the ONE place they turn into sim effects.
## Defaults are identity: level 1 + tier 1 reproduce pre-loop damage and
## caps exactly, so every existing proof stays byte-identical.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const SimEvents := preload("res://sim/events.gd")


## XP needed to go from `level` to `level + 1` (linear ramp, [T]).
static func xp_to_next(world: RefCounted, level: int) -> int:
	var prog: Resource = world.progression
	return int(prog.xp_base) + int(prog.xp_step) * (level - 1)


## Award kill XP; resolve any level-ups immediately. Level-up grows the
## lean sheet (max hp/mana) and refills both — dying to a fight you just
## leveled in is a readable death, not an attrition artifact, and the
## refill is the retry-pull-positive choice ([T], docs/19 feel-first).
static func award_xp(world: RefCounted, p: RefCounted, amount: int) -> void:
	if amount <= 0 or p.dead or world.progression == null:
		return
	p.xp += amount
	var prog: Resource = world.progression
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


## Per-shot damage through the tier multiplier (equipped frame's tier)
## and the level multiplier. Pure function of (player, base) — the fire
## path stays RNG-free and enemy-blind.
static func shot_damage(world: RefCounted, p: RefCounted, base: int) -> int:
	var prog: Resource = world.progression
	if prog == null:
		return base  # identity for bare test worlds without tables
	var tier: int = p.weapon_tiers[p.equipped_weapon]
	var tmult: float = float(prog.tier_damage_mult[tier - 1])
	var lmult: float = 1.0 + float(prog.damage_pct_per_level) * float(p.level - 1) / 100.0
	return roundi(float(base) * tmult * lmult)


## Flat armor reduction for a friendly target ([T] table; the §2.11 test
## schedule bypasses this at the damage path — mitigation-bypassing by
## contract). Never reduces a real hit below 1.
static func mitigate(world: RefCounted, a: RefCounted, amount: int) -> int:
	var at: int = a.armor_tier
	if at <= 0 or world.progression == null:
		return amount
	return maxi(1, amount - int(world.progression.armor_flat_per_tier[at]))
