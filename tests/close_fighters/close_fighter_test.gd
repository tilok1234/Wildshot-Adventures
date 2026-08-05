extends SceneTree
## CLOSE-FIGHTER WAVE 1 contracts (sl-0213 + sl-0234; PASTE E):
## - THE WOLF = the pack circler (variety rule f: its OWN archetype):
##   FLANKER band + press-in bite lunge + intercept cutoff darts;
##   leads exact (46->14, 47->18); a STANDING player DIES — the
##   sl-0208 melee-whiff pin retires INVERTED for this family;
##   lunge-and-out reads in the distance trace; the orbit really
##   orbits (angular drift); zero-distance overlap CONNECTS.
## - THE GOBLIN = flee-and-pelt (the designer's archetype, this
##   family ALONE): presses in for the shiv when its gate opens,
##   retreats to the [3.5, 5.0] band, pelts from it, approaches when
##   the player passes 5.0 (THE SET DISTANCE), and a standing player
##   dies inside an hour-glass nobody argues with (< 3200 t).
## - OLD TUSK (sl-0234): the zero-distance overlap is DEAD — a
##   player standing inside him takes the trample on its exact 30 t
##   cadence AND his own blades (spawn offsets moved inside the
##   hurtbox), and dies; the march-in case still kills.
## - THE RANGE-BAND VOCABULARY (sl-0213): "melee" = engagement
##   distance, in data — declared words must be BANDS keys; the
##   wave-1 three declare theirs; unknown words are caught.
## - THE PRESS classifier: only melee-class pattern slots (trigger
##   <= EnemyDef.MELEE_TRIGGER_MAX) open the gate — a pelt-only kit
##   never presses (NEGATIVE).
## All double-run hash-checked (the press is a pure function of
## serialized state — no mode field exists to desync). Exit 0 = green.

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const SimWorld := preload("res://sim/sim_world.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const SimEvents := preload("res://sim/events.gd")
const EnemyDef := preload("res://data/enemy_def.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const EnemyStep := preload("res://sim/systems/enemy_step.gd")

const HASH_EVERY := 30

var fails: Array[String] = []


func check(cond: bool, name: String) -> void:
	if not cond:
		fails.append(name)


func _build_bitgrid() -> RefCounted:
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://tileforge/tileforge-manifest.json")
	)
	var def := ArenaBuilder.load_def("res://data/arena_lab.json")
	var grid := Bitgrid.new()
	grid.setup(int(def.width), int(def.height))
	for c: Vector2i in ArenaBuilder.solid_cells(def, manifest):
		grid.set_solid(c.x, c.y)
	return grid


## One family run: standing (or scripted-walk) player vs one enemy.
## Collects hashes, telegraph/attack (tick, pattern) pairs, hit ticks
## by pattern, the distance trace, and the enemy's toward-player
## velocity sign per moving tick.
func _run_family(
	def: Resource, enemy_pos: Vector2, ticks: int, walk_from: int = -1, walk_ticks: int = 0
) -> Dictionary:
	var world := SimWorld.new()
	world.setup(31, _build_bitgrid())
	world.set_enemy_defs([def])
	var player := world.add_player(Vector2(24.0, 16.0))
	var enemy := world.add_enemy(0, enemy_pos)
	var hashes: Array[int] = []
	var telegraphs: Array = []
	var attacks: Array = []
	var hits := {}
	var died := false
	var death_tick := -1
	var last_pattern := 0
	var dist_trace := PackedFloat32Array()
	var toward_signs: Array = []
	for t in ticks:
		var frame: RefCounted = null
		if walk_from >= 0 and t >= walk_from and t < walk_from + walk_ticks:
			frame = InputFrame.new()
			frame.move_x = 1
			frame.normalized = true
		world.step([frame])
		for ev: Dictionary in world.events:
			match int(ev.type):
				SimEvents.Type.TELEGRAPH_STARTED:
					if int(ev.id) == enemy.id:
						telegraphs.append([int(ev.tick), int(ev.get("pattern", 0))])
				SimEvents.Type.ATTACK_STARTED:
					if int(ev.get("enemy", 0)) == enemy.id:
						attacks.append([int(ev.tick), int(ev.get("pattern", 0))])
				SimEvents.Type.DAMAGE_APPLIED:
					if int(ev.target) == player.id:
						var pid := int(ev.pattern)
						last_pattern = pid
						if not hits.has(pid):
							hits[pid] = []
						(hits[pid] as Array).append(int(ev.tick))
				SimEvents.Type.ENTITY_KILLED:
					if bool(ev.get("player", false)):
						died = true
						death_tick = int(ev.tick)
		var d: float = enemy.pos.distance_to(player.pos)
		dist_trace.append(d)
		var evel: Vector2 = enemy.vel
		if evel.length_squared() > 0.0001:
			toward_signs.append([t, d, (player.pos - enemy.pos).dot(evel) > 0.0])
		if (world.tick % HASH_EVERY) == 0:
			hashes.append(world.state_hash())
	return {
		"hashes": hashes,
		"telegraphs": telegraphs,
		"attacks": attacks,
		"hits": hits,
		"died": died,
		"death_tick": death_tick,
		"last_pattern": last_pattern,
		"dist_trace": dist_trace,
		"toward_signs": toward_signs,
		"enemy_final": enemy.pos,
	}


## Lead-law exactness over a run: every attack's lead vs the latest
## same-pattern telegraph must equal expected[pattern] exactly.
func _check_leads(r: Dictionary, expected: Dictionary, label: String) -> void:
	var seen := {}
	for a: Array in r.attacks:
		var atick := int(a[0])
		var apat := int(a[1])
		if not expected.has(apat):
			continue
		var best := -1
		for tg: Array in r.telegraphs:
			if int(tg[1]) == apat and int(tg[0]) <= atick and int(tg[0]) > best:
				best = int(tg[0])
		check(best >= 0, label + ": attack pattern %d has a telegraph" % apat)
		if best >= 0:
			check(
				atick - best == int(expected[apat]),
				(
					label
					+ ": pattern %d lead %d == %d exact" % [apat, atick - best, int(expected[apat])]
				)
			)
		seen[apat] = true
	for pid: int in expected:
		check(seen.has(pid), label + ": pattern %d actually fired" % pid)


func _hit_ticks(r: Dictionary, pid: int) -> Array:
	return (r.hits as Dictionary).get(pid, []) as Array


func _init() -> void:
	var wolf: Resource = load("res://data/enemies/wolf.tres")
	var goblin: Resource = load("res://data/enemies/goblin.tres")
	var tusk: Resource = load("res://data/enemies/old_tusk.tres")

	# ---- 1. THE WOLF: pack circler vs a standing player. ----
	var wa := _run_family(wolf, Vector2(16.0, 16.0), 1800)
	var wb := _run_family(wolf, Vector2(16.0, 16.0), 1800)
	check(wa.hashes == wb.hashes, "wolf: double-run hashes identical")
	_check_leads(wa, {46: 14, 47: 18}, "wolf")
	var bite_hits := _hit_ticks(wa, 46)
	var dart_hits := _hit_ticks(wa, 47)
	check(
		bite_hits.size() >= 5,
		"wolf: bites CONNECT on a standing player (%d >= 5)" % bite_hits.size()
	)
	check(dart_hits.size() >= 2, "wolf: cutoff darts land (%d >= 2)" % dart_hits.size())
	# THE RETIREMENT PIN (inverts the sl-0208 melee-whiff for this
	# family): the re-armed wolf KILLS the standing player, explainably.
	check(bool(wa.died), "wolf: a STANDING player dies to the lone wolf (sl-0208 pin retired)")
	check(
		int(wa.death_tick) <= 1700,
		"wolf: the kill lands inside the run (t%d <= 1700)" % int(wa.death_tick)
	)
	check(
		int(wa.last_pattern) in [46, 47],
		"wolf: the death trace names a wolf pattern (%d)" % int(wa.last_pattern)
	)
	# Lunge-and-out: between consecutive bites the wolf LEAVES (>= 2.0)
	# — the FLANKER band pulls it back out after every swing.
	var wolf_bites: Array = []
	for a: Array in wa.attacks:
		if int(a[1]) == 46:
			wolf_bites.append(int(a[0]))
	check(wolf_bites.size() >= 5, "wolf: >= 5 bite volleys (%d)" % wolf_bites.size())
	var out_between := 0
	for i in range(1, wolf_bites.size()):
		var far := 0.0
		var t0 := int(wolf_bites[i - 1])
		var t1 := int(wolf_bites[i])
		for t in range(t0, mini(t1, wa.dist_trace.size())):
			far = maxf(far, wa.dist_trace[t])
		if far >= 2.0:
			out_between += 1
	check(
		out_between >= wolf_bites.size() - 2,
		"wolf: lunge-and-out between bites (%d/%d gaps)" % [out_between, wolf_bites.size() - 1]
	)
	# The circle really circles: net angular drift around the player
	# while in the orbit band.
	var world_probe := SimWorld.new()
	world_probe.setup(31, _build_bitgrid())
	world_probe.set_enemy_defs([wolf])
	var probe_player := world_probe.add_player(Vector2(24.0, 16.0))
	var probe_wolf := world_probe.add_enemy(0, Vector2(16.0, 16.0))
	var drift := 0.0
	var prev_ang := 0.0
	var have_prev := false
	for t in 1800:
		world_probe.step([null])
		var d: float = probe_wolf.pos.distance_to(probe_player.pos)
		if probe_player.dead:
			break
		if d >= 2.0 and d <= 3.4:
			var ang := (probe_wolf.pos - probe_player.pos).angle()
			if have_prev:
				drift += absf(wrapf(ang - prev_ang, -PI, PI))
			prev_ang = ang
			have_prev = true
		else:
			have_prev = false
	check(drift >= 3.0, "wolf: the orbit orbits (band drift %.2f rad >= 3.0)" % drift)

	print(
		(
			"wolf circler ok: bites=%d darts=%d death@%d drift=%.1f"
			% [bite_hits.size(), dart_hits.size(), int(wa.death_tick), drift]
		)
	)

	# ---- 2. THE WOLF at zero distance: overlap CONNECTS. ----
	var wo := _run_family(wolf, Vector2(24.0, 16.0), 240)
	var wo_bites := _hit_ticks(wo, 46)
	check(not wo.attacks.is_empty(), "wolf overlap: the bite fires at distance zero")
	check(not wo_bites.is_empty(), "wolf overlap: the bite CONNECTS at distance zero")
	if not wo.attacks.is_empty() and not wo_bites.is_empty():
		check(
			int(wo_bites[0]) <= int(wo.attacks[0][0]) + 3,
			(
				"wolf overlap: the blade lands on arrival (t%d vs volley t%d)"
				% [int(wo_bites[0]), int(wo.attacks[0][0])]
			)
		)

	print("wolf overlap ok")

	# ---- 3. THE GOBLIN: flee-and-pelt vs a standing player. ----
	var ga := _run_family(goblin, Vector2(16.0, 16.0), 3600)
	var gb := _run_family(goblin, Vector2(16.0, 16.0), 3600)
	check(ga.hashes == gb.hashes, "goblin: double-run hashes identical")
	_check_leads(ga, {48: 12, 49: 16}, "goblin")
	var shiv_hits := _hit_ticks(ga, 48)
	var pelt_hits := _hit_ticks(ga, 49)
	check(shiv_hits.size() >= 3, "goblin: shiv presses CONNECT (%d >= 3)" % shiv_hits.size())
	check(pelt_hits.size() >= 10, "goblin: the pelt stream is real (%d >= 10)" % pelt_hits.size())
	check(bool(ga.died), "goblin: a STANDING player dies to the lone goblin (harmless era over)")
	check(
		int(ga.death_tick) <= 3200,
		"goblin: the kill lands inside the run (t%d <= 3200)" % int(ga.death_tick)
	)
	# THE PELT FLOOR (the king_grubb pinch finding): a pressing goblin
	# commits to the shiv — no pelt volley ever fires from inside the
	# 2.0 trigger_range_min (checked at each pelt ATTACK tick).
	var pelt_floor_ok := true
	for a: Array in ga.attacks:
		if int(a[1]) == 49:
			var at := int(a[0])
			if at < ga.dist_trace.size() and ga.dist_trace[at] < 1.9:
				pelt_floor_ok = false
	check(pelt_floor_ok, "goblin: no point-blank pelts (trigger_range_min honored)")
	var shiv_volleys: Array = []
	for a: Array in ga.attacks:
		if int(a[1]) == 48:
			shiv_volleys.append(int(a[0]))
	check(shiv_volleys.size() >= 3, "goblin: >= 3 press cycles (%d)" % shiv_volleys.size())
	# After every shiv the goblin RETREATS (the flee phase is real)...
	var retreats := 0
	for st: int in shiv_volleys:
		var far := 0.0
		for t in range(st, mini(st + 180, ga.dist_trace.size())):
			far = maxf(far, ga.dist_trace[t])
		if far >= 2.8:
			retreats += 1
	check(
		retreats >= shiv_volleys.size() - 1,
		"goblin: retreat follows the shiv (%d/%d presses)" % [retreats, shiv_volleys.size()]
	)
	# ...and HOLDS the band between press cycles (loose walls around
	# [3.5, 5.0]; windup stand-stills ride inside the window).
	var band_ok := true
	for si in range(0, shiv_volleys.size() - 1):
		var lo := int(shiv_volleys[si]) + 150
		var hi := mini(int(shiv_volleys[si]) + 270, ga.dist_trace.size())
		for t in range(lo, hi):
			var d2: float = ga.dist_trace[t]
			if d2 < 2.4 or d2 > 6.2:
				band_ok = false
	check(band_ok, "goblin: the hold band holds between presses")

	# THE SET DISTANCE: while the gate cools, a player walking away is
	# APPROACHED once past range_max — the designer's flip, pinned on
	# the enemy's own velocity sign.
	var gw := _run_family(goblin, Vector2(16.0, 16.0), 1500, 700, 500)
	var far_moves := 0
	var far_toward := 0
	for row: Array in gw.toward_signs:
		if int(row[0]) >= 700 and float(row[1]) > 5.2:
			far_moves += 1
			if bool(row[2]):
				far_toward += 1
	check(
		far_moves >= 30,
		"goblin set-distance: the walk actually opens the gap (%d ticks)" % far_moves
	)
	if far_moves > 0:
		check(
			float(far_toward) / float(far_moves) >= 0.8,
			"goblin set-distance: it APPROACHES past 5.0 (%d/%d toward)" % [far_toward, far_moves]
		)

	print(
		(
			"goblin skirmish ok: shivs=%d pelts=%d death@%d far_toward=%d/%d"
			% [shiv_hits.size(), pelt_hits.size(), int(ga.death_tick), far_toward, far_moves]
		)
	)

	# ---- 4. OLD TUSK: the sl-0234 overlap case is DEAD. ----
	var ta := _run_family(tusk, Vector2(24.0, 16.0), 900)
	var tb := _run_family(tusk, Vector2(24.0, 16.0), 900)
	check(ta.hashes == tb.hashes, "old tusk: double-run hashes identical")
	var trample := _hit_ticks(ta, EnemyStep.PATTERN_CONTACT)
	var sweep := _hit_ticks(ta, 22)
	check(trample.size() >= 2, "old tusk overlap: the trample lands (%d >= 2)" % trample.size())
	var cadence_ok := true
	for i in range(1, trample.size()):
		if int(trample[i]) - int(trample[i - 1]) != int(tusk.contact_cooldown_ticks):
			cadence_ok = false
	check(cadence_ok, "old tusk overlap: trample cadence exactly contact_cooldown_ticks")
	check(not sweep.is_empty(), "old tusk overlap: his OWN blades hit the player inside him")
	check(bool(ta.died), "old tusk overlap: a player standing inside him DIES (sl-0234)")
	check(
		int(ta.last_pattern) in [22, EnemyStep.PATTERN_CONTACT],
		"old tusk overlap: the death trace is his (%d)" % int(ta.last_pattern)
	)
	# The march-in case (no stopping distance BY DESIGN — the body is
	# the threat): from range he closes, sweeps, tramples, kills.
	var tm := _run_family(tusk, Vector2(30.0, 16.0), 900)
	check(bool(tm.died), "old tusk march: a standing player still dies from range start")
	check(
		not _hit_ticks(tm, EnemyStep.PATTERN_CONTACT).is_empty(),
		"old tusk march: the trample arrives with the body"
	)
	check(not _hit_ticks(tm, 22).is_empty(), "old tusk march: sweeps connect on the way in")

	print(
		(
			"old tusk ok: trample=%d sweep=%d overlap-death@%d"
			% [trample.size(), sweep.size(), int(ta.death_tick)]
		)
	)

	# ---- 5. THE RANGE-BAND VOCABULARY (sl-0213). ----
	var grid: RefCounted = Bitgrid.new()
	grid.setup(96, 32)
	var world: RefCounted = ScenarioLoader.build_world(
		load("res://data/scenarios/lab_default.tres"), 1, grid
	)
	var declared := 0
	for def: Resource in world.enemy_defs:
		var band: StringName = def.range_band
		if band == &"":
			continue
		declared += 1
		check(
			EnemyDef.BANDS.has(band),
			"range band: %s declares a vocabulary word (%s)" % [String(def.id), String(band)]
		)
	check(declared >= 3, "range band: the wave-1 three declare (%d >= 3)" % declared)
	check(wolf.range_band == &"point_blank", "range band: wolf = point_blank")
	check(goblin.range_band == &"close", "range band: goblin = close")
	check(tusk.range_band == &"point_blank", "range band: old_tusk = point_blank")
	# NEGATIVE: an out-of-vocabulary word must be caught by the same
	# check that greens the roster.
	var fake: Resource = wolf.duplicate(true)
	fake.range_band = &"stabby"
	check(not EnemyDef.BANDS.has(fake.range_band), "negative: unknown band word is caught")

	# ---- 6. THE PRESS classifier: pelt-only kits never press. ----
	var no_melee: Resource = goblin.duplicate(true)
	var only_pelt: Array[Resource] = [no_melee.emitters[1]]
	no_melee.emitters = only_pelt
	var na := _run_family(no_melee, Vector2(16.0, 16.0), 1200)
	var close_after_settle := 1.0e9
	for t in range(400, na.dist_trace.size()):
		close_after_settle = minf(close_after_settle, na.dist_trace[t])
	check(
		close_after_settle >= 2.8,
		(
			"negative: a kit with no melee-class slot NEVER presses (min %.2f >= 2.8)"
			% close_after_settle
		)
	)

	if fails.is_empty():
		print(
			(
				"close_fighter_test: PASS (wolf circler / goblin flee-pelt / tusk overlap / "
				+ (
					"bands / press classifier; wolf kill t%d, goblin kill t%d, tusk overlap kill t%d)"
					% [int(wa.death_tick), int(ga.death_tick), int(ta.death_tick)]
				)
			)
		)
		quit(0)
	else:
		for m: String in fails:
			printerr("close_fighter_test FAIL: " + m)
		quit(1)
