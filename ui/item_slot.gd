extends Control
## One square item slot (menu pass, c_menu_v2 grid vocabulary):
## bgSlot fill + 1px edge, hover brightens, a 16px atlas glyph
## centered, optional corner badge text (counts). Tooltip rides the
## built-in tooltip_text (the one grammar — callers compose it).
## Emits slot_clicked(button_index) for left/right decisions; the
## caller owns semantics (equip / drop-confirm / deposit / ...).
## View-only.

signal slot_clicked(button_index: int)

const MenuPalette := preload("res://ui/menu_palette.gd")

## Base cell size in game px (scales by theme base scale); owners may
## set a bigger cell (portrait/dollslots) before adding to the tree.
const CELL := 25.0

var cell_px := CELL

var icon_tex: Texture2D = null:
	set(v):
		icon_tex = v
		queue_redraw()
var badge := "":
	set(v):
		badge = v
		queue_redraw()
## Draw the gold selected edge (worn slots / active selections).
var selected := false:
	set(v):
		selected = v
		queue_redraw()

var _hover := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(
		func() -> void:
			_hover = true
			queue_redraw()
	)
	mouse_exited.connect(
		func() -> void:
			_hover = false
			queue_redraw()
	)
	_apply_size()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_inside_tree():
		_apply_size()


func _apply_size() -> void:
	var k := maxf(get_theme_default_base_scale(), 1.0)
	custom_minimum_size = Vector2(cell_px, cell_px) * k


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			slot_clicked.emit(mb.button_index)
			accept_event()


func _draw() -> void:
	var k := maxf(get_theme_default_base_scale(), 1.0)
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, MenuPalette.SLOT_EDGE if not selected else MenuPalette.GOLD_DIM)
	var fill := MenuPalette.SLOT_HOVER if _hover else MenuPalette.SLOT_BG
	draw_rect(r.grow(-1.0 * k), fill)
	if icon_tex != null:
		var isz := 16.0 * k
		var off := (size - Vector2(isz, isz)) * 0.5
		draw_texture_rect(icon_tex, Rect2(off, Vector2(isz, isz)), false)
	if not badge.is_empty():
		var font := get_theme_default_font()
		var fsize := get_theme_default_font_size()
		var bw := font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
		draw_string(
			font,
			Vector2(size.x - bw - 2.0 * k, size.y - 3.0 * k),
			badge,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			fsize,
			MenuPalette.GOLD_BRIGHT
		)
