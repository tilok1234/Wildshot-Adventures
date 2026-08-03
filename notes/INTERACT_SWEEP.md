# THE INTERACTABILITY SWEEP (menu pass seam H, sl-0157)

Verify-only: every interactable class answers, nothing that should
respond sits dead. Run 2026-08-03 at the close of the menu-pass view
seams (game `2b70588`). Mechanized proof pointers per class; the
honest gaps named; the designer's own Green walk is the live
confirmation layer (their hands press F — this table says what must
happen when they do).

## F INTERACT — the press classes

| class | response | mechanized proof |
|---|---|---|
| bank keeper | the BANK VAULT menu opens (station_toggle; never walk-over) | tests/bank/bank_panel_probe.gd (panel responds to station_open; evidence PNG pair); the main-side press router is code-read + designer-hands (main cannot load under --script — the recorded limit) |
| vendors (merchant + trader) | the TRADER menu opens on the NEAREST vendor | tests/vendors/vendor_panel_probe.gd + BagStep.nearest_vendor (nearest-wins, sim-side radius law) |
| quest giver, quest available | the OFFER dialogue opens (QUEST_OFFERED event) | tests/quests/quest_test.gd §1 (press → offer, mask unchanged) |
| quest giver, quest complete | TURN-IN WINS, undialogued | tests/quests/quest_test.gd §3 (payoff-first branch order) |
| quest giver, dual-state | turn-in resolves BEFORE any offer (same press) | quest_step._interact branch order (turn-in returns first) |
| rift portal | INSTANT F-CAST (the cast IS the aggro; starhook law) | tests/gather/gather_test.gd (instant cast + CAST_COMPLETE; menu/Esc-first changes touch none of it — the cast path reads the recorded interact edge sim-side) |
| dropped item | F picks the nearest INTO the bag (one per press) | tests/loop/loop_test.gd (interact-era pickup pins) |
| gather spot | see SEAM I (the pass's one sim seam — the sweep's own gap finding) | tests/gather/gather_test.gd (stillness forage v1 today) |
| future station | inherits F by the sl-0147 standing rule | the station_toggle pattern (bank/vendor are the template) |

## WALK-OVER — stays by design

| class | response | proof |
|---|---|---|
| loot bag | the LOOT panel shows, click-to-loot-one, [B] loot-all | tests/loot_bags/loot_bag_probe.gd (sl-0129 — the designer's own design, exempt from F by their word) |
| gold | auto-pickup (the interact-era survivor) | loot_step (walk-over lane) |
| dungeon/rift doors | walk-on transitions | main DUNGEON_DOORS (S1 seam 4 pins in the green test) |

## Disambiguation (nearest/priority [T])

Cross-class station separations, measured (interact radii 1.2 + 1.2
= 2.4 overlap threshold):

- bank keeper ↔ merchant 6.00 / ↔ trader 6.32 / ↔ capital giver 3.00
- merchant ↔ capital giver 3.00 / trader ↔ capital giver 3.61
- merchant ↔ trader 2.00 — the ONE overlap, SAME class:
  nearest-vendor resolves it sim-side (sane by construction)

Every cross-CLASS pair sits disjoint: one press at one station
reaches exactly one class. Giver slots: the capital cell hosts two
errands (cull + mud_pocket — the offer picks the first available;
the second offers after the first is taken/turned in), the
waystation two (west_road + provisions), the far field one.

## Honest findings (recorded, not defects)

1. **Crowd NPCs (the 32 stationed looks) have NO interact response
   today** — npc_view is PURE VIEW (CORE-35); the givers are the
   speaking class. Villager one-liners hang off the interact verb
   INCREMENTALLY [T] as content wants them (the standing handoff §3
   item; the capital zone-hub giver still has no NPC body — the
   known honest gap from the quest-pull seam).
2. **A drop underfoot AT a station**: one F press reaches BOTH
   layers (the sim picks the item into the bag; the view opens the
   station menu). Two effects, one press, across two layers — rare
   by geometry (drops land at corpses, stations sit in the safe
   capital), recorded as a designer-walk watch item [T].
3. **Foraging**: the world's gather interaction is 90-tick
   STILLNESS (sl-0105 v1), not the F verb — seam I holds the
   routed minimal F-forage build and its sizing report.
