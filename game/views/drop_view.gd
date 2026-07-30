extends Node2D
## Loop v1 ground-drop rendering (docs/19; CORE-51 Laws 1/6): quiet
## shapes on the LOOT band — grounded under every hazard fill and all
## threat bands, so loot never occludes danger. Shape by kind, tint
## intensity by tier ([T] palette — designer eyes tune). Reads sim
## drops, never mutates; presentation-only.

const RenderLayers := preload("res://game/render_layers.gd")
const DropKinds := preload("res://sim/drop_kinds.gd")

const TILE := 32.0
const GOLD_COLOR := Color(0.95, 0.8, 0.25, 0.95)
const WEAPON_COLOR := Color(0.4, 0.85, 0.9, 0.95)
const ARMOR_COLOR := Color(0.55, 0.6, 0.8, 0.95)
const ABILITY_COLOR := Color(0.75, 0.5, 0.9, 0.95)
const UNIQUE_COLOR := Color(1.0, 0.92, 0.6, 1.0)

var world: RefCounted = null


func _ready() -> void:
	z_index = RenderLayers.LOOT


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if world == null:
		return
	for d: Dictionary in world.drops:
		var dpos: Vector2 = d.pos
		var pos := dpos * TILE
		match int(d.kind):
			DropKinds.GOLD:
				draw_circle(pos, 4.0, GOLD_COLOR)
				draw_arc(pos, 5.5, 0.0, TAU, 16, GOLD_COLOR.darkened(0.35), 1.0)
			DropKinds.WEAPON:
				var wt := int(d.b)
				_diamond(pos, 6.0 + float(wt), WEAPON_COLOR.lightened(0.06 * wt))
			DropKinds.ARMOR:
				var at := int(d.a)
				var s := 5.0 + float(at)
				draw_rect(
					Rect2(pos - Vector2(s, s) * 0.5, Vector2(s, s)),
					ARMOR_COLOR.lightened(0.06 * at)
				)
			DropKinds.ABILITY:
				_triangle(pos, 6.5, ABILITY_COLOR)
			DropKinds.UNIQUE:
				_diamond(pos, 9.0, UNIQUE_COLOR)
				draw_arc(pos, 11.0, 0.0, TAU, 20, UNIQUE_COLOR, 1.5)


func _diamond(pos: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array(
		[pos + Vector2(0, -r), pos + Vector2(r, 0), pos + Vector2(0, r), pos + Vector2(-r, 0)]
	)
	draw_colored_polygon(pts, col)


func _triangle(pos: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array(
		[pos + Vector2(0, -r), pos + Vector2(r * 0.87, r * 0.5), pos + Vector2(-r * 0.87, r * 0.5)]
	)
	draw_colored_polygon(pts, col)
