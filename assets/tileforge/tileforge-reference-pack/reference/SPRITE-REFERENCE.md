# TileForge sprite reference pack

Written for a SEPARATE, ISOLATED sprite forge (and its AI assistant): everything a
sprite tool needs to make actors that sit convincingly in TileForge worlds, without
touching TileForge itself. Rendered 2026-07-25 (refreshed 2026-07-26, Wave-A close) from the live engine on the exact
export path the game consumes (`buildMapReference`, frame 0, rich deliverable
config — 31,149 tiles/theme at generation time).

## What's in this folder

- `scenes/` — 13 authored scenes ×4 themes at **1× (ground truth, 640×384)**
  plus a forest 2× copy per scene. These are LIVE GAME SETTINGS: real materials,
  structures, props and decals with every placement contract honored. Judge sprite
  candidates composited over these, at 1× and 2× — if it reads there, it reads in
  the game.
- `palette.json` — per theme: every family's role list with hex values, plus
  `materialBaseHex` (material id → representative hex, the minimap ramp).
- `palette-<theme>.png` — swatch sheets (rows = families in the json's order,
  cells = roles left-to-right). No labels; the json is the authority.

Scenes: forest-clearing · pine-wood · desert · snowfield · swamp · cave ·
dungeon-room · town-street · harbor · volcanic · corrupt-zone · farmland ·
**scale-lineup** (a height ladder — flowers → bush → barrels → statue → oak →
pine → a 2×2 cottage — for calibrating actor sizes visually).
Also: `animation-cadence.png` — the 4-frame cycles of water/river/lava/
hotspring at 3×, left to right = frames 0–3 (~300 ms each) — match this
chunky cadence rather than smooth tweening.
Regenerate (from the TileForge repo): `node cli/reference-scenes.mjs --out <dir>`.

- `flagships/` — three LARGE composed worlds ×4 themes (REF2): **crownhold**
  (walled mountain city: 3-tier snow peak, cave mouth, waterfall-fed moat +
  drawbridge, corner watchtowers, plaza + shop street, farm belt, watermill),
  **tidewater** (harbor town: quay market, dock + piers + breakwater,
  lighthouse headland, river mouth), **thornhollow** (dark wilds: bog,
  corruption front, ruined complex, drowned pool, graveyard, stone circle).
  These are the "live game settings" at their busiest — the truest test
  backdrops for sprite candidates. Regenerate: `node cli/flagship-maps.mjs`.
  One-click browsing: `viewer.html`.

## The world's visual laws (sprites must obey these to belong)

- **Grid & scale**: 32×32 px cells. 1-cell props; trees are 2 cells tall (canopy
  overhangs the cell above); structures span multiple cells. A humanoid actor
  reads best at ~22–30 px tall inside its cell; bosses can span cells.
- **Light comes from the NORTH-WEST**, always. Lit left/top, shaded right/bottom.
- **Outlines are selective**: dark 1px outline on the shaded side, open (no
  outline) on the lit side; outline color is the subject's own dark ramp, never
  pure black.
- **Ground shadows** are checkerboard-dithered seats hugging the base contour
  (see any tree/structure in the scenes). The tile shadow color reads MAROON, not
  black — pick a dark from your subject's ramp for sprite-internal darkness.
- **Openings/holes** are true near-black voids, not mid-grey.
- **Solid beats outline at 32 px**: silhouettes carry identity; 1px strands and
  outline-only shapes die at game zoom.
- **Contrast doctrine**: the grounds are DELIBERATELY quiet (fine 2px grain, no
  distinct shapes, macro tone patches at ±3 luma). Actors own the saturation and
  value pop. Check your sprite's silhouette against `materialBaseHex` for every
  material it can walk on — a body value within ~15 luma of a ground it stands on
  will camouflage. The busiest backdrops are water/wet materials; the quietest
  are the toned grounds.
- **Four themes, one geometry**: forest/autumn/dusk/winter re-color the SAME art
  via role ramps (see palette.json — dusk is the most divergent, winter the
  palest). Either draw sprites theme-neutral (colors that sit on all four) or
  re-map sprite palettes per theme the way the tiles do. Test on all four; the
  historical trap is a color that matches one theme's backdrop ramp exactly
  (things drawn in grass-green vanish on lawns).
- **Animation cadence**: tile animations are 4 frames at ~300 ms on a chunky
  clock; standing water desynchronizes per cell, flowing water stays globally
  synced. Sprites are free to use more frames, but motion reads best matching
  the world's chunky cadence rather than smooth 60fps tweening.
- **Faction/statement color**: banners, tents, keep pennants and bedrolls all fly
  one theme "statement" color (`meta` role 17 / `prop` role 12 class). If actors
  carry faction cloth, sampling that color ties them to the world's factions.

## What NOT to copy from tiles

Tiles obey seam/edge contracts (their border pixels are constrained for
tiling) — sprites don't tile and need no such ring. Tile art also avoids
per-tile uniqueness by design; sprites are the opposite — they exist to be
distinct. Take the palette, light, outline and shadow laws; leave the tiling
machinery.
