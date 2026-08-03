## sl-0186 — THE WALK CHECK (fixed gate step; CI row). THE LESSON:
## script proofs prove the SIM'S FIGHTS, never the designer's WALK —
## the wave-2 dungeon shipped with every bot proof green while the
## arena rendered as pure void over real collision (a wrong-dialect
## prop key aborted resolve_placements, erasing floors AND walls) and
## the one-room rift camera framed 4% of the serpentine. A
## human-shaped load check now sits IN THE GATE for walked content:
##
## 1. ARENA RENDER RESOLUTION — for EVERY arena-routed scenario, the
##    placement set resolves and blocking art exists exactly where
##    collision blocks: every wall cell carries a wall placement,
##    every authored prop places art at its cell, every SOLID cell is
##    covered by a wall/structures placement. An invisible wall is a
##    RED gate, not a play-session surprise.
## 2. THE DUNGEON TRAVERSE — the full serpentine walked spawn->boss
##    room on real Kinematics (waypoints + progress watchdog): the
##    path the designer walks provably exists at the collision level.
## 3. ROUTING PINS — the dungeon is a PATH rift (follow camera,
##    full-screen galaxy: rift_path true); every fit rift keeps the
##    one-room presentation (rift_path false); the flee door cell
##    (2.5,3.5 — replica of main's DUNGEON_DOORS entry, the recorded
##    --script limit) is walkable beside the spawn.
##
## Run: godot --headless --path . --script tests/rift_dungeon/dungeon_walk_test.gd
extends SceneTree

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const DodgeProof := preload("res://game/bots/dodge_proof.gd")
const InputFrame := preload("res://sim/input_frame.gd")

const DUNGEON_SCENARIO := "res://data/scenarios/rift_dungeon_path.tres"
## Replica of main.gd DUNGEON_DOORS[rift_dungeon_path][0].cell (main
## cannot compile under --script — the recorded limit; lint + boot pin
## main's side).
const DUNGEON_FLEE_CELL := Vector2(2.5, 3.5)
const WAYPOINTS: Array[Vector2] = [
	Vector2(60.5, 2.5),
	Vector2(60.5, 11.5),
	Vector2(3.5, 11.5),
	Vector2(3.5, 20.5),
	Vector2(60.5, 20.5),
	Vector2(60.5, 27.5),
	Vector2(3.5, 27.5),
	Vector2(3.5, 36.5),
	Vector2(52.5, 36.5),
	Vector2(56.5, 40.5),
]
const WATCHDOG_TICKS := 300
const TICK_BUDGET := 6000

var fails: Array[String] = []


func check(ok: bool, msg: String) -> void:
	if not ok:
		fails.append(msg)


func _init() -> void:
	_run()


func _scenarios() -> Array[Resource]:
	var out: Array[Resource] = []
	var dir := DirAccess.open("res://data/scenarios")
	for f in dir.get_files():
		if f.ends_with(".tres"):
			out.append(load("res://data/scenarios/" + f))
	return out


func _run() -> void:
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://tileforge/tileforge-manifest.json")
	)
	check(manifest != null, "tileforge manifest loads")

	# 1. ARENA RENDER RESOLUTION — every arena-routed scenario.
	var arena_paths := {}
	for s: Resource in _scenarios():
		if not String(s.worldforge_pack).is_empty():
			continue
		arena_paths[String(s.arena)] = true
	check(arena_paths.has("res://data/arena_rift_path.json"), "the dungeon arena is enumerated")
	for ap: String in arena_paths:
		var def := ArenaBuilder.load_def(ap)
		check(not def.is_empty(), "%s parses" % ap)
		if def.is_empty():
			continue
		var placements := ArenaBuilder.resolve_placements(def, manifest)
		check(placements.size() > 0, "%s resolves placements" % ap)
		var art := {}
		for p: Dictionary in placements:
			if String(p.layer) == "wall" or String(p.layer) == "structures":
				art[p.cell] = true
		for c: Vector2i in ArenaBuilder.wall_cells(def):
			if not art.has(c):
				check(false, "%s: wall cell %s has NO wall art" % [ap, c])
				break
		for pr: Dictionary in def.get("props", []):
			var pc := Vector2i(int(pr.x), int(pr.y))
			check(
				art.has(pc),
				"%s: prop '%s' at %s places NO art" % [ap, String(pr.get("name", "?")), pc]
			)
		var uncovered := 0
		for c: Vector2i in ArenaBuilder.solid_cells(def, manifest):
			if not art.has(c):
				uncovered += 1
		check(
			uncovered == 0,
			"%s: %d SOLID cells carry no blocking art (invisible walls)" % [ap, uncovered]
		)

	# 2. THE DUNGEON TRAVERSE (geometry-pure: spawns cleared — the
	# fights are the proofs' job; the WALK is this test's).
	var scenario: Resource = load(DUNGEON_SCENARIO)
	var grid: RefCounted = DodgeProof._build_bitgrid(String(scenario.arena))
	for id: String in scenario.enemy_spawns:
		var pts: PackedVector2Array = scenario.enemy_spawns[id]
		for i in pts.size():
			var cell: Vector2 = pts[i]
			check(
				not grid.is_solid(int(cell.x), int(cell.y)),
				"dungeon spawn %s #%d at %s is walkable" % [id, i, cell]
			)
	var s2: Resource = scenario.duplicate()
	s2.enemy_spawns = {}
	var world: RefCounted = ScenarioLoader.build_world(s2, 1, grid)
	var p: RefCounted = world.players[0]
	var wp := 0
	var ticks := 0
	var best: float = p.pos.distance_to(WAYPOINTS[0])
	var since_best := 0
	while wp < WAYPOINTS.size() and ticks < TICK_BUDGET:
		var d0: Vector2 = WAYPOINTS[wp] - p.pos
		var f: RefCounted = InputFrame.new()
		f.move_x = 0 if absf(d0.x) < 0.2 else (1 if d0.x > 0.0 else -1)
		f.move_y = 0 if absf(d0.y) < 0.2 else (1 if d0.y > 0.0 else -1)
		f.normalized = true
		world.step([f])
		ticks += 1
		var d: float = p.pos.distance_to(WAYPOINTS[wp])
		if d < best - 0.05:
			best = d
			since_best = 0
		else:
			since_best += 1
		if since_best > WATCHDOG_TICKS:
			check(
				false,
				(
					"traverse WEDGED short of waypoint %d (%s) at %.1f,%.1f tick %d"
					% [wp, WAYPOINTS[wp], p.pos.x, p.pos.y, ticks]
				)
			)
			break
		if d < 1.0:
			wp += 1
			if wp < WAYPOINTS.size():
				best = p.pos.distance_to(WAYPOINTS[wp])
				since_best = 0
	check(
		wp == WAYPOINTS.size(),
		"THE FULL SERPENTINE WALKS: %d/%d waypoints in %d ticks" % [wp, WAYPOINTS.size(), ticks]
	)

	# 3. ROUTING PINS.
	check(bool(scenario.rift_path), "the dungeon is a PATH rift (follow camera routing)")
	for s: Resource in _scenarios():
		if bool(s.starhook_rift) and String(s.id) != "rift_dungeon_path":
			check(
				not bool(s.rift_path), "%s stays a FIT rift (one-room presentation)" % String(s.id)
			)
	check(
		not grid.is_solid(int(DUNGEON_FLEE_CELL.x), int(DUNGEON_FLEE_CELL.y)),
		"the flee door cell is walkable"
	)
	check(
		DUNGEON_FLEE_CELL.distance_to(scenario.player_spawn) <= 4.0,
		"the flee door sits beside the spawn (no ping-pong law)"
	)

	if fails.is_empty():
		print("dungeon_walk_test: PASS (render-resolution/traverse/routing)")
		quit(0)
	else:
		for m: String in fails:
			printerr("dungeon_walk_test FAIL: " + m)
		quit(1)
