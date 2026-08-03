extends Node2D
## Overhead quest-giver icons (sl-0121): two states from the icon
## pack — quest.available (the giver has an offerable errand) and
## quest.turn_in (a carried errand is complete; the walk back pays).
## Pure view over quest sim state, mirroring quest_step's own rules
## (turn-in wins; available hides at the hands cap exactly like the
## sim refuses the accept). sl-0176: icons anchor to the giver's BODY
## cell (`cell_map`, fed from NpcView's station table) when a body
## exists — station cells are walkability-nudged off the def cell —
## and fall back to the authored giver CELL, the interact truth (the
## capital giver has no body; its icon marks the ground). CORE-35:
## general presentation, never selection or hover. Sits in the
## HP_BARS band: above actors and canopy, below every hostile band
## (Law 1) — the giver's own sprite can never occlude it.

const RenderLayers := preload("res://game/render_layers.gd")
const IconAtlas := preload("res://ui/icon_atlas.gd")
const QuestStep := preload("res://sim/systems/quest_step.gd")

const TILE := 32.0
## Icon bottom sits this far above the anchor cell center. Bodies are
## 24 px @1x (head top 12 px above center): 18 keeps a small clear
## gap over the head — overhead and ATTACHED, not floating a tile of
## air away (sl-0176: 34 read as detached, and at the bodiless
## capital slot it landed under the crowd body two tiles north).
const LIFT := 18.0

var world: RefCounted = null
## Authored giver def cell -> body station cell (NpcView.giver_map()).
## Empty = identity (labs, rifts, packless scenarios).
var cell_map: Dictionary = {}

var _avail_tex: Texture2D = null
var _turnin_tex: Texture2D = null


func _ready() -> void:
	z_index = RenderLayers.HP_BARS
	if IconAtlas.has_icon("quest.available"):
		_avail_tex = IconAtlas.icon("quest.available")
	if IconAtlas.has_icon("quest.turn_in"):
		_turnin_tex = IconAtlas.icon("quest.turn_in")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if world == null:
		return
	for st: Dictionary in giver_states(world):
		var tex: Texture2D = _turnin_tex if bool(st.turn_in) else _avail_tex
		if tex == null:
			continue
		var cell: Vector2 = cell_map.get(st.cell, st.cell)
		var px: Vector2 = (cell * TILE).round()
		var size: Vector2 = tex.get_size()
		draw_texture(tex, px + Vector2(-size.x * 0.5, -LIFT - size.y))


## ---- PURE MODEL (mirrors quest_step's semantics; probe-testable).
## One entry per giver cell that deserves an icon:
## {cell: Vector2, turn_in: bool}.
static func giver_states(world: RefCounted) -> Array:
	var out: Array = []
	if world.players.is_empty() or world.quest_defs.is_empty():
		return out
	var p: RefCounted = world.players[0]
	if p.class_id < 0:
		return out
	var carried := 0
	for ci in world.quest_defs.size():
		var c_taken: bool = (p.quests_taken_mask & (1 << ci)) != 0
		var c_done: bool = (p.quests_done_mask & (1 << ci)) != 0
		if c_taken and not c_done:
			carried += 1
	var by_cell: Dictionary = {}
	for qi in world.quest_defs.size():
		var q: Resource = world.quest_defs[qi]
		var taken: bool = (p.quests_taken_mask & (1 << qi)) != 0
		var done: bool = (p.quests_done_mask & (1 << qi)) != 0
		if done:
			continue
		# 0 none / 1 available / 2 turn-in (turn-in wins per cell).
		var state := 0
		if taken:
			var prog: int = p.quest_progress_arr[qi] if qi < p.quest_progress_arr.size() else 0
			if prog >= int(q.count):
				state = 2
		elif carried < QuestStep.QUEST_CAP:
			state = 1
		if state == 0:
			continue
		var key: Vector2 = q.giver_cell
		by_cell[key] = maxi(int(by_cell.get(key, 0)), state)
	for key: Vector2 in by_cell:
		out.append({"cell": key, "turn_in": int(by_cell[key]) == 2})
	return out
