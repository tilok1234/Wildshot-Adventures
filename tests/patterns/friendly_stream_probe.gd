## One-shot WINDOWED probe (sl-0207): the raised friendly-bullet
## counts on screen — the readability-sanity evidence the cadence
## re-composition owes. A class-lane BOW at the top dexterity step
## (L23, stat 136 -> cadence 11) with QUICKDRAW live (cadence 8,
## 7.5/s — the peak stream the game can produce) autofires across
## second_contact's hostile field (fanmaw fans + ringer radials).
## Captures reports/friendly_stream_audit_sl0207.png at peak stream
## and prints the live friendly count (Law 2 is judged by eyes on
## the PNG: player shots stay subordinate to hostile fire).
## Run WITHOUT --headless:
##   godot_console --path . --script tests/patterns/friendly_stream_probe.gd
extends SceneTree

const ScenarioLoader := preload("res://game/scenario_loader.gd")
const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const DodgeProof := preload("res://game/bots/dodge_proof.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const RenderLayers := preload("res://game/render_layers.gd")
const ProjectileView := preload("res://game/views/projectile_view.gd")
const ProjectileSprites := preload("res://game/views/projectile_sprites.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")

const TICKS := 240


func _init() -> void:
	_run()


func _run() -> void:
	var scenario: Resource = load("res://data/scenarios/second_contact.tres")
	var grid: RefCounted = DodgeProof._build_bitgrid(String(scenario.arena))
	var world: RefCounted = ScenarioLoader.build_world(scenario, 1, grid)
	CharacterProfile.apply_to_world(world, CharacterProfile.create(false, "bow"))
	var p: RefCounted = world.players[0]
	p.level = 23
	StatFrame.recompute(world, p)
	p.quickdraw_until_tick = 1000000
	world.god_mode = true
	var root := Node2D.new()
	get_root().add_child(root)
	var arena := ArenaBuilder.build_arena(root, String(scenario.arena))
	if arena.is_empty():
		printerr("friendly_stream_probe: arena did not build")
		quit(1)
		return
	var sprites: RefCounted = ProjectileSprites.new()
	if not sprites.load_manifest():
		sprites = null
	var pview := ProjectileView.new()
	pview.world = world
	pview.sprites = sprites
	pview.pattern_map = load("res://data/projectile_map.tres")
	pview.z_index = RenderLayers.HOSTILE_PROJECTILES
	root.add_child(pview)
	var cam := Camera2D.new()
	cam.position = p.pos * 32.0
	cam.zoom = Vector2(1.4, 1.4)
	root.add_child(cam)
	await process_frame
	cam.make_current()
	var peak_friendly := 0
	for t in TICKS:
		var frame := InputFrame.new()
		frame.fire_held = true
		frame.aim_x = 4096
		frame.normalized = true
		world.step([frame])
		await process_frame
		var live := 0
		var pool: RefCounted = world.projectiles
		for s in pool.CAPACITY:
			if pool.active[s] == 1 and pool.faction[s] == 0:
				live += 1
		peak_friendly = maxi(peak_friendly, live)
	await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	img.save_png(ProjectextSettingsPath("res://reports/friendly_stream_audit_sl0207.png"))
	var stat_cad := StatFrame.effective_cadence(world.weapon_frames[p.equipped_weapon], p)
	var qd_cad := maxi(1, (stat_cad * 2 + 2) / 3)
	print(
		(
			"friendly_stream_probe: bow L23 stat cadence %d (%.2f/s), quickdrawn %d (%.2f/s), peak friendly live %d"
			% [stat_cad, 60.0 / float(stat_cad), qd_cad, 60.0 / float(qd_cad), peak_friendly]
		)
	)
	print("friendly_stream_probe: wrote reports/friendly_stream_audit_sl0207.png")
	quit(0)


static func ProjectextSettingsPath(p: String) -> String:
	return ProjectSettings.globalize_path(p)
