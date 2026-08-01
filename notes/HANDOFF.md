# Session Handoff — rewritten 2026-08-01 (~15:40, pre-slice-build seam)

**COLD START — this handoff assumes NO prior context.** You may be a
fresh Claude instance under a DIFFERENT USER ACCOUNT (the designer
switches on usage limits; this handoff is written for exactly that).
Read the game repo's `CLAUDE.md` first (auto-loads; BINDING contract +
the authoritative milestone tracker — its milestone line is the full
append-only history this file deliberately does not repeat). This file
carries the current session state and the hard-won lessons the
contract doesn't.

**If you are the SLICE BUILD session: read planning
`docs/23-SLICE_BUILD_PLAN.md` FIRST, before any code** — it is the
build plan; S0 (the activation leash) is its opening work item. The
build GO is the designer's word; talk-before-build is LAW.

## §0 What this project is (60 seconds)

Wildshot Adventures: a solo-developed RotMG-inspired top-down realtime
bullet-hell ARPG in **Godot 4.6.2 (pinned), typed GDScript, custom
deterministic sim, no Godot physics in gameplay**. Serialization
SERIAL 14 (next bump 15); goldens current; all CI green.

Current phase: **THE SLICE ERA** (sl-0098, designer Tier 1, 2026-08-01:
"the world is the test"). **Slice v0.1 is the ONE milestone**: the
four-zone dusk overworld (b77) as a small scale of the full game —
living in the built world (leave a settlement, fight, loot, level
in-bracket, die to the CORE-43 city-fee death and walk back; the world
persists and refills, NO run framing) is what the docs/19 three-
sentence bar judges, over the designer's week, then 2–3 warm watched
first-touches. The b65 town loop RETIRED WITH HONOR as the mechanism
proof. Build order: chapter by chapter, **Green Country first**.

- **Game repo (you are here):** `C:\Users\headc\Documents\Wildshot-Adventures`,
  branch `main`. Implements; never reinterprets design.
- **Planning repo (design authority):**
  `C:\Users\headc\Documents\Wildshot_adventure_final_planning` — ONE
  branch, `claude/questionnaire-note-taking-9vl2sl` (no main; do not
  create one). Its `tools/sync_log.json` is the cross-repo logbook
  (doc 18, entries through sl-0099 as of this writing);
  `tools/ecosystem.lock.json` holds the pins.
- **Key planning docs for the slice:** `docs/23-SLICE_BUILD_PLAN.md`
  (THE build plan) · `docs/22-STAT_SYSTEM.md` (nine ruled blocks —
  mirrored game-side in `data/balance_frame.json`) · `docs/19`
  (the loop bar, re-aimed at the slice) · `docs/20` (world-content
  arc; step 3 = the importer, now docs/23 S0 work) · sl-0082/0087
  (the slice bill + brackets) · sl-0084 (asset-gap rulings).
- **The ecosystem map** (planning `docs/16-ECOSYSTEM_MAP.md`) names
  all seven repos and the hard cross-repo rules. **LANE RULE: game
  sessions NEVER execute other repos' plans/work.** Upstream needs
  become recorded asks. Reading other repos for context is fine;
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
  `tools/decision_deck.html` + register JSON). **PLAIN-LANGUAGE RULE:
  anything written FOR the designer uses zero repo jargon** — say
  what each option concretely does. They asked twice; it's law.
- Private by temperament — public surface stays game-forward. They
  licensed nudging the weekly-GIF cadence, one line at natural seams.
- When they ship a pack mid-task, integrating it beats finishing your
  plan. When they ask to SEE something, render and send it (4×
  nearest-neighbor reads well). When THEY show YOU something,
  treat it as primary evidence — read the frames.
- **When they state a want three times, build THAT** (sl-0078 lesson).

## §1 Where things stand (2026-08-01 evening — everything is staged for the slice)

**M0–M8 engineering complete; the acceptance triple landed today.**
The one-command ship gate `tools/pretester_check.ps1` runs ALL GREEN —
last full run 2026-08-01 ~15:07, **24.4 min at full strength: 23 fixed
steps + 33-row battery byte-identical + export both artifacts +
lockdown probe**. CI lint additionally runs the three pack validators
+ the balance calculator on every push.

**The slice ingredients, all proven and waiting for the GO:**

- **The world:** `wildshot-overworld-pack-dusk` **b77** (flood 46493,
  porosity pin 60, per-pin tileforge 9b8b2a2) with **THE FIT RULE**
  (sl-0078, SERIAL 14): props block by art-measured sub-cell discs,
  player terrain body = the sprite's feet (hurtbox 0.35 untouched),
  projectiles share the truth, enemies stay grid-walkers. **FORMALLY
  ACCEPTED by the designer's walk (sl-0097: "like playing another
  game, very good").** b65 (`small-cold-coastal`, pin 44) carries THE
  LOOP + world_walk battery rows.
- **The content plan:** `assets/wildshot-overworld-pack-dusk-content/`
  (sl-0093, REFERENCE ONLY — no importer): 127 placements (4 world
  bosses one per zone incl the hand-placed Green boss at 249,244;
  4 slice-marked dungeons; 112 encounter sites), 92 territories with
  placeholder rosters, 16 giver slots + 24 gather spots. B77 pairing
  mechanized in its fixed gate. **The hand-authored reference pass**
  (`notes/OVERWORLD_REFERENCE_PASS.md` + five `overworld_*` picker
  scenarios, battery rows 29–33) mapped it onto real defs — **and the
  designer PLAYED ALL FIVE and PASSED step 2 (sl-0099)**; the one
  finding (density too low) is ruled slice tuning: it is low BY
  CONSTRUCTION because **the sim has no activation leash** (the
  sl-0094 cold finding) — **docs/23 S0 (the leash) and the density
  retune are ONE work item.** The reference doc is the step-3
  importer-spec input.
- **The stat frame:** planning `docs/22` (nine designer-ruled blocks)
  mirrored in `data/balance_frame.json` + `tools/balance_calc.py`
  (23rd fixed step): THE damage formula
  `taken = max(attack − armor, ceil(attack × 0.2))`, weapon budgets
  12 × 1.4^t (frames ±10%), enemy hits 10/16/26/40 with armor at
  0.5×, trash at 4 reference hits, class curves + speed 100/105/110
  cap 115, XP 100/400/800/1400, six-pair grammar, unique one-break +
  chassis 70–90%. All five gates green, validator negative-tested.
  **The numbers exist before the code — the frame enters the sim AT
  SLICE BUILD.** Game-side conventions flagged `[P]` in the file.
- **The art, wiring hold LIFTED (sl-0098):**
  `assets/wildshot-icons-proto_0.1.0/` (470 16×16 glyphs, T1–T5,
  CORE-50 proof sheets) and `assets/wildshot-npc-slice-v1/` (32 NPCs,
  24×24 @1x — scale/layout IDENTICAL to the enemy pack, needs only a
  character-pack-v3 manifest adapter; sl-0092 report) **wire INTO the
  slice build**. The 13-boss pack (48×48) is THE boss roster
  (sl-0084); the enemy catalog (57 families) is live; NPC seat =
  assembler player-skins (sl-0084).
- **The mechanics base (proven by the retired b65 loop):** loot
  tiers/drops/pickup, XP/levels, carried-gold death cost + permadeath
  toggle, one-key retry, Law-8 recap — the run-lifecycle mechanisms
  are DONE and re-aim at the slice's world-persistent shape (CORE-43
  city-fee death, no run framing — see docs/23).
- **Everything else standing:** audio era live (RF cues + music duck),
  crosshair styles/size, dev map overlay (N), tester export pipeline +
  lockdown (STANDING GATE), feedback bundles + summary codes, CORE-50
  wiring verified both profiles.

## §2 Open — designer-side (do not nag; the deck + planning carry these)

- **THE SLICE BUILD GO WORD** — everything above is staged; docs/23
  is the plan; the GO and the per-chapter talk-before-build
  conversations are theirs.
- Crosshair styles on screen (preview:
  `reports/crosshair_styles_preview.png`) · dev map first N-press ·
  prop-thicket taste read (cover that sheds chasers, not shots) · b65
  city walk (feel menu, no longer a gate).
- Rested ratification stack: M2 formal close, six ordinaries,
  marathon-provisional loop/audio verdicts.
- CORE-50 render checklist pass + onboarding copy voice pass.
- Weekly GIF (fresh material everywhere: the accepted walk, the
  overworld scenarios, the boss site).
- Icon tool-source push from the other PC (sl-0083 insurance);
  deutan-sheet eyeball rides icon wiring.

## §3 Open — engineering (the slice, on the GO)

- **THE SLICE BUILD** per planning docs/23 — S0 (activation leash +
  density retune) opens it; chapter-by-chapter, Green Country first;
  wiring rounds for icons (Tier-0 surfaces) + NPCs (manifest adapter
  or third `assembler_library` instance) + the stat frame (SERIAL
  bump, goldens, full battery discipline — the paper numbers are the
  spec); the content-pack importer is docs/23 S0 work informed by
  `notes/OVERWORLD_REFERENCE_PASS.md`.
- Intakes as deliveries land (runbook + per-pack pins + paired-TF
  doctrine; passport + fixed-gate pattern for non-world packs).
- Ledger #16 (replay character block) + #17 (fit-rule round-1 scope:
  arena-def props still full-cell).

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
- the one-command gate: `pwsh tools/pretester_check.ps1` = 23 fixed
  steps + 33-row battery + export + lockdown (~20–25 min). Exit 0 =
  ship-ready. It REFUSES to run beside another same-project Godot
  instance (incl. the designer's game window — wait for it, never
  kill it; running steps individually, same commands + exit codes,
  is the recorded fallback).
- godot binaries: `~/bin/godot_console.exe` (headless) / `godot.exe`
  (play, detached + front).
- hourslog start/stop/note around ALL work (PROD-01); honest stops at
  seams (incl. waits on the designer's window).
- One approved decision = one commit; push BOTH repos at clean seams.
- Cross-repo events ⇒ sync-log entry planning-side (doc 18; no
  event, no entry). Gotcha #25 before appending.

### Canonical proof battery (all --speed=3.0; 33 rows; state 2026-08-01 —
### POLICY OF RECORD = REACTIVE; SERIAL 14; Warden 575; b65 flood 34641)

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
| world_walk → dodge_world_walk_composition.json | 1,2,3 | 3600 | PASS (b65, fit rule) |
| first_contact → dodge_first_contact_composition.json | 1,2,3 | 3600 | PASS |
| second_contact → dodge_second_contact_composition.json | 10..14 | 3600 | PASS |
| proof_yw_p1 | 208..212 | 3600 | PASS (575: natural P1 pin) |
| proof_yw_p2 (t0 drop 230 → 60%) | 209..213 | 3600 | PASS |
| proof_yw_p3 (t0 drop 403 → 29.9%) | 210..214 | 3600 | PASS |
| proof_yw_full (schedule sums 575; t1207/t2413, kill t3301) | 211..215 | 3600 | PASS |
| proof_rusher / first_contact **[--policy=primary]** | as above | 3600 | **FAIL — primary baselines** (a verdict MOVE = the sim changed) |
| forest_walk **[--policy=primary]** | 1,2,3 | 3600 | **PASS — re-pinned at sl-0078** (the deliberate-change signature) |
| lab_default + meet_blightcaster/leadshot/yard_warden | 1,2,3 | 3600 | PASS |
| loop_ring1/2/3 + proof_brk_site (b65 loop content, retired-with-honor but still proven; ring2 ringer at 199.5,126.5) | 1,2,3 | 3600 | PASS |
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
   (a whole-run heat blob in one spot = the bot PARKED somewhere);
   replay the run LIVE with a scratch forensics driver before
   theorizing; then iterate the ARENA/LAYOUT or the POLICY, never
   weaken the proof. Layout iterations on loop content must be
   MIRRORED in both the proof tres and data/scenarios/loop.tres.
8. Smoke micro-worlds use the LAB bitgrid — keep scripted movement in
   the proven-open pocket (x 16–31, y 8–20). The wall-slide floor
   derives from PlayerMove.TERRAIN_RADIUS (now 1.15625) — a retune
   moves the contract with it.
9. The undodgeable canary is GEOMETRIC (4 emitters boxing spawn). If a
   smarter policy starts passing it, the canary must get harder;
   never ship with MUST-FAIL passing.
10. DodgeBot semantics: ANCHOR enemies = data-derived keep-out discs,
    excluded from the orbit centroid; hazard zones are crossable
    between pulses; negative hazard clearance is legal play. The
    verdict field is the evidence.
11. Windows console pipes can swallow a run's tail — check the report
    JSON on disk before re-running. **GATES READ EXIT CODES, NOT
    PROSE.**
12. **NEVER edit sim data while a battery runs** — each battery row is
    its own Godot process reading the working tree. Same for docs
    during the pretester's export step (the artifacts pack project
    files).
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
    boot gate. Commit the generated `.import`/`.uid` sidecars — .uid
    files can materialize at the NEXT editor scan (sweep them at the
    following seam if one appears post-commit).
19. **The pretester's Godot guard is per-project** (godot_guard.ps1):
    provably-foreign instances don't block; same-PROJECT instances
    (the designer's game window) genuinely do — wait for them (clock
    honestly stopped), never kill their window. Running the gate
    steps individually (same commands, exit codes) is the recorded
    fallback.
20. **Release-transport intakes (doc 18 §5)**: verify zipSha256 (=
    GitHub's computed asset digest) + manifest seal + per-file hashes
    + tag→sourceCommit — ALL LOCALLY, BEFORE the drop; re-hash after
    copy. Mismatch = incident + STOP. Where a manifest ships its own
    hashes (assembler/world_filler publish gates), VERIFY them — the
    passport pins only what the manifest can't (itself).
21. **Fresh-clone byte-exactness**: `.gitattributes` pins the
    hash-gated trees (assets/audio/reports/replay fixtures +
    `tileforge_packages/`) `-text`. The repo-wide `* -text` flip is
    DELIBERATELY not done.
22. **`git add -f reports/` sweeps EVERYTHING untracked there** —
    stale repro_*.wsr from already-fixed failures ride in. Check
    `git diff --cached --name-status`, delete stale artifacts instead
    of committing them.
23. **TileForge packages are PER-PIN**: every world pack pins the
    exact package build it was resolved against;
    `world_builder.TILEFORGE_PACKAGES` is the registry. NEVER swap
    `res://tileforge/` in place. Import new builds BESIDE it.
24. **The fit rule's terrain has TWO truths (sl-0078)**: player +
    projectiles walk `walk_grid` + prop discs (art-true); enemies,
    floods, spawn checks, porosity, and every POSITIONING heuristic
    in the bot stay on the conservative `bitgrid`. Prop thickets are
    walkable-but-shot-exposed; the bot deliberately refuses to LIVE
    in them while escapes still thread them. Any new bot heuristic
    picks its grid deliberately. Kinematics with an empty discs dict
    is byte-identical legacy behavior.
25. **Planning sync-log appends race the live planning session**:
    verify the next free sl-#### id AT WRITE TIME (has happened
    repeatedly), splice with the FILE'S OWN EOL convention (currently
    CRLF, has flipped), re-parse + verify after every append, commit
    planning-side promptly, and NAME THE REAL ID in the commit
    message. Entries are append-only; status flips are planning's
    sweep, not ours.
26. **CI lint is a second gate nobody watches live** — the pretester
    does NOT run gdformat; an intake that adds a generated .gd tree
    must extend ci.yml's format-exemption filter (assets/,
    tileforge/, tileforge_packages/) or lint goes red silently.
    Never hand-format a consumed package tree — extend the filter.
    After any push, `gh run list` → the lint job concluding is the
    fast signal (the Windows jobs queue for hours behind it).
27. **Headless gates cannot see windowed-only teardown** — shutdown
    noise from DisplayServer-dependent paths never appears under
    --headless. The 4.6.2 cursor API leaks 2 Texture RIDs per final
    applied cursor at exit (engine retention, proven in a minimal
    project) — main releases the cursor at NOTIFICATION_EXIT_TREE;
    keep that handler. Method for any shutdown ERROR/RID-leak: sweep
    the gate commands solo with full stderr, characterize in a
    minimal project BEFORE touching code, fix lifecycle — never
    filter stderr.
28. **The sim has NO ACTIVATION LEASH (the sl-0094 cold finding —
    load-bearing for the slice):** every mobile enemy in a world
    scenario converges on the player from t0; "separate pulls" merge
    into one eventual fight, so authored density reads low and
    multi-pressure zones cannot be expressed honestly yet. The
    docs/23 S0 leash (territory semantics: maxActive /
    respawnPressure) fixes density and the importer's spawn surface
    IN ONE MOVE — build it before authoring dense zones. Two riders
    from the same finding: pairing viability is TERRAIN-CLASS-
    dependent (a lab-proven pairing can clip at fit-rule margins on
    world ground), and point-openness is NOT orbit-openness (cliff
    bands outside a sampled radius pinned the bot at margin 0.000) —
    site suitability for orbit-class fights needs a real clearance
    model.

## Ledger + scope

Ledger (`notes/TECH_DEBT_LEDGER.md`): OPEN = #16 (replay character
block) and #17 (fit-rule round-1 scope: arena-def props full-cell);
#1–#15 closed or deferred with recorded exits. The scope tripwire is
**SLICE V0.1** (sl-0098 — the world is the test; CLAUDE.md tripwire
superseded in place): slice work flows from designer direction under
talk-before-build via planning docs/23; anything outside the slice
bill's needs is refused and ledgered or flagged to planning. The
tester-build export pipeline + lockdown stay a STANDING GATE.
