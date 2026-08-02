extends SceneTree
## QUESTS under THE MENU PASS (S1 seam 5 → sl-0112 → sl-0144/0154):
## TURN-IN is the deliberate F-press at the giver (undialogued,
## turn-in wins); the press never accepts — it OFFERS (QUEST_OFFERED
## to the view's dialogue) and ACCEPT is the RECORDED OP (radius +
## capacity gated sim-side); ABANDON is the recorded op that returns
## an errand to its giver (re-offers, re-accepts fresh; done refuses).
## MULTI-ACTIVE capacity (cap 5 [T]) with per-quest progress;
## KILL/COLLECT count for EVERY taken unfinished quest; done-mask
## blocks repeats; legacy/dead players inert; interact on nothing
## does nothing; every field hashed (SERIAL 21); the Green five
## pinned BOTH ways against the content pack's giver slots.
## NEGATIVE-TESTED. Exit 0 = green.

const SimWorld := preload("res://sim/sim_world.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const Damage := preload("res://sim/systems/damage.gd")
const QuestDef := preload("res://data/quest_def.gd")
const SimEvents := preload("res://sim/events.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")

const PACK := "res://assets/wildshot-overworld-pack-dusk-content/"

var fails: Array[String] = []


func check(cond: bool, name: String) -> void:
	if not cond:
		fails.append(name)


func _grid() -> RefCounted:
	var g: RefCounted = Bitgrid.new()
	g.setup(64, 32)
	return g


func _quest(kind: int, giver: Vector2, id := "t_quest") -> Resource:
	var q: Resource = QuestDef.new()
	q.id = StringName(id)
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


func _press(world: RefCounted) -> void:
	var f: RefCounted = InputFrame.new()
	f.interact_pressed = true
	world.step([f])


func _accept_op(world: RefCounted, qi: int) -> void:
	var f: RefCounted = InputFrame.new()
	f.bag_op = BagStep.OP_ACCEPT_BASE + qi
	world.step([f])


func _init() -> void:
	var giver := Vector2(12.5, 16.5)

	# 1. NOTHING auto-accepts and THE PRESS NEVER ACCEPTS (menu pass
	# sl-0144): standing does nothing; the press OFFERS the giver's
	# first available quest (event only, no state change); the
	# RECORDED ACCEPT OP takes it — radius-gated.
	var w: RefCounted = _world(
		[_quest(0, giver, "q_kill"), _quest(1, giver, "q_visit"), _quest(2, giver, "q_collect")]
	)
	var p: RefCounted = w.players[0]
	p.pos = giver
	_step(w, 5)
	check(p.quests_taken_mask == 0, "NEGATIVE: standing on the giver auto-accepts nothing")
	_press(w)
	check(p.quests_taken_mask == 0, "NEGATIVE: the press never accepts (offer only, sl-0144)")
	var saw_offer := false
	for ev: Dictionary in w.events:
		if int(ev.type) == SimEvents.Type.QUEST_OFFERED and int(ev.quest) == 0:
			saw_offer = true
	check(saw_offer, "the press OFFERS the first available quest (QUEST_OFFERED)")
	p.pos = Vector2(40.5, 16.5)
	_accept_op(w, 0)
	check(p.quests_taken_mask == 0, "NEGATIVE: the accept op refuses out of the giver radius")
	p.pos = giver
	_accept_op(w, 0)
	check(p.quests_taken_mask == 1, "the recorded accept op takes the errand at the giver")
	var saw_accept := false
	for ev: Dictionary in w.events:
		if int(ev.type) == SimEvents.Type.QUEST_ACCEPTED and int(ev.quest) == 0:
			saw_accept = true
	check(saw_accept, "QUEST_ACCEPTED emitted")
	_accept_op(w, 1)
	check(p.quests_taken_mask == 3, "second op takes the giver's next quest (multi-active)")
	_accept_op(w, 2)
	check(p.quests_taken_mask == 7, "third op: three carried at once")

	# 2. Progress counts for EVERY taken unfinished quest: one kill
	# advances q_kill; a pickup advances q_collect; the visit fills by
	# proximity — all while carried together.
	var e1: RefCounted = w.add_enemy(0, Vector2(30.5, 16.5))
	Damage.apply(w, e1, 9999, 0)
	_step(w)
	check(p.quest_progress_arr[0] == 1, "kill counts for the taken kill quest")
	w.spawn_drop(p.pos, SimWorld.DROP_GOLD, 5)
	_step(w)
	check(p.quest_progress_arr[2] == 1, "gold pickup counts for the collect quest")
	p.pos = Vector2(40.5, 16.5)
	_step(w)
	check(p.quest_progress_arr[1] == 2, "visit fills by proximity while multi-carried")

	# 3. Turn-in is a deliberate press: the complete visit quest pays
	# at the giver (payoff-first: turn-in wins over accepting more).
	var gold0: int = p.gold
	p.pos = giver
	_step(w, 3)
	check((p.quests_done_mask & 2) == 0, "NEGATIVE: standing never turns in")
	_press(w)
	check((p.quests_done_mask & 2) == 2, "interact turns in the complete quest")
	check(p.gold == gold0 + 25, "reward gold in-sim")
	var saw_done := false
	for ev: Dictionary in w.events:
		if int(ev.type) == SimEvents.Type.QUEST_DONE and int(ev.quest) == 1:
			saw_done = true
	check(saw_done, "QUEST_DONE emitted")

	# 4. Finish the kill quest and re-press: done quests never
	# re-offer; interact away from any giver does nothing.
	var e2: RefCounted = w.add_enemy(0, Vector2(30.5, 16.5))
	Damage.apply(w, e2, 9999, 0)
	_step(w)
	_press(w)
	check((p.quests_done_mask & 1) == 1, "kill quest turned in")
	var mask_before: int = p.quests_taken_mask
	p.pos = Vector2(40.5, 16.5)
	_press(w)
	check(p.quests_taken_mask == mask_before, "NEGATIVE: interact on nothing does nothing")

	# 4.5 ABANDON (sl-0154, menu pass): the recorded op returns a
	# carried errand to its giver — leaves the hands, progress zeroes,
	# available again through the normal accept; done quests refuse.
	var wa: RefCounted = _world([_quest(0, giver, "a_kill")])
	var pa: RefCounted = wa.players[0]
	pa.pos = giver
	_accept_op(wa, 0)
	check(pa.quests_taken_mask == 1, "abandon setup: carried")
	var ea: RefCounted = wa.add_enemy(0, Vector2(30.5, 16.5))
	Damage.apply(wa, ea, 9999, 0)
	_step(wa)
	check(pa.quest_progress_arr[0] == 1, "abandon setup: progressed")
	var fa: RefCounted = InputFrame.new()
	fa.bag_op = BagStep.OP_ABANDON_BASE
	wa.step([fa])
	check(pa.quests_taken_mask == 0, "abandon clears the taken bit")
	check(pa.quest_progress_arr[0] == 0, "abandon zeroes progress")
	var saw_ab := false
	for ev: Dictionary in wa.events:
		if int(ev.type) == SimEvents.Type.QUEST_ABANDONED:
			saw_ab = true
	check(saw_ab, "QUEST_ABANDONED emitted")
	_press(wa)
	var saw_reoffer := false
	for ev: Dictionary in wa.events:
		if int(ev.type) == SimEvents.Type.QUEST_OFFERED and int(ev.quest) == 0:
			saw_reoffer = true
	check(saw_reoffer, "the abandoned errand RE-OFFERS through the normal dialogue")
	_accept_op(wa, 0)
	check(pa.quests_taken_mask == 1, "abandoned errand re-accepts at the giver (op)")
	check(pa.quest_progress_arr[0] == 0, "re-accepted errand starts fresh")
	var ek1: RefCounted = wa.add_enemy(0, Vector2(30.5, 16.5))
	Damage.apply(wa, ek1, 9999, 0)
	_step(wa)
	var ek2: RefCounted = wa.add_enemy(0, Vector2(30.5, 16.5))
	Damage.apply(wa, ek2, 9999, 0)
	_step(wa)
	_press(wa)
	check((pa.quests_done_mask & 1) == 1, "abandon negatives setup: turned in")
	var fd: RefCounted = InputFrame.new()
	fd.bag_op = BagStep.OP_ABANDON_BASE
	wa.step([fd])
	check(
		(pa.quests_done_mask & 1) == 1 and pa.quests_taken_mask == 1,
		"NEGATIVE: done quests refuse abandon"
	)
	_accept_op(wa, 0)
	check(
		(pa.quests_done_mask & 1) == 1 and pa.quests_taken_mask == 1,
		"NEGATIVE: done quests never re-accept (op refuses)"
	)

	# 5. The cap: six quests, cap 5 — the sixth accept OP refuses
	# sim-side (the view's loud refusal is defense-in-front, this
	# guard is the law).
	var six: Array = []
	for i in 6:
		six.append(_quest(0, giver, "q%d" % i))
	var wc: RefCounted = _world(six)
	var pc: RefCounted = wc.players[0]
	pc.pos = giver
	for i in 6:
		_accept_op(wc, i)
	var carried := 0
	for qi in 6:
		if (pc.quests_taken_mask & (1 << qi)) != 0:
			carried += 1
	check(carried == 5, "capacity caps at 5 [T] — the sixth op refuses")

	# 6. NEGATIVES: legacy players and dead players never interact —
	# neither the press (offer) nor the accept op engages.
	var wl: RefCounted = _world([_quest(0, giver)], false)
	wl.players[0].pos = giver
	_press(wl)
	_accept_op(wl, 0)
	check(wl.players[0].quests_taken_mask == 0, "negative: legacy player accepts nothing")
	var wd: RefCounted = _world([_quest(0, giver)])
	var pd: RefCounted = wd.players[0]
	Damage.apply(wd, pd, 99999, 0)
	pd.pos = giver
	_press(wd)
	_accept_op(wd, 0)
	check(pd.quests_taken_mask == 0, "negative: dead player accepts nothing")

	# 7. Hash coverage (SERIAL 21).
	var wh: RefCounted = _world([_quest(0, giver)])
	_step(wh)  # sizes the progress array
	var h0: int = wh.state_hash()
	wh.players[0].quests_taken_mask = 1
	check(wh.state_hash() != h0, "quests_taken_mask hashed")
	wh.players[0].quests_taken_mask = 0
	var h1: int = wh.state_hash()
	wh.players[0].quest_progress_arr[0] = 3
	check(wh.state_hash() != h1, "quest progress hashed")
	wh.players[0].quest_progress_arr[0] = 0
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
		print("quest_test: PASS (interact/multi-active/cap/turn-in/negatives/hash/green-five)")
		quit(0)
	else:
		for m: String in fails:
			printerr("quest_test FAIL: " + m)
		quit(1)
