extends RefCounted
## Ordered system: armed ground hazards (docs/12 §2.6). M4 form: one-shot
## zones — placed (TelegraphStarted), arm after arm_ticks (HazardArmed +
## radial damage through the shared resolution events), then removed.
## Lingering multi-hit hazards (Blightcaster) extend this at M6. Stable
## array order; hazards serialize (§2.4).
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const ActorState := preload("res://sim/actor_state.gd")
const SimEvents := preload("res://sim/events.gd")
const Damage := preload("res://sim/systems/damage.gd")


static func run(world: RefCounted) -> void:
	var hazards: Array[Dictionary] = world.hazards
	if hazards.is_empty():
		return
	var events: Array[Dictionary] = world.events
	var t: int = world.tick
	var any_fired := false
	for hz: Dictionary in hazards:
		if t < int(hz.arm_at_tick):
			continue
		any_fired = true
		(
			events
			. append(
				{
					"type": SimEvents.Type.HAZARD_ARMED,
					"tick": t,
					"id": int(hz.id),
					"pos": hz.pos,
					"radius": float(hz.radius),
				}
			)
		)
		var targets: Array = (
			world.players if int(hz.faction) == ActorState.FACTION_HOSTILE else world.enemies
		)
		var r := float(hz.radius)
		var center: Vector2 = hz.pos
		for a: RefCounted in targets:
			if a.dead:
				continue
			var apos: Vector2 = a.pos
			var d := apos - center
			var rr: float = r + a.radius
			if d.length_squared() >= rr * rr:
				continue
			Damage.apply(world, a, int(hz.damage), -2)
	if any_fired:
		world.hazards = hazards.filter(func(hz: Dictionary) -> bool: return t < int(hz.arm_at_tick))
		# Kills from hazards: enemies sweep here (projectile_step's sweep
		# already ran this tick — order: projectiles then hazards).
		Damage.sweep_dead_enemies(world)
