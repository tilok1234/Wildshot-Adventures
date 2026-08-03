## sl-0186 DIAGNOSIS + WALK EVIDENCE probe (windowed). The designer's
## real-play finding: "the dungeon is tottaly broken its just a normal
## sized room and half of it doesnt work to walk in." The wave-2 bot
## proofs PASSED — the sim's serpentine is real; the break is the
## PRESENTATION: every starhook_rift scenario got the ONE-ROOM fit
## treatment (fixed camera hard-coded to the 12x13 arena's interior at
## 192,208 world-px) and the static _rift_capture (set at every cast,
## never cleared) builds the split panes on a console jump — half the
## screen a frozen overworld picture, the other half a room-sized
## window of a 64x44 arena the player walks straight out of.
##
## BEFORE leg = the shipped presentation reproduced (panes + fixed cam)
## with the player at spawn and again after 150 ticks of walking east:
##   reports/rift_dungeon_before_spawn.png
##   reports/rift_dungeon_before_walked.png   (the player OFF-frame)
## The before PNGs are the PRESERVED pre-fix record (captured at
## 679fbd0, when resolve_placements still aborted and the arena drew
## as pure void) — the leg re-verifies the geometry claims but only
## writes the files if they are missing (quest_pull_before precedent).
## AFTER leg = the fix's routing (rift_path -> the standard clamped
## follow camera, full-screen galaxy, no panes, mouth wired to the
## scenario's own flee door) driven through THE FULL SERPENTINE with
## real Kinematics (waypoint walker, progress watchdog — a blocked
## path FAILS the probe):
##   reports/rift_dungeon_after_spawn.png
##   reports/rift_dungeon_after_midpath.png
##   reports/rift_dungeon_after_boss.png
##   reports/rift_dungeon_after_desktop.png   (screen crop, gotcha 42)
## The walker's hp is boosted (view-only world, NEVER a proof — mob
## fire stays live on screen for honest captures; dodging is the
## proofs' job, not this walk's).
## Run WITHOUT --headless:
##   godot_console --path . --script tests/rift_dungeon/dungeon_walk_probe.gd
extends SceneTree

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const DodgeProof := preload("res://game/bots/dodge_proof.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const RiftView := preload("res://game/views/rift_view.gd")
const RiftWorldPane := preload("res://game/views/rift_world_pane.gd")
const RiftNodesView := preload("res://game/views/rift_nodes_view.gd")
const RiftStep := preload("res://sim/systems/rift_step.gd")
const ProjectileView := preload("res://game/views/projectile_view.gd")
const ProjectileSprites := preload("res://game/views/projectile_sprites.gd")
const HpBarView := preload("res://game/views/hp_bar_view.gd")
const CameraRig := preload("res://game/views/camera_rig.gd")

const TILE := 32.0
const ARENA_W := 64
const ARENA_H := 44
## The serpentine, leg by leg (y offsets keep the lane half a tile off
## the pillar rows so the walk reads clean; corner slip would carry a
## head-on line too, just slower).
const WAYPOINTS: Array[Vector2] = [
	Vector2(60.5, 2.5),
	Vector2(60.5, 11.5),
	Vector2(3.5, 11.5),
	Vector2(3.5, 20.5),
	Vector2(60.5, 20.5),
	Vector2(60.5, 27.5),
	Vector2(3.5, 27.5),
	Vector2(3.5, 36.5),
	Vector2(52.5, 36.5),
	Vector2(56.5, 40.5),
]
const WATCHDOG_TICKS := 300
const TICK_BUDGET := 9000

var _fails: Array[String] = []


func _init() -> void:
	_run()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fails.append(msg)
		printerr("dungeon_walk_probe FAIL: " + msg)


func _shot(path: String, keep_existing := false) -> void:
	var full := ProjectSettings.globalize_path("res://reports/%s.png" % path)
	if keep_existing and FileAccess.file_exists(full):
		print("dungeon_walk_probe: reports/%s.png preserved (pre-fix record)" % path)
		return
	var img := get_root().get_texture().get_image()
	img.save_png(full)
	print("dungeon_walk_probe: wrote reports/%s.png" % path)


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw


func _walk_frame(world: RefCounted, target: Vector2) -> RefCounted:
	var p: RefCounted = world.players[0]
	var d: Vector2 = target - p.pos
	var f: RefCounted = InputFrame.new()
	f.move_x = 0 if absf(d.x) < 0.2 else (1 if d.x > 0.0 else -1)
	f.move_y = 0 if absf(d.y) < 0.2 else (1 if d.y > 0.0 else -1)
	f.normalized = true
	return f


func _run() -> void:
	var scenario: Resource = load("res://data/scenarios/rift_dungeon_path.tres")
	var grid: RefCounted = DodgeProof._build_bitgrid(String(scenario.arena))
	var world: RefCounted = ScenarioLoader.build_world(scenario, 1, grid)
	_check(world.rift_line != null, "dungeon world built with the line rules")
	var p: RefCounted = world.players[0]
	print(
		(
			"dungeon_walk_probe: arena %dx%d, spawn %.1f,%.1f, %d enemies"
			% [ARENA_W, ARENA_H, p.pos.x, p.pos.y, world.enemies.size()]
		)
	)
	# View-only walker armor (never a proof): the walk is about the
	# LOAD, not the dodge — mob fire stays live for honest captures.
	p.hp = 9999999
	p.max_hp = 9999999

	var root := Node2D.new()
	get_root().add_child(root)
	var arena := ArenaBuilder.build_arena(root, String(scenario.arena))
	_check(not arena.is_empty(), "the serpentine arena built (render side)")
	var rift_view := RiftView.new()
	rift_view.world = world
	rift_view.biome = int(scenario.rift_biome)
	rift_view.rare = bool(scenario.rift_rare)
	rift_view.arena_w = ARENA_W
	rift_view.arena_h = ARENA_H
	root.add_child(rift_view)
	var sprites := ProjectileSprites.new()
	if not sprites.load_manifest():
		sprites = null
	var pv := ProjectileView.new()
	pv.world = world
	pv.sprites = sprites
	pv.pattern_map = load("res://data/projectile_map.tres")
	root.add_child(pv)
	var bars := HpBarView.new()
	bars.world = world
	root.add_child(bars)
	var cam := CameraRig.new()
	cam.world = world
	root.add_child(cam)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	DisplayServer.window_set_size(Vector2i(640, 360))

	# ---- BEFORE: the shipped presentation (the diagnosis record) ----
	# The console jump after any cast that session: split panes over a
	# STALE capture + the fixed one-room camera (_apply_rift_split
	# r=0.5 math verbatim: zoom 1.0, center 32,208).
	var pane_layer := CanvasLayer.new()
	pane_layer.layer = 40
	get_root().add_child(pane_layer)
	var capture := Image.create(640, 360, false, Image.FORMAT_RGB8)
	capture.fill(Color(0.23, 0.30, 0.21))
	var wpane := TextureRect.new()
	wpane.texture = ImageTexture.create_from_image(capture)
	wpane.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wpane.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	wpane.anchor_right = 0.5
	wpane.anchor_bottom = 1.0
	wpane.modulate = Color(0.62, 0.62, 0.72, 1.0)
	pane_layer.add_child(wpane)
	var overlay := RiftWorldPane.new()
	overlay.world = world
	overlay.deep_x = RiftStep.deep_edge_x(world)
	overlay.biome_rim = RiftNodesView.BIOME_RIMS[clampi(int(scenario.rift_biome), 0, 2)]
	overlay.portal_offset = Vector2(38.0, -20.0)
	overlay.anchor_right = 0.5
	overlay.anchor_bottom = 1.0
	pane_layer.add_child(overlay)
	var zoom_v := minf(320.0 / 320.0, 360.0 / 352.0)
	var cam_x := 192.0 - ((640.0 - 320.0 * 0.5) - 320.0) / zoom_v
	# One settle BEFORE the camera call: make_current needs the tree
	# live (a bare call from _init logs an engine error).
	await _settle(2)
	cam.setup_fixed(Vector2(cam_x, 208.0), zoom_v)
	await _settle(12)
	# The galaxy pane's world rect in tiles (the RIGHT half of the
	# screen; the left half is the stale world pane) — the measurement
	# behind the designer's words.
	var pane_l := cam_x / TILE
	var pane_r := (cam_x + 320.0 / zoom_v) / TILE
	var pane_t := (208.0 - 180.0 / zoom_v) / TILE
	var pane_b := (208.0 + 180.0 / zoom_v) / TILE
	var vis_tiles := (
		(minf(pane_r, ARENA_W) - maxf(pane_l, 0.0)) * (minf(pane_b, ARENA_H) - maxf(pane_t, 0.0))
	)
	print(
		(
			"dungeon_walk_probe BEFORE: galaxy pane shows tiles x[%.1f..%.1f] y[%.1f..%.1f] = %.0f of %d arena tiles (%.1f%%) — the 'normal sized room'"
			% [
				pane_l,
				pane_r,
				pane_t,
				pane_b,
				vis_tiles,
				ARENA_W * ARENA_H,
				100.0 * vis_tiles / float(ARENA_W * ARENA_H),
			]
		)
	)
	_shot("rift_dungeon_before_spawn", true)
	# Walk east 150 ticks — the player leaves the fixed frame.
	for t in 150:
		world.step([_walk_frame(world, Vector2(60.5, 2.5))])
	await _settle(4)
	var px: float = p.pos.x
	var on_frame: bool = px >= pane_l and px <= pane_r
	print(
		(
			"dungeon_walk_probe BEFORE: after 150 ticks east the player stands at %.1f,%.1f — %s the fixed frame"
			% [p.pos.x, p.pos.y, "still inside" if on_frame else "OFF"]
		)
	)
	_check(not on_frame, "the shipped fixed camera loses the walking player (the diagnosis)")
	_shot("rift_dungeon_before_walked", true)

	# ---- AFTER: the fix's routing (rift_path -> follow camera, the
	# authored arena rendering in path mode, the mouth at the flee
	# door) ----
	pane_layer.queue_free()
	cam.fixed_mode = false
	cam.setup(ARENA_W, ARENA_H)
	rift_view.mouth = Vector2(2.5, 3.5)
	# path_mode is applied at _ready — rebuild the view the way main's
	# fixed routing constructs it.
	var pm_view := RiftView.new()
	pm_view.world = world
	pm_view.biome = int(scenario.rift_biome)
	pm_view.rare = bool(scenario.rift_rare)
	pm_view.arena_w = ARENA_W
	pm_view.arena_h = ARENA_H
	pm_view.path_mode = true
	pm_view.mouth = Vector2(2.5, 3.5)
	rift_view.queue_free()
	rift_view = pm_view
	root.add_child(rift_view)
	# Fresh world for the honest start-to-finish walk (the before leg
	# already spent ticks).
	world = ScenarioLoader.build_world(scenario, 1, grid)
	p = world.players[0]
	p.hp = 9999999
	p.max_hp = 9999999
	rift_view.world = world
	pv.world = world
	bars.world = world
	cam.world = world
	await _settle(4)
	_shot("rift_dungeon_after_spawn")

	# THE WALK: full serpentine, real Kinematics, progress watchdog.
	var wp := 0
	var ticks := 0
	var best: float = p.pos.distance_to(WAYPOINTS[0])
	var since_best := 0
	var midpath_shot := false
	while wp < WAYPOINTS.size() and ticks < TICK_BUDGET:
		world.step([_walk_frame(world, WAYPOINTS[wp])])
		ticks += 1
		var d: float = p.pos.distance_to(WAYPOINTS[wp])
		if d < best - 0.05:
			best = d
			since_best = 0
		else:
			since_best += 1
		if since_best > WATCHDOG_TICKS:
			_check(
				false,
				(
					"walk WEDGED %d ticks short of waypoint %d (%.1f,%.1f) at %.1f,%.1f"
					% [since_best, wp, WAYPOINTS[wp].x, WAYPOINTS[wp].y, p.pos.x, p.pos.y]
				)
			)
			break
		if d < 1.0:
			print(
				(
					"dungeon_walk_probe: waypoint %d (%.1f,%.1f) reached at tick %d"
					% [wp, WAYPOINTS[wp].x, WAYPOINTS[wp].y, ticks]
				)
			)
			wp += 1
			if wp < WAYPOINTS.size():
				best = p.pos.distance_to(WAYPOINTS[wp])
				since_best = 0
		if wp == 5 and not midpath_shot:
			midpath_shot = true
			await _settle(4)
			_shot("rift_dungeon_after_midpath")
	_check(
		wp == WAYPOINTS.size(),
		"THE FULL SERPENTINE WALKS: %d/%d waypoints in %d ticks" % [wp, WAYPOINTS.size(), ticks]
	)
	print(
		(
			"dungeon_walk_probe AFTER: %d/%d waypoints, %d ticks (~%.0f s), end %.1f,%.1f"
			% [wp, WAYPOINTS.size(), ticks, float(ticks) / 30.0, p.pos.x, p.pos.y]
		)
	)
	await _settle(4)
	_shot("rift_dungeon_after_boss")

	# Desktop-scale crop (gotcha 42: FORCE WINDOWED first —
	# window_set_size is ignored while effectively maximized — explicit
	# size, on-top, honesty-guarded; committed evidence never trusts a
	# blind crop).
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_position(Vector2i(0, 0))
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_move_to_foreground()
	await _settle(30)
	var screen := DisplayServer.screen_get_image(DisplayServer.window_get_current_screen())
	if screen != null:
		var wpos := DisplayServer.window_get_position()
		var wsize := DisplayServer.window_get_size()
		var rect := Rect2i(wpos, wsize).intersection(
			Rect2i(Vector2i.ZERO, Vector2i(screen.get_width(), screen.get_height()))
		)
		var shot2 := screen.get_region(rect)
		var probe_px := shot2.get_pixel(shot2.get_width() / 2, shot2.get_height() / 2)
		if probe_px.v > 0.6:
			printerr("dungeon_walk_probe: desktop crop fails the galaxy guard — NOT written")
		else:
			shot2.save_png(
				ProjectSettings.globalize_path("res://reports/rift_dungeon_after_desktop.png")
			)
			print(
				(
					"dungeon_walk_probe: wrote reports/rift_dungeon_after_desktop.png (%dx%d)"
					% [shot2.get_width(), shot2.get_height()]
				)
			)

	if _fails.is_empty():
		print("dungeon_walk_probe: PASS (diagnosis reproduced + the full path walks)")
		quit(0)
	else:
		quit(1)
