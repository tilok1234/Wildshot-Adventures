# WorldForge pack intake runbook — porosity-fix re-drop (2026-07-28)

The seam to run when the agent's re-exported dusk pack lands. Ledger
#15 is the charge sheet; `tools/diag_walkability_grid.py` is the
acquittal instrument. The hazard-aware near-miss metric (ledger #13)
is already in the harness and rides this battery.

## 1 — Drop

Replace `assets/worldforge-packs/small-cold-coastal-pack-dusk/` with
the new export (whole directory, byte-for-byte from WorldForge's
staging output).

## 2 — Validate (all must pass before any proof runs)

```
godot_console --headless --path . --script tests/worldforge_pack/worldforge_pack_test.gd
python tools/diag_walkability_grid.py            # exits 1 on any porosity
godot_console --headless --path . --quit-after 90   # grep "arena ready|ERROR"
godot_console --headless --path . --script tests/determinism/determinism_smoke.gd
```

Also eyeball the diag grid: every building must be a closed solid
block — no `.` inside `S` runs. Note the new floodCount vs old 33845
(a drop of roughly the stamped-cell count is expected; an outsized
drop = orphaned streets, STOP and send it back).

## 3 — Full canonical battery (one run serves pack + metric)

All 17 scenarios, canonical seeds (see notes/HANDOFF.md table + the
four yw rows). Expected regression matrix — anything off-matrix is a
finding, not noise:

- BYTE-IDENTICAL (no hazards in scenario, lab/forest arenas):
  canary_trivial, canary_undodgeable (JSON; wsr re-dumps fine),
  proof_rusher, proof_husk_archer, proof_fanmaw, proof_fanmaw_inside,
  proof_ringer, proof_leadshot, first_contact (still FAIL),
  second_contact, forest_walk, proof_yw_p1, proof_yw_p3.
- CHANGED near_miss ONLY (armed zones now sampled — ledger #13):
  proof_blightcaster (−1 → ~−0.167, single-seed probe verified),
  proof_yw_p2, proof_yw_full. Verdicts must stay PASS with hits 0.
  SEMANTICS: negative hazard clearance = the bot inside an armed
  zone's circle BETWEEN pulses — legal, honest play (zones bite only
  on pulse ticks). The verdict field is the evidence, as always.
- CHANGED collision (new pack): world_walk — new report, must PASS;
  the bot path may differ entirely. If it FAILs, read the heatmap
  before theorizing (stamped footprints may have narrowed a street
  the escort fight needs — that would be a spawn-layout retune, not
  a proof weakening).

## 4 — Movement re-test (the point of all this)

Relaunch the game (kill old godot, SetForegroundWindow). Designer
walks the town: facade-brushing must stay OUTSIDE building visuals
everywhere; no entering wall slots; awnings still occlude (canopy).
M2 movement approval is blocked on this feel verdict — theirs.

## 5 — Commit + records

- Game repo, one commit: pack directory + all changed reports (add -f)
  + this runbook's checkboxes in the message. Note the #13 metric's
  report lag closes here.
- Planning log: intake record (floodCount delta, battery matrix
  outcome, movement verdict when given). Push both repos.
- If the agent also delivered the roof→overhang second commit: the
  north-ridge residual in ledger #15 closes too; note it.
