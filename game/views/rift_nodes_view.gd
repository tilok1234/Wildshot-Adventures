extends Node2D
## World-side rift portals (sl-0115 — presentation only): every ACTIVE
## rift node (authored + ambient) draws the prototype's ground portal —
## a squashed dark swirl with spinning biome-colored rings and orbiting
## sparks. The portal SHOWS ITS BIOME before the cast (INDEX ruling #7).
## Near the nearest active portal, a prompt names the biome and the
## cast key ("[F] cast the starhook" — the interact verb; sl-0112 cue
## language). FRIENDLY_GROUND band: a portal is ground dressing, under
## every actor and every threat (Law 1).

const RenderLayers := preload("res://game/render_layers.gd")

const TILE := 32.0
const PROMPT_RANGE := 3.0

const BIOME_NAMES: Array[String] = ["NEBULA DRIFT", "HOLLOW VOID", "COMET FIELD"]
const BIOME_RIMS: Array[Color] = [Color("b56cff"), Color("3a6cff"), Color("a8f0ff")]
const BIOME_ACCENTS: Array[Color] = [Color("d44fb0"), Color("4fd4c8"), Color("7ce8ff")]
const BIOME_DEEPS: Array[Color] = [Color("140a20"), Color("04050e"), Color("061018")]
const STAR_COLS: Array[Color] = [Color("ffffff"), Color("c8a8ff"), Color("bff4ff")]

var world: RefCounted = null
var _prompt: Label = null


func _ready() -> void:
	z_index = RenderLayers.FRIENDLY_GROUND
	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.z_index = RenderLayers.HP_BARS
	_prompt.visible = false
	add_child(_prompt)


func _process(_delta: float) -> void:
	queue_redraw()
	_update_prompt()


func _active_nodes() -> Array:
	var out: Array = []
	var nodes: PackedVector2Array = world.rift_nodes
	for i in nodes.size():
		if world.tick < world.rift_node_respawn_at[i]:
			continue
		var biome: int = world.rift_node_biomes[i] if i < world.rift_node_biomes.size() else 0
		out.append({"pos": nodes[i], "biome": biome})
	for j in world.rift_ambient_pos.size():
		out.append({"pos": world.rift_ambient_pos[j], "biome": int(world.rift_ambient_biome[j])})
	return out


func _update_prompt() -> void:
	if world.players.is_empty():
		_prompt.visible = false
		return
	var p: RefCounted = world.players[0]
	var best_d := PROMPT_RANGE
	var best: Dictionary = {}
	for n: Dictionary in _active_nodes():
		var d: float = p.pos.distance_to(Vector2(n.pos))
		if d < best_d:
			best_d = d
			best = n
	if best.is_empty():
		_prompt.visible = false
		return
	var biome := clampi(int(best.biome), 0, 2)
	_prompt.text = "%s RIFT\n[F] cast the starhook" % BIOME_NAMES[biome]
	_prompt.modulate = BIOME_RIMS[biome]
	var np: Vector2 = Vector2(best.pos) * TILE
	_prompt.position = np + Vector2(-64.0, -44.0)
	_prompt.size = Vector2(128.0, 24.0)
	_prompt.visible = true


func _draw() -> void:
	var t := int(world.tick)
	for n: Dictionary in _active_nodes():
		var biome := clampi(int(n.biome), 0, 2)
		var cp: Vector2 = Vector2(n.pos) * TILE
		var rim := BIOME_RIMS[biome]
		var accent := BIOME_ACCENTS[biome]
		# Ground shadow + squashed swirl (the prototype's portalDraw).
		draw_set_transform(cp + Vector2(0, 3), 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 18.0, Color(0, 0, 0, 0.33))
		draw_set_transform(cp, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 15.0, BIOME_DEEPS[biome])
		for i in 3:
			var spin := float(t) * 0.04 * (1.0 if i % 2 == 0 else -1.3) + float(i) * 2.0
			var col := rim if i == 0 else Color(accent, 0.66 if i == 1 else 0.4)
			draw_arc(Vector2.ZERO, 13.0 - float(i) * 4.0, spin, spin + 3.6, 12, col, 2.0)
		# Orbiting sparks spiralling outward.
		for i in 5:
			var an := float(t) * 0.064 + float(i) * 1.257
			var rr := 3.0 + fposmod(float(t) * 0.7 + float(i) * 17.0, 10.0)
			var sc := STAR_COLS[i % STAR_COLS.size()]
			draw_rect(
				Rect2(
					Vector2(cos(an + rr * 0.2), sin(an + rr * 0.2)) * rr - Vector2.ONE,
					Vector2(2, 2)
				),
				sc,
				true
			)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		draw_circle(cp, 20.0, Color(rim, 0.10))
