# Session Handoff — written 2026-07-29 (~03:30); UPDATED 2026-07-30 (~04:15, the audio-era seam)

**COLD START — this handoff assumes NO prior context.** You may be a
fresh Claude instance under a DIFFERENT USER ACCOUNT (the designer
switches on usage limits; this handoff was written for exactly that).
Read the game repo's `CLAUDE.md` first (auto-loads; BINDING contract +
the authoritative milestone tracker) — this file carries the session
state and hard-won lessons the contract doesn't.

## §0 What this project is (60 seconds)

Wildshot Adventures: a solo-developed RotMG-inspired top-down realtime
bullet-hell ARPG in **Godot 4.6.2 (pinned), typed GDScript, custom
deterministic sim, no Godot physics in gameplay**. Current phase:
"Phase A" — a zero-reward combat-feel laboratory that outside testers
must enjoy for 20+ minutes on movement-dodging alone (Gate 1). Two
repos + a seven-repo ecosystem:

- **Game repo (you are here):** `C:\Users\headc\Documents\Wildshot-Adventures`,
  branch `main`. Implements; never reinterprets design. Serialization
  v12; goldens current; ALL CI green.
- **Planning repo (design authority):**
  `C:\Users\headc\Documents\Wildshot_adventure_final_planning` — ONE
  branch, `claude/questionnaire-note-taking-9vl2sl` (no main; do not
  create one). `git fetch` at session start and check for new
  `claude/*` branches (designer web sessions); fast-forward in only if
  they fork cleanly from the working tip.
- **The ecosystem map** (planning `docs/16-ECOSYSTEM_MAP.md`,
  designer-accepted) names all seven repos, their authority docs, and
  the cross-repo rules. Every repo's read-me-first doc carries a
  pointer block to it. **LANE RULE (designer, 2026-07-29, in the
  CLAUDE.md Authority section): game-repo sessions NEVER execute other
  repos' plans/work.** Upstream needs become recorded asks or a
  self-contained prompt the designer pastes to that repo's own agent —
  that relay pattern shipped two WorldForge arcs in one night. Reading
  other repos for context is fine; intaking their delivered packs is
  game-repo work.

## §0.5 Working with the designer

Solo dev, handle mmoabsurd (publicly **sarepat** — itch page
https://sarepat.itch.io/wildshot-adventures is LIVE with devlog + GIFs
#1/#2). Big nerd, goes hard. Works a 15:00–23:00 shift — **"rested"
keys on hours into THEIR waking day, never wall clock** (home at
midnight ≈ their 17:00; the two-tier verdict system below encodes
this). They iterate by PLAYING: ship, then relaunch the game for them
(`Start-Process` detached `~/bin/godot.exe --path .`; window opens
BEHIND — front it via user32 SetForegroundWindow; kill old godot
first). **Compact keyboard: NO F1–F12 keys, ever.** Standing authority
to commit and push both repos at every clean seam.

- **Two-tier verdicts (ruled 2026-07-29):** in-session designer calls
  count as decisions immediately; feel items additionally get one
  rested ratification. Marathons + dirty runs stay PROVISIONAL
  regardless.
- **THE DECISION DECK is the decision register**: the designer's own
  tool (planning `tools/decision_deck.html`, Desktop launcher .bat).
  They deal cards, decide, EXPORT; the JSON gets committed as planning
  `tools/decision_deck_register.json` and the session sweeps decisions
  into records + executes GOs. **PLAIN-LANGUAGE RULE: anything written
  FOR the designer (card text, ruling menus) uses zero repo jargon —
  say what each option concretely does.** They asked twice; it's law.
- They are private by temperament — public surface stays game-forward
  (posts = the game moving; never "build your brand" suggestions).
  They explicitly licensed nudging the tester-pipeline cadence (weekly
  GIF etc.), one line at natural seams.
- When they ship a pack mid-task, integrating it beats finishing your
  plan. When they ask to SEE something, render and send it (4x
  nearest-neighbor reads well). When THEY show YOU something (GIF,
  screenshot, video), treat it as primary evidence — this session's
  biggest diagnosis failure ended the moment their footage was read
  frame by frame.

## Where things stand (2026-07-29, the marathon seam)

**M0–M7 ALL ENGINEERING-COMPLETE AND CLOSED.** The one-command gate
`tools/pretester_check.ps1` runs ALL GREEN (~11 min: 11 fixed gates,
25-row proof battery byte-identical against committed reports, export
step building + boot-checking BOTH artifacts). Highlights of the
final state:

- **Reactive is the DodgeBot policy of record** (ruled; ledger #11
  closed). dodge_proof DEFAULTS to reactive; unsuffixed reports/ are
  the record; the three former wolf-pair FAILs PASS and stay watched
  as `[--policy=primary]` MUST-FAIL baseline rows (a primary PASS
  means the sim changed — investigate).
- **Yard Warden: 575 HP [T]** (ruled; ~13 s Longbolt intent — TTKBot
  measures 11.88 s, 21/21 pairs EXACT). Phase floors 66/33 pct;
  schedules re-derived (p2 drop 230, p3 drop 403, full-fight sums 575,
  transitions t1207/t2413, kill t3301); smoke pins tick-exact.
- **Export pipeline LIVE** (M7's last item): `tools/export.ps1` →
  dev + tester zips (feature tag `tester`; main.gd's ONE-FLAG
  `dev_tools` gate strips console/god/slow-mo/free-speed/bot+audit
  CLI; speed presets stay), build-id stamp on the tester HUD,
  worldforge packs LOOSE beside the exe (`resolve_src` fallback; pack
  drops swap into built zips), artifact boot check by EXIT CODE,
  butler command prepared (designer pushes; itch channel
  pipe-testers).
- **THE CITIES ARC (the night's saga, accepted in play —
  "hallelujah! finnaly works"):** cities are WYSIWYG-walkable. The
  designer's WF agent deleted the whole seal machinery upstream
  (collision = art outline minus declared pass cells; bidirectional
  gate; exceptions EMPTY) and re-exported dusk: flood 34739, 481
  one-wide inter-house strips walk, 7 enclosed courtyard islands are
  LEGAL walkable-unreachable. Game half: **ActorSortSpace** — actors +
  structure/props/fence/wall layers y-sort together at the ACTORS
  band; structures render as PER-BUILDING mini TileMapLayers anchored
  at base-row bottom edge (v1 via alternative tiles DROPPED ROOFS —
  see gotchas). Porosity diag re-pinned 44 (per-drop doctrine in the
  tool's docstring).
- **Decision Deck era:** 20 decisions burned 2026-07-29 (register
  committed). Recruitment sizing ruled (10–16, ≥4 strangers/cycle) —
  the Gate 1 calendar is UNBLOCKED. Hours log honestly backfilled
  (net +4h51 incl. a −3h55 sleep-gap correction). Docs 16/17
  accepted. world_filler: freeze RESOLVED upstream, format 1 FINAL,
  mainline **re-ruled 2026-07-30 = `main`** (the designer's approval
  line, promoted in the janitor session; planning
  notes/sessions/2026-07-30.md), proper clone at
  `Documents\world_filler\world_filler` (on `main`); game-side
  consumption stays POST-GATE-1 per planning docs/17.

## 2026-07-31 session close (~00:15) — b72 intake + crosshair — READ THIS FIRST

Mechanical night session (designer post-shift; zero feel/acceptance
verdicts recorded, by the ask's own terms). Two arcs, both pushed:

- **b72 OVERWORLD INTAKEN** (delivery sl-0035 → completion sl-0043;
  game commit dde3101): roads-only delta — every road (city lane,
  country highway, wilderness trail) is now a one-tile band line;
  path-2 census 1784→2166 (+382), trails 330→361; 0/1/2 acceptance
  holds with zero code change (normalized-recipe.json byte-identical —
  the delta is generator-side). IN-PLACE SUPERSEDE of b71 at the same
  path; **b71's lock pin RETIRED by per-pack call** (its release stays
  immutable archive). Full verify-before-drop chain (GitHub digest +
  zip + manifest + 8-file parity + tag→sourceCommit bbc10cdb) + staged
  blobs re-hashed byte-true. Addon flood recompute 45202 == manifest;
  spawn 109,182 unchanged. **Porosity re-pinned 60→64 deliberately**:
  +4 route cells = two two-wide landmark footprints (structure.ruin
  182-183,190; structure.stone_circle 249-250,116), both on-flood —
  reads as sl-0035's severed-landmarks fix; b65 keeps 44. **Cliff line
  re-confirmed** via the adapter-v4 replica CALIBRATED on b71 first
  (reproduced the recorded 1456 terraced-peak cells exactly): b72
  relief IDENTICAL ({169,820,467} by level), zero path-on-rock, zero
  walkable at terrace>=1. FULL pretester ALL GREEN 19.4 min (17 fixed
  steps + 28-row battery byte-identical incl world_walk + export +
  probe). Nothing routes to the overworld yet — loop-routing onto the
  harbor capital stays the natural next engineering arc (when asked).
- **CROSSHAIR SCALE PASS** (ask sl-0042 → completion sl-0044; game
  commit 0a7d69d): the hardware cursor never inherited the integer
  viewport stretch (11-physical-px speck; designer standing
  complaint). main.gd now scales it nearest-neighbor by the live
  integer content scale, kit hotspot re-centered, re-applied on
  size_changed. Render-only; pack assets untouched (manifest-hashed);
  lint/boot/smoke green, smoke hashes unchanged. **GAME RELAUNCHED
  WINDOWED AND FRONTED** (engine log clean, THE LOOP scenario up) —
  the designer's taste-rule on final size/contrast is the open item;
  if contrast still fails after sizing, record an upstream kit ask,
  never a pack-asset hand-edit.

Planning-side state (uncommitted BY DESIGN — the live planning session
sweeps and commits): ecosystem.lock game pin b71→b72 (pin note carries
the retirement call); sync log entries sl-0043 (b72 intake, hashes
verbatim, true-UTC ts) + sl-0044 (crosshair completion). The sl-0035 +
sl-0042 status flips are planning's sweep, not ours. Hours clock
STOPPED at close. Append-script lesson recorded: PowerShell
Measure-Object -Maximum returns a DOUBLE — ':d4' formatting throws
non-terminating and execution continues; cast [int] before -f, and
always re-parse + verify after a JSON append (the verify caught it).

## 2026-07-30 session close (~13:30) — the loop's first day (superseded above)

**THE LOOP IS ALIVE AND HAS BEEN PLAYED.** The overnight arc, in five
acts: (1) dusk **b65** + **Resonance Forge audio v1** intaken via the
new release transport (its first real exercises — music queue +
duck-under-threats, real cues, attack sounds, FIVE audio channels
each with off); (2) comments box + per-project godot guard +
`.gitattributes` byte-exactness pins; (3) **GATE 1 REWRITTEN**
(sl-0023): stranger recruitment retired WITH CAUSE, the Loop
milestone adopted as forward scope; (4) **LOOP V1 BUILT** the same
night (ask sl-0025, completion sl-0033; details in the dawn block
below): SERIAL 13 loot/XP/gold/armor, persistent character with the
permadeath toggle at creation, death costs + one-key retry, drops
rendered, the hand-authored gradient, the BONE RELIQUARY KING, four
new proofs, full pretester ALL GREEN 13.9 min; (5) **b71 overworld
intaken** (sl-0034→sl-0036): first STYLED pack (path 0/1/2 accepted,
zero code change), cliff line confirmed game-side by replicating the
adapter's terrace math at the source commit, porosity pinned 60,
lands BESIDE b65 — nothing routes to it yet. Then **FIRST REAL
PLAY**: the designer ran the loop repeatedly, died to the King twice,
and ruled in-play (Tier 1, natural-testing): "world becoming alive",
"a little hard — pay attention and you can do it", retry pull
holding. Two boss-run GIFs cut at three weights; devlog cuts
delivered (GIF #3 material, posting is theirs).

STATE: game repo pushed clean (through dc3680d); planning's lock +
sync log carry everything through sl-0036 uncommitted BY DESIGN
(planning commits its own files and sweeps sl-0034's flip); hours
clock STOPPED at session close; all designer verdicts are
marathon-provisional per two-tier.

NEXT — designer-side (do not nag): daily loop play (the L2 bar clock
starts on their "judgeable" word); the tree-placement arc rides the
planning/WF lane (they are routing it themselves); GIF #3 post; [T]
tuning one-liners whenever a number forms an opinion
(data/progression.tres + def drop tables = the whole dial surface).
NEXT — engineering (when asked): route THE LOOP onto the b71
overworld (scenario line + fresh gradient authoring + proofs — the
harbor capital is the better town); ledger #16 (replay character
block) lands naturally with L2; WF re-export intakes as the tree arc
ships (runbook + release transport + per-drop pins all stand).

## 2026-07-30 dawn seam: LOOP V1 IS BUILT (superseded above; detail stands)

Ask sl-0025 executed same night (docs/19 §3, commits 86459d1→f7b0be6
+ records): **the run exists** — "THE LOOP" picker row: spawn in the
b65 town, walk west through three proven danger rings (wolf/archer
pairs → fanmaw/ringer country → blightcaster/leadshot outlands), the
BONE RELIQUARY KING at 105 tiles (Warden kit, 900 HP [T], 48px sheet,
guaranteed T5 + gold + 35% Reliquary Coil placeholder unique). Loot
drops and matters (T1–T5 per-frame tiers + armor + abilities,
upgrades-only walk-over pickup), kill XP levels the lean sheet, gold
carries, death costs 25% [T] carried gold (normal; the permadeath
toggle at creation is hardcore's home — file deleted) and retry is
ONE key. SERIAL 13; goldens regenerated; 4 new battery rows (28) +
loop_test in the fixed gates; ledger #16 opened (replay character
block). EVERY number is [T] in data/progression.tres + the def drop
tables — the designer tunes in play; L2 (the daily-play bar clock)
starts when they call the skeleton judgeable. DESIGNER-EYES pending:
creation screen, drops/HUD, and THE RUN.

## 2026-07-30 night seam (superseded above; context below)

Two release-transport intakes landed (the doc 18 §5 flow's first real
exercises, both hash-verified end to end BEFORE the drop): **dusk b65**
(flood 34641, porosity pin 44 unchanged — route cells byte-identical;
battery byte-identical incl world_walk; game commit 5cb0e3b; sync log
sl-0020) and **Resonance Forge audio v1** (178 files hash-true; commits
ec12575+aaa7250+86873a5; sync log sl-0022). AUDIO IS LIVE: 4-track
music queue-on-loop ducking −9 dB under threat cues; real cues from
the pack's critical set; attack sounds (player+enemy fire, 13
variations round-robin, ATTACK_STARTED hook — zero sim change); FIVE
channels (Master/Sfx/KeyThreats/Music/AttackSfx) each with off.
COMMENTS BOX built (bundle comments.txt; typing suppresses hotkeys +
gameplay input; box-owned pause). M8's last answer-gated engineering
item is DONE.
Designer verdicts so far (chat, Tier 1, marathon-provisional): music
"sounds good", corrected attack build "sounds great"; NATURAL-TESTING
mode chosen — b65 city walk + formal ear pass accumulate in play, do
not nag. **GATE 1 REWRITTEN 2026-07-30** (ask sl-0023, planning
593cc27; game CLAUDE.md digest carries the provenance): stranger
recruitment, the itch testers-channel push, and stranger-aimed
onboarding polish are RETIRED WITH CAUSE — fresh eyes are
nonrenewable and failed recruitment reads as verdict when it is only
silence. NEXT TARGET = THE LOOP MILESTONE: an unguided complete run
(b65 town → out → rising danger with loot that matters → first boss
or die trying; death costs something real; immediate retry pull);
exit = fun for the DESIGNER playing daily for a week; 2–3 warm
WATCHED first-touches only at the bar. The export pipeline stays a
STANDING GATE — clean audio-era zips CUT + probed same night
(builds/wildshot-322066c-*.zip, 58.7 MB tester). ENGINEERING QUEUE:
(1) LOOP ASSEMBLY per designer direction (talk-before-build — the
bar card is staged for their words; expect a design conversation
first: loot model, death cost, boss choice, danger gradient — none
spec'd yet, docs/08+12 truth-up owed planning-side); (2) GIF #3
material = the town with music; (3) intakes as they land; (4)
optional pretester ALL-GREEN capstone any quiet ~13 min (every
component passed individually tonight).

## Next work (updated 2026-07-29 ~14:20, M8 early-start session)

**M8 ENGINEERING EXHAUSTED (2026-07-29 afternoon+evening,
designer-sanctioned early-start; CLAUDE.md milestone graf has full
detail):** lockdown sweep DONE (lint + artifact probe in the gate);
feedback return path DONE (session lifecycle evidence + bundle zip
row + WS1- summary code + tools/decode_summary_code.py); onboarding
screen DONE (once-per-run tester overlay, lowest-speed loadout
selector, loadout evidence line; ALL COPY PLACEHOLDER); CORE-50
runtime verification DONE (--verify=core50-low|high, both pretester
steps; notes/CORE50_RUNTIME_CHECKLIST.md maps the designer-eyes
render half); evidence reader DONE (tools/evidence_report.py =
bundle → Gate-1 facts; re-engagement DEFINITION stays a planning §6
lock). Gate = 17 fixed steps + 25-row battery + export + probe, ALL
GREEN 12.6 min.

Engineering-side remaining, in rough order:

1. **M8 leftovers (all designer-input-gated):** comments box (on the
   now-vs-later answer — lean yes), onboarding copy voice pass
   (designer words), CORE-50 checklist render pass (designer eyes,
   tester build). Then designer-side M8: laptop pass, rested
   per-pattern human pass, itch publish, recruitment.
2. **DESIGNER TASTE ANSWERS OPEN (asked ~13:25, Tier 1 one-liners):**
   bundle destination (Desktop default until said otherwise),
   comments box now-vs-later, summary-code paste destination
   (Discord/itch/both). DESIGNER-EYES on next launch: onboarding
   layout, bundle row + toast + Explorer reveal (render gate).
3. **Intakes as they land:** BOSS PACK INTAKEN 2026-07-29 (13 bosses
   48x48 raw at assets/assembler-boss-pack/, validator
   tools/validate_boss_pack.py; RULED keep-raw, wire on natural
   need; re-drops revalidate with the tool). WF composition passes
   are ACTIVE designer territory (~30 settlement compositions:
   chicken coops, harbors...) — new world drops expected; runbook
   procedure stands, porosity pin is per-drop. Dusk b65 INTAKEN
   2026-07-30 via the RELEASE TRANSPORT (doc 18 §5: fetch GitHub
   release by tag, hash-verify vs the notes before the drop): flood
   34641, pin 44 unchanged, battery byte-identical incl world_walk;
   designer city walk pending = acceptance. RESONANCE FORGE V1
   INTAKEN 2026-07-30 same night (second release-transport intake):
   real cues + 4-track music queue live, Music channel + duck + the
   comments box built on three Tier 1 rulings — full story in
   notes/AUDIO_CUE_MAP.md; the deferred audio verdicts now run
   against REAL audio. Audio pack may drop
   any day (Resonance Forge); cue swap is zero-code by design, music
   playback is the one new piece.
4. **Gate 1 calendar** — recruitment is sized, builds ship, channels
   are live. Scheduling is the designer's; the pipeline is ready.

Designer-side open (do not nag): rested feel cards (M2 formal close,
six-ordinaries ratification), eight-holds round-12 docks verdict
(WF-side), Discord link for the record.
AUDIO IS DEFERRED BY RULING: both audio verdicts (eyes-closed + feel)
wait for the Resonance Forge integration — placeholder cues will not
be separately ratified (notes/AUDIO_CUE_MAP.md carries the slot).

## Session rituals (the gates)

Before every commit, per touched area:
- format: `python -m gdtoolkit.formatter <files>` (it REFLOWS —
  re-grep before editing formatted files).
- smoke: `godot_console --headless --path . --script tests/determinism/determinism_smoke.gd`
  (mechanized contracts for all six ordinaries + the Warden at 575).
- goldens: any sim/serialization change ⇒ bump SERIAL_VERSION,
  regenerate + verify, say so in the commit. Next bump is 13.
- boot: `godot_console --headless --path . --quit-after 90` grep
  "arena ready|ERROR" (use "ERROR", not "SCRIPT ERROR").
- proofs: re-run canaries + every touched proof with CANONICAL SEEDS
  (table below); commit reports (`git add -f reports/*.json`).
  Unchanged scenarios must reproduce BYTE-IDENTICAL.
- the one-command gate: `pwsh tools/pretester_check.ps1` = everything
  incl. the battery + export step. Exit 0 = ship-ready. It REFUSES to
  run beside any other Godot instance — close the game first.
- godot binaries: `~/bin/godot_console.exe` (headless) / `godot.exe`
  (play, detached + front).
- hourslog start/stop/note around ALL work (PROD-01). Check the tail
  for a dangling start. Honest stops at seams — the backfill
  precedent (2026-07-29) exists because stops were missed.
- One approved decision = one commit; push BOTH repos at clean seams.

### Canonical proof battery (all --speed=3.0; state 2026-07-30 —
### POLICY OF RECORD = REACTIVE; Warden 575; WYSIWYG dusk pack
### b65 flood 34641)

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
| world_walk → dodge_world_walk_composition.json | 1,2,3 | 3600 | PASS (WYSIWYG pack) |
| first_contact → dodge_first_contact_composition.json | 1,2,3 | 3600 | PASS |
| second_contact → dodge_second_contact_composition.json | 10..14 | 3600 | PASS |
| proof_yw_p1 | 208..212 | 3600 | PASS (575: natural P1 pin) |
| proof_yw_p2 (t0 drop 230 → 60%) | 209..213 | 3600 | PASS |
| proof_yw_p3 (t0 drop 403 → 29.9%) | 210..214 | 3600 | PASS |
| proof_yw_full (schedule sums 575; t1207/t2413, kill t3301) | 211..215 | 3600 | PASS |
| proof_rusher / forest_walk / first_contact **[--policy=primary]** | as above | 3600 | **FAIL — primary-model baselines** (dodge_*_primary.json; a primary PASS = the sim changed) |
| lab_default + meet_blightcaster/leadshot/yard_warden | 1,2,3 | 3600 | PASS |
| loop_ring1/2/3 + proof_brk_site (Loop v1 gradient + boss site, docs/19; ring pulls stay ≤2 pressures by layout) | 1,2,3 | 3600 | PASS |

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
   H hitboxes, ` console (dev-only), Esc pause, Alt+Enter fullscreen.
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
14. **The porosity diag pin (44) is per-pack-drop** — a new drop that
    moves the number gets eyeballed (2-wide `ss` gateways = pass
    cells = fine) and re-pinned deliberately, never silently. 7
    walkable-unreachable courtyard islands are LEGAL under WYSIWYG.
15. The verdict console command enforces sources (feel rejects
    bot-proof); god/slow-mo stamp runs replay-dirty. Feel notes are
    PROVISIONAL until the two-tier rested pass.
16. Godot user data: `%APPDATA%\Godot\app_userdata\Wildshot Adventures\`
    — logs/session.jsonl (evidence stream), logs/terrain.jsonl (snag
    positions — THE instrument that finally located the cities
    problem from the designer's actual walk), gif_frames/ (G dumps;
    tools/gif.ps1 converts; the -Fps flag changes PLAYBACK not
    sampling — use direct ffmpeg `fps=` filters to shrink).
17. The designer's screen recordings land in
    `%LOCALAPPDATA%\Packages\Microsoft.ScreenSketch_*\TempState\Recordings\`
    — extract frames with ffmpeg and READ them; their footage
    outranks your theories.
18. **New importable resources (wav/ogg/png) need a
    `godot_console --headless --path . --import` pass** before the
    boot gate — "No loader found for resource" at boot means
    NOT-IMPORTED-YET, not missing. Commit the generated `.import`
    (and `.uid`) sidecars; the repo tracks them.
19. **The pretester's machine-wide Godot guard vs reality:** the
    `.godot/` race is PER-PROJECT. An editor open on ANOTHER project
    trips the blanket guard but cannot race this repo — running the
    gate steps individually (same commands, exit codes) is the
    legitimate fallback, recorded in the commit. Same-PROJECT
    instances (the designer's game window) genuinely block; use a
    background waiter on process exit, and expect the designer to
    relaunch — ask for ~5 quiet minutes, or defer to session end.
20. **Release-transport intakes (doc 18 §5)**: verify zipSha256 vs
    notes+sidecar, manifest seal, per-file hashes, sourceCommit vs
    tag target — ALL LOCALLY, BEFORE the drop; re-hash after copy.
    Mismatch = incident + STOP. Big masters can stay in the release
    (it IS the archive) — commit only what ships; record conversions.
21. **Fresh-clone byte-exactness**: `.gitattributes` pins the
    hash-gated trees (assets/audio/reports/replay fixtures) `-text`.
    The repo-wide `* -text` flip is DELIBERATELY not done — it would
    show the entire working tree modified (CRLF working copies vs LF
    blobs) — that is a designer-tapped big-bang, not session hygiene.

## Open items ledger-side

Ledger (notes/TECH_DEBT_LEDGER.md): #1–#15 all closed or Phase-C
deferred as of 2026-07-29 — read it before adding anything new.
Scope tripwire stands: anything outside the SPEC-A bill is refused
and ledgered. Gate 1 must pass before building beyond the bill.
