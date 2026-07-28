extends RefCounted
## TTKBot (docs/12 §2.11, M7 — the CORE-36 sponge check): measures
## empirical time-to-kill for every weapon frame x every roster
## EnemyDef, on the real sim. One enemy per run, the bot aims at its
## live position with fire held (aim is a bot-side choice from world
## state — the SIM stays targeting-free per CORE-35/32) and never
## touches the ability. God keeps the measurement alive (DAMAGE_IMMUNE
## logged; this is mechanical measurement, never dodge or feel
## evidence). Honesty assertions: hits-to-kill must equal
## ceil(hp / damage) EXACTLY for every pair (any drift = damage-path
## bug), and the elite's Longbolt TTK is recorded against §3.5's
## "~13 s of pure Longbolt DPS" line. Output: reports/ttk_matrix.json,
## labeled mechanical verification (no gate code reads it).

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const SimWorld := preload("res://sim/sim_world.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const SimEvents := preload("res://sim/events.gd")
const ProjectilePool := preload("res://sim/projectile_pool.gd")

const MAX_TICKS := 7200
const PLAYER_SPAWN := Vector2(22.0, 16.0)
const ENEMY_SPAWN := Vector2(28.0, 16.0)


static func run_from_args(args: Dictionary) -> int:
	var seed_v := int(String(args.get("seed", "7")))
	var out_path := String(args.get("out", "res://reports/ttk_matrix.json"))
	var grid := _build_bitgrid()
	var weapons: Array = [
		load("res://data/weapons/longbolt.tres"),
		load("res://data/weapons/scattercast.tres"),
		load("res://data/weapons/wheelblade.tres"),
	]
	var enemy_paths: Array[String] = [
		"res://data/enemies/rusher.tres",
		"res://data/enemies/husk_archer.tres",
		"res://data/enemies/fanmaw.tres",
		"res://data/enemies/ringer.tres",
		"res://data/enemies/leadshot.tres",
		"res://data/enemies/blightcaster.tres",
		"res://data/enemies/yard_warden.tres",
	]
	var rows: Array = []
	var all_ok := true
	for wi in weapons.size():
		var wf: Resource = weapons[wi]
		for path in enemy_paths:
			var edef: Resource = load(path)
			var row := _measure(grid, weapons, wi, edef, seed_v)
			rows.append(row)
			all_ok = all_ok and bool(row.hits_ok)
			print(
				(
					"ttk: %s vs %s -> %s hits=%d/%d ttk=%.2fs uptime=%.0f%%"
					% [
						String(wf.display_name),
						String(edef.id),
						"ok" if bool(row.hits_ok) else "HITS OUT OF BOUND",
						int(row.hits_to_kill),
						int(row.analytic_hits),
						float(row.ttk_seconds),
						float(row.uptime_pct),
					]
				)
			)

	var elite_longbolt := -1.0
	for row: Dictionary in rows:
		if String(row.enemy) == "yard_warden" and int(row.weapon_index) == 0:
			elite_longbolt = float(row.ttk_seconds)
	var report := {
		"label": "mechanical verification (no gate code reads this — CORE-53)",
		"kind": "ttk_matrix",
		"seed": seed_v,
		"rows": rows,
		"all_hits_exact": all_ok,
		"elite_longbolt_ttk_seconds": elite_longbolt,
		"elite_design_line_seconds": 13.0,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_path.get_base_dir()))
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t"))
	f.close()
	print(
		(
			"ttk_matrix -> %s (%s; elite longbolt %.2fs vs ~13s design line)"
			% [out_path, "ALL EXACT" if all_ok else "MISMATCHES", elite_longbolt]
		)
	)
	return 0 if all_ok else 1


## One weapon-vs-enemy measurement: aim at the live enemy, hold fire,
## count HIT_LANDED on it, stop at its ENTITY_KILLED.
static func _measure(
	grid: RefCounted, weapons: Array, weapon_index: int, edef: Resource, seed_v: int
) -> Dictionary:
	var world := SimWorld.new()
	world.setup(seed_v, grid)
	world.set_weapons(weapons)
	world.set_abilities([])
	world.set_enemy_defs([edef])
	var player: RefCounted = world.add_player(PLAYER_SPAWN)
	var enemy: RefCounted = world.add_enemy(0, ENEMY_SPAWN)
	var enemy_id: int = enemy.id
	world.god_mode = true
	# Close to the frame's own reach like a player would (short-range
	# frames never land on retreating enemies from spawn distance):
	# pursue while farther than 70% of max shot STRIKE range, stop by
	# 1.2 t. Boomerang shots strike only as far as their OUT phase
	# (prog_a ticks at prog_b speed) — ttl covers the return trip.
	var reach := 0.0
	var wf0: Resource = weapons[weapon_index]
	for shot: Resource in wf0.shots:
		var flight: float
		if int(shot.program) == ProjectilePool.Program.BOOMERANG:
			flight = float(shot.prog_b) * float(shot.prog_a) / 60.0
		else:
			flight = float(shot.speed) * float(int(shot.ttl_ticks)) / 60.0
		reach = maxf(reach, flight)
	var close_to := maxf(1.2, reach * 0.7)
	var first_fire := -1
	var kill_tick := -1
	var hits := 0
	var shots := 0
	for t in MAX_TICKS:
		var frame := InputFrame.new()
		if t == 0:
			frame.weapon_select = weapon_index + 1
		var epos: Vector2 = enemy.pos
		var aim: Vector2 = epos - player.pos
		var dist := aim.length()
		if dist > close_to:
			var dir := aim / dist
			frame.move_x = clampi(roundi(dir.x), -1, 1)
			frame.move_y = clampi(roundi(dir.y), -1, 1)
			frame.normalized = true
		var q := InputFrame.quantize_aim(aim)
		frame.aim_x = q.x
		frame.aim_y = q.y
		frame.fire_held = true
		world.step([frame])
		for ev: Dictionary in world.events:
			match int(ev.type):
				SimEvents.Type.PROJECTILE_SPAWNED:
					if int(ev.get("pattern", 0)) == weapon_index + 1:
						shots += 1
						if first_fire < 0:
							first_fire = int(ev.tick)
				SimEvents.Type.HIT_LANDED:
					if int(ev.get("target", -1)) == enemy_id:
						hits += 1
				SimEvents.Type.ENTITY_KILLED:
					if int(ev.get("id", -1)) == enemy_id:
						kill_tick = int(ev.tick)
		if kill_tick >= 0:
			break
	var wf: Resource = weapons[weapon_index]
	var shot0: Resource = wf.shots[0]
	# Honesty bound, not equality: the death tick can land several
	# volley pellets (and a pierce pass) at once, so hits may overshoot
	# the analytic count by up to one volley x passes; anything OUTSIDE
	# [analytic, analytic + volley] is a damage-path bug.
	var analytic_hits := ceili(float(edef.hp) / float(int(shot0.damage)))
	var overshoot: int = wf.shots.size() * maxi(1, int(shot0.max_passes))
	var ttk_ticks := (kill_tick - first_fire) if kill_tick >= 0 and first_fire >= 0 else -1
	var analytic_ticks := analytic_hits * int(wf.cadence_ticks)
	return {
		"weapon_index": weapon_index,
		"weapon": String(wf.display_name),
		"enemy": String(edef.id),
		"enemy_hp": int(edef.hp),
		"killed": kill_tick >= 0,
		"ttk_ticks": ttk_ticks,
		"ttk_seconds": float(ttk_ticks) / 60.0 if ttk_ticks >= 0 else -1.0,
		"shots_fired": shots,
		"hits_to_kill": hits,
		"analytic_hits": analytic_hits,
		"hits_ok": kill_tick >= 0 and hits >= analytic_hits and hits <= analytic_hits + overshoot,
		"analytic_floor_seconds": float(analytic_ticks) / 60.0,
		"uptime_pct": (100.0 * float(analytic_ticks) / float(ttk_ticks)) if ttk_ticks > 0 else 0.0,
	}


static func _build_bitgrid() -> RefCounted:
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://tileforge/tileforge-manifest.json")
	)
	var def := ArenaBuilder.load_def("res://data/arena_lab.json")
	var grid := Bitgrid.new()
	grid.setup(int(def.width), int(def.height))
	for c: Vector2i in ArenaBuilder.solid_cells(def, manifest):
		grid.set_solid(c.x, c.y)
	return grid
