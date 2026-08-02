extends RefCounted
## Builds a SimWorld from a ScenarioDef + seed (docs/12 §2.10): the ONE
## construction path main and the reset flow share. Owns the standard
## Phase A loadout (three weapon frames, three test abilities). The
## golden-replay scenario keeps its own code builder in
## tests/replay_fixtures until scenario-data migration (M5 cleanup) —
## regenerating goldens is deliberate, never a side effect of play
## scenarios changing.

const SimWorld := preload("res://sim/sim_world.gd")
const PropColliders := preload("res://game/arena/prop_colliders.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const ContentImporter := preload("res://game/arena/content_importer.gd")


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
	# Loop v1 (docs/19): progression tables + unique defs ride every
	# world like the weapon/ability defs — definitions, not state.
	world.set_progression(load("res://data/progression.tres"))
	# Unique defs — mask-bit order is append-only (0 = the loop coil,
	# 1 = Old Tusk's Hide, S1 seam 3).
	(
		world
		. set_uniques(
			[
				load("res://data/uniques/reliquary_coil.tres"),
				load("res://data/uniques/old_tusks_hide.tres"),
			]
		)
	)
	# THE STAT FRAME (docs/22, slice S0): balance_frame.json rides every
	# world as definitions. Inert for class_id -1 players — bot and
	# legacy worlds stay byte-identical with it aboard.
	world.set_stat_frame(StatFrame.load_frame())
	# EnemyDef roster — INDEX ORDER IS CONTRACT (def_index serializes):
	# 0=rusher, 1=husk_archer, 2=fanmaw, 3=ringer, 4=leadshot,
	# 5=blightcaster, 6=yard_warden (§3.5 elite), 7=bone_reliquary_king
	# (Loop v1 first boss, docs/19 ruling 4 — the Warden kit at 900 HP
	# [T]). S1 GREEN ROSTER (sl-0104 seam 1, docs/23 family order):
	# 8=slime, 9=goblin, 10=boar, 11=wolf, 12=bat, 13=shroom, 14=wasp,
	# 15=beetle, 16=moth, 17=snail, 18=porcupine, 19=scarecrow,
	# 20=treant, 21=bandit, 22=old_tusk (S1 seam 3 — Green's world
	# boss), 23=king_grubb (S1 seam 4 — the Warren's bottom).
	# Append-only; never reorder. Scenario extras (bot canaries)
	# append after, keeping standard indexes stable.
	var defs: Array = [
		load("res://data/enemies/rusher.tres"),
		load("res://data/enemies/husk_archer.tres"),
		load("res://data/enemies/fanmaw.tres"),
		load("res://data/enemies/ringer.tres"),
		load("res://data/enemies/leadshot.tres"),
		load("res://data/enemies/blightcaster.tres"),
		load("res://data/enemies/yard_warden.tres"),
		load("res://data/enemies/bone_reliquary_king.tres"),
		load("res://data/enemies/slime.tres"),
		load("res://data/enemies/goblin.tres"),
		load("res://data/enemies/boar.tres"),
		load("res://data/enemies/wolf.tres"),
		load("res://data/enemies/bat.tres"),
		load("res://data/enemies/shroom.tres"),
		load("res://data/enemies/wasp.tres"),
		load("res://data/enemies/beetle.tres"),
		load("res://data/enemies/moth.tres"),
		load("res://data/enemies/snail.tres"),
		load("res://data/enemies/porcupine.tres"),
		load("res://data/enemies/scarecrow.tres"),
		load("res://data/enemies/treant.tres"),
		load("res://data/enemies/bandit.tres"),
		load("res://data/enemies/old_tusk.tres"),
		load("res://data/enemies/king_grubb.tres"),
	]
	for extra: Resource in scenario.extra_enemy_defs:
		defs.append(extra)
	world.set_enemy_defs(defs)
	world.set_damage_schedule(scenario.damage_schedule)
	# CORE-43 (seam 3): the settlement respawn point = the scenario's
	# spawn. persistent_respawn itself is armed by main once the
	# PROFILE is known (normal-mode character in a persistent-world
	# scenario) — bot and replay builds stay dead-in-place.
	world.respawn_cell = scenario.player_spawn
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
	# Living-world sites (docs/23 S0, seam 2): the content pack's
	# territories + placements become leash-gated spawn tables; initial
	# populations draw here (setup-phase, before the recorder snapshot).
	# A refused pack errors loudly — never a quietly dead world.
	if not String(scenario.content_pack).is_empty():
		var imported := ContentImporter.build_sites(String(scenario.content_pack))
		if bool(imported.ok):
			world.set_site_defs(imported.sites)
		else:
			push_error(
				(
					"scenario '%s': content pack refused (%s)"
					% [String(scenario.id), String(scenario.content_pack)]
				)
			)
	# sl-0078 fit rule: pack scenarios attach art-matched prop discs +
	# the walk grid HERE — the one construction path main, DodgeBot,
	# soak, and replay verification share, so player and bot walk
	# byte-identical collision by construction. No-op when packless.
	PropColliders.attach(world, scenario)
	return world
