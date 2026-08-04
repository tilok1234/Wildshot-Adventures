extends RefCounted
## Ordered system (S1 seam 6, sl-0105; REBUILT by sl-0115 STARHOOK v2;
## REBUILT AGAIN by sl-0198 THE FORAGING BUILD — the sl-0168 spec):
## - THE CAST IS INSTANT (unchanged): an INTERACT press within reach of
##   an ACTIVE rift node casts NOW — the cast IS the aggro.
##   CAST_COMPLETE carries rarity (rng_loot) + the node's BIOME + the
##   drawn FIGHT (sl-0180). Authored nodes consume until their respawn
##   timer lands; AMBIENT nodes are consumed away.
## - AMBIENT RIFTS (deck tap shk3spwn): on worlds that opt in
##   (ScenarioDef.rift_ambient), a periodic chance roll spawns a rift
##   on walkable land near a player — rng_misc's first consumer.
##   Tuning: balance_frame.json starhook.ambient [T].
## - THE FORAGE VERB (sl-0198; the sl-0105 stillness verb + anti-AFK
##   rule RETIRED): F at a LIVE forage node starts a short GATHER BAR
##   (bar_ticks [T]); the bar INTERRUPTS on movement or getting hit
##   (the designer's own rider); on completion a LOOT BAG drops from
##   the node (the sl-0129 machinery — walk-over panel + B loot-all)
##   carrying FORAGE kin (species from the node's own prop family,
##   count [T] via rng_loot), and the node is CONSUMED AWAY.
## - AMBIENT FORAGE NODES (sl-0198): the spawner's SECOND rng_misc
##   consumer (fixed draw order: the rift roll first, always). On
##   worlds that opt in (ScenarioDef.forage_ambient), nodes surface ON
##   candidate pool cells (real stump/log/bush props — WYSIWYG) under
##   a world-wide live cap [T]; no per-node respawn timers — the
##   spawner tops the world up elsewhere over time. Tuning:
##   balance_frame.json forage [T].
## Class lane only; pools/nodes are absent in every arena/proof world —
## the battery is inert by construction.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const SimEvents := preload("res://sim/events.gd")
const DropKinds := preload("res://sim/drop_kinds.gd")

## Reach to a marked cell / node (the walk-up class).
const REACH := 1.6
## Rare-catch odds per cast [T] (prototype rareChance 0.2).
const RARE_PERMILLE := 200
## Node respawn after a cast [T] — the lazy-Green site class.
const NODE_RESPAWN_TICKS := 10800
## forage_target sentinel: not gathering (far from anywhere playable).
const NONE := Vector2(-1000000.0, -1000000.0)
## Ambient candidate probes per spawn roll [T] (both consumers).
const AMBIENT_PROBES := 8
## _near_node ambient encoding: ambient j returns -(2 + j).
const AMBIENT_HIT_BASE := -2


static func run(world: RefCounted) -> void:
	if world.rift_ambient:
		_ambient_roll(world)
	if world.forage_ambient:
		_forage_roll(world)
	if (
		world.forage_nodes_pos.is_empty()
		and world.rift_nodes.is_empty()
		and world.rift_ambient_pos.is_empty()
	):
		return
	var frames: Array = world.current_frames
	for i in world.players.size():
		var p: RefCounted = world.players[i]
		if p.class_id < 0 or p.dead:
			continue
		var frame: RefCounted = frames[i] if i < frames.size() else null
		# THE CAST (sl-0115): instant, on the interact edge. Rift nodes
		# WIN the press over forage nodes (deliberate tie order).
		if frame != null and frame.interact_pressed:
			var node := _near_node(world, p.pos)
			if node != -1:
				_cast(world, p, node)
				p.forage_target = NONE
				p.forage_ticks = 0
				continue
			# THE FORAGE PRESS (sl-0198): target the nearest live node.
			var fnode := _near_forage_node(world, p.pos)
			if fnode != -1 and world.forage_nodes_pos[fnode] != p.forage_target:
				p.forage_target = world.forage_nodes_pos[fnode]
				p.forage_ticks = 0
		# THE BAR (sl-0198): advance while still, in reach, unhit.
		if p.forage_target == NONE:
			continue
		var target_i := _forage_node_at(world, p.forage_target)
		var moving: bool = frame != null and (frame.move_x != 0 or frame.move_y != 0)
		if (
			target_i == -1
			or moving
			or p.pos.distance_to(p.forage_target) > REACH
			or _hit_this_tick(world, p)
		):
			p.forage_target = NONE
			p.forage_ticks = 0
			continue
		p.forage_ticks += 1
		if p.forage_ticks < _forage_cfg_i(world, "bar_ticks", 45):
			continue
		_forage_complete(world, p, target_i)


## Completed gather: draw the kin count (rng_loot — fixed order per
## completion), drop ONE loot bag from the node (sl-0129 machinery —
## walk-over panel + B loot-all unchanged), consume the node away,
## emit GATHERED with the species. The spawner re-fills elsewhere.
static func _forage_complete(world: RefCounted, p: RefCounted, node_i: int) -> void:
	var species: int = world.forage_nodes_species[node_i]
	var pos: Vector2 = world.forage_nodes_pos[node_i]
	var ymin := _forage_cfg_i(world, "yield_min", 1)
	var ymax := maxi(ymin, _forage_cfg_i(world, "yield_max", 2))
	var count: int = ymin + world.rng_loot.next_bounded(ymax - ymin + 1)
	world.forage_nodes_pos.remove_at(node_i)
	world.forage_nodes_species.remove_at(node_i)
	world.spawn_loot_bag(pos, PackedInt32Array([DropKinds.FORAGE, species, count]))
	p.forage_target = NONE
	p.forage_ticks = 0
	(
		world
		. events
		. append(
			{
				"type": SimEvents.Type.GATHERED,
				"tick": world.tick,
				"player": p.id,
				"species": species,
				"count": count,
				"pos": pos,
			}
		)
	)


## Did THE damage path land a hit on this player THIS tick? GatherStep
## runs after every damage emitter (projectiles/hazards/contact/rift
## drains), so the tick's own events are complete here. God-absorbed
## hits emit DAMAGE_IMMUNE, not DAMAGE_APPLIED — god runs are dirty
## anyway.
static func _hit_this_tick(world: RefCounted, p: RefCounted) -> bool:
	for ev: Dictionary in world.events:
		if int(ev.type) == SimEvents.Type.DAMAGE_APPLIED and int(ev.get("target", -1)) == p.id:
			return true
	return false


## Nearest LIVE forage node within REACH, else -1.
static func _near_forage_node(world: RefCounted, pos: Vector2) -> int:
	var best := -1
	var best_d := REACH
	var nodes: PackedVector2Array = world.forage_nodes_pos
	for i in nodes.size():
		var d := pos.distance_to(nodes[i])
		if d < best_d:
			best_d = d
			best = i
	return best


## Live node index at EXACTLY this cell (the gather target contract:
## positions are stable identity — consumes remove, spawns append,
## and no two live nodes share a cell). -1 = gone.
static func _forage_node_at(world: RefCounted, cell: Vector2) -> int:
	var nodes: PackedVector2Array = world.forage_nodes_pos
	for i in nodes.size():
		if nodes[i] == cell:
			return i
	return -1


## Periodic ambient FORAGE spawn roll (sl-0198; rng_misc's second
## consumer, always rolled after the rift roll — fixed draw order).
## Under the live cap [T], one chance roll per interval [T]; on a hit,
## up to AMBIENT_PROBES uniform pool draws find a cell with no live
## node on it. The pool is candidacy, never simultaneity.
static func _forage_roll(world: RefCounted) -> void:
	var cfg: Dictionary = world.stat_frame.get("forage", {})
	if cfg.is_empty() or world.forage_pool_cells.is_empty():
		return
	var interval := maxi(1, int(cfg.get("interval_ticks", 300)))
	if world.tick == 0 or world.tick % interval != 0:
		return
	if world.forage_nodes_pos.size() >= int(cfg.get("max_live", 15)):
		return
	var rng: RefCounted = world.rng_misc
	if rng.next_bounded(1000) >= int(cfg.get("chance_permille", 500)):
		return
	for _probe in AMBIENT_PROBES:
		var pi: int = rng.next_bounded(world.forage_pool_cells.size())
		var cell: Vector2 = world.forage_pool_cells[pi]
		if _forage_node_at(world, cell) != -1:
			continue
		var species: int = world.forage_pool_species[pi]
		world.forage_nodes_pos.append(cell)
		world.forage_nodes_species.append(species)
		(
			world
			. events
			. append(
				{
					"type": SimEvents.Type.FORAGE_NODE_SPAWNED,
					"tick": world.tick,
					"pos": cell,
					"species": species,
				}
			)
		)
		return


static func _forage_cfg_i(world: RefCounted, key: String, def: int) -> int:
	return int((world.stat_frame.get("forage", {}) as Dictionary).get(key, def))


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


## Periodic ambient RIFT spawn roll (rng_misc, fixed draw order): under
## the live cap, one chance roll per interval; on a hit, up to
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
