extends Node2D
## Hitbox/collision display (docs/12 §2.10): circles drawn FROM SIM
## SHAPES — player, stand-ins, live projectiles, hazard zones. This same
## renderer restyled is the CORE-50 player-facing hitbox indicator; the
## debug styling here is the M4 form. Toggled (default H), persisted.
## Debug-overlay band; view-only.

const ActorState := preload("res://sim/actor_state.gd")
const RenderLayers := preload("res://game/render_layers.gd")

const TILE := 32.0

var world: RefCounted = null

var _friendly := Color(0.4, 1.0, 0.9, 0.9)
var _hostile := Color(1.0, 0.5, 0.4, 0.9)


func _ready() -> void:
	z_index = RenderLayers.DEBUG_OVERLAY


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if world == null:
		return
	for p: RefCounted in world.players:
		draw_arc(p.pos * TILE, p.radius * TILE, 0.0, TAU, 32, _friendly, 1.0)
	for e: RefCounted in world.enemies:
		draw_arc(e.pos * TILE, e.radius * TILE, 0.0, TAU, 32, _hostile, 1.0)
	var pool: RefCounted = world.projectiles
	var act: PackedByteArray = pool.active
	var fac: PackedByteArray = pool.faction
	var px: PackedFloat32Array = pool.pos_x
	var py: PackedFloat32Array = pool.pos_y
	var rad: PackedFloat32Array = pool.radius
	for s in pool.CAPACITY:
		if act[s] == 0:
			continue
		var c := _hostile if fac[s] == ActorState.FACTION_HOSTILE else _friendly
		draw_arc(Vector2(px[s], py[s]) * TILE, rad[s] * TILE, 0.0, TAU, 16, c, 1.0)
	for hz: Dictionary in world.hazards:
		var c2 := _hostile if int(hz.faction) == ActorState.FACTION_HOSTILE else _friendly
		draw_arc(hz.pos * TILE, float(hz.radius) * TILE, 0.0, TAU, 32, c2, 1.0)
