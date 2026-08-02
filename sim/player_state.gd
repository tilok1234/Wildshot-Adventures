extends "res://sim/actor_state.gd"
## Player sim state, v0 class shell (docs/12 §3.2): hp 100, mana 100 (mana
## exists only for the CORE-34 ability slot — primary fire costs nothing,
## ever; CORE-32), baseline speed 4.0 tiles/s, body radius 0.35.
## SimWorld.players is an ARRAY of these (GDD-16 co-op insurance) — no player
## singleton or get_player() global exists anywhere.

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
## S1 seam 5 (SERIAL 19): GENERIC QUESTS v1 — one active quest per
## player (index into SimWorld.quest_defs, -1 = none), its progress
## count, and the append-only done bitmask (the unique_mask
## precedent). Walk-up accept/turn-in at giver cells; class lane
## only (quest_step ignores legacy players — proof worlds inert).
var active_quest: int = -1
var quest_progress: int = 0
var quests_done_mask: int = 0


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
	buf.put_8(active_quest)
	buf.put_16(quest_progress)
	buf.put_u16(quests_done_mask)
