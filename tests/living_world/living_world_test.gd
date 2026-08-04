extends SceneTree
## LIVING-WORLD PLUMBING contracts (docs/23 S0 seam 2, sl-0100):
## importer census pins on the vendored content pack (NEGATIVE-TESTED
## against corrupt packs + unknown roster ids), leash wake/sleep with
## damage-persistent fold-back and NO kill events on fold, away-only
## respawn (nothing ever pops in a player's face — structurally),
## territory tether walk-home, the sl-0219 chase leash (give-up
## beyond 18 t + full return-home past the rim, site members only —
## non-site enemies keep chase-forever), rng stream discipline
## (single-option draws consume nothing; pack draws never touch
## rng_loot), site-state hash coverage, and end-to-end slice-world
## determinism. Exit 0 = green.

const SimWorld := preload("res://sim/sim_world.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const SiteStep := preload("res://sim/systems/site_step.gd")
const Damage := preload("res://sim/systems/damage.gd")
const ContentImporter := preload("res://game/arena/content_importer.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const SimEvents := preload("res://sim/events.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")

const PACK := "res://assets/wildshot-overworld-pack-dusk-content/"

var fails: Array[String] = []


func check(cond: bool, name: String) -> void:
	if not cond:
		fails.append(name)


func _grid() -> RefCounted:
	var g: RefCounted = Bitgrid.new()
	g.setup(96, 32)
	return g


func _synth_def(pack_min: int, pack_max: int, respawn := 20) -> Dictionary:
	return {
		"cell": Vector2(70.5, 16.5),
		"roster_defs": PackedInt32Array([0]),
		"roster_weights": PackedInt32Array([1]),
		"pack_min": pack_min,
		"pack_max": pack_max,
		"max_active": 5,
		"respawn_ticks": respawn,
		"kind": "territory",
		"zone": "green",
	}


func _synth_world(seed_v := 7, pack_min := 3, pack_max := 3) -> RefCounted:
	var world: RefCounted = SimWorld.new()
	world.setup(seed_v, _grid())
	world.set_progression(load("res://data/progression.tres"))
	(
		world
		. set_enemy_defs(
			[
				load("res://data/enemies/rusher.tres"),
				load("res://data/enemies/husk_archer.tres"),
			]
		)
	)
	world.add_player(Vector2(10.5, 16.5))
	world.set_site_defs([_synth_def(pack_min, pack_max)])
	return world


func _step(world: RefCounted, n := 1) -> void:
	for i in n:
		world.step([InputFrame.new()])


func _site_enemies(world: RefCounted) -> Array:
	var out: Array = []
	for e: RefCounted in world.enemies:
		if e.site_index >= 0:
			out.append(e)
	return out


func _init() -> void:
	# 1. Importer census on the vendored pack (pins from the seam-2
	# probe; a re-authored drop moves these DELIBERATELY, with eyes).
	var got := ContentImporter.build_sites(PACK)
	check(bool(got.ok), "importer green on the vendored pack")
	var report: Dictionary = got.report
	check(int(report.territories) == 92, "92 territories")
	check(int(report.encounters_mapped) == 97, "97 encounters inherit a territory table")
	check(int(report.encounters_skipped) == 15, "15 territory-less encounters skipped, counted")
	check(int(report.bosses) == 4, "4 world-boss sites (one per zone)")
	check(int(report.dungeons_skipped) == 11, "11 dungeon bindings recorded for chapter work")
	check(int(report.unknown_ids) == 0, "zero unknown roster ids")
	check(int(report.sites) == 193, "193 sites total")
	var sites_arr: Array = got.sites
	var zone_census := {}
	for s: Dictionary in sites_arr:
		zone_census[s.zone] = int(zone_census.get(s.zone, 0)) + 1
		if String(s.kind) == "boss":
			var rd: PackedInt32Array = s.roster_defs
			# S1 seam 3: green's boss has its real identity (Old Tusk,
			# def 22); the other zones keep the Warden stand-in until
			# their chapters name them.
			var want_def := 22 if String(s.zone) == "green" else 6
			check(
				rd.size() == 1 and rd[0] == want_def,
				"boss site carries its zone's identity (green = Old Tusk)"
			)
	check(int(zone_census.get("green", 0)) == 94, "green owns 94 sites")
	# Depth key: lazy Green, fast Snow (docs/23 (c), W-3).
	var green_ticks := -1
	var cold_ticks := -1
	for s: Dictionary in sites_arr:
		if String(s.kind) == "territory":
			if String(s.zone) == "green" and green_ticks < 0:
				green_ticks = int(s.respawn_ticks)
			elif String(s.zone) == "cold" and cold_ticks < 0:
				cold_ticks = int(s.respawn_ticks)
	check(green_ticks > cold_ticks and cold_ticks > 0, "respawn lazy in Green, fast in Snow")

	# 2. Negative tests: the gate refuses garbage loudly.
	check(not bool(ContentImporter.build_sites("user://no_such_pack/").ok), "missing pack refused")
	var bad_dir := "user://living_world_test/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(bad_dir))
	var plan := FileAccess.get_file_as_string(PACK + "content-plan.json")
	var terr := FileAccess.get_file_as_string(PACK + "territories.json")
	var plac := FileAccess.get_file_as_string(PACK + "placements.json")
	for pair: Array in [
		["content-plan.json", plan],
		["territories.json", terr.replace("enemy.marauder", "enemy.gremlin")],
		["placements.json", plac],
	]:
		var f := FileAccess.open(bad_dir + String(pair[0]), FileAccess.WRITE)
		f.store_string(String(pair[1]))
		f.close()
	var bad := ContentImporter.build_sites(bad_dir)
	check(not bool(bad.ok), "unknown roster id refuses the pack")
	var bad_report: Dictionary = bad.report
	check(int(bad_report.unknown_ids) >= 1, "unknown id counted")

	# 3. Leash mechanics on a synthetic site (fixed pack of 3 — no rng).
	var w: RefCounted = _synth_world()
	var p: RefCounted = w.players[0]
	var site: Dictionary = w.sites[0]
	var pop0: PackedInt32Array = site.pop_def
	check(pop0.size() == 3, "setup stocked the dormant population")
	_step(w)
	check(not bool(w.sites[0].awake), "far player leaves the site dormant")
	check(_site_enemies(w).is_empty(), "dormant site has no live members")
	p.pos = Vector2(55.5, 16.5)  # dist 15 < WAKE 22
	_step(w)
	check(bool(w.sites[0].awake), "site wakes inside the leash")
	check(_site_enemies(w).size() == 3, "the whole pack spawns on wake")
	var woke_pop: PackedInt32Array = w.sites[0].pop_def
	check(woke_pop.is_empty(), "population moves out on wake")
	for e: RefCounted in _site_enemies(w):
		check(e.site_index == 0, "members carry their site index")
	# Kill one; damage another — both must persist across the sleep.
	var members := _site_enemies(w)
	Damage.apply(w, members[0], 99999, 0)
	Damage.sweep_dead_enemies(w)
	var hurt: RefCounted = _site_enemies(w)[0]
	hurt.hp = 5
	var kill_events_before := 0
	p.pos = Vector2(10.5, 16.5)  # dist 60 > SLEEP 30
	_step(w)
	for ev: Dictionary in w.events:
		if int(ev.type) == SimEvents.Type.ENTITY_KILLED:
			kill_events_before += 1
	check(kill_events_before == 0, "folding emits NO kill events")
	check(not bool(w.sites[0].awake), "site sleeps beyond the hysteresis")
	check(_site_enemies(w).is_empty(), "sleep removes live members")
	var slept_def: PackedInt32Array = w.sites[0].pop_def
	var slept_hp: PackedInt32Array = w.sites[0].pop_hp
	check(slept_def.size() == 2, "the kill persisted (2 of 3 fold back)")
	check(slept_hp[0] == 5 or slept_hp[1] == 5, "damage persists across the sleep")

	# 4. Away-only respawn: empty the site, timer arms ONLY dormant.
	var w2: RefCounted = _synth_world(9)
	var p2: RefCounted = w2.players[0]
	p2.pos = Vector2(55.5, 16.5)
	_step(w2)
	for e: RefCounted in _site_enemies(w2):
		Damage.apply(w2, e, 99999, 0)
	Damage.sweep_dead_enemies(w2)
	check(_site_enemies(w2).is_empty(), "site emptied by kills")
	_step(w2, 60)
	var camped: Dictionary = w2.sites[0]
	var camped_pop: PackedInt32Array = camped.pop_def
	check(bool(camped.awake), "camped site stays awake")
	check(int(camped.respawn_at) < 0, "respawn NEVER arms while a player is near")
	check(camped_pop.is_empty(), "nothing pops in the player's face")
	p2.pos = Vector2(10.5, 16.5)
	_step(w2)
	check(int(w2.sites[0].respawn_at) > 0, "timer arms once dormant")
	_step(w2, 25)
	var refilled: PackedInt32Array = w2.sites[0].pop_def
	check(refilled.size() == 3, "away timer refills a fresh full pack")
	check(int(w2.sites[0].respawn_at) < 0, "timer disarms after the refill")

	# 5. Tether: a dragged member disengages and walks home.
	var w3: RefCounted = _synth_world(11)
	var p3: RefCounted = w3.players[0]
	p3.pos = Vector2(55.5, 16.5)
	_step(w3)
	var stray: RefCounted = _site_enemies(w3)[0]
	stray.pos = Vector2(70.5 - 14.0, 16.5)  # 14 tiles from home > TETHER 12
	var dist_before: float = stray.pos.distance_to(Vector2(70.5, 16.5))
	_step(w3)
	var dist_after: float = stray.pos.distance_to(Vector2(70.5, 16.5))
	check(dist_after < dist_before, "tethered member walks home")
	check(int(stray.ai_state) == 0, "walking home reads IDLE (windup canceled)")

	# 5b. sl-0219 chase-leash: give-up + full return-home, SITE
	# MEMBERS ONLY (the measured gang-train fix —
	# reports/chase_leash_diagnosis.md). Positions are staged
	# directly per sub-check; the player always stays inside the
	# site's 30-t sleep envelope so nothing folds mid-pin.
	var w3b: RefCounted = _synth_world(19)
	var p3b: RefCounted = w3b.players[0]
	p3b.pos = Vector2(63.5, 16.5)
	_step(w3b)
	var chaser: RefCounted = _site_enemies(w3b)[0]
	chaser.pos = Vector2(68.5, 16.5)
	_step(w3b)
	check(int(chaser.ai_state) != 0, "member engages inside aggro (5 t)")
	# Between aggro and give-up (13.5 t): the chase holds — the
	# hysteresis band is structural (give-up 18 > aggro 12).
	chaser.pos = Vector2(68.5, 16.5)
	p3b.pos = Vector2(55.0, 16.5)
	_step(w3b)
	check(int(chaser.ai_state) != 0, "13.5 t: still chasing (inside the band)")
	# Beyond give-up (20 t): one tick disengages.
	chaser.pos = Vector2(68.5, 16.5)
	p3b.pos = Vector2(48.5, 16.5)
	_step(w3b)
	check(int(chaser.ai_state) == 0, "20 t from the player: gives up (IDLE)")
	# The rim case the old code parked forever: 11 t out (inside the
	# tether), player away but the site still awake — the member now
	# walks ALL the way home to RETURN_RADIUS and stands. Budget: 6 t
	# at 2.7 t/s = ~134 ticks at 60 tps, plus slack.
	chaser.pos = Vector2(59.5, 16.5)
	p3b.pos = Vector2(44.5, 16.5)
	_step(w3b, 240)
	var hd: float = chaser.pos.distance_to(Vector2(70.5, 16.5))
	check(hd <= SiteStep.RETURN_RADIUS + 0.01, "walks home past the rim (%.2f <= 5)" % hd)
	var settle: Vector2 = chaser.pos
	_step(w3b, 30)
	check(chaser.pos == settle, "and stands once re-centered")
	# A windup in flight is never interrupted by give-up (Law 8: the
	# telegraph completes and resolves honestly at range).
	chaser.pos = Vector2(68.5, 16.5)
	p3b.pos = Vector2(48.5, 16.5)
	chaser.ai_state = 2
	chaser.winding_slot = 0
	chaser.state_until = w3b.tick + 30
	_step(w3b)
	check(int(chaser.ai_state) == 2, "give-up never interrupts a windup")
	# Fresh wakes never shuffle: spawn rings max 4.4 sit inside
	# RETURN_RADIUS, so a woken-but-unaggroed pack stands still.
	var w3c: RefCounted = _synth_world(23)
	var p3c: RefCounted = w3c.players[0]
	p3c.pos = Vector2(50.5, 16.5)
	_step(w3c)
	var spawn_spots: Array[Vector2] = []
	for e: RefCounted in _site_enemies(w3c):
		spawn_spots.append(e.pos)
	_step(w3c, 30)
	var shuffled := false
	var spot_i := 0
	for e: RefCounted in _site_enemies(w3c):
		if e.pos != spawn_spots[spot_i]:
			shuffled = true
		spot_i += 1
	check(not shuffled, "a woken unaggroed pack never shuffles at its slots")
	# Non-site enemies keep chase-forever by construction (labs, the
	# Warren, the rift dungeon, every authored proof).
	var loner: RefCounted = w3c.add_enemy(0, Vector2(30.5, 16.5))
	p3c.pos = Vector2(28.5, 16.5)
	_step(w3c)
	check(int(loner.ai_state) != 0, "non-site enemy engages")
	p3c.pos = Vector2(5.5, 16.5)
	_step(w3c, 30)
	check(int(loner.ai_state) != 0, "non-site enemy NEVER gives up (25 t away, still chasing)")

	# 6. RNG discipline: fixed single-option draws consume NOTHING;
	# varied draws advance rng_enemy and never rng_loot.
	var w4: RefCounted = _synth_world(13, 3, 3)
	var enemy_state_before: int = w4.rng_enemy.state
	var loot_state_before: int = w4.rng_loot.state
	SiteStep.fill_population(
		w4, w4.site_defs[0], {"pop_def": PackedInt32Array(), "pop_hp": PackedInt32Array()}
	)
	check(w4.rng_enemy.state == enemy_state_before, "fixed pack + single roster draws no rng")
	var varied := _synth_def(2, 6)
	varied.roster_defs = PackedInt32Array([0, 1])
	varied.roster_weights = PackedInt32Array([40, 60])
	SiteStep.fill_population(
		w4, varied, {"pop_def": PackedInt32Array(), "pop_hp": PackedInt32Array()}
	)
	check(w4.rng_enemy.state != enemy_state_before, "varied draws use rng_enemy")
	check(w4.rng_loot.state == loot_state_before, "site draws never touch rng_loot")

	# 7. Hash coverage: site state is serialized state.
	var w5: RefCounted = _synth_world(17)
	var h0: int = w5.state_hash()
	w5.sites[0].awake = true
	check(w5.state_hash() != h0, "awake flag is hashed")
	w5.sites[0].awake = false
	var h1: int = w5.state_hash()
	w5.sites[0].respawn_at = 12345
	check(w5.state_hash() != h1, "respawn timer is hashed")
	w5.sites[0].respawn_at = -1
	var h2: int = w5.state_hash()
	var pd: PackedInt32Array = w5.sites[0].pop_def
	pd[0] = 1
	w5.sites[0].pop_def = pd
	check(w5.state_hash() != h2, "population is hashed")

	# 8. End-to-end slice-world determinism: two builds of the real
	# scenario, same seed, 60 ticks — byte-identical state.
	var scen: Resource = load("res://data/scenarios/slice_overworld.tres")
	var wf := WorldforgePack.validate(String(scen.worldforge_pack))
	check(bool(wf.ok), "b77 validates for the slice scenario")
	if bool(wf.ok):
		var a: RefCounted = ScenarioLoader.build_world(scen, 100, wf.bitgrid)
		var b: RefCounted = ScenarioLoader.build_world(scen, 100, wf.bitgrid)
		check(a.sites.size() == 193, "slice world carries all 193 sites")
		# sl-0219 structural pins on the real roster: give-up strictly
		# above every site-reachable def's aggro (hysteresis by
		# construction), return radius strictly above the outermost
		# spawn ring (fresh wakes never shuffle).
		var worst_aggro := 0.0
		for sd: Dictionary in a.site_defs:
			for d in sd.roster_defs:
				worst_aggro = maxf(worst_aggro, float(a.enemy_defs[d].aggro_range))
		check(
			worst_aggro < SiteStep.GIVE_UP_RADIUS,
			(
				"give-up %.1f sits above every site def's aggro (max %.1f)"
				% [SiteStep.GIVE_UP_RADIUS, worst_aggro]
			)
		)
		var max_ring := 0.0
		for r: float in SiteStep.SPAWN_RINGS:
			max_ring = maxf(max_ring, r)
		check(SiteStep.RETURN_RADIUS > max_ring, "return radius clears the outermost spawn ring")
		_step(a, 60)
		_step(b, 60)
		check(
			a.serialize() == b.serialize(), "same seed, same 60 ticks -> byte-identical slice world"
		)
		var c: RefCounted = ScenarioLoader.build_world(scen, 101, wf.bitgrid)
		_step(c, 60)
		check(a.serialize() != c.serialize(), "different seed diverges")

	# 9. CORE-43 overworld death (seam 3): in-sim gold slice at the
	# death tick, settlement respawn on the timer, ability-key early
	# confirm; dead-in-place stands everywhere the flag is off.
	var dw: RefCounted = _synth_world(21)
	dw.set_stat_frame(StatFrame.load_frame())
	CharacterProfile.apply_to_world(dw, CharacterProfile.create(false, "bow"))
	dw.persistent_respawn = true
	dw.respawn_cell = Vector2(10.5, 16.5)
	var dp: RefCounted = dw.players[0]
	dp.gold = 100
	dp.pos = Vector2(40.5, 16.5)
	Damage.apply(dw, dp, 99999, 0)
	check(dp.dead, "player dies in place first")
	check(dp.gold == 75, "death takes the 25% gold slice IN-SIM [T]")
	check(dp.respawn_at_tick == dw.tick + 240, "settlement respawn timer armed")
	var death_ev_gold := -1
	for ev: Dictionary in dw.events:
		if int(ev.type) == SimEvents.Type.ENTITY_KILLED and bool(ev.get("player", false)):
			death_ev_gold = int(ev.get("gold_lost", -1))
	check(death_ev_gold == 25, "death event carries gold_lost for the toast")
	_step(dw, 239)
	check(dp.dead, "still dead one tick before the timer")
	_step(dw, 2)
	check(not dp.dead, "timer respawn fires")
	check(dp.pos == Vector2(10.5, 16.5), "respawn lands at the settlement")
	check(
		dp.hp == dp.max_hp and dp.mana == dp.max_mana,
		"respawn refills (the walk back is the price)"
	)
	var saw_respawn := false
	for ev: Dictionary in dw.events:
		if int(ev.type) == SimEvents.Type.PLAYER_RESPAWNED:
			saw_respawn = true
	check(saw_respawn, "PLAYER_RESPAWNED emitted")
	# Early confirm: the ability key while dead.
	dp.pos = Vector2(40.5, 16.5)
	Damage.apply(dw, dp, 99999, 0)
	check(dp.dead and dp.gold == 57, "second death costs again (75 - 18 = 57)")
	var confirm_frame: RefCounted = InputFrame.new()
	confirm_frame.ability_pressed = true
	dw.step([confirm_frame])
	check(not dp.dead, "ability key while dead respawns immediately")
	check(dp.pos == Vector2(10.5, 16.5), "early respawn lands at the settlement too")
	# Negative: the flag off = dead-in-place, gold untouched (every
	# lab/proof world, hardcore characters).
	var nw: RefCounted = _synth_world(23)
	nw.set_stat_frame(StatFrame.load_frame())
	CharacterProfile.apply_to_world(nw, CharacterProfile.create(false, "bow"))
	var np: RefCounted = nw.players[0]
	np.gold = 100
	Damage.apply(nw, np, 99999, 0)
	check(np.dead and np.gold == 100, "non-persistent death: no cost, dead in place")
	_step(nw, 300)
	check(np.dead, "non-persistent stays dead through any wait")
	# Negative: a LEGACY (class -1) player in a persistent world keeps
	# dead-in-place — bot worlds never respawn.
	var lw2: RefCounted = _synth_world(25)
	lw2.persistent_respawn = true
	lw2.respawn_cell = Vector2(10.5, 16.5)
	var lp2: RefCounted = lw2.players[0]
	lp2.gold = 100
	Damage.apply(lw2, lp2, 99999, 0)
	check(lp2.dead and lp2.gold == 100, "legacy player: persistent flag changes nothing")
	_step(lw2, 300)
	check(lp2.dead, "legacy player stays dead")

	if fails.is_empty():
		print(
			"living_world_test: PASS (census/leash/respawn/tether/give-up/rng/hash/determinism/death)"
		)
		quit(0)
	else:
		for m: String in fails:
			printerr("living_world_test FAIL: " + m)
		quit(1)
