extends RefCounted
## Ordered system: resource regeneration (docs/12 §3.2). Mana 5/s always
## (the CORE-34 ability slot's fuel — primary fire costs nothing, ever);
## HP 5/s out of combat (untouched for 5 s). Integer-deterministic: +1
## every 12 ticks on the global cadence, no accumulators to serialize.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const SimEvents := preload("res://sim/events.gd")

const REGEN_PERIOD := 12  # +1 per 12 ticks = 5/s
const OUT_OF_COMBAT_TICKS := 300  # 5 s untouched
# Caps moved to PlayerState.max_hp/max_mana (Loop v1 level growth,
# SERIAL 13); the v0 sheet's 100/100 are those fields' defaults.


static func run(world: RefCounted) -> void:
	if world.tick % REGEN_PERIOD != 0:
		return
	for p: RefCounted in world.players:
		if p.dead:
			continue
		if p.mana < p.max_mana:
			p.mana += 1
			(
				world
				. events
				. append(
					{
						"type": SimEvents.Type.RESOURCE_REGEN,
						"tick": world.tick,
						"player": p.id,
						"resource": "mana",
						"amount": 1,
						"value": p.mana,
					}
				)
			)
		if p.hp < p.max_hp and world.tick - p.last_damaged_tick >= OUT_OF_COMBAT_TICKS:
			p.hp += 1
			(
				world
				. events
				. append(
					{
						"type": SimEvents.Type.RESOURCE_REGEN,
						"tick": world.tick,
						"player": p.id,
						"resource": "hp",
						"amount": 1,
						"value": p.hp,
					}
				)
			)
