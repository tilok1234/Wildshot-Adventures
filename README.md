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
| `assets/` | Raw forge drops (`.gdignore`d — importers consume these): `tileforge/` (4 theme packages + reference pack), `spriteforge/` (231-actor pack incl. projectiles/effects, manifest-driven) |
| `tileforge/` | The active theme package (dusk) as `res://tileforge/` per its GAME-GUIDE; `tileforge.tres` built by `addons/tileforge_importer/run_import.gd` (headless) |
| `addons/` | `tileforge_importer` (M1), `spriteforge_importer` (M2) |
| `autoload/` | Config, Telemetry, DebugHub, BootArgs — exactly four, none holding gameplay state |
| `data/` | Weapons, enemies, patterns, abilities, scenarios, actor sheet map, budgets — all `.tres`, hot-reloadable |
| `sim/` | The engine-decoupled deterministic sim core (`systems/`, `collision/`) — global RNG banned here |
| `input/` | HumanSampler, ReplaySource, `bot/` — three equal InputSources |
| `game/` | Main scene, render layers, `views/` (presentation only — never mutates sim) |
| `ui/` | HUD, menus, options |
| `tests/` | `pixel_match/`, `actor_sheet_slice/`, `replay_fixtures/` (golden replays), `bot_scenarios/` (incl. calibration canaries) |
| `tools/` | `hourslog.ps1`, `hours_report.ps1`; later `export.ps1`, `gif.ps1` |
| `notes/` | `hours.csv`, `TECH_DEBT_LEDGER.md` |
| `reports/` | Bot harness output — mechanical verification only, never gate evidence |

## CI

GitHub Actions, jobs activating as their producing milestone lands. Active
now: banned-RNG grep under `sim/` + GDScript format check (M0, forge packages
exempt as generated artifacts); TileForge §4 acceptance — pixel-match against
`map-reference.png` + net16 mask derivation (M1). Coming: golden-replay hash
gate (M4), nightly DodgeBot (M7), CI-only tester exports (M8). Replay/bot
jobs run on Windows runners only — the determinism scope is
same-build/same-platform.
