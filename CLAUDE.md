# Wildshot Adventures — Game Repo Contract

Committed at M0 per the approved Phase A build plan (planning repo
`docs/12-PHASE_A_LAB_BUILD_PLAN.md` §5). **Every session — human or AI — works
under this contract.** Read it before touching anything.

## Authority

- **Design authority is the planning repo**
  (`C:\Users\headc\Documents\Wildshot_adventure_final_planning`). This repo
  implements; it never reinterprets, amends, or overrides design decisions.
- Key planning docs: `docs/12-PHASE_A_LAB_BUILD_PLAN.md` (the build plan this
  repo executes), `docs/07-PROTOTYPE_SPEC.md` (Phase A design definition,
  "SPEC-A"), `docs/08-DECISION_REGISTER.md` (full decision text).
- **On any conflict between this repo and the planning docs: stop and flag.
  Do not resolve it here.** Conflicts resolve in the planning repo, never in
  game-repo commits.

## Binding-constraint digest

Status tags: [L] locked / [P] provisional / [T] test-gated / [CUT].
Full text in planning `docs/08-DECISION_REGISTER.md`; this digest binds every
line of code in this repo.

- **CORE-31 [L]** — Combat is real-time, top-down, freely aimed; movement and
  aiming are independent. It never requires a selected or locked target:
  aiming, firing, damaging, and killing all work with no enemy selected.
  Resolution is primarily spatial — hidden accuracy or evasion rolls cannot
  reject a visible hit. Single-player pause fully freezes combat and cannot be
  used to issue commands or perform actions.
- **CORE-32 [L/P]** — Tap fires once; hold fires at the equipped weapon's
  cadence; a remappable autofire toggle simulates the held state with clear HUD
  feedback. Autofire follows current free aim — including into empty space —
  and never selects, tracks, or aims at enemies. Ordinary primary attacks
  consume no mana, stamina, ammo, durability, or reload resource. Movement,
  aiming, and attacking stay independent and predictable: no root, slow,
  direction-lock, or aim-response reduction from firing. Patterns are
  deterministic and authored — no random accuracy bloom, no unexplained drift.
  No routine screen shake or global hit-stop. Projectiles collide predictably
  with visible solid terrain.
- **CORE-33 [L/T]** — Dodging is purely movement-based (RotMG tradition). The
  universal kit is movement + free aim only: no universal dash, roll, blink,
  sprint, block, parry, shield, or i-frame action. Every attack pattern must be
  honestly dodgeable through movement alone at the lowest intended movement
  speed. Movement speed is a premier, deliberately tuned stat. Falsifier
  recorded: if outside testers at lowest speed cannot honestly dodge after fair
  learning, the lock reopens in the planning repo — never silently here.
- **CORE-34 [L/P]** — Exactly one active ability per character, granted by the
  equipped ability item, running on mana. The skill tree grants no actives. No
  encounter may require a specific ability item — or any ability — to be
  survivable; movement stays sufficient, and encounter design carries that
  burden deliberately.
- **CORE-35 [CUT]** — No focus-targeting system exists: no selection, lock-on,
  marking, focused-enemy state, or hover focus on any input method; no aiming,
  damage, homing, or informational behavior is ever tied to a focused enemy.
  Enemy info comes through general presentation (overhead bars, boss
  presentation). No targeting UI exists anywhere in the scene tree.
- **CORE-36 [L/P]** — Intensity climbs through projectile density, speed,
  pattern complexity, and composition — never HP sponging; health totals stay
  honest. (TTKBot verifies; the density meter proves elite escalation is
  complexity, not density.)
- **CORE-40 [L/P]** — Lean stat set: health, mana, damage, attack speed, range,
  armor/defense, movement speed (+ regen candidates). Intentionally excluded
  [L]: accuracy/evasion/dodge chance, crit chance, life-steal/on-hit sustain,
  resistance matrices. Combat resolves through position, not dice. No crit
  event exists in the event schema.
- **CORE-44 [L/P]** — Packs combine 1–2 pressures from the role grammar
  (aimed/predictive/fan/burst/ground hazard/shield/healer/chaser); dangerous
  packs use 3+; density alone is never the difficulty. Roles readable at a
  glance; readable engagement ranges make pulling/splitting learnable.
- **CORE-50 [L/P]** — Required from start: full input remapping; hold/toggle
  fire; effect-density and opacity options; flash reduction; colorblind-safe
  projectile language (hostile shots differ by shape/pattern, never color
  alone); optional visible-hitbox indicator; UI/text scaling; reducible damage
  numbers; separate audio channels with audible key threats; pause wherever
  legal; no photosensitivity-hostile defaults. **No global difficulty setting
  [L]** — accessibility means readability and control, never enemy tuning. No
  M+K aim assist; zero aim-assist code exists.
- **CORE-51 [L/P]** — The eight readability laws: (1) threat renders above
  beauty — hostile shots/telegraphs never occluded; (2) player shots visually
  subordinate to enemy fire; (3) hostile vs friendly unmistakable by
  shape/pattern first, one consistent hostile language; (4) telegraph
  prominence equals danger; (5) hard per-encounter effect budgets,
  stress-tested at density; (6) quiet arena floors — contrast reserved for
  gameplay; (7) audio as an eyes-closed second channel for key threats;
  (8) death always explainable — an unexplainable death fails review
  regardless of appearance.
- **CORE-53 [L/P]** — Gate 1 is judged by fresh outside testers, never solely
  the builder. Every test pattern is verified dodgeable at the lowest intended
  movement speed — mechanized via the bot harness AND confirmed by rested
  humans.
- **CORE-55 [L/P]** — Gate 1 criteria: testers voluntarily re-engage 20+
  minutes with zero rewards; explainable deaths; lowest-speed dodgeability;
  dependable controls; frames change how testers fight. **The lab is
  zero-reward by law**: no loot, XP, quests, or permanent progression exists in
  any Phase A build.
- **GDD-16 [P/T]** — Co-op insurance, honored architecturally: no global
  assumption that exactly one player exists (`SimWorld.players` is an array;
  zero player singletons or `get_player()` globals anywhere — enemy AI reads
  the player list); input separated from player simulation
  (InputFrame/InputSource port); stable IDs and serializable state everywhere.
- **SPEC-A** — The Phase A minimum content bill and instrumentation list
  (planning `docs/07-PROTOTYPE_SPEC.md` §Phase A) is the scope contract: one
  greybox arena, one class shell, three deterministic weapon frames, 5–6 enemy
  behaviors, one elite, one equipped-ability test slot, heavy debug tooling,
  zero rewards.

## The no-RNG rule (restated where you will see it)

- **Nothing under `sim/` calls global RNG** — `randi()`, `randf()`,
  `randomize()`, `RandomNumberGenerator`, etc. are banned there and CI greps
  for them on every push.
- **The player fire path calls no RNG at all.** Projectile spawn
  position/angle/formation is a pure function of (aim vector, player sim
  position, weapon resource, cadence phase/volley index, tick).
- Sim randomness exists only via the named, serializable PCG32 streams owned
  by SimWorld (`rng_enemy` for authored variation, `rng_misc`). `rng_vfx`
  lives outside the sim so cosmetics can never perturb gameplay.

## Determinism scope

Same build + same platform (Windows) + same scenario/seed/input log ⇒
identical per-tick state hashes. Cross-platform float identity is out of
Phase A scope. Replay-hash and bot CI jobs therefore run on **Windows
runners only**; lint may run on Linux.

## Quiet-lab rule (gate sessions)

- During tester playtests: no coaching, prompting, explaining, or
  watching-over-shoulder commentary. Testers play unattended.
- **CORE-54 evidence is unprompted only**: game-descriptions harvested
  verbatim from Discord/itch/feedback channels go to the CORE-54 log; the
  in-build comments box is supplementary and its contents are never logged as
  CORE-54 evidence; any debrief answer to a direct question is marked
  "prompted".

## Fresh-hands rule

- Dodgeability verdicts accept sources {rested-human, bot-proof}. **Feel
  verdicts accept rested humans only — never a bot** (bots verify mechanics,
  never feel).
- Any runtime edit auto-stamps subsequent feel notes PROVISIONAL; the stamp is
  honored, never overridden by enthusiasm at hour 14. Feel-verdict sessions
  are scheduled at day start.

## Scope tripwire

Any work item outside the SPEC-A minimum content bill is **refused and
ledgered** (`notes/TECH_DEBT_LEDGER.md`), or flagged back to the planning
repo. Gate 1 must pass before anything beyond the bill is built.

## Hours-log rule (PROD-01)

- `tools/hourslog.ps1 start` before ANY project work — code, art, design,
  planning; `stop` after. Dev hours ≠ game-running hours: everything is
  logged.
- `tools/hours_report.ps1` runs weekly; the first meaningful run is end of
  week 4, when the first 4-week rolling window closes. A rolling average below
  40 h/week triggers the PROD-01 floor reset, the docs/12 §4 slip ladder, and
  roadmap re-derivation — by rule, not mood.

## Weekly GIF cadence (from M3)

One 30–60 s GIF per week (F9 ring buffer + `tools/gif.ps1`), posted to the
devlog and one community. This is a deliverable, not marketing garnish — it
primes the tester-recruitment pipeline both Gate 1 cycles draw from.

## Engine pin

- **Godot 4.6.2 stable**, pinned (dev machine: `~/bin/godot`). Upgrades only
  between Gate 1 cycles.
- Typed GDScript only; no middleware; **no Godot physics in gameplay** (custom
  sim-owned collision). C#/GDExtension escape hatch is confined to the sim
  module and triggers only if the M2 stress scene fails budget.

## Milestone position

Edit this line as milestones land: **M1 complete and designer-approved.
M2 engineering complete 2026-07-27; stress verdict recorded (min 1950
fps @ ~600 live — spatial hash deferred, C# hatch not triggered;
reports/stress_m2.json). M2 CLOSES on the designer feel pass (rested,
day start): movement feel at 3.0/4.0 ([ / ] presets), ranger facing,
pause freeze (Esc), interp A/B (I). NOTE: dev keyboard has no F-row —
all utility defaults are letter/punct keys (O options, I interp,
[ ] speed presets, G gif, R replay; HUD shows live hints) and future
debug keys must avoid F1–F12. M3 ENGINEERING COMPLETE 2026-07-27 (8a0f2d4→
d172a25; session record in planning notes/sessions/2026-07-27.md):
three WeaponFrame.tres (§3.3 values, Longbolt 6.5t cap), fire path
with sim-side autofire latch + HUD indicator, motion programs
(straight/decel/sine/boomerang) + 8-slot hit registry (max-passes,
registry_full block), one damage-resolution path + death sweep,
terrain collision + corner-snag JSONL, CORE-32 proofs mechanized in
the smoke test (fire-vs-no-fire position equality; zero RNG in fire
path), .wsr replay capture (R dumps live) + ReplaySource + golden replay
per frame verified 10x consecutive + Windows CI gate (activated M3,
one milestone early — flagged in planning log for veto), remap UI
(O) + Config autoload + settings.cfg persistence (test green), GIF
ring buffer (G) + tools/gif.ps1. OPEN designer-owned M3 items: stand
up itch page + devlog thread + bare Discord (accounts/public posts),
post the first weekly GIF (G → tools/gif.ps1) — cadence starts there
and never stops (GIF #1 posted 2026-07-27; devlog live). M4
ENGINEERING COMPLETE 2026-07-27 (session record in planning
notes/sessions/2026-07-27.md): wildshot-ui kit intake (doc-13; gilded
waiver recorded) themed everything + HP/mana bars + autofire icon +
crosshair; density meter (M) vs budgets.tres; CORE-34 ability slot
(mana/regen sim-side, Nova/Quickdraw/Blast Rune as data, hazard
mechanism, full 13-event skeleton); damage numbers (off/reduced/full;
§2.5 bands as code in render_layers.gd) + per-channel feedback
toggles; scenario .tres + T reseeding reset + lowest-speed preset;
debug emitter (pattern 100, telegraphed aimed ring — first hostile
fire); player death + Law-8 recap panel + session.jsonl evidence
stream; debug console (`) with god (DAMAGE_IMMUNE-logged,
replay-dirty), slow-mo divisor (replay-valid), event tail, and the
SPLIT VERDICT COMMAND (feel rejects bot sources; PROVISIONAL
auto-stamp on dirty/slow-mo) -> verdicts.jsonl; hitbox display (H,
from sim shapes); UI scale x1/x2 + fullscreen/hitbox persistence.
Serialization v7 at M4 close; goldens current; all CI green.
ASSEMBLER SWITCH COMPLETE 2026-07-27: §2.14 Amendment v2 approved,
importer v2 + pack v0 integrated (player = character-ranger 1x), then
the FULL ENEMY CATALOG pack (57 families / 202 variants, players
byte-identical, family:variant index shape) superseded v0 same day.
M5 ENGINEERING COMPLETE 2026-07-27 (cf54bcc→<accept>; session record
in planning notes/sessions/2026-07-27.md): EnemyDef/EmitterSlot/
PatternDef resource family (CORE-40 lean stats, policy grammar, shared
ShotDef volleys); explicit 5-state machine (idle/reposition/windup/
fire/recover) on shared player/enemy Kinematics + THE one damage path
(nova/hazard/contact unified); Rusher (wolf:gray) + Husk Archer
(skeleton:archer) at §3.4 EXACT v0 stats, designer-mapped, rendering
from assembler sheets with aim-facing attack rows; overhead HP bars
(HP_BARS band 35, CORE-35 zero targeting); scenario enemy_spawns +
picker row (first_contact default); M4 debug emitter fully retired
(SERIAL v9); recap keys telegraph lead by pattern (-3 contact / 10
husk named); TTK evidence lines in session.jsonl; §2.6 sustained
worst-case live in the density meter; §2.5 band assertions at boot;
smoke mechanizes the §3.4 contracts (telegraph lead exactly 12, period
exactly 90, contact cadence, keep-range band, hostile-death). DodgeBot
per §2.11: BootArgs autoload (3/4), movement-only 16-heading policy
via legal 8-dir frames, closed-form K=30 projection, headless CLI
(--script bot_runner or --bot=dodge_proof), .wsr repro on hit;
CANARIES calibrate (trivial MUST-PASS passes; wall MUST-FAIL fails
t32); PROOFS COMMITTED: Rusher + Husk PASS 5 seeds x 60 s at 3.0
ability-off + first_contact composition bonus PASS
(reports/dodge_*.json; M5 enemies draw no RNG so seeds are identical
runs until M6 variation). Stress-density screenshot audit captured
(reports/density_audit_m5.png; hostile fire legible above max player
VFX + numbers; meter red-lines the deliberate 26/24 over-budget; Law-3
shape signature stays M-FX/M6). Spriteforge fallback RETIRED (pack,
importer, slice test, dead actor_library removed; CI step dropped).
Serialization v9; goldens regenerated; all gates green.
POST-M5 SAME-DAY ADDITIONS (all designer-approved, session log +
docs/12 §3.1/§3.4 amendments): detailed lab arena (builder layers:
floor_patches/decals/props w/ per-prop solid flag; §3.1 skeleton
preserved); Forest Walk natural-setting readability testbed (SPEC-A
addendum: arena_forest.json + per-scenario arenas via
ScenarioDef.arena; blob-47 coverages; CANOPY band 32); RUSHER SLASH
(visible-attacks principle — §3.4 amended: 3-shot 50° arc, tele 10,
period 36, contact retired; smoke re-mechanized; DodgeBot re-learned
melee: birth-ring windup hazards, orbit stationkeeping RING 4 around
threat centroid, melee trigger bubbles under simulated pursuit);
PROJECTILE PACK integrated within the hour of drop
(assets/projectile-pack, 5 styles; data/projectile_map.tres = pattern
-> sprite, style swap = one-file remap; projectile_view per-pattern
MMIs + sphere fallback + Law-2/8 upscale guard; hazard_view zone
sprites + 8-step arm strip; CI pack+map gate) — M-FX PRE-REGISTERED
DECISION = CURATED PACK, satisfied by delivery. WORLDFORGE
CONSUMER-PREP (2026-07-28 re-ruling in planning doc 15):
addons/worldforge_importer validates packFormat 1 (sha256 parity +
baseArtifact consistency, validation-report pass gate, walkability ->
Bitgrid, flood==floodCount, TMJ structure, world formatVersion) with
hand-derived fixture + 4 negative guards + CI; PROVEN against BOTH
real packs (forest reference + dusk, each 0.6 s, flood 33845
reproduced — walkability theme-independence empirically confirmed;
contract-as-built notes blessed upstream in WorldForge plan §3.3a).
GENERATED-TEST-ARENA RULING EXERCISED 2026-07-28 (~00:50, session
log): consumption landed for ONE world — World Walk scenario plays the
dusk pack (assets/worldforge-packs committed raw drop 32 MB;
game/arena/world_builder.gd validates, REFUSES TileForge
package-identity mismatch, renders resolved TMJ 170k placements/2.1 s;
collision = walkability verbatim; spawn at pack spawnCell;
ScenarioDef.worldforge_pack routes scenarios+bot runner onto worlds).
World Walk composition proof PASS with a light escort set (1R+1H); the
full 3R+2H set FAILS in settlement streets — joined to the
first_contact adjudication. v0 limits: animated tiles frame-0, no
canopy z, POIs/settlements/minimap unconsumed (remaining post-Gate-1
scope with more worlds). PROOF STATE: Rusher/Husk solo + canaries + forest_walk
composition PASS at 3.0 ability-off; first_contact composition FAIL
committed for DESIGNER ADJUDICATION (3 wolves + 2 archers exceed the
primary policy; margins tier-3-watch ~0.1). Ledger #9-#12 opened.
OPEN designer-owned: rested day-start feel pass (formally closes M2
AND ratifies ALL 2026-07-27 provisional calls: enemies, forest, slash,
pack projectiles); first_contact adjudication (play at 3.0 preset);
M6 actor mappings CONFIRMED (designer 2026-07-28: Leadshot=
bandit:sniper, Fanmaw=carniplant:snapvine, Ringer=eyemonster:watcher,
Blightcaster=cultist:acolyte — polished sheet drops expected later,
same family:variant slots; sheets imported; slash-borrows-fang ledger
#10 still open); weekly
GIF #2 (wolves/forest/slash/GENERATED WORLD = fresh material); the
first_contact adjudication now ALSO covers the world_walk full-pack
fight (same failure class, same ruling). M6 IN PROGRESS: FANMAW + RINGER LIVE
2026-07-28 (pure data at §3.4 EXACT: fan 5x60° pattern 13 / radial
12x30° pattern 14; roster indexes 2/3 append-only; smoke mechanizes
both contracts — lead 30/36, period 150/180, anchor-stillness,
chaser-close, volley sizes from spawn events; Law-4 ordering stays
monotone 10<12<30<36; §2.6 sustained worst-case now Ringer-led:
24x4.8=115.2<150, live in the meter). DodgeBot LEARNED ANCHORS (like
melee at M5): ANCHOR-policy enemies are data-derived keep-out discs
(shot reach + pad, one-sided W=3), excluded from the orbit centroid —
mobile enemies only; anchor-free proofs verified BYTE-IDENTICAL.
CANARY STRENGTHENED: undodgeable wall is now four emitters boxing the
spawn (single wall was only undodgeable because the old policy chose
to stay close — MUST-FAIL is geometric now, fails t23). PROOFS:
fanmaw, fanmaw_inside (deep-spawn escape through active fans),
ringer solos + second_contact composition ALL PASS 3.0 ability-off
(near 0.121 = solo-ringer margin); first_contact FAIL preserved
untouched for adjudication. second_contact (M6 pack: fanmaw 40,16
zone-guards the east, ringer chases — pull-the-chaser CORE-44 lesson)
in the picker. LEADSHOT LIVE 2026-07-28 (SERIAL 10: ActorState.vel =
applied post-slide velocity, serialized+hashed, goldens regenerated;
PatternDef.aim_mode INTERCEPT closed-form lead on target vel, fallback
to current; FLANKER orbit-in landed — spiral to band 6-8, circle-
strafe, id-parity chirality, authored [T] band; §3.4 exact 45hp/2.4t/s
dart 9t/s dmg12 ttl67 pattern 12, telegraph 40, cooldown 120; smoke
witnesses band-settle+circulation AND 3 dart hits on a 3.0 t/s square-
wave strafer that current-aim geometrically misses; roster index 4;
Meet: Leadshot picker row; proof_leadshot PASS near 0.125; ALL prior
proofs reproduce exact pre-bump margins at v10). BLIGHTCASTER LIVE
2026-07-28 — THE ORDINARY §3.4 ROSTER IS COMPLETE (6/6). SERIAL 11:
hazard records carry pattern/linger_until/next_damage_tick/
hit_interval; hazard_step pulses (first damage exactly at arm, every
interval until linger inclusive, exact expiry any alignment; Blast
Rune = same path with linger==arm, byte-identical M4 behavior);
EmitterSlot.hazard→HazardDef casts at target pos (zone arm 45 IS the
§3.4 telegraph, pattern-tagged placement TELEGRAPH_STARTED → recap
lead exactly 45); hostile zones render split per §2.5 (fill 20 / rim
70); DodgeBot models full pulse trains (zones crossable between
pulses); smoke: standing pulse-train contract + reactive walker
escapes 4/4 zones at 3.0 with ZERO hits; proof PASS 0 hits; Law-4
ordering COMPLETE monotone 10<12<30<36<40<45; near-miss metric blind
to hazard proximity (reporting nit, logged). YARD WARDEN ELITE LIVE
2026-07-28 (~03:40, new-account session; planning decision 3d19a6c
recorded FIRST: transition proofs via scenario-declared damage
schedule — {tick,amount} on the scenario's elite through THE damage
path, tag -4, mitigation-bypassing, static data excluded from
serialize, replay-visible via the scenario; test scenarios only, M7
checklist guards tester builds). SERIAL 12 = EnemyState.phase_index;
goldens regenerated deliberately. PhaseDef/PhaseList resources;
phase = pure function of HP resolved at one point in enemy_step;
transitions re-arm cooldowns (entry beat + full telegraph — no
untelegraphed volley across a flip), overwrite e.move_speed,
interrupt windup, emit PHASE_CHANGED (event appended). PatternDef
ROTOR aim mode (world-frame angle = rate x tick, stateless).
dodge_policy fully phase-aware (anchor discs / melee bubbles / birth
rings / pursuit speed from live phase). Elite at §3.5 EXACT: 400 HP,
P1 keep-range fan 7sh tele 30 + triple tele 24; P2 ANCHOR rotor
radial 12sh tele 36 + zone casts arm 45 (pattern 18); P3 chaser 2.2
burst 4sh tele 24 + fan + INTERCEPT volley tele 40. Patterns 16-21
all heavy-orb (one elite family, Law 3). Roster index 6. Actor sheet
scarecrow:strawfield PROVISIONAL (designer swap = one line).
MULTI-SLOT DISCOVERY: one state machine serializes attacks — slot
gates wait out other slots' cycles; smoke asserts gap in [cd, cd+90]
for multi-slot, exact solo periods unchanged. Law-4 ordering is now
CODE in the smoke: 12 danger-ranked rows non-decreasing
10<12<24=24<30=30<36=36<40=40<45=45. Smoke also pins: crossings
tick-exact (264 hp AT the tick), 350-in-one settles P3 with ONE
crossing, kill@300 via sweep, leads exact x5, anchor bit-still,
rotor advance exact, schedule twins bit-match, peak<=budget.
PROOFS ALL PASS 3.0 ability-off 5 seeds x 3600: proof_yw_p1 (plain
fight = natural P1 pin, near 0.121), proof_yw_p2 (t0 drop 240,
inside-spawn escape through live rotor gaps, 1.587), proof_yw_p3
(t0 drop 120, chase pressure, 0.120), proof_yw_full (54-entry paced
TTK schedule, transitions mid-flight t1207/t2413, kill t3301,
cleanup to 3600, 0.120; reports carry phase_transitions +
peak_hostile_live 12/300 — the budget line is a report field now).
Elite report fields key on a SPAWNED phased enemy; all 13 ordinary
canonical reports re-verified byte-identical. meet_yard_warden in
the picker. Also fixed: pre-existing density-meter null deref on
hazard-caster slots (pattern null); worst-case now phase-aware.
EFFECTLIBRARY PASS DONE
2026-07-28 (~04:55): game/views/effect_library.gd = the ONE cosmetic/
friendly policy point (CORE-50 density 1/.66/.33, opacity 1/.7/.4,
flash reduction; Bresenham spawn gate, no RNG, view-only). STRUCTURAL
§2.6 clamp: hostile views never receive the reference (FRIENDLY
hazard instance only; projectile_view modulates friendly MMIs only;
flash pops + nova ring are cosmetic channel). Nova cast ring = pack
sprite via new projectile_map.nova_ring field (ability looked up by
id, NOVA kind, expands to def radius). Ledger #14 burning state:
armed lingering zones refill the arm strip toward each pulse from
serialized cadence over a solid armed rim + additive hot swell —
emphasis only; zone sprites now keyed by hazard pattern id (pattern
18 renders its own skin). Options rows effect density/opacity/flash
reduction + [effects] persistence (settings test extended); audit
mode forces full. IMPORTERS RE-RUN (both map-filtered by design):
projectile pack 13 sprites (heavy-orb + nova-ring were missing —
elite had sphere-fallback shots), assembler 8 sheets (scarecrow:
strawfield was missing — elite had NO body; boot error greps must
use "ERROR" not "SCRIPT ERROR", lesson recorded). Ledger #9 amended
(exit = 9-row acceptance record); #14 amended (built, awaits same).
Remaining M6: 9-row acceptance, audio cue map, CORE-34 no-ability
clear.**
