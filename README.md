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
wired. THE SLICE picker row (`slice_overworld`) is the play surface.
**S1 GREEN COUNTRY IS COMPLETE (sl-0104/0105 + the sl-0113
UI/interaction family + the sl-0115 STARHOOK v2 merge,
2026-08-02)**: all 14 Green families in play at density, T1 loot +
tooltips, OLD TUSK + the HIDE unique, THE WARREN + KING GRUBB
(first dungeon), quests v1, STARHOOK v2 (the designer's prototype
#2 built for real: instant cast at land portals, 50/50 split with
the living line, three-lives line stability — the drag cut by
sl-0123, the pull lives in the line only — three biomes with named
fish persisted per-species, four level-gated
rods on R, ambient rift spawns) + foraging — and the interact era's
deliberate hands throughout: F-key pickups/givers/casts,
multi-active quest log, character sheet (C), HUD relayout with ONE
menu on O and Esc. **THE GREEN-DAYS PASS (sl-0119..0132, 2026-08-02
evening, nine sealed seams)**: the C sheet screen-anchored with an
interactive EQUIPMENT PANE (tooltips = the one grammar), quest-pull
kit (giver glyphs + map markers + HUD tracker), Grubb on his
war-crown boss sheet + Old Tusk render-scaled, the NPC crowd
desynced, firing rate ×1.25 exact (damage recalculated through the
balance calculator; the ruled hits-band caps the raise at ~1.3×),
THE BAG (pick up into it, equip is a decision on a recorded input
byte — replay format v3), LOOT BAGS on kills ([B] loot-all), THE
BANK at the capital stash keeper, and VENDORS v1 (sell 50%/buy
200%, fixed catalogs). Serialization SERIAL 25. **THE MENU PASS
v2 (sl-0143..0157, 2026-08-03, nine sealed seams on the designer's
menu-workbench package-as-spec)**: the C menu became ONE window with
TWO TABS on the drawn panel2 chrome (character = portrait + stats +
dollslots + the bag as a SLOT GRID with item glyphs; quest log =
cards + parchment detail + per-quest TRACKED + ABANDON), L
deep-links the log, quest givers OFFER on F with accept as a real
decision (recorded op; Later-only, no Decline), bank + vendors open
on F (never walk-over — loot bags stay walk-over by the designer's
word), Esc/O close the topmost menu first (one surface at a time),
HP/mana bars sit in the LEFT corner, options carries every row on
the new chrome, and THE UNIQUE REVEAL plays on boss-unique pickups
(no-strobe mechanized, sim paused under it, any input skips). The
quest ops ride the existing recorded byte — WSR stays v3, SERIAL
stays 25, the whole battery byte-identical. Seam I (minimal
foraging) was SIZED AND SPLIT OUT honestly
(notes/FORAGE_SEAM_SIZING.md — three one-line designer questions
route it); the player-hitbox seam (sl-0146) stays queued-deferred by
word. **The chapter gate is the designer living in Green; S2 starts
only on its own routing; water fishing is PARKED.** **THE GEAR SEAM
(sl-0177/0178, 2026-08-03, SERIAL 26)**: rods are starhooking
WEAPONS — a 12-rod catalog over the four family norms (three per
tier; the original four stay the free level-grant spine; zero new
patterns), rift-side CHEST + HELM rows (line capacity / bullet-
strain defense through THE formula), THE TACKLE VENDOR at the
harbor capital priced in FISH (the wallet is in-sim; buys/equips
ride recorded ops 144..191 on the existing byte), and rare catches
DROP Green-grade pieces (deterministic rng_loot, dup-protected).
Balance calculator gate 6 validates the whole catalog including
the rod .tres frames; every number [T]; the foraging seam builds
next at SERIAL 27. **THE STARHOOK BOSS EXPANSION + DUNGEON TEST
(sl-0180/0181, 2026-08-03/04, three gated waves, SERIAL/WSR
unchanged)**: casts DRAW A FIGHT from per-biome weighted pools —
eight boss kits at roster 30-37 (placeholder descriptive ids;
2-3 phases; keep-range only, the one-room law mechanized) over
eight new patterns (ids 30-37: the first hostile SINE/BOOMERANG/
DECELERATE uses, two precessing rotors, the alternating half-gap
ring, a galaxy zone), fight lengths gated by balance_calc gate 7,
NO-STROBE extended per pattern (probe + report committed), all
proofs green first authoring; THE CREEL (fish stacks under the
bag — the wallet stays the one truth, zero cap impact) + THE
RIFTER PANEL in C (click-cycles owned gear via the recorded op;
equip-anywhere re-pin, buy stays at the station); and the
DUNGEON-RIFT PATH TEST (a 64x44 serpentine walk, phaseless mobs
whose deaths can never end the dive, the pool's decel_wall at the
end, the slow dungeon line [T], console `dungeon` access) —
battery 83→105 runs. **The QUEST-PULL FINDINGS (sl-0175/0176,
view-only)**: map markers mirror the overhead giver-icon model on
both map surfaces (bang/ring/diamond, one truth) and giver icons
anchor the BODY at head height. **REFINEMENT ROUND 1 IS THE ROUTED
NEXT (designer play verdicts, planning sl-0186..0189)**: the
dungeon loads wrong in real play (diagnose-first — the walk
contradicts the passing bot proofs), fight length RE-RULED 20–60 s
intense (all eight kits re-derive), boss life splits
room-pattern/behavioural (the one-room law amends for rift
bosses), and console jump commands for every instanced encounter;
starhook names ride the cosmic vocabulary rail (sl-0182 — the
constellation, not the creel). Foraging builds behind it at the
next free SERIAL.

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
| `assets/` | Raw forge drops (`.gdignore`d — importers consume these): `tileforge/` (theme packages incl. the 9b8b2a2 dusk drop), `assembler-pack/` (full enemy catalog: 57 families / 202 variants + 4 players), `assembler-boss-pack/` (13 bosses 48×48 — THE boss roster by sl-0084), `wildshot-npc-slice-v1/` (32 NPCs, sl-0089), `wildshot-icons-proto_0.1.0/` (470 glyphs, sl-0083), `wildshot-ui-v2/` (the menu-workbench v2 UI pack — menu-specs.json IS the layout source of truth, 4 hue palettes, captures, the stampede cinematic frame; sl-0155), `wildshot-overworld-pack-dusk-content/` (the world_filler content pack, reference-only, sl-0093), `wildshot-projectiles-sphere-v0/` (the SHIPPED projectile set; `projectile-pack/` = the 5-style recorded fallback), `uikit/`, `worldforge-packs/` (two committed worlds: dusk small-cold-coastal b65 + wildshot-overworld b77, per-pack pins). Every vendored pack carries a `.passport.json` byte pin + a fixed validation gate |
| `tileforge/` | The M1 theme package import (dusk-ae1eecb) as `res://tileforge/` per its GAME-GUIDE; `tileforge.tres` built by `addons/tileforge_importer/run_import.gd` (headless). Later package builds live beside it under `tileforge_packages/<id>/` (same driver, `--package=`); `world_builder` resolves each world pack's pinned identity against the registry |
| `assembler/` | The imported actor roster (player + mapped enemies) — roster-filtered by `addons/assembler_importer` from `data/actor_sheet_map.tres` |
| `addons/` | `tileforge_importer` (M1), `assembler_importer` (M4/M5, docs/14), `uikit_importer` (M4), `worldforge_importer` (post-M5, docs/15 — validates + consumes generated world packs) |
| `autoload/` | Config, Telemetry, DebugHub, BootArgs — exactly four, none holding gameplay state |
| `data/` | Weapons (lab trio + the three class frames + the FOUR starhook rods), enemies (incl. the 14 Green families, Old Tusk, King Grubb, the six rift catches across three biomes), patterns (incl. the biome twist variants), abilities, quests, uniques, scenarios (incl. `slice_overworld` — THE SLICE — plus `the_warren` and the six `rift_<biome>_<rarity>` arenas), arenas (`arena_warren.json`, `arena_rift.json`), `rift_line.tres` (sl-0115, amended sl-0123 — the drag is cut: the line's drains/deep-edge/lives/graces; nothing in a rift drags any body or shot), actor sheet map, budgets — `.tres`, hot-reloadable; plus `balance_frame.json` (THE docs/22 stat-frame tuning source incl. the starhook block: rods, biome fish tables, ambient spawns — the sim loads it, the calculator gates it) |
| `npcs/`, `icons/` | Consumed pack trees (S0 seam 4): 32 NPC sheets + translated manifest (`tools/import_npcs.py`), the 470-glyph icon atlas pair (`tools/import_icons.py`) — regenerate from `assets/`, never hand-edit |
| `sim/` | The engine-decoupled deterministic sim core (`systems/`, `collision/`) — global RNG banned here |
| `input/` | HumanSampler, ReplaySource, `bot/` — three equal InputSources |
| `game/` | Main scene, render layers, `views/` (presentation only — never mutates sim) |
| `ui/` | HUD, menus, options |
| `tests/` | `pixel_match/`, `assembler_pack/`, `projectile_pack/`, `uikit/`, `worldforge_pack/` (validator test + per-drop one-shot probes), `settings/`, `feedback/`, `loop/`, `stat_frame/` (docs/22 contracts), `living_world/` (leash/respawn/importer contracts), `wiring/` (npc+icon contracts + render probe), `dev_map/` (minimap consumer + render probe), `crosshair/` (styles contract + preview), `pinch_probe/` (fit-rule + movement diagnosis probes), `green_roster/` (S1: 14-family contracts + pattern→lead law), `loot_label/` (drop grammar + render probe), `quests/` (multi-active interact-era contracts), `gather/` (forage/starhook cast + rifter round-trip), `rift_split/` (rift arena + split render probe), `char_sheet/` (screen==recompute parity), `ui_family/` (HUD relayout render probe), `quest_pull/` + `boss_sprites/` (green-days render probes), `bank/` + `vendors/` + `loot_bags/` (station render probes — station_open stands in for the F press), `menu_v2/` (the menu-pass probes: two-tab menu, offer dialogue, options restyle, the unique reveal + its mechanized no-strobe check), `motion_probe/`, `determinism/` (the smoke), `replay_fixtures/` (golden replays, WSR v3), `bot_scenarios/` (proof isolates + calibration canaries + the density-audit scenario + slice/Green/dungeon/rift proofs) |
| `tools/` | `pretester_check.ps1` (THE one-command ship gate) + `battery_runner.ps1` (the parallel proof-battery pool — workers = physical cores, cap 10, longest-first; `-Workers 1` = serial), `export.ps1` (dev+tester zips), `lockdown_lint.py`/`lockdown_probe.ps1`, `balance_calc.py` (the docs/22 stat-frame gates over `data/balance_frame.json`), `validate_icon_pack.py`/`validate_npc_pack.py`/`validate_content_pack.py`/`validate_menu_pack.py` (pack byte pins; the content gate also enforces the b77 base pairing; the menu gate re-checks icon parity LIVE against the wired proto pack), `diag_walkability_grid.py` (porosity, per-drop pins), `diag_pinch.py` (prop-pinch census baseline), `evidence_report.py` + `decode_summary_code.py`, `hourslog.ps1`/`hours_report.ps1`, `gif.ps1` (G starts, G stops — start-to-finish frames stream to disk since 098a679), `godot_guard.ps1`, `validate_boss_pack.py`, `import_boss_actor.py`, `import_npcs.py`/`import_icons.py` (consumed-tree builders), `gen_cue_wavs.py` |
| `notes/` | `hours.csv`, `TECH_DEBT_LEDGER.md`, `HANDOFF.md` (cold-start briefing for any new session), `PACK_INTAKE_RUNBOOK.md` (world-pack drops), `INTERACT_SWEEP.md` (the seam-H audit), `FORAGE_SEAM_SIZING.md` (the split-out seam-I questions), per-area records (nine-row, audio map, CORE-50 checklist) |
| `reports/` | Committed mechanical evidence: the canonical proof battery (byte-identical gate), stress/density + render audit captures — bot/harness output, never feel evidence |

## CI

GitHub Actions (`.github/workflows/ci.yml`), three jobs: lint (banned-RNG
grep under `sim/` + GDScript format check; forge packages exempt as
generated artifacts); determinism-smoke (double-run hash compare + golden
replays ×10, Windows runner — the determinism scope is
same-build/same-platform); pixel-match (TileForge §4 acceptance + net16
masks + uikit/projectile/worldforge/assembler/feedback/dev-map/crosshair
validations, plus the slice-era rows: stat frame, living world,
npc+icon wiring, and the S1 rows: green roster, loot grammar, quests,
gather, character sheet). The full ship gate — the fixed steps + the
TWO-LANE proof battery byte-identical (every reactive row at the
CORE-53 floor AND the 115 cap; sl-0102 speeds 3.6/4.14) + export
both-artifacts-boot + lockdown probe (31 fixed steps / 43 rows / 83
battery runs as of the menu pass — the menu-pack validator joined
the fixed steps) — runs locally as `tools/pretester_check.ps1`
(needs exclusive project access; **~13 min since the battery went
parallel** — `battery_runner.ps1` worker pool, byte-identical to
serial, every verdict exit-code-gated). The lint job also runs the
pack validators + the balance calculator on every push.
