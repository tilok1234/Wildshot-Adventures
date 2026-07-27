extends RefCounted
## Builds a SimWorld from a ScenarioDef + seed (docs/12 §2.10): the ONE
## construction path main and the reset flow share. Owns the standard
## Phase A loadout (three weapon frames, three test abilities). The
## golden-replay scenario keeps its own code builder in
## tests/replay_fixtures until scenario-data migration (M5 cleanup) —
## regenerating goldens is deliberate, never a side effect of play
## scenarios changing.

const SimWorld := preload("res://sim/sim_world.gd")


static func build_world(scenario: Resource, seed_v: int, bitgrid: RefCounted) -> RefCounted:
	var world := SimWorld.new()
	world.setup(seed_v, bitgrid)
	(
		world
		. set_weapons(
			[
				load("res://data/weapons/longbolt.tres"),
				load("res://data/weapons/scattercast.tres"),
				load("res://data/weapons/wheelblade.tres"),
			]
		)
	)
	(
		world
		. set_abilities(
			[
				load("res://data/abilities/nova_burst.tres"),
				load("res://data/abilities/quickdraw.tres"),
				load("res://data/abilities/blast_rune.tres"),
			]
		)
	)
	# EnemyDef roster — INDEX ORDER IS CONTRACT (def_index serializes):
	# 0=rusher, 1=husk_archer. Append-only; never reorder.
	(
		world
		. set_enemy_defs(
			[
				load("res://data/enemies/rusher.tres"),
				load("res://data/enemies/husk_archer.tres"),
			]
		)
	)
	world.add_player(scenario.player_spawn)
	for p in scenario.standin_positions:
		world.add_enemy_standin(p)
	# Enemy spawns in def-roster order (stable §2.4) — the Dictionary's
	# key order never drives spawn order. Solid-tile spawns are data bugs;
	# fail loudly at build time.
	var spawn_map: Dictionary = scenario.enemy_spawns
	for def_index in world.enemy_defs.size():
		var eid := String(world.enemy_defs[def_index].id)
		var spawns: PackedVector2Array = spawn_map.get(eid, PackedVector2Array())
		for pos in spawns:
			if bitgrid.is_solid(int(floorf(pos.x)), int(floorf(pos.y))):
				push_error(
					(
						"scenario '%s': %s spawn %s is inside a solid tile"
						% [String(scenario.id), eid, pos]
					)
				)
				continue
			world.add_enemy(def_index, pos)
	for eid: String in spawn_map:
		var known := false
		for def: Resource in world.enemy_defs:
			if String(def.id) == eid:
				known = true
				break
		if not known:
			push_error("scenario '%s': unknown enemy id '%s'" % [String(scenario.id), eid])
	return world
