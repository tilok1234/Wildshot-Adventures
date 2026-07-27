extends Node2D
## Muzzle + impact flashes — placeholder punch feedback (per-channel
## feedback toggles and the real effects language land at M4/M-FX; this
## is an EffectLibrary-shaped stopgap under ledger #5). Consumes the
## driver's per-frame event relay: ATTACK_STARTED pops a small flash at
## the muzzle, HIT_LANDED a warmer one at the target. View-only, budget-
## trivial (fixed 48-slot pool), and — per CORE-32's feedback clause — no
## screen shake, no hit-stop, ever.

const SimEvents := preload("res://sim/events.gd")

const TILE := 32.0
const POOL := 48
const MUZZLE_LIFE := 0.09
const IMPACT_LIFE := 0.14

var driver: Node = null

var _pos: Array[Vector2] = []
var _age: Array[float] = []
var _life: Array[float] = []
var _size: Array[float] = []
var _color: Array[Color] = []
var _head := 0


func _ready() -> void:
	_pos.resize(POOL)
	_age.resize(POOL)
	_life.resize(POOL)
	_size.resize(POOL)
	_color.resize(POOL)
	for i in POOL:
		_age[i] = 1.0e9
		_life[i] = 1.0


func _process(delta: float) -> void:
	if driver != null:
		for ev: Dictionary in driver.frame_events:
			match int(ev.type):
				SimEvents.Type.ATTACK_STARTED:
					var muzzle: Vector2 = ev.pos + ev.aim * 0.45
					_spawn(muzzle * TILE, 5.0, Color(1.0, 0.98, 0.85), MUZZLE_LIFE)
				SimEvents.Type.HIT_LANDED:
					_spawn(ev.pos * TILE, 7.0, Color(1.0, 0.85, 0.55), IMPACT_LIFE)
	for i in POOL:
		_age[i] += delta
	queue_redraw()


## Live flash count — reported to the density meter against effects_max.
func active_count() -> int:
	var n := 0
	for i in POOL:
		if _age[i] < _life[i]:
			n += 1
	return n


func _spawn(px: Vector2, size: float, color: Color, life: float) -> void:
	_pos[_head] = px
	_age[_head] = 0.0
	_life[_head] = life
	_size[_head] = size
	_color[_head] = color
	_head = (_head + 1) % POOL


func _draw() -> void:
	for i in POOL:
		var t: float = _age[i] / _life[i]
		if t >= 1.0:
			continue
		# Quick pop: expand fast, fade out.
		var r: float = _size[i] * (0.6 + 0.4 * t)
		var c: Color = _color[i]
		c.a = 1.0 - t
		draw_circle(_pos[i], r, c)
