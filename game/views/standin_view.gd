extends MultiMeshInstance2D
## Minimal enemy stand-in renderer (M3 target practice / M2 stress): one
## quad per live INERT stand-in (def_index -1), rebuilt per frame. Real
## enemies (def_index >= 0) render from assembler sheets in
## enemy_actors_view — never here. View-only: never mutates sim.

const RenderLayers := preload("res://game/render_layers.gd")

const TILE := 32.0

var world: RefCounted = null


func _ready() -> void:
	z_index = RenderLayers.ACTORS
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	mm.mesh = quad
	mm.instance_count = 64
	multimesh = mm
	modulate = Color(0.62, 0.32, 0.32)


func _process(_delta: float) -> void:
	if world == null:
		return
	var enemies: Array = world.enemies
	var n := 0
	for e: RefCounted in enemies:
		if e.def_index >= 0:
			continue
		if n >= multimesh.instance_count:
			break
		var sc: float = e.radius * TILE
		multimesh.set_instance_transform_2d(
			n, Transform2D(Vector2(sc, 0.0), Vector2(0.0, sc), e.pos * TILE)
		)
		n += 1
	multimesh.visible_instance_count = n
