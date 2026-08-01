# b77 prop-pinch diagnosis (sl-0070) — DIAGNOSIS ONLY, no fixes

2026-08-01. Pack: `wildshot-overworld-pack-dusk` @ b77 (flood 46493,
spawn 109,182). Census tool: `tools/diag_pinch.py` (committed,
re-runnable — the baseline whichever fix lever is judged against);
full machine-readable results in `reports/pinch_diagnosis_b77.json`.
Movement facts measured on the REAL shared `Kinematics.move_circle`
at the real `TERRAIN_RADIUS` 0.25, lowest intended speed 3.0 t/s,
dt 1/60. Species mapping cross-checked exact against the sl-0067
intake record (carpet cells: stump 509 / fallen_log 490 /
bone_pile 44 / loot_pile 1 — all four verbatim).

## Plain summary (the one-paragraph version)

The gaps you tried to walk are real in the art but exactly zero
cells wide in the data: two props on diagonal cells touch
corner-to-corner, and a corner point has no width, so no body of any
size fits through. There are 1,143 reachable prop gaps like that on
b77. None of them hides anything — every single one has a walk-around
(usually ~6 tiles, worst 102) — they just refuse the shortcut your
eyes expect. The movement code is behaving: it slides smoothly around
single corners, walks 1-cell alleys at full speed, and comes to a
clean, still stop in the wedge (no jitter). And the data is honest —
zero solid cells without a visible cause on screen. So this is purely
a "two props landed diagonal" generation pattern, and the fix choice
is the design pick between spacing props at generation and changing
what a prop's collision is.

## Q1 — pinch census (per the ask's definitions)

**Corner-touch pinches** (diagonal solid-solid pair, both shared
orthogonal neighbors open — zero-width for any collision circle):

- 2,003 total on the 256×256 grid; **1,901 (94.9%) prop-involved**.
- **1,143 prop-involved with BOTH open sides on the spawn flood** —
  the ones a walker can actually meet. Zones: 811 wild, 332
  settlement.
- Connectivity class: **all 1,143 are SHORTCUT-denials** (the two
  open sides are in the same connected area; a detour exists).
  **Component-boundary pinches: 0** — no corner-touch anywhere is
  the sole meeting point of two areas. Opening any of them would
  change zero connectivity, only path length. (Direct consequence:
  lever A cannot break the flood contract by accident — there is no
  connectivity to change at these sites.)
- Detour cost around a denied shortcut (BFS through open cells):
  min 6, **median 6**, max 102 tiles. Tail: 308 pinches (26.9%)
  force >10 tiles, 94 (8.2%) force >20, 22 (1.9%) force >40. The
  tail is where "walk all the way around" pain lives.
- Top solid-pair causes: oak+oak 133, birch+oak 127,
  dead_tree+dead_tree 46, pine+pine 41, oak+pine 40,
  dead_tree+willow 39, willow+willow 32, **cactus+dead_tree 29**
  (the screenshot's desert class). Trees dominate; boulders/cacti
  carry the desert sites.

**1-wide lanes** (open cell flanked by solids across one axis — the
near-pinch, passable-but-tight class):

- 3,635 lane cells total; 3,002 prop-involved; **2,296 prop-involved
  on the flood**.

**Per prop-dense region** (16×16-cell buckets, top by prop-solid
count — where the walk feels it most):

| region @cells | prop-solid | pinches | lane cells |
|---|---|---|---|
| (224,208) | 144 | 25 | 48 |
| (208,208) | 139 | 22 | 50 |
| (0,32)    | 134 | 21 | 45 |
| (16,96)   | 121 | 32 | 55 |
| (112,128) | 113 | 31 | 57 |
| (240,160) | 110 | 21 | 42 |
| (64,128)  | 103 | 23 | 37 |
| (192,208) | 103 | 21 | 43 |

## Q2 — sample typing: DATA / GEOMETRY / FEEL

**DATA-closed: the class is EMPTY.** Every solid cell on b77 has a
visible cause — after attributing props, structures, fences, water,
rock, cliffs (tmj cliff layer), and swamp-bog terrain (full-cell bog
art; swamp is a de-facto solid terrain class — only 22 of 1,082
swamp cells walk), **zero solid cells remain causeless**. Two
attribution lessons recorded for future probes: the 173
grass-material "mystery" solids were FENCE cells (read the fence
chunk layer), and the 752 swamp ones are wetland bog (hydrology
wetlandCellCount 1272). No desired lane on this pack is closed by
invisible data.

**GEOMETRY-closed: the whole complaint class.** All 1,143 reachable
prop pinches are open-cells-with-corner-touch — the lane your eyes
see exists in the data as two open cells meeting at a point, and a
point has no width. Screenshot-class sites (cactus + ≥2 boulders +
pinch within 3 cells): 135 candidates on the pack — the walked site
is one of this class. Representative samples (legend: `.` open `,`
carpet-prop `T` tree `c` cactus `b` boulder `r` outcrop `p` other
prop `S` structure `F` fence `W` water `R` rock `C` cliff `%` bog):

Screenshot-class @ (60,141) — cactus/boulder field, GEOMETRY-closed:

    ..,......
    .,..,....
    ..T...,..
    ,..T.Tc.b
    ....c.b..
    ..c..c...
    ..,b.,..c
    pcb,,....
    bb..,.cb.

Worst-detour pinch @ (121,149) — birch+birch, detour 102 tiles
(the pinch sits against a rock/water margin, so the walk-around
crosses the whole grove):

    TpTT.TTT.
    b....T..,
    T.TT,T,..
    ..T,.T...
    ....TT..c
    ..TT.,...
    ...pTRRRT
    ..%pRRRT.
    ..%WRRR..

Dense-region pinch @ (238,209) — oak+oak, detour 54:

    .T.T..T..
    ...T...T.
    ,..TT,..T
    ,,TTTTTbT
    .,..T,...
    TbTT..,..
    TTT.T,.T.
    T..T..TTT
    TTTT..T,.

**FEEL-closed: empty for the player body.** The candidate class was
the 1-wide lanes; the movement probe walks them at open-ground speed
(below). No sampled lane with a ≥1-cell path snags.

## Q3 — movement behavior: corner-slide or hard-stop?

Both, each in its honest place — measured on the shipped kinematics
(corner-tangency ejection + corner slip, the 2026-07-28 pair):

| case | result |
|---|---|
| Pinch, diagonal press through the corner | **Hard stop.** Wedge rest at exact double tangency (final (8.250,7.750) for solids (7,7)+(8,8)); no crossing; **motion over the last 60 ticks = 0.0000** — perfectly stable, zero shiver. |
| Pinch, face-slide entry pressing into it | Slides along the face, then the same honest still rest. |
| LONE corner, same diagonal press | **Corner-slides.** Crosses in 24 ticks vs 15 on open ground (+60% inside the corner zone, then free) — the slip curls the body around smoothly. |
| 1-wide lane, centered entry | 90 ticks vs 90 open-ground — **zero overhead**. |
| 1-wide lane, entry misaligned 0.4 cells | 94 ticks (+4.4%) — the slip funnels the body in nearly free. |

So: movement corner-slides everywhere a path exists, and hard-stops
(stably, explainably) exactly where the gap is zero-width. There is
no movement bug here to fix; the stop is the geometry.

## What the numbers say about each lever (the pick is the designer's)

- **(A) WF clearance/corridor re-gen** — addresses the class at its
  source: 1,143 reachable sites, every one a shortcut-denial, so
  relocating one prop per pinch (W-13 spirit: relocate, never
  delete) cannot change connectivity — it only shortens paths.
  Priority order by pain, if wanted: the 22 detour->40 sites, then
  the 94 detour->20, then dense regions per the table.
- **(B) game-side corner-sliding** — ALREADY SHIPPED (corner slip +
  tangency ejection, 2026-07-28); the probe shows it working. B
  cannot open a zero-width gap by definition; further B-tuning
  changes approach feel only, not the refusal the designer hit.
- **(C) sub-cell prop colliders** — the only game-side change that
  opens corner-touch gaps, and exactly as flagged: it breaks the
  WYSIWYG/flood contract (sim passability diverges from the
  4-connected cell flood the entire validation chain pins — pack
  floods, porosity diag, DodgeBot walkability, proofs). It would
  also open those gaps to every enemy walker. Deliberate design act
  only.

One honest overlap note: 332 of the reachable pinches sit inside
settlement radii; if lever A fires, the two-wide street rule
(sl-0035 era) already owns street clearance — the wild 811 are the
prop-field share the sl-0063 follow-up lever named.
