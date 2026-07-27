extends Node2D
## Overhead enemy HP bars (M5): general presentation drawn for every live
## real enemy — never selection, focus, or hover state; no input can
## influence which bars draw (CORE-35). Sits in the HP_BARS band: above
## actors, below damage numbers and every hostile band (Laws 1/2 — a bar
## can never occlude a threat). Quiet palette; the red fill IS gameplay
## information (Law 6).

const RenderLayers := preload("res://game/render_layers.gd")

const TILE := 32.0
const BAR_W := 22.0
const BAR_H := 3.0
const LIFT := 8.0

var world: RefCounted = null
var clock: RefCounted = null


func _ready() -> void:
	z_index = RenderLayers.HP_BARS


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if world == null:
		return
	var defs: Array = world.enemy_defs
	var interp: bool = clock != null and clock.interp_enabled
	var alpha: float = clock.alpha() if interp else 1.0
	for e: RefCounted in world.enemies:
		var def_index: int = e.def_index
		if def_index < 0 or e.hp <= 0:
			continue
		var max_hp := int(defs[def_index].hp)
		var shown: Vector2 = e.prev_pos.lerp(e.pos, alpha) if interp else e.pos
		var px: Vector2 = (shown * TILE).round()
		var top := px + Vector2(-BAR_W * 0.5, -e.radius * TILE - LIFT - BAR_H)
		draw_rect(Rect2(top, Vector2(BAR_W, BAR_H)), Color(0.08, 0.07, 0.1, 0.85))
		var frac := clampf(float(e.hp) / float(max_hp), 0.0, 1.0)
		draw_rect(
			Rect2(top + Vector2(0.5, 0.5), Vector2((BAR_W - 1.0) * frac, BAR_H - 1.0)),
			Color(0.78, 0.22, 0.2)
		)
