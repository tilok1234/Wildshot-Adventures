# Session Handoff — written 2026-07-27, end of the M2→M4 marathon

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
  `C:\Users\headc\Documents\Wildshot_adventure_final_planning` — key
  docs: `docs/12-PHASE_A_LAB_BUILD_PLAN.md` (the plan; §2.14
  Amendment v2 applied), `docs/14-ASSEMBLER_GAME_PACK_SPEC.md`
  (BINDING asset-export contract), `docs/13` (UI kit spec),
  `notes/sessions/2026-07-27.md` (the full record of the marathon
  session this handoff summarizes). Milestone completions are recorded
  there: one approved decision = one commit + push, BOTH repos.

## §0.5 Working with the designer

Solo dev, message handle mmoabsurd. Self-described "big nerd, can go
hard" — works long sessions, sometimes overnight; their own plan
contains a **fresh-hands rule**: feel verdicts count only from rested
day-start sessions, and tired-session notes are PROVISIONAL by rule —
honor it kindly, don't nag. They iterate by PLAYING: ship a change,
relaunch the game for them (Start-Process detached; window opens
BEHIND — bring it to front), they react in short casual messages
("feels good i think" = provisional positive). Hedged phrasing is
normal, not doubt about you. They build their own asset tools
("forges": TileForge tiles, the 8-bit sprite assembler for actors, a
UI kit) and ship packs as versioned drops with manifests — treat tool
repos as READ-ONLY unless asked. **Compact keyboard: NO F1–F12 keys,
ever.** You have standing authority to commit and push both repos at
every clean seam without asking. Give honest opinions with numbers
when you disagree — they change their mind on evidence and expect you
to concede when they're right. Measure before optimizing; they respect
"I measured X" and distrust vibes (their plan is built on
falsifiability).

Read the rest AFTER `CLAUDE.md`. Design authority for anything
ambiguous: the planning repo, then the designer.

## Where things stand (one paragraph)

M2, M3, M4 engineering all completed and feel-tuned 2026-07-27 in one
session; every commit gated (smoke, goldens ×10, slice/kit/pack
validations, boot) and pushed; CI fully green. The actor source is now
the designer's 8-bit assembler (Amendment v2): pack v0 is integrated —
player renders `character-ranger` at native 1× (24 px cells, render
scale from the manifest), cast/death alias to attack/hurt until the
designer ships those rows (additive, zero code). Six assembler enemies
(goblin-scout, skeleton-knight, slime-lime, wolf-gray, bat-cave,
treant-oak) sit in `assets/assembler-pack/` awaiting M5. The old
Sprite Forge pack is FALLBACK ONLY until M5 acceptance, then retire it
(remove `assets/spriteforge/`, `spriteforge/`, its importer + slice
test; the map is already assembler-only).

## Next work: M5 (docs/12 §4, weeks 6–7 scope)

Sim first (sprite-independent), then views, then proofs:

1. `EnemyDef.tres` family: lean CORE-40 stats + MovementPolicy
   (chaser / keep-range / orbit / anchor / flanker) + EmitterSlots
   {PatternDef, trigger, telegraph_ticks}. PatternDefs = same resource
   family as WeaponFrame (reuse ShotDef). No behavior trees; explicit
   5-state machine (idle/reposition/windup/fire/recover), all timers in
   ticks, decisions from world state + `rng_enemy` ONLY.
2. First two enemies with §3.4 EXACT v0 stats: Rusher (hp20 r.30
   spd2.7 contact dmg8) and Husk Archer (hp40 r.35 spd2.2, aimed single
   10dmg 7t/s r.18 range7t ttl60, telegraph 12, cooldown 90).
3. Enemy movement uses the same axis-slide kinematics as the player
   (extract shared helper from player_move if needed). Enemies render
   via AnimatedActor from the assembler pack (extend actor_sheet_map:
   e.g. enemy_rusher → wolf-gray or slime-lime, enemy_husk →
   goblin-scout — DESIGNER picks the mapping, ask once). Overhead HP
   bars = general presentation, NO targeting anything (CORE-35).
4. The M4 debug emitter retires when real enemies can be spawned from
   the scenario picker (scenario .tres gains enemy spawn lists).
5. DodgeBot (§2.11): BootArgs autoload (2 of 4 allowed autoloads used;
   Telemetry/DebugHub still unbuilt), headless CLI
   (--bot=dodge_proof --scenario --speed --runs --seeds --ticks --out),
   movement-only 16-dir+stay closed-form projection (motion programs
   are pure functions of age — that's why), fire+ability disabled.
   PASS = seeded runs × minutes, zero hits, at 3.0. CANARIES in
   tests/bot_scenarios: one undodgeable (MUST fail) + one trivial
   (MUST pass). Reports → reports/ ("mechanical verification"; no gate
   code reads them). Any hit dumps a .wsr repro.
6. Each EnemyDef ships WITH its passing proof in the same milestone —
   never author now, prove later.
7. M5 acceptance additions: stress-density screenshot audit (hostile
   legible above player VFX + damage numbers — Laws 1/2), §2.5
   load-time band assertions activate, hostile-vs-friendly from
   separate nodes assert.

## Session rituals (the gates)

Before every commit, per touched area:
- format: `python -m gdtoolkit.formatter <files>` (gdformat not on PATH)
- smoke: `godot_console --headless --path . --script tests/determinism/determinism_smoke.gd`
- goldens: any SIM/serialization/weapon-data change ⇒ bump
  SERIAL_VERSION if format changed, regenerate
  (`tests/replay_fixtures/record_goldens.gd`), verify
  (`verify_replays.gd`), and say so in the commit — deliberate, never
  a side effect.
- boot: `godot_console --headless --path . --quit-after 60` grep
  "arena ready|SCRIPT ERROR"
- godot binary: `~/bin/godot_console.exe` (console) / `godot.exe` (play,
  launch via Start-Process detached; bring window to front — it opens
  behind otherwise).
- hourslog start/stop/note around ALL work (PROD-01).
- One approved decision = one commit; milestone records go to the
  planning session log (notes/sessions/YYYY-MM-DD.md) + push BOTH repos.

## Hard-won gotchas (cost real debugging today)

1. gdformat REFLOWS code (`(obj\n. method(` style) — after running it,
   Grep the actual text before Edit; old_string must match the
   formatted form.
2. NEVER write .tres/.json via PowerShell Set-Content — UTF-8 BOM makes
   Godot silently load null. Use the Write tool ([System.Text.UTF8Encoding]
   $false to repair).
3. GDScript type inference fails on duck-typed member access:
   `var d := apos - p.pos` (p: RefCounted) is a PARSE error that can
   silently break dependent scripts → step() aborts mid-tick → goldens
   record a tickless world. Hoist typed locals (`var ppos: Vector2 =
   p.pos`) always.
4. PackedArrays SHARE storage on assignment (4.6) — `.duplicate()` for
   snapshots; local aliases are free.
5. Anchored Controls grow END by default: right-anchored panels run off
   screen, center panels drift. Set grow_horizontal/vertical.
6. NO F-row keys ever (designer's keyboard lacks them). Current keys:
   O options, I interp, [ ] speed presets, -/= step, G gif, R replay,
   T reset, M meter, H hitboxes, ` console, Esc pause, Alt+Enter
   fullscreen. HUD bottom-right shows live hints.
7. The viewport readback (get_image) costs 32 ms on this machine —
   never per-frame; GIF recorder is armed-mode only.
8. Sim = pure core: no Nodes/clock/RNG; mutation only via ordered
   systems in step() or the command queue; events are the only output;
   views read, never write. Systems duck-type `world` (preload cycle).
9. Feel notes from the designer are PROVISIONAL by rule until a rested
   day-start pass; the verdict console command enforces sources.

## Open designer-side items (do not nag, they know)

- Rested day-start pass: formally closes M2; ratifies all 2026-07-27
  provisional feel calls + the new sprite.
- Assembler pack v2: cast + death rows (additive; aliases cover).
- Weekly GIF cadence: #1 posted 2026-07-27; #2 due next week.
- Enemy role → assembler-id mapping for M5 (one question, ask early).
- Hours session from 06:41 may still be open — check
  `notes/hours.csv` tail; if the last entry is a note (no stop), ask
  or reconstruct honestly like last time.
