extends SceneTree
## THE STAT FRAME contracts (docs/22 blocks 1-8; slice S0 seam 1,
## sl-0100). Pins: the loader's ruled-shape refusals (NEGATIVE-TESTED),
## THE damage formula's integer-exact truth table, class curves + the
## level share, the stepped XP curve (sums 20,600 to cap 30), tier-table
## weapon damage + the .tres/T1 drift pin, attack-speed/range scaling
## with structural identity at 100, the paired-trade grammar via the
## ring slot, armor slot derivation, the movement-integrator HARD CAP
## catching smuggled over-speed (the clamp's negative test), profile v2
## round-trip + the v1 fresh-start rule, regen honoring class maxes,
## and hash coverage of every new serialized field. Exit 0 = green.

const SimWorld := preload("res://sim/sim_world.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const Progress := preload("res://sim/systems/progress.gd")
const Damage := preload("res://sim/systems/damage.gd")
const PlayerRegen := preload("res://sim/systems/player_regen.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")

var fails: Array[String] = []


func check(cond: bool, name: String) -> void:
	if not cond:
		fails.append(name)


func _grid() -> RefCounted:
	var g: RefCounted = Bitgrid.new()
	g.setup(48, 32)
	return g


func _world(seed_v := 7) -> RefCounted:
	var world: RefCounted = SimWorld.new()
	world.setup(seed_v, _grid())
	world.set_progression(load("res://data/progression.tres"))
	world.set_stat_frame(StatFrame.load_frame())
	(
		world
		. set_abilities(
			[
				load("res://data/abilities/nova_burst.tres"),
				load("res://data/abilities/quickdraw.tres"),
				load("res://data/abilities/blast_rune.tres"),
			]
		)
	)
	world.add_player(Vector2(24.0, 16.0))
	return world


## Class-backed world via the REAL profile application path.
func _class_world(cls: String, seed_v := 7) -> RefCounted:
	var world: RefCounted = _world(seed_v)
	CharacterProfile.apply_to_world(world, CharacterProfile.create(false, cls))
	return world


func _move_frame() -> RefCounted:
	var f: RefCounted = InputFrame.new()
	f.move_x = 1
	return f


func _fire_frame() -> RefCounted:
	var f: RefCounted = InputFrame.new()
	f.fire_held = true
	f.aim_x = 4096
	return f


func _first_active_slot(world: RefCounted) -> int:
	var pool: RefCounted = world.projectiles
	for s in pool.CAPACITY:
		if pool.active[s] == 1:
			return s
	return -1


func _init() -> void:
	# 1. Loader: the real file is green; tampered copies REFUSE (the
	# gate's own negative tests — a drifted json must never load).
	var f := StatFrame.load_frame()
	check(not f.is_empty(), "balance_frame.json loads green")
	var bad_dir := "user://stat_frame_test"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(bad_dir))
	var real_text := FileAccess.get_file_as_string("res://data/balance_frame.json")
	var cases := {
		"floor_drift": real_text.replace('"floor_fraction": 0.2', '"floor_fraction": 0.0'),
		"cap_drift": real_text.replace('"hard_cap": 115', '"hard_cap": 150'),
		"missing_key": real_text.replace('"classes"', '"klasses"'),
		"not_json": "{ broken",
	}
	for cn: String in cases:
		var bp := bad_dir + "/" + cn + ".json"
		var bf := FileAccess.open(bp, FileAccess.WRITE)
		bf.store_string(cases[cn])
		bf.close()
		check(StatFrame.load_frame(bp).is_empty(), "loader refuses " + cn)

	# 2. THE formula (docs/22 block 2): integer-exact, ceil floor,
	# attacker's favor, one rounding step.
	check(StatFrame.taken(10, 0) == 10, "taken 10/0")
	check(StatFrame.taken(10, 5) == 5, "taken 10/5 (1 defense = 1 less)")
	check(StatFrame.taken(10, 9) == 2, "taken 10/9 floor binds ceil(2.0)=2")
	check(StatFrame.taken(3, 9) == 1, "taken 3/9 ceil(0.6)=1 (never zero)")
	check(StatFrame.taken(7, 9) == 2, "taken 7/9 ceil(1.4)=2")
	check(StatFrame.taken(15, 14) == 3, "taken 15/14 integer-exact (no float 3.0000004)")
	check(StatFrame.taken(40, 20) == 20, "taken 40/20 subtraction lane")
	check(StatFrame.taken(999, 999) == 200, "taken 999/999 ceil(199.8)=200")

	# 3. Class curves (block 5): bases + per-level; speed anchor 3.6
	# (sl-0102 re-ruling — the block-6 revisit, one constant).
	var bow: RefCounted = _class_world("bow")
	var bp2: RefCounted = bow.players[0]
	check(bp2.class_id == 2, "bow class id")
	check(bp2.max_hp == 90 and bp2.max_mana == 70, "bow L1 90hp/70mana")
	check(absf(bp2.move_speed - 3.96) < 0.0001, "bow speed 110 -> 3.96 t/s")
	var sword: RefCounted = _class_world("sword")
	var sp: RefCounted = sword.players[0]
	check(sp.max_hp == 120 and sp.max_mana == 60, "sword L1 120hp/60mana")
	check(absf(sp.move_speed - 3.6) < 0.0001, "sword speed 100 -> 3.60 t/s (the proof floor)")
	var staff: RefCounted = _class_world("staff")
	var tp: RefCounted = staff.players[0]
	check(tp.max_hp == 100 and tp.max_mana == 100, "staff L1 100hp/100mana")
	check(absf(tp.move_speed - 3.78) < 0.0001, "staff speed 105 -> 3.78 t/s")
	tp.level = 30
	StatFrame.recompute(staff, tp)
	check(tp.max_hp == 100 + 13 * 29, "staff L30 hp = base + 29 levels")

	# 4. Stepped XP (block 5): destination-bracket costs, 20,600 total,
	# cap stops cleanly, level-up grows hp/mana but NEVER damage.
	check(StatFrame.xp_to_next(bow, 1) == 100, "xp L1->2 green 100")
	check(StatFrame.xp_to_next(bow, 7) == 400, "xp L7->8 steps at the dry border")
	check(StatFrame.xp_to_next(bow, 15) == 800, "xp L15->16 wet 800")
	check(StatFrame.xp_to_next(bow, 22) == 1400, "xp L22->23 snow 1400")
	check(StatFrame.xp_to_next(bow, 30) == 0, "xp at cap = 0")
	var total := 0
	for lvl in range(1, 30):
		total += StatFrame.xp_to_next(bow, lvl)
	check(total == 20600, "xp sums 20,600 to cap 30")
	var dmg_before := Progress.shot_damage(bow, bp2, 999)
	var hp_before: int = bp2.max_hp
	Progress.award_xp(bow, bp2, 100)
	check(bp2.level == 2 and bp2.max_hp == hp_before + 11, "level-up grows class hp")
	check(Progress.shot_damage(bow, bp2, 999) == dmg_before, "NO automatic damage from levels")
	check(bp2.hp == bp2.max_hp and bp2.mana == bp2.max_mana, "level-up refills")
	bp2.level = 30
	bp2.xp = 0
	Progress.award_xp(bow, bp2, 99999)
	check(bp2.level == 30 and bp2.xp == 0, "cap 30 holds; xp stops accruing")
	bp2.level = 2

	# 5. Tier-table weapon damage (blocks 3/4) + the T1 drift pin
	# (sl-0120 x1.25 cadence pass tables).
	check(Progress.shot_damage(bow, bp2, 5) == 5, "bow T1 = 5 (table, not multiplier)")
	bp2.weapon_tiers[0] = 3
	check(Progress.shot_damage(bow, bp2, 5) == 10, "bow T3 = 10")
	bp2.weapon_tiers[0] = 5
	check(Progress.shot_damage(bow, bp2, 5) == 18, "bow T5 = 18")
	bp2.weapon_tiers[0] = 6
	check(Progress.shot_damage(bow, bp2, 5) == 18, "tier 6 clamps to the T5 table")
	bp2.weapon_tiers[0] = 1
	bp2.damage_mod = 4
	check(Progress.shot_damage(bow, bp2, 5) == 9, "gear damage mod adds flat")
	bp2.damage_mod = 0
	check(Progress.shot_damage(sword, sp, 17) == 17, "sword T1 = 17")
	sp.weapon_tiers[0] = 5
	check(Progress.shot_damage(sword, sp, 17) == 67, "sword T5 = 67")
	sp.weapon_tiers[0] = 1
	check(Progress.shot_damage(staff, tp, 8) == 8, "staff T1 = 8")
	var wt_frames: Dictionary = f.weapon_tiers.frames
	for pair: Array in [
		["res://data/weapons/class_sword.tres", "slow_heavy"],
		["res://data/weapons/class_bow.tres", "fast_light"],
		["res://data/weapons/class_staff.tres", "long_reach"],
	]:
		var wf: Resource = load(String(pair[0]))
		var row: Dictionary = wt_frames[String(pair[1])]
		var table: Array = row.damage
		var shots: Array = wf.shots
		for shot: Resource in shots:
			check(
				int(shot.damage) == int(table[0]),
				String(pair[0]) + " .tres damage documents the T1 table value"
			)
	# Legacy lane untouched: lab frame (no archetype) on a classless
	# player keeps the Loop v1 multiplier path.
	var legacy: RefCounted = _world()
	legacy.set_weapons([load("res://data/weapons/longbolt.tres")])
	var lp: RefCounted = legacy.players[0]
	check(Progress.shot_damage(legacy, lp, 12) == 12, "legacy T1/L1 identity")
	check(Progress.xp_to_next(legacy, 1) == 50, "legacy xp curve untouched")

	# 6. Attack speed / range: structural identity at 100; scaling both
	# ways; the ring trade wires through recompute (block 7 grammar).
	var fire_world: RefCounted = _class_world("bow", 9)
	var fp: RefCounted = fire_world.players[0]
	fire_world.step([_fire_frame()])
	check(fp.next_fire_tick == 24, "cadence identity at attack_speed 100")
	var slot := _first_active_slot(fire_world)
	check(slot >= 0, "identity fire spawned a shot")
	var ttl_identity: int = fire_world.projectiles.ttl[slot]
	check(fire_world.projectiles.damage[slot] == 5, "spawned shot carries table damage")
	check(fire_world.projectiles.pattern_id[slot] == 5, "bow pattern id 5")
	var fire2: RefCounted = _class_world("bow", 9)
	var fp2: RefCounted = fire2.players[0]
	fp2.attack_speed_stat = 150
	fp2.range_stat = 150
	fire2.step([_fire_frame()])
	check(fp2.next_fire_tick == 16, "attack_speed 150 -> cadence 16")
	var slot2 := _first_active_slot(fire2)
	check(slot2 >= 0, "scaled fire spawned a shot")
	var ttl_scaled: int = fire2.projectiles.ttl[slot2]
	check(ttl_scaled - ttl_identity == 12, "range 150 -> ttl 24->36 (+12)")
	var items: Array = f.items
	var ring_idx := -1
	for i in items.size():
		var it: Dictionary = items[i]
		if String(it.get("id", "")) == "t2-ring-of-reach":
			ring_idx = i
	check(ring_idx >= 0, "sample ring present in balance_frame items")
	fp2.ring_index = ring_idx
	StatFrame.recompute(fire2, fp2)
	check(
		fp2.range_stat == 102 and fp2.attack_speed_stat == 99,
		"ring of reach: +range/-attack_speed paired trade applies"
	)
	fp2.ring_index = -1
	StatFrame.recompute(fire2, fp2)
	check(fp2.range_stat == 100 and fp2.attack_speed_stat == 100, "unequip clears the trade")

	# 7. Armor slot (block 4) + THE formula through THE damage path.
	var aw: RefCounted = _class_world("sword", 11)
	var ap: RefCounted = aw.players[0]
	ap.armor_tier = 2
	StatFrame.recompute(aw, ap)
	check(ap.armor == 8, "armor T2 defense 8")
	check(ap.max_hp == 120 + 38, "armor T2 carries +38 hp")
	ap.hp = ap.max_hp
	Damage.apply(aw, ap, 10, 0)
	check(ap.hp == ap.max_hp - 2, "hit 10 vs armor 8 -> 2 through THE path (floor binds)")
	Damage.apply(aw, ap, 40, 0)
	check(ap.hp == ap.max_hp - 2 - 32, "hit 40 vs armor 8 -> 32")
	var hp_now: int = ap.hp
	Damage.apply(aw, ap, 10, SimWorld.PATTERN_TEST_SCHEDULE)
	check(ap.hp == hp_now - 10, "test schedule still bypasses all mitigation")

	# 7b. S1 seam 3 — unique armor override (block-8 break (c)): the
	# worn Hide REPLACES the tier ladder (def 12 vs the T2 budget 8,
	# T2-chassis hp) and pays a REAL −6 speed before the cap; taking
	# it off restores the ladder exactly.
	var hide_idx := -1
	for i2 in items.size():
		if String(items[i2].get("id", "")) == "u-old-tusks-hide":
			hide_idx = i2
	check(hide_idx >= 0, "the Hide present in balance_frame items")
	var uw: RefCounted = _class_world("sword", 15)
	var upx: RefCounted = uw.players[0]
	upx.armor_tier = 2
	StatFrame.recompute(uw, upx)
	var ladder_speed: float = upx.move_speed
	upx.armor_item_index = hide_idx
	StatFrame.recompute(uw, upx)
	check(upx.armor == 12, "Hide defense 12 overrides the T2 ladder's 8")
	check(upx.max_hp == 120 + 38, "Hide keeps the T2 hp row (the chassis)")
	check(
		(
			absf(upx.move_speed - (ladder_speed - 6.0 * StatFrame.SPEED_TILES_PER_100 / 100.0))
			< 0.0001
		),
		"the −6 speed cost is real"
	)
	upx.armor_item_index = -1
	StatFrame.recompute(uw, upx)
	check(upx.armor == 8, "removing the override restores the ladder")

	# 8. The movement-integrator HARD CAP (block 6): a smuggled
	# over-speed write cannot move a class-backed player past 3.45 t/s
	# (the clamp's negative test); the legacy lab band is untouched.
	var mw: RefCounted = _class_world("bow", 13)
	var mp: RefCounted = mw.players[0]
	mp.move_speed = 5.0
	var x0: float = mp.pos.x
	mw.step([_move_frame()])
	var moved: float = mp.pos.x - x0
	check(
		moved <= StatFrame.CAP_TILES_PER_S * SimWorld.DT + 0.0001,
		"integrator caps smuggled 5.0 t/s at 3.45"
	)
	check(moved >= StatFrame.CAP_TILES_PER_S * SimWorld.DT - 0.0001, "cap is a clamp, not a slow")
	var lw: RefCounted = _world(13)
	var lmp: RefCounted = lw.players[0]
	lmp.move_speed = 4.0
	var lx0: float = lmp.pos.x
	lw.step([_move_frame()])
	check(
		absf((lmp.pos.x - lx0) - 4.0 * SimWorld.DT) < 0.0001,
		"legacy lab player still moves at the 3.0-5.5 band speed"
	)
	# recompute-side cap: a hypothetical over-cap class base clamps in
	# the derivation too (belt to the integrator's suspenders).
	var mock: RefCounted = _class_world("sword", 13)
	var mock_frame: Dictionary = (mock.stat_frame as Dictionary).duplicate(true)
	var mock_classes: Dictionary = mock_frame.classes
	var mock_sword: Dictionary = mock_classes.sword
	mock_sword.base_speed = 130
	mock.set_stat_frame(mock_frame)
	var mkp: RefCounted = mock.players[0]
	StatFrame.recompute(mock, mkp)
	check(
		absf(mkp.move_speed - StatFrame.CAP_TILES_PER_S) < 0.0001,
		"recompute clamps stat 130 to the 115 cap"
	)

	# 9. Profile v2: round-trip + the v1 fresh-start rule.
	var prof := CharacterProfile.create(false, "staff")
	check(String(prof["class"]) == "staff", "create carries the class")
	var pw: RefCounted = _world(17)
	CharacterProfile.apply_to_world(pw, prof)
	var pwp: RefCounted = pw.players[0]
	check(pwp.class_id == 1, "apply lands staff class id")
	check(pw.weapon_frames.size() == 1, "class loadout replaces the lab trio")
	check(String(pw.weapon_frames[0].archetype) == "long_reach", "staff loadout = long_reach frame")
	check(pwp.weapon_tiers.size() == 1, "weapon tiers sized to the loadout")
	var harvested := prof.duplicate(true)
	pwp.gold = 55
	pwp.ring_index = ring_idx
	# sl-0116: bag round-trip BY ID — a ring + an armor tier in the bag.
	pwp.bag = PackedInt32Array([5, ring_idx, 0, 2, 3, 0])
	# sl-0130: the bank rides the same encoder.
	pwp.bank = PackedInt32Array([2, 4, 0])
	CharacterProfile.harvest(pw, harvested)
	# S1 seam 2: the profile keys the ring BY ID (items[] evolves
	# chapter by chapter; a raw index would silently re-point saves).
	check(
		int(harvested.gold) == 55 and String(harvested.ring_id) == "t2-ring-of-reach",
		"harvest carries (ring by id)"
	)
	check(String(harvested["class"]) == "staff", "harvest keeps the class")
	var bag_rows_h: Array = harvested.get("bag", [])
	check(
		(
			bag_rows_h.size() == 2
			and String(bag_rows_h[0].get("kind", "")) == "ring"
			and String(bag_rows_h[0].get("id", "")) == "t2-ring-of-reach"
			and String(bag_rows_h[1].get("kind", "")) == "armor"
			and int(bag_rows_h[1].get("tier", 0)) == 3
		),
		"harvest carries the bag BY ID/kind"
	)
	var re_applied: RefCounted = _world(19)
	CharacterProfile.apply_to_world(re_applied, harvested)
	check(
		re_applied.players[0].ring_index == ring_idx,
		"apply resolves ring_id back to the live items index"
	)
	var re_bag: PackedInt32Array = re_applied.players[0].bag
	check(
		(
			re_bag.size() == 6
			and re_bag[0] == 5
			and re_bag[1] == ring_idx
			and re_bag[3] == 2
			and re_bag[4] == 3
		),
		"apply resolves the bag rows back to live triples"
	)
	var re_bank: PackedInt32Array = re_applied.players[0].bank
	check(
		re_bank.size() == 3 and re_bank[0] == 2 and re_bank[1] == 4,
		"apply resolves the bank rows back to live triples (sl-0130)"
	)
	var v1 := {"version": 1, "hardcore": false, "gold": 999}
	var v1_path := bad_dir + "/character_v1.json"
	var v1f := FileAccess.open(v1_path, FileAccess.WRITE)
	v1f.store_string(JSON.stringify(v1))
	v1f.close()
	check(
		CharacterProfile.load_profile(v1_path).is_empty(),
		"v1 profiles read as no-character (fresh slice start rule)"
	)

	# 10. Regen honors class maxes (block 1 riding the level lane).
	# Regen runs on the tick-0 step (0 % 12 == 0) — one step suffices.
	var rw: RefCounted = _class_world("bow", 19)
	var rp: RefCounted = rw.players[0]
	rp.mana = 69
	rp.hp = rp.max_hp
	rw.step([InputFrame.new()])
	check(rp.mana == 70, "mana regen ticks toward and stops at the class max (70)")
	rw.step([InputFrame.new()])
	check(rp.mana == 70, "mana holds at the class max, not the v0 100")

	# 11. Hash coverage: every new serialized field diverges the hash.
	var hw: RefCounted = _class_world("bow", 23)
	var hp0: int = hw.state_hash()
	hw.players[0].class_id = 0
	check(hw.state_hash() != hp0, "class_id is hashed state")
	hw.players[0].class_id = 2
	var h1: int = hw.state_hash()
	hw.players[0].armor = 3
	check(hw.state_hash() != h1, "armor value is hashed state")
	hw.players[0].armor = 0
	var h2: int = hw.state_hash()
	hw.players[0].attack_speed_stat = 120
	check(hw.state_hash() != h2, "attack_speed_stat is hashed state")
	hw.players[0].attack_speed_stat = 100
	var h3: int = hw.state_hash()
	hw.players[0].range_stat = 120
	check(hw.state_hash() != h3, "range_stat is hashed state")
	hw.players[0].range_stat = 100
	var h4: int = hw.state_hash()
	hw.players[0].ring_index = 5
	check(hw.state_hash() != h4, "ring_index is hashed state")
	hw.players[0].ring_index = -1
	var h4b: int = hw.state_hash()
	hw.players[0].armor_item_index = 3
	check(hw.state_hash() != h4b, "armor_item_index is hashed state (SERIAL 18)")
	hw.players[0].armor_item_index = -1
	var h5: int = hw.state_hash()
	hw.players[0].damage_mod = 1
	check(hw.state_hash() != h5, "damage_mod is hashed state")
	hw.players[0].damage_mod = 0
	var h6: int = hw.state_hash()
	hw.players[0].bag = PackedInt32Array([2, 1, 0])
	check(hw.state_hash() != h6, "the bag is hashed state (SERIAL 23)")

	if fails.is_empty():
		print("stat_frame_test: PASS (formula/curves/xp/tiers/trades/cap/profile/hash)")
		quit(0)
	else:
		for m: String in fails:
			printerr("stat_frame_test FAIL: " + m)
		quit(1)
