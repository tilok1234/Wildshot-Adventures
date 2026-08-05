extends SceneTree
## S1 seam 6 contracts, REBUILT by sl-0115 (STARHOOK v2) and AGAIN by
## sl-0198 (THE FORAGING BUILD — the sl-0168 spec; SERIAL 27,
## deliberate re-baseline with the seam):
## - THE FORAGE VERB (sl-0198; stillness + anti-AFK RETIRED): F at a
##   LIVE forage node starts the gather bar (bar_ticks [T]); the bar
##   interrupts on movement / getting hit / reach loss; completion
##   drops ONE loot bag from the node (sl-0129 machinery) carrying
##   FORAGE kin (species from the node's prop family, count [T] via
##   rng_loot) and consumes the node away; standing still forever
##   yields NOTHING (the retirement negative);
## - THE WALLET: bag pickup of FORAGE kin lands in the per-species
##   wallet (forage_mats — the fish doctrine): ZERO bag capacity, a
##   full bag still takes kin; profile round-trip by species NAME
##   with ghost-key preservation;
## - AMBIENT FORAGE NODES: the spawner's SECOND rng_misc consumer
##   (own interval/chance/cap [T]; rolled after the rift roll): nodes
##   land ON candidate pool cells with the cell's own species, the
##   world-wide cap holds, consumed cells respawn ELSEWHERE over
##   time, same seed = same spawn;
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
## - RODS: level-gated selects refused sim-side (the four-rod legacy
##   world stays byte-frozen; the 12-rod catalog world adds OWNERSHIP
##   gating — sl-0177/0178);
## - loader refusals: broken pull def / malformed biome table;
## - hash coverage (SERIAL 22: lives/acc/grace + ambient + catches;
##   SERIAL 26: fish wallet + ownership masks + equips);
## - the RIFTER lane round-trip + slice premises (12 authored nodes +
##   biomes + ambient flag on b77);
## - THE GEAR SEAM (sl-0177/0178, SERIAL 26): the tackle catalog shape
##   (16 priced shelf rows over 12 species); the tackle vendor's
##   recorded ops (buy decrements fish + sets the owned bit +
##   auto-equips an empty slot; equip swaps among owned; refusals:
##   poor/owned/away/legacy — fish never move on a refusal); rift
##   gear stats (chest raises the line pool, helm mitigates BULLETS
##   through THE formula while the 1-hp drain chunks ride the
##   formula's floor untouched — the clock never mitigates); rod
##   ownership on the full ladder (purchasable rods refuse unowned
##   selects; the level-grant spine stays free; apply_to_rift skips
##   unowned rods); the RARE-catch gear drop (deterministic
##   chance+pool draw on rng_loot, dup-protected, harvests BY ID);
##   fish spend round-trip + unknown-species preservation (the
##   fish-first word).
## NEGATIVE-TESTED. Exit 0 = green.

const SimWorld := preload("res://sim/sim_world.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")
const TackleCatalog := preload("res://sim/tackle_catalog.gd")
const GatherGrids := preload("res://game/arena/gather_grids.gd")
const SimEvents := preload("res://sim/events.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")
const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const ScenarioDef := preload("res://data/scenario_def.gd")
const ActorState := preload("res://sim/actor_state.gd")
const RiftStep := preload("res://sim/systems/rift_step.gd")
const GatherStep := preload("res://sim/systems/gather_step.gd")
const DropKinds := preload("res://sim/drop_kinds.gd")
const Damage := preload("res://sim/systems/damage.gd")

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


## with_forage: install a 4-cell candidate pool (one cell per species,
## spread apart) + the ambient opt-in, and surface ONE LIVE bush node
## at (30.5, 10.5) — one tile from the player spawn (in REACH).
func _world(with_forage := true, with_node := false, class_backed := true) -> RefCounted:
	var g: RefCounted = Bitgrid.new()
	g.setup(48, 24)
	var world: RefCounted = SimWorld.new()
	world.setup(3, g)
	world.set_progression(load("res://data/progression.tres"))
	world.set_stat_frame(StatFrame.load_frame())
	if with_forage:
		_install_pool(world)
		world.forage_nodes_pos.append(Vector2(30.5, 10.5))
		world.forage_nodes_species.append(2)
	if with_node:
		world.set_rift_nodes(PackedVector2Array([Vector2(10.5, 10.5)]), PackedInt32Array([2]))
	world.add_player(Vector2(31.5, 10.5))
	var p: RefCounted = world.players[0]
	if class_backed:
		p.class_id = 2
		StatFrame.recompute(world, p)
	return world


func _install_pool(world: RefCounted, ambient := false) -> void:
	var ids: Array[String] = ["stump", "fallen_log", "bush", "mushrooms"]
	world.set_forage_pool(
		PackedVector2Array(
			[Vector2(30.5, 10.5), Vector2(5.5, 5.5), Vector2(40.5, 18.5), Vector2(12.5, 20.5)]
		),
		PackedInt32Array([2, 0, 1, 3]),
		ids
	)
	world.forage_ambient = ambient


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


## A 12-rod catalog rift world (the sl-0177 shape): the FULL ladder
## from the stat frame, unlock + purchasable flags exactly as the
## loader derives them.
func _rift_world12(seed_v := 3, rare := false) -> RefCounted:
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
	var unlocks := PackedInt32Array()
	var purch := PackedInt32Array()
	for rod: Dictionary in TackleCatalog.rods(world.stat_frame):
		rods.append(load("res://data/weapons/%s.tres" % String(rod.get("id", ""))))
		unlocks.append(int(rod.get("unlock_level", 99)))
		purch.append(1 if rod.has("price") else 0)
	world.set_weapons(rods)
	world.add_player(Vector2(2.9, 6.5))
	var p: RefCounted = world.players[0]
	p.max_hp = 60
	p.hp = 60
	p.move_speed = 3.6
	world.set_rift_config(load("res://data/rift_line.tres"), 0, rare, unlocks, purch)
	return world


## An overworld-like shop world: class player at the tackle cell with
## the shelf resolved exactly as the loader resolves it.
func _shop_world(at_station := true) -> RefCounted:
	var w: RefCounted = _world(false, false)
	w.tackle_cell = Vector2(31.5, 10.5) if at_station else Vector2(5.5, 5.5)
	for srow: Dictionary in TackleCatalog.shelf_rows(w.stat_frame):
		var rd := TackleCatalog.row_data(w.stat_frame, srow)
		var price_idx := TackleCatalog.resolve_price(w.stat_frame, rd.get("price", {}))
		(
			w
			. tackle_shelf
			. append(
				{
					"row_kind": int(srow.row_kind),
					"index": int(srow.index),
					"tier": int(rd.get("tier", 0)),
					"price_idx": price_idx,
				}
			)
		)
	var p: RefCounted = w.players[0]
	p.fish = PackedInt32Array()
	p.fish.resize(TackleCatalog.species_ids(w.stat_frame).size())
	return w


## sl-0221: a settlements world — the _world base (no forage node, no
## rift node) + capital/waystation tables (capital cell = the player
## spawn, the slice identity shape).
func _home_world(class_backed := true) -> RefCounted:
	var w: RefCounted = _world(false, false, class_backed)
	w.settlement_ids = PackedStringArray(["capital", "waystation"])
	w.settlement_cells = PackedVector2Array([Vector2(31.5, 10.5), Vector2(5.5, 5.5)])
	w.waypost_cells = PackedVector2Array([Vector2(33.5, 10.5), Vector2(7.5, 5.5)])
	w.respawn_cell = Vector2(31.5, 10.5)
	return w


func _op(world: RefCounted, code: int) -> void:
	var f: RefCounted = InputFrame.new()
	f.bag_op = code
	world.step([f])


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
	var bar: int = int(StatFrame.load_frame().get("forage", {}).get("bar_ticks", 45))

	# 1. THE FORAGE VERB (sl-0198): the F-press at a live node starts
	# the bar; stillness alone NEVER yields (the retirement negative);
	# completion drops ONE loot bag AT the node with the node's own
	# species, consumes the node away, and emits GATHERED.
	var w: RefCounted = _world()
	var p: RefCounted = w.players[0]
	_still(w, 400)
	check(w.loot_bags.is_empty() and p.gold == 0, "stillness never yields (the verb retired)")
	check(p.forage_ticks == 0, "no bar without the press")
	_press(w)
	check(p.forage_target == Vector2(30.5, 10.5), "the press targets the node")
	_still(w, bar - 2)
	check(p.forage_ticks == bar - 1, "the bar advances while still")
	check(w.loot_bags.is_empty(), "no bag before the bar completes")
	_still(w, 1)
	check(w.loot_bags.size() == 1, "completion drops ONE loot bag")
	if w.loot_bags.size() == 1:
		var lb: Dictionary = w.loot_bags[0]
		check(Vector2(lb.pos) == Vector2(30.5, 10.5), "the bag drops FROM the node")
		var items: PackedInt32Array = lb.items
		check(items.size() == 3 and items[0] == DropKinds.FORAGE, "the bag carries kin")
		check(items[1] == 2, "the kin carry the node's own species (bush)")
		check(items[2] >= 1 and items[2] <= 2, "yield count in the [T] band")
	check(w.forage_nodes_pos.is_empty(), "the node is consumed away")
	check(
		p.forage_target == GatherStep.NONE and p.forage_ticks == 0, "the bar resets on completion"
	)
	var gevs: Array = _events_of(w, SimEvents.Type.GATHERED)
	check(gevs.size() == 1 and int(gevs[0].species) == 2, "GATHERED carries the species")
	_press(w)
	_still(w, bar + 10)
	check(w.loot_bags.size() == 1, "a consumed node cannot be gathered again")

	# 2. THE INTERRUPTS (the designer's own rider): movement resets the
	# bar whole; a landed hit resets it; leaving reach (teleport class)
	# resets it. A fresh press restarts from zero.
	var wi: RefCounted = _world()
	var pi2: RefCounted = wi.players[0]
	_press(wi)
	_still(wi, 10)
	_move(wi)
	check(
		pi2.forage_target == GatherStep.NONE and pi2.forage_ticks == 0,
		"movement interrupts the bar"
	)
	_still(wi, bar + 5)
	check(wi.loot_bags.is_empty(), "an interrupted bar never completes")
	_press(wi)
	_still(wi, 10)
	check(pi2.forage_ticks == 11, "the re-press restarts from zero")
	wi.add_enemy_standin(Vector2(9.5, 2.0))
	wi.spawn_projectile(Vector2(31.5, 10.5), Vector2(0, 0), 0.5, 20, ActorState.FACTION_HOSTILE, 5)
	wi.step([InputFrame.new()])
	check(
		pi2.forage_target == GatherStep.NONE and pi2.forage_ticks == 0,
		"getting hit interrupts the bar (same tick)"
	)
	var wt2: RefCounted = _world()
	var pt2: RefCounted = wt2.players[0]
	_press(wt2)
	_still(wt2, 10)
	pt2.pos = Vector2(40.5, 10.5)
	_still(wt2, 1)
	check(
		pt2.forage_target == GatherStep.NONE and pt2.forage_ticks == 0,
		"leaving reach cancels the bar"
	)

	# 2b. THE WALLET (the fish doctrine): B loot-all lands kin in
	# forage_mats — ZERO bag capacity; a FULL bag still takes them;
	# LOOT_PICKED carries the FORAGE kind.
	var ww2: RefCounted = _world()
	var pw2: RefCounted = ww2.players[0]
	for fill in 20:
		BagStep.bag_add(ww2, pw2, DropKinds.GOLD, 1, 0)
	check(BagStep.bag_count(pw2) == 20, "the bag is FULL")
	_press(ww2)
	_still(ww2, bar)
	check(ww2.loot_bags.size() == 1, "the gather bag waits")
	pw2.pos = Vector2(30.5, 10.5)
	_op(ww2, BagStep.OP_LOOT_ALL)
	var picked: Array = _events_of(ww2, SimEvents.Type.LOOT_PICKED)
	check(
		picked.size() == 1 and int(picked[0].kind) == DropKinds.FORAGE,
		"loot-all picks the kin (LOOT_PICKED kind FORAGE)"
	)
	check(ww2.loot_bags.is_empty(), "the emptied bag despawns")
	check(BagStep.bag_count(pw2) == 20, "kin consume ZERO bag capacity (full bag took them)")
	check(
		pw2.forage_mats.size() >= 3 and pw2.forage_mats[2] >= 1,
		"the wallet holds the species count"
	)

	# 2c. DETERMINISM: same seed -> same yield (species fixed by the
	# node; count via rng_loot's fixed order).
	var wdet1: RefCounted = _world()
	_press(wdet1)
	_still(wdet1, bar)
	var wdet2: RefCounted = _world()
	_press(wdet2)
	_still(wdet2, bar)
	check(
		(
			wdet1.loot_bags.size() == 1
			and wdet2.loot_bags.size() == 1
			and (
				(wdet1.loot_bags[0].items as PackedInt32Array)
				== (wdet2.loot_bags[0].items as PackedInt32Array)
			)
		),
		"same seed -> the same yield"
	)

	# 2d. THE AMBIENT FORAGE SPAWNER (rng_misc's second consumer):
	# interval + chance surface nodes ON pool cells with the cell's
	# own species; the cap holds; same seed = same spawn; a consumed
	# cell can resurface later (the spawner tops the world up).
	var wa3: RefCounted = _world(false, false)
	_install_pool(wa3, true)
	wa3.stat_frame = wa3.stat_frame.duplicate(true)
	(
		wa3
		. stat_frame
		. merge(
			{
				"forage":
				{
					"bar_ticks": 45,
					"interval_ticks": 60,
					"chance_permille": 1000,
					"max_live": 2,
					"yield_min": 1,
					"yield_max": 2,
				}
			},
			true
		)
	)
	_still(wa3, 61)
	check(wa3.forage_nodes_pos.size() == 1, "a forage node spawned on the interval")
	if wa3.forage_nodes_pos.size() == 1:
		var spawned: Vector2 = wa3.forage_nodes_pos[0]
		var pool_i: int = wa3.forage_pool_cells.find(spawned)
		check(pool_i >= 0, "the node sits ON a candidate pool cell")
		check(
			pool_i >= 0 and wa3.forage_nodes_species[0] == wa3.forage_pool_species[pool_i],
			"the node carries the cell's own species"
		)
		var sevs: Array = _events_of(wa3, SimEvents.Type.FORAGE_NODE_SPAWNED)
		check(sevs.size() == 1, "FORAGE_NODE_SPAWNED emitted")
	_still(wa3, 300)
	check(wa3.forage_nodes_pos.size() == 2, "the world-wide live cap holds at max_live")
	var wa4: RefCounted = _world(false, false)
	_install_pool(wa4, true)
	wa4.stat_frame = wa3.stat_frame
	_still(wa4, 61)
	check(
		(
			wa4.forage_nodes_pos.size() == 1
			and wa3.forage_nodes_pos.size() >= 1
			and wa4.forage_nodes_pos[0] == wa3.forage_nodes_pos[0]
		),
		"same seed -> same forage spawn"
	)

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

	# 13. NEGATIVES: legacy players never cast NOR gather; dead players
	# inert; poolless worlds inert; a rift node WINS the press over a
	# forage node (deliberate tie order).
	var wl: RefCounted = _world(true, true, false)
	wl.players[0].pos = Vector2(10.5, 10.5)
	_press(wl)
	check(_events_of(wl, SimEvents.Type.CAST_COMPLETE).is_empty(), "negative: legacy never casts")
	wl.players[0].pos = Vector2(31.5, 10.5)
	_press(wl)
	_still(wl, 60)
	check(
		wl.players[0].forage_target == GatherStep.NONE and wl.loot_bags.is_empty(),
		"negative: legacy never gathers"
	)
	var wdead: RefCounted = _world(false, true)
	wdead.players[0].pos = Vector2(10.5, 10.5)
	wdead.players[0].dead = true
	_press(wdead)
	check(_events_of(wdead, SimEvents.Type.CAST_COMPLETE).is_empty(), "negative: dead never casts")
	var wn: RefCounted = _world(false, false)
	_press(wn)
	_still(wn, 300)
	check(
		wn.players[0].gold == 0 and wn.players[0].forage_target == GatherStep.NONE,
		"negative: poolless world inert"
	)
	var wprio: RefCounted = _world(true, true)
	wprio.forage_nodes_pos[0] = Vector2(10.5, 11.5)
	wprio.players[0].pos = Vector2(10.5, 10.9)
	_press(wprio)
	check(
		_events_of(wprio, SimEvents.Type.CAST_COMPLETE).size() == 1,
		"the rift node wins the shared press"
	)
	check(
		wprio.players[0].forage_target == GatherStep.NONE,
		"the winning cast never also starts a gather"
	)

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
	# sl-0198 hash coverage (SERIAL 27): forage state hashes.
	wh.rift_catches.clear()
	var h5: int = wh.state_hash()
	wh.forage_nodes_pos.append(Vector2(6.5, 6.5))
	wh.forage_nodes_species.append(1)
	check(wh.state_hash() != h5, "live forage nodes hashed")
	wh.forage_nodes_pos.clear()
	wh.forage_nodes_species.clear()
	var h6: int = wh.state_hash()
	wh.players[0].forage_target = Vector2(6.5, 6.5)
	check(wh.state_hash() != h6, "the gather target hashes")
	wh.players[0].forage_target = GatherStep.NONE
	var h7: int = wh.state_hash()
	wh.players[0].forage_ticks = 12
	check(wh.state_hash() != h7, "the bar progress hashes")
	wh.players[0].forage_ticks = 0
	var h8: int = wh.state_hash()
	wh.players[0].forage_mats = PackedInt32Array([0, 3])
	check(wh.state_hash() != h8, "the forage wallet hashes")

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

	# 15b. THE FORAGE PROFILE ROUND-TRIP (the fish-first word's
	# sibling): the wallet loads by species NAME, harvests by name,
	# and PRESERVES ghost keys; a poolless world's harvest never
	# touches the dict.
	var prof15: Dictionary = CharacterProfile.create(false, "bow")
	prof15.forage_mats = {"bush": 4, "ghost_moss": 9}
	var wfp: RefCounted = _world()
	CharacterProfile.apply_to_world(wfp, prof15)
	var pfp: RefCounted = wfp.players[0]
	check(pfp.forage_mats.size() == 4 and pfp.forage_mats[2] == 4, "profile kin load by name")
	_press(wfp)
	_still(wfp, bar)
	pfp.pos = Vector2(30.5, 10.5)
	_op(wfp, BagStep.OP_LOOT_ALL)
	check(pfp.forage_mats[2] >= 5, "the gather lands on the loaded wallet")
	CharacterProfile.harvest(wfp, prof15)
	var fbank: Dictionary = prof15.forage_mats
	check(int(fbank.get("bush", 0)) == pfp.forage_mats[2], "the harvest persists by name")
	check(int(fbank.get("ghost_moss", 0)) == 9, "unknown species keys preserved")
	var wnp15: RefCounted = _world(false, false)
	CharacterProfile.apply_to_world(wnp15, prof15)
	CharacterProfile.harvest(wnp15, prof15)
	check(
		(
			int(prof15.forage_mats.get("bush", 0)) >= 5
			and int(prof15.forage_mats.get("ghost_moss", 0)) == 9
		),
		"a poolless harvest preserves the whole dict"
	)

	# 16. Slice premises: the 12 authored nodes walk on b77, carry 12
	# biomes, ambient rifts AND ambient forage are ON; the pool derives
	# with the four-species vocabulary; the six rift scenarios carry
	# the pull + distinct biome x rarity; the forage block holds its
	# ruled shapes ([T] numbers live in data, the shapes are law).
	var slice: Resource = load("res://data/scenarios/slice_overworld.tres")
	var nodes: PackedVector2Array = slice.rift_nodes
	check(nodes.size() == 12, "12 rift nodes authored [T]")
	check(slice.rift_node_biomes.size() == 12, "12 authored node biomes")
	check(bool(slice.rift_ambient), "ambient rifts ride the slice")
	check(bool(slice.forage_ambient), "ambient forage rides the slice (sl-0198)")
	var wf := WorldforgePack.validate(WF_PACK)
	check(bool(wf.ok), "b77 validates")
	if bool(wf.ok):
		var bg: RefCounted = wf.bitgrid
		var cap := Vector2(109.5, 182.5)
		for n in nodes:
			check(not bg.is_solid(int(n.x), int(n.y)), "node walkable %s" % str(n))
			check(n.distance_to(cap) >= 26.0, "node clear of the capital %s" % str(n))
	var got := GatherGrids.derive(WF_PACK)
	check(bool(got.ok), "b77 forage pool derivation green")
	if bool(got.ok):
		check(int(got.forage_cells) > 1500, "the candidate pool covers the countryside")
		check(
			(got.cells as PackedVector2Array).size() == (got.species as PackedInt32Array).size(),
			"pool cells and species ride parallel"
		)
		check(
			(
				(got.species_ids as Array).size() == 4
				and String((got.species_ids as Array)[0]) == "stump"
			),
			"the derived vocabulary is the four prop species"
		)
	var fcfg: Dictionary = StatFrame.load_frame().get("forage", {})
	check(not fcfg.is_empty(), "the forage block ships in the frame")
	var fbar := int(fcfg.get("bar_ticks", 0))
	check(fbar >= 30 and fbar <= 60, "bar_ticks in the routed 0.5-1 s band [T]")
	var fcap := int(fcfg.get("max_live", 0))
	check(fcap >= 12 and fcap <= 18, "max_live starts in the ruled 12-18 band [T]")
	check(
		(
			int(fcfg.get("yield_min", 0)) >= 1
			and int(fcfg.get("yield_max", 0)) >= int(fcfg.get("yield_min", 0))
		),
		"yields sane [T]"
	)
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

	# 17. THE TACKLE CATALOG SHAPE (sl-0177/0178): 12 species over the
	# three biomes; 16 priced shelf rows (8 rods + 8 chest/helm) in the
	# rods-then-items order; the pure lookups hold.
	var frame17 := StatFrame.load_frame()
	var sp_ids := TackleCatalog.species_ids(frame17)
	check(sp_ids.size() == 12, "12 species in the index space")
	check(sp_ids[0] == "emberwisp_koi" and sp_ids[3] == "novaback_leviathan", "biome-major order")
	var shelf17 := TackleCatalog.shelf_rows(frame17)
	check(shelf17.size() == 16, "16 priced shelf rows")
	var rods17 := 0
	for srow17: Dictionary in shelf17:
		if int(srow17.row_kind) == TackleCatalog.ROW_ROD:
			rods17 += 1
	check(rods17 == 8, "8 priced rods (the four originals stay the free spine)")
	check(TackleCatalog.rods(frame17).size() == 12, "12 rods in the catalog")
	check(TackleCatalog.items(frame17).size() == 8, "8 chest/helm rows")
	check(TackleCatalog.tier_level(frame17, 2) == 3, "tier 2 gates at starhook 3")
	check(
		TackleCatalog.resolve_price(frame17, {"ghost_species": 1}).is_empty(),
		"negative: unknown species price resolves empty"
	)

	# 18. THE SHOP: recorded buy ops decrement fish + set the owned bit
	# + auto-equip an empty slot; equip swaps among owned; refusals
	# leave the fish untouched (poor/owned/away/legacy/unowned-equip).
	var wsh: RefCounted = _shop_world()
	var psh: RefCounted = wsh.players[0]
	psh.fish[0] = 5
	psh.fish[1] = 2
	psh.fish[6] = 1
	psh.fish[8] = 5
	psh.fish[4] = 1
	_op(wsh, BagStep.OP_TACKLE_BUY_BASE + 0)
	check((psh.rods_owned_mask & (1 << 4)) != 0, "buy sets the rod's owned bit")
	check(psh.fish[0] == 3, "buy decrements the fish wallet")
	check(not _events_of(wsh, SimEvents.Type.TACKLE_BOUGHT).is_empty(), "TACKLE_BOUGHT emitted")
	_op(wsh, BagStep.OP_TACKLE_BUY_BASE + 0)
	check(psh.fish[0] == 3, "an owned row refuses the re-buy (fish untouched)")
	_op(wsh, BagStep.OP_TACKLE_BUY_BASE + 8)
	check((psh.tackle_owned_mask & 1) != 0, "chest bought")
	check(psh.tackle_chest == 0, "first chest auto-equips the empty slot")
	_op(wsh, BagStep.OP_TACKLE_BUY_BASE + 9)
	check(psh.tackle_helm == 1, "first helm auto-equips")
	check(psh.fish[6] == 0 and psh.fish[0] == 2, "helm price drew both species")
	_op(wsh, BagStep.OP_TACKLE_BUY_BASE + 10)
	check((psh.tackle_owned_mask & (1 << 2)) != 0, "second chest bought")
	check(psh.tackle_chest == 0, "an occupied slot never auto-swaps")
	_op(wsh, BagStep.OP_TACKLE_EQUIP_BASE + 2)
	check(psh.tackle_chest == 2, "the equip op wears the owned chest")
	check(not _events_of(wsh, SimEvents.Type.TACKLE_EQUIPPED).is_empty(), "TACKLE_EQUIPPED emitted")
	_op(wsh, BagStep.OP_TACKLE_EQUIP_BASE + 3)
	check(psh.tackle_helm == 1, "negative: an unowned equip refuses")
	_op(wsh, BagStep.OP_TACKLE_BUY_BASE + 1)
	check((psh.rods_owned_mask & (1 << 5)) != 0 and psh.fish[8] == 0, "second rod buys clean")
	_op(wsh, BagStep.OP_TACKLE_BUY_BASE + 4)
	check(
		(psh.rods_owned_mask & (1 << 8)) == 0 and psh.fish[9] == 0,
		"negative: poor buy refuses (fan_t3 needs 4 herring, has 0)"
	)
	var waway: RefCounted = _shop_world(false)
	var paway: RefCounted = waway.players[0]
	paway.fish[0] = 9
	_op(waway, BagStep.OP_TACKLE_BUY_BASE + 0)
	check(
		paway.rods_owned_mask == 0 and paway.fish[0] == 9, "negative: away from the station refuses"
	)
	var wleg: RefCounted = _shop_world()
	wleg.players[0].class_id = -1
	wleg.players[0].fish[0] = 9
	_op(wleg, BagStep.OP_TACKLE_BUY_BASE + 0)
	check(wleg.players[0].rods_owned_mask == 0, "negative: the legacy lane never trades")

	# 19. RIFT GEAR STATS: chest raises the line pool, helm mitigates
	# BULLETS through THE formula; the 1-hp drain chunks ride the
	# formula's floor untouched (the clock never mitigates). Rod
	# ownership gates selects on the full ladder; apply_to_rift skips
	# unowned purchasable rods.
	var prof19 := CharacterProfile.create(false, "bow")
	prof19.starhook_tackle = ["chest_t1", "helm_t1"]
	prof19.starhook_chest = "chest_t1"
	prof19.starhook_helm = "helm_t1"
	var wg19: RefCounted = _rift_world12()
	CharacterProfile.apply_to_rift(wg19, prof19)
	var pg19: RefCounted = wg19.players[0]
	check(pg19.max_hp == 72 and pg19.hp == 72, "chest_t1 raises the line pool 60 -> 72")
	check(pg19.armor == 4, "helm_t1 lands defense 4")
	wg19.add_enemy_standin(Vector2(9.5, 2.0))
	pg19.pos = Vector2(6.0, 6.5)
	wg19.spawn_projectile(Vector2(6.0, 6.5), Vector2(0, 0), 0.2, 40, ActorState.FACTION_HOSTILE, 10)
	wg19.step([InputFrame.new()])
	check(pg19.hp == 72 - 6, "a 10-dmg bullet lands taken(10,4) = 6")
	var wg19b: RefCounted = _rift_world12()
	CharacterProfile.apply_to_rift(wg19b, prof19)
	var pg19b: RefCounted = wg19b.players[0]
	pg19b.line_drain_acc = 596
	wg19b.step([InputFrame.new()])
	check(pg19b.hp == 71, "the drain chunk stays exactly 1 under a helm (the floor holds)")
	var wr12: RefCounted = _rift_world12()
	var pr12: RefCounted = wr12.players[0]
	check(wr12.weapon_frames.size() == 12, "the rift ladder carries the 12-rod catalog")
	var sel5 := InputFrame.new()
	sel5.weapon_select = 5
	wr12.step([sel5])
	check(pr12.equipped_weapon == 0, "negative: an unowned purchasable rod refuses the select")
	pr12.rods_owned_mask |= 1 << 4
	wr12.step([sel5])
	check(pr12.equipped_weapon == 4, "the owned rod selects (level 1, tier 1)")
	var sel2b := InputFrame.new()
	sel2b.weapon_select = 2
	wr12.step([sel2b])
	check(pr12.equipped_weapon == 4, "Splitwillow stays level-locked below 3 (the free spine)")
	pr12.level = 3
	wr12.step([sel2b])
	check(pr12.equipped_weapon == 1, "level 3 grants Splitwillow with no purchase (grandfather)")
	var prof19c := CharacterProfile.create(false, "bow")
	prof19c.starhook_rod = "rod_fan_t1"
	var wr12b: RefCounted = _rift_world12()
	CharacterProfile.apply_to_rift(wr12b, prof19c)
	check(wr12b.players[0].equipped_weapon == 0, "an unowned saved rod falls back to the spine")
	prof19c.starhook_rods = ["rod_fan_t1"]
	var wr12c: RefCounted = _rift_world12()
	CharacterProfile.apply_to_rift(wr12c, prof19c)
	check(wr12c.players[0].equipped_weapon == 4, "an owned saved rod equips on entry")

	# 20. THE RARE-CATCH DROP: chance + pool draw appended to the
	# kill's fixed rng_loot sequence — deterministic per seed,
	# dup-protected, direct-granted (no ground drops), harvested BY ID.
	var drop_seed := -1
	for sv in range(1, 11):
		var wt: RefCounted = _rift_world12(sv, true)
		wt.set_enemy_defs([load("res://data/enemies/rift_catch_rare.tres")])
		var et: RefCounted = wt.add_enemy(0, Vector2(8.0, 6.5))
		et.hp = 1
		wt.spawn_projectile(
			Vector2(8.0, 6.5), Vector2(0, 0), 0.3, 20, ActorState.FACTION_FRIENDLY, 5
		)
		wt.step([InputFrame.new()])
		if not _events_of(wt, SimEvents.Type.TACKLE_DROPPED).is_empty():
			drop_seed = sv
			break
	check(drop_seed > 0, "a rare-catch gear drop lands within seeds 1..10 (chance 50)")
	if drop_seed > 0:
		var wd1: RefCounted = _rift_world12(drop_seed, true)
		wd1.set_enemy_defs([load("res://data/enemies/rift_catch_rare.tres")])
		var ed1: RefCounted = wd1.add_enemy(0, Vector2(8.0, 6.5))
		ed1.hp = 1
		wd1.spawn_projectile(
			Vector2(8.0, 6.5), Vector2(0, 0), 0.3, 20, ActorState.FACTION_FRIENDLY, 5
		)
		wd1.step([InputFrame.new()])
		var dev1: Array = _events_of(wd1, SimEvents.Type.TACKLE_DROPPED)
		check(dev1.size() == 1, "the drop grants exactly one piece")
		var pd1: RefCounted = wd1.players[0]
		check(
			pd1.rods_owned_mask != 0 or pd1.tackle_owned_mask != 0,
			"the grant is a direct owned bit"
		)
		check(wd1.drops.is_empty() and wd1.loot_bags.is_empty(), "no ground drops in the rift")
		var rd20 := TackleCatalog.row_data(
			wd1.stat_frame, {"row_kind": int(dev1[0].row_kind), "index": int(dev1[0].index)}
		)
		check(int(rd20.get("tier", 9)) <= 2, "the drop honors the Green tier bounds [1,2]")
		var wd2: RefCounted = _rift_world12(drop_seed, true)
		wd2.set_enemy_defs([load("res://data/enemies/rift_catch_rare.tres")])
		var ed2: RefCounted = wd2.add_enemy(0, Vector2(8.0, 6.5))
		ed2.hp = 1
		wd2.spawn_projectile(
			Vector2(8.0, 6.5), Vector2(0, 0), 0.3, 20, ActorState.FACTION_FRIENDLY, 5
		)
		wd2.step([InputFrame.new()])
		check(
			(
				wd2.players[0].rods_owned_mask == pd1.rods_owned_mask
				and wd2.players[0].tackle_owned_mask == pd1.tackle_owned_mask
			),
			"same seed -> the same drop"
		)
		var wd3: RefCounted = _rift_world12(drop_seed, true)
		wd3.set_enemy_defs([load("res://data/enemies/rift_catch_rare.tres")])
		wd3.players[0].rods_owned_mask = (1 << 12) - 1
		wd3.players[0].tackle_owned_mask = (1 << 8) - 1
		var ed3: RefCounted = wd3.add_enemy(0, Vector2(8.0, 6.5))
		ed3.hp = 1
		wd3.spawn_projectile(
			Vector2(8.0, 6.5), Vector2(0, 0), 0.3, 20, ActorState.FACTION_FRIENDLY, 5
		)
		wd3.step([InputFrame.new()])
		check(
			_events_of(wd3, SimEvents.Type.TACKLE_DROPPED).is_empty(),
			"an all-owned pool drops nothing (dup-protected)"
		)
		var prof20 := CharacterProfile.create(false, "bow")
		CharacterProfile.harvest_rift(wd1, prof20, true)
		var harvested: Array = []
		harvested.append_array(prof20.starhook_rods)
		harvested.append_array(prof20.starhook_tackle)
		check(harvested.size() == 1, "the dropped piece harvests BY ID")

	# 21. FISH ROUND-TRIP + THE FISH-FIRST WORD: spends persist by id;
	# species the current table does not know stay in the profile
	# untouched (a future re-roster never eats the designer's fish).
	var prof21 := CharacterProfile.create(false, "bow")
	prof21.starhook_fish = {"emberwisp_koi": 5, "ghost_fish": 7}
	var wsh21: RefCounted = _shop_world()
	CharacterProfile.apply_to_world(wsh21, prof21)
	var psh21: RefCounted = wsh21.players[0]
	check(psh21.fish[0] == 5, "profile fish load by id")
	_op(wsh21, BagStep.OP_TACKLE_BUY_BASE + 0)
	check(psh21.fish[0] == 3, "the spend lands in-sim")
	CharacterProfile.harvest(wsh21, prof21)
	check(int(prof21.starhook_fish.get("emberwisp_koi", -1)) == 3, "the spend persists by id")
	check(int(prof21.starhook_fish.get("ghost_fish", -1)) == 7, "unknown species keys preserved")
	check(prof21.starhook_rods == ["rod_fan_t1"], "the purchase persists by id")

	# 22. LOADER + SLICE PREMISES (gear): the slice pins the tackle
	# cell; the shelf resolves 16 rows on the shipped frame; the cell
	# stays clear of every other station (the interact-sweep class).
	var slice22: Resource = load("res://data/scenarios/slice_overworld.tres")
	check(slice22.tackle_cell == Vector2(110.5, 178.5), "the slice pins the tackle cell")
	for st_cell: Vector2 in [
		Vector2(109.5, 182.5), Vector2(112.5, 182.5), Vector2(106.5, 182.5), Vector2(106.5, 180.5)
	]:
		check(
			slice22.tackle_cell.distance_to(st_cell) >= 3.0,
			"tackle cell clear of station %s" % str(st_cell)
		)

	# 24. THE BOSS POOL (sl-0180): the cast's fight draw — weighted,
	# per-biome, deterministic (same seed same fight), appended to the
	# cast's fixed rng_loot sequence; absent pools fall back to catch;
	# CAST_COMPLETE carries the fight id.
	var wp: RefCounted = _world(false, true)
	wp.players[0].pos = Vector2(10.5, 10.5)
	_press(wp)
	var pevs: Array = _events_of(wp, SimEvents.Type.CAST_COMPLETE)
	check(pevs.size() == 1 and pevs[0].has("fight"), "the cast carries a fight id")
	var wp2: RefCounted = _world(false, true)
	wp2.players[0].pos = Vector2(10.5, 10.5)
	_press(wp2)
	var pevs2: Array = _events_of(wp2, SimEvents.Type.CAST_COMPLETE)
	check(
		pevs2.size() == 1 and String(pevs2[0].fight) == String(pevs[0].fight),
		"same seed -> the same fight draw"
	)
	var wnp: RefCounted = _world(false, true)
	wnp.stat_frame = wnp.stat_frame.duplicate(true)
	(wnp.stat_frame.starhook as Dictionary).erase("fight_pool")
	wnp.players[0].pos = Vector2(10.5, 10.5)
	_press(wnp)
	var nevs: Array = _events_of(wnp, SimEvents.Type.CAST_COMPLETE)
	check(
		nevs.size() == 1 and String(nevs[0].fight) == "catch",
		"an absent pool falls back to the catch"
	)
	var pool_frame := StatFrame.load_frame()
	var pools24: Dictionary = pool_frame.get("starhook", {}).get("fight_pool", {})
	for bk: String in ["nebula", "void", "comet"]:
		for rk: String in ["common", "rare"]:
			for row_v: Variant in (pools24.get(bk, {}) as Dictionary).get(rk, []) as Array:
				var fid := String((row_v as Dictionary).get("fight", ""))
				if fid == "catch":
					continue
				var sc24: Resource = load("res://data/scenarios/rift_boss_%s.tres" % fid)
				check(
					sc24 != null and bool(sc24.starhook_rift),
					"pool fight '%s' resolves to a rift scenario" % fid
				)
				check(
					sc24 != null and (sc24.damage_schedule as Array).is_empty(),
					"pool scenario '%s' carries NO damage schedule (tester-safe)" % fid
				)

	# 25. PHASED-ONLY CATCH LANDING (sl-0180, the dungeon premise): a
	# PHASELESS rift kill banks its gold and stops — no CATCH_LANDED,
	# no fish, the dive never ends on a mob.
	var wm: RefCounted = _rift_world(false, 0)
	wm.set_enemy_defs([load("res://data/enemies/slime.tres")])
	var mob: RefCounted = wm.add_enemy(0, Vector2(8.0, 6.5))
	mob.hp = 1
	var mgold0: int = wm.players[0].gold
	wm.spawn_projectile(Vector2(8.0, 6.5), Vector2(0, 0), 0.3, 20, ActorState.FACTION_FRIENDLY, 5)
	wm.step([InputFrame.new()])
	check(
		_events_of(wm, SimEvents.Type.CATCH_LANDED).is_empty(),
		"a phaseless rift kill lands NO catch"
	)
	check(wm.players[0].gold > mgold0, "the mob's gold still banks (no ground drops)")
	check(wm.rift_catches.is_empty(), "no fish drawn for a mob")

	# 26. BOSS ROSTER + KIT PREMISES (sl-0180; AMENDED sl-0188;
	# AMENDED AGAIN sl-0200): the pool defs sit at roster 30-37 +
	# 40-46, phased. THE LAW AS AMENDED TWICE: rift bosses MAY MOVE
	# AND BEHAVE (sl-0188 — the standing-there statue is dead), and NO
	# rift kit phase ever CHASES (policy 0) EXCEPT the sl-0200
	# SANCTIONED PURSUER EXPERIMENT (the designer's word: "maybe 1
	# or 2 pursuiters" — the band's honest landing is ONE: the
	# second candidate, shadow_hound, failed the fairness floor
	# across seven proof iterations and was REPORTED, not shipped) —
	# for the pursuer, fairness is STRUCTURAL: every phase's pursuit
	# speed sits STRICTLY below the 3.6 player floor (pressure,
	# never cornering; the corner-audit proof walks the worst
	# pocket). The hooked-fish law survives whole.
	var loader_scenario := ScenarioDef.new()
	loader_scenario.id = &"premise_probe"
	var g26: RefCounted = Bitgrid.new()
	g26.setup(12, 13)
	var wl26: RefCounted = ScenarioLoader.build_world(loader_scenario, 1, g26)
	check(
		wl26.enemy_defs.size() == 47,
		"roster carries 47 defs (30-37 + 40-46 = the boss pool, 38-39 = the dungeon mobs)"
	)
	var boss_ids26: Array[String] = [
		"twin_helix",
		"ring_nest",
		"sine_shoal",
		"boomerang_veil",
		"decel_wall",
		"zone_constellation",
		"cross_burst",
		"pulse_lattice",
	]
	for bi26 in boss_ids26.size():
		var bdef: Resource = wl26.enemy_defs[30 + bi26]
		check(
			String(bdef.id) == "rift_boss_" + boss_ids26[bi26],
			"roster %d is rift_boss_%s" % [30 + bi26, boss_ids26[bi26]]
		)
		check(bdef.phases != null, "boss %s is phased" % boss_ids26[bi26])
	# THE PURSUER SANCTION (sl-0200): EXACTLY this kit id may carry
	# policy 0 — and every phase of its must sit STRICTLY under the
	# 3.6 floor. Everyone else in the rift lane still never chases.
	# The sanction list is the amendment's whole text: a second
	# chaser is a red gate, not a design option (shadow_hound tried
	# and failed the floor — the record lives in the sl-0200 close).
	var sanctioned_pursuers: Array[String] = [
		"rift_boss_tide_stalker",
	]
	var pursuers_found: Array[String] = []
	for di26 in range(24, 47):
		if di26 == 38 or di26 == 39:
			continue  # the dungeon mobs have their own block below
		var rdef: Resource = wl26.enemy_defs[di26]
		if rdef.phases == null:
			continue
		if String(rdef.id) in sanctioned_pursuers:
			pursuers_found.append(String(rdef.id))
			check(
				int(rdef.movement_policy) == 0,
				"%s base policy IS the sanctioned pursuit" % String(rdef.id)
			)
			check(
				float(rdef.move_speed) < 3.6,
				"%s base pursuit strictly under the 3.6 floor" % String(rdef.id)
			)
			for php: Resource in rdef.phases.phases:
				check(
					int(php.movement_policy) == 0,
					"%s phase %s carries the pursuit" % [String(rdef.id), String(php.id)]
				)
				check(
					float(php.move_speed) < 3.6,
					(
						"%s phase %s pursuit %.1f strictly under the 3.6 floor"
						% [String(rdef.id), String(php.id), float(php.move_speed)]
					)
				)
			continue
		check(int(rdef.movement_policy) != 0, "%s base policy never chases" % String(rdef.id))
		for ph26: Resource in rdef.phases.phases:
			check(
				int(ph26.movement_policy) != 0,
				"%s phase %s never chases (one-room law)" % [String(rdef.id), String(ph26.id)]
			)
	check(
		pursuers_found.size() == 1,
		"exactly the one sanctioned pursuer experiment exists (found %d)" % pursuers_found.size()
	)
	# sl-0188 FAMILY PINS [P at build]: the eight kits split
	# ROOM-PATTERN (ANCHOR 3 — the boss holds ground, the choreography
	# fills the room; the anchored decel_wall also cannot leave the
	# dungeon boss room, the sl-0186 walk finding) vs BEHAVIOURAL
	# (FLANKER 4 — orbit/reposition/dash-reads). Def AND every phase.
	var kit_families := {
		30: 4,  # twin_helix — behavioural
		31: 3,  # ring_nest — room-pattern
		32: 4,  # sine_shoal — behavioural
		33: 4,  # boomerang_veil — behavioural
		34: 3,  # decel_wall — room-pattern (the dungeon holder)
		35: 3,  # zone_constellation — room-pattern
		36: 4,  # cross_burst — behavioural
		37: 3,  # pulse_lattice — room-pattern
		40: 3,  # gap_carousel — room-pattern (sl-0200)
		41: 4,  # sickle_weaver — behavioural (sl-0200)
		42: 4,  # dart_skirmisher — behavioural (sl-0200)
		43: 3,  # decel_orchard — room-pattern (sl-0200)
		44: 4,  # halo_lasher — behavioural (sl-0200)
		45: 0,  # tide_stalker — THE SANCTIONED PURSUER (sl-0200)
		46: 3,  # pulse_cross — room-pattern (sl-0200)
	}
	for ki26: int in kit_families:
		var kdef: Resource = wl26.enemy_defs[ki26]
		var fam26: int = kit_families[ki26]
		check(
			int(kdef.movement_policy) == fam26,
			"%s base policy is its sl-0188 family (%d)" % [String(kdef.id), fam26]
		)
		for kph26: Resource in kdef.phases.phases:
			check(
				int(kph26.movement_policy) == fam26,
				"%s phase %s carries the family" % [String(kdef.id), String(kph26.id)]
			)

	# Wave 2: the dungeon mobs are PHASELESS (the gold-only kill
	# contract), never chasers, and wake close (aggro 8 [T] — the
	# distance-discipline law's partner).
	for mi26 in [38, 39]:
		var mdef: Resource = wl26.enemy_defs[mi26]
		check(mdef.phases == null, "%s is phaseless (mob contract)" % String(mdef.id))
		check(int(mdef.movement_policy) != 0, "%s never chases" % String(mdef.id))
		check(absf(float(mdef.aggro_range) - 8.0) < 0.001, "%s wakes at 8 [T]" % String(mdef.id))
	var dsc: Resource = load("res://data/scenarios/rift_dungeon_path.tres")
	check(
		dsc != null and bool(dsc.starhook_rift) and (dsc.damage_schedule as Array).is_empty(),
		"the dungeon scenario is a rift world with NO damage schedule (tester-safe)"
	)
	check(
		String(dsc.rift_line) == "res://data/rift_line_dungeon.tres",
		"the dungeon rides its own line def (the slow clock [T])"
	)
	var dline: Resource = load(String(dsc.rift_line))
	check(
		absf(float(dline.passive_drain_per_sec) - 0.1) < 0.0001 and int(dline.lives) == 3,
		"dungeon line: passive 0.1/s [T], three lives unchanged"
	)

	# 23. HASH COVERAGE (SERIAL 26): the gear state hashes.
	var wh26: RefCounted = _rift_world12()
	var ph26: RefCounted = wh26.players[0]
	var g0: int = wh26.state_hash()
	ph26.fish = PackedInt32Array([3])
	check(wh26.state_hash() != g0, "fish wallet hashed")
	ph26.fish = PackedInt32Array()
	var g1: int = wh26.state_hash()
	ph26.rods_owned_mask = 1 << 4
	check(wh26.state_hash() != g1, "rod ownership hashed")
	ph26.rods_owned_mask = 0
	var g2: int = wh26.state_hash()
	ph26.tackle_owned_mask = 3
	check(wh26.state_hash() != g2, "tackle ownership hashed")
	ph26.tackle_owned_mask = 0
	var g3: int = wh26.state_hash()
	ph26.tackle_chest = 0
	check(wh26.state_hash() != g3, "the worn chest hashes")

	# 27. THE HOME BIND + THE RECALL CAST (sl-0221, THE NIGHT SEAM;
	# SERIAL 28). Settlement/waypost tables are definitions; SET HOME
	# is a recorded op at a waypost; RECALL is a recorded op starting a
	# 2 s cast on the gather target+ticks pair (the RECALL sentinel —
	# zero new cast-state fields); moving or a hit cancels with the
	# cooldown UNSPENT; completion teleports home and arms the
	# cooldown [T 2700]. Settlement-less worlds refuse structurally.
	var hw: RefCounted = _home_world()
	var hp27: RefCounted = hw.players[0]
	check(hw.home_cell(hp27) == Vector2(31.5, 10.5), "default home = settlement 0 (the capital)")
	_op(hw, BagStep.OP_SET_HOME)
	check(int(hp27.home_town) == 0, "set-home away from any waypost refuses")
	hp27.pos = Vector2(7.5, 5.5)
	_op(hw, BagStep.OP_SET_HOME)
	check(int(hp27.home_town) == 1, "the waypost binds home to ITS settlement")
	check(_events_of(hw, SimEvents.Type.HOME_SET).size() == 1, "HOME_SET emitted on the change")
	_op(hw, BagStep.OP_SET_HOME)
	check(_events_of(hw, SimEvents.Type.HOME_SET).is_empty(), "re-binding the same home is silent")
	check(hw.home_cell(hp27) == Vector2(5.5, 5.5), "home_cell resolves the set home")
	hp27.pos = Vector2(31.5, 10.5)
	_op(hw, BagStep.OP_RECALL)
	check(hp27.forage_target == GatherStep.RECALL_TARGET, "the recall op starts the cast")
	check(_events_of(hw, SimEvents.Type.RECALL_STARTED).size() == 1, "RECALL_STARTED emitted")
	check(hp27.forage_ticks == 1, "the cast advances on the op tick (BagStep runs first)")
	_still(hw, GatherStep.RECALL_CAST_TICKS - 2)
	check(hp27.forage_ticks == GatherStep.RECALL_CAST_TICKS - 1, "one tick short of done")
	check(hp27.pos == Vector2(31.5, 10.5), "no teleport before completion")
	_still(hw, 1)
	check(hp27.pos == Vector2(5.5, 5.5), "completion teleports HOME")
	check(
		hp27.forage_target == GatherStep.NONE and hp27.forage_ticks == 0,
		"the cast pair resets on completion"
	)
	check(_events_of(hw, SimEvents.Type.RECALLED).size() == 1, "RECALLED emitted")
	check(
		int(hp27.recall_ready_tick) == hw.tick - 1 + GatherStep.RECALL_COOLDOWN_TICKS,
		"the cooldown arms on completion [T 2700]"
	)
	_op(hw, BagStep.OP_RECALL)
	check(
		(
			hp27.forage_target == GatherStep.NONE
			and _events_of(hw, SimEvents.Type.RECALL_STARTED).is_empty()
		),
		"a cooling recall refuses"
	)
	# Move-cancel leaves the cooldown unspent — an immediate recast
	# is legal; a hit cancels the same tick (the gather bar's rule).
	var hm: RefCounted = _home_world()
	var hmp: RefCounted = hm.players[0]
	_op(hm, BagStep.OP_RECALL)
	_still(hm, 10)
	_move(hm)
	check(hmp.forage_target == GatherStep.NONE, "moving cancels the cast")
	_op(hm, BagStep.OP_RECALL)
	check(hmp.forage_target == GatherStep.RECALL_TARGET, "a canceled cast never spent the cooldown")
	hm.spawn_projectile(hmp.pos, Vector2(0, 0), 0.5, 20, ActorState.FACTION_HOSTILE, 5)
	hm.step([InputFrame.new()])
	check(hmp.forage_target == GatherStep.NONE, "getting hit cancels the cast (same tick)")
	# A recall deliberately OVERRIDES a running forage bar.
	var hf: RefCounted = _world()
	hf.settlement_ids = PackedStringArray(["capital"])
	hf.settlement_cells = PackedVector2Array([Vector2(31.5, 10.5)])
	hf.waypost_cells = PackedVector2Array([Vector2(33.5, 10.5)])
	var hfp: RefCounted = hf.players[0]
	_press(hf)
	check(hfp.forage_target == Vector2(30.5, 10.5), "forage bar running first")
	_op(hf, BagStep.OP_RECALL)
	check(
		hfp.forage_target == GatherStep.RECALL_TARGET and hfp.forage_ticks == 1,
		"a recall overrides the forage bar"
	)
	# Refusals: settlement-less worlds (labs/proofs/rifts/dungeons)
	# and the legacy lane (run()'s class guard — proofs stay inert).
	var hn: RefCounted = _world(false, false)
	_op(hn, BagStep.OP_RECALL)
	check(
		(
			hn.players[0].forage_target == GatherStep.NONE
			and _events_of(hn, SimEvents.Type.RECALL_STARTED).is_empty()
		),
		"a settlement-less world refuses the recall op"
	)
	_op(hn, BagStep.OP_SET_HOME)
	check(int(hn.players[0].home_town) == 0, "a settlement-less world refuses set-home")
	var hl: RefCounted = _home_world(false)
	_op(hl, BagStep.OP_RECALL)
	check(
		hl.players[0].forage_target == GatherStep.NONE,
		"legacy players never recall (the battery stays inert)"
	)
	# Ghost home index: home_cell falls back to the respawn cell.
	var hg: RefCounted = _home_world()
	hg.players[0].home_town = 7
	check(hg.home_cell(hg.players[0]) == hg.respawn_cell, "a ghost home falls back to respawn")
	# Death mid-cast: the revive clears the pair — no posthumous
	# teleport (player_respawn owns the clear) — and lands at HOME.
	var hd: RefCounted = _home_world()
	hd.persistent_respawn = true
	var hdp: RefCounted = hd.players[0]
	_op(hd, BagStep.OP_RECALL)
	_still(hd, 10)
	check(hdp.forage_target == GatherStep.RECALL_TARGET, "cast running before the death")
	Damage.apply(hd, hdp, 99999, 0)
	check(hdp.dead, "dead mid-cast")
	var cf27: RefCounted = InputFrame.new()
	cf27.ability_pressed = true
	hd.step([cf27])
	check(not hdp.dead, "early confirm revives")
	check(
		hdp.forage_target == GatherStep.NONE and hdp.forage_ticks == 0,
		"the revive clears the cast (no posthumous recall)"
	)
	check(hdp.pos == Vector2(31.5, 10.5), "the revive lands at home (settlement 0 default)")
	# Profile round-trip BY ID; ghost ids read the capital; a
	# settlement-less session never overwrites the set home.
	var prof27 := CharacterProfile.create(false, "bow")
	check(String(prof27.home_town_id) == "capital", "fresh profiles carry the capital home")
	prof27.home_town_id = "waystation"
	var hr: RefCounted = _home_world()
	CharacterProfile.apply_to_world(hr, prof27)
	check(int(hr.players[0].home_town) == 1, "profile home loads by id")
	CharacterProfile.harvest(hr, prof27)
	check(String(prof27.home_town_id) == "waystation", "harvest persists the home by id")
	prof27.home_town_id = "atlantis"
	var hr2: RefCounted = _home_world()
	CharacterProfile.apply_to_world(hr2, prof27)
	check(int(hr2.players[0].home_town) == 0, "a ghost home id reads the capital")
	prof27.home_town_id = "waystation"
	var hr3: RefCounted = _world(false, false)
	CharacterProfile.apply_to_world(hr3, prof27)
	CharacterProfile.harvest(hr3, prof27)
	check(
		String(prof27.home_town_id) == "waystation",
		"a settlement-less harvest preserves the home (ghost rule)"
	)
	# SERIAL 28 hash coverage — the seam's whole format growth.
	var wh27: RefCounted = _home_world()
	var hh0: int = wh27.state_hash()
	wh27.players[0].home_town = 1
	check(wh27.state_hash() != hh0, "home_town hashed (SERIAL 28)")
	wh27.players[0].home_town = 0
	var hh1: int = wh27.state_hash()
	wh27.players[0].recall_ready_tick = 999
	check(wh27.state_hash() != hh1, "recall_ready_tick hashed (SERIAL 28)")
	# Slice premises: named tables, parallel sizes, settlement 0 cell
	# == the spawn (the default home IS today's respawn — identity),
	# every cell walkable on b77, wayposts >= 2.4 t (the interact-sweep
	# threshold; measured >= 3.0) from every other station + giver.
	var slice27: Resource = load("res://data/scenarios/slice_overworld.tres")
	check(
		slice27.settlement_ids == PackedStringArray(["capital", "waystation"]),
		"the slice names capital + waystation"
	)
	check(
		(
			slice27.settlement_cells.size() == slice27.settlement_ids.size()
			and slice27.waypost_cells.size() == slice27.settlement_ids.size()
		),
		"settlement tables ride parallel"
	)
	check(
		slice27.settlement_cells[0] == slice27.player_spawn,
		"settlement 0 cell == the spawn (the default home IS today's respawn)"
	)
	if bool(wf.ok):
		var bg27: RefCounted = wf.bitgrid
		for sc27: Vector2 in slice27.settlement_cells:
			check(not bg27.is_solid(int(sc27.x), int(sc27.y)), "settlement walks %s" % str(sc27))
		for wc27: Vector2 in slice27.waypost_cells:
			check(not bg27.is_solid(int(wc27.x), int(wc27.y)), "waypost walks %s" % str(wc27))
	for wp27: Vector2 in slice27.waypost_cells:
		for other27: Vector2 in [
			slice27.bank_cell,
			slice27.tackle_cell,
			Vector2(106.5, 182.5),
			Vector2(106.5, 180.5),
			Vector2(109.5, 182.5),
			Vector2(91.5, 110.5),
		]:
			check(
				wp27.distance_to(other27) >= 2.4,
				"waypost %s clear of %s (sweep threshold)" % [str(wp27), str(other27)]
			)

	if fails.is_empty():
		print(
			"gather_test: PASS (forage-verb/interrupts/wallet/forage-spawner/instant-cast/",
			"ambient/no-drag/drains/grace/snap/clear/fish/rods/refusals/negatives/hash/",
			"forage-profile/rifter/slice/tackle-catalog/shop-ops/rift-gear/rare-drop/",
			"fish-roundtrip/gear-hash/boss-pool/phased-only-catch/kit-premises/",
			"home-bind/recall-cast (sl-0221, SERIAL 28))"
		)
		quit(0)
	else:
		for m: String in fails:
			printerr("gather_test FAIL: " + m)
		quit(1)
