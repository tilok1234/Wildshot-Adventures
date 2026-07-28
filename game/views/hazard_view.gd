extends Node2D
## Hazard/telegraph renderer: zones draw their pack sprite (rim opaque at
## the TRUE collision boundary — the pack asserts it) plus the 8-step
## arm-progress ring from the strip, scaled to the live radius. Friendly
## zones (Blast Rune) use the friendly zone sprite and a cool-modulated
## arm ring per the pack notes. Falls back to primitive circles when the
## pack is absent (Law 8 never depends on art). Reads world.hazards each
## frame; view-only.
##
## M6 split per §2.5: one instance per mode. FRIENDLY draws whole
## friendly zones at FRIENDLY_GROUND; hostile zones split across two
## bands — HOSTILE_FILL (zone sprite/fill: spatial grounding under
## bodies, never the sole signal) and HOSTILE_RIM (arm strip/rim/
## progress: the warning, above everything per Law 1).
##
## BURNING state (M6 EffectLibrary pass, closes ledger #14): an armed
## LINGERING zone pulses on a deterministic cadence the sim already
## serializes (next_damage_tick / hit_interval), so the view renders
## truth instead of a static full ring — the arm strip refills toward
## each pulse (the between-pulse window is honestly crossable and the
## refill teaches exactly that) over a solid armed rim, and the fill
## gains an additive hot swell as the bite approaches. Emphasis only:
## nothing hostile ever renders below its pre-arm visibility (Law 1).
## One-shot zones (Blast Rune) expire on their arm tick and never
## reach the burning branch — M4 behavior untouched.

enum Mode { FRIENDLY, HOSTILE_FILL, HOSTILE_RIM }

const RenderLayers := preload("res://game/render_layers.gd")

const TILE := 32.0

var world: RefCounted = null
## ProjectileSprites library + projectile_map resource (optional).
var sprites: RefCounted = null
var pattern_map: Resource = null
var mode: int = Mode.FRIENDLY
## EffectLibrary — FRIENDLY instance only (main.gd wires it that way);
## the hostile fill/rim instances never hold the reference (§2.6 clamp).
var effects: RefCounted = null

var _friendly_rim := Color(0.55, 0.75, 1.0, 0.9)
var _friendly_fill := Color(0.4, 0.6, 1.0, 0.12)
var _hostile_rim := Color(1.0, 0.32, 0.2, 0.95)
var _hostile_fill := Color(1.0, 0.3, 0.2, 0.14)
const ARM_COOL_MODULATE := Color(0.6, 0.78, 1.0, 0.95)
## Peak extra alpha of the burning fill swell at the pulse tick.
const BURN_SWELL_ALPHA := 0.12


func _ready() -> void:
	match mode:
		Mode.HOSTILE_FILL:
			z_index = RenderLayers.HOSTILE_HAZARD_FILL
		Mode.HOSTILE_RIM:
			z_index = RenderLayers.HOSTILE_TELEGRAPH_RIMS
		_:
			z_index = RenderLayers.FRIENDLY_GROUND


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if world == null:
		return
	var t: int = world.tick
	var want_hostile: bool = mode != Mode.FRIENDLY
	# FRIENDLY-channel opacity (EffectLibrary; null on hostile instances
	# by wiring — reading it here on a hostile band is impossible).
	var fa: float = effects.friendly_alpha() if effects != null else 1.0
	for hz: Dictionary in world.hazards:
		var hostile: bool = int(hz.faction) == 1
		if hostile != want_hostile:
			continue
		var pos: Vector2 = hz.pos * TILE
		var r: float = float(hz.radius) * TILE
		var arm_at: int = int(hz.arm_at_tick)
		var total: float = maxf(1.0, float(arm_at - int(hz.placed_at_tick)))
		var progress := clampf(1.0 - float(arm_at - t) / total, 0.0, 1.0)
		var rect := Rect2(pos - Vector2(r, r), Vector2(r * 2.0, r * 2.0))

		# Burning: armed AND lingering (one-shots expire at arm and
		# never get here). The strip refills toward the NEXT pulse.
		var burning: bool = t >= arm_at and int(hz.linger_until) > arm_at
		var pulse_prog := 0.0
		if burning:
			var interval := maxi(1, int(hz.hit_interval_ticks))
			var until_pulse := clampi(int(hz.next_damage_tick) - t, 0, interval)
			pulse_prog = 1.0 - float(until_pulse) / float(interval)

		var zone_entry := _zone_entry(hz, hostile)
		if mode != Mode.HOSTILE_RIM:
			var fill_mod := Color(1.0, 1.0, 1.0, fa) if not hostile else Color.WHITE
			if not zone_entry.is_empty():
				draw_texture_rect(zone_entry.tex, rect, false, fill_mod)
			else:
				var fc: Color = _hostile_fill if hostile else _friendly_fill
				fc.a *= fa if not hostile else 1.0
				draw_circle(pos, r, fc)
			if burning and hostile:
				# Additive hot swell toward the bite — emphasis on top of
				# the base fill, never a reduction (Law 1).
				var swell: Color = _hostile_rim
				swell.a = BURN_SWELL_ALPHA * pulse_prog
				draw_circle(pos, r, swell)
		if mode != Mode.HOSTILE_FILL:
			var strip := _strip_entry()
			var strip_prog := pulse_prog if burning else progress
			if burning:
				# Armed base under the refilling strip: the zone stays
				# unmistakably live between pulses.
				draw_arc(pos, r, 0.0, TAU, 48, _hostile_rim if hostile else _friendly_rim, 2.0)
			if not zone_entry.is_empty() and not strip.is_empty():
				var frames := int(strip.frames)
				var fw := float(strip.w) / float(frames)
				var k := clampi(int(strip_prog * float(frames)), 0, frames - 1)
				var region := Rect2(fw * k, 0.0, fw, float(strip.h))
				var rim_mod: Color = ARM_COOL_MODULATE if not hostile else Color.WHITE
				if not hostile:
					rim_mod.a *= fa
				draw_texture_rect_region(strip.tex, rect, region, rim_mod)
			else:
				# Primitive fallback: rim + sweeping arc (Law 8 holds
				# with zero art installed).
				var rim_c: Color = _hostile_rim if hostile else _friendly_rim
				if not hostile:
					rim_c.a *= fa
				draw_arc(pos, r, 0.0, TAU, 48, rim_c, 1.0)
				if strip_prog > 0.0:
					draw_arc(pos, r - 2.0, -PI / 2.0, -PI / 2.0 + TAU * strip_prog, 48, rim_c, 2.0)


## Zone sprite for a hazard, {} when unmapped. Keyed by the hazard's own
## pattern id (hazards carry them since SERIAL 11); pattern-less or
## unmapped hazards fall back to the faction default (15 hostile /
## -2 Blast Rune) so nothing ever loses its zone skin.
func _zone_entry(hz: Dictionary, hostile: bool) -> Dictionary:
	if sprites == null or pattern_map == null:
		return {}
	var pid := int(hz.get("pattern", -99))
	if not pattern_map.zones.has(pid):
		pid = 15 if hostile else -2
	if not pattern_map.zones.has(pid):
		return {}
	var sid := String(pattern_map.zones[pid])
	return sprites.entry(sid) if sprites.has_sprite(sid) else {}


func _strip_entry() -> Dictionary:
	if sprites == null or pattern_map == null:
		return {}
	var sid := String(pattern_map.arm_strip)
	if sid.is_empty() or not sprites.has_sprite(sid):
		return {}
	return sprites.entry(sid)
