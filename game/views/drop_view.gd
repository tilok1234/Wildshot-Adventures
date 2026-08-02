extends Node2D
## Loop v1 ground-drop rendering (docs/19; CORE-51 Laws 1/6): quiet
## shapes on the LOOT band — grounded under every hazard fill and all
## threat bands, so loot never occludes danger. Shape by kind, tint
## intensity by tier ([T] palette — designer eyes tune). Reads sim
## drops, never mutates; presentation-only.
## S1 seam 2: the nearest drop within read range grows its ONE-GRAMMAR
## label (item_text) — every number visible before you commit to the
## walk-over (docs/22 tooltip constraint). Still LOOT band: the label
## rides under threat, never over it (Law 1 outranks convenience).

const RenderLayers := preload("res://game/render_layers.gd")
const DropKinds := preload("res://sim/drop_kinds.gd")
const ItemText := preload("res://game/views/item_text.gd")

const TILE := 32.0
const GOLD_COLOR := Color(0.95, 0.8, 0.25, 0.95)
const WEAPON_COLOR := Color(0.4, 0.85, 0.9, 0.95)
const ARMOR_COLOR := Color(0.55, 0.6, 0.8, 0.95)
const ABILITY_COLOR := Color(0.75, 0.5, 0.9, 0.95)
const UNIQUE_COLOR := Color(1.0, 0.92, 0.6, 1.0)
const RING_COLOR := Color(0.95, 0.65, 0.35, 0.95)
## sl-0129 ground loot bag (kill loot lands bagged).
const BAG_COLOR := Color(0.62, 0.46, 0.3, 0.95)
## Label read range in tiles [T] — outside the 0.5 pickup radius so
## refused drops (occupied slot / not an upgrade) stay readable.
const LABEL_RANGE := 1.8
const LABEL_COLOR := Color(0.92, 0.9, 0.82, 0.95)

var world: RefCounted = null
var _font: Font = null


func _ready() -> void:
	z_index = RenderLayers.LOOT
	var theme: Theme = load("res://ui/theme.tres")
	_font = theme.default_font if theme != null else ThemeDB.fallback_font


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
			DropKinds.RING:
				draw_arc(pos, 5.0, 0.0, TAU, 16, RING_COLOR, 2.0)
			DropKinds.UNIQUE:
				_diamond(pos, 9.0, UNIQUE_COLOR)
				draw_arc(pos, 11.0, 0.0, TAU, 20, UNIQUE_COLOR, 1.5)
	# sl-0129: ground loot bags — a quiet sack silhouette (body + tie),
	# same LOOT band (Law 1: never over threat). The walk-over panel
	# lists the contents; no ground label competes with it.
	for lb: Dictionary in world.loot_bags:
		var lpos: Vector2 = lb.pos
		var bpos := lpos * TILE
		draw_circle(bpos + Vector2(0.0, 1.5), 6.0, BAG_COLOR)
		draw_rect(Rect2(bpos + Vector2(-2.5, -7.0), Vector2(5.0, 4.0)), BAG_COLOR.darkened(0.25))
		draw_arc(bpos + Vector2(0.0, 1.5), 7.0, 0.0, TAU, 16, BAG_COLOR.darkened(0.4), 1.0)
	_draw_nearest_label()


## The one ground label: nearest drop within LABEL_RANGE of any living
## player, one line of the shared grammar above the shape.
func _draw_nearest_label() -> void:
	if _font == null:
		return
	var best_d := LABEL_RANGE * LABEL_RANGE
	var best: Dictionary = {}
	for d: Dictionary in world.drops:
		var dpos: Vector2 = d.pos
		for p: RefCounted in world.players:
			if p.dead:
				continue
			var dd: float = p.pos.distance_squared_to(dpos)
			if dd < best_d:
				best_d = dd
				best = d
	if best.is_empty():
		return
	var line := ItemText.drop_line(world, best)
	if line.is_empty():
		return
	# sl-0112 deliberate hands: non-gold drops take an interact press —
	# the label says so (the binding is remappable; F default).
	if int(best.kind) != DropKinds.GOLD:
		line = "[F] " + line
	var bpos: Vector2 = best.pos
	var at := (bpos * TILE).round() + Vector2(0.0, -14.0)
	var w := _font.get_string_size(line, HORIZONTAL_ALIGNMENT_CENTER, -1.0, 10).x
	draw_string(
		_font, at - Vector2(w * 0.5, 0.0), line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, LABEL_COLOR
	)


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
