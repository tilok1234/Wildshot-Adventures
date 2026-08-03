extends Control
## THE UNIQUE REVEAL (menu pass seam G, sl-0156 — the designer's
## cinematic): plays ONLY when a UNIQUE-rarity item dropped by a BOSS
## is PICKED UP (structural predicate: unique tables ride phased boss
## defs only — pinned in green_roster_test; a non-boss unique source
## goes red there first). THE PLAY, staged per legendary3 with the
## honest asset truth: the mob pack RINGS the dimmed screen (the
## stampede-1-ring-howl look target — glow-on-dark, real assembler
## wolves) → ONE soft golden wash clears the ring (the flamebreath's
## stand-in: a single luminance ramp, the dragon reel is refinement-
## round material — no dragon sheet exists) → THE PLAQUE: the rarity
## word UNIQUE as a gold word-mark + the ribbon (item icon + name +
## stat line in the one grammar). RAILS (planning's law reads):
## ONE-SHOT, never looping, never ambient; NO strobing — the
## luminance path is dim-in / one wash / steady / fade, mechanized by
## the probe's no-strobe check. CORE-19 note stands: the boss-unique-
## only gate + one-shot + dim staging is the defense. WORLD STATE
## [T]: main PAUSES the sim for the play (never over live danger)
## and ANY INPUT SKIPS — pause_locked holds the pause key; the skip
## is this overlay's own. ~3.8 s total, shorter than the ~7 s spec
## by honesty. View-only.

signal finished

const MenuPalette := preload("res://ui/menu_palette.gd")
const IconAtlas := preload("res://ui/icon_atlas.gd")
const ItemIcons := preload("res://game/views/item_icons.gd")
const ItemText := preload("res://game/views/item_text.gd")
const AssemblerLibrary := preload("res://game/views/assembler_library.gd")

## Stage lengths in seconds [T — refinement rounds own the pacing].
const RING_T := 1.2
const WASH_T := 0.5
const PLAQUE_T := 1.8
const FADE_T := 0.3
const RING_COUNT := 10

var world: RefCounted = null

var _active := false
var _t := 0.0
var _item: Dictionary = {}
var _name_line := ""
var _stat_line := ""
var _icon: Texture2D = null
var _mobs: Array[AnimatedSprite2D] = []
var _lib: RefCounted = null


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_active() -> bool:
	return _active


## Start the one-shot for a picked-up unique {kind, a, b}. A second
## trigger during a play is ignored (never looping, never queued).
func trigger(item: Dictionary) -> void:
	if _active or world == null:
		return
	_item = item
	var line := ItemText.drop_line(world, item)
	_name_line = line.get_slice(" — ", 0)
	_stat_line = line.get_slice(" — ", 1) if line.contains(" — ") else ""
	var p_class := 0
	if not world.players.is_empty():
		p_class = int(world.players[0].class_id)
	_icon = IconAtlas.icon(ItemIcons.icon_id(world, item, p_class))
	_build_ring()
	_active = true
	_t = 0.0
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _build_ring() -> void:
	if _lib == null:
		_lib = AssemblerLibrary.new()
		if not _lib.load_manifest():
			_lib = null
	for m: AnimatedSprite2D in _mobs:
		m.queue_free()
	_mobs.clear()
	if _lib == null or not _lib.has_actor("wolf:gray"):
		return
	var frames: SpriteFrames = _lib.build_sprite_frames("wolf:gray")
	for i in RING_COUNT:
		var m := AnimatedSprite2D.new()
		m.sprite_frames = frames
		if frames.has_animation("walk-down"):
			m.animation = "walk-down"
			m.play()
		m.scale = Vector2(2.0, 2.0)
		add_child(m)
		_mobs.append(m)


func _input(event: InputEvent) -> void:
	if not _active:
		return
	var pressed := false
	if event is InputEventKey:
		pressed = (event as InputEventKey).pressed
	elif event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	if pressed:
		_finish()
		get_viewport().set_input_as_handled()


func _finish() -> void:
	_active = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for m: AnimatedSprite2D in _mobs:
		m.queue_free()
	_mobs.clear()
	finished.emit()


func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	if _t >= RING_T + WASH_T + PLAQUE_T + FADE_T:
		_finish()
		return
	# The ring slides gently inward through stage 1, then clears with
	# the wash (visibility, not motion — no strobe).
	var ring_vis := _t < RING_T + WASH_T * 0.6
	var frac := clampf(_t / RING_T, 0.0, 1.0)
	var c := size * 0.5
	var radius := minf(size.x, size.y) * (0.78 - 0.16 * frac)
	for i in _mobs.size():
		var m := _mobs[i]
		m.visible = ring_vis
		var ang := TAU * float(i) / float(RING_COUNT) + 0.35
		m.position = c + Vector2(cos(ang), sin(ang)) * radius * Vector2(1.0, 0.72)
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var k := maxf(get_theme_default_base_scale(), 1.0)
	# Dim-in (one downward ramp, held through the play).
	var dim := clampf(_t / 0.25, 0.0, 1.0) * 0.62
	if _t > RING_T + WASH_T + PLAQUE_T:
		dim *= 1.0 - clampf((_t - RING_T - WASH_T - PLAQUE_T) / FADE_T, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.03, 0.09, dim))
	# The wash: ONE soft golden ramp up and back (the no-strobe law —
	# a single luminance excursion, never flips).
	if _t >= RING_T and _t < RING_T + WASH_T:
		var wt := (_t - RING_T) / WASH_T
		var wash_a := (1.0 - absf(wt * 2.0 - 1.0)) * 0.45
		draw_rect(
			Rect2(Vector2.ZERO, size),
			Color(
				MenuPalette.GOLD_BRIGHT.r,
				MenuPalette.GOLD_BRIGHT.g,
				MenuPalette.GOLD_BRIGHT.b,
				wash_a
			)
		)
	# THE PLAQUE.
	if _t >= RING_T + WASH_T * 0.5:
		_draw_plaque(k)


func _draw_plaque(k: float) -> void:
	var font := get_theme_default_font()
	var base_size := get_theme_default_font_size()
	var c := size * 0.5
	# The rarity word-mark: UNIQUE, big and gold (the 4th-part grammar,
	# default word).
	var word := "UNIQUE"
	var wsize := base_size * 3
	var ww := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, wsize).x
	draw_string(
		font,
		Vector2(c.x - ww * 0.5, c.y - 26.0 * k),
		word,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		wsize,
		MenuPalette.GOLD_BRIGHT
	)
	# The ribbon: parchment face, icon + name + stat line.
	var rw := 220.0 * k
	var rh := 44.0 * k
	var ribbon := Rect2(c.x - rw * 0.5, c.y - 10.0 * k, rw, rh)
	draw_rect(ribbon.grow(1.0 * k), MenuPalette.GOLD_DIM)
	draw_rect(ribbon, MenuPalette.PARCHMENT)
	if _icon != null:
		draw_texture_rect(
			_icon, Rect2(ribbon.position + Vector2(6.0, 6.0) * k, Vector2(32.0, 32.0) * k), false
		)
	var tx := ribbon.position.x + 44.0 * k
	draw_string(
		font,
		Vector2(tx, ribbon.position.y + 16.0 * k),
		_name_line,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		base_size,
		MenuPalette.PARCHMENT_INK
	)
	if not _stat_line.is_empty():
		draw_string(
			font,
			Vector2(tx, ribbon.position.y + 32.0 * k),
			_stat_line,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			base_size,
			MenuPalette.PARCHMENT_DIM
		)
