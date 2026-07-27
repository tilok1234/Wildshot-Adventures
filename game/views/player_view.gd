extends Node2D
## Placeholder player marker (M2 interim): a flat circle at the sim position.
## The Sprite Forge AnimatedActor replaces this within M2 (§2.14). View-only:
## reads sim state, never mutates it (§2.1). Renders the prev/curr
## interpolated position (or snaps, per the §2.9 toggle), rounded to whole
## base-res pixels view-side only.

const TILE := 32.0

var world: RefCounted = null
var clock: RefCounted = null
var player_index: int = 0


func _process(_delta: float) -> void:
	if world == null or world.players.size() <= player_index:
		return
	var p: RefCounted = world.players[player_index]
	var shown: Vector2 = p.pos
	if clock != null and clock.interp_enabled:
		shown = p.prev_pos.lerp(p.pos, clock.alpha())
	position = (shown * TILE).round()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 0.35 * TILE, Color(0.92, 0.92, 1.0))
