extends Camera2D
## Camera per docs/12 §2.9: fixed zoom, zero smoothing, follows the player's
## rendered (interpolated or snapped) position, rounded to whole base-res
## pixels VIEW-SIDE ONLY — sim floats are untouched. Built-in Camera2D
## limits clamp the view to the arena so nothing beyond it ever shows.

const TILE := 32.0

var world: RefCounted = null
var clock: RefCounted = null
var player_index: int = 0
## sl-0115: rift arenas use a FIXED camera framing the whole interior
## in the right pane (Law 1: no off-screen bullets, ever) — no follow,
## no clamping.
var fixed_mode := false


func setup(arena_width_tiles: int, arena_height_tiles: int) -> void:
	zoom = Vector2.ONE
	position_smoothing_enabled = false
	limit_left = 0
	limit_top = 0
	limit_right = int(arena_width_tiles * TILE)
	limit_bottom = int(arena_height_tiles * TILE)
	make_current()


## Fixed framing at a world-pixel position (rift arenas).
func setup_fixed(pos_px: Vector2) -> void:
	zoom = Vector2.ONE
	position_smoothing_enabled = false
	fixed_mode = true
	limit_left = -10000000
	limit_top = -10000000
	limit_right = 10000000
	limit_bottom = 10000000
	position = pos_px
	make_current()


func _process(_delta: float) -> void:
	if fixed_mode:
		return
	if world == null or world.players.size() <= player_index:
		return
	var p: RefCounted = world.players[player_index]
	var shown: Vector2 = p.pos
	if clock != null and clock.interp_enabled:
		shown = p.prev_pos.lerp(p.pos, clock.alpha())
	position = (shown * TILE).round()
