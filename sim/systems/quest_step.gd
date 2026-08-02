extends RefCounted
## Ordered system (S1 seam 5, RE-PINNED by sl-0112 — the interact
## era): GENERIC QUESTS with DELIBERATE HANDS and MULTI-ACTIVE
## capacity. Accepting and turning in are INTERACT presses at giver
## cells (walk-up auto-accept RETIRED — the payoff is a moment, not a
## footstep); a player carries up to QUEST_CAP errands at once [T],
## each with its own progress; KILL/COLLECT count for EVERY taken,
## unfinished quest from this tick's own events, VISIT completes by
## proximity. Turn-in pays the first COMPLETE quest of the pressed
## giver; accept takes their first unoffered quest when hands allow.
## Runs LAST in the step. Rewards land IN-SIM. Class lane only;
## quest-less worlds return immediately — proofs inert.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const SimEvents := preload("res://sim/events.gd")
const Progress := preload("res://sim/systems/progress.gd")
const QuestDef := preload("res://data/quest_def.gd")

## Interact reach at a giver cell [T] — the walk-up class.
const GIVER_RADIUS := 1.2
## Errands carried at once [T] (sl-0112: all five Green quests).
const QUEST_CAP := 5


static func run(world: RefCounted) -> void:
	var quests: Array = world.quest_defs
	if quests.is_empty():
		return
	var frames: Array = world.current_frames
	for i in world.players.size():
		var p: RefCounted = world.players[i]
		if p.class_id < 0 or p.dead:
			continue
		if p.quest_progress_arr.size() < quests.size():
			p.quest_progress_arr.resize(quests.size())
		_progress(world, p, quests)
		var frame: RefCounted = frames[i] if i < frames.size() else null
		if frame != null and frame.interact_pressed:
			_interact(world, p, quests)


## Progress every taken, unfinished quest from this tick's events.
static func _progress(world: RefCounted, p: RefCounted, quests: Array) -> void:
	for qi in quests.size():
		if (p.quests_taken_mask & (1 << qi)) == 0:
			continue
		if (p.quests_done_mask & (1 << qi)) != 0:
			continue
		var q: Resource = quests[qi]
		match int(q.kind):
			QuestDef.Kind.KILL:
				for ev: Dictionary in world.events:
					if int(ev.type) != SimEvents.Type.ENTITY_KILLED:
						continue
					if bool(ev.get("player", false)):
						continue
					var di := int(ev.get("def_index", -1))
					if di >= 0 and q.target_defs.has(di):
						p.quest_progress_arr[qi] = mini(p.quest_progress_arr[qi] + 1, int(q.count))
			QuestDef.Kind.COLLECT:
				for ev: Dictionary in world.events:
					if int(ev.type) != SimEvents.Type.LOOT_PICKED:
						continue
					if int(ev.get("player", -1)) != p.id:
						continue
					p.quest_progress_arr[qi] = mini(p.quest_progress_arr[qi] + 1, int(q.count))
			QuestDef.Kind.VISIT:
				var tc: Vector2 = q.target_cell
				if p.pos.distance_to(tc) <= float(q.visit_radius):
					p.quest_progress_arr[qi] = int(q.count)


## One interact press at a giver: turn in their first COMPLETE quest,
## else accept their first unoffered one (capacity allowing). One
## action per press — deliberate hands.
static func _interact(world: RefCounted, p: RefCounted, quests: Array) -> void:
	var taken_count := 0
	for qi in quests.size():
		if (p.quests_taken_mask & (1 << qi)) != 0 and (p.quests_done_mask & (1 << qi)) == 0:
			taken_count += 1
	# Turn-in first: the payoff moment.
	for qi in quests.size():
		var q: Resource = quests[qi]
		if (p.quests_taken_mask & (1 << qi)) == 0:
			continue
		if (p.quests_done_mask & (1 << qi)) != 0:
			continue
		if p.quest_progress_arr[qi] < int(q.count):
			continue
		var gc: Vector2 = q.giver_cell
		if p.pos.distance_to(gc) > GIVER_RADIUS:
			continue
		p.gold += int(q.reward_gold)
		if int(q.reward_xp) > 0:
			Progress.award_xp(world, p, int(q.reward_xp))
		p.quests_done_mask |= 1 << qi
		(
			world
			. events
			. append(
				{
					"type": SimEvents.Type.QUEST_DONE,
					"tick": world.tick,
					"player": p.id,
					"quest": qi,
					"gold": int(q.reward_gold),
					"xp": int(q.reward_xp),
				}
			)
		)
		return
	# Accept: the pressed giver's first unoffered quest.
	if taken_count >= QUEST_CAP:
		return
	for qi in quests.size():
		if (p.quests_taken_mask & (1 << qi)) != 0:
			continue
		if (p.quests_done_mask & (1 << qi)) != 0:
			continue
		var q: Resource = quests[qi]
		var gc: Vector2 = q.giver_cell
		if p.pos.distance_to(gc) > GIVER_RADIUS:
			continue
		p.quests_taken_mask |= 1 << qi
		p.quest_progress_arr[qi] = 0
		(
			world
			. events
			. append(
				{
					"type": SimEvents.Type.QUEST_ACCEPTED,
					"tick": world.tick,
					"player": p.id,
					"quest": qi,
				}
			)
		)
		return
