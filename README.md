# Wildshot Adventures

Top-down 2D open-world fantasy action RPG with freely aimed projectile combat —
single-player-first, in the RotMG + Erenshor lineage. This repo is the game
implementation; the forward scope is **Slice v0.1** (THE WORLD IS THE TEST,
ruled 2026-08-01 sl-0098): the four-zone dusk overworld as a small scale of
the full game — living in the built world (leave a settlement, fight, loot,
level in-bracket, die and walk back; the world persists, no run framing) IS
what the loop bar judges, over the designer's week. The b65 town loop retired
with honor as the mechanism proof; the slice build plan is planning
`docs/23-SLICE_BUILD_PLAN.md`. **S0 FOUNDATIONS ARE BUILT (sl-0100/0101,
2026-08-01)**: the docs/22 stat frame is in the sim (three classes, THE
damage formula, the 115 speed cap in the integrator; anchor re-ruled 3.6
t/s by sl-0102), the living world is plumbed (193 leash-gated sites read
straight from the content pack), CORE-43 overworld death is live
(in-sim gold cost + settlement respawn), and the 32 NPCs + icon pack are
wired. THE SLICE picker row (`slice_overworld`) is the play surface;
**S1 (Green chapter content) starts only on its own designer routing.**

## Engine

**Godot 4.6.2 stable — pinned.** Do not upgrade except between Gate 1 cycles.
Typed GDScript only; no middleware; no Godot physics in gameplay code.

## Design authority

All design decisions live in the planning repo
(`Wildshot_adventure_final_planning`). This repo implements them and never
reinterprets them. **Read `CLAUDE.md` before working** — it embeds the
binding-constraint digest, the session rules (no-RNG, quiet-lab,
fresh-hands, scope tripwire), and the authoritative milestone tracker.
The build plan is the planning repo's `docs/12-PHASE_A_LAB_BUILD_PLAN.md`;
M0–M8 engineering is complete and the Gate-1 rewrite (loop bar, warm
watched first-touches) supersedes the original two-cycle prose.

## Hours logging (mandatory — PROD-01)

```powershell
tools/hourslog.ps1 start   # before ANY project work: code, art, design, planning
tools/hourslog.ps1 stop    # after
tools/hourslog.ps1 note "free-text note"
tools/hours_report.ps1     # weekly; 4-week rolling average vs the 40 h floor
```

Entries land in `notes/hours.csv` (committed). A 4-week rolling average below
40 h/week triggers the PROD-01 floor reset and the build plan's slip ladder —
by rule.

## Layout

| Path | Contents |
|---|---|
| `assets/` | Raw forge drops (`.gdignore`d — importers consume these): `tileforge/` (theme packages incl. the 9b8b2a2 dusk drop), `assembler-pack/` (full enemy catalog: 57 families / 202 variants + 4 players), `assembler-boss-pack/` (13 bosses 48×48 — THE boss roster by sl-0084), `wildshot-npc-slice-v1/` (32 NPCs, sl-0089), `wildshot-icons-proto_0.1.0/` (470 glyphs, sl-0083), `wildshot-overworld-pack-dusk-content/` (the world_filler content pack, reference-only, sl-0093), `wildshot-projectiles-sphere-v0/` (the SHIPPED projectile set; `projectile-pack/` = the 5-style recorded fallback), `uikit/`, `worldforge-packs/` (two committed worlds: dusk small-cold-coastal b65 + wildshot-overworld b77, per-pack pins). Every vendored pack carries a `.passport.json` byte pin + a fixed validation gate |
| `tileforge/` | The M1 theme package import (dusk-ae1eecb) as `res://tileforge/` per its GAME-GUIDE; `tileforge.tres` built by `addons/tileforge_importer/run_import.gd` (headless). Later package builds live beside it under `tileforge_packages/<id>/` (same driver, `--package=`); `world_builder` resolves each world pack's pinned identity against the registry |
| `assembler/` | The imported actor roster (player + mapped enemies) — roster-filtered by `addons/assembler_importer` from `data/actor_sheet_map.tres` |
| `addons/` | `tileforge_importer` (M1), `assembler_importer` (M4/M5, docs/14), `uikit_importer` (M4), `worldforge_importer` (post-M5, docs/15 — validates + consumes generated world packs) |
| `autoload/` | Config, Telemetry, DebugHub, BootArgs — exactly four, none holding gameplay state |
| `data/` | Weapons (lab trio + the three class frames), enemies, patterns, abilities, scenarios (incl. `slice_overworld` — THE SLICE), actor sheet map, budgets — `.tres`, hot-reloadable; plus `balance_frame.json` (THE docs/22 stat-frame tuning source — the sim loads it, the calculator gates it) |
| `npcs/`, `icons/` | Consumed pack trees (S0 seam 4): 32 NPC sheets + translated manifest (`tools/import_npcs.py`), the 470-glyph icon atlas pair (`tools/import_icons.py`) — regenerate from `assets/`, never hand-edit |
| `sim/` | The engine-decoupled deterministic sim core (`systems/`, `collision/`) — global RNG banned here |
| `input/` | HumanSampler, ReplaySource, `bot/` — three equal InputSources |
| `game/` | Main scene, render layers, `views/` (presentation only — never mutates sim) |
| `ui/` | HUD, menus, options |
| `tests/` | `pixel_match/`, `assembler_pack/`, `projectile_pack/`, `uikit/`, `worldforge_pack/` (validator test + per-drop one-shot probes), `settings/`, `feedback/`, `loop/`, `stat_frame/` (docs/22 contracts), `living_world/` (leash/respawn/importer contracts), `wiring/` (npc+icon contracts + render probe), `dev_map/` (minimap consumer + render probe), `crosshair/` (styles contract + preview), `pinch_probe/` (fit-rule + movement diagnosis probes), `determinism/` (the smoke), `replay_fixtures/` (golden replays), `bot_scenarios/` (proof isolates + calibration canaries + the density-audit scenario + `proof_slice_leash`) |
| `tools/` | `pretester_check.ps1` (THE one-command ship gate), `export.ps1` (dev+tester zips), `lockdown_lint.py`/`lockdown_probe.ps1`, `balance_calc.py` (the docs/22 stat-frame gates over `data/balance_frame.json`), `validate_icon_pack.py`/`validate_npc_pack.py`/`validate_content_pack.py` (pack byte pins; the content gate also enforces the b77 base pairing), `diag_walkability_grid.py` (porosity, per-drop pins), `diag_pinch.py` (prop-pinch census baseline), `evidence_report.py` + `decode_summary_code.py`, `hourslog.ps1`/`hours_report.ps1`, `gif.ps1` (G starts, G stops — start-to-finish frames stream to disk since 098a679), `godot_guard.ps1`, `validate_boss_pack.py`, `import_boss_actor.py`, `import_npcs.py`/`import_icons.py` (consumed-tree builders), `gen_cue_wavs.py` |
| `notes/` | `hours.csv`, `TECH_DEBT_LEDGER.md`, `HANDOFF.md` (cold-start briefing for any new session), `PACK_INTAKE_RUNBOOK.md` (world-pack drops), per-area records (nine-row, audio map, CORE-50 checklist) |
| `reports/` | Committed mechanical evidence: the canonical proof battery (byte-identical gate), stress/density + render audit captures — bot/harness output, never feel evidence |

## CI

GitHub Actions (`.github/workflows/ci.yml`), three jobs: lint (banned-RNG
grep under `sim/` + GDScript format check; forge packages exempt as
generated artifacts); determinism-smoke (double-run hash compare + golden
replays ×10, Windows runner — the determinism scope is
same-build/same-platform); pixel-match (TileForge §4 acceptance + net16
masks + uikit/projectile/worldforge/assembler/feedback/dev-map/crosshair
validations, plus the slice-era rows: stat frame, living world,
npc+icon wiring). The full ship gate — the fixed steps + the TWO-LANE
proof battery byte-identical (every reactive row at the CORE-53 floor
AND the 115 cap; sl-0102 speeds 3.6/4.14) + export both-artifacts-boot
+ lockdown probe (26 fixed steps / 34 rows / 65 battery runs as of
sl-0102) — runs locally as `tools/pretester_check.ps1` (needs
exclusive project access; ~40–45 min). The lint job also runs the
three pack validators + the balance calculator on every push.
