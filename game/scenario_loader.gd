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
const GatherGrids := preload("res://game/arena/gather_grids.gd")


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
	# 1 = Old Tusk's Hide, 2 = the Starlit Cast cosmetic, sl-0105).
	(
		world
		. set_uniques(
			[
				load("res://data/uniques/reliquary_coil.tres"),
				load("res://data/uniques/old_tusks_hide.tres"),
				load("res://data/uniques/starlit_skin.tres"),
			]
		)
	)
	# THE STAT FRAME (docs/22, slice S0): balance_frame.json rides every
	# world as definitions. Inert for class_id -1 players — bot and
	# legacy worlds stay byte-identical with it aboard.
	world.set_stat_frame(StatFrame.load_frame())
	# GENERIC QUESTS v1 (S1 seam 5) — the Green five, APPEND-ONLY
	# (mask bits + profile ids key on this order). Inert for legacy
	# players; giver cells sit far from every battery spawn.
	(
		world
		. set_quests(
			[
				load("res://data/quests/green_cull.tres"),
				load("res://data/quests/green_mud_pocket.tres"),
				load("res://data/quests/green_west_road.tres"),
				load("res://data/quests/green_provisions.tres"),
				load("res://data/quests/green_far_field.tres"),
			]
		)
	)
	# EnemyDef roster — INDEX ORDER IS CONTRACT (def_index serializes):
	# 0=rusher, 1=husk_archer, 2=fanmaw, 3=ringer, 4=leadshot,
	# 5=blightcaster, 6=yard_warden (§3.5 elite), 7=bone_reliquary_king
	# (Loop v1 first boss, docs/19 ruling 4 — the Warden kit at 900 HP
	# [T]). S1 GREEN ROSTER (sl-0104 seam 1, docs/23 family order):
	# 8=slime, 9=goblin, 10=boar, 11=wolf, 12=bat, 13=shroom, 14=wasp,
	# 15=beetle, 16=moth, 17=snail, 18=porcupine, 19=scarecrow,
	# 20=treant, 21=bandit, 22=old_tusk (S1 seam 3 — Green's world
	# boss), 23=king_grubb (S1 seam 4 — the Warren's bottom),
	# 24=rift_catch, 25=rift_catch_rare (S1 seam 6 — STARHOOK,
	# sl-0105). Append-only; never reorder. Scenario extras (bot
	# canaries) append after, keeping standard indexes stable.
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
		load("res://data/enemies/rift_catch.tres"),
		load("res://data/enemies/rift_catch_rare.tres"),
		load("res://data/enemies/rift_catch_void.tres"),
		load("res://data/enemies/rift_catch_void_rare.tres"),
		load("res://data/enemies/rift_catch_comet.tres"),
		load("res://data/enemies/rift_catch_comet_rare.tres"),
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
	# sl-0130: the settlement bank station (ZERO = none).
	world.bank_cell = scenario.bank_cell
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
	# S1 seam 6: the forage mask (pack worlds only — WYSIWYG species
	# cells) + the scenario's authored rift nodes (sl-0105; biomes
	# ride parallel since sl-0115).
	if not String(scenario.worldforge_pack).is_empty():
		var gathered := GatherGrids.derive(
			ContentImporter.resolve_src(String(scenario.worldforge_pack))
		)
		if bool(gathered.ok):
			world.set_forage_grid(gathered.forage)
	world.set_rift_nodes(scenario.rift_nodes, scenario.rift_node_biomes)
	world.rift_ambient = bool(scenario.rift_ambient)
	# STARHOOK v2 (sl-0115; drag cut by sl-0123): rift-fight scenarios
	# attach the LINE rules + the FULL ROD LADDER (level-gated in
	# player_fire) here, in the ONE construction path — bot, replay,
	# and profile-free runs fight the same fight by construction. Loud
	# refusals: a rift scenario with a broken line def or a malformed
	# biome table must never build a quietly wrong arena.
	if bool(scenario.starhook_rift):
		var line: Resource = null
		if not String(scenario.rift_line).is_empty():
			line = load(String(scenario.rift_line))
		if line == null or int(line.lives) < 1 or float(line.passive_drain_per_sec) < 0.0:
			push_error(
				(
					"scenario '%s': rift_line missing or malformed (%s) — REFUSED"
					% [String(scenario.id), String(scenario.rift_line)]
				)
			)
			return world
		var sh: Dictionary = world.stat_frame.get("starhook", {})
		var rods: Array = sh.get("rods", [])
		var biomes: Array = sh.get("biomes", [])
		if rods.is_empty() or not _biomes_valid(biomes):
			push_error(
				(
					"scenario '%s': starhook rods/biomes table malformed — REFUSED"
					% String(scenario.id)
				)
			)
			return world
		var rod_frames: Array = []
		var unlocks := PackedInt32Array()
		for rod: Dictionary in rods:
			var rod_path := "res://data/weapons/%s.tres" % String(rod.get("id", ""))
			var rf: Resource = load(rod_path)
			if rf == null:
				push_error("scenario '%s': rod frame missing: %s" % [String(scenario.id), rod_path])
				return world
			rod_frames.append(rf)
			unlocks.append(int(rod.get("unlock_level", 99)))
		world.set_weapons(rod_frames)
		for p: RefCounted in world.players:
			p.weapon_tiers = PackedInt32Array()
			p.weapon_tiers.resize(rod_frames.size())
			p.weapon_tiers.fill(1)
		world.set_rift_config(line, int(scenario.rift_biome), bool(scenario.rift_rare), unlocks)
	return world


## The biome-table shape the sim trusts (damage.gd fish draw): three
## biomes, each with exactly three weighted commons summing 100 and a
## named rare. Anything else is a refusal at build time.
static func _biomes_valid(biomes: Array) -> bool:
	if biomes.size() != 3:
		return false
	for b: Variant in biomes:
		if not b is Dictionary:
			return false
		var fish: Array = (b as Dictionary).get("fish", [])
		if fish.size() != 3:
			return false
		var total := 0
		for f: Variant in fish:
			if not f is Dictionary or String((f as Dictionary).get("id", "")).is_empty():
				return false
			total += int((f as Dictionary).get("w", 0))
		if total != 100:
			return false
		var rare: Dictionary = (b as Dictionary).get("rare", {})
		if String(rare.get("id", "")).is_empty():
			return false
	return true
