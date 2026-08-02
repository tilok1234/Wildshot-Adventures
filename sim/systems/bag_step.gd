extends RefCounted
## Ordered system (sl-0116 + sl-0128 — THE BAG): resolves the tick's
## recorded bag_op — equip from bag, drop from bag, de-equip worn —
## for class-lane players. Runs right after LootStep (same-tick
## pickups land in the bag first) and before GatherStep/QuestStep.
## Ops ride the recorded input stream (WSR v3) so replays and the
## profile agree byte-for-byte; bots never emit them. Legacy lane
## (class_id < 0) is inert — the whole proof battery is
## byte-identical by construction.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const SimEvents := preload("res://sim/events.gd")
const DropKinds := preload("res://sim/drop_kinds.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")

## The op byte (input_frame.gd bag_op; 0 = none):
## 1..20 EQUIP bag slot / 21..40 DROP bag slot /
## 41 DE-EQUIP worn armor / 42 DE-EQUIP worn ring.
## Weapon de-equip does not exist [T: bare hands aren't a build] —
## weapons only REPLACE (the worn one returns to the bag).
const OP_EQUIP_BASE := 1
const OP_DROP_BASE := 21
const OP_DEEQUIP_ARMOR := 41
const OP_DEEQUIP_RING := 42
## Capacity [T] (the sl-0116 suggested 20).
const BAG_CAP := 20


static func run(world: RefCounted) -> void:
	var frames: Array = world.current_frames
	for i in world.players.size():
		var p: RefCounted = world.players[i]
		if p.class_id < 0 or p.dead:
			continue
		var frame: RefCounted = frames[i] if i < frames.size() else null
		if frame == null or int(frame.bag_op) == 0:
			continue
		var op := int(frame.bag_op)
		if op >= OP_EQUIP_BASE and op < OP_EQUIP_BASE + BAG_CAP:
			_equip(world, p, op - OP_EQUIP_BASE)
		elif op >= OP_DROP_BASE and op < OP_DROP_BASE + BAG_CAP:
			_drop(world, p, op - OP_DROP_BASE)
		elif op == OP_DEEQUIP_ARMOR:
			_deequip_armor(world, p)
		elif op == OP_DEEQUIP_RING:
			_deequip_ring(world, p)


## ---- bag primitives (flat (kind,a,b) triples on PlayerState.bag).


static func bag_count(p: RefCounted) -> int:
	return p.bag.size() / 3


static func bag_item(p: RefCounted, slot: int) -> Dictionary:
	var base := slot * 3
	return {"kind": p.bag[base], "a": p.bag[base + 1], "b": p.bag[base + 2]}


## Append {kind,a,b}; false = full (BAG_FULL emitted; caller keeps the
## item where it was — nothing is ever destroyed silently).
static func bag_add(world: RefCounted, p: RefCounted, kind: int, a: int, b: int) -> bool:
	if bag_count(p) >= BAG_CAP:
		world.events.append({"type": SimEvents.Type.BAG_FULL, "tick": world.tick, "player": p.id})
		return false
	p.bag.append(kind)
	p.bag.append(a)
	p.bag.append(b)
	return true


static func bag_remove(p: RefCounted, slot: int) -> void:
	var base := slot * 3
	for k in 3:
		p.bag.remove_at(base)


## ---- ops.


static func _equip(world: RefCounted, p: RefCounted, slot: int) -> void:
	if slot >= bag_count(p):
		return
	var it := bag_item(p, slot)
	var kind := int(it.kind)
	match kind:
		DropKinds.WEAPON:
			var frame := int(it.a)
			var tier := int(it.b)
			if frame < 0 or frame >= p.weapon_tiers.size():
				return
			var worn_tier: int = p.weapon_tiers[frame]
			bag_remove(p, slot)
			bag_add(world, p, DropKinds.WEAPON, frame, worn_tier)
			p.weapon_tiers[frame] = tier
			_equipped_event(world, p, kind, frame, tier)
		DropKinds.ARMOR:
			var tier := int(it.a)
			bag_remove(p, slot)
			_return_worn_armor(world, p)
			p.armor_tier = tier
			p.armor_item_index = -1
			StatFrame.recompute(world, p)
			_equipped_event(world, p, kind, tier, 0)
		DropKinds.RING:
			var ri := int(it.a)
			var ritems: Array = world.stat_frame.get("items", [])
			if ri < 0 or ri >= ritems.size():
				return
			bag_remove(p, slot)
			if p.ring_index >= 0:
				bag_add(world, p, DropKinds.RING, p.ring_index, 0)
			p.ring_index = ri
			StatFrame.recompute(world, p)
			_equipped_event(world, p, kind, ri, 0)
		DropKinds.UNIQUE:
			var ui := int(it.a)
			if ui < 0 or ui >= world.unique_defs.size():
				return
			var udef: Resource = world.unique_defs[ui]
			var uitems_id := String(udef.items_id)
			if not uitems_id.is_empty():
				var uitems: Array = world.stat_frame.get("items", [])
				for uii in uitems.size():
					if String(uitems[uii].get("id", "")) == uitems_id:
						bag_remove(p, slot)
						_return_worn_armor(world, p)
						p.armor_item_index = uii
						StatFrame.recompute(world, p)
						_equipped_event(world, p, kind, ui, 0)
						return
				return
			# Loop-era tier-6 frame boost (the Coil): applies on equip,
			# consumes the item (today's overwrite semantics, recorded).
			var fslot := int(udef.frame_slot)
			if fslot >= 0 and fslot < p.weapon_tiers.size():
				bag_remove(p, slot)
				p.weapon_tiers[fslot] = maxi(p.weapon_tiers[fslot], 6)
				_equipped_event(world, p, kind, ui, 0)
		DropKinds.ABILITY:
			var idx := int(it.a)
			if idx < 0 or idx >= world.ability_defs.size():
				return
			bag_remove(p, slot)
			world.ability_def = world.ability_defs[idx]
			_equipped_event(world, p, kind, idx, 0)


static func _drop(world: RefCounted, p: RefCounted, slot: int) -> void:
	if slot >= bag_count(p):
		return
	var it := bag_item(p, slot)
	bag_remove(p, slot)
	world.spawn_drop(p.pos, int(it.kind), int(it.a), int(it.b))


## Worn armor (tier ladder or unique row) returns to the bag. Callers
## guarantee room: they bag_remove the incoming item FIRST, so one
## slot is always free for the return leg.
static func _return_worn_armor(world: RefCounted, p: RefCounted) -> void:
	if p.armor_item_index >= 0:
		var ui := _unique_for_items_row(world, p.armor_item_index)
		if ui >= 0:
			bag_add(world, p, DropKinds.UNIQUE, ui, 0)
		p.armor_item_index = -1
	elif p.armor_tier > 0:
		bag_add(world, p, DropKinds.ARMOR, p.armor_tier, 0)
		p.armor_tier = 0


static func _deequip_armor(world: RefCounted, p: RefCounted) -> void:
	if p.armor_item_index < 0 and p.armor_tier <= 0:
		return
	if bag_count(p) >= BAG_CAP:
		world.events.append({"type": SimEvents.Type.BAG_FULL, "tick": world.tick, "player": p.id})
		return
	_return_worn_armor(world, p)
	StatFrame.recompute(world, p)


static func _deequip_ring(world: RefCounted, p: RefCounted) -> void:
	if p.ring_index < 0:
		return
	if not bag_add(world, p, DropKinds.RING, p.ring_index, 0):
		return
	p.ring_index = -1
	StatFrame.recompute(world, p)


static func _unique_for_items_row(world: RefCounted, items_index: int) -> int:
	var uitems: Array = world.stat_frame.get("items", [])
	if items_index < 0 or items_index >= uitems.size():
		return -1
	var iid := String(uitems[items_index].get("id", ""))
	for ui in world.unique_defs.size():
		if String(world.unique_defs[ui].items_id) == iid:
			return ui
	return -1


static func _equipped_event(world: RefCounted, p: RefCounted, kind: int, a: int, b: int) -> void:
	(
		world
		. events
		. append(
			{
				"type": SimEvents.Type.ITEM_EQUIPPED,
				"tick": world.tick,
				"player": p.id,
				"kind": kind,
				"a": a,
				"b": b,
			}
		)
	)
