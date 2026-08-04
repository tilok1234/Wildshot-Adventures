extends Node2D
## World-side FORAGE nodes (sl-0198 — presentation only): every LIVE
## ambient forage node draws a VISIBLE SHIMMER over its prop cell
## (WYSIWYG — a marked stump/log/bush is gatherable, an unmarked one
## is scenery): a soft green-gold ground glow + rising sparkle motes,
## tick-animated, per-node phase from the cell (deterministic view,
## no RNG). Near the nearest live node a prompt names the species and
## the gather key ("[F] forage — bush"; plain overworld words — the
## cosmic rail is starhook-lane-only). While a player gathers, the
## GATHER BAR draws AT THE NODE (progress = sim state
## forage_ticks/bar_ticks; the bar interrupts sim-side on move/hit).
## FRIENDLY_GROUND band: ground dressing under every actor and every
## threat (Law 1); the bar + prompt ride HP_BARS like every readout.

const RenderLayers := preload("res://game/render_layers.gd")

const TILE := 32.0
const PROMPT_RANGE := 2.5

const GLOW := Color("7dd87a")
const GOLD := Color("e8c86a")
const MOTE_COLS: Array[Color] = [Color("d8f0b8"), Color("fff2c0"), Color("a8e89a")]

var world: RefCounted = null
var _prompt: Label = null
## The gather bar's own canvas item: readouts ride HP_BARS (below all
## hostile bands by construction — Law 1 structural, like every bar).
var _bar_layer: Node2D = null


func _ready() -> void:
	z_index = RenderLayers.FRIENDLY_GROUND
	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.z_index = RenderLayers.HP_BARS
	_prompt.visible = false
	add_child(_prompt)
	_bar_layer = Node2D.new()
	_bar_layer.z_index = RenderLayers.HP_BARS
	_bar_layer.draw.connect(_draw_bars)
	add_child(_bar_layer)


func _process(_delta: float) -> void:
	queue_redraw()
	_bar_layer.queue_redraw()
	_update_prompt()


func _species_name(si: int) -> String:
	var ids: Array = world.forage_species_ids
	if si >= 0 and si < ids.size():
		return String(ids[si]).replace("_", " ")
	return "forage"


func _update_prompt() -> void:
	if world.players.is_empty():
		_prompt.visible = false
		return
	var p: RefCounted = world.players[0]
	var nodes: PackedVector2Array = world.forage_nodes_pos
	var best := -1
	var best_d := PROMPT_RANGE
	for i in nodes.size():
		var d: float = p.pos.distance_to(nodes[i])
		if d < best_d:
			best_d = d
			best = i
	if best < 0:
		_prompt.visible = false
		return
	var gathering: bool = p.forage_target == nodes[best]
	_prompt.text = (
		"gathering..."
		if gathering
		else "[F] forage — %s" % _species_name(int(world.forage_nodes_species[best]))
	)
	_prompt.modulate = GOLD if gathering else GLOW
	var np: Vector2 = nodes[best] * TILE
	_prompt.position = np + Vector2(-64.0, -40.0)
	_prompt.size = Vector2(128.0, 24.0)
	_prompt.visible = true


func _draw() -> void:
	var t := int(world.tick)
	var nodes: PackedVector2Array = world.forage_nodes_pos
	for i in nodes.size():
		var cp: Vector2 = nodes[i] * TILE
		# Per-node phase from the cell itself (stable, deterministic).
		var phase := int(nodes[i].x * 7.0 + nodes[i].y * 13.0)
		var pulse := 0.5 + 0.5 * sin(float(t + phase * 9) * 0.05)
		# Soft ground glow (squashed — it sits ON the prop's base).
		draw_set_transform(cp + Vector2(0, 4), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 13.0 + 2.0 * pulse, Color(GLOW, 0.18 + 0.10 * pulse))
		draw_arc(
			Vector2.ZERO, 11.0 + 2.0 * pulse, 0.0, TAU, 20, Color(GOLD, 0.35 + 0.25 * pulse), 1.5
		)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		# Rising sparkle motes (three lanes, looping upward).
		for m in 3:
			var mt := fposmod(float(t) * 0.011 + float(m) * 0.33 + float(phase % 7) * 0.09, 1.0)
			var mx := sin(float(t) * 0.03 + float(m * 2 + phase)) * 6.0
			var mp := cp + Vector2(mx, 6.0 - mt * 26.0)
			var mc: Color = MOTE_COLS[(m + phase) % MOTE_COLS.size()]
			draw_rect(Rect2(mp - Vector2.ONE, Vector2(2, 2)), Color(mc, 1.0 - mt), true)


## THE GATHER BAR at the node (HP_BARS band): progress is pure sim
## state — forage_ticks / bar_ticks [T]; the sim owns the interrupts.
func _draw_bars() -> void:
	var bar_ticks := maxi(
		1, int((world.stat_frame.get("forage", {}) as Dictionary).get("bar_ticks", 45))
	)
	for p: RefCounted in world.players:
		if _forage_node_index(p.forage_target) < 0:
			continue
		var frac: float = clampf(float(p.forage_ticks) / float(bar_ticks), 0.0, 1.0)
		var bw := 26.0
		var bp: Vector2 = p.forage_target * TILE + Vector2(-bw * 0.5, -22.0)
		_bar_layer.draw_rect(
			Rect2(bp - Vector2(1, 1), Vector2(bw + 2.0, 5.0)), Color(0, 0, 0, 0.65), true
		)
		_bar_layer.draw_rect(Rect2(bp, Vector2(bw * frac, 3.0)), GOLD, true)


func _forage_node_index(cell: Vector2) -> int:
	var nodes: PackedVector2Array = world.forage_nodes_pos
	for i in nodes.size():
		if nodes[i] == cell:
			return i
	return -1
