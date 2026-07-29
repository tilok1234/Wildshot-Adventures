# Session Handoff — written 2026-07-29 (~03:30), end of the marathon seam

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
   procedure stands, porosity pin is per-drop. Audio pack may drop
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

### Canonical proof battery (all --speed=3.0; state 2026-07-29 —
### POLICY OF RECORD = REACTIVE; Warden 575; WYSIWYG dusk pack
### flood 34739)

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

## Open items ledger-side

Ledger (notes/TECH_DEBT_LEDGER.md): #1–#15 all closed or Phase-C
deferred as of 2026-07-29 — read it before adding anything new.
Scope tripwire stands: anything outside the SPEC-A bill is refused
and ledgered. Gate 1 must pass before building beyond the bill.
