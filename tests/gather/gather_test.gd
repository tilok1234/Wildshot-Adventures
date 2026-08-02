extends SceneTree
## S1 seam 6 contracts, REBUILT by sl-0115 (STARHOOK v2 — prototype #2
## rules the shape; deliberate re-baseline with the seam):
## - FORAGING (unchanged): stillness 90 near a forage cell yields via
##   rng_loot; movement resets; ANTI-AFK rearm (one yield per 4-tile
##   walk);
## - THE CAST IS INSTANT: an interact press at an ACTIVE node casts
##   NOW (no stillness) — CAST_COMPLETE carries rarity (rng_loot,
##   deterministic) + the node's BIOME; authored nodes consume until
##   their timer; AMBIENT nodes are consumed away;
## - AMBIENT RIFTS: interval + chance from the starhook.ambient block
##   (rng_misc — its first consumer): walkable land, node-clearance,
##   live cap, deterministic per seed;
## - THE LINE (rift arenas; sl-0123 — THE DRAG IS CUT): arena combat
##   is NORMAL combat — a still fighter never moves and NO shot
##   drifts (pinned as this amendment's negatives); passive drain 1
##   hp per exactly 150 ticks through THE damage path (deep edge: 1
##   per 24); hit grace blocks bullets only (drains never pause); a
##   depleted pool SNAPS (life burned, refill, grace, LINE_SNAPPED)
##   and the third snap is the normal death; the win clears live
##   hostile shots (CLEARED); the kill banks gold directly + draws
##   the biome fish (CATCH_LANDED + rift_catches, per-species at
##   harvest);
## - RODS: four data rows, level-gated selects refused sim-side;
## - loader refusals: broken pull def / malformed biome table;
## - hash coverage (SERIAL 22: lives/acc/grace + ambient + catches);
## - the RIFTER lane round-trip + slice premises (12 authored nodes +
##   biomes + ambient flag on b77).
## NEGATIVE-TESTED. Exit 0 = green.

const SimWorld := preload("res://sim/sim_world.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const GatherGrids := preload("res://game/arena/gather_grids.gd")
const SimEvents := preload("res://sim/events.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")
const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const ScenarioDef := preload("res://data/scenario_def.gd")
const ActorState := preload("res://sim/actor_state.gd")
const RiftStep := preload("res://sim/systems/rift_step.gd")

const WF_PACK := "res://assets/worldforge-packs/wildshot-overworld-pack-dusk/"
const ROD_PATHS: Array[String] = [
	"res://data/weapons/rod_cane.tres",
	"res://data/weapons/rod_splitwillow.tres",
	"res://data/weapons/rod_heavyline.tres",
	"res://data/weapons/rod_twinreed.tres",
]

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
		world.set_rift_nodes(PackedVector2Array([Vector2(10.5, 10.5)]), PackedInt32Array([2]))
	world.add_player(Vector2(31.5, 10.5))
	var p: RefCounted = world.players[0]
	if class_backed:
		p.class_id = 2
		StatFrame.recompute(world, p)
	return world


## A rift-arena-like world: open grid, pull attached, four rods,
## legacy-lane player at 60 hp (the rifter shape without a profile).
func _rift_world(rare := false, biome := 0, seed_v := 3) -> RefCounted:
	var g: RefCounted = Bitgrid.new()
	g.setup(12, 13)
	for x in 12:
		g.set_solid(x, 0)
		g.set_solid(x, 12)
	for y in 13:
		g.set_solid(0, y)
		g.set_solid(11, y)
	var world: RefCounted = SimWorld.new()
	world.setup(seed_v, g)
	world.set_progression(load("res://data/progression.tres"))
	world.set_stat_frame(StatFrame.load_frame())
	var rods: Array = []
	for rp in ROD_PATHS:
		rods.append(load(rp))
	world.set_weapons(rods)
	world.add_player(Vector2(2.9, 6.5))
	var p: RefCounted = world.players[0]
	p.max_hp = 60
	p.hp = 60
	p.move_speed = 3.6
	world.set_rift_config(
		load("res://data/rift_line.tres"), biome, rare, PackedInt32Array([1, 3, 5, 8])
	)
	return world


func _still(world: RefCounted, n: int) -> void:
	for i in n:
		world.step([InputFrame.new()])


func _move(world: RefCounted) -> void:
	var f: RefCounted = InputFrame.new()
	f.move_x = 1
	world.step([f])


func _press(world: RefCounted) -> void:
	var f: RefCounted = InputFrame.new()
	f.interact_pressed = true
	world.step([f])


func _events_of(world: RefCounted, type: int) -> Array:
	var out: Array = []
	for ev: Dictionary in world.events:
		if int(ev.type) == type:
			out.append(ev)
	return out


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
	check(not _events_of(w, SimEvents.Type.GATHERED).is_empty(), "GATHERED emitted")
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

	# 3. THE CAST IS INSTANT (sl-0115): the interact press at an
	# ACTIVE node casts NOW; stillness never casts; the event carries
	# the node's BIOME; consumption + rarity determinism hold.
	var wc: RefCounted = _world(false, true)
	var pc: RefCounted = wc.players[0]
	pc.pos = Vector2(10.5, 10.5)
	_still(wc, 200)
	check(_events_of(wc, SimEvents.Type.CAST_COMPLETE).is_empty(), "stillness never casts")
	_press(wc)
	var cast_evs: Array = _events_of(wc, SimEvents.Type.CAST_COMPLETE)
	check(cast_evs.size() == 1, "the press casts instantly")
	var cast_ev: Dictionary = cast_evs[0] if cast_evs.size() == 1 else {}
	check(int(cast_ev.get("biome", -1)) == 2, "the cast carries the node's authored biome")
	check(int(wc.rift_node_respawn_at[0]) > wc.tick, "the node is consumed")
	_press(wc)
	check(
		_events_of(wc, SimEvents.Type.CAST_COMPLETE).is_empty(), "a consumed node refuses the press"
	)
	var wc2: RefCounted = _world(false, true)
	wc2.players[0].pos = Vector2(10.5, 10.5)
	_still(wc2, 200)
	_press(wc2)
	var evs2: Array = _events_of(wc2, SimEvents.Type.CAST_COMPLETE)
	check(
		evs2.size() == 1 and bool(evs2[0].rare) == bool(cast_ev.get("rare", false)),
		"same seed -> same rarity draw"
	)

	# 4. AMBIENT RIFTS (sl-0115, rng_misc): interval + always-chance
	# spawns a walkable, clear node with a drawn biome; the live cap
	# holds; a cast REMOVES the ambient node; same seed = same spawn.
	var wa: RefCounted = _world(false, false)
	wa.rift_ambient = true
	var amb_cfg := {
		"interval_ticks": 60,
		"chance_permille": 1000,
		"max_live": 2,
		"min_node_dist": 4.0,
		"ring_min": 5.0,
		"ring_max": 8.0,
	}
	wa.stat_frame.starhook.ambient = amb_cfg
	_still(wa, 61)
	check(wa.rift_ambient_pos.size() == 1, "ambient node spawned on the interval")
	_still(wa, 200)
	check(wa.rift_ambient_pos.size() == 2, "the live cap holds at max_live")
	var an0: Vector2 = wa.rift_ambient_pos[0]
	check(
		not wa.bitgrid.is_solid(int(floorf(an0.x)), int(floorf(an0.y))),
		"ambient node lands on walkable land"
	)
	var wa2: RefCounted = _world(false, false)
	wa2.rift_ambient = true
	wa2.stat_frame.starhook.ambient = amb_cfg
	_still(wa2, 61)
	check(
		wa2.rift_ambient_pos.size() == 1 and wa2.rift_ambient_pos[0] == an0,
		"same seed -> same ambient spawn"
	)
	wa2.players[0].pos = an0
	_press(wa2)
	var amb_cast: Array = _events_of(wa2, SimEvents.Type.CAST_COMPLETE)
	check(amb_cast.size() == 1, "ambient node casts on the press")
	check(int(amb_cast[0].node) <= -2, "ambient cast carries the ambient encoding")
	check(wa2.rift_ambient_pos.is_empty(), "a cast ambient node is consumed away")

	# 5. THE DRAG IS CUT (sl-0123): arena combat is NORMAL combat — a
	# still fighter does not move, and NO shot of either faction
	# drifts. These are the amendment's own negatives: any future
	# smuggled entity-drag fails here loudly.
	var wr: RefCounted = _rift_world()
	wr.add_enemy_standin(Vector2(9.5, 2.0))
	var pr: RefCounted = wr.players[0]
	var rpos: Vector2 = pr.pos
	wr.spawn_projectile(Vector2(6.0, 3.0), Vector2(0, 1), 0.2, 100, ActorState.FACTION_HOSTILE)
	wr.spawn_projectile(Vector2(6.0, 9.0), Vector2(0, 1), 0.2, 100, ActorState.FACTION_FRIENDLY)
	var hx0: float = wr.projectiles.pos_x[0]
	var fx0: float = wr.projectiles.pos_x[1]
	_still(wr, 60)
	check(pr.pos == rpos, "no drag: a still fighter does not move")
	check(absf(wr.projectiles.pos_x[0] - hx0) < 0.0001, "no drag: hostile shots fly true")
	check(absf(wr.projectiles.pos_x[1] - fx0) < 0.0001, "no drag: friendly bolts fly true")

	# 6. THE DRAINS: passive = exactly 1 hp per 150 ticks through THE
	# damage path; the deep edge accelerates to 1 per 24 (13/300 per
	# tick combined); drains never pause during hit grace.
	var wd: RefCounted = _rift_world()
	var pd: RefCounted = wd.players[0]
	pd.pos = Vector2(2.0, 6.5)
	var hp0: int = pd.hp
	_still(wd, 149)
	check(pd.hp == hp0, "no passive chunk before tick 150")
	_still(wd, 1)
	check(pd.hp == hp0 - 1, "passive drain: exactly 1 hp at tick 150")
	var wdd: RefCounted = _rift_world()
	var pdd: RefCounted = wdd.players[0]
	var deep_x := RiftStep.deep_edge_x(wdd)
	pdd.pos = Vector2(deep_x + 0.4, 6.5)
	var dhp0: int = pdd.hp
	_still(wdd, 24)
	check(pdd.hp <= dhp0 - 1, "deep-edge strain drains fast (1 per ~24)")
	var wg: RefCounted = _rift_world()
	var pg: RefCounted = wg.players[0]
	pg.line_iframe_until = 1000
	pg.line_drain_acc = 596
	_still(wg, 1)
	check(pg.hp == 59, "the drains never pause during grace")

	# 8. HIT GRACE + THE SNAP + THE THIRD SNAP: bullets blocked during
	# grace; a depleted pool burns a life (refill + grace + event),
	# the third snap is the normal death (dead-in-place here).
	var ws: RefCounted = _rift_world()
	ws.add_enemy_standin(Vector2(9.5, 2.0))
	var ps: RefCounted = ws.players[0]
	ps.pos = Vector2(6.0, 6.5)
	ws.spawn_projectile(Vector2(6.0, 6.5), Vector2(0, 0), 0.2, 40, ActorState.FACTION_HOSTILE, 10)
	ws.step([InputFrame.new()])
	check(ps.hp == 50, "the first bullet lands (10 off the pool)")
	check(ps.line_iframe_until > ws.tick, "hit grace armed")
	ps.pos = Vector2(6.0, 6.5)
	ws.spawn_projectile(Vector2(6.0, 6.5), Vector2(0, 0), 0.2, 40, ActorState.FACTION_HOSTILE, 10)
	ws.step([InputFrame.new()])
	check(ps.hp == 50, "grace blocks the second bullet")
	ps.hp = 5
	ps.line_iframe_until = -1
	ps.pos = Vector2(6.0, 6.5)
	ws.spawn_projectile(Vector2(6.0, 6.5), Vector2(0, 0), 0.2, 40, ActorState.FACTION_HOSTILE, 10)
	ws.step([InputFrame.new()])
	check(ps.line_lives == 2, "the snap burns one life")
	check(ps.hp == ps.max_hp and not ps.dead, "the line re-spools full")
	check(not _events_of(ws, SimEvents.Type.LINE_SNAPPED).is_empty(), "LINE_SNAPPED emitted")
	check(ps.line_iframe_until >= ws.tick + 80, "snap grace armed")
	ps.line_lives = 1
	ps.hp = 5
	ps.line_iframe_until = -1
	ps.pos = Vector2(6.0, 6.5)
	ws.spawn_projectile(Vector2(6.0, 6.5), Vector2(0, 0), 0.2, 40, ActorState.FACTION_HOSTILE, 10)
	ws.step([InputFrame.new()])
	check(ps.dead, "the third snap is the dive lost")

	# 9. POST-WIN CLEAR: no live catch -> hostile shots vanish
	# (CLEARED); friendly shots stay.
	var ww: RefCounted = _rift_world()
	ww.spawn_projectile(Vector2(6.0, 3.0), Vector2(0, 1), 0.2, 100, ActorState.FACTION_HOSTILE)
	ww.spawn_projectile(Vector2(6.0, 9.0), Vector2(0, 1), 0.2, 100, ActorState.FACTION_FRIENDLY)
	ww.step([InputFrame.new()])
	var cleared := false
	for ev: Dictionary in ww.events:
		if (
			int(ev.type) == SimEvents.Type.PROJECTILE_DESPAWNED
			and int(ev.get("reason", -1)) == SimEvents.DespawnReason.CLEARED
		):
			cleared = true
	check(cleared, "hostile shots clear when no catch lives")
	check(ww.projectiles.active[1] == 1, "friendly shots survive the clear")

	# 10. THE KILL BANKS (sl-0115): gold straight to the pot (no
	# ground drop), the biome fish drawn + recorded; the rare rarity
	# always lands the biome's rare species.
	var wk: RefCounted = _rift_world(false, 1)
	wk.set_enemy_defs([load("res://data/enemies/rift_catch_void.tres")])
	var fish_e: RefCounted = wk.add_enemy(0, Vector2(8.0, 6.5))
	fish_e.hp = 1
	wk.players[0].pos = Vector2(2.0, 6.5)
	wk.spawn_projectile(Vector2(8.0, 6.5), Vector2(0, 0), 0.3, 20, ActorState.FACTION_FRIENDLY, 5)
	wk.step([InputFrame.new()])
	var landed: Array = _events_of(wk, SimEvents.Type.CATCH_LANDED)
	check(landed.size() == 1, "CATCH_LANDED on the kill")
	check(wk.rift_catches.size() == 1, "the catch is recorded on the world")
	check(wk.players[0].gold >= 30 and wk.players[0].gold <= 60, "gold banks directly")
	check(wk.drops.is_empty(), "no ground drops in the rift")
	check(int(landed[0].biome) == 1, "the catch carries the arena's biome")
	var wk2: RefCounted = _rift_world(true, 2)
	wk2.set_enemy_defs([load("res://data/enemies/rift_catch_comet_rare.tres")])
	var fish_e2: RefCounted = wk2.add_enemy(0, Vector2(8.0, 6.5))
	fish_e2.hp = 1
	wk2.spawn_projectile(Vector2(8.0, 6.5), Vector2(0, 0), 0.3, 20, ActorState.FACTION_FRIENDLY, 5)
	wk2.step([InputFrame.new()])
	check(
		wk2.rift_catches.size() == 1 and int(wk2.rift_catches[0].fish) == 3,
		"the rare rarity lands the biome's rare species"
	)

	# 11. RODS: the four data rows; level gates refuse sim-side.
	var wrod: RefCounted = _rift_world()
	var prod: RefCounted = wrod.players[0]
	check(wrod.weapon_frames.size() == 4, "four rods in the rift loadout")
	var sel := InputFrame.new()
	sel.weapon_select = 2
	wrod.step([sel])
	check(prod.equipped_weapon == 0, "a locked rod select is refused (level 1)")
	prod.level = 3
	wrod.step([sel])
	check(prod.equipped_weapon == 1, "level 3 unlocks Splitwillow")
	var sel4 := InputFrame.new()
	sel4.weapon_select = 4
	wrod.step([sel4])
	check(prod.equipped_weapon == 1, "Twinreed stays locked below 8")
	prod.level = 8
	wrod.step([sel4])
	check(prod.equipped_weapon == 3, "level 8 unlocks Twinreed")

	# 12. LOADER REFUSALS: a rift scenario with a broken pull path or
	# a malformed biome table builds NO pull config (loud upstream).
	var bad := ScenarioDef.new()
	bad.id = &"bad_rift"
	bad.starhook_rift = true
	bad.rift_line = "res://data/does_not_exist.tres"
	var bg2: RefCounted = Bitgrid.new()
	bg2.setup(12, 13)
	var bw: RefCounted = ScenarioLoader.build_world(bad, 1, bg2)
	check(bw.rift_line == null, "negative: broken line-def path refused")
	check(
		not ScenarioLoader._biomes_valid([{"fish": [], "rare": {}}]),
		"negative: malformed biome table refused"
	)
	check(
		ScenarioLoader._biomes_valid(StatFrame.load_frame().get("starhook", {}).get("biomes", [])),
		"the shipped biome table validates"
	)

	# 13. NEGATIVES: legacy players never cast; dead players inert;
	# nodeless worlds inert.
	var wl: RefCounted = _world(true, true, false)
	wl.players[0].pos = Vector2(10.5, 10.5)
	_press(wl)
	check(_events_of(wl, SimEvents.Type.CAST_COMPLETE).is_empty(), "negative: legacy never casts")
	var wdead: RefCounted = _world(false, true)
	wdead.players[0].pos = Vector2(10.5, 10.5)
	wdead.players[0].dead = true
	_press(wdead)
	check(_events_of(wdead, SimEvents.Type.CAST_COMPLETE).is_empty(), "negative: dead never casts")
	var wn: RefCounted = _world(false, false)
	_still(wn, 300)
	check(wn.players[0].gold == 0, "negative: maskless world inert")

	# 14. Hash coverage (SERIAL 22).
	var wh: RefCounted = _rift_world()
	var h0: int = wh.state_hash()
	wh.players[0].line_lives = 1
	check(wh.state_hash() != h0, "line lives hashed")
	wh.players[0].line_lives = 3
	var h1: int = wh.state_hash()
	wh.players[0].line_drain_acc = 77
	check(wh.state_hash() != h1, "drain accumulator hashed")
	wh.players[0].line_drain_acc = 0
	var h2: int = wh.state_hash()
	wh.players[0].line_iframe_until = 5000
	check(wh.state_hash() != h2, "hit grace hashed")
	wh.players[0].line_iframe_until = -1000000
	var h3: int = wh.state_hash()
	wh.rift_ambient_pos.append(Vector2(5.0, 5.0))
	wh.rift_ambient_biome.append(1)
	check(wh.state_hash() != h3, "ambient nodes hashed")
	wh.rift_ambient_pos.clear()
	wh.rift_ambient_biome.clear()
	var h4: int = wh.state_hash()
	wh.rift_catches.append({"biome": 0, "fish": 1, "rare": false})
	check(wh.state_hash() != h4, "landed catches hashed")

	# 15. THE RIFTER lane (v2): the profile's rod choice equips among
	# the loader's four-rod ladder (locked falls back to highest
	# unlocked); harvest persists the EQUIPPED rod + banks fish
	# PER-SPECIES; the catch counter stays win-gated.
	var prof := CharacterProfile.create(false, "bow")
	var rw: RefCounted = _rift_world()
	CharacterProfile.apply_to_rift(rw, prof)
	var rp: RefCounted = rw.players[0]
	check(rp.class_id == -1, "rifter rides the legacy lane")
	check(rp.max_hp == 60 and rp.level == 1, "rifter row: 60 hp at starhook level 1")
	check(absf(rp.move_speed - 3.6) < 0.001, "rifter speed 3.6 [T]")
	check(rp.equipped_weapon == 0, "starter rod at level 1")
	rp.gold = 44
	rp.level = 3
	rp.equipped_weapon = 1
	rw.rift_catches.append({"biome": 0, "fish": 0, "rare": false})
	rw.rift_catches.append({"biome": 0, "fish": 0, "rare": false})
	rw.rift_catches.append({"biome": 1, "fish": 3, "rare": true})
	CharacterProfile.harvest_rift(rw, prof, true)
	check(int(prof.gold) == 44, "rift pot lands in the MAIN wallet")
	check(int(prof.starhook_level) == 3, "starhook level harvested")
	check(int(prof.starhook_catches) == 1, "won fight counts the catch")
	check(String(prof.starhook_rod) == "rod_splitwillow", "the EQUIPPED rod persists")
	var bank: Dictionary = prof.starhook_fish
	check(int(bank.get("emberwisp_koi", 0)) == 2, "fish bank per-species (commons)")
	check(int(bank.get("event_horizon_maw", 0)) == 1, "fish bank per-species (rare)")
	CharacterProfile.harvest_rift(rw, prof, false)
	check(int(prof.starhook_catches) == 1, "fled fight counts no catch")
	prof.starhook_rod = "rod_twinreed"
	var rw2: RefCounted = _rift_world()
	CharacterProfile.apply_to_rift(rw2, prof)
	check(rw2.players[0].equipped_weapon == 1, "a locked saved rod falls back to unlocked")
	check(rw2.players[0].max_hp == 60 + 16, "rifter hp grows on the row (level 3)")
	rw2.players[0].unique_mask |= 1 << 2
	CharacterProfile.harvest_rift(rw2, prof, true)
	check((int(prof.starhook_skins) & 1) == 1, "starlit cast cosmetic harvested")
	var rw3: RefCounted = _rift_world()
	CharacterProfile.apply_to_rift(rw3, prof)
	check((rw3.players[0].unique_mask & (1 << 2)) != 0, "owned skin rides back in (no re-grant)")

	# 16. Slice premises: the 12 authored nodes walk on b77, carry 12
	# biomes, ambient is ON; the six rift scenarios carry the pull +
	# distinct biome x rarity.
	var slice: Resource = load("res://data/scenarios/slice_overworld.tres")
	var nodes: PackedVector2Array = slice.rift_nodes
	check(nodes.size() == 12, "12 rift nodes authored [T]")
	check(slice.rift_node_biomes.size() == 12, "12 authored node biomes")
	check(bool(slice.rift_ambient), "ambient rifts ride the slice")
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
	var combos := {}
	for sc_name in [
		"rift_nebula_common",
		"rift_nebula_rare",
		"rift_void_common",
		"rift_void_rare",
		"rift_comet_common",
		"rift_comet_rare",
	]:
		var sc: Resource = load("res://data/scenarios/%s.tres" % sc_name)
		check(sc != null and bool(sc.starhook_rift), "%s is a rift scenario" % sc_name)
		check(not String(sc.rift_line).is_empty(), "%s carries the line rules" % sc_name)
		combos["%d_%s" % [int(sc.rift_biome), str(sc.rift_rare)]] = true
	check(combos.size() == 6, "six distinct biome x rarity arenas")

	if fails.is_empty():
		print(
			"gather_test: PASS (forage/instant-cast/ambient/no-drag/drains/grace/snap/clear/",
			"fish/rods/refusals/negatives/hash/rifter/slice)"
		)
		quit(0)
	else:
		for m: String in fails:
			printerr("gather_test FAIL: " + m)
		quit(1)
