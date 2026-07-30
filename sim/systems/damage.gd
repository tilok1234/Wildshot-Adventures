extends RefCounted
## THE damage-resolution path (docs/12 §2.1): every hit point flowing to any
## actor — projectile, hazard, ability, contact — lands through apply(), so
## god-mode visibility, player death-in-place, and the event trail are
## uniform by construction. Extracted at M5 from projectile_step/hazard_step
## (which had grown twin inline copies) before enemy contact damage added a
## third. Event order per damaging hit is preserved exactly:
## [ENTITY_KILLED(player)] -> [HIT_LANDED if projectile] -> DAMAGE_APPLIED.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const ActorState := preload("res://sim/actor_state.gd")
const SimEvents := preload("res://sim/events.gd")
const Progress := preload("res://sim/systems/progress.gd")


## Apply `amount` to actor `a`. hit_slot >= 0 marks a projectile hit and
## emits HIT_LANDED with that pool slot. God flag (§2.10): friendly damage
## becomes a visible DAMAGE_IMMUNE — logged, never silent, so god use can't
## launder into evidence.
static func apply(
	world: RefCounted, a: RefCounted, amount: int, pattern: int, hit_slot := -1
) -> void:
	var t: int = world.tick
	var events: Array[Dictionary] = world.events
	if world.god_mode and a.faction == ActorState.FACTION_FRIENDLY:
		(
			events
			. append(
				{
					"type": SimEvents.Type.DAMAGE_IMMUNE,
					"tick": t,
					"target": a.id,
					"amount": amount,
					"pattern": pattern,
					"pos": a.pos,
				}
			)
		)
		return
	# Loop v1 armor (docs/19, CORE-40 lean defense): flat mitigation for
	# friendly targets through THE path — every source uniform. The §2.11
	# test schedule bypasses it by contract (mitigation-bypassing tag).
	if a.faction == ActorState.FACTION_FRIENDLY and pattern != world.PATTERN_TEST_SCHEDULE:
		amount = Progress.mitigate(world, a, amount)
	a.hp -= amount
	a.last_damaged_tick = t
	# Player death: dies in place (recap + restart own the flow); enemy
	# death stays with the sweep.
	if a.hp <= 0 and a.faction == ActorState.FACTION_FRIENDLY and not a.dead:
		a.hp = 0
		a.dead = true
		(
			events
			. append(
				{
					"type": SimEvents.Type.ENTITY_KILLED,
					"tick": t,
					"id": a.id,
					"pos": a.pos,
					"player": true,
				}
			)
		)
	if hit_slot >= 0:
		(
			events
			. append(
				{
					"type": SimEvents.Type.HIT_LANDED,
					"tick": t,
					"slot": hit_slot,
					"target": a.id,
					"damage": amount,
					"pattern": pattern,
					"pos": a.pos,
				}
			)
		)
	(
		events
		. append(
			{
				"type": SimEvents.Type.DAMAGE_APPLIED,
				"tick": t,
				"target": a.id,
				"amount": amount,
				"hp": a.hp,
				"pattern": pattern,
				"pos": a.pos,
			}
		)
	)


## The resolution path's tail: emit enemy kills (with def_index + TTK for
## the §2.10 telemetry — CORE-36's honest-health evidence), then compact.
## Players are never removed here (they die in place, flagged).
static func sweep_dead_enemies(world: RefCounted) -> void:
	var t: int = world.tick
	var any_dead := false
	for e: RefCounted in world.enemies:
		if e.hp <= 0:
			any_dead = true
			(
				world
				. events
				. append(
					{
						"type": SimEvents.Type.ENTITY_KILLED,
						"tick": t,
						"id": e.id,
						"pos": e.pos,
						"def_index": e.def_index,
						"ttk_ticks": t - e.spawned_at_tick,
					}
				)
			)
			_award_kill(world, e)
	if any_dead:
		world.enemies = world.enemies.filter(func(e: RefCounted) -> bool: return e.hp > 0)


## Loop v1 kill awards (docs/19): XP to every player, then the drop
## rolls — ONE fixed rng_loot draw sequence per kill (gold, item chance,
## kind, params, then each unique in table order), so loot is exactly as
## deterministic as everything else (§2.4). Defs whose drop fields sit
## at defaults draw only what their data enables — a def with no gold,
## no chance, and no uniques draws NOTHING, keeping pre-loop scenarios
## byte-identical.
static func _award_kill(world: RefCounted, e: RefCounted) -> void:
	var di: int = e.def_index
	if di < 0 or di >= world.enemy_defs.size():
		return
	var def: Resource = world.enemy_defs[di]
	var xp := int(def.xp_value)
	if xp > 0:
		for p: RefCounted in world.players:
			Progress.award_xp(world, p, xp)
	var rng: RefCounted = world.rng_loot
	if int(def.gold_max) > 0:
		var amt: int = (
			int(def.gold_min) + rng.next_bounded(int(def.gold_max) - int(def.gold_min) + 1)
		)
		if amt > 0:
			world.spawn_drop(e.pos, world.DROP_GOLD, amt)
	if float(def.drop_chance) > 0.0 and rng.next_unit() < float(def.drop_chance):
		var ww := int(def.drop_w_weapon)
		var wa := int(def.drop_w_armor)
		var wb := int(def.drop_w_ability)
		var total := ww + wa + wb
		if total > 0:
			var roll: int = rng.next_bounded(total)
			var tier: int = (
				int(def.drop_tier_min)
				+ rng.next_bounded(int(def.drop_tier_max) - int(def.drop_tier_min) + 1)
			)
			if roll < ww:
				world.spawn_drop(
					e.pos, world.DROP_WEAPON, rng.next_bounded(world.weapon_frames.size()), tier
				)
			elif roll < ww + wa:
				world.spawn_drop(e.pos, world.DROP_ARMOR, tier)
			else:
				world.spawn_drop(
					e.pos, world.DROP_ABILITY, rng.next_bounded(world.ability_defs.size())
				)
	var uniques: Array = def.unique_drops
	for ui in uniques.size():
		if rng.next_unit() < float(def.unique_chances[ui]):
			var idx: int = world.unique_defs.find(uniques[ui])
			if idx >= 0:
				world.spawn_drop(e.pos, world.DROP_UNIQUE, idx)
