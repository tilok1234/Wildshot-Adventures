extends RefCounted
## Ordered system: projectile motion + ttl + brute-force circle collision
## against opposing-faction actors (docs/12 §2.3, §2.6 — M2 rig subset:
## straight-line motion, no damage/pierce/despawn-reasons yet; DDA terrain
## collision lands at M3). Pure overlap = hit, no rolls (CORE-31). Iteration
## is slot-ascending and actor-array-ordered — stable order, never
## dictionary-order (§2.4). Spatial hash deliberately deferred; the M2
## stress scene renders the verdict (§2.3).
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const ActorState := preload("res://sim/actor_state.gd")
const SimEvents := preload("res://sim/events.gd")


static func run(world: RefCounted) -> void:
	var pool: RefCounted = world.projectiles
	var dt: float = world.DT
	var t: int = world.tick
	# Snapshot prev positions for view interpolation (§2.9); assignment
	# shares storage in 4.6, so a real copy needs duplicate().
	pool.prev_x = pool.pos_x.duplicate()
	pool.prev_y = pool.pos_y.duplicate()
	# Locals alias pool storage (shared, not copied) — element access on a
	# local is much cheaper than repeated member indexing in the hot loop.
	var px: PackedFloat32Array = pool.pos_x
	var py: PackedFloat32Array = pool.pos_y
	var vx: PackedFloat32Array = pool.vel_x
	var vy: PackedFloat32Array = pool.vel_y
	var rad: PackedFloat32Array = pool.radius
	var ttl: PackedInt32Array = pool.ttl
	var fac: PackedByteArray = pool.faction
	var act: PackedByteArray = pool.active
	var players: Array = world.players
	var enemies: Array = world.enemies
	var events: Array[Dictionary] = world.events
	var capacity: int = pool.CAPACITY
	for s in capacity:
		if act[s] == 0:
			continue
		var life: int = ttl[s] - 1
		if life <= 0:
			pool.despawn(s)
			events.append({"type": SimEvents.Type.PROJECTILE_DESPAWNED, "tick": t, "slot": s})
			continue
		ttl[s] = life
		var x := px[s] + vx[s] * dt
		var y := py[s] + vy[s] * dt
		px[s] = x
		py[s] = y
		var r := rad[s]
		var targets: Array = players if fac[s] == ActorState.FACTION_HOSTILE else enemies
		for a: RefCounted in targets:
			var apos: Vector2 = a.pos
			var dx := x - apos.x
			var dy := y - apos.y
			var rr: float = r + a.radius
			if dx * dx + dy * dy < rr * rr:
				pool.despawn(s)
				events.append(
					{"type": SimEvents.Type.HIT_LANDED, "tick": t, "slot": s, "target": a.id}
				)
				events.append({"type": SimEvents.Type.PROJECTILE_DESPAWNED, "tick": t, "slot": s})
				break
