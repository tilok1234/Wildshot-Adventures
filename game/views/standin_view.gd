extends MultiMeshInstance2D
## Minimal enemy stand-in renderer (M3 target practice): one quad per live
## sim enemy, rebuilt per frame from world.enemies — kills disappear on
## the tick they land. Real enemies render from Sprite Forge sheets at M5;
## this view dies then. View-only: never mutates sim.

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
	var n := mini(enemies.size(), multimesh.instance_count)
	for i in n:
		var e: RefCounted = enemies[i]
		var sc: float = e.radius * TILE
		multimesh.set_instance_transform_2d(
			i, Transform2D(Vector2(sc, 0.0), Vector2(0.0, sc), e.pos * TILE)
		)
	multimesh.visible_instance_count = n
