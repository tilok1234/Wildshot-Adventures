## sl-0219 CHASE-LEASH DIAGNOSIS probe (headless; the committed
## measurement record — the diag_pinch precedent). MEASURE BEFORE
## TOUCHING: the designer's finding is "they start cluttering up and
## ganging unreasonably up on you if you run around the map not
## killing everything." This drives a real class-floor-speed walker
## (3.6 t/s on real Kinematics input frames) down a real site
## corridor on the b77 slice (sites 123/128/129/98/99 — the x~62
## north-south chain, five sites over ~29 tiles, all inside each
## other's 30-t sleep envelope) and prints the numbers:
##   phase 1 — three road laps: engaged/near-8/live counts per sample
##   phase 2 — stand mid-road 240 t: the train catches (gang size)
##   phase 3 — step off-road NE and hold: shed or not
##   phase 4 — rim census: home-distance of every live site member
##     (the park-at-the-rim ratchet the tether's stop-inside leaves)
## Static truths this probe rides (from source): aggro 12 uniform,
## checked ONLY in IDLE; NO give-up by player distance exists; the
## tether walk-home stops the tick home_dist <= 12 (the rim);
## re-centering happens only through a >30 sleep-fold.
##
## Run: godot --headless --path . --script tests/chase_leash/chase_leash_probe.gd
extends SceneTree

const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const EnemyState := preload("res://sim/enemy_state.gd")

const PACK := "res://assets/worldforge-packs/wildshot-overworld-pack-dusk/"
const ROAD_N := Vector2(62.5, 98.5)
const ROAD_S := Vector2(62.5, 127.5)
const ROAD_MID := Vector2(62.5, 112.5)
const OFF_ROAD := Vector2(80.5, 90.5)
const SPEED := 3.6

var world: RefCounted = null
var player: RefCounted = null


func _init() -> void:
	var scenario: Resource = load("res://data/scenarios/slice_overworld.tres")
	var wf := WorldforgePack.validate(PACK)
	if not bool(wf.ok):
		printerr("FAIL: pack invalid")
		quit(1)
		return
	world = ScenarioLoader.build_world(scenario, 100, wf.bitgrid)
	player = world.players[0]
	player.pos = ROAD_N
	player.prev_pos = ROAD_N
	player.move_speed = SPEED
	player.hp = 9999999
	player.max_hp = 9999999

	print("== phase 1: three road laps (%s <-> %s at %.1f t/s)" % [ROAD_N, ROAD_S, SPEED])
	var t := 0
	for target: Vector2 in [ROAD_S, ROAD_N, ROAD_S, ROAD_N, ROAD_S, ROAD_N]:
		t = _walk_to(target, t)
		if t < 0:
			return
		print("-- reached %s at t=%d: %s" % [target, t, _counts_line()])

	print("== phase 2: stand mid-road %s for 240 t (does the train catch?)" % ROAD_MID)
	t = _walk_to(ROAD_MID, t)
	if t < 0:
		return
	for i in 240:
		_step_toward(player.pos)
		t += 1
		if (i + 1) % 60 == 0:
			_sample(t)

	print("== phase 3: step off-road NE to %s and hold 300 t (shed test)" % OFF_ROAD)
	t = _walk_to(OFF_ROAD, t)
	if t < 0:
		return
	for i in 300:
		_step_toward(player.pos)
		t += 1
		if (i + 1) % 60 == 0:
			_sample(t)

	print("== phase 4: rim census (live site members, distance from their home cell)")
	var at_home := 0
	var displaced := 0
	var rim := 0
	var max_home := 0.0
	for e: RefCounted in world.enemies:
		if e.hp <= 0 or e.site_index < 0 or e.site_index >= world.site_defs.size():
			continue
		var home: Vector2 = world.site_defs[e.site_index].cell
		var hd: float = e.pos.distance_to(home)
		max_home = maxf(max_home, hd)
		if hd <= 6.0:
			at_home += 1
		else:
			displaced += 1
			if hd > 10.0:
				rim += 1
	print(
		(
			"rim census: %d near home (<=6t), %d displaced (>6t), %d rim-parked (>10t), max home-dist %.1f"
			% [at_home, displaced, rim, max_home]
		)
	)
	print("chase_leash_probe: done at t=%d" % t)
	quit(0)


## Walk to `target` along a BFS route on the conservative bitgrid
## (what a player does around obstacles — a straight-line walker
## wedges on the first tree band and its stall would pollute the
## measurement). Returns the advanced tick, or -1 on failure.
func _walk_to(target: Vector2, t: int) -> int:
	var route := _bfs_route(player.pos, target)
	if route.is_empty():
		printerr("FAIL: no route %s -> %s" % [player.pos, target])
		quit(1)
		return -1
	for wp: Vector2 in route:
		var guard := 0
		while player.pos.distance_to(wp) > 0.6 and guard < 600:
			_step_toward(wp)
			t += 1
			guard += 1
			if t % 60 == 0:
				_sample(t)
		if guard >= 600:
			printerr("FAIL: wedged short of waypoint %s at %s" % [wp, player.pos])
			quit(1)
			return -1
	return t


## BFS on walkable cells, 4-connected; waypoints every 3rd cell.
func _bfs_route(from: Vector2, to: Vector2) -> Array[Vector2]:
	var grid: RefCounted = world.bitgrid
	var start := Vector2i(int(floorf(from.x)), int(floorf(from.y)))
	var goal := Vector2i(int(floorf(to.x)), int(floorf(to.y)))
	var prev := {start: start}
	var queue: Array[Vector2i] = [start]
	var qi := 0
	while qi < queue.size():
		var c := queue[qi]
		qi += 1
		if c == goal:
			break
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if prev.has(n) or grid.is_solid(n.x, n.y):
				continue
			prev[n] = c
			queue.append(n)
	if not prev.has(goal):
		return []
	var cells: Array[Vector2i] = [goal]
	while cells[cells.size() - 1] != start:
		cells.append(prev[cells[cells.size() - 1]])
	cells.reverse()
	# Every cell is a waypoint: adjacent 4-connected centers are 1 t
	# apart, so straight walks between them can never cross a solid
	# (sparser sampling cut a dog-leg corner and wedged the walker).
	var out: Array[Vector2] = []
	for i in cells.size():
		out.append(Vector2(cells[i]) + Vector2(0.5, 0.5))
	return out


func _step_toward(target: Vector2) -> void:
	var d: Vector2 = target - player.pos
	var f: RefCounted = InputFrame.new()
	f.move_x = 0 if absf(d.x) < 0.2 else (1 if d.x > 0.0 else -1)
	f.move_y = 0 if absf(d.y) < 0.2 else (1 if d.y > 0.0 else -1)
	f.normalized = true
	world.step([f])


func _counts() -> Dictionary:
	var engaged := 0
	var near8 := 0
	var live := 0
	for e: RefCounted in world.enemies:
		if e.hp <= 0 or e.def_index < 0:
			continue
		live += 1
		if int(e.ai_state) != EnemyState.AIState.IDLE:
			engaged += 1
		if e.pos.distance_to(player.pos) <= 8.0:
			near8 += 1
	return {"engaged": engaged, "near8": near8, "live": live}


func _counts_line() -> String:
	var c := _counts()
	return "engaged=%d near8=%d live=%d" % [c.engaged, c.near8, c.live]


func _sample(t: int) -> void:
	print("t=%4d pos=%.1f,%.1f  %s" % [t, player.pos.x, player.pos.y, _counts_line()])
