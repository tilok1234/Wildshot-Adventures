extends Control
## Dev-profile world-map overlay (sl-0065): renders the active
## WorldForge pack's OWN minimap.png — raw texture, zero new art —
## with the player position dot and a facing tick (current free aim).
## One key cycles off -> corner minimap -> fullscreen map.
##
## Profile law: constructed ONLY from main's gated block (construction
## site and toggle line pinned by tools/lockdown_lint.py), so tester
## artifacts never contain this node. Scenarios without a pack minimap
## never attach it — hidden by absence, not by flag. This is NOT the
## Part II player map (doc 13 §3 keeps map/minimap deferred to their
## own designed round: fog-of-war, markers-vs-learning, CORE-50/Law-6
## HUD treatment); this overlay is throwaway-by-design for the
## huge-world test loop.
##
## Law 6 discipline even in dev: the corner variant is small and
## dimmed — never the brightest thing on screen; fullscreen is a
## deliberate look-at-the-map mode over a darkened backdrop. If
## minimap.png resolution proves insufficient on screen, that is a
## WorldForge ask — never a game-side upscale hack (integer
## nearest-neighbor display scaling of the shipped pixels only).

enum Mode { OFF, CORNER, FULL }

const FULL_MARGIN := 12.0
const CORNER_EDGE := 96.0
## Inset keeps the corner variant clear of the hints line (bottom).
const CORNER_INSET := Vector2(4.0, 16.0)

var world: RefCounted = null  # SimWorld — player position, read-only
var mouse_tile := Callable()  # viewport mouse in tile space (facing tick)
var grid_size := Vector2i.ONE  # pack cell dims (arena def width/height)
var mode: int = Mode.OFF
var _tex: ImageTexture = null


func _ready() -> void:
	visible = false
	# Never intercept input: aiming and firing continue under the map.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Raw pack texture or nothing: a missing/unreadable minimap.png
## returns false and the caller drops the overlay entirely.
func load_minimap(path: String) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		return false
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		return false
	_tex = ImageTexture.create_from_image(img)
	return true


func cycle() -> void:
	mode = (mode + 1) % Mode.size()
	visible = mode != Mode.OFF
	queue_redraw()
	print("map: ", ["off", "corner", "fullscreen"][mode])


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()  # the dot tracks the live sim position


## Pack-relative mapping: world tile -> minimap pixel. The ratio comes
## from the actual texture vs the actual grid every time (b65/b77 ship
## 1 px per cell; nothing here assumes it).
static func tile_to_map_px(pos: Vector2, grid: Vector2i, tex: Vector2i) -> Vector2:
	var g := Vector2(maxi(grid.x, 1), maxi(grid.y, 1))
	return pos * Vector2(tex) / g


func _draw() -> void:
	if _tex == null or mode == Mode.OFF:
		return
	var vp := get_viewport_rect().size
	var ts := Vector2(_tex.get_width(), _tex.get_height())
	var rect: Rect2
	if mode == Mode.FULL:
		# Integer upscale when the map fits (crisp cells); fractional
		# fit only when the map outsizes the viewport.
		var fit := minf((vp.x - FULL_MARGIN * 2.0) / ts.x, (vp.y - FULL_MARGIN * 2.0) / ts.y)
		var s := floorf(fit) if fit >= 1.0 else maxf(fit, 0.05)
		rect = Rect2(((vp - ts * s) * 0.5).floor(), ts * s)
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0.0, 0.0, 0.0, 0.55))
		draw_texture_rect(_tex, rect, false)
		draw_rect(rect, Color(0.8, 0.8, 0.8, 0.8), false, 1.0)
	else:
		var s2 := CORNER_EDGE / maxf(ts.x, ts.y)
		var sz := ts * s2
		rect = Rect2((vp - sz - CORNER_INSET).floor(), sz)
		draw_texture_rect(_tex, rect, false, Color(1.0, 1.0, 1.0, 0.8))
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.6), false, 1.0)
	_draw_player(rect)


func _draw_player(rect: Rect2) -> void:
	if world == null:
		return
	var players: Array = world.players
	if players.is_empty():
		return
	var p: RefCounted = players[0]
	var ppos: Vector2 = p.pos
	var tex_size := Vector2i(_tex.get_width(), _tex.get_height())
	var disp_scale := rect.size / Vector2(tex_size)
	var dot := rect.position + tile_to_map_px(ppos, grid_size, tex_size) * disp_scale
	# Facing tick — the same current-free-aim vector the fire path
	# reads; re-normalized AFTER map scaling so a non-square ratio
	# cannot skew the direction.
	if mouse_tile.is_valid():
		var aim: Vector2 = (mouse_tile.call() as Vector2) - ppos
		if aim.length_squared() > 0.0001:
			var tick := (aim * disp_scale).normalized() * (7.0 if mode == Mode.FULL else 5.0)
			draw_line(dot, dot + tick, Color(1.0, 1.0, 1.0, 0.9), 1.0)
	var r := 2.5 if mode == Mode.FULL else 2.0
	draw_circle(dot, r + 1.0, Color(0.0, 0.0, 0.0, 0.9))
	draw_circle(dot, r, Color.WHITE)
