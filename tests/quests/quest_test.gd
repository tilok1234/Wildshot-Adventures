extends SceneTree
## GENERIC QUESTS v1 contracts (S1 seam 5, sl-0104; docs/23
## disposition 5): walk-up accept at giver cells (one active per
## player, class lane only — legacy players NEVER interact, the
## battery's byte-identity by construction), KILL/VISIT/COLLECT
## progress from the sim's own events, walk-up turn-in at the SAME
## giver with in-sim rewards (gold + XP), done-mask blocks repeats,
## every new field hashed (SERIAL 19), reason tags present, giver
## cells match the content pack's giver slots. NEGATIVE-TESTED.
## Exit 0 = green.

const SimWorld := preload("res://sim/sim_world.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const Damage := preload("res://sim/systems/damage.gd")
const QuestDef := preload("res://data/quest_def.gd")
const SimEvents := preload("res://sim/events.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")

const PACK := "res://assets/wildshot-overworld-pack-dusk-content/"

var fails: Array[String] = []


func check(cond: bool, name: String) -> void:
	if not cond:
		fails.append(name)


func _grid() -> RefCounted:
	var g: RefCounted = Bitgrid.new()
	g.setup(64, 32)
	return g


func _quest(kind: int, giver: Vector2) -> Resource:
	var q: Resource = QuestDef.new()
	q.id = &"t_quest"
	q.reason = "waystation"
	q.giver_cell = giver
	q.kind = kind
	q.target_defs = PackedInt32Array([0])
	q.target_cell = Vector2(40.5, 16.5)
	q.visit_radius = 3.0
	q.count = 2
	q.reward_gold = 25
	q.reward_xp = 30
	return q


func _world(quests: Array, class_backed := true) -> RefCounted:
	var world: RefCounted = SimWorld.new()
	world.setup(5, _grid())
	world.set_progression(load("res://data/progression.tres"))
	world.set_stat_frame(StatFrame.load_frame())
	world.set_enemy_defs([load("res://data/enemies/rusher.tres")])
	world.set_quests(quests)
	world.add_player(Vector2(10.5, 16.5))
	var p: RefCounted = world.players[0]
	if class_backed:
		p.class_id = 2
		StatFrame.recompute(world, p)
	return world


func _step(world: RefCounted, n := 1) -> void:
	for i in n:
		world.step([InputFrame.new()])


func _init() -> void:
	var giver := Vector2(12.5, 16.5)

	# 1. Walk-up accept: class player near the giver takes the first
	# unfinished quest; ONE active at a time; events emitted.
	var w: RefCounted = _world([_quest(0, giver), _quest(1, giver)])
	var p: RefCounted = w.players[0]
	_step(w)
	check(p.active_quest == -1, "far from the giver: nothing accepted")
	p.pos = giver
	_step(w)
	check(p.active_quest == 0, "walk-up accepts the giver's first quest")
	var saw_accept := false
	for ev: Dictionary in w.events:
		if int(ev.type) == SimEvents.Type.QUEST_ACCEPTED and int(ev.quest) == 0:
			saw_accept = true
	check(saw_accept, "QUEST_ACCEPTED emitted")
	_step(w)
	check(p.active_quest == 0 and p.quest_progress == 0, "second quest NOT stacked")

	# 2. KILL progress counts only target defs, capped at count; then
	# walk-up turn-in pays gold + xp, sets the done bit, frees the slot.
	var e1: RefCounted = w.add_enemy(0, Vector2(30.5, 16.5))
	Damage.apply(w, e1, 9999, 0)
	_step(w)  # sweep + quest read the kill in the same step
	check(p.quest_progress == 1, "target kill counts")
	var gold0: int = p.gold
	var xp0: int = p.xp
	var e2: RefCounted = w.add_enemy(0, Vector2(30.5, 16.5))
	var e3: RefCounted = w.add_enemy(0, Vector2(31.5, 16.5))
	Damage.apply(w, e2, 9999, 0)
	Damage.apply(w, e3, 9999, 0)
	p.pos = giver
	_step(w)
	check(p.quest_progress == 0 and p.active_quest == 1, "turn-in at the giver, next quest offered")
	check((p.quests_done_mask & 1) == 1, "done bit set")
	check(p.gold == gold0 + 25, "reward gold in-sim")
	check(p.xp != xp0 or p.level > 1, "reward xp in-sim")
	var saw_done := false
	for ev: Dictionary in w.events:
		if int(ev.type) == SimEvents.Type.QUEST_DONE and int(ev.quest) == 0:
			saw_done = true
	check(saw_done, "QUEST_DONE emitted")

	# 3. VISIT completes by proximity, then turns in at the giver.
	check(p.active_quest == 1, "visit quest active")
	p.pos = Vector2(40.5, 16.5)
	_step(w)
	check(p.quest_progress == 2, "visit fills progress to count")
	p.pos = giver
	_step(w)
	check(p.active_quest == -1 and (p.quests_done_mask & 2) == 2, "visit turned in")
	_step(w)
	check(p.active_quest == -1, "all quests done: giver offers nothing (no repeats)")

	# 4. COLLECT counts THIS player's pickups (any kind).
	var wc: RefCounted = _world([_quest(2, giver)])
	var pc: RefCounted = wc.players[0]
	pc.pos = giver
	_step(wc)
	check(pc.active_quest == 0, "collect quest accepted")
	wc.spawn_drop(pc.pos, wc.DROP_GOLD, 5)
	_step(wc)
	check(pc.quest_progress == 1, "pickup counts toward collect")

	# 5. NEGATIVE: legacy (class -1) players never interact.
	var wl: RefCounted = _world([_quest(0, giver)], false)
	var pl: RefCounted = wl.players[0]
	pl.pos = giver
	_step(wl, 3)
	check(pl.active_quest == -1, "negative: legacy player accepts nothing")

	# 6. NEGATIVE: a dead player interacts with nothing.
	var wd: RefCounted = _world([_quest(0, giver)])
	var pd: RefCounted = wd.players[0]
	Damage.apply(wd, pd, 99999, 0)
	pd.pos = giver
	_step(wd)
	check(pd.active_quest == -1, "negative: dead player accepts nothing")

	# 7. Hash coverage: all three quest fields are serialized state.
	var wh: RefCounted = _world([_quest(0, giver)])
	var h0: int = wh.state_hash()
	wh.players[0].active_quest = 0
	check(wh.state_hash() != h0, "active_quest hashed")
	wh.players[0].active_quest = -1
	var h1: int = wh.state_hash()
	wh.players[0].quest_progress = 3
	check(wh.state_hash() != h1, "quest_progress hashed")
	wh.players[0].quest_progress = 0
	var h2: int = wh.state_hash()
	wh.players[0].quests_done_mask = 5
	check(wh.state_hash() != h2, "quests_done_mask hashed")

	# 8. The Green five: loader order, giver cells match the pack's
	# giver slots, reasons carried, targets valid.
	var lw: RefCounted = ScenarioLoader.build_world(
		load("res://data/scenarios/lab_default.tres"), 1, _grid()
	)
	var quests: Array = lw.quest_defs
	check(quests.size() == 5, "five green quests loaded")
	var plan: Variant = JSON.parse_string(FileAccess.get_file_as_string(PACK + "content-plan.json"))
	var slot_cells := {}
	for g: Dictionary in plan.get("giverSlots", []):
		if String(g.get("id", "")).begins_with("giver.zone.green"):
			var c: Array = g.cell
			slot_cells["%d,%d" % [int(c[0]), int(c[1])]] = String(g.get("reason", ""))
	for q: Resource in quests:
		var gc: Vector2 = q.giver_cell
		var key := "%d,%d" % [int(gc.x), int(gc.y)]
		check(slot_cells.has(key), String(q.id) + ": giver cell is a real green giver slot")
		check(
			String(q.reason) == String(slot_cells.get(key, "")),
			String(q.id) + ": reason matches the slot's tag"
		)
		check(not String(q.text).is_empty(), String(q.id) + ": has its line")
		if int(q.kind) == 0:
			for di in q.target_defs:
				check(di >= 8 and di <= 21, String(q.id) + ": kill targets are Green ordinaries")

	if fails.is_empty():
		print("quest_test: PASS (accept/kill/visit/collect/turn-in/negatives/hash/green-five)")
		quit(0)
	else:
		for m: String in fails:
			printerr("quest_test FAIL: " + m)
		quit(1)
