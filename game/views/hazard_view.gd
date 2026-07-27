extends Node2D
## Hazard/telegraph renderer: zones draw their pack sprite (rim opaque at
## the TRUE collision boundary — the pack asserts it) plus the 8-step
## arm-progress ring from the strip, scaled to the live radius. Friendly
## zones (Blast Rune) use the friendly zone sprite and a cool-modulated
## arm ring per the pack notes. Falls back to primitive circles when the
## pack is absent (Law 8 never depends on art). Reads world.hazards each
## frame; view-only.

const RenderLayers := preload("res://game/render_layers.gd")

const TILE := 32.0

var world: RefCounted = null
## ProjectileSprites library + projectile_map resource (optional).
var sprites: RefCounted = null
var pattern_map: Resource = null

var _friendly_rim := Color(0.55, 0.75, 1.0, 0.9)
var _friendly_fill := Color(0.4, 0.6, 1.0, 0.12)
var _hostile_rim := Color(1.0, 0.32, 0.2, 0.95)
var _hostile_fill := Color(1.0, 0.3, 0.2, 0.14)
const ARM_COOL_MODULATE := Color(0.6, 0.78, 1.0, 0.95)


func _ready() -> void:
	# Only FRIENDLY zones exist until M6 (Blast Rune) — band 2. When
	# hostile hazards land, fills and rims split into their own nodes
	# (HOSTILE_HAZARD_FILL vs HOSTILE_TELEGRAPH_RIMS) per §2.5.
	z_index = RenderLayers.FRIENDLY_GROUND


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if world == null:
		return
	var t: int = world.tick
	for hz: Dictionary in world.hazards:
		var pos: Vector2 = hz.pos * TILE
		var r: float = float(hz.radius) * TILE
		var hostile: bool = int(hz.faction) == 1
		var arm_at: int = int(hz.arm_at_tick)
		var total: float = maxf(1.0, float(arm_at - int(hz.placed_at_tick)))
		var progress := clampf(1.0 - float(arm_at - t) / total, 0.0, 1.0)

		var zone_entry := _zone_entry(hostile)
		if not zone_entry.is_empty():
			var rect := Rect2(pos - Vector2(r, r), Vector2(r * 2.0, r * 2.0))
			draw_texture_rect(zone_entry.tex, rect, false)
			var strip := _strip_entry()
			if not strip.is_empty():
				var frames := int(strip.frames)
				var fw := float(strip.w) / float(frames)
				var k := clampi(int(progress * float(frames)), 0, frames - 1)
				var region := Rect2(fw * k, 0.0, fw, float(strip.h))
				draw_texture_rect_region(
					strip.tex, rect, region, ARM_COOL_MODULATE if not hostile else Color.WHITE
				)
			continue

		# Primitive fallback: rim + fill + sweeping arm arc (Law 8 holds
		# with zero art installed).
		draw_circle(pos, r, _hostile_fill if hostile else _friendly_fill)
		draw_arc(pos, r, 0.0, TAU, 48, _hostile_rim if hostile else _friendly_rim, 1.0)
		if progress > 0.0:
			draw_arc(
				pos,
				r - 2.0,
				-PI / 2.0,
				-PI / 2.0 + TAU * progress,
				48,
				_hostile_rim if hostile else _friendly_rim,
				2.0
			)


## Zone sprite for the faction, {} when unmapped. Zones are keyed by
## pattern in the map (-2 Blast Rune, 15 blight) — faction picks between
## them until hazards carry pattern ids (M6).
func _zone_entry(hostile: bool) -> Dictionary:
	if sprites == null or pattern_map == null:
		return {}
	var pid := 15 if hostile else -2
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
