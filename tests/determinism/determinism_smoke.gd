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
