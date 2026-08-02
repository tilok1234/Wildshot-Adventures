extends RefCounted
## Ordered system (sl-0115, STARHOOK v2): the rift arena's line rules.
## Runs only where SimWorld.rift_pull is attached — a null config makes
## this a straight no-op and every non-rift world byte-identical.
##
## - THE DRAINS: passive stability drain (the session clock) + the
##   deep-edge strain while inside the deep strip. Integer-exact: an
##   accumulator in 1/600-hp units per tick (0.4/s -> 4, 2.2/s -> 22 at
##   60 t/s), applying 1-hp chunks through THE damage path (pattern
##   PATTERN_LINE_STRAIN — every snap stays explainable, Law 8). The
##   drains never pause: hit-grace protects against bullets only.
## - POST-WIN CLEAR: the tick the catch is dead, live hostile shots
##   vanish (reason CLEARED) — a won dive can never end in a snap.
##
## The pull VECTOR itself is a pure function of the tick (pull_vec) —
## the movement/projectile integrators and DodgeBot all read it here,
## one closed form for the sim and the model.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const ActorState := preload("res://sim/actor_state.gd")
const SimEvents := preload("res://sim/events.gd")
const Damage := preload("res://sim/systems/damage.gd")

## Damage-source pattern id for line strain (namespace: pattern_def.gd;
## -4 = the test schedule, -2 = the Blast Rune hazard default).
const PATTERN_LINE_STRAIN := -5

## Drain accumulator denominator: units are 1/600 hp per tick, so
## hp-per-second rates convert exactly (rate * 10 at 60 t/s).
const ACC_DEN := 600


## The pull, tiles/second, at `tick` (multiply by DT to integrate).
## Base direction +X (toward the deep edge), oscillating ±amplitude
## on a slow sine — the prototype's exact shape at 60 t/s.
static func pull_vec(world: RefCounted, at_tick: int) -> Vector2:
	var def: Resource = world.rift_pull
	var ang: float = sin(float(at_tick) * float(def.osc_rate_per_tick))
	ang *= float(def.osc_amplitude_rad)
	return Vector2(cos(ang), sin(ang)) * float(def.pull_tiles_per_sec)


## X past which the deep-edge strain applies (from the arena's right
## interior edge; bitgrid width counts the wall ring).
static func deep_edge_x(world: RefCounted) -> float:
	return float(world.bitgrid.width - 1) - float(world.rift_pull.deep_edge_tiles)


static func run(world: RefCounted) -> void:
	if world.rift_pull == null:
		return
	var def: Resource = world.rift_pull
	var passive_units := roundi(float(def.passive_drain_per_sec) * 10.0)
	var deep_units := roundi(float(def.deep_drain_per_sec) * 10.0)
	var deep_x := deep_edge_x(world)
	for p: RefCounted in world.players:
		if p.dead:
			continue
		var units := passive_units
		if p.pos.x > deep_x:
			units += deep_units
		p.line_drain_acc += units
		while p.line_drain_acc >= ACC_DEN and not p.dead:
			p.line_drain_acc -= ACC_DEN
			Damage.apply(world, p, 1, PATTERN_LINE_STRAIN)
	# Post-win clear: no live catch means no live hostile shots.
	if not world.enemies.is_empty():
		return
	var pool: RefCounted = world.projectiles
	var fac: PackedByteArray = pool.faction
	var act: PackedByteArray = pool.active
	for s in pool.CAPACITY:
		if act[s] == 0 or fac[s] != ActorState.FACTION_HOSTILE:
			continue
		pool.despawn(s)
		(
			world
			. events
			. append(
				{
					"type": SimEvents.Type.PROJECTILE_DESPAWNED,
					"tick": world.tick,
					"slot": s,
					"reason": SimEvents.DespawnReason.CLEARED,
				}
			)
		)
