extends RefCounted
## DodgeBot primary policy (docs/12 §2.11): movement-only — fire AND
## ability disabled by construction (the frames it emits carry neither).
## Per tick: enumerate 16 headings + stay, project every hostile
## projectile, armed hazard, and contact-damage enemy body forward K
## ticks (projectile motion programs are pure functions of age — that is
## the closed form), walk each candidate through the shared Kinematics
## slide, pick the safest. Deterministic: fixed candidate order, strict
## improvement, no RNG anywhere.
##
## INPUT HONESTY: InputFrame movement is {-1,0,1} per axis (§2.4), so
## the 16 headings are realized as alternating pairs of adjacent 8-dir
## frames keyed on tick parity — every emitted frame is a legal human
## input and the sim cannot tell the bot apart (§2.8).

const InputFrame := preload("res://sim/input_frame.gd")
const Kinematics := preload("res://sim/systems/kinematics.gd")
const ActorState := preload("res://sim/actor_state.gd")
const EnemyState := preload("res://sim/enemy_state.gd")
const ProjectilePool := preload("res://sim/projectile_pool.gd")

## Projection depth K, in ticks. 60 (1 s) is enough for simulated pursuit
## to reveal a closing corner BEFORE the bot enters it — 30/45 with
## linear body extrapolation both cornered and failed the rusher proof
## (repros in reports/; the fix history lives in the M5 session log).
const HORIZON := 60
## Fully-safe stationkeeping ring (tiles) around the nearest enemy:
## orbit at this distance instead of fleeing radially — pure
## distance-maximizing walks drift into wall pockets and die there
## (2531 ticks wedged in an aisle nook, proof FAIL #3). Sits between
## the Rusher's slash trigger (1.2) and the Husk's fire trigger (7).
const RING := 4.0
## Threat inflation (tiles): projected overlaps use hitbox + this margin,
## so near-misses count against a candidate before they become hits.
const MARGIN := 0.12
## Threat-relevance filter radius (tiles): fastest shot in the game is
## 14 t/s (§3.3) + player 5.5 ceiling over the horizon, padded.
const RELEVANT_R := 12.0

## The 8 legal frame directions, angle-ordered (index i = i * 45 deg).
const DIR_X: Array[int] = [1, 1, 0, -1, -1, -1, 0, 1]
const DIR_Y: Array[int] = [0, 1, 1, 1, 0, -1, -1, -1]


## One InputFrame of pure movement for player_index, re-planned per tick.
static func compute_frame(world: RefCounted, player_index: int) -> RefCounted:
	var frame := InputFrame.new()
	var p: RefCounted = world.players[player_index]
	if p.dead:
		return frame
	var t: int = world.tick
	var threats := _project_threats(world, p)
	# Fast path: nothing relevant within reach — stand (deterministic).
	if int(threats.count) == 0:
		return frame
	# Walls only matter to candidate walks when the horizon's reach can
	# touch one; checked ONCE per tick, exact slide used only then.
	var reach: float = p.move_speed * HORIZON * world.DT + p.radius + 0.1
	var use_slide := not _clear_of_walls(world.bitgrid, p.pos, reach)
	# Stationkeeping anchor: the CENTROID of nearby live enemies — packs
	# are orbited as one cluster (a nearest-enemy anchor dragged the bot
	# through the other chasers when three converged; composition FAIL).
	var soft: Array = threats.soft_bodies
	var ppos: Vector2 = p.pos
	var anchor := Vector2.ZERO
	var anchor_n := 0
	for sp: Vector2 in soft:
		if ppos.distance_to(sp) <= 8.0:
			anchor += sp
			anchor_n += 1
	if anchor_n == 0:
		for sp: Vector2 in soft:
			anchor += sp
			anchor_n += 1
	var has_anchor := anchor_n > 0
	if has_anchor:
		anchor /= float(anchor_n)
	var best_candidate := 0
	var best_survival := -1
	var best_clearance := -1.0e18
	var best_ring := -1.0e18
	# Candidate 0 = stay; 1..16 = headings h*22.5 deg. Even headings are a
	# single dir; odd headings alternate the two adjacent dirs by parity.
	# Keys: survival first, always. Then MODE SPLIT: fully safe for the
	# whole horizon -> the ORBIT score decides (hold RING distance from
	# the anchor, advance tangentially, avoid walls — greedy flee kept
	# cornering itself); under predicted threat -> grazing margin
	# (clearance) decides, orbit breaks ties.
	for c in 17:
		var result := _score(world, p, c, t, threats, use_slide)
		var survival := int(result.survival)
		var clearance := float(result.clearance)
		var end_pos: Vector2 = result.end
		var wall_pen := maxf(0.0, 2.5 - _wall_clearance(world.bitgrid, end_pos, 3.0)) * 2.0
		var ring_score := -wall_pen
		if has_anchor:
			ring_score -= absf(end_pos.distance_to(anchor) - RING) * 2.0
			var adv := wrapf((end_pos - anchor).angle() - (p.pos - anchor).angle(), -PI, PI)
			ring_score += adv * 0.8
		var better := false
		if survival > best_survival:
			better = true
		elif survival == best_survival:
			if survival > HORIZON:
				if ring_score > best_ring + 0.0001:
					better = true
				elif absf(ring_score - best_ring) <= 0.0001 and clearance > best_clearance + 0.0001:
					better = true
			else:
				if clearance > best_clearance + 0.0001:
					better = true
				elif absf(clearance - best_clearance) <= 0.0001 and ring_score > best_ring + 0.0001:
					better = true
		if better:
			best_candidate = c
			best_survival = survival
			best_clearance = clearance
			best_ring = ring_score
	if best_candidate > 0:
		var d := _candidate_dir(best_candidate, t)
		frame.move_x = DIR_X[d]
		frame.move_y = DIR_Y[d]
		frame.normalized = true
	return frame


## Frame direction index for candidate c at tick t (parity realizes the
## odd 22.5-degree headings as alternating adjacent dirs).
static func _candidate_dir(c: int, t: int) -> int:
	var h := c - 1
	@warning_ignore("integer_division")
	var base := h / 2
	if h % 2 == 0:
		return base
	return base if t % 2 == 0 else (base + 1) % 8


## Survival ticks, min clearance over the walk, and the candidate's end
## position (the orbit score derives from it in compute_frame).
## use_slide walks the real Kinematics slide (near walls); the open-field
## path integrates directly — identical where walls are unreachable
## within the horizon.
static func _score(
	world: RefCounted, p: RefCounted, c: int, t: int, threats: Dictionary, use_slide: bool
) -> Dictionary:
	var grid: RefCounted = world.bitgrid
	var dt: float = world.DT
	var speed: float = p.move_speed
	var pr: float = p.radius
	var pos: Vector2 = p.pos
	var proj_pos: Array = threats.proj_pos
	var proj_r: PackedFloat32Array = threats.proj_r
	var proj_gone: PackedInt32Array = threats.proj_gone
	var bodies: Array = threats.bodies
	var hazards: Array = threats.hazards
	var body_pos: Array = []
	var body_speed: PackedFloat32Array = PackedFloat32Array()
	var body_r: PackedFloat32Array = PackedFloat32Array()
	for b: Dictionary in bodies:
		body_pos.append(b.pos)
		body_speed.append(float(b.speed))
		body_r.append(float(b.radius))
	var survival := HORIZON + 1
	var clearance := 1.0e18
	for h in range(1, HORIZON + 1):
		if c > 0:
			var d := _candidate_dir(c, t + h - 1)
			var mv := Vector2(float(DIR_X[d]), float(DIR_Y[d]))
			if mv.length_squared() > 1.0:
				mv = mv.normalized()
			if use_slide:
				pos = Kinematics.move_circle(grid, pos, pr, mv * speed * dt)
			else:
				pos += mv * speed * dt
		var step_positions: Array = proj_pos[h - 1]
		for i in step_positions.size():
			if proj_gone[i] < h:
				continue
			var q: Vector2 = step_positions[i]
			var rr := proj_r[i] + pr
			var dist := pos.distance_to(q)
			clearance = minf(clearance, dist - rr)
			if dist < rr + MARGIN:
				survival = h
		for k in body_pos.size():
			# Simulated pursuit, coupled to THIS candidate's path: chasers
			# home on the player (enemy_step CHASER), so linear
			# extrapolation lies exactly when it matters — in corners.
			var bp: Vector2 = body_pos[k]
			var to_player := pos - bp
			var d2 := to_player.length()
			if d2 > 0.0001:
				bp += to_player / d2 * minf(body_speed[k] * dt, d2)
				body_pos[k] = bp
			var rr2: float = body_r[k] + pr
			var dist2 := pos.distance_to(bp)
			clearance = minf(clearance, dist2 - rr2)
			if dist2 < rr2 + MARGIN:
				survival = h
		for hz: Dictionary in hazards:
			if int(hz.arm_in) == h:
				var rr3: float = float(hz.radius) + pr
				var dist3 := pos.distance_to(Vector2(hz.pos))
				clearance = minf(clearance, dist3 - rr3)
				if dist3 < rr3 + MARGIN:
					survival = h
		if survival <= h:
			break
	return {"survival": survival, "clearance": clearance, "end": pos}


## Distance from pos to the nearest solid-cell edge within max_r (returns
## max_r when nothing solid is that close).
static func _wall_clearance(grid: RefCounted, pos: Vector2, max_r: float) -> float:
	var x0 := int(floorf(pos.x - max_r))
	var x1 := int(floorf(pos.x + max_r))
	var y0 := int(floorf(pos.y - max_r))
	var y1 := int(floorf(pos.y + max_r))
	var best := max_r
	for ty in range(y0, y1 + 1):
		for tx in range(x0, x1 + 1):
			if not grid.is_solid(tx, ty):
				continue
			var qx := clampf(pos.x, float(tx), float(tx) + 1.0)
			var qy := clampf(pos.y, float(ty), float(ty) + 1.0)
			best = minf(best, pos.distance_to(Vector2(qx, qy)))
	return best


## Precompute per-tick projected positions for every relevant hostile
## projectile (closed-form: motion-program velocity at any age), plus
## contact bodies (linear extrapolation) and pending hostile hazards.
static func _project_threats(world: RefCounted, p: RefCounted) -> Dictionary:
	var pool: RefCounted = world.projectiles
	var t: int = world.tick
	var dt: float = world.DT
	var ppos: Vector2 = p.pos
	var idx: Array[int] = []
	var act: PackedByteArray = pool.active
	var fac: PackedByteArray = pool.faction
	var px: PackedFloat32Array = pool.pos_x
	var py: PackedFloat32Array = pool.pos_y
	for s in pool.CAPACITY:
		if act[s] == 0 or fac[s] != ActorState.FACTION_HOSTILE:
			continue
		if Vector2(px[s], py[s]).distance_to(ppos) > RELEVANT_R:
			continue
		idx.append(s)
	var n := idx.size()
	var proj_r := PackedFloat32Array()
	var proj_gone := PackedInt32Array()
	proj_r.resize(n)
	proj_gone.resize(n)
	var cur := []
	cur.resize(n)
	var vx: PackedFloat32Array = pool.vel_x
	var vy: PackedFloat32Array = pool.vel_y
	var dx_: PackedFloat32Array = pool.dir_x
	var dy_: PackedFloat32Array = pool.dir_y
	var rad: PackedFloat32Array = pool.radius
	var ttl: PackedInt32Array = pool.ttl
	var prog: PackedByteArray = pool.program
	var pa: PackedFloat32Array = pool.prog_a
	var pb: PackedFloat32Array = pool.prog_b
	var pc: PackedFloat32Array = pool.prog_c
	var st: PackedInt32Array = pool.spawn_tick
	for i in n:
		var s := idx[i]
		proj_r[i] = rad[s]
		proj_gone[i] = ttl[s]  # despawns when remaining ttl reaches 0
		cur[i] = Vector2(px[s], py[s])
	var proj_pos: Array = []
	for h in range(1, HORIZON + 1):
		var step: Array = []
		step.resize(n)
		for i in n:
			var s := idx[i]
			var age := float(t + h - st[s])
			var v := Vector2(vx[s], vy[s])
			match prog[s]:
				ProjectilePool.Program.DECELERATE:
					var sp := maxf(0.0, pa[s] - pb[s] * age * dt)
					v = Vector2(dx_[s], dy_[s]) * sp
				ProjectilePool.Program.SINE:
					var sway := pb[s] * sin(age * dt * pc[s])
					v = (Vector2(dx_[s], dy_[s]) * pa[s] + Vector2(-dy_[s], dx_[s]) * sway)
				ProjectilePool.Program.BOOMERANG:
					if age < pa[s]:
						v = Vector2(dx_[s], dy_[s]) * pb[s]
					else:
						v = Vector2(-dx_[s], -dy_[s]) * pc[s]
			cur[i] = Vector2(cur[i]) + v * dt
			step[i] = cur[i]
		proj_pos.append(step)
	var bodies: Array = []
	var soft_bodies: Array = []
	var hazards: Array = []
	var defs: Array = world.enemy_defs
	for e: RefCounted in world.enemies:
		var def_index: int = e.def_index
		if def_index < 0 or e.hp <= 0:
			continue
		var def: Resource = defs[def_index]
		var epos: Vector2 = e.pos
		if epos.distance_to(ppos) > RELEVANT_R:
			continue
		# Every live enemy repels positioning (they attack when close).
		# HARD pursuit threats: contact-damage bodies (radius = body) AND
		# melee slashers — their trigger range is a do-not-enter bubble
		# (the sim starts a windup at center-distance <= trigger), pursued
		# with the same simulation. Without this, removing contact damage
		# deleted the bot's long-horizon pack pressure and compositions
		# failed.
		soft_bodies.append(epos)
		var melee_trigger := _melee_trigger(def)
		if int(def.contact_damage) > 0 or melee_trigger > 0.0:
			var eff_r: float = e.radius
			if melee_trigger > 0.0:
				eff_r = maxf(eff_r, melee_trigger - float(p.radius))
			(
				bodies
				. append(
					{
						"pos": epos,
						"speed": float(def.move_speed),
						"radius": eff_r,
					}
				)
			)
		# An active windup is a telegraphed future threat — the bot dodges
		# on the telegraph, the cue humans get (Law 4/8). The danger circle
		# is the volley's BIRTH RING (where shots materialize at the arm
		# tick), NOT the full sweep: spawned shots are ordinary pool
		# projectiles the normal projection dodges reactively. A full-reach
		# disc marked every fleeing candidate doomed and cost a proof.
		if int(e.ai_state) == EnemyState.AIState.WINDUP and e.winding_slot >= 0:
			var ring := _slot_birth_ring(def, int(e.winding_slot))
			var warm := int(e.state_until) - t
			if ring > 0.0 and warm >= 1 and warm <= HORIZON:
				hazards.append({"pos": epos, "radius": ring, "arm_in": warm})
	for hz: Dictionary in world.hazards:
		if int(hz.faction) != ActorState.FACTION_HOSTILE:
			continue
		var arm_in := int(hz.arm_at_tick) - t
		if arm_in >= 1 and arm_in <= HORIZON:
			hazards.append({"pos": hz.pos, "radius": hz.radius, "arm_in": arm_in})
	return {
		"proj_pos": proj_pos,
		"proj_r": proj_r,
		"proj_gone": proj_gone,
		"bodies": bodies,
		"soft_bodies": soft_bodies,
		"hazards": hazards,
		"count": n + soft_bodies.size() + hazards.size(),
	}


## Smallest melee-class trigger range on a def (emitter slots with
## trigger_range <= 2.0), or 0.0 when the def has none.
static func _melee_trigger(def: Resource) -> float:
	var best := 0.0
	var emitters: Array = def.emitters
	for es: Resource in emitters:
		var tr := float(es.trigger_range)
		if tr <= 2.0 and (best == 0.0 or tr < best):
			best = tr
	return best


## Birth ring of one emitter slot's volley: how far from the enemy center
## shots MATERIALIZE (spawn offset + shot radius, maxed over the pattern)
## plus a reaction pad. Standing inside it at the arm tick is a
## near-guaranteed hit; outside it, the spawned shots are dodged as
## ordinary projectiles.
static func _slot_birth_ring(def: Resource, slot_index: int) -> float:
	var emitters: Array = def.emitters
	if slot_index >= emitters.size():
		return 0.0
	var es: Resource = emitters[slot_index]
	var pattern: Resource = es.pattern
	if pattern == null:
		return 0.0
	var ring := 0.0
	var shots: Array = pattern.shots
	for shot: Resource in shots:
		ring = maxf(ring, float(shot.spawn_offset) + float(shot.radius))
	return ring + 0.35 if ring > 0.0 else 0.0


## True when no solid tile sits within `reach` of pos — the horizon's
## candidate walks cannot touch a wall, so straight integration is exact.
static func _clear_of_walls(grid: RefCounted, pos: Vector2, reach: float) -> bool:
	var x0 := int(floorf(pos.x - reach))
	var x1 := int(floorf(pos.x + reach))
	var y0 := int(floorf(pos.y - reach))
	var y1 := int(floorf(pos.y + reach))
	for ty in range(y0, y1 + 1):
		for tx in range(x0, x1 + 1):
			if grid.is_solid(tx, ty):
				return false
	return true
