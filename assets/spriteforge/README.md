# Sprite Forge — full pack (2026-07-27)

231 actors, forest theme, ×2 scale. One sheet PNG per actor; composite bosses also ship a *-parts.png (each moving part separately) with motion metadata in the manifest.

- players/ — 12 armor-set kits (crusader … onivanguard), 28-row humanoid sheets
- npcs/ 6 + vendors/ 4 — civic characters incl. working poses (work/carry/lean rows)
- enemies/ 128 — every monster in the library, zone-flavored accents
- bosses/ 34 — 18 full + 6 mini gatekeepers + 10 composite multi-part (with parts sheets)
- props/ 12 · projectiles/ 20 · effects/ 15

manifest.json describes every entry: id, name, zone, cell size, sheet path, row layout (label + frame count per row), rate, flags (flying/ranged/boss/rig), the exact cfg to regenerate it, and part motions for composites.

Row order per rig is under `rigs` in the manifest. All sheets are transparent-background, frames left-to-right, rows top-to-bottom, cell*2 px per frame.
