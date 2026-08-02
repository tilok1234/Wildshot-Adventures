extends Node2D
## THE GALAXY VIEW (sl-0115, STARHOOK v2 — presentation only, reads sim
## state and never mutates). One node draws the rift arena's whole
## dressing in world coordinates, band-honest (CORE-51):
## - z 2: the biome backdrop over the dark floor (gradient + wisps +
##   stars, seeded per run — quiet, Law 6) covering the interior plus
##   the letterbox slivers.
## - z 3: arena rim line, deep-edge shimmer, the galaxy-side portal
##   (the line comes OUT of it — correction #4), and the two
##   star-rock stubs in biome dress. (The flow arrows retired with
##   the sl-0123 drag cut.)
## - z ACTORS: THE BAIT FIGHTER (the star of the feature — a small
##   simple sprite, correction #1/#2) and the star-fish catch (the
##   prototype's pixel map, tinted per biome, gold when rare).
## - z PLAYER_PROJECTILES: THE LINE, galaxy segment — out of the
##   portal to the fighter's back; sag when slack, taut and red under
##   strain, a travelling spark. Hostile bands (60/70) stay above
##   everything here by construction.

const RenderLayers := preload("res://game/render_layers.gd")
const RiftStep := preload("res://sim/systems/rift_step.gd")

const TILE := 32.0

## The prototype's star-fish (20x12, drawn at 2x). 1 outline / 2 body /
## 3 belly / 4 fin / 5 eye / 6 accent.
const FISH_MAP: Array[String] = [
	"....11111...........",
	"..114444111....11...",
	".114422222211..141..",
	"1442222222222111441.",
	"1422225222222222444.",
	"14222222222222334421",
	"1422223333333333441.",
	".11223333333311111..",
	"...1122333311.141...",
	".....11223311..11...",
	".......112211.......",
	".........111........",
]
## The bait fighter (11x12, 1x — "just a simple fighter", smaller than
## the prototype drew him [T size]). 1 outline / 2 suit / 3 visor /
## 4 accent.
const FIGHTER_MAP: Array[String] = [
	"....111....",
	"...12221...",
	"..1233321..",
	"..1232321..",
	"..1222221..",
	".112222211.",
	".121222121.",
	".121222121.",
	"..1222221..",
	"..1221221..",
	"..121.121..",
	"..11...11..",
]

## Biome dress (prototype BIOMES, verbatim hex).
const BIOMES := [
	{
		"name": "NEBULA DRIFT",
		"rim": Color("b56cff"),
		"accent": Color("d44fb0"),
		"deep": Color("140a20"),
		"mid": Color("241038"),
		"wisps": [Color("7a2bd4"), Color("d44fb0")],
		"stars": [Color("ffffff"), Color("ffc8f0"), Color("c8a8ff")],
		"boss":
		{
			"outline": Color("2a1140"),
			"body": Color("8a3ff0"),
			"belly": Color("c88cff"),
			"fin": Color("5a22a8"),
			"accent": Color("ffd24f"),
		},
	},
	{
		"name": "HOLLOW VOID",
		"rim": Color("3a6cff"),
		"accent": Color("4fd4c8"),
		"deep": Color("04050e"),
		"mid": Color("0b1124"),
		"wisps": [Color("1b2c6e"), Color("0f4a5e")],
		"stars": [Color("9fc0ff"), Color("e8f0ff")],
		"boss":
		{
			"outline": Color("060a1c"),
			"body": Color("20418f"),
			"belly": Color("4fd4c8"),
			"fin": Color("142a66"),
			"accent": Color("8ffff2"),
		},
	},
	{
		"name": "COMET FIELD",
		"rim": Color("a8f0ff"),
		"accent": Color("7ce8ff"),
		"deep": Color("061018"),
		"mid": Color("0d2233"),
		"wisps": [Color("134a66"), Color("2a7ab0")],
		"stars": [Color("ffffff"), Color("bff4ff")],
		"boss":
		{
			"outline": Color("08202e"),
			"body": Color("2a7ab0"),
			"belly": Color("a8f0ff"),
			"fin": Color("175a88"),
			"accent": Color("ffffff"),
		},
	},
]
const RARE_BOSS := {
	"outline": Color("4a2c08"),
	"body": Color("e8a41f"),
	"belly": Color("ffe08a"),
	"fin": Color("b0740f"),
	"accent": Color("ffffff"),
}
const FIGHTER_COLORS := {
	"1": Color("1a2340"), "2": Color("b8c8e0"), "3": Color("7ce8ff"), "4": Color("ffffff")
}
const LINE_SLACK := Color("dceaff")
const LINE_STRAIN := Color("ff8c7a")

var world: RefCounted = null
var clock: RefCounted = null
var biome: int = 0
var rare: bool = false
## Arena grid dims (walls included) — interior derives.
var arena_w: int = 12
var arena_h: int = 13
## The two star-rock stub cells (1x1 wall cells in arena_rift.json).
var stub_cells: Array[Vector2i] = [Vector2i(4, 4), Vector2i(7, 9)]
## The galaxy-side portal: the line comes OUT of here (tiles).
var mouth := Vector2(1.35, 6.5)

var _backdrop: ImageTexture = null
var _backdrop_node: Sprite2D = null
var _dress: Node2D = null
var _actors: Node2D = null
var _line: Node2D = null


func _ready() -> void:
	z_index = 0
	var b: Dictionary = BIOMES[clampi(biome, 0, 2)]
	_backdrop = _make_backdrop(b)
	_backdrop_node = Sprite2D.new()
	_backdrop_node.texture = _backdrop
	_backdrop_node.centered = false
	# sl-0125: 1-tile skirt beyond the walls — at the two-thirds
	# ratio the fitted camera sees past the interior sides, and the
	# galaxy must reach the pane edge, never void.
	_backdrop_node.position = Vector2(-1.0, -1.0) * TILE
	_backdrop_node.z_index = 2
	add_child(_backdrop_node)
	_dress = Node2D.new()
	_dress.z_index = 3
	_dress.draw.connect(_draw_dress.bind(_dress))
	add_child(_dress)
	_actors = Node2D.new()
	_actors.z_index = RenderLayers.ACTORS
	_actors.draw.connect(_draw_actors.bind(_actors))
	add_child(_actors)
	_line = Node2D.new()
	_line.z_index = RenderLayers.PLAYER_PROJECTILES
	_line.draw.connect(_draw_line.bind(_line))
	add_child(_line)


func _process(_delta: float) -> void:
	_dress.queue_redraw()
	_actors.queue_redraw()
	_line.queue_redraw()


## The interior + letterbox backdrop: vertical gradient, soft wisps,
## point stars (seeded per run — deterministic per world, view-only).
func _make_backdrop(b: Dictionary) -> ImageTexture:
	var w := int((float(arena_w) + 2.0) * TILE)
	var h := int((float(arena_h) + 2.0) * TILE)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var mid: Color = b.mid
	var deep: Color = b.deep
	for y in h:
		var c := mid.lerp(deep, float(y) / float(h))
		for x in w:
			img.set_pixel(x, y, c)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world.run_seed) * 7 + biome
	var wisps: Array = b.wisps
	var wisp_n := 4 if biome == 1 else 8
	for i in wisp_n:
		var cx := rng.randi_range(0, w - 1)
		var cy := rng.randi_range(0, h - 1)
		var rad := rng.randi_range(30, 80)
		var col: Color = wisps[i % 2]
		for dy in range(-rad, rad + 1, 2):
			for dx in range(-rad, rad + 1, 2):
				var px := cx + dx
				var py := cy + dy
				if px < 0 or py < 0 or px >= w or py >= h:
					continue
				var d := sqrt(float(dx * dx + dy * dy)) / float(rad)
				if d > 1.0:
					continue
				var base := img.get_pixel(px, py)
				img.set_pixel(px, py, base.lerp(col, (1.0 - d) * 0.18))
	var stars: Array = b.stars
	var star_n := 40 if biome == 1 else 90
	for i in star_n:
		var sx := rng.randi_range(0, w - 1)
		var sy := rng.randi_range(0, h - 1)
		var sc: Color = stars[rng.randi_range(0, stars.size() - 1)]
		sc.a = 0.55 if rng.randf() < 0.5 else 1.0
		img.set_pixel(sx, sy, sc)
		if rng.randf() < 0.12 and sx + 1 < w and sy + 1 < h:
			img.set_pixel(sx + 1, sy, sc)
			img.set_pixel(sx, sy + 1, sc)
	if biome == 2:
		for i in 14:
			var x0 := rng.randi_range(0, w - 16)
			var y0 := rng.randi_range(0, h - 8)
			for k in 14:
				var px2 := x0 + k
				var py2 := y0 + int(float(k) * 0.35)
				if px2 < w and py2 < h:
					var cbase := img.get_pixel(px2, py2)
					img.set_pixel(px2, py2, cbase.lerp(Color("7ce8ff"), 0.25))
	return ImageTexture.create_from_image(img)


func _view_tick() -> int:
	return int(world.tick)


func _shown_pos(a: RefCounted) -> Vector2:
	if clock != null and clock.interp_enabled:
		return a.prev_pos.lerp(a.pos, clock.alpha())
	return a.pos


## Line tension 0..1 from the fighter's place in the current + recent
## damage (view-side read of sim truth; the drains/strain are sim).
func _tension(p: RefCounted) -> float:
	var deep_x := RiftStep.deep_edge_x(world)
	var span := maxf(0.1, deep_x - mouth.x)
	var t := 0.3 + 0.55 * clampf((p.pos.x - mouth.x) / span, 0.0, 1.0)
	if p.pos.x > deep_x:
		t = 1.0
	if world.tick - p.last_damaged_tick < 20:
		t = maxf(t, 0.85)
	return t


func _draw_dress(cv: Node2D) -> void:
	var b: Dictionary = BIOMES[clampi(biome, 0, 2)]
	var rim: Color = b.rim
	var accent: Color = b.accent
	var x0 := 1.0 * TILE
	var y0 := 1.0 * TILE
	var x1 := float(arena_w - 1) * TILE
	var y1 := float(arena_h - 1) * TILE
	# Arena rim (thin, quiet).
	var rim_faint := Color(rim, 0.27)
	cv.draw_rect(Rect2(x0 - 0.5, y0 - 0.5, x1 - x0 + 1.0, y1 - y0 + 1.0), rim_faint, false, 1.0)
	# Deep-edge shimmer strip (the biome accent warns, never blocks).
	var deep_x := RiftStep.deep_edge_x(world) * TILE
	var grad_w := x1 - deep_x
	for i in 6:
		var a := 0.04 + 0.03 * float(i)
		var gx := deep_x + grad_w * float(i) / 6.0
		cv.draw_rect(Rect2(gx, y0, grad_w / 6.0, y1 - y0), Color(accent, a), true)
	# The galaxy-side portal (the mouth): squashed spinning rings.
	var t := _view_tick()
	var mp := mouth * TILE
	cv.draw_set_transform(mp, 0.0, Vector2(0.45, 1.0))
	cv.draw_circle(Vector2.ZERO, 15.0, Color(b.deep, 0.95))
	for i in 3:
		var spin := float(t) * 0.04 * (1.0 if i % 2 == 0 else -1.3) + float(i) * 2.0
		var col := rim if i == 0 else Color(accent, 0.66 if i == 1 else 0.4)
		cv.draw_arc(Vector2.ZERO, 13.0 - float(i) * 4.0, spin, spin + 3.6, 12, col, 2.0)
	cv.draw_set_transform_matrix(Transform2D.IDENTITY)
	cv.draw_circle(mp, 22.0, Color(rim, 0.13))
	# Star-rock stubs in biome dress (solid cells; sprites read over
	# the wall tiles, under actors like the prototype).
	for sc in stub_cells:
		var base := Vector2(float(sc.x), float(sc.y)) * TILE
		_draw_stub(cv, base, b)
	# sl-0123: the flow arrows retired WITH the drag [T call] — they
	# advertised a current that no longer moves anything. The line's
	# tension + the deep shimmer are the strain story now.


func _draw_stub(cv: Node2D, base: Vector2, b: Dictionary) -> void:
	var rim: Color = b.rim
	var accent: Color = b.accent
	var cx := base + Vector2(16.0, 16.0)
	match biome:
		1:
			# Runestone: a tall slab.
			cv.draw_rect(Rect2(base + Vector2(9, 4), Vector2(14, 26)), Color("0b1124"), true)
			cv.draw_rect(Rect2(base + Vector2(9, 4), Vector2(14, 26)), rim, false, 1.0)
			cv.draw_rect(Rect2(base + Vector2(14, 10), Vector2(4, 4)), Color(accent, 0.8), true)
			cv.draw_rect(Rect2(base + Vector2(13, 20), Vector2(6, 2)), Color(accent, 0.5), true)
		2:
			# Comet mound: a low glowing dome.
			cv.draw_circle(cx + Vector2(0, 6), 12.0, Color("0d2233"))
			cv.draw_arc(cx + Vector2(0, 6), 12.0, PI, TAU, 12, rim, 1.5)
			cv.draw_circle(cx + Vector2(-3, 2), 2.0, Color(accent, 0.9))
		_:
			# Crystal cluster.
			var pts := PackedVector2Array(
				[cx + Vector2(0, -14), cx + Vector2(8, 8), cx + Vector2(-8, 8)]
			)
			cv.draw_colored_polygon(pts, Color("241038"))
			cv.draw_polyline(
				PackedVector2Array(
					[
						cx + Vector2(0, -14),
						cx + Vector2(8, 8),
						cx + Vector2(-8, 8),
						cx + Vector2(0, -14)
					]
				),
				rim,
				1.0
			)
			cv.draw_colored_polygon(
				PackedVector2Array([cx + Vector2(2, -8), cx + Vector2(7, 6), cx + Vector2(-1, 6)]),
				Color(accent, 0.55)
			)


func _draw_actors(cv: Node2D) -> void:
	var t := _view_tick()
	# The catch: the star-fish pixel map, 2x, biome palette (gold when
	# rare), tail wiggle, damage flash.
	var pal: Dictionary = RARE_BOSS if rare else BIOMES[clampi(biome, 0, 2)].boss
	for e: RefCounted in world.enemies:
		if e.hp <= 0:
			continue
		var ep := _shown_pos(e) * TILE
		var face := -1.0 if e.vel.x < -0.01 else (1.0 if e.vel.x > 0.01 else -1.0)
		var flash: bool = world.tick - e.last_damaged_tick < 4
		var wig := sin(float(t) * 0.22)
		var scale := 2.4 if rare else 2.0
		for r in FISH_MAP.size():
			var row := FISH_MAP[r]
			for i in row.length():
				var ch := row[i]
				if ch == ".":
					continue
				var col: Color
				match ch:
					"1":
						col = pal.outline
					"2":
						col = pal.body
					"3":
						col = pal.belly
					"4":
						col = pal.fin
					"5":
						col = Color.WHITE
					_:
						col = pal.accent
				if flash:
					col = Color.WHITE
				var tail := roundf(wig * maxf(0.0, float(i) - 13.0) * 0.22)
				var lx := (float(i) - 10.0) * face
				var ly := float(r) - 6.0 + tail
				cv.draw_rect(Rect2(ep + Vector2(lx, ly) * scale, Vector2(scale, scale)), col, true)
		# Constellation accents orbiting the body.
		for i in 3:
			var an := float(t) * 0.06 + float(i) * 2.1
			var op := ep + Vector2(cos(an) * 26.0, sin(an) * 13.0)
			cv.draw_rect(Rect2(op, Vector2(2, 2)), Color(pal.accent, 0.6), true)
	# THE BAIT FIGHTER — the little guy on the end of the line.
	for p: RefCounted in world.players:
		if p.dead:
			continue
		# Hit-grace blink (prototype-exact readability).
		if world.tick < p.line_iframe_until and (t >> 1) % 2 == 1:
			continue
		var pp := _shown_pos(p) * TILE
		cv.draw_set_transform(pp + Vector2(0.0, 3.0), 0.0, Vector2(1.0, 0.5))
		cv.draw_circle(Vector2.ZERO, 8.0, Color("7ce8ff", 0.28))
		cv.draw_set_transform_matrix(Transform2D.IDENTITY)
		var origin := pp + Vector2(-5.5, -9.0)
		for r in FIGHTER_MAP.size():
			var row := FIGHTER_MAP[r]
			for i in row.length():
				var ch := row[i]
				if ch == ".":
					continue
				cv.draw_rect(
					Rect2(origin + Vector2(float(i), float(r)), Vector2.ONE),
					FIGHTER_COLORS[ch],
					true
				)


func _draw_line(cv: Node2D) -> void:
	if world.players.is_empty():
		return
	var p: RefCounted = world.players[0]
	if p.dead:
		return
	var t := _view_tick()
	var tension := _tension(p)
	var p0 := mouth * TILE
	var p2 := _shown_pos(p) * TILE + Vector2(0.0, -4.0)
	var sag := lerpf(26.0, 2.0, clampf(tension, 0.0, 1.0))
	var jit := sin(float(t) * 1.7) * 2.5 if tension > 0.8 else sin(float(t) * 0.11) * 2.0
	var ctrl := (p0 + p2) * 0.5 + Vector2(jit, sag)
	var col := LINE_STRAIN if tension > 0.8 or p.hp < 20 else LINE_SLACK
	var pts := PackedVector2Array()
	for i in 17:
		var u := float(i) / 16.0
		pts.append(p0.lerp(ctrl, u).lerp(ctrl.lerp(p2, u), u))
	cv.draw_polyline(pts, col, 1.0)
	# The travelling spark, portal -> fighter.
	var su := fposmod(float(t), 40.0) / 40.0
	var sp := p0.lerp(ctrl, su).lerp(ctrl.lerp(p2, su), su)
	cv.draw_rect(Rect2(sp - Vector2.ONE, Vector2(2, 2)), Color("ffffff", 0.8), true)
