# THE STARHOOK BOSS EXPANSION + DUNGEON TEST — design record (sl-0180 + sl-0181)

Size-first check invoked as sanctioned: THREE WAVES, each gated and
resolved honestly. Wave 1A = the boss pool (sim); wave 1B = fish in
the bag + the C-menu rifter panel (view); wave 2 = the dungeon test.
Every number [T]; placeholder descriptive ids only (no lore names —
identities stay data-keyed for the designer's re-skin, the
ghost-species precedent); NO feel verdicts from the seat.

## Wave 1A — the boss pool

**The pool mechanism**: `starhook.fight_pool` [T] is PER-BIOME
(common/rare weighted lists per biome — the cast's biome carries
whole: a comet tear only opens comet fights). The cast's existing
rng_loot draw sequence EXTENDS: rarity, then the fight draw
(weighted; unknown/absent pool falls back to "catch" fail-safe).
CAST_COMPLETE grows a `fight` field (events are unserialized —
replay-safe); main routes "catch" exactly as today, else to
`data/scenarios/rift_boss_<fight>.tres`. Weights [T]: catch 70,
bosses ~10 each — rifts stay mostly fish; a boss sighting is an
event (the rifts-rare charter spirit at the pool level).

**Eight kits** (2–3 phases each; the 12x13 room; NO chaser phases —
the hooked-fish law; keep-range policies; elite amber, one hostile
language; the Warden recipe is the floor; every emitter's telegraph
== its pattern's ONE lead, roster-mechanized):

| id | biome | grade | hp [T] | new pattern (id, lead) | composition |
|----|-------|-------|--------|------------------------|-------------|
| twin_helix | nebula | 1 | 1500 | helix_arms (30, 36) ROTOR 2-arm spiral | P1 helix · P2 +spray · P3 denser |
| ring_nest | nebula | 1 | 1400 | ring_offset (31, 36) half-gap ring | P1 ring · P2 alternating offset rings · P3 +dart |
| sine_shoal | nebula | 2 | 2600 | sine_shoal (32, 24) SINE 3-fan | P1 shoal · P2 +spray · P3 wide shoal |
| boomerang_veil | void | 2 | 2800 | boomerang_veil (33, 30) BOOMERANG 4-arc | P1 veil · P2 +void ring · P3 +dart |
| decel_wall | void | 3 | 1500 | decel_wall (34, 30) DECEL 7-arc hang | P1 wall · P2 +spray · P3 +dart |
| zone_constellation | void | 3 | 1600 | constellation_zone (35, 45) hazard cast | P1 spray+zones · P2 +ring · P3 dense |
| cross_burst | comet | 1 | 1600 | cross_burst (36, 36) ROTOR 4-cross | P1 cross · P2 +spray · P3 +dart |
| pulse_lattice | comet | 4 | 1900 | pulse_fan (37, 30) DECEL 5-fan | P1 spray+ring · P2 pulse fan · P3 three-slot weave |

- SINE/BOOMERANG/DECEL are bot-modeled closed-form (dodge_policy
  projects motion-program velocity at any age) — these are the FIRST
  hostile users; the proofs exercise that projection live.
- Rotor kits carry no second radial in any phase; ring_nest's
  alternating offset rings are sequential walls (long cooldowns) —
  if proofs refuse, P2 re-composes under never-weaken.
- Grades map to the tackle tier ladder; the FIGHT-LENGTH GATE
  (balance_calc GATE 7) parses each def's hp from its .tres and
  bounds hp / spine-rod-DPS(grade) within [60, 300] s [T]
  (12.0/20.0/10.9/12.9 dps — the free level-grant rod at the
  grade, the guaranteed-available identity). Also reports the
  strain-clock drain per fight length (info — the designer's
  lever). Pool ids must resolve, weights positive, catch present
  everywhere, every boss pooled somewhere. Negative-tested.
- Gold/xp by grade [T]: g1 80–140/150, g2 140–220/240, g3
  200–300/320, g4 280–400/420.
- Placeholder bodies: the code-drawn star-fish scaled by
  body_radius + per-kit tint (rift_view; zero new art).
- PHASE TOASTS generalize: the hardcoded COIL/THRASH pair becomes
  the def's own phase id (strip `p<n>_`, upper) — descriptive ids
  read as fight beats for every kit including the catch.
- CATCH-LANDING RE-PIN (pre-emptive for wave 2): the rift kill
  branch lands fish/CATCH_LANDED only for PHASED defs — gold still
  banks for any rift kill. Byte-identical today (every current
  rift enemy is phased); dungeons need mobs whose deaths do NOT
  end the dive.
- EQUIP-ANYWHERE RE-PIN (sl-0181 §6 prerequisite, sim): the tackle
  EQUIP op (176..191) becomes legal anywhere for class players —
  the C-menu panel equips from the field; BUY stays station-gated.
  One-session-old [T] behavior deliberately re-pinned; gather_test
  flips its away-refusal pin for equip only.
- NO-STROBE extends to every new pattern: a windowed probe fires
  each new pattern id in a dark rift room and counts mean-luminance
  direction flips among large deltas (the reveal-probe math);
  committed evidence + a hard bound.
- Proofs: per-kit schedule-paced proof scenarios (the
  proof_rift_catch shape — through every transition, kill,
  cleanup to 3600) at floor + cap115; battery +16 rows.

## Wave 1B — the visible starhook (view-only)

- **Fish in the bag** (sl-0181): the C-menu bag pane renders a
  CREEL strip — per-species stacked tiles composed from the in-sim
  fish wallet (p.fish, SERIAL 26). ONE truth: the species counts;
  the bag's 20 triples are untouched and fish occupy ZERO capacity
  (sized: the creel is a render of the wallet, not items — no dual
  truth, no cap interaction; a future designer word can make fish
  physical items, which would be a real sim seam). Per-species
  tooltips (name + count + "priced at the tackle keeper").
- **The rifter panel**: the character tab gains rod/chest/helm doll
  slots (worn gear from the profile/sim), equip/swap among OWNED
  pieces via the existing recorded ops (the station stays the buy
  surface). Evidence at both scales.

## Wave 2 — the dungeon test

The designer's shape verbatim: a 1–5 min PATH walked like a path,
mobs scattered along the way, a boss at the end. Committed-instance
machinery (the Warren precedent) in galaxy skin: a path-shaped rift
arena json; 2–3 rift-grade MOB defs (star language, phaseless —
their deaths bank gold only, never end the dive); pack spacing under
the Warren distance-discipline law (verified numerically at
authoring); the end boss drawn from the wave-1 pool defs; the line
frame unchanged. THE DRAIN QUESTION [P→T]: 0.4/s over a 1–5 min
path eats 24–120 stability (up to two lives by clock alone) — wave
2 ships a dungeon line def (data row) with passive drain 0.1/s [T]
so the walk is honest at L1; the designer's word picks the final
clock. TEST ACCESS FIRST: a dev console command jumps in; the
scenario also lists in the picker like every scenario (the
established exposure); ambient dungeon-rift spawns wire later
behind [T] once the test proves.

## Findings queued for the close

1. Per-biome pools keep the tear honest (the cast's biome carries).
2. Bosses are biome-PINNED v1 (each lives in one biome's pool);
   per-biome pattern variants of bosses are a future round.
3. The fight-length reference is the free-spine rod at the boss's
   grade [P] — planning may prefer a different reference.
4. The strain clock over 1–5 min fights is a real second pressure
   (reported per-fight by the calc); chest gear and the [T] drain
   are the levers.
5. Fish stay wallet-truth; the creel renders it (zero cap impact).
6. The dungeon drain def is the wave-2 [T] headline.
