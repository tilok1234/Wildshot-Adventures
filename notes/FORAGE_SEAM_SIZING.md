# SEAM I SIZING REPORT — minimal foraging (sl-0157, split out)

The routing: "F at a gather spot → yield into the bag (species per
spot type [T]) · the spot DEPLETES and RESPAWNS [T]", conditional on
an honest size check. **Sized 2026-08-03: it splits out of the pass.**
Not for code volume — for design authority. The facts:

## The premise vs the built game

The routing's premise was "the world data carries 24 gather spots;
no foraging interaction exists yet." Both halves need correcting:

1. **Foraging EXISTS** — sl-0105 foraging v1: 90-tick STILLNESS at
   ~1.9k WYSIWYG gather-species prop cells (stump / fallen log /
   bush / mushrooms), yielding 1–2 gold + 2 xp [T], with the
   anti-AFK one-yield-per-4-tile-walk rule. gather_test pins it.
   Foraging IS interactable today — through the patience verb the
   designer chose at sl-0105, not F.
2. **The 24 spots decode as 12 + 12**: the content pack's
   `gatherSpots` list = 12 `fishing` markers + 12 `foraging`
   markers. The 12 fishing cells are WATER-fishing POIs — parked
   territory by the designer's own word (sl-0111; starhook
   correction #3: rifts have nothing to do with water). Only the 12
   foraging POIs are live material.

## What the routed build would actually change

Three models the designer already ruled at sl-0105, each flipped:

| model | built (sl-0105, the designer's) | the routed build |
|---|---|---|
| verb | 90-tick stillness (patience) | F interact |
| yield | gold + xp, straight to wallet | items into the bag, species-typed |
| pacing | anti-AFK walk rule, cells never deplete | per-spot depletion + respawn timer |

Plus the mechanics bill: per-spot depletion state is SERIALIZED →
**SERIAL bump to 26**, goldens re-recorded, the full battery
re-baseline, species→item yield tables authored [T], gather_step
surgery, gather_test re-pinned. A real sim seam — over three design
choices that are the designer's to flip, not a session's
(talk-before-build).

## The question shape (plain words, one line each)

1. Should walking up and pressing F replace the stand-still cast at
   forage spots — or should both work?
2. Should foraging give ITEMS in the bag instead of (or beside) the
   little gold+xp it gives now?
3. Should the 12 marked forage spots be special rich spots that run
   dry and come back — on top of, or instead of, the everywhere-
   forage that exists now?

One word per line routes the seam; it then builds under full sim
discipline (SERIAL 26, goldens, battery). The 12 water-fishing
markers stay parked with sl-0111.
