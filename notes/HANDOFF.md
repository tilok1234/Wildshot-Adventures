# Session Handoff — written 2026-07-28 (post-midnight), end of the M5 marathon + post-M5 additions

**COLD START — this handoff assumes NO prior context.** You may be a
fresh Claude instance with no memory of any earlier session.

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
  do not create one). Key docs: `docs/12` (build plan; §3.1/§3.4 carry
  2026-07-27 amendments), `docs/14` (assembler pack spec),
  `docs/15` (WorldForge integration + the 2026-07-28 re-ruling),
  `notes/sessions/2026-07-27.md` (the FULL record of the marathon —
  read it for any "why"). One approved decision = one commit + push,
  BOTH repos.

## §0.5 Working with the designer

Solo dev, handle mmoabsurd. Big nerd, goes hard, sometimes overnight;
their plan has a **fresh-hands rule**: feel verdicts count only from
rested day-start sessions — tired-session notes are PROVISIONAL by
rule; honor it kindly, don't nag. They iterate by PLAYING: ship, then
relaunch the game for them (`Start-Process` detached `~/bin/godot.exe
--path .`; the window opens BEHIND — bring it to front via
user32 SetForegroundWindow). Short casual messages ("ye this feels
much better") = provisional positives. They build their own asset
tools and ship packs as versioned drops — tool repos (8-bit sprite
assembler, TileForge, WorldForge at `Documents\WorldForge`) are
READ-ONLY unless separately scoped. **Compact keyboard: NO F1–F12
keys, ever.** You have standing authority to commit and push both
repos at every clean seam. Give honest opinions with numbers; they
change their mind on evidence — and they'll change YOURS the same way.
When they ship a pack mid-task, integrating it beats finishing your
plan (it happened twice on 2026-07-27; both times it was right).

## Where things stand (one paragraph)

M0–M5 all engineering-complete and accepted, ~5 weeks ahead of the
docs/12 schedule (the plan had M5 at week 7; it landed on day 2).
Enemies exist and are proven: Rusher (wolf, telegraphed slash arc) +
Husk Archer (skeleton archer, aimed orb), 5-state machine, one damage
path, DodgeBot proofs at 3.0 ability-off + calibration canaries.
Three asset packs are live (assembler actor catalog 57×202, projectile
pack v0-style with 4 styles in reserve, TileForge theme package), all
via the same discipline: raw drop in `assets/` → validating importer →
only mapped items enter the project. Two arenas: the detailed dungeon
lab (`arena_lab.json`, §3.1 skeleton + dressing) and the Forest Walk
readability testbed (`arena_forest.json`); scenarios pick their arena
(`ScenarioDef.arena`) and spawn enemies by def id. WorldForge
consumer-prep is fixture-proven (validator + walkability→bitgrid);
real world packs wait post-Gate-1. Serialization v9; goldens current;
CI fully green (RNG lint, smoke, goldens ×10, pixel-match, uikit,
assembler, projectile, worldforge gates).

## Next work: M6 (docs/12 §4) — remaining roster + elite + effects/audio

Sim first, then data, then proofs — the M5 pattern. Per-behavior needs:

1. **Fanmaw** (fan/cone anchor) + **Ringer** (radial slow chaser):
   PURE DATA — PatternDef volleys (5-shot 60° fan; 12-shot radial via
   angle offsets) + EnemyDefs at §3.4 stats. ANCHOR policy exists;
   CHASER exists.
2. **Leadshot** (intercept-aimed flanker): needs (a) INTERCEPT aim
   mode on PatternDef — requires target VELOCITY as sim state
   (ActorState.prev_pos is presentation-only and BANNED for sim reads;
   add a serialized `vel`/last-move field → SERIAL_VERSION 10 + golden
   regen, deliberate); (b) FLANKER movement policy (orbit-in — enum
   value exists, anchors currently).
3. **Blightcaster** (delayed ground hazard, keep-range): needs
   lingering multi-hit hazards — hazard_step is explicitly marked for
   this extension; hazards will need linger_until/next_damage fields
   (serialized → same SERIAL bump) + a hazard-type emitter slot
   (EmitterSlot.hazard → HazardDef) + pattern-tagged hazards for the
   recap. Zone + 8-step arm sprites are ALREADY WIRED (hazard_view).
4. **Sprites**: the projectile pack PRE-ASSIGNED pattern sprites
   (dart=Leadshot 12, fang=Fanmaw 13, burr=Ringer 14, hazard-zone=15);
   `data/projectile_map.tres` already maps them. Actor sheets: use the
   PROVISIONAL picks in `data/actor_sheet_map.tres` conventions
   (tracker lists them: bandit:sniper / carniplant:snapvine /
   eyemonster:watcher / cultist:acolyte) — designer veto pending, ask
   once casually, don't block.
5. **Every EnemyDef ships WITH its passing 3.0 ability-off proof**
   (tests/bot_scenarios/proof_<id>.tres + committed report). Re-run
   canaries + ALL proofs after ANY policy/arena/pattern change — §2.11.
6. **Yard Warden elite** (§3.5): PhaseList resource, 400 HP, three
   phases, per-phase + full-fight proofs, peak ≤300 w/ meter proof.
   heavy-orb sprite reserved (elite marker).
7. **EffectLibrary pass** (ledger #9): Nova cast-flash ring sprite,
   effect-density/opacity scaler (cosmetic/friendly channels ONLY,
   hostile clamped — §2.6), flash-reduction mode; then the NINE-row
   acceptance at stress density + audio cue map + placeholder WAVs
   (Law 7) + CORE-34 full no-ability clear.

## Session rituals (the gates)

Before every commit, per touched area:
- format: `python -m gdtoolkit.formatter <files>` (gdformat not on PATH)
- smoke: `godot_console --headless --path . --script tests/determinism/determinism_smoke.gd`
- goldens: any SIM/serialization change ⇒ bump SERIAL_VERSION if
  format changed, regenerate (`tests/replay_fixtures/record_goldens.gd`),
  verify (`verify_replays.gd`), say so in the commit — deliberate,
  never a side effect.
- boot: `godot_console --headless --path . --quit-after 60` grep
  "arena ready|SCRIPT ERROR"
- proofs (if patterns/policy/arenas changed): run the canaries + every
  proof scenario via `game/bots/bot_runner.gd`; commit reports
  (`git add -f reports/*.json` — reports/ is gitignored except
  force-added verdict records).
- godot binary: `~/bin/godot_console.exe` (headless) / `godot.exe`
  (play, detached + bring to front).
- hourslog start/stop/note around ALL work (PROD-01). Check the tail
  for a dangling `start` at session start; reconstruct stops honestly
  (backdate to the last work note, note the reconstruction).
- One approved decision = one commit; milestone records go to the
  planning session log; push BOTH repos.

## Hard-won gotchas (cost real debugging)

1. **A silently hanging `--script` run = a PARSE ERROR.** Godot 4.6
   prints the error to stderr and the SceneTree idles FOREVER (quit
   never runs). Piping through `tail` hides even the banner. Kill it,
   re-run unpiped at tiny scale, read stderr. Then kill orphaned
   `godot_console` processes. bot_runner guards its dependency with
   `can_instantiate()` → exit 3; copy that pattern for new SceneTree
   entry points.
2. GDScript type inference fails on duck-typed member access:
   `var d := expr_using(p.pos)` where p is RefCounted = PARSE error.
   Hoist typed locals ALWAYS (`var ppos: Vector2 = p.pos`). This bit
   the session THREE times.
3. `as` binds looser than `!=`: `if x != [..] as Array[String]` is a
   parse error — use a typed local for the expected value.
4. NEVER write .tres/.json via PowerShell Set-Content (UTF-8 BOM ⇒
   Godot silently loads null). Use the Write tool. The importers all
   REJECT BOMs by contract.
5. gdformat REFLOWS code — after running it, Grep the actual text
   before Edit; old_string must match the formatted form. It also
   rejects parenthesized assignments (`(a = b)` is illegal anyway).
6. NO F-row keys (designer's keyboard). Current keys: O options,
   I interp, [ ] speed presets, -/= step, G gif, R replay, T reset,
   M meter, H hitboxes, ` console, Esc pause, Alt+Enter fullscreen.
7. Sim = pure core: no Nodes/clock/RNG; prev_pos is presentation-only
   (NO sim system may read it — Leadshot's intercept needs a real
   serialized vel field instead); systems duck-type `world`.
8. PackedArrays share storage on assignment — `.duplicate()` for
   snapshots.
9. The proof system WILL catch your regressions (it caught an arena
   detail pass cornering the bot, twice). When a proof fails: read the
   heatmap in the report JSON before theorizing; iterate the ARENA or
   the POLICY, never weaken the proof.
10. Feel notes are PROVISIONAL until a rested day-start pass; the
    verdict console command enforces sources (feel rejects bot-proof).
11. The planning repo's only branch is
    `claude/questionnaire-note-taking-9vl2sl`; other `claude/*`
    branches appear when the designer runs web sessions — check for
    them at session start (`git fetch` + look for new branches),
    fast-forward if they fork cleanly from the working tip.

## Open designer-side items (do not nag, they know)

- **Rested day-start pass**: formally closes M2 AND ratifies every
  2026-07-27 provisional call (enemies, forest, slash, projectiles).
- **first_contact adjudication**: the composition proof FAILS at 3.0
  under the primary policy (committed as FAILING — never launder).
  They play at the 3.0 preset and rule: retune spawns / accept until
  M7 reactive policies / composition-too-hot.
- Provisional M6 actor mappings + slash-sprite share (ledger #10).
- Weekly GIF #2 (wolves + forest + slash = fresh material).
- Dusk TileForge export (unblocks WorldForge slice drafting; nothing
  game-side waits on it).
- M6 audio cue map wants placeholder WAVs (Law 7) — sourcing is
  designer taste territory.
