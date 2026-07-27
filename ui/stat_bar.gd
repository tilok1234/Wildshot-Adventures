extends Control
## HP/mana stat bar per the kit contract: bar_frame 9-slice with the fill
## strip TILED horizontally inside the frame's 2 px padding (kit README).
## HP and mana fills differ by pattern, not hue alone (CORE-50). View-only;
## value is pushed by the HUD each frame from sim state.

var frame_box: StyleBoxTexture = null
var fill_tex: Texture2D = null
## 0..1
var value := 1.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	if frame_box != null:
		draw_style_box(frame_box, Rect2(Vector2.ZERO, size))
	if fill_tex == null:
		return
	var inner := Rect2(2.0, 2.0, (size.x - 4.0) * value, size.y - 4.0)
	if inner.size.x < 1.0:
		return
	draw_texture_rect(fill_tex, inner, true)
