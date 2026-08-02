extends Control
## The v2 "panel2" DRAWN chrome (menu pass, sl-0155; seam-A finding:
## the carved-frame look is workbench-drawn over palette tokens, not a
## kit piece). Outer Control draws the chrome (gradient body, carved
## 2px frame, gold corner studs, optional centered title plaque with
## an optional 16px atlas glyph); `content` is an inner full-rect
## MarginContainer owners put their widgets in (a MarginContainer
## force-layouts EVERY child, so the close button must live OUTSIDE
## it — the bisect-probe lesson: a container-stretched icon_close
## renders as a panel-sized X). Optional close button (kit icon_close
## — the sl-0145 every-menu-close rule). All geometry multiplies by
## the live ui-scale. View-only; emits close_requested — owners decide
## what closing means.

signal close_requested

const MenuPalette := preload("res://ui/menu_palette.gd")
const IconAtlas := preload("res://ui/icon_atlas.gd")

## Plaque title (empty = no plaque) + optional atlas glyph id.
var title := ""
var title_icon := ""
## Build the close button (top-right).
var show_close := true
## Owners add their widgets HERE, never to the panel directly.
var content: MarginContainer = null

var _close_btn: TextureButton = null
## Reentry guard: add_theme_constant_override fires THEME_CHANGED
## synchronously — without this, _apply_margins recurses to overflow.
var _applying := false


func _ready() -> void:
	content = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content)
	_apply_margins()
	if show_close:
		_close_btn = TextureButton.new()
		_close_btn.texture_normal = load("res://uikit/icon_close.png")
		_close_btn.stretch_mode = TextureButton.STRETCH_SCALE
		_close_btn.pressed.connect(func() -> void: close_requested.emit())
		add_child(_close_btn)
	resized.connect(_layout_close)
	_layout_close.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_inside_tree() and not _applying:
		_apply_margins()
		_layout_close()
		queue_redraw()


func _scale() -> float:
	return maxf(get_theme_default_base_scale(), 1.0)


func _apply_margins() -> void:
	if content == null:
		return
	_applying = true
	var k := _scale()
	var top := 18.0 if not title.is_empty() else 10.0
	content.add_theme_constant_override("margin_left", int(8.0 * k))
	content.add_theme_constant_override("margin_right", int(8.0 * k))
	content.add_theme_constant_override("margin_top", int(top * k))
	content.add_theme_constant_override("margin_bottom", int(8.0 * k))
	_applying = false


func _layout_close() -> void:
	if _close_btn == null:
		return
	var k := _scale()
	_close_btn.custom_minimum_size = Vector2(12.0, 12.0) * k
	_close_btn.position = Vector2(size.x - 15.0 * k, 3.0 * k)
	_close_btn.size = Vector2(12.0, 12.0) * k


func _draw() -> void:
	var k := _scale()
	var r := Rect2(Vector2.ZERO, size)
	# Carved frame: outer dark carve, inner lip, then the body gradient.
	draw_rect(r, MenuPalette.EDGE_DARK)
	draw_rect(r.grow(-1.0 * k), MenuPalette.EDGE_LIP)
	var body := r.grow(-2.0 * k)
	draw_polygon(
		PackedVector2Array(
			[
				body.position,
				Vector2(body.end.x, body.position.y),
				body.end,
				Vector2(body.position.x, body.end.y),
			]
		),
		PackedColorArray(
			[
				MenuPalette.BODY_TOP,
				MenuPalette.BODY_TOP,
				MenuPalette.BODY_BOTTOM,
				MenuPalette.BODY_BOTTOM,
			]
		)
	)
	# Gold corner studs (2px on the frame line, dim backing).
	_draw_studs(k)
	if not title.is_empty():
		_draw_plaque(k)


func _draw_studs(k: float) -> void:
	var pts := [
		Vector2(2.0, 2.0),
		Vector2(size.x / k - 5.0, 2.0),
		Vector2(2.0, size.y / k - 5.0),
		Vector2(size.x / k - 5.0, size.y / k - 5.0),
	]
	for p: Vector2 in pts:
		draw_rect(Rect2(p * k, Vector2(3.0, 3.0) * k), MenuPalette.GOLD_DIM)
		draw_rect(Rect2((p + Vector2(0.5, 0.5)) * k, Vector2(2.0, 2.0) * k), MenuPalette.GOLD)


func _draw_plaque(k: float) -> void:
	var font := get_theme_default_font()
	var fsize := get_theme_default_font_size()
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	var icon: Texture2D = null
	if not title_icon.is_empty() and IconAtlas.has_icon(title_icon):
		icon = IconAtlas.icon(title_icon)
	var iw := (18.0 * k) if icon != null else 0.0
	var pw := tw + iw + 12.0 * k
	var ph := 14.0 * k
	var px := (size.x - pw) * 0.5
	var plaque := Rect2(px, 1.0 * k, pw, ph)
	draw_rect(plaque.grow(1.0 * k), MenuPalette.GOLD_DIM)
	draw_polygon(
		PackedVector2Array(
			[
				plaque.position,
				Vector2(plaque.end.x, plaque.position.y),
				plaque.end,
				Vector2(plaque.position.x, plaque.end.y),
			]
		),
		PackedColorArray(
			[
				MenuPalette.PLAQUE_TOP,
				MenuPalette.PLAQUE_TOP,
				MenuPalette.PLAQUE_BOTTOM,
				MenuPalette.PLAQUE_BOTTOM,
			]
		)
	)
	var tx := px + 6.0 * k
	if icon != null:
		draw_texture_rect(icon, Rect2(tx, plaque.position.y - 1.0 * k, 16.0 * k, 16.0 * k), false)
		tx += iw
	var baseline := (
		plaque.position.y + (ph + font.get_ascent(fsize) - font.get_descent(fsize)) * 0.5
	)
	draw_string(
		font,
		Vector2(tx, baseline),
		title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		fsize,
		MenuPalette.GOLD_BRIGHT
	)
