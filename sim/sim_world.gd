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
const ActorState := preload("res://sim/actor_state.gd")
const PlayerState := preload("res://sim/player_state.gd")
const EnemyState := preload("res://sim/enemy_state.gd")
const ProjectilePool := preload("res://sim/projectile_pool.gd")
const SimEvents := preload("res://sim/events.gd")
const PlayerMove := preload("res://sim/systems/player_move.gd")
const PlayerRegen := preload("res://sim/systems/player_regen.gd")
const PlayerAbility := preload("res://sim/systems/player_ability.gd")
const PlayerFire := preload("res://sim/systems/player_fire.gd")
const EnemyStep := preload("res://sim/systems/enemy_step.gd")
const ProjectileStep := preload("res://sim/systems/projectile_step.gd")
const HazardStep := preload("res://sim/systems/hazard_step.gd")
const EmitterStep := preload("res://sim/systems/emitter_step.gd")

const TICKS_PER_SECOND := 60
const DT := 1.0 / 60.0
const SERIAL_VERSION := 8

## Named PCG32 stream ids (§2.4). rng_vfx deliberately does NOT exist here —
## it lives view-side so cosmetics can never perturb gameplay.
const STREAM_ENEMY := 1
const STREAM_MISC := 2

enum Command {
	SPAWN_PROJECTILE,
	SET_MOVE_SPEED,
	SET_ABILITY,
	TOGGLE_EMITTER,
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
var players: Array[PlayerState] = []
var enemies: Array[ActorState] = []
var projectiles: ProjectilePool = ProjectilePool.new()
var rng_enemy: Pcg32 = Pcg32.new()
var rng_misc: Pcg32 = Pcg32.new()

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
## Available AbilityDef resources (definitions) + the ONE equipped slot
## (CORE-34). Swapping is a debug/scenario action, not gameplay input —
## it marks the run replay-dirty.
var ability_defs: Array = []
var ability_def: Resource = null

## Live armed-zone hazards (§2.6 M4 subset), stable order, serialized:
## {id, pos, radius, faction, damage, arm_at_tick}.
var hazards: Array[Dictionary] = []

## God/invulnerability flag (§2.10): friendly actors take no damage —
## every absorbed hit emits DAMAGE_IMMUNE, so god use is always visible
## in logs and no verdict can launder through it. Serialized; toggling
## marks the run replay-dirty.
var god_mode: bool = false

## M4 debug hostile emitter (sim/systems/emitter_step.gd). Serialized;
## toggling is a debug command and marks the run replay-dirty.
var emitter_on: bool = false
var emitter_pos: Vector2 = Vector2.ZERO
var emitter_next_fire: int = 0
var emitter_cadence: int = 90
var emitter_damage: int = 10

var _commands: Array[Dictionary] = []


func setup(p_seed: int, p_bitgrid: RefCounted) -> void:
	run_seed = p_seed
	bitgrid = p_bitgrid
	rng_enemy.seed_stream(p_seed, STREAM_ENEMY)
	rng_misc.seed_stream(p_seed, STREAM_MISC)
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


## In-step hazard placement (systems call this). Emits TelegraphStarted.
func place_hazard(pos: Vector2, r: float, fac: int, dmg: int, arm_ticks: int) -> void:
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
				"pattern": -2,
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
	var emitters: Array = def.emitters
	e.cooldowns.resize(emitters.size())
	enemies.append(e)
	return e


## One fixed-dt tick: drain queued commands, then run the ordered systems.
## frames[i] belongs to players[i]; null means "no input this tick".
func step(frames: Array) -> void:
	events.clear()
	current_frames = frames
	_drain_commands()
	PlayerRegen.run(self)
	PlayerMove.run(self)
	PlayerAbility.run(self)
	PlayerFire.run(self)
	EnemyStep.run(self)
	EmitterStep.run(self)
	ProjectileStep.run(self)
	HazardStep.run(self)
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
	buf.put_u8(0 if ability_def == null else ability_defs.find(ability_def) + 1)
	buf.put_u8(1 if god_mode else 0)
	buf.put_u8(1 if emitter_on else 0)
	buf.put_double(emitter_pos.x)
	buf.put_double(emitter_pos.y)
	buf.put_64(emitter_next_fire)
	buf.put_32(emitter_cadence)
	buf.put_32(emitter_damage)
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
			Command.TOGGLE_EMITTER:
				emitter_on = bool(cmd.on)
				if emitter_on:
					emitter_pos = cmd.pos
					emitter_cadence = int(cmd.get("cadence", 90))
					emitter_damage = int(cmd.get("damage", 10))
					emitter_next_fire = tick + emitter_cadence
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
