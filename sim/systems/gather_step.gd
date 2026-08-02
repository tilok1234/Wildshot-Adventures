extends RefCounted
## Ordered system (S1 seam 6, sl-0105): the PATIENCE verbs — no new
## inputs, CORE-48 no automation.
## - THE CAST (STARHOOK): stand STILL within reach of an ACTIVE rift
##   node for 120 ticks -> CAST_COMPLETE (the driver runs the rift
##   transition like a Warren door) + the node is CONSUMED until its
##   respawn timer lands ([T] — nodes are the anti-repeat; no rearm
##   walk needed). Rarity draws from rng_loot at the cast tick
##   (deterministic, replay-honest).
## - FORAGING: stand STILL within reach of a forage cell for 90 ticks
##   -> a small honest yield in-sim (1-2 gold + 2 xp [T] via
##   rng_loot); ANTI-AFK: the verb re-arms only after a 4-tile walk —
##   standing forever earns exactly one yield.
## Nodes take priority over forage where both are near. Class lane
## only; masks/nodes are absent in every arena/proof world — the
## battery is inert by construction.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const SimEvents := preload("res://sim/events.gd")
const Progress := preload("res://sim/systems/progress.gd")

const CAST_TICKS := 120
const FORAGE_TICKS := 90
## Reach to a marked cell / node (the walk-up class).
const REACH := 1.6
## Walk this far from the last forage yield to re-arm [T].
const REARM_DIST := 4.0
## Node respawn after a cast [T] — the lazy-Green site class.
const NODE_RESPAWN_TICKS := 10800
## Rare-catch odds per cast [T].
const RARE_PERMILLE := 200
## gather_rearm sentinel: "armed" (far from anywhere playable).
const ARMED := Vector2(-1000000.0, -1000000.0)


static func run(world: RefCounted) -> void:
	if world.forage_grid == null and world.rift_nodes.is_empty():
		return
	var frames: Array = world.current_frames
	for i in world.players.size():
		var p: RefCounted = world.players[i]
		if p.class_id < 0 or p.dead:
			continue
		if p.gather_rearm != ARMED and p.pos.distance_to(p.gather_rearm) >= REARM_DIST:
			p.gather_rearm = ARMED
		var frame: RefCounted = frames[i] if i < frames.size() else null
		var moving: bool = frame == null or frame.move_x != 0 or frame.move_y != 0
		if moving:
			p.gather_still_ticks = 0
			continue
		var node := _near_node(world, p.pos)
		var near_forage: bool = node < 0 and p.gather_rearm == ARMED and _near_forage(world, p.pos)
		if node < 0 and not near_forage:
			p.gather_still_ticks = 0
			continue
		p.gather_still_ticks += 1
		if node >= 0:
			if p.gather_still_ticks < CAST_TICKS:
				continue
			p.gather_still_ticks = 0
			world.rift_node_respawn_at[node] = world.tick + NODE_RESPAWN_TICKS
			var rare: bool = world.rng_loot.next_bounded(1000) < RARE_PERMILLE
			(
				world
				. events
				. append(
					{
						"type": SimEvents.Type.CAST_COMPLETE,
						"tick": world.tick,
						"player": p.id,
						"node": node,
						"rare": rare,
						"pos": p.pos,
					}
				)
			)
		else:
			if p.gather_still_ticks < FORAGE_TICKS:
				continue
			p.gather_still_ticks = 0
			p.gather_rearm = p.pos
			var gold: int = 1 + world.rng_loot.next_bounded(2)
			p.gold += gold
			Progress.award_xp(world, p, 2)
			(
				world
				. events
				. append(
					{
						"type": SimEvents.Type.GATHERED,
						"tick": world.tick,
						"player": p.id,
						"gold": gold,
						"xp": 2,
						"pos": p.pos,
					}
				)
			)


## Index of an ACTIVE rift node within REACH, else -1.
static func _near_node(world: RefCounted, pos: Vector2) -> int:
	var nodes: PackedVector2Array = world.rift_nodes
	for i in nodes.size():
		if world.tick < world.rift_node_respawn_at[i]:
			continue
		if pos.distance_to(nodes[i]) <= REACH:
			return i
	return -1


## True when any forage cell in the 5x5 neighborhood is within REACH.
static func _near_forage(world: RefCounted, pos: Vector2) -> bool:
	var grid: RefCounted = world.forage_grid
	if grid == null:
		return false
	var cx := int(floorf(pos.x))
	var cy := int(floorf(pos.y))
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var x := cx + dx
			var y := cy + dy
			if x < 0 or y < 0:
				continue
			if not grid.is_solid(x, y):
				continue
			if pos.distance_to(Vector2(float(x) + 0.5, float(y) + 0.5)) <= REACH:
				return true
	return false
