# WorldForge pack intake runbook — porosity-fix re-drop (2026-07-28)

> **CURRENT STATE (2026-08-01, after ten clean intakes through b77).**
> The PROCEDURE below stands; the embedded EXPECTATIONS are
> era-stamped — live values: TWO committed worlds, per-pack porosity
> pins (`small-cold-coastal-pack-dusk` b65 = **44**;
> `wildshot-overworld-pack-dusk` b77 = **60**, flood 46493, spawn
> 109,182 — the diag takes pack dir + region + allowed as args); the
> battery matrix lives in notes/HANDOFF.md (43 rows / 83 runs × TWO LANES since
> S1 — floor 3.6 + cap 4.14, reactive record, parallel pool
> `tools/battery_runner.ps1` (byte-identical to serial); the content
> pack now rides scenarios as living-world spawn tables, and
> `proof_slice_leash` guards the leash); walkable-unreachable cells
> are LEGAL under WYSIWYG. Step 3's "first_contact still FAIL" is
> obsolete. Non-world packs (icons/NPCs/content) follow the passport
> + fixed-gate pattern instead — see their validators in tools/; NPC
> + icon re-drops additionally re-run tools/import_npcs.py /
> import_icons.py (consumed trees) + the wiring test.
>
> **RELEASE TRANSPORT (doc 18 §5, blessed sl-0016, first exercised
> 2026-07-30):** packs arrive as GitHub releases from
> tilok1234/WorldForge, tag = artifact id. BEFORE step 1: download the
> zip, locally verify zipSha256 (= GitHub's computed asset digest) +
> manifestSha256 + per-file manifest parity + tag→sourceCommit against
> the delivery line. Mismatch = incident entry + STOP. Then mirror the
> extracted pack directory in and RE-HASH after copy.
>
> **PAIRED TILEFORGE DOCTRINE (b76, sl-0061/sl-0064):** every pack
> pins `tileforge.packageId`; `world_builder.TILEFORGE_PACKAGES`
> resolves per-pin and refuses mismatches. If a delivery pins a NEW
> package build, it is a PAIRED DROP: import the TF release BESIDE
> the existing instances (raw under `assets/tileforge/`, consumed at
> `res://tileforge_packages/<id>/`, tres via
> `run_import.gd -- --package=<dir>`), append the registry line —
> NEVER swap `res://tileforge/` in place (HANDOFF gotcha #22).
> Same-pin drops (b77 class) need zero TF work.
>
> **MEASUREMENT LESSONS (b76/b77):** delivery-line censuses can be
> WORLD-side numbers — the pack differs by the world→pack seam (the
> same class that makes pack flood ≠ world flood); measure the PACK,
> and pin discrepancies via an immutable-archive diff of the
> predecessor release. Type every walkability/porosity delta cell
> (species / structure family / on-flood) per the sl-0052 precedent.

The seam to run when the agent's re-exported dusk pack lands. Ledger
#15 is the charge sheet; `tools/diag_walkability_grid.py` is the
acquittal instrument. The hazard-aware near-miss metric (ledger #13)
is already in the harness and rides this battery.

## 1 — Drop

Replace the delivered pack's own directory under
`assets/worldforge-packs/` (whole directory, byte-for-byte from the
verified release; in-place supersede is the norm — the predecessor
release stays the immutable archive). b65 and the overworld are
SEPARATE lineages with separate pins; a drop touches exactly one.

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
