extends RefCounted
## Ordered system (S1 seam 6, sl-0105; REBUILT by sl-0115 STARHOOK v2 —
## prototype #2 rules the shape):
## - THE CAST IS INSTANT: an INTERACT press within reach of an ACTIVE
##   rift node casts NOW — the cast IS the aggro (no stillness, no
##   bite-wait; the prototype's own supersession). CAST_COMPLETE
##   carries rarity (rng_loot) + the node's BIOME; the driver runs the
##   rift transition like a Warren door. Authored nodes consume until
##   their respawn timer lands; AMBIENT nodes are consumed away.
## - AMBIENT RIFTS (deck tap shk3spwn): on worlds that opt in
##   (ScenarioDef.rift_ambient), a periodic chance roll spawns a rift
##   on walkable land near a player — rng_misc's first consumer.
##   Tuning lives in balance_frame.json starhook.ambient [T].
## - FORAGING (unchanged): stand STILL within reach of a forage cell
##   for 90 ticks -> a small honest yield (1-2 gold + 2 xp [T] via
##   rng_loot); ANTI-AFK: re-arms only after a 4-tile walk.
## Class lane only; masks/nodes are absent in every arena/proof world —
## the battery is inert by construction.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const SimEvents := preload("res://sim/events.gd")
const Progress := preload("res://sim/systems/progress.gd")

const FORAGE_TICKS := 90
## Reach to a marked cell / node (the walk-up class).
const REACH := 1.6
## Walk this far from the last forage yield to re-arm [T].
const REARM_DIST := 4.0
## Node respawn after a cast [T] — the lazy-Green site class.
const NODE_RESPAWN_TICKS := 10800
## Rare-catch odds per cast [T] (prototype rareChance 0.2).
const RARE_PERMILLE := 200
## gather_rearm sentinel: "armed" (far from anywhere playable).
const ARMED := Vector2(-1000000.0, -1000000.0)
## Ambient-node candidate probes per spawn roll [T].
const AMBIENT_PROBES := 8
## _near_node ambient encoding: ambient j returns -(2 + j).
const AMBIENT_HIT_BASE := -2


static func run(world: RefCounted) -> void:
	if world.rift_ambient:
		_ambient_roll(world)
	if (
		world.forage_grid == null
		and world.rift_nodes.is_empty()
		and world.rift_ambient_pos.is_empty()
	):
		return
	var frames: Array = world.current_frames
	for i in world.players.size():
		var p: RefCounted = world.players[i]
		if p.class_id < 0 or p.dead:
			continue
		if p.gather_rearm != ARMED and p.pos.distance_to(p.gather_rearm) >= REARM_DIST:
			p.gather_rearm = ARMED
		var frame: RefCounted = frames[i] if i < frames.size() else null
		# THE CAST (sl-0115): instant, on the interact edge.
		if frame != null and frame.interact_pressed:
			var node := _near_node(world, p.pos)
			if node != -1:
				_cast(world, p, node)
				p.gather_still_ticks = 0
				continue
		# FORAGING: the patience verb, unchanged.
		var moving: bool = frame == null or frame.move_x != 0 or frame.move_y != 0
		if moving:
			p.gather_still_ticks = 0
			continue
		var near_forage: bool = p.gather_rearm == ARMED and _near_forage(world, p.pos)
		if not near_forage:
			p.gather_still_ticks = 0
			continue
		p.gather_still_ticks += 1
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


## Consume the node, draw rarity, then THE FIGHT (sl-0180: the boss
## pool — a weighted per-biome draw appended to the cast's fixed
## rng_loot sequence; "catch" = the standard fish fight; unknown or
## absent pools fall back to catch FAIL-SAFE, and balance_calc GATE 7
## validates the tables). Emit CAST_COMPLETE with biome + fight.
## Authored nodes (index >= 0) re-arm on a timer; ambient nodes
## (encoded < -1) are removed — new ones keep surfacing.
static func _cast(world: RefCounted, p: RefCounted, node: int) -> void:
	var biome := 0
	var pos: Vector2
	if node >= 0:
		world.rift_node_respawn_at[node] = world.tick + NODE_RESPAWN_TICKS
		biome = world.rift_node_biomes[node] if node < world.rift_node_biomes.size() else 0
		pos = world.rift_nodes[node]
	else:
		var j := -node + AMBIENT_HIT_BASE
		biome = world.rift_ambient_biome[j]
		pos = world.rift_ambient_pos[j]
		world.rift_ambient_pos.remove_at(j)
		world.rift_ambient_biome.remove_at(j)
	var rare: bool = world.rng_loot.next_bounded(1000) < RARE_PERMILLE
	var fight := _draw_fight(world, biome, rare)
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
				"biome": biome,
				"fight": fight,
				"pos": pos,
			}
		)
	)


## The weighted fight draw (ONE rng_loot draw whenever a non-empty
## pool exists — the sequence stays fixed per cast). BIOME_KEYS order
## is the starhook.biomes contract (0 nebula / 1 void / 2 comet).
const BIOME_KEYS: Array[String] = ["nebula", "void", "comet"]


static func _draw_fight(world: RefCounted, biome: int, rare: bool) -> String:
	var pools: Dictionary = world.stat_frame.get("starhook", {}).get("fight_pool", {})
	var bkey := BIOME_KEYS[biome] if biome >= 0 and biome < BIOME_KEYS.size() else ""
	var pool_v: Variant = (pools.get(bkey, {}) as Dictionary).get("rare" if rare else "common", [])
	if not pool_v is Array or (pool_v as Array).is_empty():
		return "catch"
	var pool: Array = pool_v
	var total := 0
	for row_v: Variant in pool:
		total += maxi(0, int((row_v as Dictionary).get("w", 0)))
	if total <= 0:
		return "catch"
	var roll: int = world.rng_loot.next_bounded(total)
	var acc := 0
	for row_v: Variant in pool:
		var row: Dictionary = row_v
		acc += maxi(0, int(row.get("w", 0)))
		if roll < acc:
			return String(row.get("fight", "catch"))
	return "catch"


## Periodic ambient spawn roll (rng_misc, fixed draw order): under the
## live cap, one chance roll per interval; on a hit, up to
## AMBIENT_PROBES candidate cells in a ring around a drawn player —
## walkable on the conservative bitgrid, clear of every existing node.
static func _ambient_roll(world: RefCounted) -> void:
	var sh: Dictionary = world.stat_frame.get("starhook", {})
	var amb: Dictionary = sh.get("ambient", {})
	if amb.is_empty() or world.players.is_empty():
		return
	var interval := maxi(1, int(amb.get("interval_ticks", 900)))
	if world.tick == 0 or world.tick % interval != 0:
		return
	if world.rift_ambient_pos.size() >= int(amb.get("max_live", 3)):
		return
	var rng: RefCounted = world.rng_misc
	if rng.next_bounded(1000) >= int(amb.get("chance_permille", 220)):
		return
	var anchor: RefCounted = world.players[rng.next_bounded(world.players.size())]
	var ring_min := float(amb.get("ring_min", 10.0))
	var ring_max := float(amb.get("ring_max", 22.0))
	var min_dist := float(amb.get("min_node_dist", 8.0))
	for _probe in AMBIENT_PROBES:
		var ang := float(rng.next_bounded(3600)) * TAU / 3600.0
		var radius: float = ring_min + float(rng.next_unit()) * (ring_max - ring_min)
		var apos: Vector2 = anchor.pos + Vector2(cos(ang), sin(ang)) * radius
		var cell := Vector2(floorf(apos.x) + 0.5, floorf(apos.y) + 0.5)
		if world.bitgrid.is_solid(int(floorf(cell.x)), int(floorf(cell.y))):
			continue
		if not _clear_of_nodes(world, cell, min_dist):
			continue
		var biome: int = rng.next_bounded(3)
		world.rift_ambient_pos.append(cell)
		world.rift_ambient_biome.append(biome)
		(
			world
			. events
			. append(
				{
					"type": SimEvents.Type.RIFT_NODE_SPAWNED,
					"tick": world.tick,
					"pos": cell,
					"biome": biome,
				}
			)
		)
		return


static func _clear_of_nodes(world: RefCounted, pos: Vector2, min_dist: float) -> bool:
	for n in world.rift_nodes:
		if pos.distance_to(n) < min_dist:
			return false
	for n in world.rift_ambient_pos:
		if pos.distance_to(n) < min_dist:
			return false
	return true


## Nearest ACTIVE rift node within REACH: authored index >= 0, ambient
## encoded -(2 + j), -1 = none. Authored nodes win ties (stable order:
## authored list first, then ambient list).
static func _near_node(world: RefCounted, pos: Vector2) -> int:
	var best := -1
	var best_d := REACH
	var nodes: PackedVector2Array = world.rift_nodes
	for i in nodes.size():
		if world.tick < world.rift_node_respawn_at[i]:
			continue
		var d := pos.distance_to(nodes[i])
		if d < best_d:
			best_d = d
			best = i
	for j in world.rift_ambient_pos.size():
		var d2 := pos.distance_to(world.rift_ambient_pos[j])
		if d2 < best_d:
			best_d = d2
			best = AMBIENT_HIT_BASE - j
	return best


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
