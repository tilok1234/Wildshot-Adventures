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
const BagStep := preload("res://sim/systems/bag_step.gd")
const SimEvents := preload("res://sim/events.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const ItemText := preload("res://game/views/item_text.gd")
const InputFrame := preload("res://sim/input_frame.gd")

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


## One INTERACT press through the real step (sl-0112).
func _press(world: RefCounted) -> void:
	var f: RefCounted = InputFrame.new()
	f.interact_pressed = true
	world.step([f])


## One recorded BAG OP through the real step (sl-0116).
func _bag_op(world: RefCounted, code: int) -> void:
	var f: RefCounted = InputFrame.new()
	f.bag_op = code
	world.step([f])


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
	check(
		JSON.stringify(a.loot_bags) == JSON.stringify(b.loot_bags),
		"same-seed loot bags identical (sl-0129)"
	)

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

	# 6. Pickup rules (sl-0112 DELIBERATE HANDS): gold is walk-over
	# auto; items require the INTERACT press — one drop per press,
	# nothing auto-equips; upgrades-only still governs weapon/armor.
	var u: RefCounted = _world_with(_drop_def(), 9)
	var up: RefCounted = u.players[0]
	u.spawn_drop(up.pos, SimWorld.DROP_GOLD, 25)
	u.spawn_drop(up.pos, SimWorld.DROP_WEAPON, 0, 1)
	u.spawn_drop(up.pos, SimWorld.DROP_WEAPON, 1, 4)
	u.spawn_drop(up.pos, SimWorld.DROP_ARMOR, 2)
	u.step([InputFrame.new()])
	check(up.gold == 25, "gold picks up walk-over (stays auto)")
	check(
		up.weapon_tiers[1] == 1 and up.armor_tier == 0 and u.drops.size() == 3,
		"NEGATIVE: nothing auto-equips without the press"
	)
	_press(u)
	_press(u)
	_press(u)
	check(up.weapon_tiers[1] == 4, "pressed pickup equips the upgrade")
	check(up.armor_tier == 2, "pressed pickup equips the armor")
	check(up.weapon_tiers[0] == 1 and u.drops.size() == 1, "equal-tier weapon refuses (stays)")

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
	# sl-0129: the roll lands BAGGED at the corpse — verify the branch
	# there, then stage a GROUND ring for the loose-drop flow (world
	# spawns + drop-from-bag still ground items).
	check(rw.loot_bags.size() == 1 and rw.drops.is_empty(), "ring def rolls into ONE corpse bag")
	var lb_items: PackedInt32Array = rw.loot_bags[0].items
	check(
		lb_items.size() == 3 and lb_items[0] == SimWorld.DROP_RING,
		"the bagged roll is exactly one RING"
	)
	var ritems: Array = rw.stat_frame.items
	var rit: Dictionary = ritems[lb_items[1]]
	check(String(rit.slot) == "ring" and int(rit.tier) == 1, "ring branch picks a T1 ring item")
	rw.loot_bags.clear()
	rw.spawn_drop(Vector2(20.0, 12.0), SimWorld.DROP_RING, lb_items[1])
	var rd: Dictionary = rw.drops[0]
	rp.pos = rd.pos
	rw.step([InputFrame.new()])
	check(rp.ring_index == -1 and rw.drops.size() == 1, "NEGATIVE: rings never walk-over equip")
	var first_ring := int(rd.a)
	# sl-0116 THE BAG ERA (deliberate re-baseline of the sl-0112
	# hands): the press BAGS the ring — nothing auto-equips anywhere
	# on the class lane; equip is a DECISION (a recorded bag op).
	_press(rw)
	check(
		rp.ring_index == -1 and rw.drops.is_empty() and BagStep.bag_count(rp) == 1,
		"pressed pickup bags the ring (nothing auto-equips — the bag era)"
	)
	check(int(BagStep.bag_item(rp, 0).kind) == SimWorld.DROP_RING, "bagged item is the ring")
	_bag_op(rw, BagStep.OP_EQUIP_BASE)
	check(
		rp.ring_index == first_ring and BagStep.bag_count(rp) == 0, "equip op wears the bagged ring"
	)
	check(rp.move_speed != base_speed or rp.max_hp != base_hp, "ring trade wires through recompute")
	# The REPLACED item returns TO THE BAG (sl-0116: the bag
	# supersedes the sl-0112 ground-swap language). Second ring comes
	# the sl-0129 way: looted from a corpse bag.
	_kill_n(rw, 1)
	rp.pos = rw.loot_bags[0].pos
	_bag_op(rw, BagStep.OP_LOOT_ALL)
	check(BagStep.bag_count(rp) == 1, "second ring looted to the bag while worn")
	var second_ring := int(BagStep.bag_item(rp, 0).a)
	_bag_op(rw, BagStep.OP_EQUIP_BASE)
	check(rp.ring_index == second_ring, "equip op swaps to the new ring")
	check(
		BagStep.bag_count(rp) == 1 and int(BagStep.bag_item(rp, 0).a) == first_ring,
		"the replaced ring returns to the bag"
	)
	# DE-EQUIP: worn ring -> bag; the slot empties.
	_bag_op(rw, BagStep.OP_DEEQUIP_RING)
	check(rp.ring_index == -1 and BagStep.bag_count(rp) == 2, "de-equip returns the worn ring")
	# DROP from the bag: the item lands at the feet as a real drop.
	_bag_op(rw, BagStep.OP_DROP_BASE)
	check(
		rw.drops.size() == 1 and BagStep.bag_count(rp) == 1,
		"drop op grounds the bag item at the feet"
	)
	check(rw.drops[0].pos == rp.pos, "dropped item lands at the feet")
	# BAG FULL: a stuffed bag refuses the pickup — the drop stays.
	while BagStep.bag_count(rp) < BagStep.BAG_CAP:
		BagStep.bag_add(rw, rp, SimWorld.DROP_ARMOR, 1, 0)
	_press(rw)
	check(rw.drops.size() == 1, "NEGATIVE: full bag refuses — the drop stays grounded")
	var saw_full := false
	for ev: Dictionary in rw.events:
		if int(ev.type) == SimEvents.Type.BAG_FULL:
			saw_full = true
	check(saw_full, "BAG_FULL event emitted")
	# DEATH KEEPS THE BAG (the gold slice stays the one death cost).
	var bag_before: int = BagStep.bag_count(rp)
	Damage.apply(rw, rp, 9999, 0)
	check(rp.dead and BagStep.bag_count(rp) == bag_before, "death keeps the bag")
	# Legacy lane: class -1 never bags and never equips rings.
	var lw: RefCounted = _world_with(ring_def, 93)
	lw.set_stat_frame(StatFrame.load_frame())
	_kill_n(lw, 1)
	lw.players[0].pos = lw.drops[0].pos
	_press(lw)
	check(
		(
			lw.players[0].ring_index == -1
			and lw.drops.size() == 1
			and BagStep.bag_count(lw.players[0]) == 0
		),
		"legacy player refuses rings AND never bags"
	)

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
			== "T1 Bow — 3 dmg @ 4.0/s"
		),
		"class weapon line exact (tier table + cadence, sl-0207 tables)"
	)
	check(
		ItemText.drop_line(u, {"kind": SimWorld.DROP_WEAPON, "a": 0, "b": 2}) == "T2 Longbolt",
		"lab weapon line falls back to name+tier"
	)

	# 11. S1 seam 3 — the Hide: an items-mapped UNIQUE equips unique
	# armor (mask bit + override index through recompute); the grammar
	# line publishes its numbers like everything else.
	var hw2: RefCounted = _world_with(ring_def, 97)
	hw2.set_stat_frame(StatFrame.load_frame())
	(
		hw2
		. set_uniques(
			[
				load("res://data/uniques/reliquary_coil.tres"),
				load("res://data/uniques/old_tusks_hide.tres"),
			]
		)
	)
	var hp2: RefCounted = hw2.players[0]
	hp2.class_id = 0
	StatFrame.recompute(hw2, hp2)
	hw2.spawn_drop(hp2.pos, SimWorld.DROP_UNIQUE, 1)
	_press(hw2)
	var hitems: Array = hw2.stat_frame.items
	check(hp2.unique_mask == 2, "hide pickup sets mask bit 1 (collection truth at pickup)")
	check(
		hp2.armor_item_index == -1 and BagStep.bag_count(hp2) == 1,
		"the hide BAGS on pickup (sl-0116: equip is a decision)"
	)
	_bag_op(hw2, BagStep.OP_EQUIP_BASE)
	check(
		hp2.armor_item_index >= 0 and String(hitems[hp2.armor_item_index].id) == "u-old-tusks-hide",
		"equip op wears the unique armor row"
	)
	check(hp2.armor == 12, "worn hide armors 12 through recompute")
	# De-equip returns the unique to the bag by def uid; re-equip works.
	_bag_op(hw2, BagStep.OP_DEEQUIP_ARMOR)
	check(hp2.armor_item_index == -1 and BagStep.bag_count(hp2) == 1, "hide de-equips into the bag")
	_bag_op(hw2, BagStep.OP_EQUIP_BASE)
	check(hp2.armor == 12, "hide re-equips from the bag")
	check(
		(
			ItemText.drop_line(hw2, {"kind": SimWorld.DROP_UNIQUE, "a": 1, "b": 0})
			== "UNIQUE: Old Tusk's Hide — +12 def, +38 hp / −6 spd"
		),
		"hide line exact"
	)

	# 12. sl-0129 LOOT BAGS: a kill's non-gold roll lands in ONE ground
	# bag at the corpse (same rng_loot sequence — only the landing
	# moved); gold stays its own walk-over drop; looting rides the
	# recorded ops; LOOT_PICKED emits per looted item (COLLECT quests
	# keep counting); nothing is ever destroyed silently.
	var bw: RefCounted = _world_with(ring_def, 101)
	bw.set_stat_frame(StatFrame.load_frame())
	var bp: RefCounted = bw.players[0]
	bp.class_id = 2
	StatFrame.recompute(bw, bp)
	_kill_n(bw, 1)
	check(
		bw.loot_bags.size() == 1 and bw.drops.is_empty(),
		"kill loot lands in ONE ground bag (no loose items)"
	)
	var lb0: Dictionary = bw.loot_bags[0]
	check((lb0.items as PackedInt32Array).size() == 3, "the bag holds the one rolled item")
	bp.pos = lb0.pos
	bw.step([InputFrame.new()])
	check(
		bw.loot_bags.size() == 1 and BagStep.bag_count(bp) == 0,
		"NEGATIVE: walk-over never auto-loots the bag"
	)
	_bag_op(bw, BagStep.OP_LOOT_ALL)
	var picked := 0
	for ev: Dictionary in bw.events:
		if int(ev.type) == SimEvents.Type.LOOT_PICKED:
			picked += 1
	check(picked == 1, "LOOT_PICKED per looted item (COLLECT quests count)")
	check(
		BagStep.bag_count(bp) == 1 and bw.loot_bags.is_empty(),
		"loot-all empties + despawns the ground bag"
	)
	_kill_n(bw, 2)
	check(bw.loot_bags.size() == 2, "two kills = two bags")
	bp.pos = bw.loot_bags[0].pos
	_bag_op(bw, BagStep.OP_LOOT_ROW_BASE)
	check(
		BagStep.bag_count(bp) == 2 and bw.loot_bags.size() == 1,
		"row-loot takes one + despawns the emptied bag"
	)
	while BagStep.bag_count(bp) < BagStep.BAG_CAP:
		BagStep.bag_add(bw, bp, SimWorld.DROP_ARMOR, 1, 0)
	bp.pos = bw.loot_bags[0].pos
	_bag_op(bw, BagStep.OP_LOOT_ALL)
	check(bw.loot_bags.size() == 1, "a full player bag leaves leftovers in the ground bag")
	bw.loot_bags[0].expires_at_tick = bw.tick
	bw.step([InputFrame.new()])
	check(bw.loot_bags.is_empty(), "expired ground bag sweeps")
	var gw2: RefCounted = _world_with(_drop_def(), 103)
	_kill_n(gw2, 1)
	check(
		not gw2.drops.is_empty() and int(gw2.drops[0].kind) == SimWorld.DROP_GOLD,
		"gold stays its own walk-over drop (never bagged)"
	)
	var bh0: int = bw.state_hash()
	bw.spawn_loot_bag(Vector2(20.0, 12.0), PackedInt32Array([2, 1, 0]))
	check(bw.state_hash() != bh0, "loot bags are hashed state (SERIAL 24)")

	# 13. sl-0130 THE BANK: two-way with the bag AT THE BANK CELL only;
	# capacities refuse loudly both ways; death never touches the bank.
	var kw: RefCounted = _world_with(ring_def, 107)
	kw.set_stat_frame(StatFrame.load_frame())
	var kp: RefCounted = kw.players[0]
	kp.class_id = 2
	StatFrame.recompute(kw, kp)
	kw.bank_cell = Vector2(21.0, 12.0)
	kp.pos = kw.bank_cell
	BagStep.bag_add(kw, kp, SimWorld.DROP_ARMOR, 2, 0)
	_bag_op(kw, BagStep.OP_DEPOSIT_BASE)
	check(BagStep.bank_count(kp) == 1 and BagStep.bag_count(kp) == 0, "deposit moves bag -> bank")
	_bag_op(kw, BagStep.OP_WITHDRAW_BASE)
	check(BagStep.bank_count(kp) == 0 and BagStep.bag_count(kp) == 1, "withdraw moves bank -> bag")
	kp.pos = Vector2(25.0, 12.0)
	_bag_op(kw, BagStep.OP_DEPOSIT_BASE)
	check(
		BagStep.bank_count(kp) == 0 and BagStep.bag_count(kp) == 1,
		"NEGATIVE: deposit refuses beyond the bank radius"
	)
	kp.pos = kw.bank_cell
	for i in BagStep.BANK_CAP:
		kp.bank.append_array(PackedInt32Array([2, 1, 0]))
	_bag_op(kw, BagStep.OP_DEPOSIT_BASE)
	var saw_bank_full := false
	for ev: Dictionary in kw.events:
		if int(ev.type) == SimEvents.Type.BANK_FULL:
			saw_bank_full = true
	check(
		saw_bank_full and BagStep.bag_count(kp) == 1,
		"NEGATIVE: full bank refuses (BANK_FULL, the item stays bagged)"
	)
	while BagStep.bag_count(kp) < BagStep.BAG_CAP:
		BagStep.bag_add(kw, kp, SimWorld.DROP_ARMOR, 1, 0)
	_bag_op(kw, BagStep.OP_WITHDRAW_BASE)
	check(
		BagStep.bank_count(kp) == BagStep.BANK_CAP,
		"NEGATIVE: withdraw into a full bag refuses (the item stays banked)"
	)
	var bank_before: int = BagStep.bank_count(kp)
	Damage.apply(kw, kp, 9999, 0)
	check(kp.dead and BagStep.bank_count(kp) == bank_before, "death never touches the bank")
	var kh0: int = kw.state_hash()
	kp.bank.append_array(PackedInt32Array([5, 0, 0]))
	check(kw.state_hash() != kh0, "the bank is hashed state (SERIAL 25)")
	var nw: RefCounted = _world_with(ring_def, 109)
	nw.set_stat_frame(StatFrame.load_frame())
	nw.players[0].class_id = 2
	BagStep.bag_add(nw, nw.players[0], SimWorld.DROP_ARMOR, 2, 0)
	_bag_op(nw, BagStep.OP_DEPOSIT_BASE)
	check(
		BagStep.bank_count(nw.players[0]) == 0,
		"NEGATIVE: a world without a bank cell keeps bank ops inert"
	)

	# 14. sl-0131 VENDORS v1: sell anything at value*fraction, buy from
	# the static catalog at value*multiplier — gold integer-exact
	# through the one serialized field; nothing half-happens.
	var vw2: RefCounted = _world_with(ring_def, 113)
	vw2.set_stat_frame(StatFrame.load_frame())
	var vp2: RefCounted = vw2.players[0]
	vp2.class_id = 2
	StatFrame.recompute(vw2, vp2)
	vw2.vendor_cells = PackedVector2Array([Vector2(21.0, 12.0)])
	vw2.vendor_stock = [PackedInt32Array([2, 1, 0, 1, 0, 2])]
	vp2.pos = Vector2(21.0, 12.0)
	vp2.gold = 100
	# SELL: a T2 armor (value 16) at 50% = +8 gold, item gone.
	BagStep.bag_add(vw2, vp2, SimWorld.DROP_ARMOR, 2, 0)
	_bag_op(vw2, BagStep.OP_SELL_BASE)
	check(vp2.gold == 108 and BagStep.bag_count(vp2) == 0, "sell pays value*fraction exact")
	# BUY: stock row 0 = T1 armor (value 10) at 200% = 20 gold.
	_bag_op(vw2, BagStep.OP_BUY_BASE)
	check(
		vp2.gold == 88 and BagStep.bag_count(vp2) == 1,
		"buy charges value*multiplier exact + bags the item"
	)
	check(int(BagStep.bag_item(vp2, 0).kind) == SimWorld.DROP_ARMOR, "bought item is the stock row")
	# POOR refuses: row 1 = T2 weapon (value 16) at 200% = 32 gold.
	vp2.gold = 10
	_bag_op(vw2, BagStep.OP_BUY_BASE + 1)
	check(
		vp2.gold == 10 and BagStep.bag_count(vp2) == 1, "NEGATIVE: too poor refuses — nothing moves"
	)
	# FULL BAG refuses with the gold UNCHANGED.
	vp2.gold = 100
	while BagStep.bag_count(vp2) < BagStep.BAG_CAP:
		BagStep.bag_add(vw2, vp2, SimWorld.DROP_ARMOR, 1, 0)
	_bag_op(vw2, BagStep.OP_BUY_BASE)
	check(
		vp2.gold == 100 and BagStep.bag_count(vp2) == BagStep.BAG_CAP,
		"NEGATIVE: full bag refuses the buy — gold never moves"
	)
	# RADIUS: away from the vendor both ops refuse.
	vp2.pos = Vector2(26.0, 12.0)
	var gold_far: int = vp2.gold
	_bag_op(vw2, BagStep.OP_SELL_BASE)
	check(
		vp2.gold == gold_far and BagStep.bag_count(vp2) == BagStep.BAG_CAP,
		"NEGATIVE: sell refuses beyond the vendor radius"
	)
	# Ring pricing keys the items[] tier (T1 ring value 12 -> sell 6).
	check(
		BagStep.sell_price(vw2, SimWorld.DROP_RING, haste_idx, 0) == 6,
		"ring sell price keys the items tier table"
	)
	# Vendor-less worlds keep the ops inert.
	var vn: RefCounted = _world_with(ring_def, 115)
	vn.set_stat_frame(StatFrame.load_frame())
	vn.players[0].class_id = 2
	vn.players[0].gold = 50
	BagStep.bag_add(vn, vn.players[0], SimWorld.DROP_ARMOR, 2, 0)
	_bag_op(vn, BagStep.OP_SELL_BASE)
	check(
		vn.players[0].gold == 50 and BagStep.bag_count(vn.players[0]) == 1,
		"NEGATIVE: a world without vendors keeps trade ops inert"
	)

	if fails.is_empty():
		print("loop_test: PASS (drops/streams/curve/damage/armor/pickup/rings/text/hash)")
		quit(0)
	else:
		for m: String in fails:
			printerr("loop_test FAIL: " + m)
		quit(1)
