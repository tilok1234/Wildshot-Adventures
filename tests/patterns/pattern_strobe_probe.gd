## One-shot WINDOWED probe (sl-0180): THE NO-STROBE LAW EXTENDED TO
## EVERY NEW PATTERN — each rift boss kit runs live in its own arena
## (telegraph flashes + volleys + programs, the real render path) and
## the probe samples viewport mean luminance every 8 ticks across 300
## ticks (~5 s, 38 samples), counting sign ALTERNATIONS among large
## deltas (the reveal-probe math). Sustained combat lawfully cycles
## (telegraph pulse + volley per cadence), so the bound is a RATE:
## more than 10 flips in 5 s (2/s) approaches the photosensitivity
## danger band (~3 Hz) and FAILS — CORE-50: no photosensitivity-
## hostile defaults. Writes reports/pattern_strobe_report.json
## (committed evidence). Run WITHOUT --headless:
##   godot_console --path . --script tests/patterns/pattern_strobe_probe.gd
extends SceneTree

const ScenarioLoader := preload("res://game/scenario_loader.gd")
const DodgeProof := preload("res://game/bots/dodge_proof.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const RenderLayers := preload("res://game/render_layers.gd")
const ProjectileView := preload("res://game/views/projectile_view.gd")
const HazardView := preload("res://game/views/hazard_view.gd")
const RiftView := preload("res://game/views/rift_view.gd")

const KITS: Array[String] = [
	"twin_helix",
	"ring_nest",
	"sine_shoal",
	"boomerang_veil",
	"decel_wall",
	"zone_constellation",
	"cross_burst",
	"pulse_lattice",
	"gap_carousel",
	"sickle_weaver",
	"dart_skirmisher",
	"decel_orchard",
	"halo_lasher",
	"tide_stalker",
	"pulse_cross",
]
const SAMPLE_EVERY := 8
const TICKS := 300
const DELTA_BIG := 0.02
const FLIP_BOUND := 10


func _init() -> void:
	_run()


func _run() -> void:
	var results := {}
	var worst := 0
	for kid in KITS:
		var flips := await _probe_kit(kid)
		results[kid] = flips
		worst = maxi(worst, int(flips.flips))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var f := FileAccess.open(
		ProjectSettings.globalize_path("res://reports/pattern_strobe_report.json"), FileAccess.WRITE
	)
	(
		f
		. store_string(
			(
				JSON
				. stringify(
					{
						"kind": "pattern_strobe",
						"law":
						(
							"flips among |delta luma| > %.2f across %d ticks (every %d) <= %d"
							% [DELTA_BIG, TICKS, SAMPLE_EVERY, FLIP_BOUND]
						),
						"kits": results,
					},
					"\t"
				)
			)
		)
	)
	f.close()
	if worst > FLIP_BOUND:
		printerr("pattern_strobe_probe: FAIL — worst kit flips %d > %d" % [worst, FLIP_BOUND])
		quit(1)
		return
	print(
		(
			"pattern_strobe_probe: PASS — worst flips %d <= %d across %d kits (report committed)"
			% [worst, FLIP_BOUND, KITS.size()]
		)
	)
	quit(0)


func _probe_kit(kid: String) -> Dictionary:
	var scenario: Resource = load("res://data/scenarios/rift_boss_%s.tres" % kid)
	var grid: RefCounted = DodgeProof._build_bitgrid(String(scenario.arena))
	var world: RefCounted = ScenarioLoader.build_world(scenario, 1, grid)
	var root := Node2D.new()
	get_root().add_child(root)
	var rift := RiftView.new()
	rift.world = world
	rift.biome = int(scenario.rift_biome)
	rift.rare = bool(scenario.rift_rare)
	root.add_child(rift)
	var pview := ProjectileView.new()
	pview.world = world
	pview.z_index = RenderLayers.HOSTILE_PROJECTILES
	root.add_child(pview)
	var hview := HazardView.new()
	hview.world = world
	hview.z_index = RenderLayers.HOSTILE_HAZARD_FILL
	root.add_child(hview)
	var cam := Camera2D.new()
	cam.position = Vector2(6.0, 6.5) * 32.0
	cam.zoom = Vector2(1.6, 1.6)
	root.add_child(cam)
	await process_frame
	cam.make_current()
	# The bait stands mid-room so patterns aim and fire for real; the
	# player is never stepped into danger (luma is the subject, not
	# dodging). God keeps the fighter alive through the sampling.
	world.god_mode = true
	var lumas: Array[float] = []
	for t in TICKS:
		var frame := InputFrame.new()
		world.step([frame])
		if t % SAMPLE_EVERY == 0:
			await process_frame
			await RenderingServer.frame_post_draw
			var img := get_root().get_texture().get_image()
			img.resize(64, 36, Image.INTERPOLATE_NEAREST)
			var acc := 0.0
			for y in 36:
				for x in 64:
					var c := img.get_pixel(x, y)
					acc += c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			lumas.append(acc / (64.0 * 36.0))
	var flips := 0
	var last_sign := 0
	for i in range(1, lumas.size()):
		var d := lumas[i] - lumas[i - 1]
		if absf(d) < DELTA_BIG:
			continue
		var s := 1 if d > 0.0 else -1
		if last_sign != 0 and s != last_sign:
			flips += 1
		last_sign = s
	var lmin := 1.0
	var lmax := 0.0
	for l in lumas:
		lmin = minf(lmin, l)
		lmax = maxf(lmax, l)
	root.queue_free()
	await process_frame
	print("  %s: flips=%d luma [%.3f..%.3f]" % [kid, flips, lmin, lmax])
	return {"flips": flips, "luma_min": lmin, "luma_max": lmax}
