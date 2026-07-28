# Session Handoff — written 2026-07-28 (~03:00), end of the M6 roster session

**COLD START — this handoff assumes NO prior context.** You may be a
fresh Claude instance (possibly under a different user account — the
designer switched accounts on usage limits mid-M6) with no memory of
any earlier session.

## §0 What this project is (60 seconds)

Wildshot Adventures: a solo-developed RotMG-inspired top-down realtime
bullet-hell ARPG in **Godot 4.6.2 (pinned), typed GDScript, custom
deterministic sim, no Godot physics in gameplay**. Current phase:
"Phase A" — a zero-reward combat-feel laboratory that outside testers
must enjoy for 20+ minutes on movement-dodging alone (Gate 1). Two
repos:

- **Game repo (you are here):** `C:\Users\headc\Documents\Wildshot-Adventures`
  — implements. Its `CLAUDE.md` is a BINDING contract (auto-loads):
  design constraints digest, no-RNG-in-sim rule, milestone tracker
  (the authoritative "where are we"). Never reinterpret design here;
  conflicts get flagged to the planning repo.
- **Planning repo (design authority):**
  `C:\Users\headc\Documents\Wildshot_adventure_final_planning` — ONE
  branch only, `claude/questionnaire-note-taking-9vl2sl` (no main —
  do not create one). Other `claude/*` branches appear when the
  designer runs web sessions: `git fetch` at session start, check for
  new ones, fast-forward in only if they fork cleanly from the working
  tip (a stale fully-absorbed branch needs no action — one existed
  2026-07-28 and was correctly ignored). Key docs: `docs/12` (build
  plan; §3.4 as amended), `docs/14` (assembler packs), `docs/15`
  (WorldForge), `notes/sessions/2026-07-27.md` + `2026-07-28.md` (the
  full record of the marathon and the M6 roster session — read for
  any "why"). One approved decision = one commit + push, BOTH repos.

## §0.5 Working with the designer

Solo dev, handle mmoabsurd. Big nerd, goes hard, sometimes overnight;
their plan has a **fresh-hands rule**: feel verdicts count only from
rested day-start sessions — tired-session notes are PROVISIONAL by
rule; honor it kindly, don't nag. They iterate by PLAYING: ship, then
relaunch the game for them (`Start-Process` detached
`~/bin/godot.exe --path .`; the window opens BEHIND — bring it to
front via user32 SetForegroundWindow; kill the old godot process
first or two builds run at once). Short casual messages ("ye this
feels much better", "he does exactly that!") = provisional positives.
They build their own asset tools and ship packs as versioned drops —
tool repos (8-bit sprite assembler, TileForge, WorldForge at
`Documents\WorldForge`) are READ-ONLY unless separately scoped.
**Compact keyboard: NO F1–F12 keys, ever.** You have standing
authority to commit and push both repos at every clean seam. Give
honest opinions with numbers; they change their mind on evidence —
and they'll change YOURS the same way. When they ship a pack
mid-task, integrating it beats finishing your plan. When they ask to
SEE something before ruling (they did, for the M6 actor sheets),
render it and send it — 4x nearest-neighbor upscales read well.

## Where things stand (one paragraph)

M0–M5 complete and accepted. **M6 is past its halfway point: THE
ORDINARY §3.4 ROSTER IS COMPLETE — all six enemies live, each with
its passing 3.0 t/s ability-off proof.** Rusher (wolf, slash arc),
Husk Archer (skeleton, aimed), Fanmaw (carniplant, 5-shot fan ANCHOR,
pattern 13), Ringer (eyemonster, 12-shot radial slow chaser, 14),
Leadshot (bandit sniper, INTERCEPT-aimed FLANKER, 12), Blightcaster
(cultist, lingering ground-hazard caster, keep-range, 15). Law-4
telegraph ordering complete and monotone: 10<12<30<36<40<45.
Serialization is at **v11** (v10 added ActorState.vel — real applied
post-slide velocity, written every tick, prev_pos stays
presentation-only and BANNED for sim reads; v11 added hazard
linger/pulse fields). All four M6 actor-sheet mappings are
DESIGNER-CONFIRMED (2026-07-28: bandit:sniper / carniplant:snapvine /
eyemonster:watcher / cultist:acolyte); polished sheet drops are
expected later in the SAME family:variant slots (importer re-run =
zero-code swap). Three arenas: lab (detailed), Forest Walk, World
Walk (real WorldForge dusk pack). Picker rows: first_contact,
forest_walk, lab_default, meet_blightcaster, meet_leadshot,
second_contact, world_walk. All CI gates green; goldens current at
v11.

## Next work: rest of M6 (docs/12 §4)

1. **Yard Warden elite (§3.5)** — the next code task, biggest
   authoring lift of M6: PhaseList resource (ordered phases swapping
   policy + emitter sets on HP%), 400 HP [T], three phases: P1
   (100–66%) aimed triples + fan; P2 (66–33%) rotating radial +
   ground hazards; P3 (33–0%) predictive volleys + fan + chase
   bursts. Peak hostile projectiles ≤ 300 (budgets.tres
   hostile_elite_max) with a density-meter proof. **Per-phase
   DodgeBot proofs at 3.0 ability-off PLUS a full-fight proof across
   phase transitions.** Building blocks all exist now: aimed/fan/
   radial patterns, INTERCEPT aim, hazard casting, multi-slot
   emitters (EmitterSlot array — multi-slot never yet exercised;
   _ready_slot picks the first open+in-range slot). PhaseList needs:
   a resource type, an elite def referencing it, sim-side phase
   swap on HP% thresholds (serialized phase index → SERIAL 12 +
   golden regen, deliberate), and probably a heavy-orb elite marker
   (sprite reserved in the projectile pack). Expect the elite to
   need a new proof-harness thought: the bot must FIGHT it... no —
   proofs are movement-only; the full-fight proof needs the elite's
   HP driven down. §2.11/§3.5 intent: per-phase proofs run each
   phase's pattern set (spawn the elite pinned at a phase via
   scenario/test rig — a phase-force debug hook or per-phase defs);
   the full-fight proof crosses transitions — that needs damage, so
   either a scripted damage schedule in the harness (console command
   exists for damage? god exists; direct hp set would be a new
   sim-legal test hook) or accept the fight at full length with a
   fire-enabled... NO: proofs are ability-off AND fire-off by
   construction. Design the transition proof deliberately: a test
   hook that steps the elite's hp down on a tick schedule inside the
   harness (sim command, replay-visible) is the honest route. Flag
   the design in the planning log before building.
2. **EffectLibrary pass (ledger #9)**: Nova cast-flash ring sprite,
   effect-density/opacity scaler (cosmetic/friendly channels ONLY,
   hostile clamped — §2.6), flash-reduction mode. Ledger #14 (zone
   burning-state visual) belongs to this pass.
3. **Nine-row acceptance** at stress density + audio cue map +
   placeholder WAVs (Law 7; sourcing is designer-taste territory) +
   CORE-34 full no-ability clear. Ledger #10 (slash borrows fang)
   gets designer ruling here.

## Session rituals (the gates)

Before every commit, per touched area:
- format: `python -m gdtoolkit.formatter <files>` (gdformat not on
  PATH). It REFLOWS — re-grep before editing formatted files.
- smoke: `godot_console --headless --path . --script tests/determinism/determinism_smoke.gd`
  — now carries mechanized contracts for ALL SIX enemies (exact
  telegraph leads, periods, volley sizes, policy behaviors, the
  Leadshot intercept-beats-mover witness, the Blightcaster
  reactive-walker escape witness).
- goldens: any sim/serialization change ⇒ bump SERIAL_VERSION,
  regenerate (`tests/replay_fixtures/record_goldens.gd`), verify
  (`verify_replays.gd`), say so in the commit — deliberate, never a
  side effect. Two bumps happened this session (10, 11); the next
  (PhaseList state) is 12.
- boot: `godot_console --headless --path . --quit-after 60` grep
  "arena ready|SCRIPT ERROR"
- proofs: **re-run canaries + EVERY proof after ANY pattern/policy/
  arena change, with the CANONICAL SEEDS** (see table below). Commit
  reports (`git add -f reports/*.json` — reports/ is gitignored
  except force-adds). Unchanged scenarios must reproduce their
  committed reports BYTE-IDENTICAL (empty git diff = the
  no-regression proof; this was demonstrated twice this session).
- godot binary: `~/bin/godot_console.exe` (headless) / `godot.exe`
  (play, detached + bring to front).
- hourslog start/stop/note around ALL work (PROD-01). Check the tail
  for a dangling `start` at session start.
- One approved decision = one commit; milestone records go to the
  planning session log; push BOTH repos.

### Canonical proof battery (13 scenarios, all --speed=3.0)

| scenario | seeds | ticks | expected |
|---|---|---|---|
| canary_trivial | 1,2,3,4,5 | 3600 | PASS (MUST-PASS) |
| canary_undodgeable | 1,2,3 | 1800 | FAIL (MUST-FAIL, ~t23) |
| proof_rusher | 1,2,3,4,5 | 3600 | PASS |
| proof_husk_archer | 1,2,3,4,5 | 3600 | PASS |
| proof_fanmaw | 203..207 | 3600 | PASS (stand-off, near 2.678) |
| proof_fanmaw_inside | 205..209 | 3600 | PASS (escape, near 0.315) |
| proof_ringer | 204..208 | 3600 | PASS (near 0.120) |
| proof_leadshot | 206..210 | 3600 | PASS (near 0.125) |
| proof_blightcaster | 207..211 | 3600 | PASS (0 hits; near reads −1, ledger #13) |
| forest_walk → dodge_forest_walk_composition.json | 1,2,3 | 3600 | PASS |
| world_walk → dodge_world_walk_composition.json | 1,2,3 | 3600 | PASS |
| first_contact → dodge_first_contact_composition.json | 1,2,3 | 3600 | **FAIL — committed adjudication evidence, never launder** |
| second_contact → dodge_second_contact_composition.json | 10..14 | 3600 | PASS (near 0.121) |

Runner: `godot_console --headless --path . --script game/bots/bot_runner.gd -- --scenario=<id> --speed=3.0 --seeds=<list> --ticks=<n> [--out=res://reports/<name>.json]`
(compositions need the explicit --out names above).

## Hard-won gotchas (cost real debugging — read ALL of them)

1. **A silently hanging `--script` run = a PARSE ERROR.** Godot 4.6
   prints the error to stderr and the SceneTree idles FOREVER. Kill
   it, re-run unpiped at tiny scale, read stderr. Then kill orphaned
   `godot_console` processes. bot_runner guards with
   `can_instantiate()` → exit 3; copy that pattern for new SceneTree
   entry points.
2. GDScript type inference fails on duck-typed member access:
   `var d := expr_using(p.pos)` where p is RefCounted = PARSE error.
   Hoist typed locals ALWAYS (`var ppos: Vector2 = p.pos`).
3. `as` binds looser than `!=` — use typed locals for expected
   values. Also `sqrtf` does NOT exist in GDScript — it's `sqrt`.
4. NEVER write .tres/.json via PowerShell Set-Content (UTF-8 BOM ⇒
   Godot silently loads null). Use the Write tool. Importers REJECT
   BOMs by contract.
5. gdformat REFLOWS code — after running it, re-grep the actual text
   before Edit; old_string must match the formatted form.
6. NO F-row keys (designer's keyboard). Current keys: O options,
   I interp, [ ] speed presets, -/= step, G gif, R replay, T reset,
   M meter, H hitboxes, ` console, Esc pause, Alt+Enter fullscreen.
7. Sim = pure core: no Nodes/clock/RNG; prev_pos is presentation-only
   (NO sim system may read it — intercept reads the serialized
   ActorState.vel instead); systems duck-type `world`.
8. PackedArrays share storage on assignment — `.duplicate()` for
   snapshots.
9. The proof system WILL catch your regressions. When a proof fails:
   read the heatmap in the report JSON before theorizing; iterate the
   ARENA/LAYOUT or the POLICY, never weaken the proof.
10. Feel notes are PROVISIONAL until a rested day-start pass; the
    verdict console command enforces sources (feel rejects
    bot-proof).
11. The planning repo's only branch is
    `claude/questionnaire-note-taking-9vl2sl`; check for new
    `claude/*` branches at session start.
12. **Smoke micro-worlds use the LAB bitgrid — it has interior
    furniture.** A scripted straight-line walker pinned itself on a
    prop ~10 tiles west of (24,16) and invalidated an escape witness.
    Keep scripted movement near the proven-open pocket (x 16–31,
    y 8–20 has been used safely) or bounce with alternating
    directions.
13. **The undodgeable canary is GEOMETRIC now** (four wall emitters
    boxing the spawn). The old single wall was only undodgeable
    because the old bot policy chose to stand close — a smarter bot
    flees and threads a single ring's widening gaps. If you improve
    the policy and the canary starts passing, the canary is what
    must get harder; never ship with MUST-FAIL passing.
14. **DodgeBot anchor semantics** (learned this session): ANCHOR-
    policy enemies are data-derived keep-out discs (shot reach +
    pad) and are EXCLUDED from the orbit centroid — the bot orbits
    only what chases it. Scenario layouts must respect the same
    geometry: never spawn the player inside an anchor's envelope,
    never leave a habitable pocket between an anchor's disc and a
    wall (both bit second_contact; heatmaps diagnosed both).
15. The report near-miss metric is HAZARD-BLIND (ledger #13): a
    hazard-only enemy reads near −1 with zero hits. The verdict
    field is the evidence, not the margin.
16. Blast Rune and Blightcaster zones share ONE code path: one-shot =
    linger_until == arm tick. Touch hazard_step with both in mind;
    the smoke's blight block plus the fire-path ability casts cover
    it.
17. Windows console pipes can swallow a run's tail — when a battery
    loop's last line looks truncated, check the report JSON on disk
    before re-running.

## Open designer-side items (do not nag, they know)

- **Rested day-start pass** — the big one, now covers: formally
  closing M2, and ratifying EVERY provisional call from 2026-07-27
  AND -28: enemies (all six — each got a positive PROVISIONAL touch
  tonight, Blightcaster's "he does exactly that!" latest), forest,
  slash, pack projectiles, the generated world, the four confirmed
  actor mappings, the M6 authored [T] values (Leadshot band 6–8,
  Blightcaster band 5.5–7 / trigger 8 / cast tell 15, recover 20s),
  the DodgeBot anchor/centroid evolution, and the geometric canary.
- **Composition adjudication at the 3.0 preset**: first_contact
  (3R+2H) AND the world_walk full-pack fight — same failure class
  (primary policy limits, ledger #11), one ruling covers both:
  retune spawns / accept until M7 reactive policies / too hot.
- **Weekly GIF #2** (cadence!): best material — the dusk town walk
  with a wolf on your heels, or the new pack: fanmaw denying a
  quarter while a ringer presses and a leadshot leads you.
- docs/12 §2.7/§3.4 may want a truth-up commit for the M6 authored
  [T] values after the rested ratification (planning-side, designer
  approves).
