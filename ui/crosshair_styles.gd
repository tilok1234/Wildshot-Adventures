extends RefCounted
## sl-0077 selectable crosshair shapes + size (designer deck-note on
## the ratified crosshair card). PLAYER-FACING, both profiles.
##
## STYLE 0 "classic" = the ratified kit cursor_crosshair.png — at its
## native size it is returned UNTOUCHED (bit-identical default).
## Styles 1-3 (dot / ring / cross-x) are drawn deterministically at
## request time using the kit cursor's OWN two colors, sampled from
## its pixels (brightest opaque = light core, darkest = dark rim), so
## every style shares the ratified palette and silhouette is the only
## differentiator (CORE-50: never hue). Every shape is odd-sized with
## a lit TRUE CENTER pixel and carries a 1 px dark rim (doc-13 cursor
## spec) so it survives every floor.
##
## Sizes are odd only, small bounded range; 11 = the kit native.
## View/cursor layer only — zero sim impact by construction.

const KIT_CURSOR := "res://uikit/cursor_crosshair.png"

const STYLE_NAMES: Array[String] = ["classic", "dot", "ring", "cross"]
const SIZES: Array[int] = [9, 11, 13, 15]
const DEFAULT_STYLE := 0
const DEFAULT_SIZE := 11


static func clamp_style(idx: int) -> int:
	return clampi(idx, 0, STYLE_NAMES.size() - 1)


## Snap any persisted value onto the legal odd ladder.
static func clamp_size(size: int) -> int:
	var best: int = SIZES[0]
	for s: int in SIZES:
		if absi(size - s) < absi(size - best):
			best = s
	return best


## Base (unscaled) cursor image for a style at an odd size. Style 0 at
## kit-native size is the ratified bitmap verbatim; other sizes
## nearest-resize it (odd->odd keeps the true center pixel). Drawn
## styles render exactly at the requested size.
static func build_base_image(style: int, size: int) -> Image:
	style = clamp_style(style)
	size = clamp_size(size)
	var kit := (load(KIT_CURSOR) as Texture2D).get_image()
	if style == 0:
		if size != kit.get_width():
			kit.resize(size, size, Image.INTERPOLATE_NEAREST)
		return kit
	var colors := _sample_colors(kit)
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := (size - 1) / 2
	match style:
		1:  # dot — filled disc, reads as a solid point
			var r_core := maxi(1, c - 2)
			for y in size:
				for x in size:
					if Vector2(x - c, y - c).length() <= float(r_core) + 0.1:
						img.set_pixel(x, y, colors.light)
		2:  # ring — hollow circle + lit true-center pixel
			var r_ring := float(c) - 1.5
			for y in size:
				for x in size:
					if absf(Vector2(x - c, y - c).length() - r_ring) < 0.6:
						img.set_pixel(x, y, colors.light)
			img.set_pixel(c, c, colors.light)
		3:  # cross — diagonal X (45 deg vs the classic's orthogonal plus)
			for d in range(-(c - 1), c):
				img.set_pixel(c + d, c + d, colors.light)
				img.set_pixel(c + d, c - d, colors.light)
	_rim(img, colors.dark)
	return img


## Sample the kit cursor's palette: brightest opaque pixel = light
## core, darkest opaque = dark rim. A future kit re-drop re-skins
## every style automatically — no hardcoded hues.
static func _sample_colors(kit: Image) -> Dictionary:
	var light := Color(1, 1, 1)
	var dark := Color(0, 0, 0)
	var lo := 4.0
	var hi := -1.0
	for y in kit.get_height():
		for x in kit.get_width():
			var p := kit.get_pixel(x, y)
			if p.a < 0.5:
				continue
			var lum := p.r + p.g + p.b
			if lum > hi:
				hi = lum
				light = p
			if lum < lo:
				lo = lum
				dark = p
	return {"light": light, "dark": dark}


## 1 px dark rim: every empty pixel 8-adjacent to a light pixel.
static func _rim(img: Image, dark: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var lit: Array[Vector2i] = []
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.5:
				lit.append(Vector2i(x, y))
	for p: Vector2i in lit:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var n := p + Vector2i(dx, dy)
				if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
					continue
				if img.get_pixel(n.x, n.y).a < 0.5:
					img.set_pixel(n.x, n.y, dark)
