# Session Handoff — rewritten 2026-08-01 (~23:40, post-S0 + sl-0102 seam)

**COLD START — this handoff assumes NO prior context.** Read the game
repo's `CLAUDE.md` first (auto-loads; BINDING contract + the
authoritative milestone tracker — its milestone tail is the full
append-only history this file deliberately does not repeat). This file
carries the current session state and the hard-won lessons the
contract doesn't. The account-switch note from the previous handoff
stands: nothing repo-side gates on the Claude account; git identity
and gh auth are machine-local; this file + `CLAUDE.md` + planning
`docs/23` are the complete context carrier.

**If you are the S1 session: DO NOT START S1 WITHOUT ITS OWN
ROUTING.** S0 is complete and stopped exactly at the routed stop line
(sl-0100/0101). S1 (Green Country chapter content) begins only when
planning routes it on the designer's word. Until then: intakes, feel
one-liners, tuning batches, and whatever the designer asks.

## §0 What this project is (60 seconds)

Wildshot Adventures: a solo-developed RotMG-inspired top-down realtime
bullet-hell ARPG in **Godot 4.6.2 (pinned), typed GDScript, custom
deterministic sim, no Godot physics in gameplay**. Serialization
SERIAL 17 (next bump 18); goldens current; all CI green.

Current phase: **THE SLICE ERA** (sl-0098: the world is the test).
**Slice v0.1 is the ONE milestone**: the four-zone dusk overworld
(b77) as a small scale of the full game — living in the built world
(leave a settlement, fight, loot, level in-bracket, die to the
CORE-43 city-fee death and walk back; the world persists and refills,
NO run framing) is what the docs/19 three-sentence bar judges, over
the designer's week, then 2–3 warm watched first-touches. Build
order: chapter by chapter, **Green Country first** (planning
docs/23).

**S0 FOUNDATIONS ARE COMPLETE (2026-08-01, sl-0100 executed as four
sealed seams — game 695f898→4acca00→8c0ce7a→5ad9dbb; gate ALL GREEN
42.4 min; the full seam-by-seam record is planning
`notes/sessions/2026-08-01-slice-s0.md`):**
1. **The stat frame is in the sim** (SERIAL 15): docs/22 blocks 1–8
   on the class-backed lane (`PlayerState.class_id` 0/1/2 =
   sword/staff/bow; −1 = the legacy lane, byte-identical by
   construction); THE damage formula integer-exact in THE damage
   path; `data/balance_frame.json` = the single tuning source
   (drift-refusing loader); stepped XP to cap 30; three class weapon
   frames on the json tier tables; the 115 movement HARD CAP inside
   player_move.gd. Profile v2: class chosen at creation; the class
   frame replaces the lab trio; v1 profiles read as no-character.
2. **The living world is plumbed** (SERIAL 16): the content pack's
   territories + placements read DIRECTLY as spawn tables
   (`game/arena/content_importer.gd` — 193 sites: 92 territories +
   97 encounters + 4 world bosses on the Warden kit; 11 dungeon
   bindings recorded for chapter work); activation leash (wake ≤22 /
   sleep >30, damage-persistent fold-by-id — no kill events on
   fold); away-only depth-keyed respawn (green 10800 → cold 5400
   ticks [T], bosses ×3 — nothing pops in faces, structurally);
   tether 12 in enemy_step (beyond every class weapon reach ~9.4 —
   no shoot-from-safety exists).
3. **Overworld death is live** (SERIAL 17; CORE-43, no run framing):
   the [T] 25% carried-gold slice lands IN-SIM at the death tick;
   settlement respawn on a 240-tick timer or the ability key while
   dead (replay-honest — the key is meaningless to a corpse); full
   refill; persistent worlds keep RUNNING through deaths (recap
   unpaused, hides on respawn; RecapTracker re-arms per death);
   dead-in-place stands for labs, proofs, hardcore.
4. **NPCs + icons wired** (view-only): 32 looks stationed (zone
   givers at content-pack giver cells walkability-nudged; the crowd
   on a golden-angle spiral at the capital) inside the y-sorted
   ActorSortSpace — render evidence committed
   (reports/npc_render_audit_capital.png); the icon atlas consumed
   (res://icons/, `ui/icon_atlas.gd` cuts by id); weapon tier glyph
   top-right + class emblems on the creation screen.

**SPEED ANCHOR RE-RULED same night (sl-0102/0103 — the block-6 feel
reservation fired after the designer's first S0 walk):** stat 100 ==
**3.6 t/s** [T] — sword 3.60 (the CORE-53 floor) / staff 3.78 / bow
3.96 (== the old lab feel) / cap 4.14. ONE constant
(`StatFrame.SPEED_TILES_PER_100`); both proof lanes re-baselined at
3.6/4.14. **The GIF recorder is START-TO-FINISH now** (098a679): G
starts, G stops, frames stream to disk, any length — the last-10-s
ring is retired.

- **Game repo (you are here):** `C:\Users\headc\Documents\Wildshot-Adventures`,
  branch `main`. Implements; never reinterprets design.
- **Planning repo (design authority):**
  `C:\Users\headc\Documents\Wildshot_adventure_final_planning` — ONE
  branch, `claude/questionnaire-note-taking-9vl2sl` (no main; do not
  create one). Its `tools/sync_log.json` is the cross-repo logbook
  (entries through sl-0103 as of this writing);
  `tools/ecosystem.lock.json` holds the pins. A planning-side sweep
  agent commits between game sessions — always `git pull --ff-only`
  before planning writes.
- **Key planning docs for the slice:** `docs/23-SLICE_BUILD_PLAN.md`
  (THE build plan; S1's recipe is its §Build-order) ·
  `docs/22-STAT_SYSTEM.md` (the nine ruled blocks — mirrored
  game-side in `data/balance_frame.json`) · `docs/19` (the bar) ·
  sl-0082/0087 (the slice bill + brackets).
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
spawns an engine child named plain "godot" — but NEVER kill a window
they are actively playing). **Compact keyboard: NO F1–F12 keys,
ever.** Standing authority to commit and push both repos at every
clean seam.

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
  nearest-neighbor reads well). When THEY show YOU something, treat
  it as primary evidence — read the frames.
- **When they state a want three times, build THAT** (sl-0078 law —
  re-proven S0 night by the GIF recorder: "not the whole gif" ×3
  meant the RING DESIGN was wrong, not the conversion).
- **Their feel words name SYSTEMS, not necessarily the one you're
  holding**: "recordings are a tad slow" turned out to be the CLASS
  WALK SPEED feel note the block-6 ruling reserved for — check which
  lever they're actually touching before diagnosing yours.
- GIF flow they use: G starts, G again stops (any length; ● REC
  badge while on); `tools/gif.ps1 -FramesDir <dump>` converts; full
  recordings are BIG (~80 MB/30 s) — cut posting-size versions with
  ffmpeg fps/scale filters on request.

## §1 Where things stand (2026-08-01 ~23:40)

**M0–M8 + S0 engineering complete.** The one-command ship gate
`tools/pretester_check.ps1` last ran ALL GREEN 2026-08-01 ~22:40
(**42.4 min: 26 fixed steps + the 67-run two-lane battery
byte-identical + export both artifacts + lockdown probe**) — that was
at the RETIRED 3.0/3.45 speeds. The sl-0102 re-anchor then
re-baselined the battery lanes at 3.6/4.14 (65 runs + solo confirms,
all on-matrix vs the updated table) with fixed steps + lint + boot
green individually; **the export step + lockdown probe were NOT
re-run after the re-anchor (the designer's play window held the
machine) — that deferred-gate debt rides the NEXT exclusive seam**
(the recorded fallback; artifacts on disk are from the 22:40 gate =
old speeds).

The designer is LIVING IN THE SLICE (restarted 23:18 on the new
speeds + new recorder; the bar clock is their daily play). Artifact
verification from the S0 gate: balance_frame.json rides the export;
the content pack ships loose beside the exe.

## §2 Open — designer-side (do not nag; the deck + planning carry these)

- **THE S1 GO WORD** — Green Country chapter content (docs/23 recipe)
  starts only on its own routing.
- Slice feel one-liners as they play (density / pack sizes / respawn
  pace / anything) — BATCH tuning numbers into single gate runs.
- New surfaces to judge when they feel like it: the NPC crowd
  (sl-0089 watch-items: named-vs-villager blur, dark-outfit dusk
  contrast), class creation screen + emblems, weapon tier glyph.
- Weekly GIF (deferred by their word tonight; fresh material
  everywhere — the living world, the crowd, class kits).
- Standing: rested ratification stack (M2 formal close, six
  ordinaries, marathon-provisional verdicts), CORE-50 render
  checklist pass, onboarding copy voice, icon tool-source push from
  the other PC, crosshair styles on screen, b65 city walk (feel
  menu).

## §3 Open — engineering

- **S1 awaits routing** (never start it unrouted). S0 left the
  ground ready: sites live, stat frame under everything, death
  honest, NPCs standing where quests will hang.
- **Deferred-gate debt:** export.ps1 + lockdown probe at the next
  exclusive seam (post-sl-0102 artifacts; one pretester
  -SkipBattery run covers it, or the full gate if a sim change
  lands first).
- Density tuning is DATA now (authored pack sizes × the leash [T]
  radii in site_step.gd) — expect it inside S1's feel rounds.
- Intakes as deliveries land (runbook + per-pack pins + paired-TF
  doctrine; passport + fixed-gate pattern for non-world packs; NPC/
  icon re-drops re-run their import_*.py + the wiring test).
- Ledger: OPEN = #16 (replay character block — class/ring joined the
  gap at S0) and #17 (fit-rule round-1 scope: arena-def props
  full-cell). #7 amended (recorder reworked; async readback stays
  the improvement path).

## §4 Session rituals (the gates)

Before every commit, per touched area:
- format: `python -m gdtoolkit.formatter <files>` (it REFLOWS —
  re-grep before editing formatted files).
- smoke: `godot_console --headless --path . --script tests/determinism/determinism_smoke.gd`.
- goldens: any sim/serialization change ⇒ bump SERIAL_VERSION
  (next bump is **18**), regenerate + verify ×10, say so in the
  commit.
- boot: `godot_console --headless --path . --quit-after 90` grep
  "arena ready|ERROR" (use "ERROR", not "SCRIPT ERROR").
- proofs: re-run canaries + every touched proof with CANONICAL SEEDS
  (table below), BOTH LANES; commit reports
  (`git add -f reports/...`). Unchanged scenarios must reproduce
  BYTE-IDENTICAL.
- the one-command gate: `pwsh tools/pretester_check.ps1` = 27 fixed
  steps + the 69-run two-lane battery (36 floor rows + 33 cap runs;
  pinned FAILs are expectations) + export + lockdown.
  Exit 0 = ship-ready. It REFUSES to run beside another same-project
  Godot instance (incl. the designer's game window — wait for it,
  never kill it; running steps individually, same commands + exit
  codes, is the recorded fallback).
- godot binaries: `~/bin/godot_console.exe` (headless) / `godot.exe`
  (play, detached + front).
- hourslog start/stop/note around ALL work (PROD-01); honest stops at
  seams (incl. waits on the designer's window).
- One approved decision = one commit; push BOTH repos at clean seams.
- Cross-repo events ⇒ sync-log entry planning-side (doc 18; no
  event, no entry). Gotcha #25 before appending.

### Canonical proof battery (state 2026-08-01 post-sl-0102 — POLICY
### OF RECORD = REACTIVE; SERIAL 17; Warden 575; b65 flood 34641).
### TWO LANES (docs/22 block 6: proofs at floor AND cap FOREVER),
### SPEEDS PER THE sl-0102 RE-ANCHOR (stat 100 == 3.6 t/s [T]):
### floor lane --speed=3.6 (the CORE-53 floor = sword), cap lane
### --speed=4.14 (the 115 hard cap; reports keep the dodge_*_cap115
### names — 115 is the STAT). Primary rows stay floor-only
### watch-baselines: rusher PASS (re-pinned at 3.6 — was FAIL at the
### retired 3.0), forest_walk PASS, first_contact FAIL. PINNED CAP
### FAIL: meet_leadshot at 4.14 (seed-invariant 1-hit graze @t647,
### near 0.013, repros committed — the INTERCEPT dart aims where you
### are GOING; constant full commitment is perfectly predictable; the
### floor row = the CORE-33 mandate PASSES; humans tap-modulate out).
### The OLD 3.45 ringer-cap pin retired WITH the anchor (both ringer
### lanes PASS now — the S0 session file holds that story + the
### half-duty fix-and-revert lesson). All pins WATCHED: a verdict
### move = the sim (or policy) changed under us.

| scenario | seeds | ticks | expected (reactive record, floor/cap) |
|---|---|---|---|
| canary_trivial | 1,2,3,4,5 | 3600 | PASS / PASS (MUST-PASS) |
| canary_undodgeable | 1,2,3 | 1800 | FAIL / FAIL (MUST-FAIL, geometric 4-wall box) |
| proof_rusher | 1,2,3,4,5 | 3600 | PASS / PASS |
| proof_husk_archer | 1,2,3,4,5 | 3600 | PASS / PASS |
| proof_fanmaw | 203..207 | 3600 | PASS / PASS (stand-off) |
| proof_fanmaw_inside | 205..209 | 3600 | PASS / PASS (escape) |
| proof_ringer | 204..208 | 3600 | PASS / PASS (old 3.45 cap pin retired by sl-0102) |
| proof_leadshot | 206..210 | 3600 | PASS / PASS |
| proof_blightcaster (open-pocket 20,12/26,12) | 207..211 | 3600 | PASS / PASS |
| forest_walk → dodge_forest_walk_composition.json | 1,2,3 | 3600 | PASS / PASS |
| world_walk → dodge_world_walk_composition.json | 1,2,3 | 3600 | PASS / PASS (b65, fit rule) |
| first_contact → dodge_first_contact_composition.json | 1,2,3 | 3600 | PASS / PASS |
| second_contact → dodge_second_contact_composition.json | 10..14 | 3600 | PASS / PASS |
| proof_yw_p1/p2/p3/full (575 schedule: t0 drops 230/403; full sums 575) | 208..215 ladders | 3600 | PASS / PASS ×4 |
| proof_rusher **[primary]** | 1..5 | 3600 | **PASS — re-pinned at the 3.6 floor (sl-0102)** |
| forest_walk **[primary]** | 1,2,3 | 3600 | PASS (re-pinned at sl-0078) |
| first_contact **[primary]** | 1,2,3 | 3600 | **FAIL — the standing primary baseline** |
| lab_default + meet_blightcaster/leadshot/yard_warden | 1,2,3 | 3600 | PASS / PASS — EXCEPT **meet_leadshot cap = PINNED FAIL** (see lane note) |
| loop_ring1/2/3 + proof_brk_site (b65 loop content, retired-with-honor but still proven) | 1,2,3 | 3600 | PASS / PASS |
| overworld_green/dry/wet/cold/green_boss → dodge_overworld_*_composition.json | 1,2,3 | 3600 | PASS / PASS |
| proof_slice_leash (S0 seam 2: the isolated camp at seed 98,225 — spawn INSIDE its envelope, exactly one site wakes; RE-BASELINED at S1 seam 1: the re-table made it the ranged Green set at density 1.5, margins 1.975 → ~0.120, honest) | 1,2,3 | 3600 | PASS / PASS |
| proof_green_camp (S1 seam 1: the most isolated MIXED green territory, seed 185,244 — the full melee+ranged re-table at density, near ~0.90) | 1,2,3 | 3600 | PASS / PASS |
| proof_green_ranged (S1 seam 1: the most isolated green territory of all, seed 108,138, prowler-only → the PURE ranged set: anchors+flanker+aimed, near ~0.121) | 1,2,3 | 3600 | PASS / PASS |

Runner: `godot_console --headless --path . --script game/bots/bot_runner.gd -- --scenario=<id> --speed=3.6 --seeds=<list> --ticks=<n> [--out=res://reports/<name>.json] [--policy=primary|orbit|axis]`
(default policy = reactive; compositions need the explicit --out
names; cap runs use --speed=4.14 + an explicit --out=..._cap115.json).

## Hard-won gotchas (cost real debugging — read ALL of them)

1. **A silently hanging `--script` run = a PARSE ERROR.** Godot prints
   to stderr and the SceneTree idles FOREVER. Kill it, re-run unpiped
   at tiny scale. Then kill orphaned godot_console processes — NOTE
   the console wrapper spawns an engine child named plain "godot";
   process-kill filters must include both names. ALSO: main.gd cannot
   compile under `--script` runs (it reads the Config autoload) — a
   test that preloads main.gd hangs exactly this way (sl-0065 lesson).
2. GDScript type inference fails on duck-typed member access — hoist
   typed locals ALWAYS (bit again at S0 seam 2: `e.pos.distance_to`
   on a duck-typed loop var). `as` binds looser than `!=`. `sqrtf`
   doesn't exist (it's `sqrt`).
3. NEVER write .tres/.json/.gd/.cfg via PowerShell Set-Content (UTF-8
   BOM ⇒ Godot silently loads null). Use the Write tool or
   `[IO.File]::WriteAllText` (no BOM).
4. gdformat REFLOWS code — re-grep the actual text before Edit. It
   also WRAPS long lines, which can break single-line lint anchors
   (lockdown lint pins) — keep pinned lines short (sl-0065 lesson).
5. NO F-row keys. Current: O options, I interp, [ ] speed presets,
   -/= free step (dev-only), G gif (start/stop, start-to-finish),
   R replay, T reset, M meter, H hitboxes, N map (dev-only, pack
   scenarios only), ` console (dev-only), Esc pause, Alt+Enter
   fullscreen, Space = ability AND respawn-now while dead
   (persistent worlds).
6. Sim = pure core: no Nodes/clock/RNG; prev_pos is presentation-only;
   PackedArrays share storage — `.duplicate()` for snapshots.
7. When a proof fails: read the heatmap in the report JSON first
   (a whole-run heat blob in one spot = the bot PARKED somewhere);
   replay the run LIVE with a scratch forensics driver before
   theorizing; then iterate the ARENA/LAYOUT or the POLICY, never
   weaken the proof. Layout iterations on loop content must be
   MIRRORED in both the proof tres and data/scenarios/loop.tres.
   ADDENDUM (S0 cap-lane lesson): GLOBAL policy scoring knobs are
   whack-a-mole across 30+ rows — the half-duty rescue fixed the
   ringer and broke first_contact; prefer PINNING a lattice-class
   FAIL with cause over policy surgery mid-seam.
8. Smoke micro-worlds use the LAB bitgrid — keep scripted movement in
   the proven-open pocket (x 16–31, y 8–20). The wall-slide floor
   derives from PlayerMove.TERRAIN_RADIUS (now 1.15625) — a retune
   moves the contract with it.
9. The undodgeable canary is GEOMETRIC (4 emitters boxing spawn). If a
   smarter policy starts passing it, the canary must get harder;
   never ship with MUST-FAIL passing. (Verified failing at 3.6 AND
   4.14.)
10. DodgeBot semantics: ANCHOR enemies = data-derived keep-out discs,
    excluded from the orbit centroid; hazard zones are crossable
    between pulses; negative hazard clearance is legal play. The
    verdict field is the evidence.
11. Windows console pipes can swallow a run's tail — check the report
    JSON on disk before re-running. **GATES READ EXIT CODES, NOT
    PROSE.** (Re-proven at sl-0102: a battery "mismatch" was a
    swallowed verdict line; the disk report was PASS.)
12. **NEVER edit sim data while a battery runs** — each battery row is
    its own Godot process reading the working tree. Same for docs
    during the pretester's export step (the artifacts pack project
    files).
13. **Headless boots CANNOT see render bugs.** Designer eyes are the
    render gate — or a windowed probe writing committed PNG evidence
    (canopy/dev-map/crosshair/npc precedents); read the captures
    yourself before shipping.
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
    PLAYBACK not sampling — use ffmpeg `fps=` filters to shrink),
    replays/, character.json (v2: class-backed; v1 reads as
    no-character).
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
    fallback. Batteries CAN run beside their play window in practice
    (read-only of the tree; adjudicate any flake by gotcha 11 + a
    solo re-run) — but goldens-verify and the export step are the
    flake-prone ones; defer those to exclusive seams.
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
    of committing them. RETIRED-PIN evidence gets `git rm`'d in the
    retiring commit (the sl-0102 ringer/rusher sweep).
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
28. **The activation leash EXISTS since S0 seam 2** (site_step.gd:
    wake 22 / sleep 30 / tether 12, away-only respawn). The
    HISTORICAL finding (sl-0094): without it every mobile enemy
    converged from t0 — that is why the reference-pass scenarios
    were authored sparse. Two riders STILL standing: pairing
    viability is TERRAIN-CLASS-dependent (a lab-proven pairing can
    clip at fit-rule margins on world ground), and point-openness is
    NOT orbit-openness (cliff bands outside a sampled radius pinned
    the bot at margin 0.000) — site suitability for orbit-class
    fights still needs a real clearance model (upstream wf
    conversation material).
29. **Gate scripts: the EXIT CODE must cover EVERY verdict.** A
    seam-1 re-sweep script gated only its floor spots — a cap row
    flipped PASS→FAIL mid-output under exit 0 and the tail read
    green. Batteries print per-row; scripts COMPARE per-row and
    fail loudly on any mismatch (the final sweep pattern).
30. **Never spawn a scenario player ON or NEAR a site cell** — the
    leash wakes the site and the wake ring materializes the pack on
    their head (9 hits @t21 the first time). Probe candidate spawns
    against site positions; the capital spawn is verified CLEAN
    (zero sites within 26). Related: a passive bot outside the
    TETHER pins melee packs at the line (vacuous near −1 "pass") —
    proofs must fight INSIDE the envelope; players cannot exploit
    this (tether 12 > max weapon reach ~9.4).
31. **The full-speed lattice class is real and speed-specific**: a
    bot committed to constant full speed loses to (a) razor
    radial-gap threading (the retired 3.45 ringer pin) and (b)
    INTERCEPT prediction (the live 4.14 meet_leadshot pin — the dart
    aims where you're GOING and constant commitment is perfectly
    predictable). Humans tap-modulate out of both. Every new anchor
    re-rolls which rows it bites — that's WHY both lanes re-run on
    any speed change, and why pins are per-anchor.

## Ledger + scope

Ledger (`notes/TECH_DEBT_LEDGER.md`): OPEN = #16 (replay character
block — class/ring joined the gap at S0) and #17 (fit-rule round-1
scope: arena-def props still full-cell); #7 amended (recorder
reworked start-to-finish; async readback stays the improvement
path); #1–#15 closed or deferred with recorded exits. The scope
tripwire is **SLICE V0.1** (sl-0098 — the world is the test): slice
work flows from designer direction under talk-before-build via
planning docs/23; anything outside the slice bill's needs is refused
and ledgered or flagged to planning. **S1 does not start without its
own routing.** The tester-build export pipeline + lockdown stay a
STANDING GATE (current debt: re-export + probe at the next exclusive
seam, post-sl-0102).
