## One-shot WINDOWED evidence probe (sl-0213/0234 close-fighter wave
## 1): four committed frames, read by eyes before the seam ships
## (gotcha 13 — headless gates cannot see render bugs):
##   reports/close_fighter_wolf_pack.png       — the circling pack at
##     its worst projectile tick (bites/darts in flight, real sheets);
##   reports/close_fighter_goblin_skirmish.png — the skirmish trio at
##     its worst pelt tick;
##   reports/close_fighter_old_tusk_overlap.png — THE sl-0234 ANSWER
##     FRAME: the bait hugged inside the boss body with his own
##     blades mid-flight INSIDE the ring (the designer's evidence
##     frame, inverted);
##   reports/close_fighter_density_worstcase.png — the AUTHORED
##     worst-case convergence (audit_close_density: tusk + wolf pack
##     + goblin gang on one standing target) at its measured worst
##     hostile-live tick (the ecosystem read is the designer's);
##   reports/close_fighter_density_camp.png — the re-tabled green
##     camp on the real b77 ground, bot-driven (the in-world read).
## Deterministic capture ticks: a viewless twin run measures, the
## render run replays to the same tick (same seed, same policy — the
## worlds are byte-twins by construction).
## Run WITHOUT --headless:
##   godot_console --path . --script tests/close_fighters/close_fighter_evidence_probe.gd
extends SceneTree

const ScenarioLoader := preload("res://game/scenario_loader.gd")
const DodgeProof := preload("res://game/bots/dodge_proof.gd")
const DodgePolicy := preload("res://game/bots/dodge_policy.gd")
const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const WorldBuilder := preload("res://game/arena/world_builder.gd")
const RenderLayers := preload("res://game/render_layers.gd")
const AssemblerLibrary := preload("res://game/views/assembler_library.gd")
const EnemyActorsView := preload("res://game/views/enemy_actors_view.gd")
const ProjectileView := preload("res://game/views/projectile_view.gd")
const HazardView := preload("res://game/views/hazard_view.gd")
const HitboxView := preload("res://game/views/hitbox_view.gd")
const ViewClock := preload("res://game/views/view_clock.gd")
const SimWorld := preload("res://sim/sim_world.gd")
const SimEvents := preload("res://sim/events.gd")

const TILE := 32.0
const PACK := "res://assets/worldforge-packs/wildshot-overworld-pack-dusk/"


func _init() -> void:
	_run()


func _run() -> void:
	var ok := true
	ok = await _capture_isolate("proof_wolf_pack", "close_fighter_wolf_pack") and ok
	ok = await _capture_isolate("proof_goblin_skirmish", "close_fighter_goblin_skirmish") and ok
	ok = await _capture_tusk_overlap() and ok
	ok = await _capture_audit_density() and ok
	ok = await _capture_camp_density() and ok
	if ok:
		print("close_fighter_evidence_probe: PASS (5 frames committed to reports/)")
		quit(0)
	else:
		printerr("close_fighter_evidence_probe: FAIL")
		quit(1)


func _grid_for(scenario: Resource) -> RefCounted:
	if not String(scenario.worldforge_pack).is_empty():
		return WorldforgePack.validate(String(scenario.worldforge_pack)).bitgrid
	return DodgeProof._build_bitgrid(String(scenario.arena))


## Worst live-hostile-projectile tick of a bot-driven run (viewless twin).
func _worst_tick(scenario: Resource, grid: RefCounted, ticks: int) -> int:
	var world: RefCounted = ScenarioLoader.build_world(scenario, 1, grid)
	world.players[0].move_speed = 3.6
	var best_tick := 0
	var best_n := -1
	for t in ticks:
		var frame: RefCounted = DodgePolicy.compute_frame(world, 0, DodgePolicy.Policy.REACTIVE)
		world.step([frame])
		var n := DodgeProof._live_hostile_count(world)
		if n > best_n:
			best_n = n
			best_tick = t
	print("  worst tick %d: %d live hostile shots" % [best_tick, best_n])
	return best_tick


## Mount the real combat view stack over a sim world.
func _mount_views(root: Node2D, world: RefCounted) -> void:
	var clock := ViewClock.new()
	var lib := AssemblerLibrary.new()
	if not lib.load_manifest():
		printerr("evidence: assembler manifest missing")
		return
	var enemy_actors := EnemyActorsView.new()
	enemy_actors.world = world
	enemy_actors.clock = clock
	enemy_actors.lib = lib
	enemy_actors.sheet_map = load("res://data/actor_sheet_map.tres")
	enemy_actors.y_sort_enabled = true
	if FileAccess.file_exists("res://assembler_boss/manifest.json"):
		var lib_boss := AssemblerLibrary.new()
		lib_boss.manifest_path = "res://assembler_boss/manifest.json"
		lib_boss.sheet_root = "res://assembler_boss/"
		if lib_boss.load_manifest():
			enemy_actors.lib_boss = lib_boss
	enemy_actors.z_index = RenderLayers.ACTORS
	root.add_child(enemy_actors)
	var pview := ProjectileView.new()
	pview.world = world
	pview.z_index = RenderLayers.HOSTILE_PROJECTILES
	root.add_child(pview)
	var hview := HazardView.new()
	hview.world = world
	hview.z_index = RenderLayers.HOSTILE_HAZARD_FILL
	root.add_child(hview)
	var hit := HitboxView.new()
	hit.world = world
	root.add_child(hit)


func _snap(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/" + path + ".png"))
	print("  wrote reports/" + path + ".png")


func _capture_isolate(scenario_id: String, out_name: String) -> bool:
	print("evidence: " + scenario_id)
	var scenario: Resource = load("res://tests/bot_scenarios/%s.tres" % scenario_id)
	var grid := _grid_for(scenario)
	var target := _worst_tick(scenario, grid, 1800)
	var world: RefCounted = ScenarioLoader.build_world(scenario, 1, grid)
	world.players[0].move_speed = 3.6
	var root := Node2D.new()
	get_root().add_child(root)
	_mount_views(root, world)
	var cam := Camera2D.new()
	cam.zoom = Vector2(1.6, 1.6)
	root.add_child(cam)
	await process_frame
	cam.make_current()
	for t in target + 1:
		var frame: RefCounted = DodgePolicy.compute_frame(world, 0, DodgePolicy.Policy.REACTIVE)
		world.step([frame])
	cam.position = Vector2(world.players[0].pos) * TILE
	await _snap(out_name)
	root.queue_free()
	await process_frame
	return true


## THE sl-0234 ANSWER FRAME: the bait hugged against Old Tusk (0.7
## tiles — the trample band reaches to 0.725), his own blades caught
## mid-flight between his center and the ring. Any closer and the
## blades connect the tick they spawn (combined radius 0.415 vs
## spawn ~0.46 — the fix working, nothing to photograph); the test
## pins that instant-connect case, this frame shows the geometry.
func _capture_tusk_overlap() -> bool:
	print("evidence: old_tusk overlap")
	var grid := DodgeProof._build_bitgrid("res://data/arena_lab.json")
	var world := SimWorld.new()
	world.setup(31, grid)
	world.set_enemy_defs([load("res://data/enemies/old_tusk.tres")])
	world.add_player(Vector2(24.7, 16.0))
	world.god_mode = true
	world.add_enemy(0, Vector2(24.0, 16.0))
	var root := Node2D.new()
	get_root().add_child(root)
	_mount_views(root, world)
	var cam := Camera2D.new()
	cam.position = Vector2(24.25, 16.0) * TILE
	cam.zoom = Vector2(2.2, 2.2)
	root.add_child(cam)
	await process_frame
	cam.make_current()
	var fired := -1
	for t in 300:
		world.step([null])
		for ev: Dictionary in world.events:
			if int(ev.type) == SimEvents.Type.ATTACK_STARTED and fired < 0:
				fired = t
		if fired >= 0:
			break  # capture on the fire step — the hug kills blades by age 2
	await _snap("close_fighter_old_tusk_overlap")
	root.queue_free()
	await process_frame
	return fired >= 0


## THE WORST-CASE DENSITY FRAME (the audit_density convention): the
## authored convergence scene at its measured worst hostile-live tick
## against a STANDING god bait — the sl-0208/0234 disease case is
## exactly the standing target, so the worst case stands still.
func _capture_audit_density() -> bool:
	print("evidence: authored worst-case density")
	var scenario: Resource = load("res://tests/bot_scenarios/audit_close_density.tres")
	var grid := _grid_for(scenario)
	var measure: RefCounted = ScenarioLoader.build_world(scenario, 1, grid)
	measure.god_mode = true
	var best_tick := 0
	var best_n := -1
	for t in 1200:
		measure.step([null])
		var n := DodgeProof._live_hostile_count(measure)
		if n > best_n:
			best_n = n
			best_tick = t
	print("  worst tick %d: %d live hostile shots" % [best_tick, best_n])
	var world: RefCounted = ScenarioLoader.build_world(scenario, 1, grid)
	world.god_mode = true
	var root := Node2D.new()
	get_root().add_child(root)
	_mount_views(root, world)
	var cam := Camera2D.new()
	cam.position = Vector2(scenario.player_spawn) * TILE
	cam.zoom = Vector2(1.6, 1.6)
	root.add_child(cam)
	await process_frame
	cam.make_current()
	for t in best_tick + 1:
		world.step([null])
	await _snap("close_fighter_density_worstcase")
	root.queue_free()
	await process_frame
	return true


func _capture_camp_density() -> bool:
	print("evidence: green camp on the real ground (bot-driven)")
	var scenario: Resource = load("res://tests/bot_scenarios/proof_green_camp.tres")
	var wf := WorldforgePack.validate(PACK)
	if not bool(wf.ok):
		printerr("evidence: b77 pack refused")
		return false
	var target := _worst_tick(scenario, wf.bitgrid, 1800)
	var world: RefCounted = ScenarioLoader.build_world(scenario, 1, wf.bitgrid)
	world.players[0].move_speed = 3.6
	var root := Node2D.new()
	get_root().add_child(root)
	var arena := WorldBuilder.build_world_arena(root, PACK)
	if arena.is_empty():
		printerr("evidence: b77 world did not build")
		return false
	_mount_views(root, world)
	var cam := Camera2D.new()
	cam.zoom = Vector2(1.4, 1.4)
	root.add_child(cam)
	await process_frame
	cam.make_current()
	for t in target + 1:
		var frame: RefCounted = DodgePolicy.compute_frame(world, 0, DodgePolicy.Policy.REACTIVE)
		world.step([frame])
	cam.position = Vector2(world.players[0].pos) * TILE
	await _snap("close_fighter_density_camp")
	root.queue_free()
	await process_frame
	return true
