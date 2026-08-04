## One-shot WINDOWED evidence probe (sl-0200): live fight captures for
## the pool extension — one kit per family (ANCHOR gap_carousel /
## FLANKER sickle_weaver / PURSUER tide_stalker), each stepped mid-
## fight on the real render path (RiftView + projectile view + the
## fixed rift camera) and captured at base res to
## reports/rift_pool_ext_<family>_<kit>.png. The captures are READ BY
## EYES before committing (gotcha 13 — headless boots cannot see
## render bugs; this probe is the committed-PNG variant). God keeps
## the bait alive; the world steps a still fighter so patterns aim
## and fire for real. Run WITHOUT --headless:
##   godot_console --path . --script tests/patterns/rift_pool_capture_probe.gd
extends SceneTree

const ScenarioLoader := preload("res://game/scenario_loader.gd")
const DodgeProof := preload("res://game/bots/dodge_proof.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const RenderLayers := preload("res://game/render_layers.gd")
const ProjectileView := preload("res://game/views/projectile_view.gd")
const HazardView := preload("res://game/views/hazard_view.gd")
const RiftView := preload("res://game/views/rift_view.gd")

## kit id -> [family label, ticks to step before the shot]
const CAPTURES := {
	"gap_carousel": ["anchor", 170],
	"sickle_weaver": ["flanker", 170],
	"tide_stalker": ["pursuer", 230],
}


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var wrote: Array[String] = []
	for kid: String in CAPTURES:
		var fam: String = CAPTURES[kid][0]
		var ticks: int = CAPTURES[kid][1]
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
		world.god_mode = true
		for t in ticks:
			world.step([InputFrame.new()])
			await process_frame
		await process_frame
		var img := get_root().get_texture().get_image()
		var out := "res://reports/rift_pool_ext_%s_%s.png" % [fam, kid]
		img.save_png(ProjectSettings.globalize_path(out))
		wrote.append(out)
		root.queue_free()
		await process_frame
	print("rift_pool_capture_probe: wrote %d captures" % wrote.size())
	for w: String in wrote:
		print("  " + w)
	quit(0)
