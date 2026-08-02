extends Resource
## THE LINE (sl-0115; AMENDED by sl-0123 — THE DRAG IS CUT). Arena
## combat in the galaxy view is NORMAL combat: nothing here moves the
## bait fighter, the catch, or any shot. The rift's pull lives in THE
## LINE ONLY — the strain clock (passive drain), the deep-edge strip,
## bullet hits straining the line, and the line's visual tension. NO
## coined name exists for any of this (correction #8): it is the line,
## the arena. Every number is [T] — refinement rounds own them.
##
## Attached per-scenario (ScenarioDef.rift_line -> SimWorld.rift_line);
## a null world field = no drains, no lives, no grace anywhere — every
## non-rift world is byte-identical by construction.

## Line stability drains, hp/second [T]: passive = the session clock;
## deep-edge = the overstretched-line strain, added on top while
## inside the deep strip. Integer-exact in-sim: units of 1/600 hp per
## tick (0.4/s -> 4, 2.2/s -> 22 at 60 t/s; see rift_step.gd ACC_DEN).
@export var passive_drain_per_sec := 0.4
@export var deep_drain_per_sec := 2.2
## Deep-strip width in tiles, measured from the arena's right interior
## edge (prototype: 26 px = 0.8125 t). Stays by the sl-0123 word.
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
