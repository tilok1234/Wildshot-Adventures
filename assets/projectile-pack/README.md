# wildshot-projectiles-all v0 — one packet, five styles

Aggregation of the five M-FX candidate packs into a single distributable
packet with **one preview**. Nothing new is authored here: this pack copies
the source packs' sprites under `sprites/<style>/…`, merges their manifests
(100 rows, each tagged with `style` and a `<style>:` id prefix), and
composes the comparison artifacts. The game repo remains untouched.

| Style | What it is | Source of truth |
|---|---|---|
| `v0` | shaded/detailed silhouettes | `../wildshot-projectiles-v0/` |
| `min` | flat restyle of the same silhouettes | `../wildshot-projectiles-min-v0/` |
| `eclipse` | new shapes + proposed void-heart signature | `../wildshot-projectiles-eclipse-v0/` |
| `mono` | disc variations library (4 sizes × 5 pips + clusters) | `../wildshot-projectiles-mono-v0/` |
| `ray` | small capsule tracers (length = speed; needs hostile rotation) | `../wildshot-projectiles-ray-v0/` |

## The one preview

- `preview/all-styles.png` — five styles × the nine Phase-A slots at 4× on
  dusk AND winter grounds, plus every hazard/rune zone at 1×. The whole
  M-FX decision on a single sheet.
- `preview/viewer.html` — one viewer, **live style dropdown**: lineup,
  true-speed flight, and the seeded stress swarm (~120 sustained hostile).
  The swarm keeps running when you switch styles — same seed, same shots,
  different skin: the fairest A/B possible. Hitbox overlay shows each
  style's Law-8 contract.

## Using it

Pick by id prefix (`mono:hostile-disc:d13-triad`) or by style folder. All
five styles share: the §2.5 bands (5 friendly / 7 hostile / 8 hazard
rim+arm), Law-8 coverage asserted by each source generator, hitbox mapping
via `hitbox_diameter_px`, native 1× / 32 px per tile / nearest. Per-style
contracts (signature variant, orientation requirements, cluster rules,
Phase-A mapping) live in each source README — linked in `manifest.json`
under `styles.*.docs`. Eclipse's signature deviation and ray's
rotation-along-velocity requirement are per-style decisions, flagged
there, never silently inherited by picking this packet.

## Regenerate

```powershell
# 1. regenerate any edited source pack first:
pwsh ../wildshot-projectiles-mono-v0/tools/generate.ps1   # etc.
# 2. reassemble this packet:
pwsh tools/assemble.ps1
```

Deterministic; no RNG. `assemble.ps1` fails loudly if a source pack is
missing.
