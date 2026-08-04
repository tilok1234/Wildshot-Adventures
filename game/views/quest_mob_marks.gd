extends Node2D
## Overhead quest-mob marks (sl-0218): a mob whose def serves a
## carried unfinished KILL errand wears a small mark above its HP
## bar — "you need that mob" at a glance (the designer's word; the
## activity-promotion model: cheap, legible, everywhere — no bespoke
## story staging). Pure view over quest + enemy sim state: general
## presentation, never selection/focus/hover; no input influences
## which mobs mark; nothing in aiming, damage, or AI reads the mark
## (CORE-35). Binding mirrors the HUD tracker and the map objectives
## EXACTLY (sl-0175): a tracked carried unfinished errand narrows
## marks to its own targets; no tracked choice = every carried
## errand [T]. GRAMMAR (sl-0184): the mark ships OBJECTIVE-family —
## amber, the map-diamond family, on an unclaimed shape (the dot);
## green belongs to turn-in. The designer's spoken green-dot lean
## and an amber chevron are captured beside it in the evidence sheet
## — `style` flips by one line, their eyes pick [T]. COLLECT marks
## nothing (any mob drops — marking everything is noise); VISIT has
## the map diamond. Sits in the HP_BARS band: below every hostile
## band, so a mark can never occlude a threat (Law 1).

const RenderLayers := preload("res://game/render_layers.gd")

const TILE := 32.0
## Bar geometry mirrored from hp_bar_view (LIFT 8 + BAR_H 3) + a
## small clear gap: the mark stacks just above the HP bar.
const BAR_STACK := 11.0
const GAP := 2.0
## Mark palette: amber = the map objective family; green = the
## turn-in family (captured as an option only).
const AMBER := Color(1.0, 0.78, 0.25)
const GREEN := Color(0.55, 1.0, 0.62)
const HALO := Color(0.0, 0.0, 0.0, 0.9)

## Style [T — the designer's eyes pick from the evidence sheet]:
## 0 = amber dot (shipped default), 1 = green dot (the spoken lean),
## 2 = amber chevron.
var style: int = 0
var world: RefCounted = null
var clock: RefCounted = null
## Config autoload (tracked-quest binding); probes NULL this after
## the first frame (gotcha 41: the node exists under --script runs).
var _cfg: Node = null


func _ready() -> void:
	z_index = RenderLayers.HP_BARS
	_cfg = get_node_or_null("/root/Config")


func _process(_delta: float) -> void:
	queue_redraw()


func _tracked_quest() -> String:
	if _cfg == null:
		return ""
	return String(_cfg.get_setting("ui", "tracked_quest", ""))


func _draw() -> void:
	if world == null:
		return
	var marked := marked_defs(world, _tracked_quest())
	if marked.is_empty():
		return
	var interp: bool = clock != null and clock.interp_enabled
	var alpha: float = clock.alpha() if interp else 1.0
	for e: RefCounted in world.enemies:
		if e.def_index < 0 or e.hp <= 0:
			continue
		if not marked.has(e.def_index):
			continue
		var shown: Vector2 = e.prev_pos.lerp(e.pos, alpha) if interp else e.pos
		var px: Vector2 = (shown * TILE).round()
		_draw_mark(px + Vector2(0.0, -e.radius * TILE - BAR_STACK - GAP))


## One mark above one mob; `anchor` is the bar-top center. Every
## style carries a black halo (the pack minimap-marker discipline —
## legible over any ground).
func _draw_mark(anchor: Vector2) -> void:
	var c := anchor + Vector2(0.0, -3.0)
	match style:
		1:
			draw_circle(c, 3.4, HALO)
			draw_circle(c, 2.2, GREEN)
		2:
			var halo := PackedVector2Array(
				[
					c + Vector2(-4.4, -4.6),
					c + Vector2(0.0, 0.6),
					c + Vector2(4.4, -4.6),
					c + Vector2(0.0, -1.8),
				]
			)
			draw_colored_polygon(halo, HALO)
			var pts := PackedVector2Array(
				[
					c + Vector2(-3.2, -4.0),
					c + Vector2(0.0, -0.4),
					c + Vector2(3.2, -4.0),
					c + Vector2(0.0, -2.2),
				]
			)
			draw_colored_polygon(pts, AMBER)
		_:
			draw_circle(c, 3.4, HALO)
			draw_circle(c, 2.2, AMBER)


## ---- PURE MODEL (probe-testable; the quest_markers binding
## skeleton exactly). def_index -> true for every def serving a
## bound carried unfinished KILL errand. A finished-but-unturned
## errand marks nothing — its mobs are no longer needed.
static func marked_defs(world: RefCounted, tracked_id := "") -> Dictionary:
	var out: Dictionary = {}
	if world == null or world.players.is_empty():
		return out
	var p: RefCounted = world.players[0]
	if p.class_id < 0:
		return out
	var only_qi := -1
	if not tracked_id.is_empty():
		for ti in world.quest_defs.size():
			if String(world.quest_defs[ti].id) != tracked_id:
				continue
			if (p.quests_taken_mask & (1 << ti)) == 0:
				continue
			if (p.quests_done_mask & (1 << ti)) != 0:
				continue
			only_qi = ti
	for qi in world.quest_defs.size():
		if only_qi >= 0 and qi != only_qi:
			continue
		if (p.quests_taken_mask & (1 << qi)) == 0:
			continue
		if (p.quests_done_mask & (1 << qi)) != 0:
			continue
		var q: Resource = world.quest_defs[qi]
		if int(q.kind) != 0:
			continue
		var prog: int = p.quest_progress_arr[qi] if qi < p.quest_progress_arr.size() else 0
		if prog >= int(q.count):
			continue
		for d in q.target_defs:
			out[int(d)] = true
	return out
