# THE GEAR SEAM — design record (sl-0177 as amended by sl-0178)

> **SINCE LANDING (2026-08-03/04):** the equip-at-station pin
> flipped — tackle EQUIP ops are legal anywhere since sl-0181
> (the C-menu rifter panel wears owned gear from the field; BUY
> stays station-gated). The sl-0182 naming ruling relaxes
> no-coined-names INSIDE starhooking to the cosmic vocabulary
> rail — rod/tackle/keeper words stand until the designer's own
> naming act renames them (only the creel was routed; it is THE
> CONSTELLATION now). This file stays the as-built record.

SIM seam, SERIAL 26 (the sl-0168 "26 = foraging" reservation amends to
this seam per sl-0177's whichever-builds-first rule; foraging takes the
next free number). Functional-first by the designer's word: real stats,
real slots, placeholder visuals only. Every number below [T]; shape
calls marked [P] resolve with the designer (findings named at close).

## The shape as built

**Three rifter slots: rod + chest + helm** (sl-0170 ruling 2).

**Rods are starhooking weapons** (sl-0178): the rod catalog =
`starhook.rods` (append-only), 4 → 12 rows across four FAMILIES, each
family a pattern NORM (the pond's sword/staff/bow parallel — the
planning lean built):

| family | pattern | norm                          | T1 | T2 | T3 | T4 |
|--------|---------|-------------------------------|----|----|----|----|
| line   | 7       | 1 bolt, spd 14, ttl 30        | Cane Rod 6/30 | Line Rod 8/30 | — | Line Rod 13/30 |
| fan    | 8       | 3 bolts ±12°, spd 12, ttl 28  | Fan Rod 3/36 | Splitwillow 4/36 | Fan Rod 5/36 | — |
| sinker | 9       | 1 orb, spd 9, ttl 80          | — | Heavy Rod 12/88 | Heavyline 16/88 | Heavy Rod 21/88 |
| twin   | 29      | 2 needles ±3°, spd 15, ttl 52 | Twin Rod 2/28 | — | Twin Rod 3/34 | Twinreed 3/28 |

(cells = per-shot dmg / cadence ticks). ZERO new patterns — every rod
reuses its family's PatternDef verbatim (sl-0169's law untouched:
pattern DEVIATION stays the uniques' job, and unique rods are FUTURE,
not built). Family-internal paper DPS is tier-monotone (validator
gate); CROSS-family DPS is identity-priced, not budget-priced — the
four proto rods' numbers are designer-word [proto→T] and ride verbatim,
exact-pinned in the validator. 3 rods per tier ("several" ✓).

**Tier ladder** = the existing [T] unlock ladder verbatim:
tier→starhook level {1:1, 2:3, 3:5, 4:8}. Every rod's unlock_level
must equal its tier's threshold (validator). Use-gating for ALL rods =
level vs unlock_level (the shipped player_fire machinery, unchanged).

**Acquisition [P]**: the four ORIGINAL rods keep their level-grant
(sl-0177's own sanction: "rod unlocks may stay the one leveled
ladder") — one free identity per tier, the spine. The 8 NEW rods are
purchasable-only (fish) or rare-catch drops: ownership gates their
use on top of the level gate. Finding for the designer: should the
originals ever move to purchase-only, that is a one-word flip
(price rows exist for the machinery; grant lane keyed per-row).

**Chest + helm** = rift-side ONLY (overworld combat untouched —
structurally: stats apply in apply_to_rift, nowhere else):
- chest = line capacity: max stability +12/+16/+21/+28 (steps within
  [1.25, 1.35] [T])
- helm = strain guard: defense +4/+5/+6/+7, applied vs BULLET strain
  through THE docs/22 formula (the drains never mitigate — the clock
  is the clock). Obtainable Green-grade (T1-T2) defense = 4-5 vs the
  10-dmg rift typical hit = 0.40-0.50x (the armor_rules band); max 7
  ≤ 0.7x plateau.
- Rows live in `starhook.tackle.items` (ONE append-only list, mask-bit
  contract like balance items[]).
- NOT built (future stat family, named as a finding): drain-rate /
  deep-edge / grace / lives modifiers — those touch the line's clock
  semantics and deserve their own designed round.

**The tackle vendor v1**: ONE station, the harbor capital, cell
pinned in slice_overworld.tres (walkability script-verified; ≥3 t
from every existing station — the interact-sweep disambiguation
class). F-opens the panel (station law, v2 chrome, plaque "TACKLE");
stock = every PRICED catalog row grouped by tier; the fish wallet
shows in the head rule. Prices are per-species dicts keyed by species
ID STRING — the fish-first word (sl-0178 commit) means the designer
re-rosters species later with zero machinery rework.

**The spend is recorded + deterministic**: fish counts enter the sim
at setup (profile starhook_fish → PlayerState.fish by current species
table), purchases ride NEW recorded ops on the existing bag_op byte —
144..175 TACKLE BUY shelf row, 176..191 TACKLE EQUIP items row (both
legal only at the tackle cell, class lane; 128..143 stay the quest
ACCEPT range). Buying sets the owned bit + decrements fish; chest/helm
auto-equip into an EMPTY slot; equip-op swaps among owned; no
de-equip v1 (gear carries no downside). Rod choice stays R in the
rift (no rod-equip op).

**Rare-catch drops**: after the fish draw in the kill's fixed rng_loot
sequence, a RARE rift kill rolls chance_pct 50 [T] for ONE piece drawn
uniformly among priced rows within tier bounds [1, 2] [T]
(zone/danger-gated per no-depth — Green rifts drop Green-grade; future
zones raise the bounds in data) that some player lacks; the grant is
direct owned-bit (no ground drops in rifts). Dup-protected by
construction (unowned-only pool; all-owned = no draw beyond the
chance roll).

**Serialization (SERIAL 26, PlayerState tail)**: fish counts (u8 size
+ u16 each), rods_owned_mask u32, tackle_owned_mask u32, tackle_chest
i8, tackle_helm i8. Profile: starhook_rods[] / starhook_tackle[] /
starhook_chest / starhook_helm — ALL BY ID (the seam-2 doctrine);
absent keys read empty (no profile version bump — the designer's save
carries).

## Findings to name at close (sl-0177/0178 resolution)

1. The open shape point RESOLVED AS THE LEAN [P]: families carry
   their own patterns (norms) — and the built four already WERE that
   shape; tiers within a family are stat flavors. Flipping to
   same-pattern-everything would be a data edit, not code.
2. Originals keep level-grant; new rods purchase/drop-only [P].
3. Chest/helm rows are single-stat (hp / def) v1; line-clock stat
   family (drain/grace/lives) deliberately future.
4. Equip surface v1 = the vendor station (+ auto-equip on first buy);
   a C-menu rift-gear pane is a future round.
5. Rare-drop pool = priced rows only (the level-grant spine never
   drops — it is already free).
