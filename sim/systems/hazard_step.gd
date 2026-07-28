extends RefCounted
## Ordered system: armed ground hazards (docs/12 §2.6). Zones are placed
## (TelegraphStarted, pattern-tagged), arm after arm_ticks (HazardArmed +
## first damage pulse), then — M6 lingering form — keep pulsing every
## hit_interval_ticks through the shared damage path until linger_until,
## when they expire. One-shot zones (Blast Rune: linger_until == arm
## tick) pulse once and expire on the same tick, byte-identical to the
## M4 behavior. Stable array order; hazards serialize (§2.4, SERIAL 11).
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
	var any_pulse := false
	var any_expired := false
	for hz: Dictionary in hazards:
		var arm_at := int(hz.arm_at_tick)
		if t < arm_at:
			continue
		if t == arm_at:
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
		var linger_until := int(hz.linger_until)
		# Pulse window is [arm_at, linger_until] inclusive — the last pulse
		# may land exactly at expiry (one-shot zones: arm == expiry, one
		# pulse, gone the same tick — the M4 behavior byte-for-byte).
		if t <= linger_until and t >= int(hz.next_damage_tick):
			any_pulse = true
			hz.next_damage_tick = t + maxi(1, int(hz.hit_interval_ticks))
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
				Damage.apply(world, a, int(hz.damage), int(hz.pattern))
		if t >= linger_until:
			any_expired = true
	if any_expired:
		world.hazards = hazards.filter(
			func(hz: Dictionary) -> bool: return t < int(hz.arm_at_tick) or t < int(hz.linger_until)
		)
	if any_pulse:
		# Kills from hazards: enemies sweep here (projectile_step's sweep
		# already ran this tick — order: projectiles then hazards).
		Damage.sweep_dead_enemies(world)
