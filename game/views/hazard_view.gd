extends Node2D
## Hazard/telegraph renderer (M4 subset): live zones draw a rim ring with
## an arm-progress sweep — the §2.5 telegraph language's placeholder.
## Friendly zones (Blast Rune) render in the friendly band; HOSTILE zone
## rims move ABOVE player VFX when hostile hazards exist (M6 band
## assertions). Reads world.hazards each frame; view-only.

const TILE := 32.0

var world: RefCounted = null

var _friendly_rim := Color(0.55, 0.75, 1.0, 0.9)
var _friendly_fill := Color(0.4, 0.6, 1.0, 0.12)
var _hostile_rim := Color(1.0, 0.32, 0.2, 0.95)
var _hostile_fill := Color(1.0, 0.3, 0.2, 0.14)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if world == null:
		return
	var t: int = world.tick
	for hz: Dictionary in world.hazards:
		var pos: Vector2 = hz.pos * TILE
		var r: float = float(hz.radius) * TILE
		var hostile: bool = int(hz.faction) == 1
		draw_circle(pos, r, _hostile_fill if hostile else _friendly_fill)
		draw_arc(pos, r, 0.0, TAU, 48, _hostile_rim if hostile else _friendly_rim, 1.0)
		# Arm-progress sweep: fills as detonation approaches (Law 4-ish
		# placeholder; the authored arm indicators land with M-FX).
		var arm_at: int = int(hz.arm_at_tick)
		var total: float = maxf(1.0, float(arm_at - int(hz.placed_at_tick)))
		var left := float(arm_at - t)
		var progress := clampf(1.0 - left / total, 0.0, 1.0)
		if progress > 0.0:
			draw_arc(
				pos,
				r - 2.0,
				-PI / 2.0,
				-PI / 2.0 + TAU * progress,
				48,
				_hostile_rim if hostile else _friendly_rim,
				2.0
			)
