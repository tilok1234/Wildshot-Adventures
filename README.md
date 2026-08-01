# Wildshot Adventures

Top-down 2D open-world fantasy action RPG with freely aimed projectile combat —
single-player-first, in the RotMG + Erenshor lineage. This repo is the game
implementation; the forward scope is the **Loop milestone** (Gate 1 as
rewritten 2026-07-30): an unguided complete run — spawn in town, fight out
through rising danger where loot drops and matters, reach the first boss or
die trying, death costs something real, retry pulls immediately — that stays
fun for the designer playing it daily. Loop v1 is built and being played;
the zero-reward lab law was lifted for loop work by that ruling.

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
| `assets/` | Raw forge drops (`.gdignore`d — importers consume these): `tileforge/` (theme packages incl. the 9b8b2a2 dusk drop), `assembler-pack/` (full enemy catalog: 57 families / 202 variants + 4 players), `assembler-boss-pack/` (13 bosses 48×48, raw by ruling), `wildshot-projectiles-sphere-v0/` (the SHIPPED projectile set; `projectile-pack/` = the 5-style recorded fallback), `uikit/`, `worldforge-packs/` (two committed worlds: dusk small-cold-coastal b65 + wildshot-overworld b77, per-pack pins) |
| `tileforge/` | The M1 theme package import (dusk-ae1eecb) as `res://tileforge/` per its GAME-GUIDE; `tileforge.tres` built by `addons/tileforge_importer/run_import.gd` (headless). Later package builds live beside it under `tileforge_packages/<id>/` (same driver, `--package=`); `world_builder` resolves each world pack's pinned identity against the registry |
| `assembler/` | The imported actor roster (player + mapped enemies) — roster-filtered by `addons/assembler_importer` from `data/actor_sheet_map.tres` |
| `addons/` | `tileforge_importer` (M1), `assembler_importer` (M4/M5, docs/14), `uikit_importer` (M4), `worldforge_importer` (post-M5, docs/15 — validates + consumes generated world packs) |
| `autoload/` | Config, Telemetry, DebugHub, BootArgs — exactly four, none holding gameplay state |
| `data/` | Weapons, enemies, patterns, abilities, scenarios, actor sheet map, budgets — all `.tres`, hot-reloadable |
| `sim/` | The engine-decoupled deterministic sim core (`systems/`, `collision/`) — global RNG banned here |
| `input/` | HumanSampler, ReplaySource, `bot/` — three equal InputSources |
| `game/` | Main scene, render layers, `views/` (presentation only — never mutates sim) |
| `ui/` | HUD, menus, options |
| `tests/` | `pixel_match/`, `assembler_pack/`, `projectile_pack/`, `uikit/`, `worldforge_pack/` (validator test + per-drop one-shot probes), `settings/`, `feedback/`, `loop/`, `determinism/` (the smoke), `replay_fixtures/` (golden replays), `bot_scenarios/` (proof isolates + calibration canaries + the density-audit scenario) |
| `tools/` | `pretester_check.ps1` (THE one-command ship gate), `export.ps1` (dev+tester zips), `lockdown_lint.py`/`lockdown_probe.ps1`, `diag_walkability_grid.py` (porosity, per-drop pins), `evidence_report.py` + `decode_summary_code.py`, `hourslog.ps1`/`hours_report.ps1`, `gif.ps1` (F-rowless: G arms the ring buffer), `godot_guard.ps1`, `validate_boss_pack.py`, `import_boss_actor.py`, `gen_cue_wavs.py` |
| `notes/` | `hours.csv`, `TECH_DEBT_LEDGER.md`, `HANDOFF.md` (cold-start briefing for any new session), `PACK_INTAKE_RUNBOOK.md` (world-pack drops), per-area records (nine-row, audio map, CORE-50 checklist) |
| `reports/` | Committed mechanical evidence: the canonical proof battery (byte-identical gate), stress/density + render audit captures — bot/harness output, never feel evidence |

## CI

GitHub Actions (`.github/workflows/ci.yml`), three jobs: lint (banned-RNG
grep under `sim/` + GDScript format check; forge packages exempt as
generated artifacts); determinism-smoke (double-run hash compare + golden
replays ×10, Windows runner — the determinism scope is
same-build/same-platform); pixel-match (TileForge §4 acceptance + net16
masks + uikit/projectile/worldforge/assembler/feedback validations). The
full ship gate — 17 fixed steps + the 28-row proof battery byte-identical
+ export both-artifacts-boot + lockdown probe — runs locally as
`tools/pretester_check.ps1` (needs exclusive project access; ~15 min).
