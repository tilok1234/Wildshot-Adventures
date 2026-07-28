# wildshot-projectiles-sphere v0 — shaded orbs

Seventh M-FX candidate, iterated to its final form on designer direction
(2026-07-28): **classic shaded orbs** — each sphere is ONE color identity,
smoothly shaded (NW-offset highlight per the world's light law, deepening
edge) with a **near-black outline** (`#120e14`-range — the world law says
never pure #000). Hard binary-alpha silhouette; all smoothing is baked
color feathering. Built read-only; the game repo was not touched.

## Library

| Group | Variants | Files |
|---|---|---|
| hostile orb | **a color system**: 24-hue wheel × 4 tones (base / `-pastel` / `-deep` / `-dark`) + a 6-step neutral ramp (white / gray / slate / charcoal / black / onyx) = **102 identities** × **7 sizes** (small tier d6/d8/d10 + d12/d13/d16/d20) = **714 orbs**; the outline thins with radius so tiny orbs keep a body | `sprites/hostile/orb-d{D}-{ident}.png` |
| hostile zones | bright-rimmed 1.5-tile hazard + 8-step arm ring | `hazard-zone.png`, `hazard-arm-strip8.png` |
| friendly | shaded silver bolt / pellet / wheel annulus / nova ring / blast rune zone | `sprites/friendly/*.png` |

Hues are generated (deterministic HSV, per-region value tuning — wheel
names: red vermilion orange amber gold yellow chartreuse lime green
emerald jade teal cyan sky azure blue sapphire indigo violet purple
orchid magenta pink rose). The manifest suggests a Phase-A mapping (Husk
red, Leadshot violet, Fanmaw orange, Ringer magenta, Warden amber) —
**hue-per-family is the designer's pick**; with 300 orbs on the shelf the
choice is a data edit, not an art request. One steer: pastels sit closest
to friendly silver — prefer base/deep for primary threats, keep pastels
for accents and Phase B variety.

## Contract

- Hostile orbs are full-bleed: the outline sits ON the collision boundary;
  Law-8 coverage asserted per sprite (all 76 pass). Friendly art is
  smaller than its hitbox (bolt d8 in hd10, pellet d6.4 in hd8).
- **Faction split** now rides on saturation/value: saturated shaded hues =
  hostile; friendly is exclusively desaturated silver (and smaller). Both
  factions wear the same near-black outline.
- **Signature note (flagged, designer-directed)**: this replaces the §2.6
  placeholder (rim + hard core) with "saturated shaded body + near-black
  outline". The M6 Law-3 hostile-vs-friendly stress test at density is the
  arbiter; if it ever reads soft, the recorded fallback is re-brightening
  hostile outlines to own-hue tints (the previous iteration, one generator
  edit). Hue varies per family — CORE-50 holds because size + volley
  pattern also separate families. Adopting this pack = a one-line §2.6
  amendment in the planning repo first.
- Round everything: no rotation needed anywhere; friendly stays round so
  the existing view travel-stretch pipeline works unchanged. Still the
  most drop-in candidate. Bands 5/7/8 as everywhere; hostile channels
  clamp fully visible at every density setting. Native 1×, 32 px/tile,
  nearest.

## Regenerate / preview

```powershell
pwsh tools/generate.ps1
```

Deterministic; no RNG. Static: `preview/lineup-4x.png` (8×4 hue/size grid
on dusk + winter), `preview/zones-2x.png`. Animated: the combined packet's
viewer (`../wildshot-projectiles-all-v0/preview/viewer.html`, style
"sphere") — lineup / true-speed flight / seeded stress swarm / hitbox
overlay.
