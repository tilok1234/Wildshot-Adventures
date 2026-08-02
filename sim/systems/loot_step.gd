extends RefCounted
## Ordered system (Loop v1 docs/19; RE-PINNED by sl-0112 — DELIBERATE
## HANDS): ground-drop lifetime + pickup. GOLD stays walk-over auto
## (the silent counter is its readout); EVERY OTHER KIND requires an
## INTERACT press — the nearest eligible drop within reach is the one
## taken, one drop per press. Upgrades-only holds for weapon/armor;
## abilities swap deliberately; a worn ring SWAPS with the pressed
## ground ring (the old ring drops where the new one lay). Runs last
## in the step. Pickup is GAMEPLAY, fully deterministic, never
## replay-dirtying.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const SimEvents := preload("res://sim/events.gd")
const DropKinds := preload("res://sim/drop_kinds.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const BagStep := preload("res://sim/systems/bag_step.gd")


static func run(world: RefCounted) -> void:
	if world.drops.is_empty():
		return
	var t: int = world.tick
	var prog: Resource = world.progression
	var radius: float = float(prog.pickup_radius) if prog != null else 0.5
	var frames: Array = world.current_frames
	# Interact pickups first: each pressing player takes their nearest
	# eligible non-gold drop within reach (player order = §2.4 stable).
	for i in world.players.size():
		var p: RefCounted = world.players[i]
		if p.dead:
			continue
		var frame: RefCounted = frames[i] if i < frames.size() else null
		if frame == null or not frame.interact_pressed:
			continue
		var best := -1
		var best_d := radius * radius
		for di in world.drops.size():
			var d: Dictionary = world.drops[di]
			if int(d.kind) == DropKinds.GOLD or t >= int(d.expires_at_tick):
				continue
			var dd: float = p.pos.distance_squared_to(d.pos)
			if dd <= best_d:
				best_d = dd
				best = di
		if best < 0:
			continue
		var chosen: Dictionary = world.drops[best]
		if _apply(world, p, chosen):
			(
				world
				. events
				. append(
					{
						"type": SimEvents.Type.LOOT_PICKED,
						"tick": t,
						"id": int(chosen.id),
						"kind": int(chosen.kind),
						"player": p.id,
						"a": int(chosen.a),
						"b": int(chosen.b),
						"pos": chosen.pos,
					}
				)
			)
			world.drops.remove_at(best)
	# Walk-over lane: gold only, plus TTL expiry.
	var kept: Array[Dictionary] = []
	for d: Dictionary in world.drops:
		if t >= int(d.expires_at_tick):
			continue
		var taken := false
		if int(d.kind) == DropKinds.GOLD:
			for p: RefCounted in world.players:
				if p.dead:
					continue
				var dpos: Vector2 = d.pos
				if p.pos.distance_squared_to(dpos) > radius * radius:
					continue
				if _apply(world, p, d):
					(
						world
						. events
						. append(
							{
								"type": SimEvents.Type.LOOT_PICKED,
								"tick": t,
								"id": int(d.id),
								"kind": int(d.kind),
								"player": p.id,
								"a": int(d.a),
								"b": int(d.b),
								"pos": dpos,
							}
						)
					)
					taken = true
					break
		if not taken:
			kept.append(d)
	world.drops = kept


## Apply a drop to a player. Returns false when the drop stays on the
## ground. CLASS LANE (sl-0116): every non-gold pickup lands IN THE
## BAG — nothing auto-equips, the upgrades-only filter is retired,
## downgrades are collected happily; a full bag refuses (BAG_FULL) and
## the drop stays. Equip is a DECISION (bag_step ops from the C pane).
## LEGACY LANE keeps the pre-bag press-equip behavior verbatim — every
## proof world byte-identical by construction.
static func _apply(world: RefCounted, p: RefCounted, d: Dictionary) -> bool:
	if int(d.kind) != DropKinds.GOLD and p.class_id >= 0:
		var udef_gate := true
		if int(d.kind) == DropKinds.UNIQUE:
			# The collection mask stays a PICKUP truth (skins/profile
			# records key on it) and still refuses double-pickup.
			var ui := int(d.a)
			if ui < 0 or ui >= world.unique_defs.size():
				udef_gate = false
			elif (p.unique_mask & (1 << ui)) != 0:
				udef_gate = false
		if not udef_gate:
			return false
		if not BagStep.bag_add(world, p, int(d.kind), int(d.a), int(d.b)):
			return false
		if int(d.kind) == DropKinds.UNIQUE:
			p.unique_mask |= 1 << int(d.a)
		return true
	match int(d.kind):
		DropKinds.GOLD:
			p.gold += int(d.a)
			return true
		DropKinds.WEAPON:
			var frame := int(d.a)
			var tier := int(d.b)
			if tier <= p.weapon_tiers[frame]:
				return false
			p.weapon_tiers[frame] = tier
			return true
		DropKinds.ARMOR:
			var atier := int(d.a)
			if atier <= p.armor_tier:
				return false
			p.armor_tier = atier
			# Class lane: armor carries defense + HP (docs/22 block 4) —
			# re-derive; no free heal, current hp only ever clamps down.
			if p.class_id >= 0:
				StatFrame.recompute(world, p)
			return true
		DropKinds.ABILITY:
			var idx := int(d.a)
			if idx < 0 or idx >= world.ability_defs.size():
				return false
			if world.ability_def == world.ability_defs[idx]:
				return false
			world.ability_def = world.ability_defs[idx]
			return true
		DropKinds.RING:
			# sl-0112: rings are a CHOICE made with deliberate hands —
			# interact equips an empty slot, or SWAPS with the worn
			# ring (the old ring drops exactly where the new one lay,
			# same TTL clock as any fresh drop). Class lane only —
			# ring_index feeds StatFrame.recompute's trade sheet.
			var ri := int(d.a)
			if p.class_id < 0:
				return false
			var ritems: Array = world.stat_frame.get("items", [])
			if ri < 0 or ri >= ritems.size():
				return false
			if p.ring_index >= 0:
				world.spawn_drop(d.pos, DropKinds.RING, p.ring_index)
			p.ring_index = ri
			StatFrame.recompute(world, p)
			return true
		DropKinds.UNIQUE:
			var ui := int(d.a)
			if ui < 0 or ui >= world.unique_defs.size():
				return false
			if (p.unique_mask & (1 << ui)) != 0:
				return false
			p.unique_mask |= 1 << ui
			var udef: Resource = world.unique_defs[ui]
			# S1 seam 3: an items-mapped unique EQUIPS its balance row
			# (Old Tusk's Hide — unique armor replaces the tier ladder
			# via recompute's override branch). Loop-era frame-boost
			# uniques keep their tier-6 model below.
			var uitems_id := String(udef.items_id)
			if not uitems_id.is_empty():
				var uitems: Array = world.stat_frame.get("items", [])
				for uii in uitems.size():
					if String(uitems[uii].get("id", "")) == uitems_id:
						p.armor_item_index = uii
						if p.class_id >= 0:
							StatFrame.recompute(world, p)
						break
				return true
			# Loop-era tier-6 frame boost. Class loadouts are smaller
			# than the lab trio — bounds-guarded; slice unique
			# BEHAVIOURS are chapter work (docs/22 block 8).
			var slot := int(udef.frame_slot)
			if slot >= 0 and slot < p.weapon_tiers.size():
				p.weapon_tiers[slot] = maxi(p.weapon_tiers[slot], 6)
			return true
	return false
