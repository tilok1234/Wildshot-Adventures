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
const PlayerMove := preload("res://sim/systems/player_move.gd")

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
	# Wall-slide floor = 1.0 + the LOCOMOTION radius (2026-07-28
	# walk-close [T]: players hug walls at TERRAIN_RADIUS, not the
	# combat hurtbox — the bound reads the constant so a retune moves
	# the contract with it). NOTE: this assert failed silently between
	# the terrain-radius commit and the pretester checklist catching it
	# — the commit-gate smoke output was piped to its tail and the exit
	# code went unchecked. Gates read exit codes, not prose.
	var wall_floor: float = 1.0 + PlayerMove.TERRAIN_RADIUS
	if a.min_x < wall_floor - 0.0001:
		printerr("FAIL: player penetrated the west wall (min_x=%f)" % a.min_x)
		failed = true
	if a.min_x > wall_floor + 0.0001:
		printerr("FAIL: wall slide never engaged (min_x=%f)" % a.min_x)
		failed = true
	if a.live_end == 0:
		printerr("FAIL: no live projectiles at end — pool unexercised")
		failed = true
	if not _check_speed_edit():
		failed = true
	if not _check_fire_path():
		failed = true
	if not _check_hostile_death():
		failed = true
	if not _check_enemy_behavior():
		failed = true
	if not _check_m6_data_enemies():
		failed = true
	if not _check_leadshot():
		failed = true
	if not _check_blightcaster():
		failed = true
	if not _check_yard_warden():
		failed = true
	if not _check_law4_ordering():
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


## Hostile-projectile player-death contract (M4, re-based onto real
## enemies when the debug emitter retired at M5): aimed hostile fire
## kills a standing player deterministically; a dead player is inert
## (no further damage); double-run hashes stay identical.
func _check_hostile_death() -> bool:
	var a := _run_hostile_death_once()
	var b := _run_hostile_death_once()
	var ok := true
	if a.hashes != b.hashes:
		printerr("FAIL: hostile-death runs diverge")
		ok = false
	if not bool(a.died):
		printerr("FAIL: player never died under husk fire")
		ok = false
	if int(a.hits_after_death) != 0:
		printerr("FAIL: dead player took %d further hits" % int(a.hits_after_death))
		ok = false
	if ok:
		print("hostile-death ok: died at tick %d, hp floor %d" % [int(a.death_tick), int(a.hp_end)])
	return ok


func _run_hostile_death_once() -> Dictionary:
	var world := SimWorld.new()
	world.setup(5, _build_bitgrid())
	world.set_enemy_defs([load("res://data/enemies/husk_archer.tres")])
	var player := world.add_player(Vector2(24.0, 16.0))
	for i in 3:
		var ang := TAU * i / 3.0
		world.add_enemy(0, Vector2(24.0, 16.0) + Vector2(cos(ang), sin(ang)) * 5.5)
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


## M5 enemy-machine contract (docs/12 §2.7/§3.4 as amended 2026-07-27:
## every enemy attack is a visible telegraphed pattern), mechanized:
## 1. double-run hash equality with live enemy AI (machine is deterministic);
## 2. Rusher closes and SLASHES: telegraph leads every volley by exactly
##    its data ticks, volleys land pattern-11 damage on their cooldown
##    period, and a standing player dies EXPLAINABLY (pattern 11 trace);
## 3. Husk Archer telegraphs exactly telegraph_ticks before every volley,
##    fires on its data cooldown period, aims at the player (stationary
##    target ⇒ hits land), and holds its keep-range band after settling;
## 4. all timings read from the SHIPPED .tres defs — never re-hardcoded.
func _check_enemy_behavior() -> bool:
	var rdef: Resource = load("res://data/enemies/rusher.tres")
	var hdef: Resource = load("res://data/enemies/husk_archer.tres")
	var ok := true

	var rslot: Resource = rdef.emitters[0]
	var rpattern: Resource = rslot.pattern
	var rpid := int(rpattern.pattern_id)
	var ra := _run_rusher_once(rdef, rpid)
	var rb := _run_rusher_once(rdef, rpid)
	if ra.hashes != rb.hashes:
		printerr("FAIL: rusher runs diverge")
		ok = false
	var slash_volleys: Array = ra.attack_ticks
	var slash_telegraphs: Array = ra.telegraph_ticks_list
	if slash_volleys.size() < 3:
		printerr("FAIL: only %d slash volleys — rusher never pressed in" % slash_volleys.size())
		ok = false
	if slash_telegraphs.size() != slash_volleys.size():
		printerr(
			(
				"FAIL: %d slash telegraphs vs %d volleys"
				% [slash_telegraphs.size(), slash_volleys.size()]
			)
		)
		ok = false
	var rlead := int(rslot.telegraph_ticks)
	for i in mini(slash_telegraphs.size(), slash_volleys.size()):
		if slash_volleys[i] - slash_telegraphs[i] != rlead:
			printerr(
				(
					"FAIL: slash telegraph lead %d != %d at volley %d"
					% [slash_volleys[i] - slash_telegraphs[i], rlead, i]
				)
			)
			ok = false
			break
	var rcd := int(rslot.cooldown_ticks)
	for i in range(1, slash_volleys.size()):
		if slash_volleys[i] - slash_volleys[i - 1] != rcd:
			printerr("FAIL: slash period %d != %d" % [slash_volleys[i] - slash_volleys[i - 1], rcd])
			ok = false
			break
	if int(ra.slash_hits) < 3:
		printerr("FAIL: only %d slash hits landed on a standing player" % int(ra.slash_hits))
		ok = false
	if not bool(ra.player_died):
		printerr("FAIL: standing player survived the rusher — slash not lethal")
		ok = false
	if int(ra.last_hit_pattern) != rpid:
		printerr("FAIL: death trace pattern %d != %d (slash)" % [int(ra.last_hit_pattern), rpid])
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
				"enemy-machine ok: slashes=%d hits=%d death@%d; volleys=%d lead=%d period=%d band=[%.2f, %.2f]"
				% [
					slash_volleys.size(),
					int(ra.slash_hits),
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


func _run_rusher_once(rdef: Resource, slash_pid: int) -> Dictionary:
	var world := SimWorld.new()
	world.setup(21, _build_bitgrid())
	world.set_enemy_defs([rdef])
	var player := world.add_player(Vector2(24.0, 16.0))
	var rusher := world.add_enemy(0, Vector2(16.0, 16.0))
	var hashes: Array[int] = []
	var telegraph_ticks_list: Array[int] = []
	var attack_ticks: Array[int] = []
	var slash_hits := 0
	var player_died := false
	var death_tick := -1
	var last_hit_pattern := 0
	for t in 900:
		world.step([null])
		for ev: Dictionary in world.events:
			match int(ev.type):
				SimEvents.Type.TELEGRAPH_STARTED:
					if int(ev.id) == rusher.id:
						telegraph_ticks_list.append(int(ev.tick))
				SimEvents.Type.ATTACK_STARTED:
					if int(ev.get("enemy", 0)) == rusher.id:
						attack_ticks.append(int(ev.tick))
				SimEvents.Type.DAMAGE_APPLIED:
					if int(ev.target) == player.id:
						last_hit_pattern = int(ev.pattern)
						if int(ev.pattern) == slash_pid:
							slash_hits += 1
				SimEvents.Type.ENTITY_KILLED:
					if bool(ev.get("player", false)):
						player_died = true
						death_tick = int(ev.tick)
		if (world.tick % HASH_EVERY) == 0:
			hashes.append(world.state_hash())
	return {
		"hashes": hashes,
		"telegraph_ticks_list": telegraph_ticks_list,
		"attack_ticks": attack_ticks,
		"slash_hits": slash_hits,
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


## M6 pure-data enemy contracts (docs/12 §3.4 rows Fanmaw/Ringer),
## mechanized like the M5 pair:
## 1. double-run hash equality for both (the data roster stays deterministic);
## 2. Fanmaw ANCHORS — position never changes — telegraphs exactly its data
##    lead before every volley, fires on its data period, and the fan hits
##    a standing player with pattern-13 damage;
## 3. Ringer CHASES — closes distance between volleys — telegraphs/fires on
##    its data timings, and the ring hits a standing player (pattern 14);
## 4. volley size read from the pool on each first-fire tick equals the
##    SHIPPED shots-array size (5 fan / 12 radial);
## 5. all timings/sizes read from the shipped .tres defs — never re-hardcoded.
func _check_m6_data_enemies() -> bool:
	var ok := true
	for spec: Array in [
		[load("res://data/enemies/fanmaw.tres"), true],
		[load("res://data/enemies/ringer.tres"), false],
	]:
		var def: Resource = spec[0]
		var anchored: bool = spec[1]
		var eid := String(def.id)
		var slot: Resource = def.emitters[0]
		var pattern: Resource = slot.pattern
		var pid := int(pattern.pattern_id)
		var volley_size: int = pattern.shots.size()
		var lead := int(slot.telegraph_ticks)
		var period := int(slot.cooldown_ticks)
		var a := _run_solo_enemy_once(def)
		var b := _run_solo_enemy_once(def)
		if a.hashes != b.hashes:
			printerr("FAIL: %s runs diverge" % eid)
			ok = false
		var telegraphs: Array = a.telegraph_ticks_list
		var attacks: Array = a.attack_ticks
		if attacks.size() < 3:
			printerr("FAIL: only %d %s volleys" % [attacks.size(), eid])
			ok = false
		if telegraphs.size() != attacks.size():
			printerr(
				"FAIL: %s %d telegraphs vs %d volleys" % [eid, telegraphs.size(), attacks.size()]
			)
			ok = false
		for i in mini(telegraphs.size(), attacks.size()):
			if attacks[i] - telegraphs[i] != lead:
				printerr(
					(
						"FAIL: %s telegraph lead %d != %d at volley %d"
						% [eid, attacks[i] - telegraphs[i], lead, i]
					)
				)
				ok = false
				break
		for i in range(1, attacks.size()):
			if attacks[i] - attacks[i - 1] != period:
				printerr(
					"FAIL: %s fire period %d != %d" % [eid, attacks[i] - attacks[i - 1], period]
				)
				ok = false
				break
		for i in a.volley_counts.size():
			if int(a.volley_counts[i]) != volley_size:
				printerr(
					(
						"FAIL: %s volley %d spawned %d shots (shipped pattern has %d)"
						% [eid, i, int(a.volley_counts[i]), volley_size]
					)
				)
				ok = false
				break
		if int(a.pattern_hits) == 0:
			printerr("FAIL: no pattern-%d hit landed on the standing player (%s)" % [pid, eid])
			ok = false
		if int(a.other_hits) != 0:
			printerr("FAIL: %s landed %d non-pattern-%d hits" % [eid, int(a.other_hits), pid])
			ok = false
		if anchored:
			if float(a.moved_max) > 0.0001:
				printerr("FAIL: %s moved %.4f tiles — ANCHOR must hold ground" % [eid, a.moved_max])
				ok = false
		else:
			if float(a.dist_min) > float(a.dist_start) - 1.0:
				printerr(
					(
						"FAIL: %s closed only %.2f tiles — CHASER must press in"
						% [eid, float(a.dist_start) - float(a.dist_min)]
					)
				)
				ok = false
		if ok:
			print(
				(
					"m6 %s ok: volleys=%d x%d shots lead=%d period=%d hits=%d moved=%.3f closed=%.2f"
					% [
						eid,
						attacks.size(),
						volley_size,
						lead,
						period,
						int(a.pattern_hits),
						float(a.moved_max),
						float(a.dist_start) - float(a.dist_min),
					]
				)
			)
	return ok


## Solo M6 enemy micro-world: standing player at (24,16), enemy at (30,16)
## (inside both trigger ranges), 900 ticks of null input. Volley size is
## counted from PROJECTILE_SPAWNED events on each ATTACK_STARTED tick —
## a pool read would miss shots that spawn point-blank and despawn on
## their own spawn tick (a pressed-in Ringer does exactly that).
func _run_solo_enemy_once(def: Resource) -> Dictionary:
	var world := SimWorld.new()
	world.setup(23, _build_bitgrid())
	world.set_enemy_defs([def])
	var player := world.add_player(Vector2(24.0, 16.0))
	var enemy: RefCounted = world.add_enemy(0, Vector2(30.0, 16.0))
	var slot: Resource = def.emitters[0]
	var pattern: Resource = slot.pattern
	var pid := int(pattern.pattern_id)
	var spawn_pos: Vector2 = enemy.pos
	var dist_start: float = spawn_pos.distance_to(player.pos)
	var hashes: Array[int] = []
	var telegraph_ticks_list: Array[int] = []
	var attack_ticks: Array[int] = []
	var volley_counts: Array[int] = []
	var pattern_hits := 0
	var other_hits := 0
	var moved_max := 0.0
	var dist_min := dist_start
	for t in 900:
		world.step([null])
		var fired := false
		var spawned_this_tick := 0
		for ev: Dictionary in world.events:
			match int(ev.type):
				SimEvents.Type.TELEGRAPH_STARTED:
					if int(ev.id) == enemy.id:
						telegraph_ticks_list.append(int(ev.tick))
				SimEvents.Type.ATTACK_STARTED:
					if int(ev.get("enemy", 0)) == enemy.id:
						attack_ticks.append(int(ev.tick))
						fired = true
				SimEvents.Type.PROJECTILE_SPAWNED:
					if int(ev.pattern) == pid:
						spawned_this_tick += 1
				SimEvents.Type.DAMAGE_APPLIED:
					if int(ev.target) == player.id:
						if int(ev.pattern) == pid:
							pattern_hits += 1
						else:
							other_hits += 1
		if fired:
			volley_counts.append(spawned_this_tick)
		var epos: Vector2 = enemy.pos
		moved_max = maxf(moved_max, spawn_pos.distance_to(epos))
		dist_min = minf(dist_min, epos.distance_to(player.pos))
		if (world.tick % HASH_EVERY) == 0:
			hashes.append(world.state_hash())
	return {
		"hashes": hashes,
		"telegraph_ticks_list": telegraph_ticks_list,
		"attack_ticks": attack_ticks,
		"volley_counts": volley_counts,
		"pattern_hits": pattern_hits,
		"other_hits": other_hits,
		"moved_max": moved_max,
		"dist_start": dist_start,
		"dist_min": dist_min,
	}


## M6 Leadshot contract (docs/12 §3.4 row 3, SERIAL 10), mechanized in
## two runs reading every number from the shipped .tres:
## STANDING target: double-run hash equality; telegraph leads every
## volley by exactly its data ticks; volleys on the exact data period;
## one dart per volley; FLANKER settles into its range band and
## CIRCULATES (swept bearing ≥ 1 rad — chaser/keep-range sweep ~0);
## darts hit the stander (vel zero ⇒ intercept degenerates to current
## aim, the closed-form's own edge case).
## MOVING target (square-wave perpendicular strafe at 3.0 t/s): darts
## HIT the mover. At ~8-10 tiles a current-position aim misses a 3.0
## t/s perpendicular strafer by ~3 tiles (flight ~1 s) — any pattern-12
## hit on a constant-velocity leg witnesses the lead solve reading the
## serialized vel. Reversal-straddling volleys miss: that IS the
## intended counter (jink on the telegraph), not flakiness — the runs
## are deterministic, so the hit set is fixed.
func _check_leadshot() -> bool:
	var ldef: Resource = load("res://data/enemies/leadshot.tres")
	var slot: Resource = ldef.emitters[0]
	var pattern: Resource = slot.pattern
	var pid := int(pattern.pattern_id)
	var lead := int(slot.telegraph_ticks)
	var period := int(slot.cooldown_ticks)
	var ok := true

	var sa := _run_leadshot_once(ldef, false, 600)
	var sb := _run_leadshot_once(ldef, false, 600)
	if sa.hashes != sb.hashes:
		printerr("FAIL: leadshot standing runs diverge")
		ok = false
	var ma := _run_leadshot_once(ldef, true, 900)
	var mb := _run_leadshot_once(ldef, true, 900)
	if ma.hashes != mb.hashes:
		printerr("FAIL: leadshot mover runs diverge")
		ok = false

	for named: Array in [["standing", sa], ["mover", ma]]:
		var label := String(named[0])
		var r: Dictionary = named[1]
		var telegraphs: Array = r.telegraph_ticks_list
		var attacks: Array = r.attack_ticks
		if attacks.size() < 3:
			printerr("FAIL: only %d leadshot volleys (%s)" % [attacks.size(), label])
			ok = false
		if telegraphs.size() != attacks.size():
			printerr(
				(
					"FAIL: leadshot %d telegraphs vs %d volleys (%s)"
					% [telegraphs.size(), attacks.size(), label]
				)
			)
			ok = false
		for i in mini(telegraphs.size(), attacks.size()):
			if attacks[i] - telegraphs[i] != lead:
				printerr(
					(
						"FAIL: leadshot telegraph lead %d != %d at volley %d (%s)"
						% [attacks[i] - telegraphs[i], lead, i, label]
					)
				)
				ok = false
				break
		for i in range(1, attacks.size()):
			if attacks[i] - attacks[i - 1] != period:
				printerr(
					(
						"FAIL: leadshot period %d != %d (%s)"
						% [attacks[i] - attacks[i - 1], period, label]
					)
				)
				ok = false
				break
		for i in r.volley_counts.size():
			if int(r.volley_counts[i]) != pattern.shots.size():
				printerr(
					(
						"FAIL: leadshot volley %d spawned %d darts (%s)"
						% [i, int(r.volley_counts[i]), label]
					)
				)
				ok = false
				break
		if int(r.other_hits) != 0:
			printerr(
				"FAIL: leadshot landed %d non-pattern-%d hits (%s)" % [r.other_hits, pid, label]
			)
			ok = false

	if int(sa.pattern_hits) < 3:
		printerr("FAIL: only %d darts hit the standing player" % int(sa.pattern_hits))
		ok = false
	if float(sa.dist_min) < float(ldef.range_min) - 0.6:
		printerr(
			(
				"FAIL: flanker closed to %.2f (band %s-%s)"
				% [sa.dist_min, ldef.range_min, ldef.range_max]
			)
		)
		ok = false
	if float(sa.dist_max) > float(ldef.range_max) + 0.6:
		printerr(
			(
				"FAIL: flanker drifted to %.2f (band %s-%s)"
				% [sa.dist_max, ldef.range_min, ldef.range_max]
			)
		)
		ok = false
	if absf(float(sa.sweep)) < 1.0:
		printerr("FAIL: flanker swept only %.2f rad — not circulating" % absf(float(sa.sweep)))
		ok = false
	if int(ma.pattern_hits) < 1:
		printerr("FAIL: no dart hit the strafing player — intercept lead not working")
		ok = false

	if ok:
		print(
			(
				"m6 leadshot ok: stand volleys=%d hits=%d band=[%.2f, %.2f] sweep=%.2f rad; mover hits=%d lead=%d period=%d"
				% [
					sa.attack_ticks.size(),
					int(sa.pattern_hits),
					float(sa.dist_min),
					float(sa.dist_max),
					float(sa.sweep),
					int(ma.pattern_hits),
					lead,
					period,
				]
			)
		)
	return ok


## Leadshot micro-world: player at (18,16) speed 3.0, leadshot at
## (28,16) — exactly its 10-tile trigger. mover=false: null input
## (band/orbit/timing witnesses). mover=true: square-wave perpendicular
## strafe, reversing every 90 ticks (constant-velocity legs for the
## intercept witness; ±4.5 tiles of travel stays in the open arena).
## Band and sweep sample after tick 300 (settled).
func _run_leadshot_once(ldef: Resource, mover: bool, ticks: int) -> Dictionary:
	var world := SimWorld.new()
	world.setup(24, _build_bitgrid())
	world.set_enemy_defs([ldef])
	var player := world.add_player(Vector2(18.0, 16.0))
	player.move_speed = 3.0
	var enemy: RefCounted = world.add_enemy(0, Vector2(28.0, 16.0))
	var slot: Resource = ldef.emitters[0]
	var pattern: Resource = slot.pattern
	var pid := int(pattern.pattern_id)
	var hashes: Array[int] = []
	var telegraph_ticks_list: Array[int] = []
	var attack_ticks: Array[int] = []
	var volley_counts: Array[int] = []
	var pattern_hits := 0
	var other_hits := 0
	var dist_min := 1.0e9
	var dist_max := 0.0
	var sweep := 0.0
	var prev_bearing: float = (enemy.pos - player.pos).angle()
	for t in ticks:
		var frame: RefCounted = null
		if mover:
			frame = InputFrame.new()
			@warning_ignore("integer_division")
			frame.move_y = 1 if (t / 90) % 2 == 0 else -1
			frame.normalized = true
		world.step([frame])
		var fired := false
		var spawned_this_tick := 0
		for ev: Dictionary in world.events:
			match int(ev.type):
				SimEvents.Type.TELEGRAPH_STARTED:
					if int(ev.id) == enemy.id:
						telegraph_ticks_list.append(int(ev.tick))
				SimEvents.Type.ATTACK_STARTED:
					if int(ev.get("enemy", 0)) == enemy.id:
						attack_ticks.append(int(ev.tick))
						fired = true
				SimEvents.Type.PROJECTILE_SPAWNED:
					if int(ev.pattern) == pid:
						spawned_this_tick += 1
				SimEvents.Type.DAMAGE_APPLIED:
					if int(ev.target) == player.id:
						if int(ev.pattern) == pid:
							pattern_hits += 1
						else:
							other_hits += 1
		if fired:
			volley_counts.append(spawned_this_tick)
		var bearing: float = (enemy.pos - player.pos).angle()
		sweep += wrapf(bearing - prev_bearing, -PI, PI)
		prev_bearing = bearing
		if t >= 300:
			var d: float = enemy.pos.distance_to(player.pos)
			dist_min = minf(dist_min, d)
			dist_max = maxf(dist_max, d)
		if (world.tick % HASH_EVERY) == 0:
			hashes.append(world.state_hash())
	return {
		"hashes": hashes,
		"telegraph_ticks_list": telegraph_ticks_list,
		"attack_ticks": attack_ticks,
		"volley_counts": volley_counts,
		"pattern_hits": pattern_hits,
		"other_hits": other_hits,
		"dist_min": dist_min,
		"dist_max": dist_max,
		"sweep": sweep,
	}


## M6 Blightcaster contract (docs/12 §3.4 row 6, SERIAL 11), mechanized
## in two runs, every number from the shipped .tres resources:
## STANDING target: double-run hash equality; casts on the exact
## fire-to-fire period; the zone's first damage lands exactly arm_ticks
## after its placement telegraph (§3.4: "telegraph 45 = full arm time" —
## the arming zone IS the warning); pulses continue every
## hit_interval_ticks; a full-stood zone lands exactly
## 1 + linger/interval hits then expires (no sixth pulse); live-zone
## count stays bounded; the keep-range caster holds its band.
## REACTIVE WALKER at 3.0 t/s (lowest speed): stands until the zone's
## placement telegraph appears at their feet, then walks — and takes
## ZERO hits. That is the CORE-33 escape witness: center-to-edge 1.63
## tiles inside a 45-tick arm window at 3.0 t/s leaves ~12 ticks spare.
func _check_blightcaster() -> bool:
	var bdef: Resource = load("res://data/enemies/blightcaster.tres")
	var slot: Resource = bdef.emitters[0]
	var hz: Resource = slot.hazard
	var pid := int(hz.pattern_id)
	var arm := int(hz.arm_ticks)
	var interval := int(hz.hit_interval_ticks)
	var per_zone := 1 + int(hz.linger_ticks) / maxi(1, interval)
	var period := int(slot.cooldown_ticks)
	var ok := true

	var sa := _run_blight_once(bdef, false)
	var sb := _run_blight_once(bdef, false)
	if sa.hashes != sb.hashes:
		printerr("FAIL: blightcaster standing runs diverge")
		ok = false
	var wa := _run_blight_once(bdef, true)
	var wb := _run_blight_once(bdef, true)
	if wa.hashes != wb.hashes:
		printerr("FAIL: blightcaster walker runs diverge")
		ok = false

	var attacks: Array = sa.attack_ticks
	if attacks.size() < 3:
		printerr("FAIL: only %d blightcaster casts" % attacks.size())
		ok = false
	for i in range(1, attacks.size()):
		if attacks[i] - attacks[i - 1] != period:
			printerr("FAIL: blight cast period %d != %d" % [attacks[i] - attacks[i - 1], period])
			ok = false
			break
	var hits: Array = sa.hit_ticks
	if hits.size() < per_zone:
		printerr("FAIL: only %d blight hits on a standing player" % hits.size())
		ok = false
	else:
		var lead: int = int(hits[0]) - int(sa.telegraph_before_first_hit)
		if lead != arm:
			printerr("FAIL: blight first-damage lead %d != arm %d" % [lead, arm])
			ok = false
		for i in range(1, per_zone):
			if int(hits[i]) - int(hits[i - 1]) != interval:
				printerr(
					(
						"FAIL: blight pulse gap %d != %d at hit %d"
						% [int(hits[i]) - int(hits[i - 1]), interval, i]
					)
				)
				ok = false
				break
		var zone_end: int = int(hits[0]) + int(hz.linger_ticks)
		var in_first_zone := 0
		for ht: int in hits:
			if ht <= zone_end:
				in_first_zone += 1
		if in_first_zone != per_zone:
			printerr(
				(
					"FAIL: first zone landed %d hits (expected exactly %d) — expiry leak?"
					% [in_first_zone, per_zone]
				)
			)
			ok = false
	if int(sa.armed_events) != attacks.size():
		printerr(
			"FAIL: %d HAZARD_ARMED events for %d casts" % [int(sa.armed_events), attacks.size()]
		)
		ok = false
	if int(sa.max_live_zones) > 2:
		printerr("FAIL: %d zones live at once (bound 2)" % int(sa.max_live_zones))
		ok = false
	if float(sa.dist_min) < float(bdef.range_min) - 0.6:
		printerr(
			(
				"FAIL: blightcaster closed to %.2f (band %s-%s)"
				% [sa.dist_min, bdef.range_min, bdef.range_max]
			)
		)
		ok = false
	if float(sa.dist_max) > float(bdef.range_max) + 0.6:
		printerr(
			(
				"FAIL: blightcaster drifted to %.2f (band %s-%s)"
				% [sa.dist_max, bdef.range_min, bdef.range_max]
			)
		)
		ok = false
	if int(wa.hit_ticks.size()) != 0:
		printerr(
			(
				"FAIL: reactive walker took %d blight hits — zone not escapable at 3.0"
				% wa.hit_ticks.size()
			)
		)
		ok = false
	if ok:
		print(
			(
				"m6 blightcaster ok: casts=%d period=%d first-lead=%d pulses x%d gap=%d walker-hits=0 band=[%.2f, %.2f]"
				% [
					attacks.size(),
					period,
					arm,
					per_zone,
					interval,
					float(sa.dist_min),
					float(sa.dist_max),
				]
			)
		)
	return ok


## Blightcaster micro-world: player at (24,16) speed 3.0, caster at
## (30,16) — inside trigger and band, so it casts immediately.
## reactive_walker=false stands forever (pulse-train witness); true
## walks 60 ticks (3 tiles — past the 1.63-tile escape radius with
## margin) each time a placement telegraph appears at the player's
## feet, alternating direction per zone so the bounce stays inside the
## lab arena's open pocket (a straight-line walker pinned itself on
## interior props and ate zones — the alternating escape is also the
## stronger witness: every zone is escaped from center at 3.0).
func _run_blight_once(bdef: Resource, reactive_walker: bool) -> Dictionary:
	var world := SimWorld.new()
	world.setup(25, _build_bitgrid())
	world.set_enemy_defs([bdef])
	var player := world.add_player(Vector2(24.0, 16.0))
	player.move_speed = 3.0
	# Harness allowance (like move_speed): a shipped-hp stander dies to
	# zone 2 and silences later casts — the period/expiry assertions need
	# four full cast cycles observed.
	player.hp = 300
	var enemy: RefCounted = world.add_enemy(0, Vector2(30.0, 16.0))
	var slot: Resource = bdef.emitters[0]
	var hzdef: Resource = slot.hazard
	var pid := int(hzdef.pattern_id)
	var hashes: Array[int] = []
	var attack_ticks: Array[int] = []
	var hit_ticks: Array[int] = []
	var telegraph_before_first_hit := -1
	var last_pattern_telegraph := -1
	var armed_events := 0
	var max_live_zones := 0
	var dist_min := 1.0e9
	var dist_max := 0.0
	var walk_until := -1
	var walk_dir := 0
	var next_dir := -1
	for t in 600:
		var frame: RefCounted = null
		if t < walk_until:
			frame = InputFrame.new()
			frame.move_x = walk_dir
			frame.normalized = true
		world.step([frame])
		for ev: Dictionary in world.events:
			match int(ev.type):
				SimEvents.Type.TELEGRAPH_STARTED:
					if int(ev.get("pattern", 0)) == pid:
						last_pattern_telegraph = int(ev.tick)
						var epos: Vector2 = ev.pos
						if reactive_walker and epos.distance_to(player.pos) < 0.1:
							walk_dir = next_dir
							next_dir = -next_dir
							walk_until = t + 60
				SimEvents.Type.ATTACK_STARTED:
					if int(ev.get("enemy", 0)) == enemy.id:
						attack_ticks.append(int(ev.tick))
				SimEvents.Type.HAZARD_ARMED:
					armed_events += 1
				SimEvents.Type.DAMAGE_APPLIED:
					if int(ev.target) == player.id and int(ev.pattern) == pid:
						if hit_ticks.is_empty():
							telegraph_before_first_hit = last_pattern_telegraph
						hit_ticks.append(int(ev.tick))
		max_live_zones = maxi(max_live_zones, world.hazards.size())
		if t >= 200:
			var d: float = enemy.pos.distance_to(player.pos)
			dist_min = minf(dist_min, d)
			dist_max = maxf(dist_max, d)
		if (world.tick % HASH_EVERY) == 0:
			hashes.append(world.state_hash())
	return {
		"hashes": hashes,
		"attack_ticks": attack_ticks,
		"hit_ticks": hit_ticks,
		"telegraph_before_first_hit": telegraph_before_first_hit,
		"armed_events": armed_events,
		"max_live_zones": max_live_zones,
		"dist_min": dist_min,
		"dist_max": dist_max,
	}


## Yard Warden elite contracts (§3.5, SERIAL 12, planning decision
## 2026-07-28): HP% thresholds swap phases at EXACT ticks under the
## scenario damage schedule (top-of-step application, same-tick enemy
## step); a multi-threshold drop settles at the final phase with ONE
## crossing event; schedule damage carries pattern -4 through THE
## damage path; per-phase telegraph leads / volley sizes / periods
## match the def exactly; the ROTOR radial advances its world-frame
## aim by rotor_deg_per_tick x elapsed; P2 anchors bit-still; every
## transition re-arms (entry beat + full telegraph before the first
## post-flip volley); peak live hostile stays under the elite budget;
## the kill lands through the normal sweep.
func _check_yard_warden() -> bool:
	var wdef: Resource = load("res://data/enemies/yard_warden.tres")
	var budgets: Resource = load("res://data/budgets.tres")
	var ok := true
	if int(wdef.hp) != 575:
		printerr("FAIL: yard warden hp %d != 575 (§3.5 as ruled 2026-07-29)" % int(wdef.hp))
		ok = false
	var plist: Array = wdef.phases.phases
	if plist.size() != 3:
		printerr("FAIL: yard warden has %d phases (expected 3)" % plist.size())
		return false
	var floors: Array[float] = []
	for pe: Resource in plist:
		floors.append(float(pe.hp_floor_pct))
	if floors != [66.0, 33.0, 0.0]:
		printerr("FAIL: phase floors %s != [66, 33, 0]" % [floors])
		ok = false

	# --- Threshold exactness + kill (575 HP, floors 379.5/189.75):
	# 196 -> 379 hp (65.9% <= 66) must flip to P2 AT t100; 190 more ->
	# 189 hp (32.9% <= 33) at t200 flips P3; final 189 -> 0 at t300
	# kills through the sweep.
	var thr := _run_warden(
		wdef,
		[{"tick": 100, "amount": 196}, {"tick": 200, "amount": 190}, {"tick": 300, "amount": 189}],
		400
	)
	var changes: Array = thr.phase_changes
	if changes.size() != 2:
		printerr("FAIL: %d phase changes (expected 2)" % changes.size())
		ok = false
	else:
		var c0: Dictionary = changes[0]
		var c1: Dictionary = changes[1]
		if int(c0.tick) != 100 or int(c0.phase) != 1 or int(c0.hp) != 379:
			printerr("FAIL: first crossing %s != {tick 100, phase 1, hp 379}" % [c0])
			ok = false
		if int(c1.tick) != 200 or int(c1.phase) != 2 or int(c1.hp) != 189:
			printerr("FAIL: second crossing %s != {tick 200, phase 2, hp 189}" % [c1])
			ok = false
	if int(thr.elite_kill_tick) != 300:
		printerr("FAIL: elite kill tick %d != 300" % int(thr.elite_kill_tick))
		ok = false
	var sched_ticks: Array = thr.schedule_hit_ticks
	if sched_ticks != [100, 200, 300]:
		printerr("FAIL: pattern -4 damage ticks %s != [100, 200, 300]" % [sched_ticks])
		ok = false

	# --- Multi-threshold single application settles at the FINAL phase
	# with exactly one crossing event (460 in one hit: 575 -> 115 = P3).
	var skip := _run_warden(wdef, [{"tick": 50, "amount": 460}], 120)
	var skip_changes: Array = skip.phase_changes
	if skip_changes.size() != 1:
		printerr("FAIL: rapid drop made %d crossings (expected 1)" % skip_changes.size())
		ok = false
	else:
		var sc: Dictionary = skip_changes[0]
		if int(sc.tick) != 50 or int(sc.phase) != 2:
			printerr("FAIL: rapid drop settled %s != {tick 50, phase 2}" % [sc])
			ok = false

	# --- P1 contract (fresh spawn, no schedule): fan (slot order, both
	# open, dist 6 inside trigger 7) leads exactly 30 with 7 shots;
	# triple follows at lead 24 with 3; fan period exactly 150.
	var p1 := _run_warden(wdef, [], 700)
	if not _assert_pattern(p1, 17, 30, 7, 150, "P1 fan"):
		ok = false
	if not _assert_pattern(p1, 16, 24, 3, 90, "P1 triple"):
		ok = false
	if not p1.phase_changes.is_empty():
		printerr("FAIL: movement-only P1 run crossed phases: %s" % [p1.phase_changes])
		ok = false

	# --- P2 contract (t0 drop to 345 = 60%): radial lead exactly 36 x12
	# shots period 120; zone cast places pattern-18 telegraphs; the
	# first post-flip telegraph honors entry beat 30; the anchor is
	# bit-still from entry to the run's end; ROTOR advance is exact.
	var p2 := _run_warden(wdef, [{"tick": 0, "amount": 230}], 700)
	if not _assert_pattern(p2, 19, 36, 12, 120, "P2 radial"):
		ok = false
	var p2_entry: Resource = plist[1]
	var first_tel := 1 << 30
	var tel_map: Dictionary = p2.telegraphs
	for pid: int in tel_map:
		var arr: Array = tel_map[pid]
		if not arr.is_empty():
			first_tel = mini(first_tel, int(arr[0]))
	if first_tel < int(p2_entry.entry_cooldown_ticks):
		printerr(
			(
				"FAIL: post-flip telegraph at %d before entry beat %d"
				% [first_tel, int(p2_entry.entry_cooldown_ticks)]
			)
		)
		ok = false
	if not tel_map.has(18) or (tel_map[18] as Array).size() < 2:
		printerr("FAIL: P2 zone cast placed %s pattern-18 telegraphs" % [tel_map.get(18, [])])
		ok = false
	if float(p2.elite_moved) != 0.0:
		printerr("FAIL: P2 anchor moved %.6f tiles" % float(p2.elite_moved))
		ok = false
	var radial_attacks: Array = (p2.attacks as Dictionary).get(19, [])
	if radial_attacks.size() >= 2:
		var a0: Dictionary = radial_attacks[0]
		var a1: Dictionary = radial_attacks[1]
		var aim0: Vector2 = a0.aim
		var aim1: Vector2 = a1.aim
		var want := deg_to_rad(float(a1.tick - a0.tick) * float(_radial_rotor(wdef)))
		var got := wrapf(aim1.angle() - aim0.angle(), -PI, PI)
		if absf(got - wrapf(want, -PI, PI)) > 0.0001:
			printerr("FAIL: rotor advanced %.5f rad (expected %.5f)" % [got, want])
			ok = false

	# --- P3 contract (t0 drop to 172 = 29.9%): chaser closes on a
	# stander; burst x4 lead 24, volley x3 lead 40 (INTERCEPT), fan
	# re-used.
	var p3 := _run_warden(wdef, [{"tick": 0, "amount": 403}], 700)
	if not _assert_pattern(p3, 21, 24, 4, 60, "P3 burst"):
		ok = false
	if not _assert_pattern(p3, 20, 40, 3, 120, "P3 volley"):
		ok = false
	# Chase witness: the elite spends most of P3 winding/firing (stand-
	# still states), so approach is stepwise — 1.5 tiles on a stander
	# proves the CHASER policy is live without over-fitting the pace.
	if float(p3.elite_closed) < 1.5:
		printerr("FAIL: P3 chaser closed only %.2f tiles" % float(p3.elite_closed))
		ok = false

	# --- Density: worst observed peak across the three phase runs sits
	# under the elite budget (the proof reports carry the same figure).
	var peak := maxi(maxi(int(p1.max_live), int(p2.max_live)), int(p3.max_live))
	if peak > int(budgets.hostile_elite_max):
		printerr("FAIL: peak %d exceeds elite budget %d" % [peak, int(budgets.hostile_elite_max)])
		ok = false

	# --- Determinism with the schedule active: twin P2 runs bit-match.
	var p2b := _run_warden(wdef, [{"tick": 0, "amount": 230}], 700)
	if p2.hashes != p2b.hashes:
		printerr("FAIL: schedule-driven runs diverge")
		ok = false

	if ok:
		print(
			(
				"m6 yard warden ok: crossings@[100,200] kill@300 skip->P3 x1; leads fan=30 triple=24 radial=36 volley=40 burst=24; anchor-still rotor-exact chaser-closed=%.1f peak=%d/%d"
				% [float(p3.elite_closed), peak, int(budgets.hostile_elite_max)]
			)
		)
	return ok


## Multi-slot cadence slack (ticks): the longest a reopened slot gate
## can wait out the other slots' windup + recover cycles in any §3.5
## phase (P3 worst case: burst 24+10 plus fan 30+20 ≈ 84).
const PERIOD_SLACK := 90


## Rotor rate of the P2 radial (read from data, never hard-coded).
func _radial_rotor(wdef: Resource) -> float:
	var p2: Resource = wdef.phases.phases[1]
	var emitters: Array = p2.emitters
	for es: Resource in emitters:
		var pattern: Resource = es.pattern
		if pattern != null and int(pattern.pattern_id) == 19:
			return float(pattern.rotor_deg_per_tick)
	return 0.0


## Assert one elite pattern's contract from a run's event record: first
## telegraph lead is exactly the slot's, every volley is exactly the
## def's shot count, and consecutive same-pattern attacks respect the
## slot cadence: never FASTER than cooldown (the hard law), at most
## cooldown + PERIOD_SLACK later (multi-slot §3.5 semantics: one state
## machine serializes attacks, so a slot's reopened gate can wait out
## another slot's windup + recover — exact periods are a single-slot
## property the ordinary checks keep).
func _assert_pattern(
	run: Dictionary, pid: int, lead: int, volley: int, period: int, label: String
) -> bool:
	var ok := true
	var attacks_map: Dictionary = run.attacks
	var attacks: Array = attacks_map.get(pid, [])
	if attacks.is_empty():
		printerr("FAIL: %s never fired" % label)
		return false
	var telegraphs_map: Dictionary = run.telegraphs
	var tels: Array = telegraphs_map.get(pid, [])
	if tels.is_empty():
		printerr("FAIL: %s fired with no telegraph" % label)
		return false
	var a0: Dictionary = attacks[0]
	var got_lead := int(a0.tick) - int(tels[0])
	if got_lead != lead:
		printerr("FAIL: %s lead %d != %d" % [label, got_lead, lead])
		ok = false
	var volleys_map: Dictionary = run.volley_sizes
	var sizes: Array = volleys_map.get(pid, [])
	for s: int in sizes:
		if s != volley:
			printerr("FAIL: %s volley %d != %d shots" % [label, s, volley])
			ok = false
			break
	for i in range(1, attacks.size()):
		var prev: Dictionary = attacks[i - 1]
		var cur: Dictionary = attacks[i]
		var gap := int(cur.tick) - int(prev.tick)
		if gap < period or gap > period + PERIOD_SLACK:
			printerr(
				"FAIL: %s gap %d outside [%d, %d]" % [label, gap, period, period + PERIOD_SLACK]
			)
			ok = false
			break
	return ok


## Elite micro-world: standing player at (24,16) speed 3.0 (harness hp
## allowance — patterns are observed, not dodged; escapability proofs
## are DodgeBot territory), warden at (30,16) = dist 6. The damage
## schedule drives phases exactly like a proof scenario would.
func _run_warden(wdef: Resource, schedule: Array, ticks: int) -> Dictionary:
	var world := SimWorld.new()
	world.setup(31, _build_bitgrid())
	world.set_enemy_defs([wdef])
	world.set_damage_schedule(schedule)
	var player := world.add_player(Vector2(24.0, 16.0))
	player.move_speed = 3.0
	player.hp = 9000
	var enemy: RefCounted = world.add_enemy(0, Vector2(30.0, 16.0))
	var elite_id: int = enemy.id
	var spawn_pos: Vector2 = enemy.pos
	var hashes: Array[int] = []
	var phase_changes: Array = []
	var telegraphs := {}
	var attacks := {}
	var volley_sizes := {}
	var schedule_hit_ticks: Array[int] = []
	var elite_kill_tick := -1
	var max_live := 0
	var anchor_from := -1
	var elite_moved := 0.0
	var dist_start := spawn_pos.distance_to(player.pos)
	var dist_min := dist_start
	var anchor_pos := Vector2.ZERO
	for t in ticks:
		world.step([null])
		var spawns_this_tick := {}
		for ev: Dictionary in world.events:
			match int(ev.type):
				SimEvents.Type.PHASE_CHANGED:
					phase_changes.append(
						{"tick": int(ev.tick), "phase": int(ev.phase), "hp": int(ev.hp)}
					)
					if int(ev.phase) == 1:
						anchor_from = int(ev.tick)
						anchor_pos = ev.pos
				SimEvents.Type.TELEGRAPH_STARTED:
					var pid := int(ev.get("pattern", 0))
					if not telegraphs.has(pid):
						telegraphs[pid] = []
					(telegraphs[pid] as Array).append(int(ev.tick))
				SimEvents.Type.ATTACK_STARTED:
					var apid := int(ev.pattern)
					if not attacks.has(apid):
						attacks[apid] = []
					(attacks[apid] as Array).append(
						{"tick": int(ev.tick), "aim": ev.aim as Vector2}
					)
				SimEvents.Type.PROJECTILE_SPAWNED:
					var spid := int(ev.pattern)
					spawns_this_tick[spid] = int(spawns_this_tick.get(spid, 0)) + 1
				SimEvents.Type.DAMAGE_APPLIED:
					if int(ev.pattern) == SimWorld.PATTERN_TEST_SCHEDULE:
						schedule_hit_ticks.append(int(ev.tick))
				SimEvents.Type.ENTITY_KILLED:
					if int(ev.id) == elite_id:
						elite_kill_tick = int(ev.tick)
		for spid: int in spawns_this_tick:
			if not volley_sizes.has(spid):
				volley_sizes[spid] = []
			(volley_sizes[spid] as Array).append(int(spawns_this_tick[spid]))
		max_live = maxi(max_live, _live_hostile(world))
		if elite_kill_tick < 0:
			var epos: Vector2 = enemy.pos
			dist_min = minf(dist_min, epos.distance_to(player.pos))
			if anchor_from >= 0:
				elite_moved = maxf(elite_moved, epos.distance_to(anchor_pos))
		if (world.tick % HASH_EVERY) == 0:
			hashes.append(world.state_hash())
	return {
		"hashes": hashes,
		"phase_changes": phase_changes,
		"telegraphs": telegraphs,
		"attacks": attacks,
		"volley_sizes": volley_sizes,
		"schedule_hit_ticks": schedule_hit_ticks,
		"elite_kill_tick": elite_kill_tick,
		"max_live": max_live,
		"elite_moved": elite_moved,
		"elite_closed": dist_start - dist_min,
	}


func _live_hostile(world: RefCounted) -> int:
	var pool: RefCounted = world.projectiles
	var act: PackedByteArray = pool.active
	var fac: PackedByteArray = pool.faction
	var n := 0
	for s in pool.CAPACITY:
		if act[s] == 1 and fac[s] == 1:
			n += 1
	return n


## CORE-51 Law 4 ordering check as code (§3.4 pattern-review line):
## telegraph prominence sorted by the DESIGNED danger ranking must be
## non-decreasing — equal-danger rungs share a value, and a retune that
## reintroduces an inversion fails here. Values are read live from the
## defs, never hard-coded.
func _check_law4_ordering() -> bool:
	var rows: Array = [
		["rusher slash", _slot_tele("res://data/enemies/rusher.tres", 0)],
		["husk aimed", _slot_tele("res://data/enemies/husk_archer.tres", 0)],
		["yw triple", _phase_slot_tele("res://data/enemies/yard_warden.tres", 0, 1)],
		["yw burst", _phase_slot_tele("res://data/enemies/yard_warden.tres", 2, 0)],
		["fanmaw fan", _slot_tele("res://data/enemies/fanmaw.tres", 0)],
		["yw fan", _phase_slot_tele("res://data/enemies/yard_warden.tres", 0, 0)],
		["tusk sweep", _phase_slot_tele("res://data/enemies/old_tusk.tres", 0, 0)],
		["ringer radial", _slot_tele("res://data/enemies/ringer.tres", 0)],
		["yw radial", _phase_slot_tele("res://data/enemies/yard_warden.tres", 1, 0)],
		["leadshot dart", _slot_tele("res://data/enemies/leadshot.tres", 0)],
		["yw volley", _phase_slot_tele("res://data/enemies/yard_warden.tres", 2, 2)],
		["gore rush", _phase_slot_tele("res://data/enemies/old_tusk.tres", 1, 1)],
		["blight zone arm", _zone_arm("res://data/enemies/blightcaster.tres")],
		["yw zone arm", _phase_zone_arm("res://data/enemies/yard_warden.tres", 1, 1)],
		["tusk mud arm", _phase_zone_arm("res://data/enemies/old_tusk.tres", 2, 2)],
	]
	var prev := -1
	for row: Array in rows:
		var v := int(row[1])
		if v < prev:
			printerr("FAIL: Law-4 inversion at %s (%d < %d)" % [String(row[0]), v, prev])
			return false
		prev = v
	print("law-4 ordering ok: %d rows non-decreasing, max %d" % [rows.size(), prev])
	return true


func _slot_tele(path: String, slot: int) -> int:
	var def: Resource = load(path)
	var es: Resource = def.emitters[slot]
	return int(es.telegraph_ticks)


func _phase_slot_tele(path: String, phase: int, slot: int) -> int:
	var def: Resource = load(path)
	var pe: Resource = def.phases.phases[phase]
	var es: Resource = pe.emitters[slot]
	return int(es.telegraph_ticks)


func _zone_arm(path: String) -> int:
	var def: Resource = load(path)
	var es: Resource = def.emitters[0]
	var hz: Resource = es.hazard
	return int(hz.arm_ticks)


func _phase_zone_arm(path: String, phase: int, slot: int) -> int:
	var def: Resource = load(path)
	var pe: Resource = def.phases.phases[phase]
	var es: Resource = pe.emitters[slot]
	var hz: Resource = es.hazard
	return int(hz.arm_ticks)


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
