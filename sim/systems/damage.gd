extends RefCounted
## THE damage-resolution path (docs/12 §2.1): every hit point flowing to any
## actor — projectile, hazard, ability, contact — lands through apply(), so
## god-mode visibility, player death-in-place, and the event trail are
## uniform by construction. Extracted at M5 from projectile_step/hazard_step
## (which had grown twin inline copies) before enemy contact damage added a
## third. Event order per damaging hit is preserved exactly:
## [ENTITY_KILLED(player)] -> [HIT_LANDED if projectile] -> DAMAGE_APPLIED.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const ActorState := preload("res://sim/actor_state.gd")
const SimEvents := preload("res://sim/events.gd")
const Progress := preload("res://sim/systems/progress.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const PlayerRespawn := preload("res://sim/systems/player_respawn.gd")


## Apply `amount` to actor `a`. hit_slot >= 0 marks a projectile hit and
## emits HIT_LANDED with that pool slot. God flag (§2.10): friendly damage
## becomes a visible DAMAGE_IMMUNE — logged, never silent, so god use can't
## launder into evidence.
static func apply(
	world: RefCounted, a: RefCounted, amount: int, pattern: int, hit_slot := -1
) -> void:
	var t: int = world.tick
	var events: Array[Dictionary] = world.events
	if world.god_mode and a.faction == ActorState.FACTION_FRIENDLY:
		(
			events
			. append(
				{
					"type": SimEvents.Type.DAMAGE_IMMUNE,
					"tick": t,
					"target": a.id,
					"amount": amount,
					"pattern": pattern,
					"pos": a.pos,
				}
			)
		)
		return
	# Mitigation through THE path — every source uniform. The §2.11 test
	# schedule bypasses it by contract (mitigation-bypassing tag).
	# Friendly: two lanes inside Progress.mitigate (docs/22 formula for
	# class-backed, Loop v1 flat table frozen for legacy). Hostile: THE
	# formula on the armor VALUE — 0 today, so enemy armor is a data
	# change when a chapter needs it, never a code change.
	if pattern != world.PATTERN_TEST_SCHEDULE:
		if a.faction == ActorState.FACTION_FRIENDLY:
			amount = Progress.mitigate(world, a, amount)
		elif a.armor > 0:
			amount = StatFrame.taken(amount, a.armor)
	a.hp -= amount
	a.last_damaged_tick = t
	# sl-0115 hit grace: a rift BULLET hit arms the short grace window
	# (prototype i-frames, 60 t/s converted; drains never arm it — the
	# clock is the clock). The snap branch below assigns its own longer
	# grace over this.
	if world.rift_pull != null and a.faction == ActorState.FACTION_FRIENDLY and hit_slot >= 0:
		a.line_iframe_until = maxi(a.line_iframe_until, t + int(world.rift_pull.hit_iframe_ticks))
	# THE LINE SNAPS (sl-0115): in a rift arena, a depleted stability
	# pool burns one of the three lives instead of killing — the line
	# re-spools full, a snap-grace window arms (bullets only; the
	# drains never pause), and the fight continues. The THIRD snap
	# falls through to the normal death path: the dive is lost.
	if (
		a.hp <= 0
		and a.faction == ActorState.FACTION_FRIENDLY
		and not a.dead
		and world.rift_pull != null
		and a.line_lives > 1
	):
		a.line_lives -= 1
		a.hp = a.max_hp
		a.line_drain_acc = 0
		a.line_iframe_until = t + int(world.rift_pull.snap_grace_ticks)
		(
			events
			. append(
				{
					"type": SimEvents.Type.LINE_SNAPPED,
					"tick": t,
					"player": a.id,
					"lives_left": a.line_lives,
					"pattern": pattern,
					"pos": a.pos,
				}
			)
		)
		if hit_slot >= 0:
			(
				events
				. append(
					{
						"type": SimEvents.Type.HIT_LANDED,
						"tick": t,
						"slot": hit_slot,
						"target": a.id,
						"damage": amount,
						"pattern": pattern,
						"pos": a.pos,
					}
				)
			)
		(
			events
			. append(
				{
					"type": SimEvents.Type.DAMAGE_APPLIED,
					"tick": t,
					"target": a.id,
					"amount": amount,
					"hp": a.hp,
					"pattern": pattern,
					"pos": a.pos,
				}
			)
		)
		return
	# Player death. Persistent worlds (CORE-43, slice seam 3): the
	# gold cost lands IN-SIM at the death tick ([T] percentage of
	# CARRIED gold, progression data) and the settlement respawn
	# timer arms — the world persists, no run framing (sl-0098).
	# Everywhere else: dies in place (recap + restart own the flow).
	# Enemy death stays with the sweep.
	if a.hp <= 0 and a.faction == ActorState.FACTION_FRIENDLY and not a.dead:
		a.hp = 0
		a.dead = true
		var gold_lost := 0
		if world.persistent_respawn and a.class_id >= 0:
			var pct := 25
			if world.progression != null:
				pct = int(world.progression.death_gold_pct)
			gold_lost = a.gold * pct / 100
			a.gold -= gold_lost
			a.respawn_at_tick = t + PlayerRespawn.RESPAWN_DELAY_TICKS
		(
			events
			. append(
				{
					"type": SimEvents.Type.ENTITY_KILLED,
					"tick": t,
					"id": a.id,
					"pos": a.pos,
					"player": true,
					"gold_lost": gold_lost,
				}
			)
		)
	if hit_slot >= 0:
		(
			events
			. append(
				{
					"type": SimEvents.Type.HIT_LANDED,
					"tick": t,
					"slot": hit_slot,
					"target": a.id,
					"damage": amount,
					"pattern": pattern,
					"pos": a.pos,
				}
			)
		)
	(
		events
		. append(
			{
				"type": SimEvents.Type.DAMAGE_APPLIED,
				"tick": t,
				"target": a.id,
				"amount": amount,
				"hp": a.hp,
				"pattern": pattern,
				"pos": a.pos,
			}
		)
	)


## The resolution path's tail: emit enemy kills (with def_index + TTK for
## the §2.10 telemetry — CORE-36's honest-health evidence), then compact.
## Players are never removed here (they die in place, flagged).
static func sweep_dead_enemies(world: RefCounted) -> void:
	var t: int = world.tick
	var any_dead := false
	for e: RefCounted in world.enemies:
		if e.hp <= 0:
			any_dead = true
			(
				world
				. events
				. append(
					{
						"type": SimEvents.Type.ENTITY_KILLED,
						"tick": t,
						"id": e.id,
						"pos": e.pos,
						"def_index": e.def_index,
						"ttk_ticks": t - e.spawned_at_tick,
					}
				)
			)
			_award_kill(world, e)
	if any_dead:
		world.enemies = world.enemies.filter(func(e: RefCounted) -> bool: return e.hp > 0)


## Loop v1 kill awards (docs/19): XP to every player, then the drop
## rolls — ONE fixed rng_loot draw sequence per kill (gold, item chance,
## kind, params, then each unique in table order), so loot is exactly as
## deterministic as everything else (§2.4). Defs whose drop fields sit
## at defaults draw only what their data enables — a def with no gold,
## no chance, and no uniques draws NOTHING, keeping pre-loop scenarios
## byte-identical.
static func _award_kill(world: RefCounted, e: RefCounted) -> void:
	var di: int = e.def_index
	if di < 0 or di >= world.enemy_defs.size():
		return
	var def: Resource = world.enemy_defs[di]
	var xp := int(def.xp_value)
	if xp > 0:
		for p: RefCounted in world.players:
			Progress.award_xp(world, p, xp)
	var rng: RefCounted = world.rng_loot
	# STARHOOK v2 (sl-0115) — THE WIN IS PURELY THE KILL: in a rift
	# arena the catch's pay BANKS directly (no ground drops — the dive
	# ends on the kill; correction #7, the reel is cut). Draw order is
	# fixed: gold, uniques (both the def's own rolls), then the FISH
	# from the biome's table (weighted commons; the rare rarity always
	# lands the biome's rare species). Species persist per-species at
	# harvest — fish are species-currency (deck tap shk2ctch).
	if world.rift_pull != null:
		if int(def.gold_max) > 0:
			var pot: int = (
				int(def.gold_min) + rng.next_bounded(int(def.gold_max) - int(def.gold_min) + 1)
			)
			for p: RefCounted in world.players:
				p.gold += pot
		var runiques: Array = def.unique_drops
		for rui in runiques.size():
			if rng.next_unit() < float(def.unique_chances[rui]):
				var ridx: int = world.unique_defs.find(runiques[rui])
				if ridx >= 0:
					for p: RefCounted in world.players:
						p.unique_mask |= 1 << ridx
		var fish := 3
		if not world.rift_rare:
			var biomes: Array = world.stat_frame.get("starhook", {}).get("biomes", [])
			fish = 0
			if world.rift_biome < biomes.size():
				var table: Array = biomes[world.rift_biome].get("fish", [])
				var roll: int = rng.next_bounded(100)
				var acc := 0
				for fi in table.size():
					acc += int(table[fi].get("w", 0))
					if roll < acc:
						fish = fi
						break
		var catch := {"biome": world.rift_biome, "fish": fish, "rare": world.rift_rare}
		world.rift_catches.append(catch)
		(
			world
			. events
			. append(
				{
					"type": SimEvents.Type.CATCH_LANDED,
					"tick": world.tick,
					"biome": world.rift_biome,
					"fish": fish,
					"rare": world.rift_rare,
					"pos": e.pos,
				}
			)
		)
		return
	if int(def.gold_max) > 0:
		var amt: int = (
			int(def.gold_min) + rng.next_bounded(int(def.gold_max) - int(def.gold_min) + 1)
		)
		if amt > 0:
			world.spawn_drop(e.pos, world.DROP_GOLD, amt)
	if float(def.drop_chance) > 0.0 and rng.next_unit() < float(def.drop_chance):
		var ww := int(def.drop_w_weapon)
		var wa := int(def.drop_w_armor)
		var wb := int(def.drop_w_ability)
		# S1 seam 2: rings join the kind roll ONLY when a def sets the
		# weight — wr == 0 leaves total, roll, and every draw below
		# byte-identical for the whole pre-slice roster.
		var wr := int(def.drop_w_ring)
		var total := ww + wa + wb + wr
		if total > 0:
			var roll: int = rng.next_bounded(total)
			var tier: int = (
				int(def.drop_tier_min)
				+ rng.next_bounded(int(def.drop_tier_max) - int(def.drop_tier_min) + 1)
			)
			if roll < ww:
				world.spawn_drop(
					e.pos, world.DROP_WEAPON, rng.next_bounded(world.weapon_frames.size()), tier
				)
			elif roll < ww + wa:
				world.spawn_drop(e.pos, world.DROP_ARMOR, tier)
			elif roll < ww + wa + wb:
				world.spawn_drop(
					e.pos, world.DROP_ABILITY, rng.next_bounded(world.ability_defs.size())
				)
			else:
				# Ring: pick among the stat frame's ring items AT the
				# drawn tier (block-7 one-pair trades; docs/22 block 4).
				# No ring at that tier = no drop — the green test pins
				# that T1 rings exist wherever wr > 0.
				var candidates := PackedInt32Array()
				var items: Array = world.stat_frame.get("items", [])
				for ii in items.size():
					var it: Dictionary = items[ii]
					if String(it.get("slot", "")) == "ring" and int(it.get("tier", -1)) == tier:
						candidates.append(ii)
				if not candidates.is_empty():
					world.spawn_drop(
						e.pos, world.DROP_RING, candidates[rng.next_bounded(candidates.size())]
					)
	var uniques: Array = def.unique_drops
	for ui in uniques.size():
		if rng.next_unit() < float(def.unique_chances[ui]):
			var idx: int = world.unique_defs.find(uniques[ui])
			if idx >= 0:
				world.spawn_drop(e.pos, world.DROP_UNIQUE, idx)
