extends SceneTree
## sl-0077 crosshair styles + size consumer test (fixed gate): the
## doc-13 cursor contract mechanized for every style x size —
## odd-sized, lit TRUE-CENTER pixel, every silhouette pixel is one of
## the kit's own two colors (light core / dark rim — silhouette is
## the only differentiator, CORE-50), and every light pixel bordered
## by empty space carries its 1 px dark rim. THE DEFAULT IS PINNED:
## style 0 at size 11 must be BYTE-IDENTICAL to the ratified kit
## bitmap (the sl-0042 crosshair stays untouched). Also writes the
## render-evidence sheet reports/crosshair_styles_preview.png
## (styles x sizes, 8x nearest) for designer eyes. Pure Image ops —
## Linux-safe, no rendering server.
##
## Run: godot --headless --path . --script tests/crosshair/crosshair_styles_test.gd

const CrosshairStyles := preload("res://ui/crosshair_styles.gd")

const UPSCALE := 8
const CELL := 16 * UPSCALE


func _init() -> void:
	var failed := false

	# 1. Default pin: style 0 @ kit-native size = the ratified bitmap.
	# (Via kit_image(): a fresh checkout has no import cache — the old
	# raw load() nulled there and the abort idled forever; sl-0201.)
	var kit := CrosshairStyles.kit_image()
	kit.convert(Image.FORMAT_RGBA8)
	var def := CrosshairStyles.build_base_image(0, 11)
	def.convert(Image.FORMAT_RGBA8)
	if def.get_width() != kit.get_width() or def.get_data() != kit.get_data():
		printerr("FAIL: default style/size is not the ratified kit bitmap")
		failed = true

	# Kit palette for the two-color check.
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

	# 2. Contract per style x size + 3. preview sheet.
	var styles := CrosshairStyles.STYLE_NAMES.size()
	var sizes: Array[int] = CrosshairStyles.SIZES
	var sheet := Image.create_empty(CELL * sizes.size(), CELL * styles, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.35, 0.4, 0.35, 1.0))  # mid ground so rims read
	for si in styles:
		for zi in sizes.size():
			var size: int = sizes[zi]
			var img := CrosshairStyles.build_base_image(si, size)
			img.convert(Image.FORMAT_RGBA8)
			if img.get_width() != size or img.get_height() != size:
				printerr(
					(
						"FAIL: style %d size %d built %dx%d"
						% [si, size, img.get_width(), img.get_height()]
					)
				)
				failed = true
				continue
			if size % 2 != 1:
				printerr("FAIL: even size %d on the ladder" % size)
				failed = true
			var c := (size - 1) / 2
			var center := img.get_pixel(c, c)
			if center.a < 0.5 or not center.is_equal_approx(light):
				printerr("FAIL: style %d size %d has no lit true-center pixel" % [si, size])
				failed = true
			for y in size:
				for x in size:
					var p := img.get_pixel(x, y)
					if p.a < 0.5:
						continue
					if not (p.is_equal_approx(light) or p.is_equal_approx(dark)):
						printerr(
							(
								"FAIL: style %d size %d pixel (%d,%d) off the kit two-color palette"
								% [si, size, x, y]
							)
						)
						failed = true
					if p.is_equal_approx(light) and _bare_light_edge(img, x, y):
						printerr(
							(
								"FAIL: style %d size %d light pixel (%d,%d) missing its dark rim"
								% [si, size, x, y]
							)
						)
						failed = true
			# Blit into the preview sheet, 8x nearest, cell-centered.
			var big := img.duplicate()
			big.resize(size * UPSCALE, size * UPSCALE, Image.INTERPOLATE_NEAREST)
			var off := Vector2i(
				zi * CELL + (CELL - big.get_width()) / 2, si * CELL + (CELL - big.get_height()) / 2
			)
			sheet.blend_rect(big, Rect2i(0, 0, big.get_width(), big.get_height()), off)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	sheet.save_png(ProjectSettings.globalize_path("res://reports/crosshair_styles_preview.png"))

	print("crosshair styles test: " + ("FAIL" if failed else "PASS"))
	print("preview sheet: reports/crosshair_styles_preview.png (rows=styles, cols=sizes)")
	quit(1 if failed else 0)


## True when a LIGHT pixel touches transparent space with no dark
## pixel between (in-bounds 8-neighborhood; the image edge itself
## counts as rimmed — the rim only owes coverage inside the bitmap).
func _bare_light_edge(img: Image, x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			if nx < 0 or ny < 0 or nx >= img.get_width() or ny >= img.get_height():
				continue
			if img.get_pixel(nx, ny).a < 0.5:
				return true
	return false
