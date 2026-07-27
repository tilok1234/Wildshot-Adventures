extends Node2D
## Debug-emitter renderer: the turret was firing from an INVISIBLE point
## — a Law 8 hole even in a dev scene (deaths must be explainable, and
## "shot by nothing" isn't). Draws a hostile diamond at the emitter and a
## contracting windup ring while the next volley telegraphs (reads sim
## state: emitter_next_fire), in the hostile-telegraph band. View-only.
## Real enemies (M5) replace this with sheet-rendered actors + authored
## telegraphs.

const RenderLayers := preload("res://game/render_layers.gd")

const TILE := 32.0
const TELEGRAPH_TICKS := 30  # mirrors emitter_step

var world: RefCounted = null


func _ready() -> void:
	z_index = RenderLayers.HOSTILE_TELEGRAPH_RIMS


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if world == null or not world.emitter_on:
		return
	var pos: Vector2 = world.emitter_pos * TILE
	# Body: hostile diamond, unmistakably a shooter.
	var r := 7.0
	var pts := PackedVector2Array(
		[
			pos + Vector2(0.0, -r),
			pos + Vector2(r, 0.0),
			pos + Vector2(0.0, r),
			pos + Vector2(-r, 0.0),
		]
	)
	draw_colored_polygon(pts, Color(0.75, 0.2, 0.16))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1.0, 0.45, 0.35), 1.0)
	# Windup: ring contracts onto the turret as firing approaches (Law 4
	# placeholder — prominence tracks imminence).
	var until_fire: int = int(world.emitter_next_fire) - int(world.tick)
	if until_fire <= TELEGRAPH_TICKS and until_fire >= 0:
		var t := 1.0 - float(until_fire) / TELEGRAPH_TICKS
		var ring_r := lerpf(22.0, 8.0, t)
		draw_arc(pos, ring_r, 0.0, TAU, 32, Color(1.0, 0.32, 0.2, 0.4 + 0.6 * t), 2.0)
