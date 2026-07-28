extends RefCounted
## SoakBot (docs/12 §2.11, M7): hours of seeded rotating scenarios
## under the DodgeBot policy, watching for the failures that only
## duration finds — crashes (surviving the run IS the check), NaN
## positions, projectile-pool exhaustion, and determinism drift
## (every segment runs TWICE with identical seed + inputs; checkpoint
## hashes must match bit-for-bit). Output: reports/soak_report.json,
## labeled mechanical verification (no gate code reads it, CORE-53).
##
## Run: godot --headless --path . --script game/bots/soak_runner.gd -- \
##   [--minutes=30] [--seed0=9000] [--policy=primary] [--out=...]

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const DodgePolicy := preload("res://game/bots/dodge_policy.gd")
const SimEvents := preload("res://sim/events.gd")

const SEGMENT_TICKS := 3600
const HASH_EVERY := 60

## Rotation: every proof + composition + picker scenario.
const SCENARIOS: Array[String] = [
	"proof_rusher",
	"proof_husk_archer",
	"proof_fanmaw",
	"proof_fanmaw_inside",
	"proof_ringer",
	"proof_leadshot",
	"proof_blightcaster",
	"proof_yw_p1",
	"proof_yw_p2",
	"proof_yw_p3",
	"proof_yw_full",
	"first_contact",
	"second_contact",
	"forest_walk",
	"world_walk",
	"meet_blightcaster",
	"meet_leadshot",
	"meet_yard_warden",
	"lab_default",
]


static func run_from_args(args: Dictionary) -> int:
	var minutes := float(String(args.get("minutes", "30")))
	var seed0 := int(String(args.get("seed0", "9000")))
	var policy_name := String(args.get("policy", "primary"))
	var policy_ids := {
		"primary": DodgePolicy.Policy.PRIMARY,
		"reactive": DodgePolicy.Policy.REACTIVE,
	}
	if not policy_ids.has(policy_name):
		printerr("soak: unknown --policy=" + policy_name)
		return 2
	var policy: int = policy_ids[policy_name]
	var out_path := String(args.get("out", "res://reports/soak_report.json"))
	var deadline := Time.get_ticks_msec() + int(minutes * 60000.0)

	var grids := {}
	var segments: Array = []
	var seg_i := 0
	var total_ticks := 0
	var drift := 0
	var nan_count := 0
	var pool_max := 0
	var pool_full_events := 0
	while Time.get_ticks_msec() < deadline:
		var scen_id: String = SCENARIOS[seg_i % SCENARIOS.size()]
		var seed_v := seed0 + seg_i
		var seg := _soak_segment(scen_id, seed_v, policy, grids)
		if seg.is_empty():
			printerr("soak: segment build failed for " + scen_id)
			return 2
		segments.append(seg)
		total_ticks += int(seg.ticks)
		drift += 0 if bool(seg.hashes_match) else 1
		nan_count += int(seg.nans)
		pool_max = maxi(pool_max, int(seg.pool_max))
		pool_full_events += int(seg.pool_full)
		print(
			(
				"soak #%d %s seed=%d -> %s pool_max=%d hits=%d"
				% [
					seg_i,
					scen_id,
					seed_v,
					"ok" if bool(seg.hashes_match) and int(seg.nans) == 0 else "ANOMALY",
					int(seg.pool_max),
					int(seg.hits),
				]
			)
		)
		seg_i += 1

	var clean := drift == 0 and nan_count == 0 and pool_full_events == 0
	var report := {
		"label": "mechanical verification (no gate code reads this — CORE-53)",
		"kind": "soak",
		"policy": policy_name,
		"minutes_requested": minutes,
		"segments": segments.size(),
		"total_ticks": total_ticks,
		"determinism_drift_segments": drift,
		"nan_events": nan_count,
		"pool_max_live": pool_max,
		"pool_full_events": pool_full_events,
		"clean": clean,
		"rotation": SCENARIOS,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_path.get_base_dir()))
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t"))
	f.close()
	print(
		(
			"soak: %d segments, %d ticks, drift=%d nan=%d pool_max=%d full=%d -> %s (%s)"
			% [
				segments.size(),
				total_ticks,
				drift,
				nan_count,
				pool_max,
				pool_full_events,
				out_path,
				"CLEAN" if clean else "ANOMALIES"
			]
		)
	)
	return 0 if clean else 1


## One scenario x seed, run TWICE with identical inputs: checkpoint
## hashes must match (determinism drift watch); NaN and pool watch on
## the first pass.
static func _soak_segment(
	scen_id: String, seed_v: int, policy: int, grids: Dictionary
) -> Dictionary:
	var scenario_path := _resolve(scen_id)
	if scenario_path.is_empty():
		return {}
	var scenario: Resource = load(scenario_path)
	var grid := _grid_for(scenario, grids)
	if grid == null:
		return {}
	var a := _run_once(scenario, seed_v, policy, grid, true)
	var b := _run_once(scenario, seed_v, policy, grid, false)
	return {
		"scenario": scen_id,
		"seed": seed_v,
		"ticks": SEGMENT_TICKS,
		"hashes_match": a.hashes == b.hashes,
		"nans": a.nans,
		"pool_max": a.pool_max,
		"pool_full": a.pool_full,
		"hits": a.hits,
	}


static func _run_once(
	scenario: Resource, seed_v: int, policy: int, grid: RefCounted, watch: bool
) -> Dictionary:
	var world: RefCounted = ScenarioLoader.build_world(scenario, seed_v, grid)
	var player: RefCounted = world.players[0]
	player.move_speed = 3.0
	var hashes: Array[int] = []
	var nans := 0
	var pool_max := 0
	var pool_full := 0
	var hits := 0
	for t in SEGMENT_TICKS:
		var frame: RefCounted = DodgePolicy.compute_frame(world, 0, policy)
		world.step([frame])
		if watch:
			var ppos: Vector2 = player.pos
			if is_nan(ppos.x) or is_nan(ppos.y):
				nans += 1
			for e: RefCounted in world.enemies:
				var epos: Vector2 = e.pos
				if is_nan(epos.x) or is_nan(epos.y):
					nans += 1
			var live: int = world.projectiles.live_count
			pool_max = maxi(pool_max, live)
			if live >= world.projectiles.CAPACITY:
				pool_full += 1
			for ev: Dictionary in world.events:
				if (
					int(ev.type) == SimEvents.Type.DAMAGE_APPLIED
					and int(ev.get("target", -1)) == player.id
				):
					hits += 1
		if (world.tick % HASH_EVERY) == 0:
			hashes.append(world.state_hash())
	return {
		"hashes": hashes, "nans": nans, "pool_max": pool_max, "pool_full": pool_full, "hits": hits
	}


static func _resolve(arg: String) -> String:
	for root: String in ["res://tests/bot_scenarios/", "res://data/scenarios/"]:
		var p := root + arg + ".tres"
		if FileAccess.file_exists(p):
			return p
	return ""


## Bitgrids are pure per-arena data — cache per source so the rotation
## does not rebuild the 256x256 world flood every segment.
static func _grid_for(scenario: Resource, grids: Dictionary) -> RefCounted:
	var key := (
		String(scenario.worldforge_pack)
		if not String(scenario.worldforge_pack).is_empty()
		else String(scenario.arena)
	)
	if grids.has(key):
		return grids[key]
	var grid: RefCounted = null
	if not String(scenario.worldforge_pack).is_empty():
		var wf := WorldforgePack.validate(String(scenario.worldforge_pack))
		if bool(wf.ok):
			grid = wf.bitgrid
	else:
		var manifest: Variant = JSON.parse_string(
			FileAccess.get_file_as_string("res://tileforge/tileforge-manifest.json")
		)
		var adef := ArenaBuilder.load_def(String(scenario.arena))
		grid = Bitgrid.new()
		grid.setup(int(adef.width), int(adef.height))
		for c: Vector2i in ArenaBuilder.solid_cells(adef, manifest):
			grid.set_solid(c.x, c.y)
	if grid != null:
		grids[key] = grid
	return grid
