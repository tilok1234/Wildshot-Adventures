extends Control
## The WORLD side of the starhook split (sl-0115 — presentation only):
## overlays the frozen cast-moment capture with the LIVE half of the
## two-portal topology (correction #4): the line runs from the body's
## rod INTO the world-side rift — always drawn that way — sagging when
## slack, taut and red under strain, with the travelling spark; the
## portal pulses while the fight is live. The body and the portal
## themselves are IN the capture (the world was drawn when the line
## sank); this overlay is the living part.

const TILE := 32.0
const LINE_SLACK := Color("dceaff")
const LINE_STRAIN := Color("ff8c7a")

var world: RefCounted = null
## Live pane width, base-res px (sl-0125: the split ratio is
## flippable — the body centers in whatever width the world pane
## has, and the portal clamp keeps the line readable at 1/3).
var pane_w := 320.0
## Portal offset from the caster's screen position, base-res px.
var portal_offset := Vector2.ZERO
var biome_rim := Color("b56cff")
## Deep-edge x (tiles) for the strain read (mirrors rift_view).
var deep_x := 10.2
var mouth_x := 1.35


func _process(_delta: float) -> void:
	queue_redraw()


func _tension() -> float:
	if world == null or world.players.is_empty():
		return 0.3
	var p: RefCounted = world.players[0]
	var span := maxf(0.1, deep_x - mouth_x)
	var t := 0.3 + 0.55 * clampf((p.pos.x - mouth_x) / span, 0.0, 1.0)
	if p.pos.x > deep_x:
		t = 1.0
	if world.tick - p.last_damaged_tick < 20:
		t = maxf(t, 0.85)
	return t


func _draw() -> void:
	var t := int(world.tick) if world != null else 0
	var body := Vector2(pane_w * 0.5, 180.0)
	var rod_tip := body + Vector2(6.0 * signf(portal_offset.x + 0.01), -12.0)
	var portal := body + portal_offset
	portal.x = clampf(portal.x, 12.0, pane_w - 12.0)
	portal.y = clampf(portal.y, 16.0, 344.0)
	# Portal pulse: the rift breathes while the fight is on.
	var pulse := 0.5 + 0.5 * sin(float(t) * 0.1)
	draw_set_transform(portal, 0.0, Vector2(1.0, 0.42))
	draw_arc(
		Vector2.ZERO, 16.0 + pulse * 4.0, 0.0, TAU, 20, Color(biome_rim, 0.5 + 0.3 * pulse), 2.0
	)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# The line: rod -> INTO the portal.
	var tension := _tension()
	var sag := lerpf(26.0, 2.0, clampf(tension, 0.0, 1.0))
	var jit := sin(float(t) * 1.7) * 2.5 if tension > 0.8 else sin(float(t) * 0.11) * 2.0
	var ctrl := (rod_tip + portal) * 0.5 + Vector2(jit, sag)
	var low_line: bool = world != null and not world.players.is_empty() and world.players[0].hp < 20
	var col := LINE_STRAIN if tension > 0.8 or low_line else LINE_SLACK
	var pts := PackedVector2Array()
	for i in 17:
		var u := float(i) / 16.0
		pts.append(rod_tip.lerp(ctrl, u).lerp(ctrl.lerp(portal, u), u))
	draw_polyline(pts, col, 1.0)
	var su := fposmod(float(t), 40.0) / 40.0
	var sp := rod_tip.lerp(ctrl, su).lerp(ctrl.lerp(portal, su), su)
	draw_rect(Rect2(sp - Vector2.ONE, Vector2(2, 2)), Color("ffffff", 0.8), true)
