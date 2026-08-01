# Session Handoff — rewritten 2026-08-01 (~02:45, post-b77 seam)

**COLD START — this handoff assumes NO prior context.** You may be a
fresh Claude instance under a DIFFERENT USER ACCOUNT (the designer
switches on usage limits; this handoff is written for exactly that).
Read the game repo's `CLAUDE.md` first (auto-loads; BINDING contract +
the authoritative milestone tracker — its milestone line is the full
append-only history this file deliberately does not repeat). This file
carries the current session state and the hard-won lessons the
contract doesn't.

## §0 What this project is (60 seconds)

Wildshot Adventures: a solo-developed RotMG-inspired top-down realtime
bullet-hell ARPG in **Godot 4.6.2 (pinned), typed GDScript, custom
deterministic sim, no Godot physics in gameplay**. Serialization
SERIAL 13; goldens current; all CI green.

Current phase: **the Loop era.** Gate 1 was REWRITTEN 2026-07-30
(sl-0023): the recruited-stranger zero-reward gate is retired with
cause; the bar is an unguided complete run — spawn in town, fight out
through rising danger where loot drops and matters, reach the first
boss or die trying, death costs something real, retry pulls
immediately — that stays **fun for the designer playing daily**. The
zero-reward lab law is lifted for loop work. Loop v1 is BUILT and has
been PLAYED (positive in-play verdicts, marathon-provisional). Warm
WATCHED first-touches get scheduled only once the loop bar holds.

- **Game repo (you are here):** `C:\Users\headc\Documents\Wildshot-Adventures`,
  branch `main`. Implements; never reinterprets design.
- **Planning repo (design authority):**
  `C:\Users\headc\Documents\Wildshot_adventure_final_planning` — ONE
  branch, `claude/questionnaire-note-taking-9vl2sl` (no main; do not
  create one). Its `tools/sync_log.json` is the cross-repo logbook
  (doc 18); `tools/ecosystem.lock.json` holds the pins.
- **The ecosystem map** (planning `docs/16-ECOSYSTEM_MAP.md`) names
  all seven repos and the hard cross-repo rules. **LANE RULE: game
  sessions NEVER execute other repos' plans/work.** Upstream needs
  become recorded asks or a self-contained prompt the designer hands
  to that repo's own agent. Reading other repos for context is fine;
  INTAKING their delivered packs is game-repo work.

## §0.5 Working with the designer

Solo dev, handle mmoabsurd (publicly **sarepat** — itch page
https://sarepat.itch.io/wildshot-adventures is LIVE with devlog +
GIFs). Big nerd, goes hard. Works a 15:00–23:00 shift — **"rested"
keys on hours into THEIR waking day, never wall clock** (home at
midnight ≈ their 17:00). They iterate by PLAYING: ship, then relaunch
the game for them (`Start-Process` detached `~/bin/godot.exe
--path .`; window opens BEHIND — front it via user32
SetForegroundWindow; kill old godot first — the console wrapper
spawns an engine child named plain "godot"). **Compact keyboard: NO
F1–F12 keys, ever.** Standing authority to commit and push both repos
at every clean seam.

- **Two-tier verdicts:** in-session designer calls count immediately;
  feel items additionally get one rested ratification. Marathons +
  dirty runs stay PROVISIONAL regardless. Feel verdicts accept rested
  humans only — never a bot.
- **THE DECISION DECK is the decision register** (planning
  `tools/decision_deck.html` + register JSON; they deal, decide,
  export; sessions sweep). **PLAIN-LANGUAGE RULE: anything written
  FOR the designer uses zero repo jargon** — say what each option
  concretely does. They asked twice; it's law.
- Private by temperament — public surface stays game-forward. They
  licensed nudging the weekly-GIF cadence, one line at natural seams.
- When they ship a pack mid-task, integrating it beats finishing your
  plan. When they ask to SEE something, render and send it (4×
  nearest-neighbor reads well). When THEY show YOU something (GIF,
  screenshot, video), treat it as primary evidence — read the frames.

## §1 Where things stand (2026-08-01)

**M0–M8 engineering complete.** The one-command ship gate
`tools/pretester_check.ps1` runs ALL GREEN (~14–19 min: 18 fixed
steps, 28-row proof battery byte-identical against committed reports,
export step building + boot-checking BOTH artifacts, lockdown probe).
Last full run: 2026-08-01 at the sl-0065 dev-map seam, 17.1 min.

- **THE LOOP (v1, SERIAL 13):** "THE LOOP" picker row — spawn in the
  b65 town, three proven danger rings westward, the BONE RELIQUARY
  KING at 105 tiles (Warden kit, 900 HP [T]). Loot tiers T1–T5 +
  armor + XP/levels + carried gold; death costs 25% [T] carried gold
  (permadeath toggle at creation = hardcore); one-key retry. EVERY
  number is [T] in `data/progression.tres` + the def drop tables.
  L2 (daily-play tuning) starts when the designer calls the skeleton
  "judgeable". Ledger #16 (replay character block) lands with L2.
- **Worlds, two committed lineages** (per-pack pins, doc-18 release
  transport, `notes/PACK_INTAKE_RUNBOOK.md`):
  `small-cold-coastal-pack-dusk` **b65** (THE LOOP's town +
  world_walk battery row; porosity pin 44; renders via the legacy M1
  tileforge import) and `wildshot-overworld-pack-dusk` **b77**
  (Overworld Walk picker row; flood 46493, spawn 109,182; porosity
  pin 60; renders via the 9b8b2a2 package). b77 = the
  prop-walkability drop: carpet/canopy/solid classes, 2,352 walkable
  crown cells, walk-under canopy PROVEN on screen
  (reports/canopy_render_audit_b77_*.png + pixel-mask verdict in the
  intake record). Road joints (47 cells) render since b76.
- **TileForge is PER-PIN** (b76 paired drop):
  `world_builder.TILEFORGE_PACKAGES` = `res://tileforge/` (M1
  ae1eecb build — b65-era packs) + 
  `res://tileforge_packages/dusk-9b8b2a2-seed103991/`. Packs resolve
  by their pinned identity; mismatches refuse loudly. See gotcha #22
  before touching anything tileforge-shaped.
- **Combat record:** REACTIVE is the DodgeBot policy of record; the
  three wolf-pair primary FAILs stay watched as `[--policy=primary]`
  MUST-FAIL baselines. Warden 575 HP [T] (~12 s Longbolt, TTKBot
  21/21 EXACT). Six ordinaries + elite all proof-passed at 3.0
  ability-off. Nine-row acceptance signed (rows 1/2/3/6/9,
  2026-07-29); sphere projectile set is the shipped look.
- **Audio era live** (Resonance Forge v1 intaken 2026-07-30): real
  cues on the data-driven map, 4-track music queue ducking −9 dB
  under threats, attack sounds (round-robin, zero sim change), FIVE
  channels (Master/Sfx/KeyThreats/Music/AttackSfx) each with off.
  Designer verdicts so far positive (Tier 1, provisional);
  NATURAL-TESTING mode — verdicts accumulate in play, do not nag.
- **Dev map overlay (sl-0065, 2026-08-01):** `N` cycles corner
  minimap / fullscreen map on every pack-routed scenario (THE LOOP
  included — b65 ships a minimap); the pack's own minimap.png raw +
  player dot + facing tick; dev profile only (lint-pinned like the
  console, negative-tested); hidden by absence on arena scenarios.
  Fixed gate tests/dev_map/dev_map_test.gd; render evidence
  reports/dev_map_audit_b77_*.png. If minimap resolution fails the
  designer's eyes it becomes a WF ask — upscale hacks banned. The
  PLAYER map stays Part II (doc 13 §3); this one is throwaway.
- **Tester pipeline standing:** export.ps1 dev+tester zips, one-flag
  dev_tools lockdown (lint + artifact probe in the gate), onboarding
  screen (copy = placeholder, designer voice pending), feedback
  bundle + WS1- summary codes + evidence_report.py. CORE-50 wiring
  mechanized both profiles; the RENDER half of the checklist
  (designer eyes, tester build) is still unchecked
  (`notes/CORE50_RUNTIME_CHECKLIST.md`).

## §2 Open — designer-side (do not nag; the deck + planning carry these)

- **b77 navigation walk** = THE sl-0066 acceptance (the "getting
  blocked" complaint is the test; conversion shipped, walk pending).
- THE LOOP "judgeable" call — starts the L2 daily-bar clock.
- Crosshair size/contrast taste-rule (sl-0042 pass shipped).
- b65 city walk (open since that intake).
- Rested ratification stack: M2 formal close, six ordinaries, all
  marathon-provisional loop/audio verdicts.
- CORE-50 render checklist pass + onboarding copy voice pass.
- Weekly GIF cadence (theirs to post; material exists every week).

Resolved recently so you don't re-open them: b76 street/joints look
APPROVED on the walk (2026-07-31); CORE-34 no-ability clear DONE;
boss pack intaken raw-by-ruling (wire only on natural need).

## §3 Open — engineering (when asked)

- ~~sl-0065 dev-map overlay~~ DONE 2026-08-01 (87bdc15, sync log
  sl-0069); the designer's first N-press on the overworld walk is
  the acceptance.
- Loop-routing onto the b77 harbor capital (scenario + gradient +
  proofs — the natural next content arc; talk-before-build).
- Intakes as deliveries land (runbook + per-pack pins + paired-TF
  doctrine). WF/TF/RF re-drops all follow the same transport.
- Ledger #16 replay character block (rides L2).

## §4 Session rituals (the gates)

Before every commit, per touched area:
- format: `python -m gdtoolkit.formatter <files>` (it REFLOWS —
  re-grep before editing formatted files).
- smoke: `godot_console --headless --path . --script tests/determinism/determinism_smoke.gd`.
- goldens: any sim/serialization change ⇒ bump SERIAL_VERSION
  (next bump is **14**), regenerate + verify ×10, say so in the
  commit.
- boot: `godot_console --headless --path . --quit-after 90` grep
  "arena ready|ERROR" (use "ERROR", not "SCRIPT ERROR").
- proofs: re-run canaries + every touched proof with CANONICAL SEEDS
  (table below); commit reports (`git add -f reports/...`).
  Unchanged scenarios must reproduce BYTE-IDENTICAL.
- the one-command gate: `pwsh tools/pretester_check.ps1` = everything
  incl. battery + export + lockdown. Exit 0 = ship-ready. It REFUSES
  to run beside another same-project Godot instance.
- godot binaries: `~/bin/godot_console.exe` (headless) / `godot.exe`
  (play, detached + front).
- hourslog start/stop/note around ALL work (PROD-01); check the tail
  for a dangling start; honest stops at seams.
- One approved decision = one commit; push BOTH repos at clean seams.
- Cross-repo events ⇒ sync-log entry planning-side (doc 18; no
  event, no entry). Gotcha #24 before appending.

### Canonical proof battery (all --speed=3.0; state 2026-08-01 —
### POLICY OF RECORD = REACTIVE; Warden 575; b65 flood 34641; the
### overworld pack is NOT in the battery — world_walk is b65)

| scenario | seeds | ticks | expected (reactive record) |
|---|---|---|---|
| canary_trivial | 1,2,3,4,5 | 3600 | PASS (MUST-PASS) |
| canary_undodgeable | 1,2,3 | 1800 | FAIL (MUST-FAIL, geometric 4-wall box) |
| proof_rusher | 1,2,3,4,5 | 3600 | PASS |
| proof_husk_archer | 1,2,3,4,5 | 3600 | PASS |
| proof_fanmaw | 203..207 | 3600 | PASS (stand-off) |
| proof_fanmaw_inside | 205..209 | 3600 | PASS (escape) |
| proof_ringer | 204..208 | 3600 | PASS |
| proof_leadshot | 206..210 | 3600 | PASS |
| proof_blightcaster (open-pocket 20,12/26,12) | 207..211 | 3600 | PASS |
| forest_walk → dodge_forest_walk_composition.json | 1,2,3 | 3600 | PASS |
| world_walk → dodge_world_walk_composition.json | 1,2,3 | 3600 | PASS (b65 pack) |
| first_contact → dodge_first_contact_composition.json | 1,2,3 | 3600 | PASS |
| second_contact → dodge_second_contact_composition.json | 10..14 | 3600 | PASS |
| proof_yw_p1 | 208..212 | 3600 | PASS (575: natural P1 pin) |
| proof_yw_p2 (t0 drop 230 → 60%) | 209..213 | 3600 | PASS |
| proof_yw_p3 (t0 drop 403 → 29.9%) | 210..214 | 3600 | PASS |
| proof_yw_full (schedule sums 575; t1207/t2413, kill t3301) | 211..215 | 3600 | PASS |
| proof_rusher / forest_walk / first_contact **[--policy=primary]** | as above | 3600 | **FAIL — primary-model baselines** (dodge_*_primary.json; a primary PASS = the sim changed) |
| lab_default + meet_blightcaster/leadshot/yard_warden | 1,2,3 | 3600 | PASS |
| loop_ring1/2/3 + proof_brk_site (Loop v1 gradient + boss site; ring pulls stay ≤2 pressures by layout) | 1,2,3 | 3600 | PASS |

Runner: `godot_console --headless --path . --script game/bots/bot_runner.gd -- --scenario=<id> --speed=3.0 --seeds=<list> --ticks=<n> [--out=res://reports/<name>.json] [--policy=primary|orbit|axis]`
(default policy = reactive; compositions need the explicit --out names).

## Hard-won gotchas (cost real debugging — read ALL of them)

1. **A silently hanging `--script` run = a PARSE ERROR.** Godot prints
   to stderr and the SceneTree idles FOREVER. Kill it, re-run unpiped
   at tiny scale. Then kill orphaned godot_console processes — NOTE
   the console wrapper spawns an engine child named plain "godot";
   process-kill filters must include both names.
2. GDScript type inference fails on duck-typed member access — hoist
   typed locals ALWAYS. `as` binds looser than `!=`. `sqrtf` doesn't
   exist (it's `sqrt`).
3. NEVER write .tres/.json/.gd/.cfg via PowerShell Set-Content (UTF-8
   BOM ⇒ Godot silently loads null). Use the Write tool or
   `[IO.File]::WriteAllText` (no BOM).
4. gdformat REFLOWS code — re-grep the actual text before Edit.
5. NO F-row keys. Current: O options, I interp, [ ] speed presets,
   -/= free step (dev-only now), G gif, R replay, T reset, M meter,
   H hitboxes, N map (dev-only, pack scenarios only), ` console
   (dev-only), Esc pause, Alt+Enter fullscreen.
6. Sim = pure core: no Nodes/clock/RNG; prev_pos is presentation-only;
   PackedArrays share storage — `.duplicate()` for snapshots.
7. When a proof fails: read the heatmap in the report JSON first;
   iterate the ARENA/LAYOUT or the POLICY, never weaken the proof.
8. Smoke micro-worlds use the LAB bitgrid (interior furniture) — keep
   scripted movement in the proven-open pocket (x 16–31, y 8–20).
9. The undodgeable canary is GEOMETRIC (4 emitters boxing spawn). If a
   smarter policy starts passing it, the canary must get harder;
   never ship with MUST-FAIL passing.
10. DodgeBot semantics: ANCHOR enemies = data-derived keep-out discs,
    excluded from the orbit centroid; hazard zones are crossable
    between pulses; the near-miss metric's negative hazard clearance
    is legal play. The verdict field is the evidence.
11. Windows console pipes can swallow a run's tail — check the report
    JSON on disk before re-running. **GATES READ EXIT CODES, NOT
    PROSE** (a silently-failing piped assert hid for a day).
12. **NEVER edit sim data while a battery runs** — each battery row is
    its own Godot process reading the working tree; mid-run edits
    split row provenance (got lucky once; don't).
13. **Headless boots CANNOT see render bugs.** The alt-tile y-sort v1
    dropped every roof and booted "clean" (placements counted, cells
    invisible). Designer eyes are the render gate — relaunch the game
    for them and ask before committing render work. (Also the
    concrete lesson: Godot alternative-tile creation at runtime
    dropped cells; per-building mini TileMapLayers was the fix.)
14. **Porosity diag pins are PER-PACK-DROP** (b65 = 44, overworld =
    60 at b77) — a drop that moves a number gets eyeballed (2-wide
    `ss` gateways = pass cells = fine) and re-pinned deliberately,
    never silently; type every changed cell (species / structure
    family / on-flood — the sl-0052 precedent). Walkable-unreachable
    cells are LEGAL under WYSIWYG.
15. The verdict console command enforces sources (feel rejects
    bot-proof); god/slow-mo stamp runs replay-dirty. Feel notes are
    PROVISIONAL until the two-tier rested pass.
16. Godot user data: `%APPDATA%\Godot\app_userdata\Wildshot Adventures\`
    — logs/session.jsonl (evidence stream), logs/terrain.jsonl (snag
    positions), gif_frames/ (G dumps; tools/gif.ps1 converts; the
    -Fps flag changes PLAYBACK not sampling — use direct ffmpeg
    `fps=` filters to shrink).
17. The designer's screen recordings land in
    `%LOCALAPPDATA%\Packages\Microsoft.ScreenSketch_*\TempState\Recordings\`
    — extract frames with ffmpeg and READ them; their footage
    outranks your theories.
18. **New importable resources (wav/ogg/png) need a
    `godot_console --headless --path . --import` pass** before the
    boot gate — "No loader found for resource" at boot means
    NOT-IMPORTED-YET, not missing. Commit the generated `.import`
    (and `.uid`) sidecars; the repo tracks them.
19. **The pretester's Godot guard is per-project** (godot_guard.ps1):
    provably-foreign instances don't block; same-PROJECT instances
    (the designer's game window) genuinely do — expect the designer
    to relaunch, ask for ~5 quiet minutes, or defer to session end.
    Running the gate steps individually (same commands, exit codes)
    is the recorded fallback when a foreign editor trips a check.
20. **Release-transport intakes (doc 18 §5)**: verify zipSha256 (=
    GitHub's computed asset digest) + manifest seal + per-file hashes
    + tag→sourceCommit — ALL LOCALLY, BEFORE the drop; re-hash after
    copy. Mismatch = incident + STOP. Big masters can stay in the
    release (it IS the archive) — commit only what ships; record
    conversions.
21. **Fresh-clone byte-exactness**: `.gitattributes` pins the
    hash-gated trees (assets/audio/reports/replay fixtures +
    `tileforge_packages/`) `-text`. The repo-wide `* -text` flip is
    DELIBERATELY not done — designer-tapped big-bang, not session
    hygiene.
22. **TileForge packages are PER-PIN (b76 paired intake)**: every
    world pack pins the exact package build it was resolved against;
    `world_builder.TILEFORGE_PACKAGES` is the registry. NEVER swap
    `res://tileforge/` in place — that breaks every committed pack
    pinning the old build (b65 = THE LOOP's town). Import new builds
    BESIDE it: raw drop under `assets/tileforge/`, consumed instance
    at `res://tileforge_packages/<id>/`, tres via
    `run_import.gd -- --package=<dir>` (the package's own shipped
    importer builds it), append the registry line; the export include
    filter (`tileforge_packages/*/*.json`) already covers manifests.
    A pin matching nothing refuses to render, loudly, by design.
23. **Delivery censuses can be WORLD-side numbers** — the pack
    differs by the world→pack seam (same class as pack flood ≠ world
    flood). Measure the PACK; pin any discrepancy by re-fetching the
    predecessor's immutable release and diffing (the b76 1466-vs-1461
    street-census lesson; also how the 47-joint render delta was
    independently reproduced).
24. **Planning sync-log appends race the live planning session**:
    verify the next free sl-#### id AT WRITE TIME (sl-0063 was taken
    mid-intake once), splice with the FILE'S OWN EOL convention (it
    has flipped LF↔CRLF between sessions), re-parse + verify after
    every append, and commit planning-side promptly. Entries are
    append-only; status flips are planning's sweep, not ours.

## Ledger + scope

Ledger (`notes/TECH_DEBT_LEDGER.md`): #16 is the only OPEN entry
(replay character block — rides L2); #1–#15 closed or Phase-C
deferred with recorded exits. The scope tripwire is the LOOP
MILESTONE (Gate-1 rewrite): loop-assembly work flows from designer
direction under talk-before-build; anything outside the loop bar's
needs is refused and ledgered or flagged to planning. Test scenes
accrete into game content where possible; the tester-build export
pipeline + lockdown stay a STANDING GATE regardless.
