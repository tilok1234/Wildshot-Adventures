extends SceneTree
## M2 determinism smoke test (docs/12 §2.4): two independent SimWorld runs,
## same seed + same scripted inputs, must produce byte-identical FNV-1a state
## hashes at every 30-tick checkpoint across 1800 ticks (30 s). Also asserts
## the scenario actually exercises the spine: movement slides along the wall
## without penetrating, projectiles spawn/hit/despawn, hashes evolve.
## Scope: same build + same platform (Windows) — never run cross-platform.
##
## Run: godot --headless --path . --script tests/determinism/determinism_smoke.gd

const ArenaBuilder := preload("res://game/arena/arena_builder.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const SimWorld := preload("res://sim/sim_world.gd")
const InputFrame := preload("res://sim/input_frame.gd")
const SimEvents := preload("res://sim/events.gd")

const TICKS := 1800
const HASH_EVERY := 30
const RUN_SEED := 42
const SPAWN := Vector2(3.0, 3.0)  # near the corner so wall slide engages

## Scripted movement: one of 8 directions per 40-tick leg, repeating. The
## leftward legs push the player into the west wall — slide must clamp.
const MOVE_X: Array[int] = [1, 1, 0, -1, -1, -1, 0, 1]
const MOVE_Y: Array[int] = [0, 1, 1, 1, 0, -1, -1, -1]


func _init() -> void:
	var a := _run_once()
	var b := _run_once()
	var failed := false

	var hashes_a: Array = a.hashes
	var hashes_b: Array = b.hashes
	for i in hashes_a.size():
		if hashes_a[i] != hashes_b[i]:
			printerr(
				(
					"FAIL: hash mismatch at checkpoint %d (tick %d): %s vs %s"
					% [
						i,
						(i + 1) * HASH_EVERY,
						String.num_uint64(hashes_a[i], 16),
						String.num_uint64(hashes_b[i], 16),
					]
				)
			)
			failed = true
	if a.hits != b.hits:
		printerr("FAIL: hit counts diverge: %d vs %d" % [a.hits, b.hits])
		failed = true

	var distinct := {}
	for h: int in hashes_a:
		distinct[h] = true
	if distinct.size() < hashes_a.size() / 2:
		printerr("FAIL: only %d distinct hashes — state is not evolving" % distinct.size())
		failed = true
	if a.hits == 0:
		printerr("FAIL: no hits landed — collision path unexercised")
		failed = true
	if a.min_x < 1.3499:
		printerr("FAIL: player penetrated the west wall (min_x=%f)" % a.min_x)
		failed = true
	if a.min_x > 1.3501:
		printerr("FAIL: wall slide never engaged (min_x=%f)" % a.min_x)
		failed = true
	if a.live_end == 0:
		printerr("FAIL: no live projectiles at end — pool unexercised")
		failed = true

	if failed:
		quit(1)
		return
	print(
		(
			(
				"PASS: %d checkpoints identical across runs (%d distinct); "
				% [hashes_a.size(), distinct.size()]
			)
			+ "hits=%d live_end=%d min_x=%.4f " % [a.hits, a.live_end, a.min_x]
			+ (
				"first=%s last=%s"
				% [String.num_uint64(hashes_a[0], 16), String.num_uint64(hashes_a[-1], 16)]
			)
		)
	)
	quit(0)


func _build_bitgrid() -> RefCounted:
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://tileforge/tileforge-manifest.json")
	)
	var def := ArenaBuilder.load_def("res://data/arena_lab.json")
	var grid := Bitgrid.new()
	grid.setup(int(def.width), int(def.height))
	for c: Vector2i in ArenaBuilder.solid_cells(def, manifest):
		grid.set_solid(c.x, c.y)
	return grid


func _run_once() -> Dictionary:
	var world := SimWorld.new()
	world.setup(RUN_SEED, _build_bitgrid())
	var player := world.add_player(SPAWN)
	for i in 24:
		var ang := TAU * i / 24.0
		world.add_enemy_standin(Vector2(24.0, 16.0) + Vector2(cos(ang), sin(ang)) * 8.0)

	var hashes: Array[int] = []
	var hits := 0
	var min_x := SPAWN.x
	for t in TICKS:
		var frame := InputFrame.new()
		var leg := (t / 40) % 8
		frame.move_x = MOVE_X[leg]
		frame.move_y = MOVE_Y[leg]
		frame.normalized = true
		var aim := Vector2.RIGHT.rotated(t * 0.037)
		var q := InputFrame.quantize_aim(aim)
		frame.aim_x = q.x
		frame.aim_y = q.y

		# Friendly 2-shot fan along the rotating aim, every 3 ticks.
		if t % 3 == 0:
			for spread in [-0.15, 0.15]:
				(
					world
					. enqueue_command(
						{
							"type": SimWorld.Command.SPAWN_PROJECTILE,
							"pos": player.pos,
							"vel": aim.rotated(spread) * 11.0,
							"radius": 0.15,
							"ttl": 120,
							"faction": 0,
						}
					)
				)
		# Hostile shot from a ring stand-in toward the player's current
		# position, every 10 ticks.
		if t % 10 == 0:
			var shooter: RefCounted = world.enemies[(t / 10) % 24]
			(
				world
				. enqueue_command(
					{
						"type": SimWorld.Command.SPAWN_PROJECTILE,
						"pos": shooter.pos,
						"vel": (player.pos - shooter.pos).normalized() * 6.0,
						"radius": 0.2,
						"ttl": 150,
						"faction": 1,
					}
				)
			)
		# Guaranteed hit path: a friendly shot aimed dead-on at a stationary
		# stand-in, every 45 ticks — the line passes through its center.
		if t % 45 == 0:
			var target: RefCounted = world.enemies[(t / 45) % 24]
			(
				world
				. enqueue_command(
					{
						"type": SimWorld.Command.SPAWN_PROJECTILE,
						"pos": player.pos,
						"vel": (target.pos - player.pos).normalized() * 11.0,
						"radius": 0.15,
						"ttl": 300,
						"faction": 0,
					}
				)
			)
		# No sim system consumes the RNG streams until enemy AI lands (M5),
		# so advance rng_enemy here — identically in both runs — purely so
		# stream state changes and its serialization is covered by the hash.
		if t % 7 == 0:
			world.rng_enemy.next_u32()

		world.step([frame])

		for ev: Dictionary in world.events:
			if int(ev.type) == SimEvents.Type.HIT_LANDED:
				hits += 1
		min_x = minf(min_x, player.pos.x)
		if (world.tick % HASH_EVERY) == 0:
			hashes.append(world.state_hash())

	return {
		"hashes": hashes,
		"hits": hits,
		"min_x": min_x,
		"live_end": world.projectiles.live_count,
	}
