extends RefCounted
## Ordered system (Loop v1, docs/19): ground-drop lifetime + walk-over
## pickup. Runs last in the step so this tick's deaths drop first and
## pickups read final positions. Pickup is GAMEPLAY, fully deterministic,
## never replay-dirtying. Auto-equip takes UPGRADES ONLY — a drop that
## would not improve the slot stays on the ground (no inventory in v1;
## the minimal equip surface is the HUD's slot readout).
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const SimEvents := preload("res://sim/events.gd")
const DropKinds := preload("res://sim/drop_kinds.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")


static func run(world: RefCounted) -> void:
	if world.drops.is_empty():
		return
	var t: int = world.tick
	var prog: Resource = world.progression
	var radius: float = float(prog.pickup_radius) if prog != null else 0.5
	var kept: Array[Dictionary] = []
	for d: Dictionary in world.drops:
		if t >= int(d.expires_at_tick):
			continue
		var taken := false
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


## Apply a drop to a player. Returns false when the drop is NOT an
## upgrade (it stays on the ground).
static func _apply(world: RefCounted, p: RefCounted, d: Dictionary) -> bool:
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
		DropKinds.UNIQUE:
			var ui := int(d.a)
			if ui < 0 or ui >= world.unique_defs.size():
				return false
			if (p.unique_mask & (1 << ui)) != 0:
				return false
			p.unique_mask |= 1 << ui
			# Loop-era tier-6 frame boost. Class loadouts are smaller
			# than the lab trio — bounds-guarded; slice unique
			# BEHAVIOURS are chapter work (docs/22 block 8).
			var slot := int(world.unique_defs[ui].frame_slot)
			if slot >= 0 and slot < p.weapon_tiers.size():
				p.weapon_tiers[slot] = maxi(p.weapon_tiers[slot], 6)
			return true
	return false
