extends Node2D
## Projectile renderer — M2 rig form, the seed of the §2.6 per-family
## renderer. One MultiMeshInstance2D per faction: hostile and friendly
## render from SEPARATE nodes so content cannot violate layering
## structurally, and hostile draws above friendly — player shots are
## visually subordinate to enemy fire (CORE-51 Laws 2/3, §2.5 bands 5/7).
## Flat greybox quads for now; family sprite sheets and the shared hostile
## signature arrive with M-FX/M6 behind EffectLibrary. Positions
## interpolate prev→curr per the §2.9 toggle. View-only: reads the pool,
## never mutates it.

const ActorState := preload("res://sim/actor_state.gd")

const TILE := 32.0

var world: RefCounted = null
var clock: RefCounted = null

var _friendly := MultiMeshInstance2D.new()
var _hostile := MultiMeshInstance2D.new()
var _allocated := false


func _ready() -> void:
	_setup_mmi(_friendly, Color(0.72, 0.84, 1.0, 0.85))
	_setup_mmi(_hostile, Color(1.0, 0.32, 0.22))
	add_child(_friendly)
	add_child(_hostile)


func _process(_delta: float) -> void:
	if world == null:
		return
	var pool: RefCounted = world.projectiles
	if not _allocated:
		_friendly.multimesh.instance_count = pool.CAPACITY
		_hostile.multimesh.instance_count = pool.CAPACITY
		_allocated = true
	var interp: bool = clock != null and clock.interp_enabled
	var alpha: float = clock.alpha() if clock != null else 1.0
	var px: PackedFloat32Array = pool.pos_x
	var py: PackedFloat32Array = pool.pos_y
	var qx: PackedFloat32Array = pool.prev_x
	var qy: PackedFloat32Array = pool.prev_y
	var rad: PackedFloat32Array = pool.radius
	var fac: PackedByteArray = pool.faction
	var act: PackedByteArray = pool.active
	var mm_f: MultiMesh = _friendly.multimesh
	var mm_h: MultiMesh = _hostile.multimesh
	var n_f := 0
	var n_h := 0
	for s in pool.CAPACITY:
		if act[s] == 0:
			continue
		var x: float = px[s]
		var y: float = py[s]
		if interp:
			x = qx[s] + (x - qx[s]) * alpha
			y = qy[s] + (y - qy[s]) * alpha
		var sc: float = rad[s] * TILE
		var xf := Transform2D(Vector2(sc, 0.0), Vector2(0.0, sc), Vector2(x, y) * TILE)
		if fac[s] == ActorState.FACTION_HOSTILE:
			mm_h.set_instance_transform_2d(n_h, xf)
			n_h += 1
		else:
			mm_f.set_instance_transform_2d(n_f, xf)
			n_f += 1
	mm_f.visible_instance_count = n_f
	mm_h.visible_instance_count = n_h


static func _setup_mmi(mmi: MultiMeshInstance2D, color: Color) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)  # unit-ish quad; instance transform scales by radius*TILE
	mm.mesh = quad
	mmi.multimesh = mm
	mmi.modulate = color
