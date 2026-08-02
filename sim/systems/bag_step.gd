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
## 41 DE-EQUIP worn armor / 42 DE-EQUIP worn ring /
## 43 LOOT-ALL the nearest ground bag / 44..51 LOOT row 0..7.
## Weapon de-equip does not exist [T: bare hands aren't a build] —
## weapons only REPLACE (the worn one returns to the bag).
const OP_EQUIP_BASE := 1
const OP_DROP_BASE := 21
const OP_DEEQUIP_ARMOR := 41
const OP_DEEQUIP_RING := 42
const OP_LOOT_ALL := 43
const OP_LOOT_ROW_BASE := 44
const LOOT_ROW_MAX := 8
## sl-0130 THE BANK: 52..71 DEPOSIT bag slot / 72..83 WITHDRAW bank
## slot — legal only within BANK_RADIUS of the scenario's bank cell.
const OP_DEPOSIT_BASE := 52
const OP_WITHDRAW_BASE := 72
## sl-0131 VENDORS: 84..103 SELL bag slot / 104..111 BUY stock row —
## legal only within VENDOR_RADIUS of the NEAREST vendor cell.
const OP_SELL_BASE := 84
const OP_BUY_BASE := 104
const BUY_ROW_MAX := 8
## Menu pass (sl-0154): 112..127 ABANDON quest index — handled by
## quest_step (the quest-op range of the ONE recorded byte; legal
## anywhere, the quest returns to its giver). 128..143 are RESERVED
## for the seam-C explicit ACCEPT.
const OP_ABANDON_BASE := 112
const OP_ACCEPT_BASE := 128
const QUEST_OP_MAX := 16
## Capacity [T] (the sl-0116 suggested 20).
const BAG_CAP := 20
## Bank capacity [T] — small, distinct from the bag (sl-0130).
const BANK_CAP := 12
## Ground-bag reach [T] (sl-0129: the walk-over panel's radius too).
const LOOT_RADIUS := 0.9
## Bank station reach [T] (the giver-radius class).
const BANK_RADIUS := 1.2
## Vendor station reach [T] (same class).
const VENDOR_RADIUS := 1.2


static func run(world: RefCounted) -> void:
	# sl-0129: expired ground bags sweep every tick (no-op while none
	# exist — proof worlds untouched by construction).
	if not world.loot_bags.is_empty():
		var kept: Array[Dictionary] = []
		for lb: Dictionary in world.loot_bags:
			if world.tick < int(lb.expires_at_tick):
				kept.append(lb)
		world.loot_bags = kept
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
		elif op == OP_LOOT_ALL:
			_loot_all(world, p)
		elif op >= OP_LOOT_ROW_BASE and op < OP_LOOT_ROW_BASE + LOOT_ROW_MAX:
			_loot_row(world, p, op - OP_LOOT_ROW_BASE)
		elif op >= OP_DEPOSIT_BASE and op < OP_DEPOSIT_BASE + BAG_CAP:
			_deposit(world, p, op - OP_DEPOSIT_BASE)
		elif op >= OP_WITHDRAW_BASE and op < OP_WITHDRAW_BASE + BANK_CAP:
			_withdraw(world, p, op - OP_WITHDRAW_BASE)
		elif op >= OP_SELL_BASE and op < OP_SELL_BASE + BAG_CAP:
			_sell(world, p, op - OP_SELL_BASE)
		elif op >= OP_BUY_BASE and op < OP_BUY_BASE + BUY_ROW_MAX:
			_buy(world, p, op - OP_BUY_BASE)


## ---- ground loot bags (sl-0129).


## Nearest ground bag within reach, else -1.
static func nearest_bag(world: RefCounted, p: RefCounted) -> int:
	var best := -1
	var best_d := LOOT_RADIUS * LOOT_RADIUS
	for bi in world.loot_bags.size():
		var lb: Dictionary = world.loot_bags[bi]
		var dd: float = p.pos.distance_squared_to(lb.pos)
		if dd <= best_d:
			best_d = dd
			best = bi
	return best


static func _loot_all(world: RefCounted, p: RefCounted) -> void:
	var bi := nearest_bag(world, p)
	if bi < 0:
		return
	var row := 0
	while row * 3 < (world.loot_bags[bi].items as PackedInt32Array).size():
		if not _take_from_bag(world, p, bi, row):
			row += 1
	if (world.loot_bags[bi].items as PackedInt32Array).is_empty():
		world.loot_bags.remove_at(bi)


static func _loot_row(world: RefCounted, p: RefCounted, row: int) -> void:
	var bi := nearest_bag(world, p)
	if bi < 0:
		return
	_take_from_bag(world, p, bi, row)
	if (world.loot_bags[bi].items as PackedInt32Array).is_empty():
		world.loot_bags.remove_at(bi)


## ---- the bank (sl-0130): the settlement stash, two-way with the
## bag; ops legal only at the scenario's bank cell. Death never
## touches these arrays (no death-path writes anywhere).


static func bank_count(p: RefCounted) -> int:
	return p.bank.size() / 3


static func bank_item(p: RefCounted, slot: int) -> Dictionary:
	var base := slot * 3
	return {"kind": p.bank[base], "a": p.bank[base + 1], "b": p.bank[base + 2]}


static func at_bank(world: RefCounted, p: RefCounted) -> bool:
	if world.bank_cell == Vector2.ZERO:
		return false
	return p.pos.distance_to(world.bank_cell) <= BANK_RADIUS


static func _deposit(world: RefCounted, p: RefCounted, slot: int) -> void:
	if not at_bank(world, p) or slot >= bag_count(p):
		return
	if bank_count(p) >= BANK_CAP:
		world.events.append({"type": SimEvents.Type.BANK_FULL, "tick": world.tick, "player": p.id})
		return
	var it := bag_item(p, slot)
	bag_remove(p, slot)
	p.bank.append(int(it.kind))
	p.bank.append(int(it.a))
	p.bank.append(int(it.b))


static func _withdraw(world: RefCounted, p: RefCounted, slot: int) -> void:
	if not at_bank(world, p) or slot >= bank_count(p):
		return
	var it := bank_item(p, slot)
	if not bag_add(world, p, int(it.kind), int(it.a), int(it.b)):
		return
	var base := slot * 3
	for k in 3:
		p.bank.remove_at(base)


## ---- vendors (sl-0131): sell anything for gold; buy from a static
## catalog. Prices integer-exact from the vendors block [T]; gold
## flows through the one serialized field; ops legal only at the
## NEAREST vendor within reach.


static func nearest_vendor(world: RefCounted, p: RefCounted) -> int:
	var best := -1
	var best_d := VENDOR_RADIUS * VENDOR_RADIUS
	for vi in world.vendor_cells.size():
		var dd: float = p.pos.distance_squared_to(world.vendor_cells[vi])
		if dd <= best_d:
			best_d = dd
			best = vi
	return best


## Item value from the vendors table (0 = unpriced, trades refuse).
static func item_value(world: RefCounted, kind: int, a: int, b: int) -> int:
	var vend: Dictionary = world.stat_frame.get("vendors", {})
	var vals: Dictionary = vend.get("values", {})
	match kind:
		DropKinds.WEAPON:
			var tw: Array = vals.get("weapon", [])
			if tw.is_empty():
				return 0
			return int(tw[clampi(b, 1, tw.size()) - 1])
		DropKinds.ARMOR:
			var ta: Array = vals.get("armor", [])
			if ta.is_empty():
				return 0
			return int(ta[clampi(a, 1, ta.size()) - 1])
		DropKinds.RING:
			var items: Array = world.stat_frame.get("items", [])
			if a < 0 or a >= items.size():
				return 0
			var rt: Array = vals.get("ring_tier", [])
			if rt.is_empty():
				return 0
			var it: Dictionary = items[a]
			return int(rt[clampi(int(it.get("tier", 1)), 1, rt.size()) - 1])
		DropKinds.ABILITY:
			return int(vals.get("ability", 0))
		DropKinds.UNIQUE:
			return int(vals.get("unique", 0))
	return 0


static func sell_price(world: RefCounted, kind: int, a: int, b: int) -> int:
	var vend: Dictionary = world.stat_frame.get("vendors", {})
	return item_value(world, kind, a, b) * int(vend.get("sell_fraction_pct", 50)) / 100


static func buy_price(world: RefCounted, kind: int, a: int, b: int) -> int:
	var vend: Dictionary = world.stat_frame.get("vendors", {})
	return item_value(world, kind, a, b) * int(vend.get("buy_multiplier_pct", 200)) / 100


static func _sell(world: RefCounted, p: RefCounted, slot: int) -> void:
	if nearest_vendor(world, p) < 0 or slot >= bag_count(p):
		return
	var it := bag_item(p, slot)
	var price := sell_price(world, int(it.kind), int(it.a), int(it.b))
	if price <= 0:
		return
	bag_remove(p, slot)
	p.gold += price


static func _buy(world: RefCounted, p: RefCounted, row: int) -> void:
	var vi := nearest_vendor(world, p)
	if vi < 0 or vi >= world.vendor_stock.size():
		return
	var stock: PackedInt32Array = world.vendor_stock[vi]
	if row * 3 + 2 >= stock.size():
		return
	var kind := stock[row * 3]
	var a := stock[row * 3 + 1]
	var b := stock[row * 3 + 2]
	var price := buy_price(world, kind, a, b)
	if price <= 0 or p.gold < price:
		return
	# bag_add FIRST (a full bag refuses with BAG_FULL and the gold
	# never moves — nothing half-happens).
	if not bag_add(world, p, kind, a, b):
		return
	p.gold -= price


## Move one bag row to the player's bag. False = refused (out of
## range row, duplicate unique, or the player's bag is full — the
## item STAYS in the ground bag; nothing is destroyed silently).
static func _take_from_bag(world: RefCounted, p: RefCounted, bag_i: int, row: int) -> bool:
	var lb: Dictionary = world.loot_bags[bag_i]
	var items: PackedInt32Array = lb.items
	var base := row * 3
	if base + 2 >= items.size():
		return false
	var kind := items[base]
	var a := items[base + 1]
	var b := items[base + 2]
	if kind == DropKinds.UNIQUE:
		# The collection mask stays a pickup truth (the loot_step rule);
		# a duplicate unique stays in the ground bag and expires.
		if a < 0 or a >= world.unique_defs.size() or (p.unique_mask & (1 << a)) != 0:
			return false
	if not bag_add(world, p, kind, a, b):
		return false
	if kind == DropKinds.UNIQUE:
		p.unique_mask |= 1 << a
	for k in 3:
		items.remove_at(base)
	lb.items = items
	(
		world
		. events
		. append(
			{
				"type": SimEvents.Type.LOOT_PICKED,
				"tick": world.tick,
				"id": int(lb.id),
				"kind": kind,
				"player": p.id,
				"a": a,
				"b": b,
				"pos": lb.pos,
			}
		)
	)
	return true


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
