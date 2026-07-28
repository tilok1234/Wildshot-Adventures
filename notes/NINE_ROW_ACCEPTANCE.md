# Nine-Row Effects Acceptance (M6 — CORE-51 Laws 1–8 + photosensitivity)

Per docs/12 §4 M6: "acceptance is an event with a record, not a vibe."
This is the record. Applied to the SHIPPED set: **wildshot-projectiles-
sphere-v0 (shaded orbs — adopted 2026-07-28, designer-directed; §2.6
hostile-signature amendment recorded in the planning log; hue map with
the CVD-checked ringer magenta-deep fix; §3.4 small-tier shot-radius
retune, full battery re-proven)** + assembler actor sheets +
EffectLibrary pass (game 372a94f) + audio cue map (c794906). The
previous projectile pack stays in-repo as the recorded fallback until
this acceptance passes. Captures below regenerated against the sphere
set; `reports/density_audit_m6_deutan.png` (deuteranopia-simulated max
capture) is committed as added Law-3 evidence — judge row 3 with those
eyes too.

**Evidence captures** (scripted `--audit=density` runs, seed 77, tick
420, god-logged, settings untouched):
- `reports/density_audit_m6.png` — MAX: every player channel forced
  full (scattercast spam + flashes + full damage numbers) over the
  stress ring + 2 Blightcasters (armed burning zones IN FRAME under
  the pile — the M6 hazard-occlusion requirement). Meter visible:
  enemies 27/24 deliberately over-budget (red), sustained worst-case
  17/150, 60 fps.
- `reports/density_audit_m6_min.png` — MIN: effect density minimal,
  opacity faint, flash reduction ON, damage numbers reduced. Effects
  0/150 (vs 9/150 at max) with hostile shots, zone fills, rims, and
  arm strips rendering IDENTICALLY to the max capture — the §2.6
  hostile clamp demonstrating itself.
- `reports/density_audit_m5.png` — retained M5 historical evidence
  (pre-hazard scenario revision).

Scenario note: audit_density carries the M5 ring (24 husk + 4 rusher,
27 enemies over the 24 budget) + 2 Blightcasters added at M6 for zone
coverage. Live hostile projectiles at capture ≈ 17–22 — that IS the
honest sustained density of a legal composition (the §2.6 rule bounds
shipped scenarios under 150; the ceiling is a budget, not a target).
Player-side noise, not hostile flood, is what Laws 1/2 stress here.

| # | Row | Mechanical evidence (done) | Eyes verdict (designer, rested) |
|---|---|---|---|
| 1 | Threat renders above beauty — hostile shots/telegraphs never occluded | §2.5 band assertions active at every boot (hostile rims band 70 over all friendly bands); hazard fill/rim split; Law-2/8 sprite upscale guard | PENDING — judge both captures: zone rims + arm strips + hostile shots legible under max player VFX |
| 2 | Player shots visually subordinate | Friendly 0.75 visual scale (under-render is player-favorable); separate friendly/hostile nodes by band; friendly-only opacity dimming | PENDING — max capture |
| 3 | Hostile vs friendly unmistakable by shape/pattern, one hostile language | Per-family shapes (orb/fang/dart/burr/heavy-orb/zones); pack-owned hostile signature; families differ by shape never color alone | PENDING at stress density — includes the **ledger #10 ruling** (slash shares fang with fanmaw: accept or request a pack rev) |
| 4 | Telegraph prominence equals danger | **MECHANIZED**: smoke Law-4 check — 12 danger-ranked rows non-decreasing (10<12<24=24<30=30<36=36<40=40<45=45), values read live from defs | Covered by code; spot-check at will |
| 5 | Hard per-encounter effect budgets, stress-tested | budgets.tres + density meter (live, 5 s peak, per-faction, sustained worst-case); elite peak now a REPORT FIELD (12 ≤ 300, dodge_proof_yw_full.json); meter red-lines the deliberate 27/24 in both captures | Covered by mechanism |
| 6 | Quiet arena floors — contrast reserved for gameplay | Lab/forest/dusk floors authored low-contrast (M1 Law-6 check; WorldForge dusk pack passed visual intake 2026-07-28) | PENDING — confirm on current builds |
| 7 | Audio as an eyes-closed second channel for key threats | Cue map written (notes/AUDIO_CUE_MAP.md) + 7 distinct-contour cues + separate KeyThreats bus + per-channel volumes; classification data-driven | PENDING — eyes-closed pass (slot in AUDIO_CUE_MAP.md) |
| 8 | Death always explainable | Recap freeze-frame + 5 s trace + telegraph lead by pattern (elite leads smoke-pinned: 24/30/36/40/45); session.jsonl evidence stream | Standing since M4; elite deaths verify in play |
| 9 | Photosensitivity: no element >~3 flashes/s, no full-screen luminance flips, on defaults; flash reduction further reduces | No screen shake / global hit-stop by construction (CORE-32); flashes are one-shot fades (no strobing element exists); flash reduction verified to shrink/dim/shorten every pop (0.6× size, 0.7× alpha, 0.75× life). Honest note: at stress, same-target impact pops can retrigger faster than 3/s — the pops move with targets and fade individually (not a fixed-position strobe), and flash reduction further dampens them | PENDING — judge max capture + live stress play on defaults |

## Sign-off

- Mechanical rows (4, 5) and the structural halves of 1/2/9: in place,
  evidenced above. — build session 2026-07-28
- Eye rows (1, 2, 3 incl. ledger #10, 6, 7, 9): **PENDING designer,
  rested session.** Record verdicts + date below.

| Date | Row(s) | Verdict | Notes |
|---|---|---|---|
| 2026-07-29 ~00:47 | 1, 2, 3, 6, 9 | ACCEPTED | Via Decision Deck register (two-tier in-session basis — the verdict-system ruling landed the same session). Fanmaw hue ruled KEEP ORANGE same session (the row-3 CVD adjunct; deutan capture is the evidence). Row 7 remains on the separate eyes-closed card. Ledger #10 note in row 3 was already closed by the sphere-pack hue map. |
