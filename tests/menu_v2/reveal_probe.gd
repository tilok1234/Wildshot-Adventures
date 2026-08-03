## One-shot WINDOWED render probe (menu pass seam G, sl-0156): THE
## UNIQUE REVEAL — the wolf ring on the dimmed world (the stampede
## look target), then the plaque (UNIQUE word-mark + ribbon with Old
## Tusk's Hide). Committed captures, read by eyes:
##   reports/unique_reveal_ring.png / unique_reveal_plaque.png
##   reports/unique_reveal_plaque_scale2.png
## PLUS the mechanized NO-STROBE check (the photosensitivity rail):
## mean luminance sampled across the whole play — the path must be
## dim-in / ONE wash excursion / steady / fade, never rapid flips.
## Run WITHOUT --headless:
##   godot_console --path . --script tests/menu_v2/reveal_probe.gd
extends SceneTree

const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")
const UniqueReveal := preload("res://ui/unique_reveal.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const DropKinds := preload("res://sim/drop_kinds.gd")


func _init() -> void:
	_run()


func _run() -> void:
	var grid: RefCounted = Bitgrid.new()
	grid.setup(64, 32)
	var world: RefCounted = ScenarioLoader.build_world(
		load("res://data/scenarios/lab_default.tres"), 1, grid
	)
	var prof := CharacterProfile.create(false, "sword")
	CharacterProfile.apply_to_world(world, prof)
	var hide_ui := -1
	for ui in world.unique_defs.size():
		if String(world.unique_defs[ui].items_id) == "u-old-tusks-hide":
			hide_ui = ui
	if hide_ui < 0:
		printerr("reveal_probe: Old Tusk's Hide not in unique_defs")
		quit(1)
		return

	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.2, 0.14)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(bg)
	var hud := CanvasLayer.new()
	get_root().add_child(hud)
	var reveal := UniqueReveal.new()
	reveal.world = world
	reveal.theme = load("res://ui/theme.tres")
	hud.add_child(reveal)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	await _settle(1)
	reveal.trigger({"kind": DropKinds.UNIQUE, "a": hide_ui, "b": 0})
	if not reveal.is_active():
		printerr("reveal_probe: trigger did not start the play")
		quit(1)
		return

	# Sample luminance across the play while grabbing the two stage
	# shots (the play runs on wall delta — frames ARE the clock).
	var lumas: Array[float] = []
	var ring_shot: Image = null
	var plaque_shot: Image = null
	var elapsed := 0.0
	while reveal.is_active() and elapsed < 6.0:
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_texture().get_image()
		lumas.append(_mean_luma(img))
		elapsed += 6.0 / 60.0
		if ring_shot == null and elapsed >= 0.55:
			ring_shot = img
		if plaque_shot == null and elapsed >= 2.3:
			plaque_shot = img
	if ring_shot == null or plaque_shot == null:
		printerr("reveal_probe: play ended before both stage shots")
		quit(1)
		return
	ring_shot.save_png(ProjectSettings.globalize_path("res://reports/unique_reveal_ring.png"))
	plaque_shot.save_png(ProjectSettings.globalize_path("res://reports/unique_reveal_plaque.png"))

	# NO-STROBE: count sign ALTERNATIONS among large luminance deltas.
	# The lawful path (dim-in, one wash up+down, steady, fade) flips
	# direction at most 3 times at this granularity; strobing would
	# alternate every sample.
	var flips := 0
	var last_sign := 0
	for i in range(1, lumas.size()):
		var d := lumas[i] - lumas[i - 1]
		if absf(d) < 0.02:
			continue
		var s := 1 if d > 0.0 else -1
		if last_sign != 0 and s != last_sign:
			flips += 1
		last_sign = s
	if flips > 3:
		printerr("reveal_probe: NO-STROBE FAIL — %d luminance direction flips" % flips)
		quit(1)
		return
	print(
		(
			"reveal_probe: no-strobe PASS (%d direction flips across %d samples)"
			% [flips, lumas.size()]
		)
	)

	# The plaque at ui scale x2.
	var th2: Theme = (load("res://ui/theme.tres") as Theme).duplicate()
	th2.default_base_scale = 2.0
	th2.default_font_size = 20
	reveal.theme = th2
	reveal.trigger({"kind": DropKinds.UNIQUE, "a": hide_ui, "b": 0})
	var el2 := 0.0
	while reveal.is_active() and el2 < 2.4:
		for i in 6:
			await process_frame
		el2 += 6.0 / 60.0
	await RenderingServer.frame_post_draw
	var shot2 := get_root().get_texture().get_image()
	shot2.save_png(ProjectSettings.globalize_path("res://reports/unique_reveal_plaque_scale2.png"))
	print("reveal_probe: wrote unique_reveal_{ring,plaque,plaque_scale2}.png")
	quit(0)


static func _mean_luma(img: Image) -> float:
	var small: Image = img.duplicate()
	small.resize(16, 9, Image.INTERPOLATE_BILINEAR)
	var total := 0.0
	for y in 9:
		for x in 16:
			var px := small.get_pixel(x, y)
			total += px.r * 0.299 + px.g * 0.587 + px.b * 0.114
	return total / (16.0 * 9.0)


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
