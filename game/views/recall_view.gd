extends Node2D
## THE RECALL CAST bar (sl-0221 — presentation only): while a player's
## gather pair carries the RECALL sentinel, a cast bar draws ABOVE
## THEIR OWN HEAD (the gather bar's sibling — same 26 px gold bar,
## plus the plain word RECALL). Progress is pure sim state
## (forage_ticks / RECALL_CAST_TICKS); the sim owns every cancel
## (move/hit) and the completion teleport. HP_BARS band like every
## readout (Law 1 structural — hostile bands stay above). Mounted only
## where a settlement table exists; plain overworld words (the cosmic
## rail is starhook-lane-only).

const RenderLayers := preload("res://game/render_layers.gd")
const GatherStep := preload("res://sim/systems/gather_step.gd")

const TILE := 32.0
const GOLD := Color("e8c86a")

var world: RefCounted = null


func _ready() -> void:
	z_index = RenderLayers.HP_BARS


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if world == null:
		return
	for p: RefCounted in world.players:
		if p.forage_target != GatherStep.RECALL_TARGET:
			continue
		var frac: float = clampf(
			float(p.forage_ticks) / float(GatherStep.RECALL_CAST_TICKS), 0.0, 1.0
		)
		var bw := 26.0
		var bp: Vector2 = p.pos * TILE + Vector2(-bw * 0.5, -26.0)
		draw_rect(Rect2(bp - Vector2(1, 1), Vector2(bw + 2.0, 5.0)), Color(0, 0, 0, 0.65), true)
		draw_rect(Rect2(bp, Vector2(bw * frac, 3.0)), GOLD, true)
		var font := ThemeDB.fallback_font
		draw_string(
			font, bp + Vector2(-4.0, -4.0), "RECALL", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, GOLD
		)
