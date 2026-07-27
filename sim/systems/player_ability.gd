extends RefCounted
## Ordered system: the CORE-34 equipped ability. Exactly one active,
## running on mana; cast on the frame's ability edge when affordable.
## Kinds are hard-coded behind AbilityDef params (TECH-06 deferred,
## ledger #1/#2). Reads the frame's ability + aim channels only — no
## enemy awareness enters the cast decision. All damage flows through
## the same resolution events as everything else.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const ActorState := preload("res://sim/actor_state.gd")
const SimEvents := preload("res://sim/events.gd")
const AbilityDef := preload("res://data/ability_def.gd")


static func run(world: RefCounted) -> void:
	var frames: Array = world.current_frames
	var def: Resource = world.ability_def
	if def == null:
		return
	for i in world.players.size():
		if i >= frames.size() or frames[i] == null:
			continue
		var frame: RefCounted = frames[i]
		if not frame.ability_pressed:
			continue
		var p: RefCounted = world.players[i]
		if p.dead or p.mana < int(def.mana_cost):
			continue
		p.mana -= int(def.mana_cost)
		(
			world
			. events
			. append(
				{
					"type": SimEvents.Type.RESOURCE_SPENT,
					"tick": world.tick,
					"player": p.id,
					"resource": "mana",
					"amount": int(def.mana_cost),
					"value": p.mana,
				}
			)
		)
		(
			world
			. events
			. append(
				{
					"type": SimEvents.Type.ABILITY_CAST,
					"tick": world.tick,
					"player": p.id,
					"ability": String(def.id),
					"pos": p.pos,
				}
			)
		)
		match int(def.kind):
			AbilityDef.Kind.NOVA:
				_cast_nova(world, p, def)
			AbilityDef.Kind.CADENCE_BUFF:
				p.quickdraw_until_tick = world.tick + int(def.duration_ticks)
			AbilityDef.Kind.PLACED_ZONE:
				_cast_zone(world, p, frame, def)


## Radial damage around the player — same resolution events as shots.
static func _cast_nova(world: RefCounted, p: RefCounted, def: Resource) -> void:
	var r := float(def.radius)
	var ppos: Vector2 = p.pos
	var events: Array[Dictionary] = world.events
	for e: RefCounted in world.enemies:
		if e.dead:
			continue
		var apos: Vector2 = e.pos
		var d := apos - ppos
		var rr: float = r + e.radius
		if d.length_squared() >= rr * rr:
			continue
		e.hp -= int(def.damage)
		e.last_damaged_tick = world.tick
		(
			events
			. append(
				{
					"type": SimEvents.Type.DAMAGE_APPLIED,
					"tick": world.tick,
					"target": e.id,
					"amount": int(def.damage),
					"hp": e.hp,
					"pattern": -1,
					"pos": e.pos,
				}
			)
		)
	# Death sweep for nova kills happens in projectile_step's shared sweep
	# later this tick (systems order: ability -> fire -> projectiles).


## Friendly hazard placed along aim (§3.6 Blast Rune: status-free, reuses
## the hazard mechanism on the friendly faction).
static func _cast_zone(world: RefCounted, p: RefCounted, frame: RefCounted, def: Resource) -> void:
	var aim: Vector2 = frame.aim_vector()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	var at: Vector2 = p.pos + aim.normalized() * float(def.place_range)
	world.place_hazard(
		at, float(def.radius), ActorState.FACTION_FRIENDLY, int(def.damage), int(def.arm_ticks)
	)
