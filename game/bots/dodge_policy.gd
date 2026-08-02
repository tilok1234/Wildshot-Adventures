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
const PlayerMove := preload("res://sim/systems/player_move.gd")
const ProjectileStep := preload("res://sim/systems/projectile_step.gd")
const RiftStep := preload("res://sim/systems/rift_step.gd")
const ActorState := preload("res://sim/actor_state.gd")
const EnemyState := preload("res://sim/enemy_state.gd")
const ProjectilePool := preload("res://sim/projectile_pool.gd")
const EnemyDef := preload("res://data/enemy_def.gd")

## Policy modes (M7 §2.11). PRIMARY is the canonical proof policy.
## REACTIVE (ledger #11's re-adjudication route) differs in exactly one
## model choice: melee-slot enemies are bodies at their RAW radius —
## the bot may enter trigger range and dodge the windup on its
## telegraph like a human, instead of treating the whole trigger
## bubble as do-not-enter. ORBIT and AXIS_STRAFE are deliberately
## simple baselines (no threat projection) for evidence diversity —
## they are expected to be worse and their reports say so.
enum Policy { PRIMARY, REACTIVE, ORBIT, AXIS_STRAFE }

## Baseline axis-strafe flip period (ticks).
const AXIS_FLIP := 30

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
## ANCHOR-policy enemies cannot chase, so standing outside their shot
## reach is free and permanent — the CORE-44 lesson packs teach. Each
## live anchor projects a keep-out disc of its data reach plus this pad;
## candidates ending inside are penalized (M6 fanmaw composition: RING-4
## centroid orbiting parked the bot inside the fan envelope and died
## pinched against the chaser — the bot learns anchors like it learned
## melee at M5).
const ANCHOR_PAD := 0.5
## Keep-out weight per tile of anchor-disc penetration. Strictly above
## the RING deviation weight (2.0) so the summed score slopes outward
## everywhere inside the disc instead of plateauing against the ring
## pull.
const ANCHOR_W := 3.0
## Threat inflation (tiles): projected overlaps use hitbox + this margin,
## so near-misses count against a candidate before they become hits.
const MARGIN := 0.12
## Threat-relevance filter radius (tiles): fastest shot in the game is
## 14 t/s (§3.3) + player 5.5 ceiling over the horizon, padded.
const RELEVANT_R := 12.0
## sl-0115: keep-out weight per tile of deep-edge penetration (rift
## arenas). The deep strip drains the line, not the body — a
## POSITIONING penalty like the anchor discs, never a survival threat
## (CORE-33 dodge honesty stays about bullets).
const DEEP_EDGE_W := 3.0

## The 8 legal frame directions, angle-ordered (index i = i * 45 deg).
const DIR_X: Array[int] = [1, 1, 0, -1, -1, -1, 0, 1]
const DIR_Y: Array[int] = [0, 1, 1, 1, 0, -1, -1, -1]


## One InputFrame of pure movement for player_index, re-planned per tick.
static func compute_frame(
	world: RefCounted, player_index: int, policy: int = Policy.PRIMARY
) -> RefCounted:
	var frame := InputFrame.new()
	var p: RefCounted = world.players[player_index]
	if p.dead:
		return frame
	var t: int = world.tick
	if policy == Policy.ORBIT or policy == Policy.AXIS_STRAFE:
		return _baseline_frame(world, p, t, policy)
	var threats := _project_threats(world, p, policy == Policy.REACTIVE)
	# Fast path: nothing relevant within reach — stand (deterministic).
	if int(threats.count) == 0:
		return frame
	# Walls only matter to candidate walks when the horizon's reach can
	# touch one; checked ONCE per tick, exact slide used only then.
	# Candidate walks use the LOCOMOTION radius (one truth with
	# player_move); threat clearances keep the combat hurtbox.
	# sl-0078: checked against the CONSERVATIVE bitgrid — every prop
	# disc lives in a bitgrid-solid cell by construction, so this one
	# check also arms exact slides wherever discs are reachable.
	var reach: float = p.move_speed * HORIZON * world.DT + PlayerMove.TERRAIN_RADIUS + 0.1
	# sl-0115: the pull carries the body further than legs alone —
	# the wall-reach check must include it or slides arm too late.
	if world.rift_pull != null:
		reach += (
			float(world.rift_pull.pull_tiles_per_sec)
			* float(world.rift_pull.player_mult)
			* HORIZON
			* world.DT
		)
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
		# Positioning stays CONSERVATIVE (sl-0078): prop fields keep
		# repelling the stationkeeper even though the body can thread
		# them — a pocket the sprite fits is not a pocket to LIVE in
		# (the 0.35 hurtbox cannot dodge inside sprite-width gaps;
		# loop_ring2 parked 3600 ticks in one and got clipped at t436).
		# Escapes still WALK the true fit-rule model in _score.
		var wall_pen := maxf(0.0, 2.5 - _wall_clearance(world.bitgrid, end_pos, 3.0)) * 2.0
		var ring_score := -wall_pen
		if has_anchor:
			ring_score -= absf(end_pos.distance_to(anchor) - RING) * 2.0
			var adv := wrapf((end_pos - anchor).angle() - (p.pos - anchor).angle(), -PI, PI)
			ring_score += adv * 0.8
		var zones: Array = threats.anchor_zones
		for z: Dictionary in zones:
			var zpen := maxf(0.0, float(z.reach) - end_pos.distance_to(Vector2(z.pos)))
			ring_score -= zpen * ANCHOR_W
		# sl-0115: the deep strip strains the line — positioning stays
		# out of it the way it stays out of anchor envelopes.
		if world.rift_pull != null:
			ring_score -= maxf(0.0, end_pos.x - RiftStep.deep_edge_x(world)) * DEEP_EDGE_W
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
	var grid: RefCounted = world.walk_grid
	var discs: Dictionary = world.prop_discs
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
	# sl-0115: in a rift arena EVERY candidate drifts with the pull —
	# including "stay" (a still body is not still; the prototype's
	# shape). The same closed form the sim integrates (player_move).
	var rift: bool = world.rift_pull != null
	var pull_mult: float = float(world.rift_pull.player_mult) if rift else 0.0
	for h in range(1, HORIZON + 1):
		var step := Vector2.ZERO
		if c > 0:
			var d := _candidate_dir(c, t + h - 1)
			var mv := Vector2(float(DIR_X[d]), float(DIR_Y[d]))
			if mv.length_squared() > 1.0:
				mv = mv.normalized()
			step = mv * speed * dt
		if rift:
			step += RiftStep.pull_vec(world, t + h - 1) * pull_mult * dt
		if step != Vector2.ZERO:
			if use_slide:
				# Walk with the locomotion radius (player_move parity);
				# pr below stays the combat hurtbox for threat overlap.
				pos = Kinematics.move_circle(grid, pos, PlayerMove.TERRAIN_RADIUS, step, discs)
			else:
				pos += step
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


## Baseline policies (M7): no projection, one simple rule each. ORBIT
## walks tangent around the live-enemy centroid; AXIS_STRAFE oscillates
## perpendicular to the nearest enemy, flipping every AXIS_FLIP ticks.
## Every emitted frame is still a legal human input.
static func _baseline_frame(world: RefCounted, p: RefCounted, t: int, policy: int) -> RefCounted:
	var frame := InputFrame.new()
	var centroid := Vector2.ZERO
	var nearest := Vector2.ZERO
	var best := INF
	var n := 0
	for e: RefCounted in world.enemies:
		if e.def_index < 0 or e.hp <= 0:
			continue
		var epos: Vector2 = e.pos
		centroid += epos
		n += 1
		var d2: float = p.pos.distance_squared_to(epos)
		if d2 < best:
			best = d2
			nearest = epos
	if n == 0:
		return frame
	centroid /= float(n)
	var dir := Vector2.ZERO
	if policy == Policy.ORBIT:
		var out: Vector2 = p.pos - centroid
		var dist := out.length()
		if dist < 0.001:
			out = Vector2.RIGHT
			dist = 1.0
		var tangent := Vector2(-out.y, out.x) / dist
		# Hold RING distance while circling: blend radial correction in.
		var radial: Vector2 = out / dist * clampf(RING - dist, -1.0, 1.0)
		dir = (tangent + radial).normalized()
	else:
		var to_e: Vector2 = nearest - p.pos
		if to_e.length_squared() < 0.001:
			to_e = Vector2.RIGHT
		var perp := Vector2(-to_e.y, to_e.x).normalized()
		@warning_ignore("integer_division")
		var flip := -1.0 if (t / AXIS_FLIP) % 2 == 1 else 1.0
		dir = perp * flip
	var h := wrapi(roundi(dir.angle() / (TAU / 16.0)), 0, 16)
	var d := _candidate_dir(h + 1, t)
	frame.move_x = DIR_X[d]
	frame.move_y = DIR_Y[d]
	frame.normalized = true
	return frame


## Precompute per-tick projected positions for every relevant hostile
## projectile (closed-form: motion-program velocity at any age), plus
## contact bodies (linear extrapolation) and pending hostile hazards.
## reactive=true is the REACTIVE policy's one model change: melee-slot
## enemies stay bodies at their RAW radius (enter range, dodge the
## windup on its telegraph) instead of trigger-bubble inflation.
static func _project_threats(world: RefCounted, p: RefCounted, reactive: bool) -> Dictionary:
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
	# sl-0078: the projection shares the sim's terrain truth — a shot
	# that dies on a wall or a prop disc stops threatening from that
	# step on (one truth for the sim and the model; previously the
	# model conservatively assumed terrain never kills shots, and the
	# fit rule's tighter margins made that over-estimate cost real
	# dodges — loop_ring2's t436 clip found it).
	var wgrid: RefCounted = world.walk_grid
	var wdiscs: Dictionary = world.prop_discs
	# sl-0115: hostile shots drift with the pull (×bullet_mult) — the
	# projection integrates the same per-tick displacement the sim
	# applies, or margins lie exactly at fit-rule scale.
	var rift: bool = world.rift_pull != null
	var bullet_mult: float = float(world.rift_pull.bullet_mult) if rift else 0.0
	var proj_pos: Array = []
	for h in range(1, HORIZON + 1):
		var step: Array = []
		step.resize(n)
		var pull_step := Vector2.ZERO
		if rift:
			pull_step = RiftStep.pull_vec(world, t + h - 1) * bullet_mult * dt
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
			cur[i] = Vector2(cur[i]) + v * dt + pull_step
			step[i] = cur[i]
			if proj_gone[i] >= h:
				var q: Vector2 = cur[i]
				if (
					ProjectileStep._terrain_cell(wgrid, q.x, q.y, rad[s]) >= 0
					or ProjectileStep._terrain_disc(wdiscs, q.x, q.y, rad[s]) >= 0
				):
					proj_gone[i] = h - 1
		proj_pos.append(step)
	var bodies: Array = []
	var soft_bodies: Array = []
	var hazards: Array = []
	var anchor_zones: Array = []
	var defs: Array = world.enemy_defs
	for e: RefCounted in world.enemies:
		var def_index: int = e.def_index
		if def_index < 0 or e.hp <= 0:
			continue
		var def: Resource = defs[def_index]
		# Phase-resolved behavior (§3.5): policy and emitter set come
		# from the CURRENT phase — a P2-anchored elite is a keep-out
		# disc this tick and an orbit target again when P3 starts
		# chasing. Reading serialized live state (phase_index,
		# move_speed) keeps the bot honest across transitions.
		var eph: int = e.phase_index
		var e_policy: int = def.active_policy(eph)
		var e_emitters: Array = def.active_emitters(eph)
		var epos: Vector2 = e.pos
		if epos.distance_to(ppos) > RELEVANT_R:
			continue
		# Mobile enemies repel positioning (they attack when close).
		# HARD pursuit threats: contact-damage bodies (radius = body) AND
		# melee slashers — their trigger range is a do-not-enter bubble
		# (the sim starts a windup at center-distance <= trigger), pursued
		# with the same simulation. Without this, removing contact damage
		# deleted the bot's long-horizon pack pressure and compositions
		# failed.
		# ANCHOR-policy enemies are keep-out DISCS (shot reach from the
		# def's own data), never orbit targets: an anchor cannot close the
		# gap, so respecting its envelope costs nothing — while averaging
		# it into the stationkeeping centroid dragged the bot to point-
		# blank range of the pack's chasers (second_contact pinch). Only
		# MOBILE enemies join the orbit cluster.
		if e_policy == EnemyDef.MovementPolicy.ANCHOR:
			var reach := _anchor_reach(e_emitters, dt)
			if reach > 0.0:
				anchor_zones.append({"pos": epos, "reach": reach + ANCHOR_PAD})
		else:
			soft_bodies.append(epos)
		var melee_trigger := _melee_trigger(e_emitters)
		if int(def.contact_damage) > 0 or melee_trigger > 0.0:
			var eff_r: float = e.radius
			if melee_trigger > 0.0 and not reactive:
				eff_r = maxf(eff_r, melee_trigger - float(p.radius))
			(
				bodies
				. append(
					{
						"pos": epos,
						"speed": float(e.move_speed),
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
			var ring := _slot_birth_ring(e_emitters, int(e.winding_slot))
			var warm := int(e.state_until) - t
			if ring > 0.0 and warm >= 1 and warm <= HORIZON:
				hazards.append({"pos": epos, "radius": ring, "arm_in": warm})
	for hz: Dictionary in world.hazards:
		if int(hz.faction) != ActorState.FACTION_HOSTILE:
			continue
		# Every future damage pulse inside the horizon is a hazard step:
		# the first (arm, or the next lingering pulse — M6 zones burn on a
		# deterministic cadence) plus each interval after. Between pulses a
		# zone is honestly crossable; standing in one at a pulse tick is
		# death, and the candidate walk sees exactly that.
		var pulse_in := int(hz.arm_at_tick) - t
		if pulse_in < 1:
			if t >= int(hz.get("linger_until", 0)):
				continue
			pulse_in = maxi(1, int(hz.get("next_damage_tick", 0)) - t)
		var interval := maxi(1, int(hz.get("hit_interval_ticks", 0)))
		var last_in := int(hz.get("linger_until", hz.arm_at_tick)) - t
		while pulse_in <= HORIZON and pulse_in <= last_in:
			hazards.append({"pos": hz.pos, "radius": hz.radius, "arm_in": pulse_in})
			if int(hz.get("hit_interval_ticks", 0)) <= 0:
				break
			pulse_in += interval
	return {
		"proj_pos": proj_pos,
		"proj_r": proj_r,
		"proj_gone": proj_gone,
		"bodies": bodies,
		"soft_bodies": soft_bodies,
		"hazards": hazards,
		"anchor_zones": anchor_zones,
		"count": n + soft_bodies.size() + hazards.size() + anchor_zones.size(),
	}


## Max shot reach across an emitter set (phase-resolved by the caller):
## spawn offset + flight distance (speed x ttl, closed form — same DT
## the sim integrates with) + shot radius. 0.0 when it has no shots.
static func _anchor_reach(emitters: Array, dt: float) -> float:
	var reach := 0.0
	for es: Resource in emitters:
		var pattern: Resource = es.pattern
		if pattern == null:
			continue
		var shots: Array = pattern.shots
		for shot: Resource in shots:
			var flight := float(shot.speed) * float(int(shot.ttl_ticks)) * dt
			reach = maxf(reach, float(shot.spawn_offset) + flight + float(shot.radius))
	return reach


## Smallest melee-class trigger range on an emitter set (slots with
## trigger_range <= 2.0), or 0.0 when it has none.
static func _melee_trigger(emitters: Array) -> float:
	var best := 0.0
	for es: Resource in emitters:
		var tr := float(es.trigger_range)
		if tr <= 2.0 and (best == 0.0 or tr < best):
			best = tr
	return best


## Birth ring of one emitter slot's volley: how far from the enemy center
## shots MATERIALIZE (spawn offset + shot radius, maxed over the pattern)
## plus a reaction pad. Standing inside it at the arm tick is a
## near-guaranteed hit; outside it, the spawned shots are dodged as
## ordinary projectiles. The set is phase-resolved by the caller.
static func _slot_birth_ring(emitters: Array, slot_index: int) -> float:
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
