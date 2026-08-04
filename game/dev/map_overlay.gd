extends Control
## Dev-profile world-map overlay (sl-0065): renders the active
## WorldForge pack's OWN minimap.png — raw texture, zero new art —
## with the player position dot and a facing tick (current free aim).
## One key cycles off -> corner minimap -> fullscreen map.
##
## Profile law: constructed ONLY from main's gated block (construction
## site and toggle line pinned by tools/lockdown_lint.py), so tester
## artifacts never contain this node. Scenarios without a pack minimap
## never attach it — hidden by absence, not by flag. This is NOT the
## Part II player map (doc 13 §3 keeps map/minimap deferred to their
## own designed round: fog-of-war, markers-vs-learning, CORE-50/Law-6
## HUD treatment); this overlay is throwaway-by-design for the
## huge-world test loop.
##
## Law 6 discipline even in dev: the corner variant is small and
## dimmed — never the brightest thing on screen; fullscreen is a
## deliberate look-at-the-map mode over a darkened backdrop. If
## minimap.png resolution proves insufficient on screen, that is a
## WorldForge ask — never a game-side upscale hack (integer
## nearest-neighbor display scaling of the shipped pixels only).

enum Mode { OFF, CORNER, FULL }

const QuestGiverIcons := preload("res://game/views/quest_giver_icons.gd")

const FULL_MARGIN := 12.0
const CORNER_EDGE := 96.0
## Inset keeps the corner variant clear of the hints line (bottom).
const CORNER_INSET := Vector2(4.0, 16.0)
## Seam B (sl-0109): the corner minimap lives TOP-RIGHT under the
## bars now; main feeds the top inset (it knows the UI scale) [T].
var corner_top_inset := 34.0

var world: RefCounted = null  # SimWorld — player position, read-only
var mouse_tile := Callable()  # viewport mouse in tile space (facing tick)
var grid_size := Vector2i.ONE  # pack cell dims (arena def width/height)
var mode: int = Mode.OFF
var _tex: ImageTexture = null
## Config autoload (tracked-quest binding); probes NULL this after the
## first frame (gotcha 41: the node exists under --script runs).
var _cfg: Node = null


func _ready() -> void:
	visible = false
	# Never intercept input: aiming and firing continue under the map.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cfg = get_node_or_null("/root/Config")


## Raw pack texture or nothing: a missing/unreadable minimap.png
## returns false and the caller drops the overlay entirely.
func load_minimap(path: String) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		return false
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		return false
	_tex = ImageTexture.create_from_image(img)
	return true


func cycle() -> void:
	mode = (mode + 1) % Mode.size()
	visible = mode != Mode.OFF
	queue_redraw()
	print("map: ", ["off", "corner", "fullscreen"][mode])


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()  # the dot tracks the live sim position


## Pack-relative mapping: world tile -> minimap pixel. The ratio comes
## from the actual texture vs the actual grid every time (b65/b77 ship
## 1 px per cell; nothing here assumes it).
static func tile_to_map_px(pos: Vector2, grid: Vector2i, tex: Vector2i) -> Vector2:
	var g := Vector2(maxi(grid.x, 1), maxi(grid.y, 1))
	return pos * Vector2(tex) / g


func _draw() -> void:
	if _tex == null or mode == Mode.OFF:
		return
	var vp := get_viewport_rect().size
	var ts := Vector2(_tex.get_width(), _tex.get_height())
	var rect: Rect2
	if mode == Mode.FULL:
		# Integer upscale when the map fits (crisp cells); fractional
		# fit only when the map outsizes the viewport.
		var fit := minf((vp.x - FULL_MARGIN * 2.0) / ts.x, (vp.y - FULL_MARGIN * 2.0) / ts.y)
		var s := floorf(fit) if fit >= 1.0 else maxf(fit, 0.05)
		rect = Rect2(((vp - ts * s) * 0.5).floor(), ts * s)
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0.0, 0.0, 0.0, 0.55))
		draw_texture_rect(_tex, rect, false)
		draw_rect(rect, Color(0.8, 0.8, 0.8, 0.8), false, 1.0)
	else:
		var s2 := CORNER_EDGE / maxf(ts.x, ts.y)
		var sz := ts * s2
		rect = Rect2(Vector2(vp.x - sz.x - CORNER_INSET.x, corner_top_inset).floor(), sz)
		draw_texture_rect(_tex, rect, false, Color(1.0, 1.0, 1.0, 0.8))
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.6), false, 1.0)
	_draw_regions(rect)
	_draw_markers(rect)
	_draw_player(rect)


## sl-0121 quest markers, extended by sl-0175: every giver worth a
## press — available (gold bang) and turn-in (green ring) — from THE
## overhead-icon model (QuestGiverIcons.giver_states: turn-in wins per
## cell, available hides at the hands cap), plus tracked-quest VISIT
## objectives (amber diamond), tracked-binding identical to the HUD
## tracker (a tracked carried unfinished errand narrows objectives to
## it; no tracked choice = every carried errand [T]). All drawn with
## the player-dot mapping chain so markers can never drift off the
## dot's math. Shape-first (CORE-50): bang vs ring vs diamond, never
## color alone. KILL/COLLECT quests carry no objective CELL in data —
## no exact marker is the honest answer; sl-0218 closes the gap with
## a soft REGION instead (quest_regions below). The pack minimap
## bakes structure footprints as dark cells; markers ride above them
## with black halos.
static func quest_markers(world: RefCounted, tracked_id := "") -> Array:
	var out: Array = []
	if world == null or world.players.is_empty():
		return out
	var p: RefCounted = world.players[0]
	if p.class_id < 0:
		return out
	for st: Dictionary in QuestGiverIcons.giver_states(world):
		out.append({"cell": Vector2(st.cell), "kind": "turn_in" if bool(st.turn_in) else "avail"})
	var only_qi := -1
	if not tracked_id.is_empty():
		for ti in world.quest_defs.size():
			if String(world.quest_defs[ti].id) != tracked_id:
				continue
			if (p.quests_taken_mask & (1 << ti)) == 0:
				continue
			if (p.quests_done_mask & (1 << ti)) != 0:
				continue
			only_qi = ti
	for qi in world.quest_defs.size():
		if only_qi >= 0 and qi != only_qi:
			continue
		if (p.quests_taken_mask & (1 << qi)) == 0:
			continue
		if (p.quests_done_mask & (1 << qi)) != 0:
			continue
		var q: Resource = world.quest_defs[qi]
		var prog: int = p.quest_progress_arr[qi] if qi < p.quest_progress_arr.size() else 0
		if prog < int(q.count) and int(q.kind) == 1:
			out.append({"cell": Vector2(q.target_cell), "kind": "objective"})
	return out


func _tracked_quest() -> String:
	if _cfg == null:
		return ""
	return String(_cfg.get_setting("ui", "tracked_quest", ""))


## sl-0218 — soft objective REGIONS for KILL/COLLECT errands: the
## general position, never an exact pin (closing the honest gap
## recorded since sl-0184). THE ROUTED LITERAL WAS REFUTED BY DATA:
## whole-species territory centroid + radius washes the entire map —
## on the live b77 content 93 sites match the cull and spread
## p50=106 t from their centroid (re-tabled species live zone-wide).
## The honest neighbor keeps the mechanism (species territory
## centroid + radius) on the NEAREST CLUSTER: single-linkage growth
## from the nearest matching site to the quest's OWN giver cell (the
## errand's narrative anchor — static, deterministic, no player
## coupling), link REGION_LINK, cap REGION_CAP sites; the disc =
## cluster centroid + enclosing radius + REGION_PAD, clamped to
## [REGION_R_MIN, REGION_R_MAX]. KILL matches sites whose roster
## carries any target def; COLLECT (any-kind pickups) matches every
## populated site — the countryside around the giver. VISIT keeps
## its exact diamond (a cell exists in data). Site-less worlds
## return nothing by construction. All numbers [T].
const REGION_LINK := 15.0
const REGION_CAP := 10
const REGION_PAD := 4.0
const REGION_R_MIN := 10.0
const REGION_R_MAX := 30.0


static func quest_regions(world: RefCounted, tracked_id := "") -> Array:
	var out: Array = []
	if world == null or world.players.is_empty() or world.site_defs.is_empty():
		return out
	var p: RefCounted = world.players[0]
	if p.class_id < 0:
		return out
	var only_qi := -1
	if not tracked_id.is_empty():
		for ti in world.quest_defs.size():
			if String(world.quest_defs[ti].id) != tracked_id:
				continue
			if (p.quests_taken_mask & (1 << ti)) == 0:
				continue
			if (p.quests_done_mask & (1 << ti)) != 0:
				continue
			only_qi = ti
	for qi in world.quest_defs.size():
		if only_qi >= 0 and qi != only_qi:
			continue
		if (p.quests_taken_mask & (1 << qi)) == 0:
			continue
		if (p.quests_done_mask & (1 << qi)) != 0:
			continue
		var q: Resource = world.quest_defs[qi]
		var kind := int(q.kind)
		if kind != 0 and kind != 2:
			continue
		var prog: int = p.quest_progress_arr[qi] if qi < p.quest_progress_arr.size() else 0
		if prog >= int(q.count):
			continue
		var matching: Array[Vector2] = []
		for sd: Dictionary in world.site_defs:
			var roster: PackedInt32Array = sd.roster_defs
			if roster.is_empty():
				continue
			var hit := kind == 2
			if not hit:
				for d in q.target_defs:
					if roster.has(int(d)):
						hit = true
						break
			if hit:
				matching.append(Vector2(sd.cell))
		if matching.is_empty():
			continue
		var giver: Vector2 = q.giver_cell
		var seed_i := 0
		var best := 1.0e18
		for i in matching.size():
			var d := giver.distance_to(matching[i])
			if d < best:
				best = d
				seed_i = i
		var cluster: Array[Vector2] = [matching[seed_i]]
		var used := {seed_i: true}
		var grew := true
		while grew and cluster.size() < REGION_CAP:
			grew = false
			for i in matching.size():
				if used.has(i):
					continue
				for m: Vector2 in cluster:
					if m.distance_to(matching[i]) <= REGION_LINK:
						cluster.append(matching[i])
						used[i] = true
						grew = true
						break
				if cluster.size() >= REGION_CAP:
					break
		var center := Vector2.ZERO
		for m: Vector2 in cluster:
			center += m
		center /= float(cluster.size())
		var enclose := 0.0
		for m: Vector2 in cluster:
			enclose = maxf(enclose, center.distance_to(m))
		var radius := clampf(enclose + REGION_PAD, REGION_R_MIN, REGION_R_MAX)
		out.append({"center": center, "radius": radius})
	return out


## Soft amber wash + faint rim, drawn UNDER the markers and the
## player dot. Per-axis scaling keeps the disc honest on a
## non-square pack (an ellipse is the truthful projection).
func _draw_regions(rect: Rect2) -> void:
	if world == null or _tex == null:
		return
	var tex_size := Vector2i(_tex.get_width(), _tex.get_height())
	var disp_scale := rect.size / Vector2(tex_size)
	var g := Vector2(maxi(grid_size.x, 1), maxi(grid_size.y, 1))
	var px_per_tile := Vector2(tex_size) / g * disp_scale
	for rg: Dictionary in quest_regions(world, _tracked_quest()):
		var c := rect.position + tile_to_map_px(rg.center, grid_size, tex_size) * disp_scale
		var rr: Vector2 = px_per_tile * float(rg.radius)
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * float(i) / 24.0
			pts.append(c + Vector2(cos(a) * rr.x, sin(a) * rr.y))
		draw_colored_polygon(pts, Color(1.0, 0.78, 0.25, 0.13))
		var ring := pts.duplicate()
		ring.append(pts[0])
		draw_polyline(ring, Color(1.0, 0.78, 0.25, 0.35), 1.0)


func _draw_markers(rect: Rect2) -> void:
	if world == null or _tex == null:
		return
	var tex_size := Vector2i(_tex.get_width(), _tex.get_height())
	var disp_scale := rect.size / Vector2(tex_size)
	var r := 5.0 if mode == Mode.FULL else 3.0
	for m: Dictionary in quest_markers(world, _tracked_quest()):
		var cell: Vector2 = m.cell
		var px := rect.position + tile_to_map_px(cell, grid_size, tex_size) * disp_scale
		match String(m.kind):
			"turn_in":
				draw_arc(px, r, 0.0, TAU, 16, Color(0.0, 0.0, 0.0, 0.9), 3.5)
				draw_arc(px, r, 0.0, TAU, 16, Color(0.55, 1.0, 0.62), 1.5)
			"avail":
				# Gold exclamation: bar + dot (the press-worth cue).
				var bw := r * 0.5
				draw_rect(
					Rect2(
						px + Vector2(-bw * 0.5 - 1.0, -r - 1.6), Vector2(bw + 2.0, r * 1.2 + 2.0)
					),
					Color(0.0, 0.0, 0.0, 0.9)
				)
				draw_circle(px + Vector2(0.0, r * 0.8), bw * 0.6 + 1.0, Color(0.0, 0.0, 0.0, 0.9))
				draw_rect(
					Rect2(px + Vector2(-bw * 0.5, -r - 0.6), Vector2(bw, r * 1.2)),
					Color(1.0, 0.85, 0.35)
				)
				draw_circle(px + Vector2(0.0, r * 0.8), bw * 0.6, Color(1.0, 0.85, 0.35))
			"objective":
				var halo := PackedVector2Array(
					[
						px + Vector2(0, -r - 1.5),
						px + Vector2(r + 1.5, 0),
						px + Vector2(0, r + 1.5),
						px + Vector2(-r - 1.5, 0),
					]
				)
				draw_colored_polygon(halo, Color(0.0, 0.0, 0.0, 0.9))
				var pts := PackedVector2Array(
					[
						px + Vector2(0, -r),
						px + Vector2(r, 0),
						px + Vector2(0, r),
						px + Vector2(-r, 0),
					]
				)
				draw_colored_polygon(pts, Color(1.0, 0.78, 0.25))


func _draw_player(rect: Rect2) -> void:
	if world == null:
		return
	var players: Array = world.players
	if players.is_empty():
		return
	var p: RefCounted = players[0]
	var ppos: Vector2 = p.pos
	var tex_size := Vector2i(_tex.get_width(), _tex.get_height())
	var disp_scale := rect.size / Vector2(tex_size)
	var dot := rect.position + tile_to_map_px(ppos, grid_size, tex_size) * disp_scale
	# Facing tick — the same current-free-aim vector the fire path
	# reads; re-normalized AFTER map scaling so a non-square ratio
	# cannot skew the direction.
	if mouse_tile.is_valid():
		var aim: Vector2 = (mouse_tile.call() as Vector2) - ppos
		if aim.length_squared() > 0.0001:
			var tick := (aim * disp_scale).normalized() * (7.0 if mode == Mode.FULL else 5.0)
			draw_line(dot, dot + tick, Color(1.0, 1.0, 1.0, 0.9), 1.0)
	var r := 2.5 if mode == Mode.FULL else 2.0
	draw_circle(dot, r + 1.0, Color(0.0, 0.0, 0.0, 0.9))
	draw_circle(dot, r, Color.WHITE)
