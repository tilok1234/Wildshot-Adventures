extends SceneTree
## Loop v1 sim contracts (docs/19, ask sl-0025): deterministic drop
## sequences from the named loot stream, stream independence (loot can
## never perturb enemy variation), XP/level curve + growth + refill,
## armor mitigation floor + §2.11 schedule bypass, pickup upgrade-only
## rules, tier/level damage scaling with identity at defaults. Exit 0 =
## green.

const SimWorld := preload("res://sim/sim_world.gd")
const EnemyDefScript := preload("res://data/enemy_def.gd")
const Progress := preload("res://sim/systems/progress.gd")
const Damage := preload("res://sim/systems/damage.gd")
const LootStep := preload("res://sim/systems/loot_step.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const ItemText := preload("res://game/views/item_text.gd")

var fails: Array[String] = []


func check(cond: bool, name: String) -> void:
	if not cond:
		fails.append(name)


func _drop_def() -> Resource:
	var def: Resource = EnemyDefScript.new()
	def.id = &"loot_dummy"
	def.hp = 10
	def.xp_value = 30
	def.gold_min = 3
	def.gold_max = 7
	def.drop_chance = 0.5
	def.drop_tier_min = 1
	def.drop_tier_max = 3
	return def


func _world_with(def: Resource, seed_v: int) -> RefCounted:
	var world: RefCounted = SimWorld.new()
	world.setup(seed_v, null)
	world.set_progression(load("res://data/progression.tres"))
	(
		world
		. set_weapons(
			[
				load("res://data/weapons/longbolt.tres"),
				load("res://data/weapons/scattercast.tres"),
				load("res://data/weapons/wheelblade.tres"),
			]
		)
	)
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
	world.set_enemy_defs([def])
	world.add_player(Vector2(20.0, 12.0))
	return world


func _kill_n(world: RefCounted, n: int) -> void:
	for i in n:
		var e: RefCounted = world.add_enemy(0, Vector2(22.0 + i, 12.0))
		Damage.apply(world, e, 9999, 0)
		Damage.sweep_dead_enemies(world)


func _init() -> void:
	# 1. Same seed -> byte-identical drop sequence; different seed differs.
	var a: RefCounted = _world_with(_drop_def(), 77)
	var b: RefCounted = _world_with(_drop_def(), 77)
	var c: RefCounted = _world_with(_drop_def(), 78)
	_kill_n(a, 12)
	_kill_n(b, 12)
	_kill_n(c, 12)
	check(JSON.stringify(a.drops) == JSON.stringify(b.drops), "same-seed drops identical")
	check(JSON.stringify(a.drops) != JSON.stringify(c.drops), "different-seed drops differ")
	check(not a.drops.is_empty(), "12 kills produced drops (gold guaranteed)")

	# 2. Loot draws never touch the enemy stream: a def with NO drop data
	# leaves rng_loot untouched, and rng_enemy equals the drop-rich run's
	# (only rng_loot may diverge between them).
	var inert: Resource = EnemyDefScript.new()
	inert.id = &"inert"
	inert.hp = 10
	var d: RefCounted = _world_with(inert, 77)
	_kill_n(d, 12)
	var fresh: RefCounted = _world_with(inert, 77)
	check(d.rng_loot.state == fresh.rng_loot.state, "inert def draws nothing from rng_loot")
	check(a.rng_enemy.state == d.rng_enemy.state, "loot rolls never advance rng_enemy")

	# 3. XP/level curve: 50 + 75*(n-1); growth + full refill on level-up.
	var p: RefCounted = a.players[0]
	var lvl0: int = p.level
	p.hp = 1
	Progress.award_xp(a, p, Progress.xp_to_next(a, p.level))
	check(p.level == lvl0 + 1, "level-up at exact curve cost")
	check(p.max_hp == 100 + (p.level - 1) * 8, "max_hp growth per level")
	check(p.hp == p.max_hp, "level-up refills hp")
	check(Progress.xp_to_next(a, 1) == 50 and Progress.xp_to_next(a, 3) == 200, "curve values")

	# 4. Damage scaling: identity at tier1/level1; tier table applies.
	var w: RefCounted = _world_with(_drop_def(), 5)
	var wp: RefCounted = w.players[0]
	check(Progress.shot_damage(w, wp, 10) == 10, "tier1/level1 damage identity")
	wp.weapon_tiers[0] = 5
	check(Progress.shot_damage(w, wp, 10) == 23, "tier5 damage 10*2.3")
	wp.weapon_tiers[0] = 1
	wp.level = 11
	check(Progress.shot_damage(w, wp, 10) == 12, "level 11 damage 10*1.20")

	# 5. Armor: flat reduction, floor 1, schedule bypass.
	wp.level = 1
	wp.armor_tier = 3
	wp.hp = 100
	Damage.apply(w, wp, 10, 0)
	check(wp.hp == 100 - 6, "armor tier3 reduces 10 to 6")
	Damage.apply(w, wp, 3, 0)
	check(wp.hp == 94 - 1, "mitigation floors at 1")
	wp.hp = 100
	Damage.apply(w, wp, 10, SimWorld.PATTERN_TEST_SCHEDULE)
	check(wp.hp == 90, "test schedule bypasses armor")

	# 6. Pickup rules: gold adds; equal-tier weapon stays; upgrade equips.
	var u: RefCounted = _world_with(_drop_def(), 9)
	var up: RefCounted = u.players[0]
	u.spawn_drop(up.pos, SimWorld.DROP_GOLD, 25)
	u.spawn_drop(up.pos, SimWorld.DROP_WEAPON, 0, 1)
	u.spawn_drop(up.pos, SimWorld.DROP_WEAPON, 1, 4)
	u.spawn_drop(up.pos, SimWorld.DROP_ARMOR, 2)
	LootStep.run(u)
	check(up.gold == 25, "gold picked up")
	check(up.weapon_tiers[0] == 1 and u.drops.size() == 1, "equal-tier weapon stays on ground")
	check(up.weapon_tiers[1] == 4, "higher-tier weapon equips")
	check(up.armor_tier == 2, "armor upgrade equips")

	# 7. Serialization: drops + progression fields round through the hash.
	var h1: int = u.state_hash()
	up.gold += 1
	check(u.state_hash() != h1, "gold is hashed state")

	# 8. Bone Reliquary King data pins (docs/19 ruling 4): the Warden kit
	# at 900 HP [T] — phase floors 594/297, unique table well-formed.
	var king: Resource = load("res://data/enemies/bone_reliquary_king.tres")
	check(int(king.hp) == 900, "king hp 900 [T]")
	check(king.phase_for_hp(595) == 0 and king.phase_for_hp(594) == 1, "king p2 floor 594")
	check(king.phase_for_hp(298) == 1 and king.phase_for_hp(297) == 2, "king p3 floor 297")
	check(
		king.unique_drops.size() == 1 and king.unique_chances.size() == 1,
		"king unique table parallel arrays"
	)
	var uniq: Resource = king.unique_drops[0]
	check(String(uniq.display_name) == "Reliquary Coil", "unique placeholder present")

	# 9. S1 seam 2 — RING drops (block 7: the pure situational slot).
	# wr joins the kind roll ONLY when set (wr=0 defs keep their exact
	# draw sequence — the repo-wide pin is the battery byte gate); the
	# ring branch picks among ring items AT the drawn tier; walk-over
	# equips only an EMPTY slot and wires the trade through recompute.
	var ring_def: Resource = EnemyDefScript.new()
	ring_def.id = &"ring_dummy"
	ring_def.hp = 10
	ring_def.drop_chance = 1.0
	ring_def.drop_w_weapon = 0
	ring_def.drop_w_armor = 0
	ring_def.drop_w_ability = 0
	ring_def.drop_w_ring = 1
	ring_def.drop_tier_min = 1
	ring_def.drop_tier_max = 1
	var rw: RefCounted = _world_with(ring_def, 91)
	rw.set_stat_frame(StatFrame.load_frame())
	var rp: RefCounted = rw.players[0]
	rp.class_id = 2  # bow lane; recompute derives speed/hp for trades
	rp.level = 1
	StatFrame.recompute(rw, rp)
	var base_speed: float = rp.move_speed
	var base_hp: int = rp.max_hp
	_kill_n(rw, 1)
	check(rw.drops.size() == 1, "ring def drops exactly one ring")
	var rd: Dictionary = rw.drops[0]
	check(int(rd.kind) == SimWorld.DROP_RING, "drop kind is RING")
	var ritems: Array = rw.stat_frame.items
	var rit: Dictionary = ritems[int(rd.a)]
	check(String(rit.slot) == "ring" and int(rit.tier) == 1, "ring branch picks a T1 ring item")
	rp.pos = rd.pos
	LootStep.run(rw)
	check(rp.ring_index == int(rd.a) and rw.drops.is_empty(), "empty slot equips the ring")
	check(rp.move_speed != base_speed or rp.max_hp != base_hp, "ring trade wires through recompute")
	# Occupied slot: the next ring stays on the ground (a choice, not
	# a ladder — swap semantics are a designer call later).
	_kill_n(rw, 1)
	var held: int = rp.ring_index
	rp.pos = rw.drops[0].pos
	LootStep.run(rw)
	check(rw.drops.size() == 1 and rp.ring_index == held, "occupied slot leaves rings grounded")
	# Legacy lane: class -1 never equips rings.
	var lw: RefCounted = _world_with(ring_def, 93)
	lw.set_stat_frame(StatFrame.load_frame())
	_kill_n(lw, 1)
	lw.players[0].pos = lw.drops[0].pos
	LootStep.run(lw)
	check(lw.players[0].ring_index == -1 and lw.drops.size() == 1, "legacy player refuses rings")

	# 10. THE ONE ITEM-TEXT GRAMMAR (docs/22: every number visible; one
	# grammar everywhere) — exact lines, pinned.
	var haste_idx := -1
	for ii in ritems.size():
		if String(ritems[ii].get("id", "")) == "t1-ring-of-haste":
			haste_idx = ii
	check(haste_idx >= 0, "ring of haste present")
	check(
		(
			ItemText.drop_line(rw, {"kind": SimWorld.DROP_RING, "a": haste_idx, "b": 0})
			== "Ring of Haste — +2 spd / −8 hp"
		),
		"ring line exact"
	)
	check(
		(
			ItemText.drop_line(rw, {"kind": SimWorld.DROP_ARMOR, "a": 1, "b": 0})
			== "T1 Armor — +5 def, +30 hp"
		),
		"armor line exact"
	)
	check(
		ItemText.drop_line(rw, {"kind": SimWorld.DROP_GOLD, "a": 12, "b": 0}) == "12 gold",
		"gold line exact"
	)
	var cw: RefCounted = _world_with(ring_def, 95)
	cw.set_stat_frame(StatFrame.load_frame())
	cw.set_weapons([load("res://data/weapons/class_bow.tres")])
	check(
		(
			ItemText.drop_line(cw, {"kind": SimWorld.DROP_WEAPON, "a": 0, "b": 1})
			== "T1 Bow — 6 dmg @ 2.0/s"
		),
		"class weapon line exact (tier table + cadence)"
	)
	check(
		ItemText.drop_line(u, {"kind": SimWorld.DROP_WEAPON, "a": 0, "b": 2}) == "T2 Longbolt",
		"lab weapon line falls back to name+tier"
	)

	if fails.is_empty():
		print("loop_test: PASS (drops/streams/curve/damage/armor/pickup/rings/text/hash)")
		quit(0)
	else:
		for m: String in fails:
			printerr("loop_test FAIL: " + m)
		quit(1)
