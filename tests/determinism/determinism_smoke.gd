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
	if not _check_speed_edit():
		failed = true
	if not _check_fire_path():
		failed = true
	if not _check_emitter_death():
		failed = true
	if not _check_enemy_behavior():
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


const FIRE_TICKS := 1500


## Fire-path determinism + CORE-32 independence, mechanized:
## 1. double fire-run hash equality (weapons, cadence, pierce registry,
##    kills — all deterministic);
## 2. player positions EXACTLY equal between a fire run and a no-fire twin
##    with identical movement — firing writes zero movement state;
## 3. RNG stream end-states identical between fire and no-fire runs — the
##    fire path draws no randomness;
## 4. all three frames landed damage, kills happened, the cadence gate
##    held (no two volleys closer than the fastest cadence), and the
##    autofire latch fired during a fire_held gap.
func _check_fire_path() -> bool:
	var a := _run_fire_once(true)
	var b := _run_fire_once(true)
	var quiet := _run_fire_once(false)
	var ok := true
	if a.hashes != b.hashes:
		printerr("FAIL: fire-path hashes diverge between identical runs")
		ok = false
	if a.pos_trace != quiet.pos_trace:
		printerr("FAIL: CORE-32 violation — firing changed movement")
		ok = false
	if a.rng_end != quiet.rng_end:
		printerr("FAIL: CORE-32 violation — fire path consumed RNG")
		ok = false
	if a.kills == 0:
		printerr("FAIL: no kills — resolution path unexercised")
		ok = false
	for pattern_id in [1, 2, 3]:
		if int(a.dmg_by_pattern.get(pattern_id, 0)) == 0:
			printerr("FAIL: weapon pattern %d landed no damage" % pattern_id)
			ok = false
	# Minimum legal volley spacing derives from the DATA (fastest cadence
	# in the loadout) — never a hardcoded tuning value.
	var min_cadence := 1000000
	for wf: Resource in [
		load("res://data/weapons/longbolt.tres"),
		load("res://data/weapons/scattercast.tres"),
		load("res://data/weapons/wheelblade.tres"),
	]:
		min_cadence = mini(min_cadence, int(wf.cadence_ticks))
	var attacks: Array = a.attack_ticks
	for i in range(1, attacks.size()):
		if attacks[i] - attacks[i - 1] < min_cadence:
			printerr(
				(
					"FAIL: cadence gate breach — volleys %d ticks apart at tick %d (min %d)"
					% [attacks[i] - attacks[i - 1], attacks[i], min_cadence]
				)
			)
			ok = false
			break
	var latch_fired := false
	for t: int in attacks:
		if t >= 300 and t < 420 and (t % 90) >= 60:
			latch_fired = true
			break
	if not latch_fired:
		printerr("FAIL: autofire latch never fired during a fire_held gap")
		ok = false
	if int(a.casts) < 2:
		printerr("FAIL: ability casts missing (%d/2)" % int(a.casts))
		ok = false
	if int(a.dmg_by_pattern.get(-1, 0)) == 0:
		printerr("FAIL: nova landed no damage")
		ok = false
	if int(a.mana_min) > 70:
		printerr("FAIL: mana never spent (min %d)" % int(a.mana_min))
		ok = false
	if ok:
		print(
			"fire-path ok: kills=%d attacks=%d dmg=%s" % [a.kills, attacks.size(), a.dmg_by_pattern]
		)
	return ok


func _run_fire_once(with_fire: bool) -> Dictionary:
	var world := SimWorld.new()
	world.setup(77, _build_bitgrid())
	(
		world
		. set_weapons(
			[
				load("res://data/weapons/longbolt.tres"),
				load("res://data/weapons/scattercast.tres"),
				load("res://data/weapons/wheelblade.tres"),
			]
		)
	)
	world.set_abilities([load("res://data/abilities/nova_burst.tres")])
	var player := world.add_player(Vector2(24.0, 16.0))
	# Ring A inside Wheelblade's out-and-return path; ring B in Longbolt
	# reach (14 t/s x 28 ticks = 6.53 tiles).
	for i in 6:
		var ang := TAU * i / 6.0
		world.add_enemy_standin(Vector2(24.0, 16.0) + Vector2(cos(ang), sin(ang)) * 3.0)
	for i in 6:
		var ang := TAU * (i + 0.5) / 6.0
		world.add_enemy_standin(Vector2(24.0, 16.0) + Vector2(cos(ang), sin(ang)) * 6.0)

	var hashes: Array[int] = []
	var pos_trace := PackedVector2Array()
	var attack_ticks: Array[int] = []
	var dmg_by_pattern := {}
	var kills := 0
	var casts := 0
	var mana_min := 100
	for t in FIRE_TICKS:
		var frame := InputFrame.new()
		var leg := (t / 50) % 8
		frame.move_x = MOVE_X[leg]
		frame.move_y = MOVE_Y[leg]
		frame.normalized = true
		var q := InputFrame.quantize_aim(Vector2.RIGHT.rotated(t * 0.021))
		frame.aim_x = q.x
		frame.aim_y = q.y
		# Wheelblade FIRST, while both stand-in rings are fully alive —
		# its pierce/registry coverage must not depend on how many
		# targets the other frames' tuning leaves behind.
		if t == 0:
			frame.weapon_select = 3
		elif t == 500:
			frame.weapon_select = 1
		elif t == 1000:
			frame.weapon_select = 2
		if with_fire:
			frame.fire_held = (t % 90) < 60
			frame.autofire_toggle_edge = t == 300 or t == 420
			# Nova casts: ring A is inside the 2.5-tile radius from center.
			frame.ability_pressed = t == 200 or t == 900
		if t % 7 == 0:
			world.rng_enemy.next_u32()
		world.step([frame])
		pos_trace.append(player.pos)
		for ev: Dictionary in world.events:
			match int(ev.type):
				SimEvents.Type.ATTACK_STARTED:
					attack_ticks.append(int(ev.tick))
				SimEvents.Type.DAMAGE_APPLIED:
					var pattern := int(ev.pattern)
					dmg_by_pattern[pattern] = int(dmg_by_pattern.get(pattern, 0)) + 1
				SimEvents.Type.ENTITY_KILLED:
					kills += 1
				SimEvents.Type.ABILITY_CAST:
					casts += 1
		mana_min = mini(mana_min, player.mana)
		if (world.tick % HASH_EVERY) == 0:
			hashes.append(world.state_hash())

	return {
		"hashes": hashes,
		"pos_trace": pos_trace,
		"attack_ticks": attack_ticks,
		"dmg_by_pattern": dmg_by_pattern,
		"kills": kills,
		"casts": casts,
		"mana_min": mana_min,
		"rng_end": [world.rng_enemy.state, world.rng_misc.state],
	}


## Debug-emitter + player-death contract (M4): hostile fire kills the
## player deterministically; a dead player is inert (no further damage,
## no movement); double-run hashes stay identical.
func _check_emitter_death() -> bool:
	var a := _run_emitter_once()
	var b := _run_emitter_once()
	var ok := true
	if a.hashes != b.hashes:
		printerr("FAIL: emitter runs diverge")
		ok = false
	if not bool(a.died):
		printerr("FAIL: player never died under emitter fire")
		ok = false
	if int(a.hits_after_death) != 0:
		printerr("FAIL: dead player took %d further hits" % int(a.hits_after_death))
		ok = false
	if ok:
		print("emitter-death ok: died at tick %d, hp floor %d" % [int(a.death_tick), int(a.hp_end)])
	return ok


func _run_emitter_once() -> Dictionary:
	var grid := Bitgrid.new()
	grid.setup(16, 16)
	var world := SimWorld.new()
	world.setup(5, grid)
	var player := world.add_player(Vector2(8.0, 8.0))
	(
		world
		. enqueue_command(
			{
				"type": SimWorld.Command.TOGGLE_EMITTER,
				"on": true,
				"pos": Vector2(4.0, 8.0),
				"damage": 25,
				"cadence": 60,
			}
		)
	)
	var hashes: Array[int] = []
	var died := false
	var death_tick := -1
	var hits_after_death := 0
	for t in 900:
		world.step([null])
		for ev: Dictionary in world.events:
			match int(ev.type):
				SimEvents.Type.ENTITY_KILLED:
					if bool(ev.get("player", false)):
						died = true
						death_tick = int(ev.tick)
				SimEvents.Type.DAMAGE_APPLIED:
					if died and int(ev.target) == player.id and int(ev.tick) > death_tick:
						hits_after_death += 1
		if (world.tick % HASH_EVERY) == 0:
			hashes.append(world.state_hash())
	return {
		"hashes": hashes,
		"died": died,
		"death_tick": death_tick,
		"hits_after_death": hits_after_death,
		"hp_end": player.hp,
	}


## M5 enemy-machine contract (docs/12 §2.7/§3.4), mechanized:
## 1. double-run hash equality with live enemy AI (machine is deterministic);
## 2. Rusher closes and lands contact damage gated by its data cooldown,
##    and a standing player eventually dies EXPLAINABLY (pattern -3 trace);
## 3. Husk Archer telegraphs exactly telegraph_ticks before every volley,
##    fires on its data cooldown period, aims at the player (stationary
##    target ⇒ hits land), and holds its keep-range band after settling;
## 4. all timings read from the SHIPPED .tres defs — never re-hardcoded.
func _check_enemy_behavior() -> bool:
	var rdef: Resource = load("res://data/enemies/rusher.tres")
	var hdef: Resource = load("res://data/enemies/husk_archer.tres")
	var ok := true

	var ra := _run_rusher_once(rdef)
	var rb := _run_rusher_once(rdef)
	if ra.hashes != rb.hashes:
		printerr("FAIL: rusher runs diverge")
		ok = false
	var contact_ticks: Array = ra.contact_ticks
	if contact_ticks.size() < 5:
		printerr("FAIL: only %d contact hits — rusher never pressed in" % contact_ticks.size())
		ok = false
	var contact_cd := int(rdef.contact_cooldown_ticks)
	for i in range(1, contact_ticks.size()):
		if contact_ticks[i] - contact_ticks[i - 1] < contact_cd:
			printerr(
				(
					"FAIL: contact cooldown breach — %d ticks apart (min %d)"
					% [contact_ticks[i] - contact_ticks[i - 1], contact_cd]
				)
			)
			ok = false
			break
	if not bool(ra.player_died):
		printerr("FAIL: standing player survived the rusher — contact not lethal")
		ok = false
	if int(ra.last_hit_pattern) != -3:
		printerr("FAIL: death trace pattern %d != -3 (contact)" % int(ra.last_hit_pattern))
		ok = false

	var slot0: Resource = hdef.emitters[0]
	var telegraph := int(slot0.telegraph_ticks)
	var cooldown := int(slot0.cooldown_ticks)
	var ha := _run_husk_once(hdef)
	var hb := _run_husk_once(hdef)
	if ha.hashes != hb.hashes:
		printerr("FAIL: husk runs diverge")
		ok = false
	var telegraphs: Array = ha.telegraph_ticks_list
	var attacks: Array = ha.attack_ticks
	if attacks.size() < 3:
		printerr("FAIL: only %d husk volleys" % attacks.size())
		ok = false
	if telegraphs.size() != attacks.size():
		printerr("FAIL: %d telegraphs vs %d volleys" % [telegraphs.size(), attacks.size()])
		ok = false
	for i in mini(telegraphs.size(), attacks.size()):
		if attacks[i] - telegraphs[i] != telegraph:
			printerr(
				(
					"FAIL: telegraph lead %d != %d at volley %d"
					% [attacks[i] - telegraphs[i], telegraph, i]
				)
			)
			ok = false
			break
	for i in range(1, attacks.size()):
		if attacks[i] - attacks[i - 1] != cooldown:
			printerr("FAIL: husk fire period %d != %d" % [attacks[i] - attacks[i - 1], cooldown])
			ok = false
			break
	if int(ha.aimed_hits) == 0:
		printerr("FAIL: no aimed shot hit the standing player")
		ok = false
	if float(ha.settled_min) < float(hdef.range_min) - 0.6:
		printerr(
			(
				"FAIL: husk closed to %.2f (band %s-%s)"
				% [ha.settled_min, hdef.range_min, hdef.range_max]
			)
		)
		ok = false
	if float(ha.settled_max) > float(hdef.range_max) + 0.6:
		printerr(
			(
				"FAIL: husk drifted to %.2f (band %s-%s)"
				% [ha.settled_max, hdef.range_min, hdef.range_max]
			)
		)
		ok = false
	if ok:
		print(
			(
				"enemy-machine ok: contact=%d death@%d; volleys=%d lead=%d period=%d band=[%.2f, %.2f]"
				% [
					contact_ticks.size(),
					int(ra.death_tick),
					attacks.size(),
					telegraph,
					cooldown,
					float(ha.settled_min),
					float(ha.settled_max),
				]
			)
		)
	return ok


func _run_rusher_once(rdef: Resource) -> Dictionary:
	var world := SimWorld.new()
	world.setup(21, _build_bitgrid())
	world.set_enemy_defs([rdef])
	var player := world.add_player(Vector2(24.0, 16.0))
	world.add_enemy(0, Vector2(16.0, 16.0))
	var hashes: Array[int] = []
	var contact_ticks: Array[int] = []
	var player_died := false
	var death_tick := -1
	var last_hit_pattern := 0
	for t in 900:
		world.step([null])
		for ev: Dictionary in world.events:
			match int(ev.type):
				SimEvents.Type.DAMAGE_APPLIED:
					if int(ev.target) == player.id:
						contact_ticks.append(int(ev.tick))
						last_hit_pattern = int(ev.pattern)
				SimEvents.Type.ENTITY_KILLED:
					if bool(ev.get("player", false)):
						player_died = true
						death_tick = int(ev.tick)
		if (world.tick % HASH_EVERY) == 0:
			hashes.append(world.state_hash())
	return {
		"hashes": hashes,
		"contact_ticks": contact_ticks,
		"player_died": player_died,
		"death_tick": death_tick,
		"last_hit_pattern": last_hit_pattern,
	}


func _run_husk_once(hdef: Resource) -> Dictionary:
	var world := SimWorld.new()
	world.setup(22, _build_bitgrid())
	world.set_enemy_defs([hdef])
	var player := world.add_player(Vector2(24.0, 16.0))
	var husk := world.add_enemy(0, Vector2(21.0, 16.0))
	var hashes: Array[int] = []
	var telegraph_ticks_list: Array[int] = []
	var attack_ticks: Array[int] = []
	var aimed_hits := 0
	var settled_min := 1.0e9
	var settled_max := 0.0
	for t in 600:
		world.step([null])
		for ev: Dictionary in world.events:
			match int(ev.type):
				SimEvents.Type.TELEGRAPH_STARTED:
					if int(ev.id) == husk.id:
						telegraph_ticks_list.append(int(ev.tick))
				SimEvents.Type.ATTACK_STARTED:
					if int(ev.get("enemy", 0)) == husk.id:
						attack_ticks.append(int(ev.tick))
				SimEvents.Type.DAMAGE_APPLIED:
					if int(ev.target) == player.id:
						aimed_hits += 1
		if t >= 200:
			var d: float = husk.pos.distance_to(player.pos)
			settled_min = minf(settled_min, d)
			settled_max = maxf(settled_max, d)
		if (world.tick % HASH_EVERY) == 0:
			hashes.append(world.state_hash())
	return {
		"hashes": hashes,
		"telegraph_ticks_list": telegraph_ticks_list,
		"attack_ticks": attack_ticks,
		"aimed_hits": aimed_hits,
		"settled_min": settled_min,
		"settled_max": settled_max,
	}


## Speed-editor sim contract (§3.2/§2.10): the command clamps to the band,
## stamps replay_dirty, and an edited run hashes differently from a clean
## twin — an edit can never masquerade as clean evidence.
func _check_speed_edit() -> bool:
	var grid := Bitgrid.new()
	grid.setup(8, 8)
	var clean := SimWorld.new()
	clean.setup(9, grid)
	clean.add_player(Vector2(4.0, 4.0))
	var edited := SimWorld.new()
	edited.setup(9, grid)
	edited.add_player(Vector2(4.0, 4.0))
	for t in 3:
		clean.step([null])
		edited.step([null])
	edited.enqueue_command({"type": SimWorld.Command.SET_MOVE_SPEED, "player": 0, "speed": 99.0})
	clean.step([null])
	edited.step([null])
	if not edited.replay_dirty or clean.replay_dirty:
		printerr(
			(
				"FAIL: replay_dirty flag wrong (edited=%s clean=%s)"
				% [edited.replay_dirty, clean.replay_dirty]
			)
		)
		return false
	if edited.players[0].move_speed != SimWorld.MOVE_SPEED_MAX:
		printerr("FAIL: band clamp missed: %f" % edited.players[0].move_speed)
		return false
	if clean.state_hash() == edited.state_hash():
		printerr("FAIL: edited run hashes identical to clean run")
		return false
	return true


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
