extends Node2D
## Damage numbers (docs/12 §2.10): non-occluding default — small, offset
## above the target, alpha-faded, HARD CAP on simultaneous instances
## (reported to the density meter against effects_max), and rendered in
## the DAMAGE_NUMBERS band, below every hostile band (§2.5 band 6).
## Modes (CORE-50 "reducible"): FULL / REDUCED (half cap, minor damage
## dropped) / OFF. Presentation-only; the sim is ignorant of all of it.

const SimEvents := preload("res://sim/events.gd")
const RenderLayers := preload("res://game/render_layers.gd")

enum Mode {
	OFF,
	REDUCED,
	FULL,
}

const TILE := 32.0
const CAP_FULL := 24
const CAP_REDUCED := 8
const REDUCED_MIN_DAMAGE := 5
const LIFE := 0.6
const RISE_TILES := 0.5

var driver: Node = null
## Shared feedback-settings dictionary (main owns it; options panel
## mutates it live). Key: "damage_numbers" -> Mode.
var settings: Dictionary = {}

var _font: Font = null
var _pos: Array[Vector2] = []
var _text: Array[String] = []
var _age: Array[float] = []
var _active: Array[bool] = []


func _ready() -> void:
	z_index = RenderLayers.DAMAGE_NUMBERS
	var theme: Theme = load("res://ui/theme.tres")
	_font = theme.default_font if theme != null else ThemeDB.fallback_font
	_pos.resize(CAP_FULL)
	_text.resize(CAP_FULL)
	_age.resize(CAP_FULL)
	_active.resize(CAP_FULL)


func active_count() -> int:
	var n := 0
	for i in CAP_FULL:
		if _active[i]:
			n += 1
	return n


func _process(delta: float) -> void:
	var mode := int(settings.get("damage_numbers", Mode.FULL))
	if driver != null and mode != Mode.OFF:
		for ev: Dictionary in driver.frame_events:
			match int(ev.type):
				SimEvents.Type.DAMAGE_APPLIED:
					if mode == Mode.REDUCED and int(ev.amount) < REDUCED_MIN_DAMAGE:
						continue
					_spawn(ev.pos, str(int(ev.amount)), mode)
				SimEvents.Type.DAMAGE_BLOCKED:
					if bool(settings.get("blocked", true)):
						_spawn(ev.pos, "x", mode)
	for i in CAP_FULL:
		if _active[i]:
			_age[i] += delta
			if _age[i] >= LIFE:
				_active[i] = false
	queue_redraw()


## Cap behavior: FULL recycles the oldest slot; REDUCED drops new spawns
## at its (lower) cap — reduced stays quiet under spam by design.
func _spawn(at: Vector2, text: String, mode: int) -> void:
	var cap := CAP_REDUCED if mode == Mode.REDUCED else CAP_FULL
	var slot := -1
	var oldest := -1
	var oldest_age := -1.0
	var used := 0
	for i in CAP_FULL:
		if _active[i]:
			used += 1
			if _age[i] > oldest_age:
				oldest_age = _age[i]
				oldest = i
		elif slot < 0:
			slot = i
	if used >= cap:
		if mode == Mode.REDUCED:
			return
		slot = oldest
	if slot < 0:
		slot = oldest
	_pos[slot] = at
	_text[slot] = text
	_age[slot] = 0.0
	_active[slot] = true


func _draw() -> void:
	if _font == null:
		return
	for i in CAP_FULL:
		if not _active[i]:
			continue
		var t: float = _age[i] / LIFE
		var world_px := _pos[i] * TILE + Vector2(0.0, -8.0 - RISE_TILES * TILE * t)
		var c := Color(1.0, 0.95, 0.85, 1.0 - maxf(0.0, t - 0.5) * 2.0)
		if _text[i] == "x":
			c = Color(0.65, 0.6, 0.75, c.a)
		draw_string(_font, world_px.round(), _text[i], HORIZONTAL_ALIGNMENT_CENTER, -1.0, 10, c)
