extends Control
## THE QUEST OFFER DIALOGUE (menu pass, sl-0144 + the sl-0154
## Later-only rule): F at a giver with an available errand OFFERS it —
## the sim emits QUEST_OFFERED, main opens this window (quest_offer_v2
## spec: panel2 w=300, title plaque with the giver's name, reread
## text, objective, reward, buttons). ACCEPT IS A DECISION: the gold
## primary button, or F again while open [T — F-as-confirm]; it rides
## the RECORDED accept op (radius + capacity guarded sim-side). The
## hands-cap refusal is LOUD (toast) before any op queues. NON-ACCEPT
## = "LATER" ONLY this pass: Later / the close X / Esc / walking away
## all close the window and the quest STAYS with the giver — the
## spec's Decline button is deliberately NOT BUILT (sl-0154). The
## world keeps running; never pauses. View-only.

signal toast_requested(msg: String)

const MenuPalette := preload("res://ui/menu_palette.gd")
const Panel2 := preload("res://ui/panel2.gd")
const IconAtlas := preload("res://ui/icon_atlas.gd")
const CharacterSheet := preload("res://ui/character_sheet.gd")
const QuestStep := preload("res://sim/systems/quest_step.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")

## Giver display names by reason tag [T — designer voice pending;
## plain fallback = the tag upper-cased].
const GIVER_NAMES := {"zone_hub": "THE WARDENS", "waystation": "THE WAYSTATION"}
const BASE_W := 300.0

var world: RefCounted = null
## Queues the recorded accept op (main injects the sampler's queue).
var bag_op_sink := Callable()

var _qi := -1
var _panel: Panel2 = null
var _body: VBoxContainer = null


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = Panel2.new()
	_panel.show_close = true
	_panel.close_requested.connect(dismiss)
	add_child(_panel)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 4)
	_panel.content.add_child(_body)


func wants_suppress() -> bool:
	return visible and _panel.get_global_rect().has_point(get_global_mouse_position())


## Open (or re-target) the window for quest qi.
func offer(qi: int) -> void:
	if world == null or qi < 0 or qi >= world.quest_defs.size():
		return
	if visible and _qi == qi:
		return
	_qi = qi
	_rebuild()
	visible = true


func dismiss() -> void:
	visible = false
	_qi = -1


## The accept decision (button or F-as-confirm). Loud at the cap;
## the recorded op carries the mutation.
func confirm_accept() -> void:
	if not visible or _qi < 0 or world == null or world.players.is_empty():
		return
	var p: RefCounted = world.players[0]
	var taken_count := 0
	for ti in world.quest_defs.size():
		if (p.quests_taken_mask & (1 << ti)) != 0 and (p.quests_done_mask & (1 << ti)) == 0:
			taken_count += 1
	if taken_count >= QuestStep.QUEST_CAP:
		toast_requested.emit("your hands are full — finish or abandon an errand first")
		return
	if bag_op_sink.is_valid():
		bag_op_sink.call(BagStep.OP_ACCEPT_BASE + _qi)


func _process(_delta: float) -> void:
	if not visible or world == null or world.players.is_empty() or _qi < 0:
		return
	var p: RefCounted = world.players[0]
	# Accept landed (the op resolved sim-side) — the moment passes to
	# the toast + the log; the window's job is done.
	if (p.quests_taken_mask & (1 << _qi)) != 0:
		dismiss()
		return
	# Walk-away closes (identical to Later — sl-0154).
	var q: Resource = world.quest_defs[_qi]
	var gc: Vector2 = q.giver_cell
	if p.pos.distance_to(gc) > QuestStep.GIVER_RADIUS + 0.3:
		dismiss()


func _rebuild() -> void:
	var k := maxf(get_theme_default_base_scale(), 1.0)
	var d := CharacterSheet.quest_detail(world, _qi)
	if d.is_empty():
		dismiss()
		return
	var q: Resource = world.quest_defs[_qi]
	_panel.title = (
		"ERRAND — %s" % String(GIVER_NAMES.get(String(q.reason), String(q.reason).to_upper()))
	)
	_panel.title_icon = "quest.available"
	for c in _body.get_children():
		(c as CanvasItem).visible = false
		c.queue_free()
	var text := Label.new()
	text.text = String(d.text)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_color_override("font_color", MenuPalette.TEXT_BRIGHT)
	_body.add_child(text)
	var obj := Label.new()
	obj.text = String(d.objective)
	obj.add_theme_color_override("font_color", MenuPalette.TEXT_DIM)
	_body.add_child(obj)
	var reward := HBoxContainer.new()
	reward.add_theme_constant_override("separation", 4)
	_body.add_child(reward)
	var rlabel := Label.new()
	rlabel.text = "reward"
	rlabel.add_theme_color_override("font_color", MenuPalette.TEXT_DIM)
	reward.add_child(rlabel)
	var gicon := TextureRect.new()
	gicon.texture = IconAtlas.icon("currency.gold")
	gicon.custom_minimum_size = Vector2(16.0, 16.0) * k
	gicon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward.add_child(gicon)
	var rtext := Label.new()
	rtext.text = "%d gold · %d xp" % [int(d.reward_gold), int(d.reward_xp)]
	rtext.add_theme_color_override("font_color", MenuPalette.GOLD)
	reward.add_child(rtext)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	_body.add_child(btns)
	var accept := Button.new()
	accept.text = "Accept"
	accept.add_theme_stylebox_override("normal", _primary_box())
	accept.add_theme_stylebox_override("hover", _primary_box())
	accept.add_theme_color_override("font_color", MenuPalette.GOLD_BRIGHT)
	accept.pressed.connect(confirm_accept)
	btns.add_child(accept)
	var later := Button.new()
	later.text = "Later"
	later.pressed.connect(dismiss)
	btns.add_child(later)
	# Fixed width, height from FONT METRICS (an autowrap label's
	# pre-layout minimum wraps at width 0 and explodes — the first
	# probe run's full-screen slab), centered slightly above
	# mid-screen (the capture's placement).
	var w := BASE_W * k
	var font := get_theme_default_font()
	var fsize := get_theme_default_font_size()
	var text_w := font.get_string_size(String(d.text), HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	var lines := ceili(text_w / maxf(w - 40.0 * k, 1.0))
	var h := (78.0 + 13.0 * float(lines)) * k
	_panel.position = Vector2((size.x - w) * 0.5, size.y * 0.5 - h * 0.62)
	_panel.size = Vector2(w, h)


## The gold-framed primary look (the workbench's default-choice
## button).
static func _primary_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = MenuPalette.PLAQUE_BOTTOM
	sb.border_color = MenuPalette.GOLD
	sb.set_border_width_all(1)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	return sb
