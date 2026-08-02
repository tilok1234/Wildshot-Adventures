extends RefCounted
## The pure sim core (docs/12 §2.1): owns ALL gameplay state — actors,
## SoA projectile pool, RNG streams, tick counter — mutated only by ordered
## systems inside step(). No Nodes, no Godot physics, no engine clock: DT is
## a compile-time constant and the integer tick is the only clock (CORE-32,
## CORE-31). Drivers step it; views read state + events and never mutate.
##
## players is an ARRAY (GDD-16 co-op insurance) — zero player singletons or
## get_player() globals anywhere; anything that needs players reads this list.
##
## Setup-phase mutators (setup/add_player/add_enemy_standin) build the
## scenario BEFORE the first step. Mid-run mutation from outside enters only
## through enqueue_command(), drained at the top of the next step.

const Pcg32 := preload("res://sim/pcg32.gd")
const DropKinds := preload("res://sim/drop_kinds.gd")
const ActorState := preload("res://sim/actor_state.gd")
const PlayerState := preload("res://sim/player_state.gd")
const EnemyState := preload("res://sim/enemy_state.gd")
const ProjectilePool := preload("res://sim/projectile_pool.gd")
const SimEvents := preload("res://sim/events.gd")
const PlayerMove := preload("res://sim/systems/player_move.gd")
const PlayerRegen := preload("res://sim/systems/player_regen.gd")
const PlayerRespawn := preload("res://sim/systems/player_respawn.gd")
const PlayerAbility := preload("res://sim/systems/player_ability.gd")
const PlayerFire := preload("res://sim/systems/player_fire.gd")
const EnemyStep := preload("res://sim/systems/enemy_step.gd")
const SiteStep := preload("res://sim/systems/site_step.gd")
const ProjectileStep := preload("res://sim/systems/projectile_step.gd")
const HazardStep := preload("res://sim/systems/hazard_step.gd")
const LootStep := preload("res://sim/systems/loot_step.gd")
const GatherStep := preload("res://sim/systems/gather_step.gd")
const QuestStep := preload("res://sim/systems/quest_step.gd")
const RiftStep := preload("res://sim/systems/rift_step.gd")
const Damage := preload("res://sim/systems/damage.gd")

const TICKS_PER_SECOND := 60
const DT := 1.0 / 60.0
## 17 = overworld death (slice S0 seam 3, sl-0100; CORE-43): in-sim
## gold cost + settlement respawn timer for class-backed players in
## persistent worlds (PlayerState.respawn_at_tick). Inert everywhere
## persistent_respawn is off — every proof world. 16 = living-world
## sites (seam 2); 15 = docs/22 stat frame (seam 1). 18 = S1 seam 3:
## PlayerState.armor_item_index (unique armor — Old Tusk's Hide).
## 19 = S1 seam 5: quest fields (active/progress/done mask).
## 20 = S1 seam 6: gather fields + rift-node respawn state (sl-0105).
## 21 = sl-0112: multi-active quest state (taken mask + per-quest
## progress array replace active/progress; the interact era).
## 22 = sl-0115 STARHOOK v2 (prototype #2): the line's three lives +
## drain accumulator + grace on PlayerState; ambient rift nodes
## (pos + biome) and the dive's landed catches on the world.
const SERIAL_VERSION := 22

## Damage-source pattern id for the scenario-declared test damage
## schedule (§2.11 elite transition proofs; planning log 2026-07-28).
## Namespace: pattern_def.gd.
const PATTERN_TEST_SCHEDULE := -4

## Named PCG32 stream ids (§2.4). rng_vfx deliberately does NOT exist here —
## it lives view-side so cosmetics can never perturb gameplay. STREAM_LOOT
## (Loop v1, docs/19) is drawn ONLY by the death-sweep drop rolls, so loot
## can never perturb enemy variation and vice versa.
const STREAM_ENEMY := 1
const STREAM_MISC := 2
const STREAM_LOOT := 3

## Ground-drop kinds (Loop v1 docs/19; drops entries carry kind + a/b:
## gold amount / frame+tier / armor tier / ability index / unique index).
## Canonical ids live in sim/drop_kinds.gd (leaf module — LootStep match
## patterns need class constants); these aliases keep call sites terse.
const DROP_GOLD := DropKinds.GOLD
const DROP_WEAPON := DropKinds.WEAPON
const DROP_ARMOR := DropKinds.ARMOR
const DROP_ABILITY := DropKinds.ABILITY
const DROP_UNIQUE := DropKinds.UNIQUE
const DROP_RING := DropKinds.RING

enum Command {
	SPAWN_PROJECTILE,
	SET_MOVE_SPEED,
	SET_ABILITY,
	SET_GOD,
}

## §3.2 move-speed tuning band. The sim-side clamp means NO path — debug
## editor included — can set a speed outside the band. Tuning below 3.0
## first requires re-proving the whole dodgeability suite at the new floor
## (proofs are speed-stamped; harness lands M7) — the band floor here is
## that rule's hard backstop.
const MOVE_SPEED_MIN := 3.0
const MOVE_SPEED_MAX := 5.5

var tick: int = 0
var run_seed: int = 0
## Stable monotonic entity ids, never reused within a run (§2.1).
var next_entity_id: int = 1
var bitgrid: RefCounted = null
## sl-0078 fit rule: the PLAYER + PROJECTILE terrain truth. walk_grid =
## bitgrid minus art-matched solid-prop cells (defaults to bitgrid
## itself — arena worlds and packless scenarios are byte-unchanged);
## prop_discs maps cell -> Array[Vector3(x, y, r)] sub-cell colliders
## measured from each cell's own sprite base. The bitgrid stays the
## CONSERVATIVE FLOOR: enemies, floods, spawns, and every upstream
## contract (porosity, world_walk, pack validation) keep their meaning.
## Static setup data like bitgrid — rebuilt deterministically from the
## scenario's pack, never serialized.
var walk_grid: RefCounted = null
var prop_discs: Dictionary = {}
var players: Array[PlayerState] = []
var enemies: Array[ActorState] = []
var projectiles: ProjectilePool = ProjectilePool.new()
var rng_enemy: Pcg32 = Pcg32.new()
var rng_misc: Pcg32 = Pcg32.new()
var rng_loot: Pcg32 = Pcg32.new()

## True once ANY runtime edit command touched this run (§2.10): the run can
## no longer serve as clean replay/feel evidence. Serialized — an edited
## run hashes differently from a clean one, deliberately.
var replay_dirty: bool = false

## Events emitted by systems this tick (sim/events.gd vocabulary). Cleared at
## the start of every step; consumers read between steps, never mutate sim.
var events: Array[Dictionary] = []

## InputFrames for the tick being stepped, one per player index — human,
## replay, and bot sources are indistinguishable here (§2.8). Transient
## input, not state: excluded from serialization (a replay is initial state
## plus the frame stream).
var current_frames: Array = []

## Weapon frame RESOURCES (definitions, not state): set at setup, indexed
## by weapon_select-1. Excluded from serialize() like the bitgrid — the
## replay header's data-definitions hash covers them instead (§2.4).
var weapon_frames: Array = []
## EnemyDef RESOURCES (definitions, not state): set at setup; EnemyState
## points in by def_index. Same serialization exclusion as weapon_frames.
var enemy_defs: Array = []
## Scenario-declared test damage schedule (§2.11 transition proofs):
## {tick, amount} entries applied to the first live PHASED enemy (the
## scenario's elite) at exact tick equality, through THE damage path,
## tagged PATTERN_TEST_SCHEDULE. Amounts are final HP deltas. Static
## definition data like the defs above — excluded from serialize();
## replays reproduce it because a replay names its scenario. Only test
## scenarios declare one; tester-reachable scenarios never do (M7
## checklist line).
var damage_schedule: Array = []
## Available AbilityDef resources (definitions) + the ONE equipped slot
## (CORE-34). Swapping is a debug/scenario action, not gameplay input —
## it marks the run replay-dirty.
var ability_defs: Array = []
var ability_def: Resource = null

## Live ground hazards (§2.6; lingering multi-hit since M6), stable
## order, serialized: {id, pos, radius, faction, damage, placed_at_tick,
## arm_at_tick, pattern, linger_until, next_damage_tick,
## hit_interval_ticks}.
var hazards: Array[Dictionary] = []

## Live ground drops (Loop v1 docs/19): stable order, serialized —
## {id, pos, kind, a, b, expires_at_tick}.
var drops: Array[Dictionary] = []

## Progression tables (Loop v1): definition resource like weapon_frames —
## excluded from serialize(); the replay header's data hash covers it.
var progression: Resource = null
## THE STAT FRAME (docs/22): parsed data/balance_frame.json — the single
## tuning source for the class-backed lane. Definitions like progression
## above: excluded from serialize(); {} keeps every lane legacy.
var stat_frame: Dictionary = {}

## Living-world SITE DEFINITIONS (docs/23 S0 plumbing v1): built by the
## content importer from the vendored pack's territories + placements.
## Definitions like enemy_defs — excluded from serialize(); a replay
## reproduces them because it names its scenario. Empty = no sites (the
## default; every pre-slice world).
## Entry: {cell: Vector2, roster_defs: PackedInt32Array,
##   roster_weights: PackedInt32Array, pack_min, pack_max, max_active,
##   respawn_ticks, kind: String}
var site_defs: Array = []
## Living-world SITE STATE (SERIAL 16), parallel to site_defs: awake
## flag, away-only respawn timer, and the dormant population (def_index
## + hp per member — damaged survivors stay damaged across sleeps).
var sites: Array[Dictionary] = []

## CORE-43 overworld death (slice S0 seam 3). Setup config like the
## defs (unserialized; the scenario + profile determine it): when
## true, a class-backed player's death costs carried gold IN-SIM and
## respawns them at respawn_cell — the world persists, no run
## framing (sl-0098). False = dead-in-place (every lab/proof world,
## hardcore characters, profile-free runs).
var persistent_respawn: bool = false
## Where persistent respawn lands — the scenario's settlement spawn.
var respawn_cell: Vector2 = Vector2.ZERO
## Unique item definitions (boss-tied, docs/19): definitions, excluded;
## drops reference them by index.
var unique_defs: Array = []
## Quest definitions (S1 seam 5): definitions, excluded from
## serialize; append-only order is the mask/profile contract.
var quest_defs: Array = []
## S1 seam 6: FORAGE cell mask (definitions; null = the verb is inert
## — every arena/proof world) and STARHOOK rift nodes (sl-0105):
## node CELLS are definitions; per-node respawn ticks are SERIALIZED
## state (a cast consumes the node until its timer lands).
var forage_grid: RefCounted = null
var rift_nodes: PackedVector2Array = PackedVector2Array()
var rift_node_respawn_at: PackedInt64Array = PackedInt64Array()
## STARHOOK v2 (sl-0115; drag cut by sl-0123 — the pull lives in THE
## LINE only). Setup configs (definitions, unserialized — the
## scenario reproduces them): rift_line = the line's rules resource
## (data/rift_line_def.gd: drains, deep edge, lives, graces; null =
## not a rift arena, every other world byte-identical by
## construction); rift_biome 0/1/2 = nebula/void/comet (indexes
## balance_frame starhook.biomes); rift_rare = the rarity step;
## rift_rod_unlocks = per-rod unlock levels in loadout order
## (player_fire refuses locked selects); rift_node_biomes = authored
## node biomes parallel to rift_nodes; rift_ambient = this world
## rolls ambient rift spawns (gather_step, rng_misc — its first
## consumer).
var rift_line: Resource = null
var rift_biome: int = 0
var rift_rare: bool = false
var rift_rod_unlocks: PackedInt32Array = PackedInt32Array()
var rift_node_biomes: PackedInt32Array = PackedInt32Array()
var rift_ambient: bool = false
## STARHOOK v2 SERIALIZED STATE (SERIAL 22): ambient nodes are world
## state (they appear at runtime, consumed = removed, no respawn);
## rift_catches = the dive's landed catches ({biome, fish, rare} int
## rows; fish 0-2 = the biome's commons, 3 = its rare) — harvest
## banks them per-species on a won exit.
var rift_ambient_pos: PackedVector2Array = PackedVector2Array()
var rift_ambient_biome: PackedInt32Array = PackedInt32Array()
var rift_catches: Array[Dictionary] = []

## God/invulnerability flag (§2.10): friendly actors take no damage —
## every absorbed hit emits DAMAGE_IMMUNE, so god use is always visible
## in logs and no verdict can launder through it. Serialized; toggling
## marks the run replay-dirty.
var god_mode: bool = false

var _commands: Array[Dictionary] = []


func setup(p_seed: int, p_bitgrid: RefCounted) -> void:
	run_seed = p_seed
	bitgrid = p_bitgrid
	# Fit-rule defaults (sl-0078): identical collision until a pack
	# scenario attaches its measured prop discs (scenario_loader).
	walk_grid = p_bitgrid
	prop_discs = {}
	rng_enemy.seed_stream(p_seed, STREAM_ENEMY)
	rng_misc.seed_stream(p_seed, STREAM_MISC)
	rng_loot.seed_stream(p_seed, STREAM_LOOT)
	projectiles.setup()


## Setup-phase: install the weapon loadout (order = select keys 1..N).
func set_weapons(frames: Array) -> void:
	weapon_frames = frames


## Setup-phase: install the EnemyDef roster. INDEX ORDER IS CONTRACT —
## def_index serializes, so a scenario's def list order must be stable
## (scenario_loader owns the standard order).
func set_enemy_defs(defs: Array) -> void:
	enemy_defs = defs


## Setup-phase: available abilities; index 0 equips by default.
func set_abilities(defs: Array) -> void:
	ability_defs = defs
	ability_def = defs[0] if not defs.is_empty() else null


## Setup-phase: install the scenario's test damage schedule (§2.11).
func set_damage_schedule(entries: Array) -> void:
	damage_schedule = entries


## Setup-phase: progression tables (Loop v1 docs/19).
func set_progression(prog: Resource) -> void:
	progression = prog


## Setup-phase: the parsed stat frame (docs/22; StatFrame.load_frame).
func set_stat_frame(f: Dictionary) -> void:
	stat_frame = f


## Setup-phase: install living-world site definitions and draw every
## site's INITIAL population (rng_enemy — authored variation; a fresh
## world's sites are fully stocked before the recorder snapshot).
## Single-entry rosters and fixed pack sizes draw nothing, so boss
## sites never consume the stream.
func set_site_defs(defs: Array) -> void:
	site_defs = defs
	sites = []
	for def: Dictionary in defs:
		var site := {
			"awake": false,
			"respawn_at": -1,
			"pop_def": PackedInt32Array(),
			"pop_hp": PackedInt32Array(),
		}
		SiteStep.fill_population(self, def, site)
		sites.append(site)


## Setup-phase: unique item defs (boss-tied; drops reference by index).
func set_uniques(defs: Array) -> void:
	unique_defs = defs


## Setup-phase: quest defs (S1 seam 5) — definitions like the unique
## list, excluded from serialize; APPEND-ONLY (the done bitmask and
## profile active-id key on stable order).
func set_quests(defs: Array) -> void:
	quest_defs = defs


## Setup-phase (S1 seam 6): the forage cell mask — definitions.
func set_forage_grid(grid: RefCounted) -> void:
	forage_grid = grid


## Setup-phase (S1 seam 6, sl-0105): rift node cells — definitions;
## the respawn-state array initializes armed (0 = active now).
## sl-0115: biomes ride parallel (short/absent entries read nebula 0).
func set_rift_nodes(cells: PackedVector2Array, biomes := PackedInt32Array()) -> void:
	rift_nodes = cells
	rift_node_respawn_at = PackedInt64Array()
	rift_node_respawn_at.resize(cells.size())
	rift_node_biomes = PackedInt32Array()
	rift_node_biomes.resize(cells.size())
	for i in mini(cells.size(), biomes.size()):
		rift_node_biomes[i] = biomes[i]


## Setup-phase (sl-0115): attach the rift arena's line rules +
## identity. Arms every player's line (lives from the def) — the
## scenario build runs this BEFORE the recorder snapshot, so replays
## carry the true initial state.
func set_rift_config(line: Resource, biome: int, rare: bool, rod_unlocks: PackedInt32Array) -> void:
	rift_line = line
	rift_biome = biome
	rift_rare = rare
	rift_rod_unlocks = rod_unlocks
	if line != null:
		for p in players:
			p.line_lives = int(line.lives)


## In-step ground-drop spawn (the death-sweep drop rolls call this).
## Emits LOOT_DROPPED. TTL from progression ([T]).
func spawn_drop(pos: Vector2, kind: int, a: int, b := 0) -> void:
	var ttl := 3600
	if progression != null:
		ttl = int(progression.drop_ttl_ticks)
	var id := _alloc_id()
	(
		drops
		. append(
			{
				"id": id,
				"pos": pos,
				"kind": kind,
				"a": a,
				"b": b,
				"expires_at_tick": tick + ttl,
			}
		)
	)
	(
		events
		. append(
			{
				"type": SimEvents.Type.LOOT_DROPPED,
				"tick": tick,
				"id": id,
				"kind": kind,
				"pos": pos,
				"a": a,
				"b": b,
			}
		)
	)


## In-step hazard placement (systems call this). Emits TelegraphStarted.
## Defaults reproduce the M4 one-shot Blast Rune shape (pulse once at the
## arm tick, then gone); linger_ticks > 0 makes a lingering multi-hit
## zone pulsing every hit_interval ticks (M6 Blightcaster, SERIAL 11).
func place_hazard(
	pos: Vector2,
	r: float,
	fac: int,
	dmg: int,
	arm_ticks: int,
	pattern: int = -2,
	linger_ticks: int = 0,
	hit_interval: int = 0
) -> void:
	var id := _alloc_id()
	(
		hazards
		. append(
			{
				"id": id,
				"pos": pos,
				"radius": r,
				"faction": fac,
				"damage": dmg,
				"placed_at_tick": tick,
				"arm_at_tick": tick + arm_ticks,
				"pattern": pattern,
				"linger_until": tick + arm_ticks + linger_ticks,
				"next_damage_tick": tick + arm_ticks,
				"hit_interval_ticks": hit_interval,
			}
		)
	)
	(
		events
		. append(
			{
				"type": SimEvents.Type.TELEGRAPH_STARTED,
				"tick": tick,
				"id": id,
				"pos": pos,
				"radius": r,
				"faction": fac,
				"arm_at_tick": tick + arm_ticks,
				"pattern": pattern,
			}
		)
	)


func add_player(pos: Vector2) -> PlayerState:
	var p := PlayerState.new()
	p.id = _alloc_id()
	p.pos = pos
	p.prev_pos = pos
	p.faction = ActorState.FACTION_FRIENDLY
	players.append(p)
	return p


## Inert hostile stand-in (M2 stress/testing): an EnemyState with
## def_index -1, so the enemy system skips it and the enemies array
## stays one uniform type.
func add_enemy_standin(pos: Vector2, body_radius := 0.35) -> ActorState:
	var e := EnemyState.new()
	e.id = _alloc_id()
	e.pos = pos
	e.prev_pos = pos
	e.radius = body_radius
	e.hp = 40
	e.faction = ActorState.FACTION_HOSTILE
	e.move_speed = 0.0
	e.def_index = -1
	e.spawned_at_tick = tick
	enemies.append(e)
	return e


## Setup-phase (and scenario-reset) spawn of a real enemy from the def
## roster. Stats copy from the def; behavior state starts IDLE.
func add_enemy(def_index: int, pos: Vector2) -> EnemyState:
	var def: Resource = enemy_defs[def_index]
	var e := EnemyState.new()
	e.id = _alloc_id()
	e.pos = pos
	e.prev_pos = pos
	e.radius = float(def.body_radius)
	e.hp = int(def.hp)
	e.faction = ActorState.FACTION_HOSTILE
	e.move_speed = float(def.move_speed)
	e.def_index = def_index
	e.spawned_at_tick = tick
	# Phase-resolved slot count (§3.5): phased defs keep the flat
	# emitters array empty and spawn into phase 0's set.
	var emitters: Array = def.active_emitters(0)
	e.cooldowns.resize(emitters.size())
	enemies.append(e)
	return e


## One fixed-dt tick: drain queued commands, apply any scheduled test
## damage (top of step — the same tick's EnemyStep already acts in the
## resulting phase), then run the ordered systems.
func step(frames: Array) -> void:
	events.clear()
	current_frames = frames
	_drain_commands()
	_apply_damage_schedule()
	PlayerRespawn.run(self)
	PlayerRegen.run(self)
	PlayerMove.run(self)
	PlayerAbility.run(self)
	PlayerFire.run(self)
	SiteStep.run(self)
	EnemyStep.run(self)
	ProjectileStep.run(self)
	HazardStep.run(self)
	# sl-0115: the line's drains + post-win shot clear (rift arenas
	# only — rift_line null means this is a straight no-op).
	RiftStep.run(self)
	LootStep.run(self)
	# S1 seam 6: the patience verbs (forage yields, rift casts).
	GatherStep.run(self)
	# S1 seam 5: quests read the tick's OWN events (kills, pickups) —
	# last by construction, after every emitter.
	QuestStep.run(self)
	tick += 1


func enqueue_command(cmd: Dictionary) -> void:
	_commands.append(cmd)


## In-step spawn path (systems and drained commands call this; external code
## never does). Emits PROJECTILE_SPAWNED. Returns the slot, -1 if exhausted.
## Defaults give the M2 rig shape: straight, zero damage, non-pierce.
func spawn_projectile(
	pos: Vector2,
	vel: Vector2,
	r: float,
	ttl_ticks: int,
	fac: int,
	dmg := 0,
	pattern := 0,
	program := ProjectilePool.Program.STRAIGHT,
	prog_a := 0.0,
	prog_b := 0.0,
	prog_c := 0.0,
	passes := 0
) -> int:
	var slot := projectiles.spawn(
		pos.x,
		pos.y,
		vel.x,
		vel.y,
		r,
		ttl_ticks,
		fac,
		dmg,
		pattern,
		program,
		prog_a,
		prog_b,
		prog_c,
		tick,
		passes
	)
	if slot >= 0:
		(
			events
			. append(
				{
					"type": SimEvents.Type.PROJECTILE_SPAWNED,
					"tick": tick,
					"slot": slot,
					"pattern": pattern,
				}
			)
		)
	return slot


## Canonical full-state serialization (§2.4). Everything a future tick can
## depend on is here — and only that: prev positions and current_frames are
## presentation/input, deliberately excluded.
func serialize() -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.put_u16(SERIAL_VERSION)
	buf.put_64(tick)
	buf.put_64(run_seed)
	buf.put_64(next_entity_id)
	buf.put_u8(1 if replay_dirty else 0)
	buf.put_64(rng_enemy.state)
	buf.put_64(rng_enemy.inc)
	buf.put_64(rng_misc.state)
	buf.put_64(rng_misc.inc)
	buf.put_64(rng_loot.state)
	buf.put_64(rng_loot.inc)
	buf.put_u32(players.size())
	for p in players:
		p.serialize_into(buf)
	buf.put_u32(enemies.size())
	for e in enemies:
		e.serialize_into(buf)
	projectiles.serialize_into(buf)
	buf.put_u32(hazards.size())
	for hz: Dictionary in hazards:
		buf.put_64(int(hz.id))
		var hpos: Vector2 = hz.pos
		buf.put_double(hpos.x)
		buf.put_double(hpos.y)
		buf.put_double(float(hz.radius))
		buf.put_u8(int(hz.faction))
		buf.put_32(int(hz.damage))
		buf.put_64(int(hz.placed_at_tick))
		buf.put_64(int(hz.arm_at_tick))
		buf.put_32(int(hz.pattern))
		buf.put_64(int(hz.linger_until))
		buf.put_64(int(hz.next_damage_tick))
		buf.put_32(int(hz.hit_interval_ticks))
	buf.put_u32(drops.size())
	for d: Dictionary in drops:
		buf.put_64(int(d.id))
		var dpos: Vector2 = d.pos
		buf.put_double(dpos.x)
		buf.put_double(dpos.y)
		buf.put_u8(int(d.kind))
		buf.put_32(int(d.a))
		buf.put_32(int(d.b))
		buf.put_64(int(d.expires_at_tick))
	buf.put_u8(0 if ability_def == null else ability_defs.find(ability_def) + 1)
	buf.put_u8(1 if god_mode else 0)
	buf.put_u32(sites.size())
	for s: Dictionary in sites:
		buf.put_u8(1 if bool(s.awake) else 0)
		buf.put_64(int(s.respawn_at))
		var pop_def: PackedInt32Array = s.pop_def
		var pop_hp: PackedInt32Array = s.pop_hp
		buf.put_u16(pop_def.size())
		for m in pop_def.size():
			buf.put_u16(pop_def[m])
			buf.put_32(pop_hp[m])
	# S1 seam 6 (SERIAL 20, sl-0105): rift-node consumption timers —
	# a cast is world state exactly like a site's respawn clock.
	buf.put_u16(rift_node_respawn_at.size())
	for na in rift_node_respawn_at:
		buf.put_64(na)
	# sl-0115 (SERIAL 22): ambient rift nodes (runtime world state —
	# spawned by gather_step, removed on cast) + the dive's catches.
	buf.put_u16(rift_ambient_pos.size())
	for ai in rift_ambient_pos.size():
		buf.put_double(rift_ambient_pos[ai].x)
		buf.put_double(rift_ambient_pos[ai].y)
		buf.put_u8(rift_ambient_biome[ai])
	buf.put_u16(rift_catches.size())
	for cd: Dictionary in rift_catches:
		buf.put_u8(int(cd.biome))
		buf.put_u8(int(cd.fish))
		buf.put_u8(1 if bool(cd.rare) else 0)
	return buf.data_array


## FNV-1a 64 over the canonical serialization — the replay-checkpoint hash
## (§2.4; checkpoint cadence is the caller's, every 30 ticks by convention).
func state_hash() -> int:
	return fnv1a_64(serialize())


static func fnv1a_64(bytes: PackedByteArray) -> int:
	var h := -3750763034362895579  # offset basis 0xCBF29CE484222325 as signed
	for b in bytes:
		h = (h ^ b) * 1099511628211  # prime 0x100000001B3; 64-bit wrap intended
	return h


## Scheduled test damage (§2.11): entries land at exact tick equality on
## the first live phased enemy, through THE damage path (events, death
## sweep, HP bars all behave normally; the sweep runs later this tick in
## ProjectileStep). No cursor state — the schedule is static data and
## this scan is a pure function of the tick.
func _apply_damage_schedule() -> void:
	if damage_schedule.is_empty():
		return
	for entry: Dictionary in damage_schedule:
		if int(entry.tick) != tick:
			continue
		for e in enemies:
			var di: int = e.def_index
			if di >= 0 and e.hp > 0 and enemy_defs[di].phases != null:
				Damage.apply(self, e, int(entry.amount), PATTERN_TEST_SCHEDULE)
				break


func _alloc_id() -> int:
	var id := next_entity_id
	next_entity_id += 1
	return id


func _drain_commands() -> void:
	for cmd: Dictionary in _commands:
		match int(cmd.type) as Command:
			Command.SPAWN_PROJECTILE:
				spawn_projectile(cmd.pos, cmd.vel, cmd.radius, cmd.ttl, cmd.faction)
			Command.SET_MOVE_SPEED:
				_cmd_set_move_speed(int(cmd.player), float(cmd.speed))
			Command.SET_ABILITY:
				var idx := int(cmd.index)
				if idx >= 0 and idx < ability_defs.size():
					ability_def = ability_defs[idx]
					replay_dirty = true
			Command.SET_GOD:
				god_mode = bool(cmd.on)
				replay_dirty = true
	_commands.clear()


## Runtime stat edit (M2: movement speed only; the full lean-stat editor is
## M4). Sim-side band clamp + replay-dirty stamp — by construction no
## caller can exceed the band or edit without leaving a mark.
func _cmd_set_move_speed(player_index: int, speed: float) -> void:
	if player_index < 0 or player_index >= players.size():
		return
	players[player_index].move_speed = clampf(speed, MOVE_SPEED_MIN, MOVE_SPEED_MAX)
	replay_dirty = true
