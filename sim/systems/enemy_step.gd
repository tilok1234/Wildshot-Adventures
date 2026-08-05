extends RefCounted
## Ordered system: the explicit 5-state enemy machine (docs/12 §2.7 —
## idle / reposition / windup / fire / recover). All timers in ticks;
## decisions read world state only (+ rng_enemy for authored variation —
## the M5 roster draws none). Movement runs on the shared Kinematics
## slide, so enemies and players corner identically by construction.
## Fire mirrors player_fire's ShotDef volley loop through
## world.spawn_projectile; contact damage flows through THE damage path.
## No targeting state exists anywhere (CORE-35): this system reads the
## players ARRAY (GDD-16), computes an aim vector at the fire tick, and
## remembers nothing about who it aimed at.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const ActorState := preload("res://sim/actor_state.gd")
const EnemyState := preload("res://sim/enemy_state.gd")
const EnemyDef := preload("res://data/enemy_def.gd")
const PatternDef := preload("res://data/pattern_def.gd")
const SimEvents := preload("res://sim/events.gd")
const Kinematics := preload("res://sim/systems/kinematics.gd")
const Damage := preload("res://sim/systems/damage.gd")
const SiteStep := preload("res://sim/systems/site_step.gd")

## Damage-source pattern id for body contact (namespace: pattern_def.gd).
const PATTERN_CONTACT := -3
## Windup telegraph ring reaches this far beyond the body (presentation
## sizing; the danger is the SHOT, telegraphed by the timing contract).
const WINDUP_RING_EXTRA := 0.25


static func run(world: RefCounted) -> void:
	var defs: Array = world.enemy_defs
	var t: int = world.tick
	var dt: float = world.DT
	var grid: RefCounted = world.bitgrid
	var players: Array = world.players
	for e: RefCounted in world.enemies:
		# Unconditional: the view interpolates every enemy every tick (§2.9).
		e.prev_pos = e.pos
		# Serialized applied velocity (SERIAL 10): zero unless _move runs
		# this tick — WINDUP/FIRE/RECOVER stand still and read as such.
		e.vel = Vector2.ZERO
		var def_index: int = e.def_index
		if def_index < 0 or e.hp <= 0:
			continue  # inert stand-in, or killed this tick awaiting sweep
		var def: Resource = defs[def_index]

		# Phase resolution (§3.5 elite): the active phase is a pure
		# function of current HP; this is the single point where a
		# crossing's side effects fire (exactly once — phase_index is
		# serialized edge-detection state). Old-phase projectiles and
		# hazards persist untouched: transition seams are real, and the
		# full-fight proof exists to witness them.
		var phase_res: Resource = def.phases
		if phase_res != null:
			var want: int = def.phase_for_hp(e.hp)
			if want != e.phase_index:
				_enter_phase(world, e, def, want, t)
		var emitters: Array = def.active_emitters(e.phase_index)
		var policy: int = def.active_policy(e.phase_index)
		# THE PRESS (sl-0213 close-fighter wave 1): an open melee-class
		# gate overrides the base policy with a committed close. Pure
		# function of (t, serialized cooldowns) — no mode state exists.
		if bool(def.press_on_melee_gate) and _melee_gate_open(e, emitters, t):
			policy = EnemyDef.MovementPolicy.CHASER
		var rmin: float = float(def.range_min)
		var rmax: float = float(def.range_max)
		if phase_res != null:
			var pe: Resource = def.phase_entry(e.phase_index)
			rmin = float(pe.range_min)
			rmax = float(pe.range_max)

		# TERRITORY DISCIPLINE (docs/23 S0 tether; sl-0219 give-up +
		# full return-home). The tether: a site member beyond its
		# territory line disengages and walks straight home — nobody
		# migrates, chases end at the line. An in-progress windup
		# cancels (an unkept telegraph cannot kill, Law 8). At the
		# exact boundary it alternates step-home / re-engage — bounded
		# edge-guarding, which reads as "it will not chase past its
		# ground". Give-up and return-home live in the state machine
		# below (IDLE walk-home / REPOSITION give-up) and apply to
		# SITE MEMBERS ONLY — labs, the Warren, the rift dungeon and
		# every authored proof keep chase-forever by construction.
		var is_site: bool = e.site_index >= 0 and e.site_index < world.site_defs.size()
		var home := Vector2.ZERO
		var home_dist := 0.0
		if is_site:
			var site_def: Dictionary = world.site_defs[e.site_index]
			home = site_def.cell
			home_dist = e.pos.distance_to(home)
			if home_dist > SiteStep.TETHER_RADIUS:
				e.ai_state = EnemyState.AIState.IDLE
				e.winding_slot = -1
				_walk_home(grid, e, home, home_dist, dt)
				continue

		# Nearest living player: linear scan, first-wins ties (stable §2.4).
		var target: RefCounted = null
		var best := INF
		for p: RefCounted in players:
			if p.dead:
				continue
			var ppos: Vector2 = p.pos
			var d2: float = e.pos.distance_squared_to(ppos)
			if d2 < best:
				best = d2
				target = p
		if target == null:
			e.ai_state = EnemyState.AIState.IDLE
			continue
		var tpos: Vector2 = target.pos
		var dist := sqrt(best)

		# Contact damage: a body-touch attack on its own cooldown, state-free
		# (a Rusher pressed into you mid-recover still hurts).
		var contact := int(def.contact_damage)
		if contact > 0 and t >= e.next_contact_tick:
			var rr: float = e.radius + target.radius
			if best < rr * rr:
				Damage.apply(world, target, contact, PATTERN_CONTACT)
				e.next_contact_tick = t + int(def.contact_cooldown_ticks)

		match e.ai_state:
			EnemyState.AIState.IDLE:
				if dist <= float(def.aggro_range):
					e.ai_state = EnemyState.AIState.REPOSITION
				elif is_site and home_dist > SiteStep.RETURN_RADIUS:
					# sl-0219 FULL RETURN-HOME: a disengaged member
					# re-centers all the way (the tether's stop-inside
					# parked whole camps at the rim — the measured
					# ratchet). Never moves a fresh wake: spawn rings
					# max 4.4 < RETURN_RADIUS.
					_walk_home(grid, e, home, home_dist, dt)
			EnemyState.AIState.REPOSITION:
				if is_site and dist > SiteStep.GIVE_UP_RADIUS:
					# sl-0219 GIVE-UP: the player left — stop caring.
					# One standing tick; the IDLE branch walks it home
					# from the next. Structural hysteresis: give-up 18
					# > aggro 12/14, so re-engaging means the player
					# actually came back. A windup in flight is not
					# interrupted here — it completes harmlessly at
					# this range (Law 8 keeps its telegraph honest).
					e.ai_state = EnemyState.AIState.IDLE
					continue
				_move(grid, e, policy, rmin, rmax, tpos, dist, dt)
				var slot := _ready_slot(e, emitters, t, dist)
				if slot >= 0:
					var es: Resource = emitters[slot]
					e.ai_state = EnemyState.AIState.WINDUP
					e.winding_slot = slot
					e.state_until = t + int(es.telegraph_ticks)
					(
						world
						. events
						. append(
							{
								"type": SimEvents.Type.TELEGRAPH_STARTED,
								"tick": t,
								"id": e.id,
								"pos": e.pos,
								"radius": e.radius + WINDUP_RING_EXTRA,
								"faction": ActorState.FACTION_HOSTILE,
								"arm_at_tick": e.state_until,
								"pattern": _slot_pattern_id(es),
							}
						)
					)
			EnemyState.AIState.WINDUP:
				if t >= e.state_until:
					e.ai_state = EnemyState.AIState.FIRE
					_fire(world, e, emitters, target, t)
			EnemyState.AIState.FIRE:
				# The volley left on the WINDUP->FIRE transition tick; FIRE
				# persists one observable tick (explicit 5-state contract).
				e.ai_state = EnemyState.AIState.RECOVER
			EnemyState.AIState.RECOVER:
				if t >= e.state_until:
					e.ai_state = EnemyState.AIState.REPOSITION


## One step of the walk home (tether return + sl-0219 re-centering —
## the same math either way). Callers guarantee home_dist > 0.
static func _walk_home(
	grid: RefCounted, e: RefCounted, home: Vector2, home_dist: float, dt: float
) -> void:
	var epos_now: Vector2 = e.pos
	var toward_home: Vector2 = (home - epos_now) / home_dist
	e.pos = Kinematics.move_circle(grid, epos_now, e.radius, toward_home * float(e.move_speed) * dt)
	e.vel = (e.pos - epos_now) / dt


## Phase transition (§3.5): re-arm cooldowns for the new phase's slots
## (entry beat + full telegraph — no volley may arrive untelegraphed
## across a flip), apply the phase's movement speed, interrupt any
## in-progress windup (its telegraph resolves to nothing — safe by Law
## 8: an unkept warning cannot kill), and emit PHASE_CHANGED.
static func _enter_phase(
	world: RefCounted, e: RefCounted, def: Resource, want: int, t: int
) -> void:
	e.phase_index = want
	var pe: Resource = def.phase_entry(want)
	var pspeed: float = float(pe.move_speed)
	e.move_speed = float(def.move_speed) if pspeed < 0.0 else pspeed
	var pemit: Array = pe.emitters
	var fresh := PackedInt64Array()
	fresh.resize(pemit.size())
	for k in pemit.size():
		var es: Resource = pemit[k]
		fresh[k] = t + int(pe.entry_cooldown_ticks) + int(es.telegraph_ticks)
	e.cooldowns = fresh
	if e.ai_state != EnemyState.AIState.IDLE:
		e.ai_state = EnemyState.AIState.REPOSITION
	e.winding_slot = -1
	(
		world
		. events
		. append(
			{
				"type": SimEvents.Type.PHASE_CHANGED,
				"tick": t,
				"id": e.id,
				"def_index": e.def_index,
				"phase": want,
				"hp": e.hp,
				"pos": e.pos,
			}
		)
	)


## Movement policies (§2.7). WINDUP/FIRE/RECOVER stand still — telegraphs
## stay readable where they started (Law 4 honesty). Speed reads
## e.move_speed (copied from the def at spawn; phase entry overwrites it
## for §3.5 elites), band comes from the caller's phase-resolved values.
static func _move(
	grid: RefCounted,
	e: RefCounted,
	policy: int,
	rmin: float,
	rmax: float,
	tpos: Vector2,
	dist: float,
	dt: float
) -> void:
	if dist < 0.0001:
		return
	var toward: Vector2 = (tpos - e.pos) / dist
	var dir := Vector2.ZERO
	match policy:
		EnemyDef.MovementPolicy.CHASER:
			dir = toward
		EnemyDef.MovementPolicy.KEEP_RANGE:
			if dist < rmin:
				dir = -toward
			elif dist > rmax:
				dir = toward
		EnemyDef.MovementPolicy.FLANKER:
			# Orbit-in (M6 Leadshot, §2.7): spiral toward the band, then
			# circle-strafe inside it — never a straight radial approach.
			# Chirality from id parity: authored variation, zero RNG,
			# stable across serialization (id is serialized state).
			var tangent := Vector2(-toward.y, toward.x)
			if e.id % 2 == 1:
				tangent = -tangent
			if dist > rmax:
				dir = (toward + tangent).normalized()
			elif dist < rmin:
				dir = (tangent - toward).normalized()
			else:
				dir = tangent
		_:
			# ANCHOR holds ground; ORBIT lands with a roster row that
			# needs it and anchors until then (enemy_def.gd note).
			dir = Vector2.ZERO
	if dir == Vector2.ZERO:
		return
	var before: Vector2 = e.pos
	var step: Vector2 = dir * float(e.move_speed) * dt
	e.pos = Kinematics.move_circle(grid, e.pos, e.radius, step)
	e.vel = (e.pos - before) / dt


## True when any melee-class pattern slot (trigger_range <=
## EnemyDef.MELEE_TRIGGER_MAX) could begin its windup now — the same
## fire-to-fire gate _ready_slot reads, minus the range condition (the
## press exists exactly to CLOSE that range). Hazard slots never press.
static func _melee_gate_open(e: RefCounted, emitters: Array, t: int) -> bool:
	for k in emitters.size():
		var es: Resource = emitters[k]
		if es.pattern == null:
			continue
		if float(es.trigger_range) > EnemyDef.MELEE_TRIGGER_MAX:
			continue
		if t >= e.cooldowns[k] - int(es.telegraph_ticks):
			return true
	return false


## Pattern id a slot's attack carries: the cast hazard's id when the
## slot is a caster (M6), else the volley pattern's.
static func _slot_pattern_id(es: Resource) -> int:
	var hz: Resource = es.hazard
	if hz != null:
		return int(hz.pattern_id)
	var pattern: Resource = es.pattern
	return int(pattern.pattern_id)


## First emitter slot whose cooldown gate is open (windup may begin
## telegraph_ticks before the fire gate: cooldown is fire-to-fire) and
## whose trigger band contains the nearest player (range_min <= dist
## <= range; the min defaults 0.0 — sl-0213 wave 1). -1 = none. The
## caller passes the phase-resolved emitter set (§3.5).
static func _ready_slot(e: RefCounted, emitters: Array, t: int, dist: float) -> int:
	for k in emitters.size():
		var es: Resource = emitters[k]
		if t < e.cooldowns[k] - int(es.telegraph_ticks):
			continue
		if dist <= float(es.trigger_range) and dist >= float(es.trigger_range_min):
			return k
	return -1


## Fire the winding slot. Hazard slots (M6 Blightcaster) CAST: the zone
## is placed at the target's position — its arm period is the §3.4
## telegraph, and place_hazard's own TELEGRAPH_STARTED (pattern-tagged,
## at the zone) is what the recap's lead measurement keys on. Volley
## slots spawn shots on an aim vector per the pattern's aim mode
## (CURRENT = target position at the fire tick; INTERCEPT = closed-form
## lead on the target's serialized vel — M6 Leadshot; ROTOR = a
## world-frame angle advancing with the tick — §3.5 rotating radial,
## stateless and seed-free). The caller passes the phase-resolved
## emitter set (§3.5).
static func _fire(
	world: RefCounted, e: RefCounted, emitters: Array, target: RefCounted, t: int
) -> void:
	var es: Resource = emitters[e.winding_slot]
	var tpos: Vector2 = target.pos
	var aim: Vector2 = tpos - e.pos
	var hz: Resource = es.hazard
	if hz != null:
		aim = aim.normalized() if aim.length_squared() > 0.0001 else Vector2.RIGHT
		(
			world
			. events
			. append(
				{
					"type": SimEvents.Type.ATTACK_STARTED,
					"tick": t,
					"enemy": e.id,
					"def_index": e.def_index,
					"pattern": int(hz.pattern_id),
					"pos": e.pos,
					"aim": aim,
				}
			)
		)
		world.place_hazard(
			tpos,
			float(hz.radius),
			ActorState.FACTION_HOSTILE,
			int(hz.damage),
			int(hz.arm_ticks),
			int(hz.pattern_id),
			int(hz.linger_ticks),
			int(hz.hit_interval_ticks)
		)
		e.cooldowns[e.winding_slot] = t + int(es.cooldown_ticks)
		e.state_until = t + int(es.recover_ticks)
		e.winding_slot = -1
		return
	var pattern: Resource = es.pattern
	if int(pattern.aim_mode) == PatternDef.AimMode.INTERCEPT and not pattern.shots.is_empty():
		var tvel: Vector2 = target.vel
		var shot0: Resource = pattern.shots[0]
		aim = _intercept_aim(e.pos, tpos, tvel, float(shot0.speed))
	elif int(pattern.aim_mode) == PatternDef.AimMode.ROTOR:
		aim = Vector2.RIGHT.rotated(deg_to_rad(float(t) * float(pattern.rotor_deg_per_tick)))
	aim = aim.normalized() if aim.length_squared() > 0.0001 else Vector2.RIGHT
	(
		world
		. events
		. append(
			{
				"type": SimEvents.Type.ATTACK_STARTED,
				"tick": t,
				"enemy": e.id,
				"def_index": e.def_index,
				"pattern": int(pattern.pattern_id),
				"pos": e.pos,
				"aim": aim,
			}
		)
	)
	var shots: Array = pattern.shots
	for si in shots.size():
		var shot: Resource = shots[si]
		var dir := aim.rotated(deg_to_rad(float(shot.angle_offset_deg)))
		world.spawn_projectile(
			e.pos + dir * float(shot.spawn_offset),
			dir * float(shot.speed),
			float(shot.radius),
			int(shot.ttl_ticks),
			ActorState.FACTION_HOSTILE,
			int(shot.damage),
			int(pattern.pattern_id),
			int(shot.program),
			float(shot.prog_a),
			float(shot.prog_b),
			float(shot.prog_c),
			int(shot.max_passes)
		)
	e.cooldowns[e.winding_slot] = t + int(es.cooldown_ticks)
	e.state_until = t + int(es.recover_ticks)
	e.winding_slot = -1


## Closed-form intercept (M6, CORE-32-deterministic): solve
## |d + v*t| = s*t for the earliest positive t and aim at the future
## point. Reads the target's serialized vel — NEVER prev_pos (that is
## presentation-only). Falls back to the current position when no
## forward solution exists (target at or beyond shot speed). Returns an
## UNnormalized aim vector; the caller normalizes.
static func _intercept_aim(
	origin: Vector2, tpos: Vector2, tvel: Vector2, shot_speed: float
) -> Vector2:
	var d := tpos - origin
	var a := tvel.dot(tvel) - shot_speed * shot_speed
	var b := 2.0 * d.dot(tvel)
	var c := d.dot(d)
	var t_hit := -1.0
	if absf(a) < 0.0001:
		if absf(b) > 0.0001:
			t_hit = -c / b
	else:
		var disc := b * b - 4.0 * a * c
		if disc >= 0.0:
			var sq := sqrt(disc)
			var t1 := (-b - sq) / (2.0 * a)
			var t2 := (-b + sq) / (2.0 * a)
			var lo := minf(t1, t2)
			t_hit = lo if lo > 0.0 else maxf(t1, t2)
	if t_hit <= 0.0:
		return d
	return d + tvel * t_hit
