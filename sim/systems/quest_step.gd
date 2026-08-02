extends RefCounted
## Ordered system (S1 seam 5): GENERIC QUESTS v1 — walk-up accept and
## turn-in at giver cells (the loot walk-over language; zero input
## changes), one active quest per player, progress counted from this
## tick's OWN events (kills, pickups) plus visit proximity. Runs LAST
## in the step so kill and pickup events for the tick are complete.
## Rewards land IN-SIM (gold + Progress XP) — replay-honest like
## everything else. Site-less/quest-less worlds return immediately;
## legacy (class -1) players never interact — every pre-slice
## scenario and the whole proof battery are byte-identical by
## construction.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const SimEvents := preload("res://sim/events.gd")
const Progress := preload("res://sim/systems/progress.gd")
const QuestDef := preload("res://data/quest_def.gd")

## Walk-up radius at a giver cell [T] — the loot-pickup class.
const GIVER_RADIUS := 1.2


static func run(world: RefCounted) -> void:
	var quests: Array = world.quest_defs
	if quests.is_empty():
		return
	for p: RefCounted in world.players:
		if p.class_id < 0 or p.dead:
			continue
		if p.active_quest >= 0:
			_progress(world, p, quests[p.active_quest])
			_try_turn_in(world, p, quests[p.active_quest])
		if p.active_quest < 0:
			_try_accept(world, p, quests)


static func _progress(world: RefCounted, p: RefCounted, q: Resource) -> void:
	match int(q.kind):
		QuestDef.Kind.KILL:
			for ev: Dictionary in world.events:
				if int(ev.type) != SimEvents.Type.ENTITY_KILLED:
					continue
				if bool(ev.get("player", false)):
					continue
				var di := int(ev.get("def_index", -1))
				if di >= 0 and q.target_defs.has(di):
					p.quest_progress = mini(p.quest_progress + 1, int(q.count))
		QuestDef.Kind.COLLECT:
			for ev: Dictionary in world.events:
				if int(ev.type) != SimEvents.Type.LOOT_PICKED:
					continue
				if int(ev.get("player", -1)) != p.id:
					continue
				p.quest_progress = mini(p.quest_progress + 1, int(q.count))
		QuestDef.Kind.VISIT:
			var tc: Vector2 = q.target_cell
			if p.pos.distance_to(tc) <= float(q.visit_radius):
				p.quest_progress = int(q.count)


static func _try_turn_in(world: RefCounted, p: RefCounted, q: Resource) -> void:
	if p.quest_progress < int(q.count):
		return
	var gc: Vector2 = q.giver_cell
	if p.pos.distance_to(gc) > GIVER_RADIUS:
		return
	p.gold += int(q.reward_gold)
	if int(q.reward_xp) > 0:
		Progress.award_xp(world, p, int(q.reward_xp))
	p.quests_done_mask |= 1 << p.active_quest
	var done: int = p.active_quest
	p.active_quest = -1
	p.quest_progress = 0
	(
		world
		. events
		. append(
			{
				"type": SimEvents.Type.QUEST_DONE,
				"tick": world.tick,
				"player": p.id,
				"quest": done,
				"gold": int(q.reward_gold),
				"xp": int(q.reward_xp),
			}
		)
	)


## The nearest giver's FIRST unfinished quest, walk-up. One at a time.
static func _try_accept(world: RefCounted, p: RefCounted, quests: Array) -> void:
	for qi in quests.size():
		if (p.quests_done_mask & (1 << qi)) != 0:
			continue
		var q: Resource = quests[qi]
		var gc: Vector2 = q.giver_cell
		if p.pos.distance_to(gc) > GIVER_RADIUS:
			continue
		p.active_quest = qi
		p.quest_progress = 0
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
