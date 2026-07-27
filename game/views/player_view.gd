extends Node2D
## Placeholder player marker (M2 interim): a flat circle at the sim position.
## The Sprite Forge AnimatedActor replaces this within M2 (§2.14). View-only:
## reads sim state, never mutates it (§2.1). Position rounding and prev/curr
## interpolation arrive with the §2.9 camera task.

const TILE := 32.0

var world: RefCounted = null
var player_index: int = 0


func _process(_delta: float) -> void:
	if world == null or world.players.size() <= player_index:
		return
	position = world.players[player_index].pos * TILE


func _draw() -> void:
	draw_circle(Vector2.ZERO, 0.35 * TILE, Color(0.92, 0.92, 1.0))
