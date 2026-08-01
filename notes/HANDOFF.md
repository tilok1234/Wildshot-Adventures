# Session Handoff — rewritten 2026-08-01 (~10:50, post-fit-rule seam)

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
SERIAL 14 (next bump 15); goldens current; all CI green.

Current phase: **the Loop era.** Gate 1 was REWRITTEN 2026-07-30
(sl-0023): the bar is an unguided complete run — spawn in town, fight
out through rising danger where loot drops and matters, reach the
first boss or die trying, death costs something real, retry pulls
immediately — that stays **fun for the designer playing daily**. Loop
v1 is BUILT and being PLAYED. Warm WATCHED first-touches get scheduled
only once the loop bar holds.

- **Game repo (you are here):** `C:\Users\headc\Documents\Wildshot-Adventures`,
  branch `main`. Implements; never reinterprets design.
- **Planning repo (design authority):**
  `C:\Users\headc\Documents\Wildshot_adventure_final_planning` — ONE
  branch, `claude/questionnaire-note-taking-9vl2sl` (no main; do not
  create one). Its `tools/sync_log.json` is the cross-repo logbook
  (doc 18, entries through sl-0096 as of this writing);
  `tools/ecosystem.lock.json` holds the pins.
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
- **When they state a want three times, build THAT** (sl-0078 lesson,
  planning owned it): the desire-line complaints were a MOVEMENT want
  twice mis-routed as placement fixes. The deliberate-act clause
  exists for exactly that moment.

## §1 Where things stand (2026-08-01, post-sl-0085 icon intake)

**M0–M8 engineering complete.** The one-command ship gate
`tools/pretester_check.ps1` runs ALL GREEN (23 fixed steps, 33-row
proof battery byte-identical against committed reports, export step
building + boot-checking BOTH artifacts, lockdown probe). Last full
run: **2026-08-01 ~15:07, ALL GREEN 24.4 min at full strength — 23
fixed steps + 33-row battery byte-identical (the five overworld
reference rows' first canonical run) + export + lockdown probe** —
the seam the sl-0094/0096 sessions deferred, run the moment the
designer closed their play window. The intake seams before it ran
`-SkipBattery` deliberately (zero sim change each).

- **THE FIT RULE (sl-0078, 2026-08-01, SERIAL 14) — the newest big
  thing:** "if the character sprite visibly fits through a gap, the
  character passes." Solid PROPS block by art-measured sub-cell discs
  (`game/arena/prop_colliders.gd` measures each cell's own sprite
  base at load — b77 opens 7,560 prop cells, b65 6,996); the player's
  terrain body = the ranger's FEET (`PlayerMove.TERRAIN_RADIUS =
  0.15625` — 10 px measured / 2 / 32, art-derived); projectiles share
  the same truth (one truth for walking and shooting). HURTBOX 0.35
  byte-untouched — dodge fairness intact. Enemies STAY grid-walkers
  (accepted round-1 asymmetry: the player threads prop fields, mobs
  go around). The cell bitgrid stays the CONSERVATIVE FLOOR — floods,
  porosity, spawn checks, upstream contracts all keep their meaning;
  b77 stays current; zero upstream work. One attach point in
  `ScenarioLoader.build_world` gives main/DodgeBot/soak/replay-verify
  identical collision by construction. ACCEPTANCE = the designer's
  walk along their own three red-line screenshots (game relaunched
  for them at the seam; mechanized shadow already proves both
  screenshot classes cross while legacy + enemy models stay blocked —
  `tests/pinch_probe/fit_rule_probe.gd`).
- **THE LOOP (v1, now SERIAL 14):** "THE LOOP" picker row — spawn in
  the b65 town, three proven danger rings westward, the BONE
  RELIQUARY KING at 105 tiles (Warden kit, 900 HP [T]). Loot tiers
  T1–T5 + armor + XP/levels + carried gold; death costs 25% [T]
  carried gold (permadeath toggle at creation = hardcore); one-key
  retry. EVERY number is [T] in `data/progression.tres` + the def
  drop tables. The ring-2 ringer spawn moved to (199.5,126.5) at the
  fit-rule seam (never-weaken layout iteration — it predated the
  thicket becoming walkable). L2 (daily-play tuning) starts when the
  designer calls the skeleton "judgeable". Ledger #16 rides L2.
- **Worlds, two committed lineages** (per-pack pins, doc-18 release
  transport, `notes/PACK_INTAKE_RUNBOOK.md`):
  `small-cold-coastal-pack-dusk` **b65** (THE LOOP's town +
  world_walk battery row; porosity pin 44; legacy M1 tileforge
  import) and `wildshot-overworld-pack-dusk` **b77** (Overworld Walk
  picker row; flood 46493, spawn 109,182; porosity pin 60; renders
  via the 9b8b2a2 package). Both carry the fit rule. b77 = the
  prop-walkability drop (carpet/canopy/solid classes, walk-under
  canopy proven at pixel level). Road joints render since b76.
- **TileForge is PER-PIN** (b76 paired drop):
  `world_builder.TILEFORGE_PACKAGES` = `res://tileforge/` (M1
  ae1eecb — b65-era packs) + 
  `res://tileforge_packages/dusk-9b8b2a2-seed103991/`. Packs resolve
  by pinned identity; mismatches refuse loudly. Gotcha #23 before
  touching anything tileforge-shaped.
- **Combat record:** REACTIVE is the DodgeBot policy of record.
  Battery = 28 rows, all on-matrix at the fit-rule re-baseline:
  canonical PASS rows PASS, MUST-FAIL canary FAILS, primary baselines
  = rusher FAIL / first_contact FAIL / **forest_walk PASS (re-pinned
  2026-08-01 — the fit rule freed the primary model's forest pockets;
  the flip is the deliberate-change signature)**. Warden 575 HP [T].
  The DodgeBot's threat projection is terrain-aware since sl-0078
  (shots die on walls/discs in the model too); its POSITIONING
  heuristics deliberately stay on the conservative bitgrid (gotcha
  #24).
- **Audio era live** (Resonance Forge v1): real cues on the
  data-driven map, 4-track music queue ducking −9 dB under threats,
  attack sounds, FIVE channels each with off. Eyes-closed evidence
  RECORDED (2026-08-01, deck sweep sl-0071): the seven classes
  distinguishable — `notes/AUDIO_CUE_MAP.md` slot carries it.
- **Player-facing QoL (2026-08-01):** crosshair STYLES + SIZE in
  options, both profiles (classic/dot/ring/cross × 9–15 px; classic
  at 11 = the ratified cursor byte-pinned; sl-0077). DEV-profile
  world map: `N` cycles corner minimap / fullscreen map on any
  pack-routed scenario incl THE LOOP — the pack's own minimap.png +
  player dot (sl-0065; throwaway-by-design, the PLAYER map stays
  Part II per doc 13 §3).
- **Icon pack v0.1 vendored UNWIRED (sl-0083 → sl-0085,
  2026-08-01):** the designer's icon-forge export — 470 16×16 glyphs,
  T1–T5 complete, CORE-50 proof sheets in-pack — sits raw at
  `assets/wildshot-icons-proto_0.1.0/` with a passport beside it
  (per-file sha256s; the manifest ships none) and a fixed gate
  (`tools/validate_icon_pack.py`, 20th step + CI row — verified
  green on a fresh Linux checkout) refusing byte drift. WIRING
  FIRES ONLY AFTER the Loop acceptance run (sl-0082 ruling; sl-0077
  Tier-0 sequencing note). Tool-source push owed from the
  designer's other PC (sl-0083 insurance line).
- **THE STAT FRAME ON PAPER (sl-0095 → sl-0096, 2026-08-01):**
  docs/22's nine designer-ruled blocks live as
  `data/balance_frame.json` (game-owned numbers [P] inside the
  ruled frame; planning owns the design — never amend docs/22
  game-side) + `tools/balance_calc.py` (23rd step + CI row): five
  gates all green — TTK/TTD bands, armor 0.5× everywhere with
  plateau flags clear, pattern fairness at every tier, 4 hits +
  ≤3-digit numbers, and the item validator (negative-tested). THE
  damage formula everywhere: `taken = max(attack − armor,
  ceil(attack × 0.2))`. NO sim contact — the frame enters at slice
  build; game-side conventions are flagged `[P]` in the file for
  planning's sweep.
- **Dusk content pack + THE OVERWORLD REFERENCE PASS (sl-0093 →
  sl-0094, 2026-08-01):** world_filler's first game-side artifact —
  REFERENCE ONLY (docs/20 step 1, no importer) at
  `assets/wildshot-overworld-pack-dusk-content/`; fixed gate
  `tools/validate_content_pack.py` (22nd step + CI row) pins bytes,
  the eight designer locks, and the b77 base pairing (loud refusal).
  The hand-authored pass: `notes/OVERWORLD_REFERENCE_PASS.md` (the
  step-3 importer-spec input) + FIVE proof-PASSED picker scenarios
  (`overworld_green/dry/wet/cold/green_boss`) on real pack site
  cells — battery rows 29–33. THE COLD FINDING is the big datum: no
  activation leash → multi-pull zone density needs territory
  semantics (the importer question, with numbers). **STEP 2 = the
  designer's feel session on those five rows.**
- **NPC slice roster v1 vendored UNWIRED (sl-0089 → sl-0092,
  2026-08-01):** 32 characters (13 named roles / 10 zone
  quest-givers / 9 ambient villagers) from the assembler's FIRST
  release — provenance proven end-to-end (tag == main tip; manifest
  `cleanPushedSource` independently confirmed). 24×24 @1x, 20×4
  sheets with REAL cast/death rows; scale treatment IDENTICAL to
  the enemy pack (sl-0092 report — wiring needs only a
  character-pack-v3 schema adapter). The manifest ships per-file
  sha256s (verified at intake, not generated); the passport pins
  the manifest; fixed gate `tools/validate_npc_pack.py` (21st step
  + CI row). WIRING AT SLICE BUILD, post-Loop-acceptance, alongside
  the icons.
- **Tester pipeline standing:** export.ps1 dev+tester zips, one-flag
  dev_tools lockdown (lint + artifact probe in the gate), onboarding
  screen (copy = placeholder, designer voice pending), feedback
  bundle + WS1- summary codes + evidence_report.py. CORE-50 wiring
  mechanized both profiles; the RENDER half of the checklist
  (designer eyes, tester build) is still unchecked
  (`notes/CORE50_RUNTIME_CHECKLIST.md`).

## §2 Open — designer-side (do not nag; the deck + planning carry these)

- **THE OVERWORLD FEEL SESSION** (docs/20 step 2, armed sl-0094):
  play the five `Overworld Ref:` picker rows — does directed
  placement feel right (the danger ramp, the boss spot at 249,244,
  the territory texture)? Their verdict decides whether step 3 (the
  importer) gets planned or the mapping/recipe iterates first.
- **THE RED-LINE WALK** = the sl-0078 acceptance: walk the three
  screenshot spots (desert lane, tree-band wall, sparse scatter) —
  pass wherever the sprite visibly fits, or the round reopens. This
  walk in practice also serves the b77 navigation-walk acceptance
  line (sl-0067) planning still carries.
- THE LOOP "judgeable" call — starts the L2 daily-bar clock.
- Crosshair styles on screen (four silhouettes + sizes; preview
  sheet: `reports/crosshair_styles_preview.png`).
- Dev map on screen (first N-press, overworld walk).
- Prop-thicket taste read (new tactical regime from the fit rule:
  thickets shed chasers but not shots — delicious or needs tuning,
  their call in play).
- b65 city walk (open since that intake).
- Rested ratification stack: M2 formal close, six ordinaries, all
  marathon-provisional loop/audio verdicts.
- CORE-50 render checklist pass + onboarding copy voice pass.
- Weekly GIF cadence (theirs to post; **fresh material: threading
  between trees where you never could** — the fit rule demos itself).

Resolved recently so you don't re-open them: crosshair fix RATIFIED +
closed (sl-0071 deck); Gate-1 rewrite RATIFIED; loop frame RATIFIED;
eyes-closed audio evidence captured + slot written; b76 street/joints
look APPROVED; sl-0070 pinch lever pick DISCHARGED by the sl-0078
ruling (the designer picked and it shipped).

## §3 Open — engineering (when asked)

- **Loop-routing onto the b77 harbor capital** (scenario + gradient +
  proofs — the natural next content arc; talk-before-build).
- Intakes as deliveries land (runbook + per-pack pins + paired-TF
  doctrine). WF/TF/RF re-drops follow the same transport. NOTE: WF's
  b78 spacing pass is PARKED UNRELEASED by the sl-0078 ruling — do
  not expect it; composition stays as authored.
- `tools/diag_pinch.py` is the committed pinch-census baseline —
  re-run it if anyone wants the fit-rule delta measured against the
  sl-0070 numbers (cell-level census semantics unchanged: it measures
  the conservative floor).
- Ledger #16 (replay character block — rides L2) and #17 (fit-rule
  round-1 scope: arena-def props still full-cell).
- Icon wiring (first surfaces per the deck's Tier-0 talk) — GATED on
  the Loop acceptance run; when it fires, sl-0083's watch-items ride
  along (abstract skill-node rows re-judged in the tree UI;
  ability-charm tiers eyeballed vs the in-pack deutan sheet).
- NPC wiring — same gate (slice build): a character-pack-v3 manifest
  adapter or a third `assembler_library` instance (scale/layout
  already match the enemy pack — sl-0092 report); watch-items ride
  along (named-vs-villager readability via overhead quest markers —
  the icon set has them; dark-outfit contrast on dusk ground is a
  one-field regen upstream).

## §4 Session rituals (the gates)

Before every commit, per touched area:
- format: `python -m gdtoolkit.formatter <files>` (it REFLOWS —
  re-grep before editing formatted files).
- smoke: `godot_console --headless --path . --script tests/determinism/determinism_smoke.gd`.
- goldens: any sim/serialization change ⇒ bump SERIAL_VERSION
  (next bump is **15**), regenerate + verify ×10, say so in the
  commit.
- boot: `godot_console --headless --path . --quit-after 90` grep
  "arena ready|ERROR" (use "ERROR", not "SCRIPT ERROR").
- proofs: re-run canaries + every touched proof with CANONICAL SEEDS
  (table below); commit reports (`git add -f reports/...`).
  Unchanged scenarios must reproduce BYTE-IDENTICAL.
- the one-command gate: `pwsh tools/pretester_check.ps1` = everything
  incl. battery + export + lockdown. Exit 0 = ship-ready. It REFUSES
  to run beside another same-project Godot instance (incl. the
  designer's game window — wait for it, never kill it; the recorded
  fallback for a foreign-editor trip is running the steps
  individually, same commands + exit codes).
- godot binaries: `~/bin/godot_console.exe` (headless) / `godot.exe`
  (play, detached + front).
- hourslog start/stop/note around ALL work (PROD-01); check the tail
  for a dangling start; honest stops at seams (incl. mid-session
  waits on the designer's game window — precedent 2026-08-01).
- One approved decision = one commit; push BOTH repos at clean seams.
- Cross-repo events ⇒ sync-log entry planning-side (doc 18; no
  event, no entry). Gotcha #25 before appending.

### Canonical proof battery (all --speed=3.0; state 2026-08-01 —
### POLICY OF RECORD = REACTIVE; SERIAL 14 fit-rule re-baseline;
### Warden 575; b65 flood 34641; world_walk is b65)

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
| world_walk → dodge_world_walk_composition.json | 1,2,3 | 3600 | PASS (b65 pack, fit rule active) |
| first_contact → dodge_first_contact_composition.json | 1,2,3 | 3600 | PASS |
| second_contact → dodge_second_contact_composition.json | 10..14 | 3600 | PASS |
| proof_yw_p1 | 208..212 | 3600 | PASS (575: natural P1 pin) |
| proof_yw_p2 (t0 drop 230 → 60%) | 209..213 | 3600 | PASS |
| proof_yw_p3 (t0 drop 403 → 29.9%) | 210..214 | 3600 | PASS |
| proof_yw_full (schedule sums 575; t1207/t2413, kill t3301) | 211..215 | 3600 | PASS |
| proof_rusher / first_contact **[--policy=primary]** | as above | 3600 | **FAIL — primary-model baselines** (a verdict MOVE = the sim changed) |
| forest_walk **[--policy=primary]** | 1,2,3 | 3600 | **PASS — re-pinned 2026-08-01** (sl-0078 fit rule freed the primary model's forest pockets; the flip IS the deliberate-change signature) |
| lab_default + meet_blightcaster/leadshot/yard_warden | 1,2,3 | 3600 | PASS |
| loop_ring1/2/3 + proof_brk_site (Loop v1 gradient + boss site; ring pulls ≤2 pressures by layout; ring2 ringer at 199.5,126.5 since sl-0078) | 1,2,3 | 3600 | PASS |
| overworld_green/dry/wet/cold/green_boss → dodge_overworld_*_composition.json (sl-0094 reference pass on b77 pack sites; cold = zone-heavy solo by the recorded finding) | 1,2,3 | 3600 | PASS |

Runner: `godot_console --headless --path . --script game/bots/bot_runner.gd -- --scenario=<id> --speed=3.0 --seeds=<list> --ticks=<n> [--out=res://reports/<name>.json] [--policy=primary|orbit|axis]`
(default policy = reactive; compositions need the explicit --out names).

## Hard-won gotchas (cost real debugging — read ALL of them)

1. **A silently hanging `--script` run = a PARSE ERROR.** Godot prints
   to stderr and the SceneTree idles FOREVER. Kill it, re-run unpiped
   at tiny scale. Then kill orphaned godot_console processes — NOTE
   the console wrapper spawns an engine child named plain "godot";
   process-kill filters must include both names. ALSO: main.gd cannot
   compile under `--script` runs (it reads the Config autoload) — a
   test that preloads main.gd hangs exactly this way (sl-0065 lesson).
2. GDScript type inference fails on duck-typed member access — hoist
   typed locals ALWAYS. `as` binds looser than `!=`. `sqrtf` doesn't
   exist (it's `sqrt`).
3. NEVER write .tres/.json/.gd/.cfg via PowerShell Set-Content (UTF-8
   BOM ⇒ Godot silently loads null). Use the Write tool or
   `[IO.File]::WriteAllText` (no BOM).
4. gdformat REFLOWS code — re-grep the actual text before Edit. It
   also WRAPS long lines, which can break single-line lint anchors
   (lockdown lint pins) — keep pinned lines short (sl-0065 lesson).
5. NO F-row keys. Current: O options, I interp, [ ] speed presets,
   -/= free step (dev-only), G gif, R replay, T reset, M meter,
   H hitboxes, N map (dev-only, pack scenarios only), ` console
   (dev-only), Esc pause, Alt+Enter fullscreen.
6. Sim = pure core: no Nodes/clock/RNG; prev_pos is presentation-only;
   PackedArrays share storage — `.duplicate()` for snapshots.
7. When a proof fails: read the heatmap in the report JSON first
   (a whole-run heat blob in one spot = the bot PARKED somewhere it
   shouldn't); replay the run LIVE with a scratch forensics driver
   (deterministic — compute_frame + world.step reproduces it) before
   theorizing; then iterate the ARENA/LAYOUT or the POLICY, never
   weaken the proof. Layout iterations on loop content must be
   MIRRORED in both the proof tres and data/scenarios/loop.tres.
8. Smoke micro-worlds use the LAB bitgrid (interior furniture) — keep
   scripted movement in the proven-open pocket (x 16–31, y 8–20). The
   wall-slide floor derives from PlayerMove.TERRAIN_RADIUS (now
   1.15625) — a retune moves the contract with it.
9. The undodgeable canary is GEOMETRIC (4 emitters boxing spawn). If a
   smarter policy starts passing it, the canary must get harder;
   never ship with MUST-FAIL passing.
10. DodgeBot semantics: ANCHOR enemies = data-derived keep-out discs,
    excluded from the orbit centroid; hazard zones are crossable
    between pulses; the near-miss metric's negative hazard clearance
    is legal play. The verdict field is the evidence.
11. Windows console pipes can swallow a run's tail — check the report
    JSON on disk before re-running. **GATES READ EXIT CODES, NOT
    PROSE.**
12. **NEVER edit sim data while a battery runs** — each battery row is
    its own Godot process reading the working tree; mid-run edits
    split row provenance. Same for docs during the pretester's export
    step (the artifacts pack project files).
13. **Headless boots CANNOT see render bugs.** Designer eyes are the
    render gate — or a windowed probe writing committed PNG evidence
    (canopy/dev-map/crosshair precedents); read the captures yourself
    before shipping.
14. **Porosity diag pins are PER-PACK-DROP** (b65 = 44, overworld =
    60 at b77) — a drop that moves a number gets eyeballed and
    re-pinned deliberately, never silently; type every changed cell.
    Walkable-unreachable cells are LEGAL under WYSIWYG.
15. The verdict console command enforces sources (feel rejects
    bot-proof); god/slow-mo stamp runs replay-dirty. Feel notes are
    PROVISIONAL until the two-tier rested pass.
16. Godot user data: `%APPDATA%\Godot\app_userdata\Wildshot Adventures\`
    — logs/session.jsonl (evidence stream), logs/terrain.jsonl,
    gif_frames/ (G dumps; tools/gif.ps1 converts; -Fps changes
    PLAYBACK not sampling — use ffmpeg `fps=` filters to shrink).
17. The designer's screen recordings land in
    `%LOCALAPPDATA%\Packages\Microsoft.ScreenSketch_*\TempState\Recordings\`
    — extract frames with ffmpeg and READ them; their footage
    outranks your theories. Their annotated screenshots land in
    planning `notes/evidence/`.
18. **New importable resources (wav/ogg/png) need a
    `godot_console --headless --path . --import` pass** before the
    boot gate. Commit the generated `.import`/`.uid` sidecars — note
    .uid files can materialize at the NEXT editor scan (sweep them at
    the following seam if one appears post-commit).
19. **The pretester's Godot guard is per-project** (godot_guard.ps1):
    provably-foreign instances don't block; same-PROJECT instances
    (the designer's game window) genuinely do — wait for them (clock
    honestly stopped), never kill their window. Running the gate
    steps individually (same commands, exit codes) is the recorded
    fallback when a foreign editor trips a check.
20. **Release-transport intakes (doc 18 §5)**: verify zipSha256 (=
    GitHub's computed asset digest) + manifest seal + per-file hashes
    + tag→sourceCommit — ALL LOCALLY, BEFORE the drop; re-hash after
    copy. Mismatch = incident + STOP.
21. **Fresh-clone byte-exactness**: `.gitattributes` pins the
    hash-gated trees (assets/audio/reports/replay fixtures +
    `tileforge_packages/`) `-text`. The repo-wide `* -text` flip is
    DELIBERATELY not done.
22. **`git add -f reports/` sweeps EVERYTHING untracked there** —
    stale repro_*.wsr from already-fixed failures and abandoned probe
    captures ride in. Check `git diff --cached --name-status`, verify
    mtimes, delete stale artifacts instead of committing them
    (2026-08-01 lesson: 16 stale files from three resolved eras).
23. **TileForge packages are PER-PIN**: every world pack pins the
    exact package build it was resolved against;
    `world_builder.TILEFORGE_PACKAGES` is the registry. NEVER swap
    `res://tileforge/` in place. Import new builds BESIDE it; a pin
    matching nothing refuses to render, loudly, by design.
24. **The fit rule's terrain has TWO truths (sl-0078)**: player +
    projectiles walk `walk_grid` + prop discs (art-true); enemies,
    floods, spawn checks, porosity, and every POSITIONING heuristic
    in the bot stay on the conservative `bitgrid`. Prop thickets are
    walkable-but-shot-exposed: they shed chasers but not shots, and
    the 0.35 hurtbox cannot dodge inside sprite-width gaps — the bot
    deliberately refuses to LIVE in them (wall_pen on bitgrid) while
    escapes still thread them. Any new bot heuristic must pick its
    grid deliberately. Kinematics/slide with an empty discs dict is
    byte-identical legacy behavior — enemy movement never changed.
25. **Planning sync-log appends race the live planning session**:
    verify the next free sl-#### id AT WRITE TIME (taken-mid-append
    has happened twice: sl-0063 and sl-0071 eras), splice with the
    FILE'S OWN EOL convention (currently CRLF, has flipped), re-parse
    + verify after every append, commit planning-side promptly, and
    NAME THE REAL ID in the commit message (a misnamed header needs a
    record-fix commit — d17fc25 precedent). Entries are append-only;
    status flips are planning's sweep, not ours.
26. **CI lint is a second gate nobody watches live** — the pretester
    does NOT run gdformat; an intake that adds a generated .gd tree
    must extend ci.yml's format-exemption filter (assets/,
    tileforge/, tileforge_packages/) or lint goes red silently (the
    b76/b77 seams left it red for a day; caught at the sl-0083 seam
    because the new icon CI row sat skipped behind the red step).
    Never hand-format a consumed package tree — extend the filter
    instead. After any push, `gh run list` → the lint job concluding
    is the fast signal (the Windows jobs queue for hours behind it).
27. **Headless gates cannot see windowed-only teardown** — shutdown
    noise from DisplayServer-dependent paths never appears under
    --headless; it lives in the WINDOWED closes (artifact boot
    checks, the designer's play window). The 4.6.2 cursor API leaks
    2 Texture RIDs per final applied cursor at exit — engine
    retention, proven in an empty minimal project on the pinned
    binary — so main releases the cursor at NOTIFICATION_EXIT_TREE;
    keep that handler. Method for any shutdown ERROR/RID-leak: sweep
    the gate commands solo with full stderr captured to type the
    emitter, characterize in a minimal project BEFORE touching code,
    then fix lifecycle (release engine-held resources pre-teardown)
    — never filter stderr. Remaining windowed-close stderr is the
    RealtimeDriver's designed slew telemetry only.

## Ledger + scope

Ledger (`notes/TECH_DEBT_LEDGER.md`): OPEN = #16 (replay character
block — rides L2) and #17 (fit-rule round-1 scope: arena-def props
full-cell); #1–#15 closed or Phase-C deferred with recorded exits.
The scope tripwire is the LOOP MILESTONE (Gate-1 rewrite):
loop-assembly work flows from designer direction under
talk-before-build; anything outside the loop bar's needs is refused
and ledgered or flagged to planning. Test scenes accrete into game
content where possible; the tester-build export pipeline + lockdown
stay a STANDING GATE regardless.
