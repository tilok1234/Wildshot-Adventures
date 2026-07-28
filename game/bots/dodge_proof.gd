extends RefCounted
## DodgeBot proof core (docs/12 §2.11), shared by the --script runner and
## the main-scene --bot route so both CLIs behave identically. Movement-
## only by construction: the policy emits frames with no fire, no
## ability, no autofire edge — the "ability-off" in every proof name is
## structural, not configured.

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const ReplayRecorder := preload("res://input/replay_recorder.gd")
const SimEvents := preload("res://sim/events.gd")
const DodgePolicy := preload("res://game/bots/dodge_policy.gd")
const ActorState := preload("res://sim/actor_state.gd")

const HEAT_W := 12
const HEAT_H := 8


static func run_from_args(args: Dictionary) -> int:
	var scenario_arg := String(args.get("scenario", ""))
	if scenario_arg.is_empty():
		printerr("dodge_proof: --scenario required")
		return 2
	var scenario_path := _resolve_scenario(scenario_arg)
	if scenario_path.is_empty():
		printerr("dodge_proof: scenario not found: " + scenario_arg)
		return 2
	var scenario: Resource = load(scenario_path)
	var speed_arg := String(args.get("speed", "3.0"))
	var speed := 3.0 if speed_arg == "lowest" else float(speed_arg)
	var ticks := int(String(args.get("ticks", "3600")))
	var seeds: Array[int] = []
	if args.has("seeds"):
		for s in String(args.seeds).split(",", false):
			seeds.append(int(s))
	else:
		var base := int(String(args.get("seed", str(scenario.default_seed))))
		var runs := int(String(args.get("runs", "5")))
		for i in runs:
			seeds.append(base + i)
	var out_path := String(args.get("out", "res://reports/dodge_%s.json" % String(scenario.id)))

	var grid: RefCounted
	if not String(scenario.worldforge_pack).is_empty():
		var wf := WorldforgePack.validate(String(scenario.worldforge_pack))
		if not bool(wf.ok):
			for line: String in wf.log:
				printerr("dodge_proof: " + line)
			return 2
		grid = wf.bitgrid
	else:
		grid = _build_bitgrid(String(scenario.arena))
	var run_reports: Array = []
	var all_pass := true
	for seed_v in seeds:
		var r := _run_one(scenario, seed_v, speed, ticks, grid)
		run_reports.append(r)
		all_pass = all_pass and int(r.hits) == 0
		print(
			(
				"dodge_proof: scenario=%s seed=%d speed=%.1f ticks=%d -> hits=%d%s near_miss=%.3f"
				% [
					String(scenario.id),
					seed_v,
					speed,
					ticks,
					int(r.hits),
					(
						""
						if int(r.hits) == 0
						else " FIRST@%d repro=%s" % [int(r.first_hit_tick), String(r.repro)]
					),
					float(r.near_miss_min),
				]
			)
		)

	var report := {
		"label": "mechanical verification (no gate code reads this — CORE-53)",
		"kind": "dodge_proof",
		"scenario": String(scenario.id),
		"scenario_path": scenario_path,
		"speed": speed,
		"policy": "primary-16dir-stay-closed-form",
		"horizon_ticks": DodgePolicy.HORIZON,
		"ability_used": false,
		"fire_used": false,
		"ticks_per_run": ticks,
		"seeds": seeds,
		"runs": run_reports,
		"pass": all_pass,
	}
	# Elite evidence roll-up (§3.5): worst peak across runs, vs the
	# budgets.tres ceiling the density meter enforces in play.
	var peak_max := -1
	for r: Dictionary in run_reports:
		if r.has("peak_hostile_live"):
			peak_max = maxi(peak_max, int(r.peak_hostile_live))
	if peak_max >= 0:
		var budgets: Resource = load("res://data/budgets.tres")
		report["peak_hostile_live_max"] = peak_max
		report["hostile_elite_budget"] = int(budgets.hostile_elite_max)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_path.get_base_dir()))
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t"))
	f.close()
	print(
		(
			"dodge_proof: %s -> %s (%s)"
			% [String(scenario.id), out_path, "PASS" if all_pass else "FAIL"]
		)
	)
	return 0 if all_pass else 1


static func _run_one(
	scenario: Resource, seed_v: int, speed: float, ticks: int, grid: RefCounted
) -> Dictionary:
	var world: RefCounted = ScenarioLoader.build_world(scenario, seed_v, grid)
	var player: RefCounted = world.players[0]
	player.move_speed = speed
	# Elite runs (§3.5) additionally evidence peak hostile density (the
	# <= 300 budget line becomes a report field) and every PHASE_CHANGED
	# crossing. Tracked only when a phased enemy actually SPAWNED — the
	# def sits in every roster, so a roster scan would grow every
	# ordinary report and break their byte-identical reproduction.
	var has_elite := false
	for e: RefCounted in world.enemies:
		var edi: int = e.def_index
		if edi >= 0 and world.enemy_defs[edi].phases != null:
			has_elite = true
			break
	var peak_hostile := 0
	var phase_log: Array = []
	var recorder := ReplayRecorder.new()
	recorder.begin(world)
	var hits := 0
	var first_hit := -1
	var near_miss := 1.0e18
	var heat := PackedInt32Array()
	heat.resize(HEAT_W * HEAT_H)
	for t in ticks:
		var frame: RefCounted = DodgePolicy.compute_frame(world, 0)
		recorder.record_frames([frame])
		world.step([frame])
		recorder.after_step()
		for ev: Dictionary in world.events:
			if int(ev.type) == SimEvents.Type.DAMAGE_APPLIED and int(ev.target) == player.id:
				hits += 1
				if first_hit < 0:
					first_hit = int(ev.tick)
			elif has_elite and int(ev.type) == SimEvents.Type.PHASE_CHANGED:
				phase_log.append({"tick": int(ev.tick), "phase": int(ev.phase), "hp": int(ev.hp)})
		if has_elite:
			peak_hostile = maxi(peak_hostile, _live_hostile_count(world))
		near_miss = minf(near_miss, _nearest_threat_clearance(world, player))
		var hx := clampi(int(player.pos.x * HEAT_W / float(grid.width)), 0, HEAT_W - 1)
		var hy := clampi(int(player.pos.y * HEAT_H / float(grid.height)), 0, HEAT_H - 1)
		heat[hy * HEAT_W + hx] += 1
		if player.dead:
			break
	var repro := ""
	if hits > 0:
		repro = "res://reports/repro_%s_seed%d.wsr" % [String(scenario.id), seed_v]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
		recorder.save_wsr(repro, "bot", String(scenario.id))
	var heat_rows: Array = []
	for y in HEAT_H:
		var row: Array = []
		for x in HEAT_W:
			row.append(heat[y * HEAT_W + x])
		heat_rows.append(row)
	var result := {
		"seed": seed_v,
		"hits": hits,
		"first_hit_tick": first_hit,
		"survived_ticks": world.tick,
		"near_miss_min": near_miss if near_miss < 1.0e17 else -1.0,
		"heatmap": heat_rows,
		"repro": repro,
	}
	if has_elite:
		result["peak_hostile_live"] = peak_hostile
		result["phase_transitions"] = phase_log
	return result


## Live hostile projectile count this tick (the density meter's H
## figure, computed sim-side for the elite report's peak evidence).
static func _live_hostile_count(world: RefCounted) -> int:
	var pool: RefCounted = world.projectiles
	var act: PackedByteArray = pool.active
	var fac: PackedByteArray = pool.faction
	var n := 0
	for s in pool.CAPACITY:
		if act[s] == 1 and fac[s] == ActorState.FACTION_HOSTILE:
			n += 1
	return n


## Min live clearance (tiles) between the player edge and any hostile
## threat edge this tick — projectiles AND contact-damage bodies — the
## report's near-miss figure.
static func _nearest_threat_clearance(world: RefCounted, player: RefCounted) -> float:
	var pool: RefCounted = world.projectiles
	var act: PackedByteArray = pool.active
	var fac: PackedByteArray = pool.faction
	var px: PackedFloat32Array = pool.pos_x
	var py: PackedFloat32Array = pool.pos_y
	var rad: PackedFloat32Array = pool.radius
	var ppos: Vector2 = player.pos
	var pr: float = player.radius
	var best := 1.0e18
	for s in pool.CAPACITY:
		if act[s] == 0 or fac[s] != 1:
			continue
		var d: float = ppos.distance_to(Vector2(px[s], py[s])) - rad[s] - pr
		best = minf(best, d)
	var defs: Array = world.enemy_defs
	for e: RefCounted in world.enemies:
		var def_index: int = e.def_index
		if def_index < 0 or e.hp <= 0:
			continue
		if int(defs[def_index].contact_damage) <= 0:
			continue
		var epos: Vector2 = e.pos
		var d2: float = ppos.distance_to(epos) - e.radius - pr
		best = minf(best, d2)
	return best


## Scenario name shorthand: bare ids look in tests/bot_scenarios first
## (canaries + proof isolates), then data/scenarios.
static func _resolve_scenario(arg: String) -> String:
	if arg.contains("/"):
		return arg if FileAccess.file_exists(arg) else ""
	for root: String in ["res://tests/bot_scenarios/", "res://data/scenarios/"]:
		var p := root + arg + ".tres"
		if FileAccess.file_exists(p):
			return p
	return ""


static func _build_bitgrid(arena_path: String) -> RefCounted:
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://tileforge/tileforge-manifest.json")
	)
	var def := ArenaBuilder.load_def(arena_path)
	var grid := Bitgrid.new()
	grid.setup(int(def.width), int(def.height))
	for c: Vector2i in ArenaBuilder.solid_cells(def, manifest):
		grid.set_solid(c.x, c.y)
	return grid
