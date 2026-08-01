# Overworld reference pass — sl-0093 content pack, hand-authored (docs/20 step 1)

2026-08-01. The dusk content pack (`assets/wildshot-overworld-pack-dusk-content/`,
REFERENCE ONLY — no importer, no sim consumption) mined by hand into spawn
tables + boss-site scenarios on the vendored b77 overworld. **This mapping is
the docs/20 step-3 importer-spec input** — every choice below is evidence for
that later session, and step 2 (the designer's feel verdict) judges the
authored result, not the pack. Nothing here is wired into THE LOOP or any
progression system; the five scenarios are picker rows.

## Zone brackets (sl-0087, Option B slice cap 30 — zone=level, 4 flat tiers)

| zone (plan id) | level bracket | flat tier | authored scenario |
|---|---|---|---|
| Green Country (`zone.green.0`, 30,949 cells) | 1–7 | 1 — light, 1–2 pressures | `overworld_green` |
| Dry Reach (`zone.dry.28429`, 9,683) | 8–15 | 2 — paired pressures | `overworld_dry` |
| Wetlands (`zone.wet.11248`, 10,114) | 16–22 | 3 — hazards join, up to 3 | `overworld_wet` |
| Snow Country (`zone.cold.66`, 8,038) | 23–30 | 4 — dangerous class, 3+ | `overworld_cold` |

Zone membership is authoritative from `content-plan.json` `zones[].memberRegionIds`
(placement/territory `regionId` → zone). The wf `dangerBand` field is the
director's own model — DELIBERATELY NOT used for the game mapping (the ruled
model is zone=level flat tiers; the band data stays in the pack for step 3 to
reconsider).

## Placeholder roster → real defs (the vocabulary seed, docs/20 "data-first")

| wf placeholder (census) | real def | rationale (role grammar) |
|---|---|---|
| `enemy.marauder` (81) | `rusher` | the common chaser — melee pressure |
| `enemy.prowler` (59) | `husk_archer` | the bread aimed-ranged |
| `enemy.night_shade` (43, nightOnly) | `leadshot` | predictive/intercept "stalker"; NO night system exists — authored as normal presence, the nightOnly bit is recorded vocabulary for step 3 |
| `enemy.mire_creeper` (18, wet) | `blightcaster` | ground hazard — the mire itself |
| `enemy.frost_wraith` (15, cold) | `ringer` | radial burst — the cold heavy |
| — (zone flavor) | `fanmaw` | fan pressure joins at tier 2+ where the grammar wants a second readable pressure |
| territory `elitePermille` / boss sites | `yard_warden` kit | the proven phased elite; boss IDENTITY is the designer's lore act (docs/20: "the site gets WHO and WHY from the designer"), kit is the stand-in |

## Authored scenarios (all cells = real pack site cells, walkability-verified)

Every enemy position and player spawn was checked against the b77 walkability
grid before authoring; every pull honors CORE-44 (1–2 pressures ordinary, 3+
only in the dangerous tier). Proofs: reactive DodgeBot, 3.0 t/s ability-off,
seeds 1,2,3 × 3600 ticks — committed as
`reports/dodge_overworld_*_composition.json`.

- **`overworld_green`** — five green sites east of the capital
  (grass.22653/28532/30868 clusters): rusher pair, husk solos, one
  rusher+husk two-pressure pull. Spawn on the sixth site (145,109).
- **`overworld_dry`** — husk+leadshot (aim+predict) at (66,126); rusher+fanmaw
  (chase+fan) at (39,117); husk pair at (24,123). Spawn (62,118).
- **`overworld_wet`** — the 3-pressure dangerous pull sits DEEP (blightcaster+
  fanmaw+rusher at 204,171); husk pair at (200,169); the border camp per its
  flag (below). Spawn (192,149).
- **`overworld_cold`** — the zone heavy SOLO: ringer at site (119,53), spawn
  (118,62). Six richer layouts FAILED the proof first (see the cold finding
  below) — the shipped demo is the proven class, margin 0.121 == the lab
  solo-ringer margin exactly (the b77 site reproduces it; the site is sound).
- **`overworld_green_boss`** — the designer's hand-placed Green world boss at
  (249,244) (`region.mud.57087` ∈ zone.green, arena box 247,242+6): Warden kit
  stand-in, player approach from (243,245) outside the arena box. The other
  three boss sites are recorded below, unauthored this pass ("a boss site or
  two" — docs/20).

## The six border camps (sl-0093 flagged: tune at authoring)

High-level sites within 3 cells of Green ground. Ruling applied: a green-level
wanderer crossing the border meets READABLE pressure, not execution — camps
authored/tabled at their zone's ENTRY composition, chase-and-hazard only (no
fan walls, no ringer radials, no leadshot prediction at the doorstep).

| camp cell | zone | authored treatment |
|---|---|---|
| (180,143) | wet | **placed in `overworld_wet`**: blightcaster+rusher (2 pressures, entry-wet) |
| (181,182) | wet | tabled same treatment (blightcaster+rusher) — not placed this pass |
| (183,186) | wet | tabled same treatment — not placed this pass |
| (102,62) | cold | tabled: rusher pair (chase-only) — pulled from the playable scenario by the cold finding below; the WET camp is the playable tuning demo |
| (68,7) | cold | tabled same treatment (rusher pair) — not placed this pass |
| (78,27) | cold | tabled same treatment — not placed this pass |

## Review dispositions carried (designer-approved, sl-0093)

- **Snow-east ruined city** (11 unbound `poi.city_ruin` anchors, 150–163 ×
  19–29): plays as UNMARKED discovery — zero authored content, zero markers;
  verified no authored cell lands in the box.
- **Four floor-killed dungeon Xs**: accepted by name upstream; nothing to
  author (dungeons are slice-build scope — the 4 slice-marked bindings at
  green (193,239) / dry (17,131) / cold (153,19) / wet (193,163) are recorded
  for the slice round, not touched here).
- **Giver slots (16) + gather spots (24)**: plan payload, unconsumed this
  pass — they belong to the quest/gathering slice rounds (sl-0086 shapes).

## The cold finding (measured — six failed layouts before the shipped demo)

Snow Country could not hold a multi-pressure authored scenario under the
current machinery. The iteration record (all seeds identical per layout —
deterministic, so each number is exact):

| layout | result |
|---|---|
| ringer+leadshot+husk pull + rusher pack 5 cells away + camp | 3 hits @772 (bot parked, pulls merged) |
| same, pack moved 40 tiles NE | 11 hits @451 |
| recomposed per the ring3 precedent (≤2 types per pull) | 4 hits @1350 |
| heavies anchored (fanmaw), camp as husk pair | 8 hits @1350 |
| minimal: ringer+husk + far camp pair | 4 hits @1350 |
| ringer+husk relocated to the NE "open" site (157,39) | 15 hits @229, margin 0.000 (cliff-band pinning — the ruined-city terraces sit just north; point-openness missed it) |
| **ringer solo at (119,53)** | **PASS, 0 hits, 0.121 = the lab solo margin** |

Three mechanisms, all recorded for step 3:

1. **The sim has no activation leash** — every mobile enemy in a world
   scenario converges from t0, so "separate pulls" merge into one eventual
   fight; spacing only delays it. Multi-pull zone authoring NEEDS activation/
   territory semantics (the pack's `maxActive` / `respawnPressure` / territory
   machinery) before it can express tier-4 density honestly. This is the
   importer's core spawn-surface question, now with numbers.
2. **FIRST@1350 was invariant across support compositions** = a husk-volley
   (period 90, volley 15) alignment against the ringer orbit at fit-rule
   margins on b77 ground — the ringer+husk pairing that passes in the lab
   clips razor-thin (0.003–0.007) out here. Pairing viability is
   TERRAIN-CLASS-dependent, not just composition-dependent.
3. **Point-openness is not orbit-openness** — (157,39) scored 0.97 walkable
   at r8 yet pinned the bot at margin 0.000 (cliff bands just outside the
   sampled radius). Site suitability for orbit-class fights needs a real
   clearance model (wf's own `clearance` score term is the natural home —
   step-3/upstream conversation material, not a game-side hack).

The ring3 lesson ("3-pressure simultaneous exceeds the proven ceiling")
reconfirms on the overworld, and tightens: even 2-type pulls depend on ground.
Zone=level tier-4 remains the DESIGN; its honest mechanization waits on
activation semantics. Exactly the cheap learning docs/20 step 1 exists for.

## What step 3 (the importer planning session) should take from this

1. Zone-from-region membership worked cleanly; the importer's spawn surface
   can key on it directly.
2. The roster vocabulary above is the seed of the "real enemy defs" recipe
   vocabulary (docs/20 data-first note) — including nightOnly as carried-but-
   unconsumed vocabulary.
3. Site cells were usable VERBATIM (walkability held for all 24 authored
   cells — wf gate G1/G3 discipline holds up downstream).
4. Territory rosters/packSize/maxActive/respawnPressure were NOT consumed by
   this hand pass (fixed authored pulls instead) — the importer decides how
   they become live spawn behavior; `elitePermille` maps naturally onto elite
   presence, pending the feel verdict.
