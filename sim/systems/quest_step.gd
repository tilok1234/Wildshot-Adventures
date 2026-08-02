extends RefCounted
## Ordered system (S1 seam 5, RE-PINNED by sl-0112, RE-PINNED AGAIN by
## the menu pass sl-0144/0154): GENERIC QUESTS with DELIBERATE HANDS
## and MULTI-ACTIVE capacity. TURN-IN is an INTERACT press at the
## giver (the payoff moment, undialogued — turn-in wins); the press
## never accepts anymore — it OFFERS (QUEST_OFFERED to the view's
## dialogue) and ACCEPT is a RECORDED OP (a decision: mouse/hotkey in
## the offer window), radius+capacity gated sim-side. ABANDON is a
## recorded op too (the errand returns to its giver). A player
## carries up to QUEST_CAP errands at once [T], each with its own
## progress; KILL/COLLECT count for EVERY taken, unfinished quest
## from this tick's own events, VISIT completes by proximity. Runs
## LAST in the step. Rewards land IN-SIM. Class lane only; quest-less
## worlds return immediately — proofs inert.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const SimEvents := preload("res://sim/events.gd")
const Progress := preload("res://sim/systems/progress.gd")
const QuestDef := preload("res://data/quest_def.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")

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
		# Menu pass (sl-0144/0154): the recorded quest ops — ABANDON
		# (the errand returns to its giver, progress zeroes, done
		# refuses) and ACCEPT (the offer dialogue's decision;
		# radius + capacity gated here regardless of the view).
		if frame != null:
			var op := int(frame.bag_op)
			if (
				op >= BagStep.OP_ABANDON_BASE
				and op < BagStep.OP_ABANDON_BASE + BagStep.QUEST_OP_MAX
			):
				_abandon(world, p, op - BagStep.OP_ABANDON_BASE, quests)
			elif (
				op >= BagStep.OP_ACCEPT_BASE and op < BagStep.OP_ACCEPT_BASE + BagStep.QUEST_OP_MAX
			):
				_accept(world, p, op - BagStep.OP_ACCEPT_BASE, quests)


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


## One interact press at a giver: turn in their first COMPLETE quest
## (undialogued — TURN-IN WINS), else OFFER their first available one
## to the view's dialogue. One action per press — deliberate hands.
static func _interact(world: RefCounted, p: RefCounted, quests: Array) -> void:
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
	# Offer (sl-0144): the press NEVER accepts — the giver's first
	# available quest goes to the view's dialogue as an event (no
	# state change; events are unserialized, replay-safe). Emitted
	# even at the hands cap: the window reads fine, accepting
	# refuses loudly.
	_offer_first_here(world, p, quests)


## Emit QUEST_OFFERED for the first available quest at the player's
## feet. Pure event — the accept decision rides the recorded op.
static func _offer_first_here(world: RefCounted, p: RefCounted, quests: Array) -> void:
	for qi in quests.size():
		if (p.quests_taken_mask & (1 << qi)) != 0:
			continue
		if (p.quests_done_mask & (1 << qi)) != 0:
			continue
		var q: Resource = quests[qi]
		var gc: Vector2 = q.giver_cell
		if p.pos.distance_to(gc) > GIVER_RADIUS:
			continue
		(
			world
			. events
			. append(
				{
					"type": SimEvents.Type.QUEST_OFFERED,
					"tick": world.tick,
					"player": p.id,
					"quest": qi,
				}
			)
		)
		return


## The recorded ACCEPT op (sl-0144): the offer dialogue's decision.
## Legal only within the quest's OWN giver radius, hands allowing;
## taken/done indexes refuse. The view refuses loudly at capacity —
## this guard holds regardless of what any view shows.
static func _accept(world: RefCounted, p: RefCounted, qi: int, quests: Array) -> void:
	if qi < 0 or qi >= quests.size():
		return
	if (p.quests_taken_mask & (1 << qi)) != 0:
		return
	if (p.quests_done_mask & (1 << qi)) != 0:
		return
	var taken_count := 0
	for ti in quests.size():
		if (p.quests_taken_mask & (1 << ti)) != 0 and (p.quests_done_mask & (1 << ti)) == 0:
			taken_count += 1
	if taken_count >= QUEST_CAP:
		return
	var q: Resource = quests[qi]
	var gc: Vector2 = q.giver_cell
	if p.pos.distance_to(gc) > GIVER_RADIUS:
		return
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


## The recorded ABANDON op (sl-0154): a carried, unfinished quest
## leaves the hands and returns to its giver — available again through
## the normal offer path by construction (available == !taken &&
## !done). Progress zeroes; done quests and untaken indexes refuse.
static func _abandon(world: RefCounted, p: RefCounted, qi: int, quests: Array) -> void:
	if qi < 0 or qi >= quests.size():
		return
	if (p.quests_taken_mask & (1 << qi)) == 0:
		return
	if (p.quests_done_mask & (1 << qi)) != 0:
		return
	p.quests_taken_mask &= ~(1 << qi)
	if qi < p.quest_progress_arr.size():
		p.quest_progress_arr[qi] = 0
	(
		world
		. events
		. append(
			{
				"type": SimEvents.Type.QUEST_ABANDONED,
				"tick": world.tick,
				"player": p.id,
				"quest": qi,
			}
		)
	)
