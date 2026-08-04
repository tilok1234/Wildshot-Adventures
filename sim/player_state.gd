extends "res://sim/actor_state.gd"
## Player sim state, v0 class shell (docs/12 §3.2): hp 100, mana 100 (mana
## exists only for the CORE-34 ability slot — primary fire costs nothing,
## ever; CORE-32), baseline speed 4.0 tiles/s.
## BODY RADII, deliberately split three ways: the COMBAT hurtbox below
## (sl-0208), locomotion = PlayerMove.TERRAIN_RADIUS (the fit rule),
## interact/door/station reaches = their own constants (audited
## uncoupled at the sl-0208 seam — none read ActorState.radius).
## SimWorld.players is an ARRAY of these (GDD-16 co-op insurance) — no player
## singleton or get_player() global exists anywhere.

## sl-0208 (sl-0146 executed as written — the designer: "the player
## hitbox should be atleast half the size of what it is now"): the
## COMBAT hurtbox. Every damage class reads ActorState.radius
## (projectile/melee/hazard/contact — THE one damage path), so this
## one value IS the player character hitbox. Half the original 0.35
## body [T; "at least" = license smaller — the designer's hands rule
## the final value; the smoke pins the 0.175 CEILING, never a floor].
## A serialized VALUE, not a format change — SERIAL 27 stands; the
## goldens/battery re-baseline deliberately with the seam.
const HURTBOX_RADIUS := 0.175


func _init() -> void:
	radius = HURTBOX_RADIUS


var mana: int = 100
## Sim-side autofire latch (§2.8): toggled by the frame's toggle edge, so
## it appears in replays and the HUD indicator reads sim state.
var autofire_on: bool = false
## Index into SimWorld.weapon_frames.
var equipped_weapon: int = 0
## Cadence gate: firing is legal when tick >= this.
var next_fire_tick: int = 0
## Last tick fire was held — the tap buffer (§2.8 responsiveness): a tap
## released during cooldown still fires when the gate opens, if recent.
var last_fire_held_tick: int = -1000000
## Quickdraw cadence buff active while tick < this (hard-coded 2/3
## cadence multiplier — ledger #2, no stat pipeline).
var quickdraw_until_tick: int = -1000000

## ---- Loop v1 (docs/19, SERIAL 13). Defaults preserve pre-loop
## behavior exactly: level 1 grants no bonus, tier 1 multiplies by 1.0,
## gold/xp start empty. Regen caps moved from constants to these maxes
## so level growth can raise them (100 = the §3.2 v0 sheet).
var gold: int = 0
## XP toward the NEXT level (resets each level-up; the curve lives in
## data/progression.tres).
var xp: int = 0
var level: int = 1
var max_hp: int = 100
var max_mana: int = 100
## Per-frame weapon tier 1–6 (index = weapon slot; 6 = unique-boosted).
## Picking up a higher-tier drop for a frame raises that slot only —
## frame CHOICE stays the player's (weapon keys), CORE-32 untouched.
var weapon_tiers: PackedInt32Array = PackedInt32Array([1, 1, 1])
## Bitmask of picked-up uniques (index into SimWorld.unique_defs).
var unique_mask: int = 0

## ---- The stat frame (docs/22, SERIAL 15). class_id -1 = the
## pre-slice LEGACY LANE: every derived stat below stays at its
## identity default and the loop-era progression math applies
## unchanged, so bare test scenarios and the whole proof battery are
## byte-identical by construction. 0/1/2 = sword/staff/bow
## (StatFrame.CLASS_IDS order = balance_frame.json key order).
var class_id: int = -1
## Ring slot: index into balance_frame.json items[] (a slot=="ring"
## row), -1 = none. Ring CONTENT lands with chapter drops; the slot +
## paired-trade derivation are frame machinery (docs/22 block 7).
var ring_index: int = -1
## Derived stats (StatFrame.recompute) — 100/100/0 identity for the
## legacy lane. Serialized: the fire path reads them every volley.
var attack_speed_stat: int = 100
var range_stat: int = 100
var damage_mod: int = 0
## CORE-43 (SERIAL 17): tick this dead player revives at the
## settlement (persistent worlds only; -1 = no respawn pending).
## Armed by THE damage path at the death tick; the ability key while
## dead confirms early (player_respawn.gd).
var respawn_at_tick: int = -1
## S1 seam 3 (SERIAL 18): unique ARMOR item worn — index into
## balance_frame.json items[] (a slot=="armor" unique row), -1 = the
## ordinary armor_tier ladder. Set by the UNIQUE pickup path;
## recompute reads the item's defense/hp/speed_cost INSTEAD of the
## tier table (block-8 break (c): over-budget defense with a real
## paired speed cost).
var armor_item_index: int = -1
## Quests (SERIAL 21, sl-0112 re-pin of the seam-5 one-active law):
## MULTI-ACTIVE — taken quests are a bitmask (cap [T] in quest_step),
## per-quest progress rides a parallel array sized to the quest list
## at setup, and the append-only done bitmask stays (the unique_mask
## precedent). Accept/turn-in are INTERACT presses at giver cells;
## class lane only (legacy players inert — proof worlds untouched).
var quests_taken_mask: int = 0
var quests_done_mask: int = 0
var quest_progress_arr: PackedInt32Array = PackedInt32Array()
## sl-0198 THE FORAGING BUILD (SERIAL 27; supersedes the SERIAL-20
## stillness fields — the patience verb + its anti-AFK rearm RETIRED
## from foraging): F at a live forage node starts a short GATHER BAR
## (bar_ticks [T] in balance_frame forage). forage_target = the node
## CELL being gathered (the sentinel = none; nodes are tracked by
## position, stable under other players' consumes); forage_ticks =
## bar progress, sim state advanced by ticks. The bar INTERRUPTS on
## movement or getting hit (gather_step). forage_mats = the
## per-species materials WALLET (index space =
## SimWorld.forage_species_ids order, loaded from the profile's
## name-keyed forage_mats at setup — the starhook_fish doctrine
## exactly; zero bag capacity by construction).
var forage_target: Vector2 = Vector2(-1000000.0, -1000000.0)
var forage_ticks: int = 0
var forage_mats: PackedInt32Array = PackedInt32Array()
## THE BAG (sl-0116/0128, SERIAL 23): carried items as flat
## (kind, a, b) triples in acquisition order — the same {kind,a,b}
## vocabulary drops speak (drop_kinds.gd). Class lane only: pickups
## land HERE (nothing auto-equips since the bag era); equip/drop ops
## ride the recorded bag_op byte (bag_step.gd owns the codes + the
## capacity [T 20]). Legacy lane (class_id < 0) never bags — every
## proof world byte-identical by construction.
var bag: PackedInt32Array = PackedInt32Array()
## THE BANK (sl-0130, SERIAL 25): the settlement stash — same flat
## triples, capacity in bag_step (BANK_CAP [T 12]). Deposit/withdraw
## ride recorded ops at the scenario's bank cell; DEATH NEVER TOUCHES
## THE BANK (no death-path writes — by construction, test-pinned).
var bank: PackedInt32Array = PackedInt32Array()
## STARHOOK v2 (sl-0115, SERIAL 22) — THE LINE. Only read where
## SimWorld.rift_line is attached (rift arenas); zero elsewhere by
## construction. line_lives = snaps remaining before the dive is lost
## (set from the pull def at scenario build); line_drain_acc = the
## integer drain accumulator (1/600 hp units — rift_step.gd);
## line_iframe_until = post-hit/post-snap grace (bullets only, the
## drains never pause).
var line_lives: int = 0
var line_drain_acc: int = 0
var line_iframe_until: int = -1000000
## THE GEAR SEAM (sl-0177/0178, SERIAL 26). fish = the species-currency
## wallet IN-SIM (index space = tackle_catalog species order, loaded
## from the profile's id-keyed starhook_fish at setup) so tackle-vendor
## spends are recorded + deterministic. rods_owned_mask /
## tackle_owned_mask = purchased/dropped catalog rows (bit = list
## index, both lists APPEND-ONLY); the four original rods are the free
## level-grant spine and never need their bits. tackle_chest /
## tackle_helm = equipped tackle.items indexes (-1 = bare) — stats
## apply in apply_to_rift ONLY (overworld combat untouched by
## construction). Defaults are all-zero/empty: every profile-free
## world is byte-identical in behavior.
var fish: PackedInt32Array = PackedInt32Array()
var rods_owned_mask: int = 0
var tackle_owned_mask: int = 0
var tackle_chest: int = -1
var tackle_helm: int = -1


func serialize_into(buf: StreamPeerBuffer) -> void:
	super.serialize_into(buf)
	buf.put_32(mana)
	buf.put_u8(1 if autofire_on else 0)
	buf.put_u8(equipped_weapon)
	buf.put_64(next_fire_tick)
	buf.put_64(last_fire_held_tick)
	buf.put_64(quickdraw_until_tick)
	buf.put_64(gold)
	buf.put_32(xp)
	buf.put_u16(level)
	buf.put_32(max_hp)
	buf.put_32(max_mana)
	buf.put_u8(weapon_tiers.size())
	for wt in weapon_tiers:
		buf.put_u8(wt)
	buf.put_u16(unique_mask)
	buf.put_8(class_id)
	buf.put_16(ring_index)
	buf.put_u16(attack_speed_stat)
	buf.put_u16(range_stat)
	buf.put_32(damage_mod)
	buf.put_64(respawn_at_tick)
	buf.put_16(armor_item_index)
	buf.put_u16(quests_taken_mask)
	buf.put_u16(quests_done_mask)
	buf.put_u16(quest_progress_arr.size())
	for qp in quest_progress_arr:
		buf.put_16(qp)
	# sl-0198 (SERIAL 27): the gather bar replaces the stillness pair.
	buf.put_float(forage_target.x)
	buf.put_float(forage_target.y)
	buf.put_u16(forage_ticks)
	buf.put_u8(forage_mats.size())
	for fm in forage_mats:
		buf.put_u16(fm)
	buf.put_u8(line_lives)
	buf.put_u16(line_drain_acc)
	buf.put_64(line_iframe_until)
	buf.put_u8(bag.size() / 3)
	for bi in bag.size() / 3:
		buf.put_u8(bag[bi * 3])
		buf.put_16(bag[bi * 3 + 1])
		buf.put_16(bag[bi * 3 + 2])
	buf.put_u8(bank.size() / 3)
	for ki in bank.size() / 3:
		buf.put_u8(bank[ki * 3])
		buf.put_16(bank[ki * 3 + 1])
		buf.put_16(bank[ki * 3 + 2])
	# THE GEAR SEAM (SERIAL 26): the fish wallet + tackle ownership.
	buf.put_u8(fish.size())
	for fc in fish:
		buf.put_u16(fc)
	buf.put_u32(rods_owned_mask)
	buf.put_u32(tackle_owned_mask)
	buf.put_8(tackle_chest)
	buf.put_8(tackle_helm)
