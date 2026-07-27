# TileForge — complete asset packages

Four self-contained packages, one per theme. **A game world uses exactly one
package** (one theme per map is a forge constraint; cross-theme mixing in a
single world is deliberately deferred — see ROADMAP §7 M1b).

| file | theme | mood |
|---|---|---|
| `tileforge-forest-complete.zip` | Forest | temperate greens, teal arcana |
| `tileforge-autumn-complete.zip` | Autumn | warm golds, chartreuse arcana |
| `tileforge-dusk-complete.zip`   | Dusk   | violet twilight, acid-green corruption |
| `tileforge-winter-complete.zip` | Winter | cold blues, snow-covered world |

Every zip contains the identical, complete catalog — 80 families (28
materials, 22 decals, 88 prop species, 52 structures, every network type,
crops, ramps, cliffs) — generated from seed 103991 at the RICH config
(user-picked 2026-07-20): **6 variants, coordinated mode** (no adjacent
identical tiles) **and boosted per-tile texture** (detail 0.85,
highlight 0.55, flowers 0.28, rough 0.3). Validation inside each zip:
0 failures, 0 warnings.

> **Build status (2026-07-26 night, ROAD-LAYER RETIREMENT at commit
> `ae1eecb` — this IS the current release): 31,431 tiles per theme**
> (unchanged — the atlas keeps every family). Road + ruined-road are now
> **data-only LEGACY**: `mappings.roadTypesLegacy = [1,3]` flags them for
> importers, their brushes and the corridor Lane toggle are gone from the
> forge, and the packaged guide's legend/type-mixing/plaza prose is marked
> accordingly (dirtpath, type 2, is the one live band — trails). Legacy
> maps and saves still render; the showcase map's three road strips stay ON
> PURPOSE as the full-catalog acceptance coverage. Route doctrine as
> packaged (unchanged from RD7): **routes render as BARE packed-road
> corridors** (2–4 cells, mat 27) — town streets are cobble areas, major
> crossings are bridge STRUCTURES, minor crossings the ford decal.
>
> Previous (2026-07-26 night, WAVE RD FULL CLOSE at commit `a5baf52` —
> the release WorldForge pinned as its W0B fixture):
> **31,431 tiles per theme** (+282: the RD7 PACKEDROAD ground family, mat 27 —
> the warm graded roadbed that is now the default route floor). Road doctrine
> as packaged: **routes render as BARE packed-road corridors** (2–4 cells);
> the one-cell ROAD BAND is DEPRECATED for route display (user ruling
> 2026-07-26) — town streets are cobble areas, major crossings are bridge
> STRUCTURES, minor crossings the ford decal, and dirtpath keeps the faint
> backtrail job. The RD6 Corridor tool ships in the forge (straight-leg drag
> → corridor + hash-stable lay-bys). Manifests now carry **`sourceCommit`**
> (package identity for consumer dependency locks — WorldForge keys on it).
> Earlier in the same wave: dirtpath de-wired, wheel-rut/wear language on all
> 16 net16 masks, long-run rim nicks, cap terminus fades. Drivers:
> `review/road-system-reassessment/` + `review/road-direction-assessment/`;
> ruling record `review/rd7-packedroad/bare-vs-band.png`.
>
> Previous (2026-07-26, WAVES S + A CLOSE):
> **31,149 tiles per theme.** Wave S rolled the tone-bucket macro variation
> out to twelve more families (minerals, earths, exotics — 17 toned families
> total). Wave A closed the 2026-07 structures/props/decals audit: all 47
> confirmed findings fixed — true void-dark openings everywhere (new prop
> role 17), storefront/shell separation (dark doors, grounded merch, the
> half-timber tavern), statement-color identity marks (warm lamp glow, gold
> beehive skep, dark-facet crystals, guaranteed ore glints), contact shadows
> hugging their masses, the dock's crane with real mass, the smithy's worked
> floor, directional crack/web/rapids/waterfall decal re-reads (the fall now
> sizes to the river band and pours crest-to-splash), and the small-prop
> polish pass (seeded shrubs, separated target rings, plank-read debris).
> The showcase waterfall fixture moved onto the actual cliff face row.
> Post-wave record: `baseline/post-wave-a/close-report.txt`.
>
> Previous (2026-07-24, WAVE R CLOSE): 27,765 tiles per theme, Wave R complete: wet-group + hedge de-wallpaper (shallow p32 61.5→9.7 · water 39.8→8.6 · deep 37.1→7.6 · hedge 69.5→43.9), per-cell animation phase desync (importer ships TILE_ANIMATION_MODE_RANDOM_START_TIMES for the standing group), all four cliff biomes on the Q10 face ladder, the paving-apron decal (id 23), the animated ice-blue frost re-read, clustered leaves/blood/bones, rain-grey puddles, `mappings.minimap` (mat id → hex) and the §2.11 no-margin note, selector **v2 with macro tone buckets**. Wave Q
> (the quiet-ground re-polish, Q0–Q10) rebuilt every walkable ground on the
> fine-grain laws, added the weighted variant selector (grass's rare
> flower-meadow accent @10%) and the Q7/Q8 **tone-bucket macro variation**:
> five families (grass, drygrass, snow, sand, soil) split their variant axis
> pattern × tone — a smooth separately-seeded field drifts broad tonal
> patches across fields, baked as plain tiles (`mappings.selector` carries
> the integer recipe; GAME-GUIDE §2.4 + `tileforge_worldgen_example.gd`
> replicate it). Also in this release: dusk's earth + mineral palettes
> re-separated, winter's rock/stone split, snow cliff faces read at map
> zoom. Terrain is measurably calmer than the 2026-07-20 baseline across
> every ground (final report: `baseline/post-wave-q/close-report.txt`).
>
> **Selector / migration notes:** projects saved before the weighted
> selector carry no `selector` field and pin to **v1 uniform** —
> byte-identical output, forever. v2 is the shipped look; the forge offers
> a one-click migration under the Visual-variants slider. Game-side,
> uniform `% variants` picks stay structurally seam-safe but over-show the
> flower accent and scatter tone per-cell (tone siblings' edges differ by
> a faint ~⅛-step tint, so uniform picks also show a subtle tint checker
> at seams) — use the §2.4 field selector for the intended look.
> **Intentionally exempt from the quiet-ground treatment:** the animated
> hazard/wet group (water, shallow, deep, river, lava, hotspring) — being
> visible is their job; `deep` is fully untouched.

Each contains:

- one atlas PNG + Tiled `.tsj` per family (wang sets on terrain families)
- `tileforge-manifest.json` — the machine authority (`mappings` block: every
  id table, priorities, transitions, semantic-id grammars)
- `map.tmj` + `map-reference.png` + `map-data.json` — the **full-coverage
  showcase map**: every family and system on one 72×48 sheet. The reference
  PNG is the acceptance test (GAME-GUIDE §4): a renderer that pixel-matches
  it has proven the complete catalog. `map-data.json` carries ALL raw grid
  layers — the editable source representation.
- `GAME-GUIDE.md` — the integration guide (§2 = the complete runtime
  rendering algorithm; §2.13 = authoring new maps from scratch; §3 =
  walkability/hazards; §4 = the acceptance test). Written for a zero-context
  AI; audit-proven (a cold reader re-derived every mask and produced a
  pixel-identical render from these docs alone, 2026-07-20).
- `FORMATS.md` — format reference for custom importers
- `tileforge_importer.gd` (Godot 4.2+, builds the TileSet with collision,
  animation, terrain peering, custom data) · `tileforge_map_importer.gd`
  (Godot 4.3+, rebuilds map.tmj as map.tscn) ·
  `tileforge_worldgen_example.gd` (a runnable, replay-verified reference
  implementation of the procedural rendering algorithm — copy-adapt it)
- `TileForgeImporter.cs` (Unity — known limitation, predates the keyed
  manifest; see GAME-GUIDE §6)
- `validation-report.json` (0 failures)

## Handing a package to an AI

Give it the zip and say: *"Integrate this tile package into the game per its
GAME-GUIDE.md. Prove your renderer with the §4 acceptance test against
map-reference.png before building anything else."* Everything it needs is
inside; it should trust `mappings` over prose for every id.

## Regenerating

From the repo root (deterministic — same inputs, byte-identical zips):

The rich style rides in `showcase-rich.tileforge.json` (committed beside
this file — the CLI has no style flags, so the project file carries them):

```
node cli/tileforge.mjs --project exports/showcase-rich.tileforge.json --theme forest --out exports/tileforge-forest-complete.zip
node cli/tileforge.mjs --project exports/showcase-rich.tileforge.json --theme autumn --out exports/tileforge-autumn-complete.zip
node cli/tileforge.mjs --project exports/showcase-rich.tileforge.json --theme dusk   --out exports/tileforge-dusk-complete.zip
node cli/tileforge.mjs --project exports/showcase-rich.tileforge.json --theme winter --out exports/tileforge-winter-complete.zip
```

Theme zips are gitignored (on-disk release); this README + the project file
are the record.

## Sprite-forge reference pack

`tileforge-reference-pack.zip` (committed) mirrors the repo's `reference/`
folder: 13 biome scenes + 3 flagship maps ×4 themes, palette data, the
visual-laws doc and a machine manifest — the self-contained handoff for the
user's SEPARATE sprite forge. Entry point inside: README.md. Regenerate via
`cli/reference-scenes.mjs` + `cli/flagship-maps.mjs`, then re-zip.
