# Wildshot Adventures

Top-down 2D open-world fantasy action RPG with freely aimed projectile combat —
single-player-first, in the RotMG + Erenshor lineage. This repo is the game
implementation; it currently builds the **Phase A combat laboratory**: a
zero-reward combat-feel lab judged by fresh outside testers (Gate 1).

## Engine

**Godot 4.6.2 stable — pinned.** Do not upgrade except between Gate 1 cycles.
Typed GDScript only; no middleware; no Godot physics in gameplay code.

## Design authority

All design decisions live in the planning repo
(`Wildshot_adventure_final_planning`). This repo implements them and never
reinterprets them. **Read `CLAUDE.md` before working** — it embeds the
binding-constraint digest and the session rules (no-RNG, quiet-lab,
fresh-hands, scope tripwire). The build plan is the planning repo's
`docs/12-PHASE_A_LAB_BUILD_PLAN.md` (M0–M7 pre-vacation, M8 + two Gate 1
cycles in the vacation sprint).

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
| `assets/` | Raw forge drops (`.gdignore`d — importers consume these): `tileforge/` (theme packages), `assembler-pack/` (full enemy catalog: 57 families / 202 variants + 4 players), `projectile-pack/` (5 styles, pattern-mapped), `worldforge-packs/` (generated worlds; dusk small-cold-coastal committed) |
| `tileforge/` | The M1 theme package import (dusk-ae1eecb) as `res://tileforge/` per its GAME-GUIDE; `tileforge.tres` built by `addons/tileforge_importer/run_import.gd` (headless). Later package builds live beside it under `tileforge_packages/<id>/` (same driver, `--package=`); `world_builder` resolves each world pack's pinned identity against the registry |
| `assembler/` | The imported actor roster (player + mapped enemies) — roster-filtered by `addons/assembler_importer` from `data/actor_sheet_map.tres` |
| `addons/` | `tileforge_importer` (M1), `assembler_importer` (M4/M5, docs/14), `uikit_importer` (M4), `worldforge_importer` (post-M5, docs/15 — validates + consumes generated world packs) |
| `autoload/` | Config, Telemetry, DebugHub, BootArgs — exactly four, none holding gameplay state |
| `data/` | Weapons, enemies, patterns, abilities, scenarios, actor sheet map, budgets — all `.tres`, hot-reloadable |
| `sim/` | The engine-decoupled deterministic sim core (`systems/`, `collision/`) — global RNG banned here |
| `input/` | HumanSampler, ReplaySource, `bot/` — three equal InputSources |
| `game/` | Main scene, render layers, `views/` (presentation only — never mutates sim) |
| `ui/` | HUD, menus, options |
| `tests/` | `pixel_match/`, `assembler_pack/`, `replay_fixtures/` (golden replays), `bot_scenarios/` (proof isolates + calibration canaries + the density-audit scenario) |
| `tools/` | `hourslog.ps1`, `hours_report.ps1`, `gif.ps1` (F-rowless: G arms the ring buffer); later `export.ps1` |
| `notes/` | `hours.csv`, `TECH_DEBT_LEDGER.md`, `HANDOFF.md` (cold-start briefing for any new session) |
| `reports/` | Bot harness output — mechanical verification only, never gate evidence |

## CI

GitHub Actions, jobs activating as their producing milestone lands. Active
now: banned-RNG grep under `sim/` + GDScript format check (M0, forge packages
exempt as generated artifacts); TileForge §4 acceptance — pixel-match +
net16 mask derivation (M1); golden-replay hash gate ×10 (activated M3);
uikit, assembler-pack, projectile-pack, and worldforge-pack gates (M4+).
Coming: nightly DodgeBot (M7), CI-only tester exports (M8). Replay/bot jobs
run on Windows runners only — the determinism scope is
same-build/same-platform.
