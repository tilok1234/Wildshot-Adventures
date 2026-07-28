extends Node2D
## Muzzle + impact flashes + the Nova cast ring (M6 EffectLibrary pass,
## ledger #9 — the cast ring's procedural stopgap is retired; generic
## pops stay procedural under the same governance). Consumes the
## driver's per-frame event relay: ATTACK_STARTED pops a small flash at
## the muzzle, HIT_LANDED a warmer one at the target, ABILITY_CAST of a
## NOVA-kind ability draws the pack's ring sprite expanding to the
## ability's radius. Everything here is the COSMETIC channel: spawn
## gating (effect density), alpha (effect opacity), and flash reduction
## all come from the EffectLibrary. View-only, budget-counted, and —
## per CORE-32's feedback clause — no screen shake, no hit-stop, ever.

const SimEvents := preload("res://sim/events.gd")
const RenderLayers := preload("res://game/render_layers.gd")
const AbilityDef := preload("res://data/ability_def.gd")

const TILE := 32.0
const POOL := 48
const MUZZLE_LIFE := 0.09
const IMPACT_LIFE := 0.14
const KILL_LIFE := 0.22
const RING_POOL := 8
const RING_LIFE := 0.35
## Ring starts at this fraction of the ability radius and eases out.
const RING_START := 0.35

var driver: Node = null
var world: RefCounted = null
## Shared feedback settings (keys: "impact", "kill" — bools). Channel
## gates are presentation-only; the sim never knows (§2.10).
var settings: Dictionary = {}
## EffectLibrary (cosmetic channel governance); null = ungoverned.
var effects: RefCounted = null
## ProjectileSprites library + projectile_map (nova ring sprite).
var sprites: RefCounted = null
var pattern_map: Resource = null

var _pos: Array[Vector2] = []
var _age: Array[float] = []
var _life: Array[float] = []
var _size: Array[float] = []
var _color: Array[Color] = []
var _head := 0

var _ring_pos: Array[Vector2] = []
var _ring_age: Array[float] = []
var _ring_radius: Array[float] = []
var _ring_head := 0


func _ready() -> void:
	z_index = RenderLayers.PLAYER_PROJECTILES
	_pos.resize(POOL)
	_age.resize(POOL)
	_life.resize(POOL)
	_size.resize(POOL)
	_color.resize(POOL)
	for i in POOL:
		_age[i] = 1.0e9
		_life[i] = 1.0
	_ring_pos.resize(RING_POOL)
	_ring_age.resize(RING_POOL)
	_ring_radius.resize(RING_POOL)
	for i in RING_POOL:
		_ring_age[i] = 1.0e9


func _process(delta: float) -> void:
	if driver != null:
		var impact_on := bool(settings.get("impact", true))
		var kill_on := bool(settings.get("kill", true))
		for ev: Dictionary in driver.frame_events:
			match int(ev.type):
				SimEvents.Type.ATTACK_STARTED:
					if impact_on and _keep():
						var muzzle: Vector2 = ev.pos + ev.aim * 0.45
						_spawn(muzzle * TILE, 5.0, Color(1.0, 0.98, 0.85), MUZZLE_LIFE)
				SimEvents.Type.HIT_LANDED:
					if impact_on and _keep():
						_spawn(ev.pos * TILE, 7.0, Color(1.0, 0.85, 0.55), IMPACT_LIFE)
				SimEvents.Type.ENTITY_KILLED:
					if kill_on and _keep():
						_spawn(ev.pos * TILE, 12.0, Color(1.0, 0.75, 0.4), KILL_LIFE)
				SimEvents.Type.ABILITY_CAST:
					var r := _nova_radius(String(ev.ability))
					if r > 0.0 and _keep():
						_spawn_ring(Vector2(ev.pos) * TILE, r * TILE)
	for i in POOL:
		_age[i] += delta
	for i in RING_POOL:
		_ring_age[i] += delta
	queue_redraw()


## Live flash + ring count — reported to the density meter vs effects_max.
func active_count() -> int:
	var n := 0
	for i in POOL:
		if _age[i] < _life[i]:
			n += 1
	for i in RING_POOL:
		if _ring_age[i] < RING_LIFE:
			n += 1
	return n


## Cosmetic density gate (EffectLibrary); ungoverned when absent.
func _keep() -> bool:
	return effects == null or effects.keep_cosmetic()


## The cast ability's radius when it is a NOVA kind, else 0 (only novas
## draw a ring). Looked up by id in the world's ability defs — the event
## stays lean and the sim stays ignorant of presentation.
func _nova_radius(ability_id: String) -> float:
	if world == null:
		return 0.0
	for def: Resource in world.ability_defs:
		if String(def.id) == ability_id:
			if int(def.kind) == AbilityDef.Kind.NOVA:
				return float(def.radius)
			return 0.0
	return 0.0


func _spawn(px: Vector2, size: float, color: Color, life: float) -> void:
	var size_scale: float = effects.flash_size_scale() if effects != null else 1.0
	var life_scale: float = effects.flash_life_scale() if effects != null else 1.0
	_pos[_head] = px
	_age[_head] = 0.0
	_life[_head] = life * life_scale
	_size[_head] = size * size_scale
	_color[_head] = color
	_head = (_head + 1) % POOL


func _spawn_ring(px: Vector2, radius_px: float) -> void:
	_ring_pos[_ring_head] = px
	_ring_age[_ring_head] = 0.0
	_ring_radius[_ring_head] = radius_px
	_ring_head = (_ring_head + 1) % RING_POOL


func _draw() -> void:
	var alpha_scale: float = effects.cosmetic_alpha() if effects != null else 1.0
	for i in POOL:
		var t: float = _age[i] / _life[i]
		if t >= 1.0:
			continue
		# Quick pop: expand fast, fade out.
		var r: float = _size[i] * (0.6 + 0.4 * t)
		var c: Color = _color[i]
		c.a = (1.0 - t) * alpha_scale
		draw_circle(_pos[i], r, c)
	var ring := _ring_entry()
	for i in RING_POOL:
		var t2: float = _ring_age[i] / RING_LIFE
		if t2 >= 1.0:
			continue
		# Ease-out expansion to the ability radius, fading as it lands.
		var k := 1.0 - (1.0 - t2) * (1.0 - t2)
		var r2: float = _ring_radius[i] * (RING_START + (1.0 - RING_START) * k)
		var a: float = (1.0 - t2) * alpha_scale
		if not ring.is_empty():
			var rect := Rect2(_ring_pos[i] - Vector2(r2, r2), Vector2(r2 * 2.0, r2 * 2.0))
			draw_texture_rect(ring.tex, rect, false, Color(1.0, 1.0, 1.0, a))
		else:
			# Procedural fallback (cosmetic — Law 8 never depended on it).
			draw_arc(_ring_pos[i], r2, 0.0, TAU, 48, Color(0.7, 0.85, 1.0, a), 3.0)


func _ring_entry() -> Dictionary:
	if sprites == null or pattern_map == null:
		return {}
	var sid := String(pattern_map.nova_ring)
	if sid.is_empty() or not sprites.has_sprite(sid):
		return {}
	return sprites.entry(sid)
