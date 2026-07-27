extends Node2D
## Projectile renderer: one MultiMeshInstance2D per faction (the §2.6
## per-family split arrives with the M-FX effects language). Both factions
## draw a small procedural sphere sized EXACTLY to the collision circle —
## visual = hitbox, the honest Law 8 placeholder (designer call: simple
## small sphere). Hostile renders from a SEPARATE node added above
## friendly, so player shots stay visually subordinate and content cannot
## violate layering structurally (CORE-51 Laws 2/3, §2.5); the shared
## hostile signature replaces the plain red tint at M-FX/M6. Positions
## interpolate prev→curr per the §2.9 toggle. View-only: reads the pool,
## never mutates.

const ActorState := preload("res://sim/actor_state.gd")

const TILE := 32.0
const SPHERE_TEX_PX := 16

var world: RefCounted = null
var clock: RefCounted = null

var _friendly := MultiMeshInstance2D.new()
var _hostile := MultiMeshInstance2D.new()
var _allocated := false


func _ready() -> void:
	var sphere := _make_sphere_texture()
	_setup_mmi(_friendly, Color(0.82, 0.9, 1.0), sphere)
	_setup_mmi(_hostile, Color(1.0, 0.36, 0.28), sphere)
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


static func _setup_mmi(mmi: MultiMeshInstance2D, color: Color, tex: Texture2D) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)  # unit quad; instance scale = radius*TILE
	mm.mesh = quad
	mmi.multimesh = mm
	mmi.modulate = color
	mmi.texture = tex


## Small white sphere: filled circle with an up-left highlight and a hard
## pixel edge (Nearest filtering keeps it crisp). Faction color comes from
## node modulate.
static func _make_sphere_texture() -> ImageTexture:
	var img := Image.create(SPHERE_TEX_PX, SPHERE_TEX_PX, false, Image.FORMAT_RGBA8)
	var c := (SPHERE_TEX_PX - 1) / 2.0
	for y in SPHERE_TEX_PX:
		for x in SPHERE_TEX_PX:
			var d := Vector2(x - c, y - c).length() / c
			if d > 1.0:
				continue
			var hl := Vector2(x - c + c * 0.35, y - c + c * 0.35).length() / c
			var b := clampf(1.1 - 0.5 * hl, 0.55, 1.0)
			img.set_pixel(x, y, Color(b, b, b, 1.0))
	return ImageTexture.create_from_image(img)
