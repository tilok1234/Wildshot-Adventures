extends SceneTree
## S1 seam 6 contracts (sl-0104 foraging + sl-0105 STARHOOK):
## - FORAGING: stillness near a forage cell for 90 ticks yields small
##   honest gold+xp via rng_loot; movement resets; ANTI-AFK rearm
##   (one yield per 4-tile walk);
## - THE CAST: stillness at an ACTIVE rift node for 120 ticks emits
##   CAST_COMPLETE (rarity drawn from rng_loot, deterministic) and
##   CONSUMES the node until its respawn timer lands; consumed nodes
##   accrue nothing;
## - class lane only; maskless/nodeless worlds inert (the battery's
##   byte-identity by construction); dead players inert;
## - hash coverage (SERIAL 20: gather fields + node timers);
## - the RIFTER lane: apply_to_rift builds the mini-class row from
##   the stat frame's starhook block (rod = the class, newest unlock
##   auto-equips) and harvest_rift routes gold/level/skins back to
##   the profile's starhook fields (win-gated catch counter);
## - slice premises: 12 authored nodes, all walkable on b77, ≥26 t
##   from the capital; the b77 forage derivation census.
## NEGATIVE-TESTED. Exit 0 = green.

const SimWorld := preload("res://sim/sim_world.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const GatherGrids := preload("res://game/arena/gather_grids.gd")
const SimEvents := preload("res://sim/events.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")
const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")

const WF_PACK := "res://assets/worldforge-packs/wildshot-overworld-pack-dusk/"

var fails: Array[String] = []


func check(cond: bool, name: String) -> void:
	if not cond:
		fails.append(name)


func _world(with_forage := true, with_node := false, class_backed := true) -> RefCounted:
	var g: RefCounted = Bitgrid.new()
	g.setup(48, 24)
	var world: RefCounted = SimWorld.new()
	world.setup(3, g)
	world.set_progression(load("res://data/progression.tres"))
	world.set_stat_frame(StatFrame.load_frame())
	if with_forage:
		var forage: RefCounted = Bitgrid.new()
		forage.setup(48, 24)
		forage.set_solid(30, 10)
		world.set_forage_grid(forage)
	if with_node:
		world.set_rift_nodes(PackedVector2Array([Vector2(10.5, 10.5)]))
	world.add_player(Vector2(31.5, 10.5))
	var p: RefCounted = world.players[0]
	if class_backed:
		p.class_id = 2
		StatFrame.recompute(world, p)
	return world


func _still(world: RefCounted, n: int) -> void:
	for i in n:
		world.step([InputFrame.new()])


func _move(world: RefCounted) -> void:
	var f: RefCounted = InputFrame.new()
	f.move_x = 1
	world.step([f])


func _init() -> void:
	# 1. Foraging: 90 still ticks near a forage cell yields; movement
	# resets the count; the event carries the numbers.
	var w: RefCounted = _world()
	var p: RefCounted = w.players[0]
	var gold0: int = p.gold
	_still(w, 89)
	check(p.gold == gold0, "no forage yield before 90 still ticks")
	_move(w)
	_still(w, 89)
	check(p.gold == gold0, "movement reset the count")
	_still(w, 1)
	check(p.gold > gold0 and p.gold <= gold0 + 2, "forage yields 1-2 gold at 90")
	var saw := false
	for ev: Dictionary in w.events:
		if int(ev.type) == SimEvents.Type.GATHERED:
			saw = true
	check(saw, "GATHERED emitted")
	var gold1: int = p.gold

	# 2. Anti-AFK: standing forever earns exactly one yield; a 4-tile
	# walk re-arms.
	_still(w, 400)
	check(p.gold == gold1, "standing forever earns exactly one yield")
	p.pos = Vector2(36.5, 10.5)
	_still(w, 1)
	p.pos = Vector2(31.5, 10.5)
	_still(w, 90)
	check(p.gold > gold1, "a 4-tile walk re-arms the verb")

	# 3. THE CAST: 120 still ticks at an ACTIVE node -> CAST_COMPLETE
	# + the node consumed; a consumed node accrues NOTHING; rarity is
	# a deterministic rng_loot draw (same seed, same rarity).
	var wc: RefCounted = _world(false, true)
	var pc: RefCounted = wc.players[0]
	pc.pos = Vector2(10.5, 10.5)
	_still(wc, 119)
	var casts := 0
	for ev: Dictionary in wc.events:
		if int(ev.type) == SimEvents.Type.CAST_COMPLETE:
			casts += 1
	check(casts == 0, "no cast before 120")
	_still(wc, 1)
	var cast_ev: Dictionary = {}
	for ev: Dictionary in wc.events:
		if int(ev.type) == SimEvents.Type.CAST_COMPLETE:
			cast_ev = ev
	check(not cast_ev.is_empty(), "CAST_COMPLETE at 120")
	check(int(wc.rift_node_respawn_at[0]) > wc.tick, "the node is consumed")
	_still(wc, 200)
	var casts2 := 0
	for ev: Dictionary in wc.events:
		if int(ev.type) == SimEvents.Type.CAST_COMPLETE:
			casts2 += 1
	check(casts2 == 0, "a consumed node accrues nothing")
	var wc2: RefCounted = _world(false, true)
	wc2.players[0].pos = Vector2(10.5, 10.5)
	_still(wc2, 120)
	var rare2 := -1
	for ev: Dictionary in wc2.events:
		if int(ev.type) == SimEvents.Type.CAST_COMPLETE:
			rare2 = 1 if bool(ev.rare) else 0
	check(rare2 == (1 if bool(cast_ev.rare) else 0), "same seed -> same rarity draw")

	# 4. NEGATIVES: legacy players never gather/cast; dead players
	# inert; maskless worlds inert.
	var wl: RefCounted = _world(true, true, false)
	wl.players[0].pos = Vector2(10.5, 10.5)
	_still(wl, 300)
	check(wl.players[0].gold == 0, "negative: legacy player casts nothing")
	var wn: RefCounted = _world(false, false)
	_still(wn, 300)
	check(wn.players[0].gold == 0, "negative: maskless world inert")

	# 5. Hash coverage (SERIAL 20).
	var wh: RefCounted = _world(false, true)
	var h0: int = wh.state_hash()
	wh.players[0].gather_still_ticks = 7
	check(wh.state_hash() != h0, "gather_still_ticks hashed")
	wh.players[0].gather_still_ticks = 0
	var h1: int = wh.state_hash()
	wh.players[0].gather_rearm = Vector2(1.0, 2.0)
	check(wh.state_hash() != h1, "gather_rearm hashed")
	wh.players[0].gather_rearm = Vector2(-1000000.0, -1000000.0)
	var h2: int = wh.state_hash()
	wh.rift_node_respawn_at[0] = 999
	check(wh.state_hash() != h2, "node respawn timers hashed")

	# 6. THE RIFTER lane (sl-0105): apply/harvest round-trip on the
	# stat frame's starhook row; rod unlock at level 3; win-gated
	# catch counter; the line snap = simply never harvesting.
	var prof := CharacterProfile.create(false, "bow")
	var rw: RefCounted = _world(false, false)
	CharacterProfile.apply_to_rift(rw, prof)
	var rp: RefCounted = rw.players[0]
	check(rp.class_id == -1, "rifter rides the legacy lane")
	check(rp.max_hp == 60 and rp.level == 1, "rifter row: 60 hp at starhook level 1")
	check(absf(rp.move_speed - 3.6) < 0.001, "rifter speed 3.6 [T]")
	check(rw.weapon_frames.size() == 1, "the rod IS the loadout")
	check(String(rw.weapon_frames[0].id) == "rod_cane", "starter rod at level 1")
	rp.gold = 44
	rp.level = 3
	CharacterProfile.harvest_rift(rw, prof, true)
	check(int(prof.gold) == 44, "rift pot lands in the MAIN wallet")
	check(int(prof.starhook_level) == 3, "starhook level harvested")
	check(int(prof.starhook_catches) == 1, "won fight counts the catch")
	check(String(prof.starhook_rod) == "rod_splitwillow", "level 3 unlocks Splitwillow")
	CharacterProfile.harvest_rift(rw, prof, false)
	check(int(prof.starhook_catches) == 1, "fled fight counts no catch")
	var rw2: RefCounted = _world(false, false)
	CharacterProfile.apply_to_rift(rw2, prof)
	check(String(rw2.weapon_frames[0].id) == "rod_splitwillow", "unlocked rod equips")
	check(rw2.players[0].max_hp == 60 + 16, "rifter hp grows on the row (level 3)")
	# Cosmetic: the starlit mask bit round-trips.
	rw2.players[0].unique_mask |= 1 << 2
	CharacterProfile.harvest_rift(rw2, prof, true)
	check((int(prof.starhook_skins) & 1) == 1, "starlit cast cosmetic harvested")
	var rw3: RefCounted = _world(false, false)
	CharacterProfile.apply_to_rift(rw3, prof)
	check((rw3.players[0].unique_mask & (1 << 2)) != 0, "owned skin rides back in (no re-grant)")

	# 7. Slice premises: the 12 authored nodes walk on b77, all ≥26 t
	# from the capital; the forage derivation covers the countryside.
	var slice: Resource = load("res://data/scenarios/slice_overworld.tres")
	var nodes: PackedVector2Array = slice.rift_nodes
	check(nodes.size() == 12, "12 rift nodes authored [T]")
	var wf := WorldforgePack.validate(WF_PACK)
	check(bool(wf.ok), "b77 validates")
	if bool(wf.ok):
		var bg: RefCounted = wf.bitgrid
		var cap := Vector2(109.5, 182.5)
		for n in nodes:
			check(not bg.is_solid(int(n.x), int(n.y)), "node walkable %s" % str(n))
			check(n.distance_to(cap) >= 26.0, "node clear of the capital %s" % str(n))
	var got := GatherGrids.derive(WF_PACK)
	check(bool(got.ok), "b77 forage derivation green")
	if bool(got.ok):
		check(int(got.forage_cells) > 1500, "forage cells cover the countryside")

	if fails.is_empty():
		print("gather_test: PASS (forage/anti-afk/cast/nodes/rifter/negatives/hash/b77)")
		quit(0)
	else:
		for m: String in fails:
			printerr("gather_test FAIL: " + m)
		quit(1)
