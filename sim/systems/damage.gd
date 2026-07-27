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
	if any_dead:
		world.enemies = world.enemies.filter(func(e: RefCounted) -> bool: return e.hp > 0)
