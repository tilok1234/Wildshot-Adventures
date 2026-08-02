extends Resource
## THE PULL + THE LINE (sl-0115, prototype #2 — "worth a real .tres").
## One resource holds the rift arena's physics: the constant pull toward
## the deep edge, the line's stability drains, and the three lives. NO
## coined name exists for any of this (designer correction #8): it is
## the pull, the line, the arena. Every number is [T] — prototype values
## converted to the game's 60 t/s where the prototype's were per-second
## or 30 t/s ticks (HANDOFF §7; the conversion is the seam record).
##
## Attached per-scenario (ScenarioDef.rift_pull -> SimWorld.rift_pull);
## a null world field = no pull, no drain, no lives anywhere — every
## non-rift world is byte-identical by construction.

## Pull magnitude, tiles/second (wall-clock; the integrators multiply
## by DT). Prototype 1.35 [proto->T].
@export var pull_tiles_per_sec := 1.35
## Direction oscillation: angle = sin(tick * rate) * amplitude around
## +X (toward the deep edge). Prototype: sin(t*0.008)*0.45 at 30 t/s
## == rate 0.004 at 60 t/s, amplitude ±0.45 rad ≈ ±25°, period ~26 s.
@export var osc_amplitude_rad := 0.45
@export var osc_rate_per_tick := 0.004
## Per-kind multipliers [proto->T]: the bait fighter fights the full
## current; the catch drifts a little; HOSTILE shots bend slightly
## (friendly bolts fly true — the prototype's own choice, and CORE-32's:
## the player's aim is never perturbed).
@export var player_mult := 1.0
@export var boss_mult := 0.3
@export var bullet_mult := 0.15
## Line stability drains, hp/second [proto->T]: passive = the session
## clock; deep-edge = the overstretched-line strain, added on top while
## inside the deep strip. Integer-exact in-sim: units of 1/600 hp per
## tick (0.4/s -> 4, 2.2/s -> 22; see rift_step.gd ACC_DEN).
@export var passive_drain_per_sec := 0.4
@export var deep_drain_per_sec := 2.2
## Deep-strip width in tiles, measured from the arena's right interior
## edge (prototype: 26 px = 0.8125 t).
@export var deep_edge_tiles := 0.8
## THE THREE LIVES (deck tap shk1loss): a dive survives up to three
## snaps; each line is HARD to lose [T]. A depleted life refills
## stability and burns a snap; the third snap ends the dive.
@export var lives := 3
## Post-hit grace, ticks (prototype 15 @ 30 t/s = 0.5 s -> 30 @ 60).
## Bullet hits only — the drains never pause (the clock is the clock).
@export var hit_iframe_ticks := 30
## Grace after a snap [T] — a fresh line is not lost to the same volley.
@export var snap_grace_ticks := 90
