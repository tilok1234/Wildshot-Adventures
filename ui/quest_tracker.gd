extends Label
## THE HUD TRACKER (sl-0121): carried errands at a glance — short
## name + progress count, one line per errand up to the hands cap —
## top-right under the bars/minimap stack [T]. The C sheet stays THE
## one log (full text + reason tags + capacity); this is the pull,
## not the log. Main feeds offset_top ui-scale-aware beside the
## minimap inset.

var world: RefCounted = null

var _accum := 0.0
var _cfg: Node = null


func _ready() -> void:
	_cfg = get_node_or_null("/root/Config")
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	modulate = Color(0.92, 0.9, 0.82, 0.92)
	text = ""
	set_top(34.0)


## Deterministic fixed rect, top-right (no preset/grow games — those
## reset under post-add offset feeds): main calls this ui-scale-aware.
func set_top(y: float) -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -280.0
	offset_right = -4.0
	offset_top = y
	offset_bottom = y + 160.0


func _process(delta: float) -> void:
	_accum += delta
	if _accum < 0.25:
		return
	_accum = 0.0
	if world == null:
		text = ""
		return
	# Menu pass: the tracker BINDS to the tracked quest (the log's
	# per-quest toggle, [ui]-persisted view-side). No tracked choice =
	# every carried errand, the pre-pass behavior [T].
	var tracked := ""
	if _cfg != null:
		tracked = String(_cfg.get_setting("ui", "tracked_quest", ""))
	text = "\n".join(rows(world, tracked))


## ---- PURE MODEL. One short line per carried errand:
## "West Road  3/6" / "Mud Pocket  DONE — return". Short names derive
## from the quest id slug (defs carry no short name; the full
## sentence lives in the C log). A non-empty tracked id that matches a
## carried, unfinished quest narrows the tracker to THAT errand
## (menu-pass binding); otherwise every carried errand shows [T].
static func rows(world: RefCounted, tracked_id := "") -> Array[String]:
	var out: Array[String] = []
	if world.players.is_empty() or world.quest_defs.is_empty():
		return out
	var p: RefCounted = world.players[0]
	if p.class_id < 0:
		return out
	var only_qi := -1
	if not tracked_id.is_empty():
		for qi in world.quest_defs.size():
			if String(world.quest_defs[qi].id) != tracked_id:
				continue
			if (p.quests_taken_mask & (1 << qi)) == 0:
				continue
			if (p.quests_done_mask & (1 << qi)) != 0:
				continue
			only_qi = qi
	for qi in world.quest_defs.size():
		if only_qi >= 0 and qi != only_qi:
			continue
		if (p.quests_taken_mask & (1 << qi)) == 0:
			continue
		if (p.quests_done_mask & (1 << qi)) != 0:
			continue
		var q: Resource = world.quest_defs[qi]
		var prog: int = p.quest_progress_arr[qi] if qi < p.quest_progress_arr.size() else 0
		var short := short_name(String(q.id))
		if prog >= int(q.count):
			out.append("%s  DONE — return" % short)
		else:
			out.append("%s  %d/%d" % [short, prog, int(q.count)])
	return out


## "green_mud_pocket" -> "Mud Pocket" (zone prefix stripped).
static func short_name(id: String) -> String:
	var s := id
	var us := s.find("_")
	if us >= 0:
		s = s.substr(us + 1)
	return s.capitalize()
