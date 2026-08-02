# Wildshot Adventures — Game Repo Contract

> **ECOSYSTEM POINTER (2026-07-29, designer-accepted doc 16).** This
> repo is one of seven in the Wildshot project. The shared map — what
> each repo owns, its authority docs, and the hard cross-repo rules
> (authority flows planning→game→upstream-asks; packs are frozen and
> validated at every boundary; pins are deliberate) — lives at
> `Wildshot_adventure_final_planning/docs/16-ECOSYSTEM_MAP.md`.
> Read your repo's row before working here.

> **SYNC-LOG HOOK (doc 18, ACCEPTED 2026-07-30).** At session end, with
> the handoff update, append a line to planning `tools/sync_log.json`
> for every cross-repo event this session caused (pack delivered or
> intaken, ask opened/resolved, incident, pin change). No event, no
> entry. Protocol: planning `docs/18-AGENT_SYNC_PROTOCOL.md`.

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
- **Stay in this repo's lane (designer rule, 2026-07-29):** game-repo
  sessions never execute other repos' plans or work (WorldForge,
  world_filler, TileForge, assembler, Resonance Forge). Upstream needs
  become recorded asks or a self-contained prompt the designer hands to
  that repo's own agent. Reading other repos for context is fine;
  intaking their delivered packs is game-repo work; DOING their work is
  not.

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
- **CORE-53 [L/P — AMENDED BY RULING 2026-07-30]** (sl-0023, planning 593cc27;
  deck ratification staged; docs/08 row amended planning-side same day) —
  human judgment moves BEHIND the loop bar: 2–3 warm, WATCHED first-touches
  (screen-share or in person), designer-scheduled only once the bar holds. The
  rule's heart survives verbatim — the gate is never judged solely by the
  builder. Lowest-speed dodgeability verification (bot-mechanized AND
  confirmed by rested humans) unchanged.
- **CORE-55 [L/P — GATE 1 REWRITTEN 2026-07-30]** (sl-0023, planning 593cc27) —
  the recruited-stranger zero-reward gate is RETIRED WITH CAUSE (fresh eyes are
  nonrenewable and get spent on first touch; failed recruitment reads as
  verdict when it is only silence). NEW GATE = THE LOOP BAR: an unguided
  complete run — spawn in the b65 town, walk out, fight through rising danger
  where loot actually drops and matters, reach the first boss or die trying,
  death costs something real, dying pulls you to retry immediately — that
  stays fun for the DESIGNER playing it daily for a week. Feel and stakes over
  polish. **The zero-reward lab law is thereby lifted for loop work**: loot and
  death-cost systems are in scope by ruling. Explainable deaths, lowest-speed
  dodgeability, and dependable controls stay binding. The bar's final wording
  is the designer's (deck card staged); docs/08 rows + docs/12 supersession
  banner landed planning-side same day (verified 2026-07-30 late).
  **AMENDED AGAIN 2026-08-01 (sl-0098, Tier 1): THE SLICE IS THE LOOP** —
  Slice v0.1 (the four-zone dusk overworld) is the bar's judging vehicle;
  living in the built world (no run framing, the world persists and
  refills) is what the three-sentence docs/19 bar judges over the
  designer's week; the b65 run framing retires with honor as the
  mechanism proof; register row amended planning-side.
- **GDD-16 [P/T]** — Co-op insurance, honored architecturally: no global
  assumption that exactly one player exists (`SimWorld.players` is an array;
  zero player singletons or `get_player()` globals anywhere — enemy AI reads
  the player list); input separated from player simulation
  (InputFrame/InputSource port); stable IDs and serializable state everywhere.
- **SPEC-A [COMPLETE — superseded as the forward scope 2026-07-30]** — The
  Phase A minimum content bill and instrumentation list (planning
  `docs/07-PROTOTYPE_SPEC.md` §Phase A) is BUILT: one greybox arena, one class
  shell, three deterministic weapon frames, 5–6 enemy behaviors, one elite,
  one equipped-ability test slot, heavy debug tooling, zero rewards. It stands
  as the Phase A record; the forward scope referent is the Loop milestone
  (Gate-1 rewrite — see the scope tripwire).

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

- AMENDED 2026-07-30 (Gate-1 rewrite, sl-0023): gate sessions are now 2–3
  warm WATCHED first-touches (screen-share or in person), designer-scheduled
  once the loop bar holds. Watching is SILENT — the no-coaching, no-prompting,
  no-explaining law holds during the run; the watcher observes, never guides.
  (Pre-rewrite text: testers play unattended.)
- **CORE-54 evidence is unprompted only**: game-descriptions harvested
  verbatim from Discord/itch/feedback channels go to the CORE-54 log; the
  in-build comments box is supplementary and its contents are never logged as
  CORE-54 evidence; any debrief answer to a direct question is marked
  "prompted".

## Fresh-hands rule (TWO-TIER since 2026-07-29, ruled via Decision Deck)

- **Tier 1:** in-session designer calls (chat one-liners, deck taps) count
  as decisions immediately. **Tier 2:** feel items additionally get one
  rested ratification pass before they are final. Dodgeability verdicts
  accept sources {rested-human, bot-proof}; **feel verdicts accept rested
  humans only — never a bot** (bots verify mechanics, never feel).
- **"Rested"/"day start" key on hours into the DESIGNER'S waking day and
  session, never wall clock** — they work a 15:00–23:00 shift, so home at
  midnight is their ~17:00. Marathon-length sessions and dirty runs
  (god/slow-mo/runtime edits) stay PROVISIONAL regardless of tier.
- Any runtime edit auto-stamps subsequent feel notes PROVISIONAL; the stamp is
  honored, never overridden by enthusiasm at hour 14.

## Scope tripwire (rewritten 2026-07-30 with Gate 1, sl-0023; SUPERSEDED IN PLACE 2026-08-01, sl-0098)

> **sl-0098 (designer, Tier 1): THE WORLD IS THE TEST.** The forward
> scope is **Slice v0.1** (planning `docs/23-SLICE_BUILD_PLAN.md`) —
> the slice IS the loop; the separate Loop-acceptance gate DISSOLVES;
> the b65 town loop retires with honor as the mechanism proof; the
> pack-wiring hold LIFTS (icons + NPCs wire into the slice build).
> The refusal mechanics below stand unchanged, aimed at the slice
> bill's needs; the pre-rewrite text stays as history.

The forward scope is the **Loop milestone**: loop-assembly work items (run
flow from the b65 town outward, rising danger, loot that matters, death cost,
first boss, immediate retry pull) flow from designer direction under the
talk-before-build law — the bar card is staged for the designer's own words,
and loop systems get designed with them before they get built. Anything
outside the loop bar's needs is **refused and ledgered**
(`notes/TECH_DEBT_LEDGER.md`) or flagged back to the planning repo, exactly as
before. Test scenes are built to accrete into game content where possible —
"playable" is a gated artifact. The loop bar must hold (fun for the designer
daily for a week) before the warm watched first-touches are scheduled. The
tester-build export pipeline + lockdown profile stay a STANDING GATE
regardless — clean-stamped zips are what make warm testing frictionless.

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
AUDIO CUE MAP LIVE
2026-07-28 (~05:20): Law-7 eyes-closed channel. Buses Sfx +
KeyThreats (code-created idempotent, both → Master; per-channel
volume rows 100/70/40/off persisted under [audio] — CORE-50
separate channels). Seven placeholder cues generated
deterministically by tools/gen_cue_wavs.py into audio/placeholder/
(assets/ is .gdignore'd raw-drop land — importers copy OUT of it;
lesson re-learned with WAVs). data/audio_cue_map.tres = class →
{wav, bus} + melee_patterns [11]; classification is data-driven
(zone ids from projectile_map.zones). game/views/audio_cue_view.gd
consumes the event relay: telegraph_ranged/melee, hazard_cast/
armed (HAZARD_ARMED now carries faction — events are unserialized,
payload additions replay-safe), phase_change, player_hit/death;
8-tick per-class retrigger gate. notes/AUDIO_CUE_MAP.md holds the
written map + PENDING designer eyes-closed review slot. SPHERE PACK ADOPTED
2026-07-28 (~06:40, designer-directed; planning decision 0680ca9 =
§2.6 signature amendment + §3.4 small-shot retune [T]):
assets/wildshot-projectiles-sphere-v0 (shaded orbs, 726 files,
deterministic generator) supersedes the v0 5-style pack (held
in-repo as recorded fallback until 9-row passes). Hue map per the
CVD-checked proposal: husk red d8, slash cyan d10 (LEDGER #10
CLOSED — share dissolved), dart violet d10, fanmaw orange d10
(deutan-bucket flag with red recorded; teal = alternate), ringer
MAGENTA-DEEP d8 (base magenta collapses into friendly silver under
deuteranopia — the sim caught it), Warden amber tone-ladder
d10/d12 unchanged radii (now reads one tier above ordinaries).
Ordinary shot radii retuned to small tier [T]: husk/ringer 0.125,
slash/dart/fanmaw 0.156 (elite untouched). Exact-fit + full-bleed
orbs = visual == hitbox at ~native scale. Importer + pack test
repointed; 16 sprites imported; wheelblade alt frame dropped
(annulus spin invisible). FULL BATTERY re-proven at new radii:
canaries correct (MUST-FAIL still t23), all solos + forest/world/
second PASS with widened margins (fanmaw_inside 0.315→0.365,
rusher 0.311), ELITE PROOFS BYTE-IDENTICAL (untouched control ✓),
canary_trivial heatmap shifted (it IS a lone husk — explained).
**first_contact STILL FAIL, reshaped: 13 hits from t1050
seed-identical (smaller shots changed the deterministic path into
a worse pocket) — organic-flip hypothesis refuted; ledger #11
adjudication stands.** Audit captures regenerated on the sphere
set + density_audit_m6_deutan.png committed (Law-3 CVD evidence).
Remaining M6: 9-row acceptance (designer eyes, now vs sphere set),
CORE-34 no-ability clear (designer play, session.jsonl evidence).
2026-07-28 AFTERNOON ARC (the movement odyssey + M7 first half; full
narrative in planning notes/sessions/2026-07-28.md): M7 STARTED
designer-directed parallel to the designer-side M6 queue. Landed:
policy modes (Policy.{PRIMARY,REACTIVE,ORBIT,AXIS_STRAFE},
--policy=, suffix-guarded outputs; reactive = melee bodies at RAW
radius, dodge windups on telegraph); TTKBot (ttk_runner/ttk_bot, 21
pairs ALL EXACT, finding: Warden dies to current Longbolt in 8.38s
vs stale ~13s prose — RULING PENDING); ledger #13 CLOSED (armed
zones in near-miss; negative = between-pulse crossing, legal).
MOVEMENT ODYSSEY (four real fixes chasing the designer's "walking
bugs out near structures"): (1) RealtimeDriver 5-tick catch-up
bursts → 2-tick cap + time-stretch shed; (2) props-overhang →
CANOPY band (walk under awnings, occluded); (3) WorldForge packs
re-exported by DESIGNER-RUN WF AGENTS (a1304b9 full-footprint
stamping — porosity was inter-placement slits + POI pass cells,
NOT window columns; flood 33712, spawn 240,125, diag allows exactly
11 route cells; then cbf11a9 level-0 moss carpet walks — flood
34556, 626 carpet + 366 bridged cells; both intakes battery-clean,
world_walk byte-identical through moss); (4) THE core bug since M2:
Kinematics corner over-ejection limit cycle (2-px shiver, zero
progress at visible gaps) → TANGENT ejection (face math
byte-identical); then designer-directed WALK-CLOSE FEEL [T]:
TERRAIN_RADIUS 0.25 locomotion split (hurtbox 0.35 untouched
everywhere; bot walks 0.25/threats 0.35) + CORNER SLIP in the one
shared slide (unused corner-blocked motion deflects along escape
unless input opposes; all movers). Designer: "doesnt lag anymore".
CONSEQUENCE: slip freed WOLVES from prop snags → 3 primary-FAIL/
reactive-PASS pairs (rusher solo 4 hits/0.015, forest 12/0.003,
first_contact) — one root: melee-as-do-not-enter; reactive passes
all three clean + solos wolves + fails the geometric canary.
world_walk flipped PASS under primary (its FAIL was porosity-era).
proof_blightcaster layout iterated to the open pocket
(20,12)/(26,12) per never-weaken (its old PASS partly rode
over-ejection slip). Goldens regenerated twice (tangent, slip).
DESIGNER RULING MENU (chat ~14:10, all one-liners): (1) the 13
sealed grass slit cells (keep sealed / reopen / TileForge dressing
— lean: keep now, dressing endstate); (2) REACTIVE AS POLICY OF
RECORD (lean: yes — closes ledger #11, dissolves first_contact
adjudication); (3) Warden HP 8.4s-vs-575 (lean: accept 8.4s);
(4) six-ordinaries ratification ("Approved : not done" needs the
word). APPROVED TODAY (morning batch): Warden full ratification,
sphere set + §2.6 amendment, arenas (tree-border taste note);
M2 movement approval pending the walk on the current build.
LONG PASS COMPLETE (~16:00, designer-authorized, at work): SoakBot
live (b818e71; 151-segment/543k-tick full-rotation soak CLEAN —
drift 0, NaN 0, pool 0 — report committed 04d91ef; plus 32 clean
segments from an earlier soak the assistant accidentally killed:
the Godot CONSOLE wrapper spawns an engine child named plain
"godot" — process-kill filters must account for it); composition
proofs for every picker scenario (d33eba5 — lab_default + three
meets PASS, seeds 1,2,3); tools/pretester_check.ps1 = the
one-command M7 gate, ALL GREEN 9.7 min exit 0 (37 steps: RNG lint,
walkability diag, seven consumer/determinism tests, boot, 25-run
battery vs an expectations table encoding the wolf-pair FAILs,
byte-identical check; exclusive-access precondition — concurrent
Godot instances race .godot and flake determinism steps; loops
closure-free — pwsh $LASTEXITCODE in GetNewClosure is unreliable).
THE CHECKLIST'S FIRST CATCH: the smoke wall assert had been failing
silently since the terrain-radius commit (gate output was piped to
its tail, exit code unchecked — GATES READ EXIT CODES, NOT PROSE);
assert now derives from PlayerMove.TERRAIN_RADIUS (4e59412).
Export pipeline: templates verified present, one-shot design in
notes/EXPORT_PIPELINE_DESIGN.md. Remaining M7: export.ps1
dev/tester profiles + the export step in the checklist. DESIGNER
four-ruling menu unchanged (queue leads with it).
DECISION DECK ERA BEGINS 2026-07-28 late (~23:30-00:50, session
record planning notes/sessions/2026-07-29.md): designer-built
Decision Deck (Claude-design export) ADOPTED as THE decision
register (planning tools/decision_deck.html + payload + register;
test_deck retired; plain-language rule for all designer-facing card
text — memory + payload rewritten). BURN-DOWN: 20 decisions in the
register (tools/decision_deck_register.json). RULED: verdict system
TWO-TIER + shift-work rested definition (digest above amended);
REACTIVE = DodgeBot policy of record (ledger #11 CLOSED,
first_contact adjudication dissolved, battery re-baseline QUEUED on
exclusive access); recruitment 10-16, >=4 strangers/cycle, >=5 held
for cycle 2; Warden HP -> ~575 [T] re-proof QUEUED (13-s intent
kept); fanmaw stays ORANGE (9-row row-3 adjunct); scarecrow:
strawfield APPROVED; grass slits keep-sealed-now (designer note
flags confusion — clarification pending, dressing endstate);
hours backfill approved (numbers pending); ledger #12 grandfather
note recorded (CLOSED). ACCEPTED: 9-row eye rows 1/2/3/6/9 (table
signed, two-tier basis), ecosystem map doc 16 (pointer blocks
armed), doc 17 world_filler plan (post-Gate-1 ladder). GOs ARMED:
export.ps1 (M7 close), WorldForge 49/50 merge + dusk re-export +
intake, docs truth-up. VERIFIED EVIDENCE: assembler b7eae05f
PUSHED (+ 48x48 boss direction pilots on the branch — polished
sheets warming); CORE-34 no-ability clear (session.jsonl
2026-07-29: 3 Warden kills t556/581/721, ZERO ability events,
the one death was world_walk husk — M6 acceptance line met);
itch/Discord marked done by designer (links pending). world_filler:
freeze review RESOLVED upstream (38/38, format 1 FINAL), mainline
RULED = freeze-review-resolution-tf6bkf, proper clone landed
(HEAD adds F9 studio A+B); game-side consumption stays post-Gate-1
per doc 17. Weekly GIF #2 produced (Warden fight, 2.54 MB devlog
cut). OPEN feel cards stay rested-gated per two-tier: M2 close,
six ordinaries, audio-in-play; eyes-closed audio evidence open.
ENGINEERING QUEUE (needs exclusive Godot access — designer's game
closes first): reactive re-baseline -> Warden 575 -> export.ps1 ->
WF merge chain -> docs truth-up + pointer blocks.
CHAIN EXECUTED 2026-07-29 (~02:00-02:40, designer closed the game and
said go; session record planning notes/sessions/2026-07-29.md):
(1) REACTIVE RE-BASELINE LANDED (4b1c2b4) — dodge_proof defaults
reactive, unsuffixed reports = the record, full 25-row battery
regenerated (former wolf-pairs PASS; MUST-FAIL canary still fails);
the three primary FAILs stay watched as [primary] baseline rows +
committed dodge_*_primary.json (if primary ever PASSES one, the sim
changed). (2) WARDEN 575 LANDED (59cd087) — floors stay 66/33 pct
(379.5/189.75), schedules re-derived (p2 drop 230 -> 60%, p3 drop
403 -> 29.9%, full-fight sums 575 on the same skeleton: transitions
t1207/t2413, kill t3301), smoke pins green, all elite proofs + meet
PASS, TTKBot 21 pairs ALL EXACT — Longbolt vs Warden 11.88s (was
8.38 at 400; design line ~13s; planning §3.5 truthed 0c6c04f).
(3) EXPORT PIPELINE LIVE — export_presets.cfg (windows-dev debug /
windows-tester release + custom feature "tester"), main.gd dev_tools
ONE-FLAG gate (console+god+slowmo+verdict, free speed steps, bot/
audit CLI; speed presets STAY tester-facing), build_info.gd stamp
(export.ps1 rewrites via git describe, restores after; tester HUD
shows it), tools/export.ps1 (export both -> loose worldforge packs
beside the exe -> zip wildshot-<id>-<profile>.zip -> artifact boot
check by EXIT CODE -> butler command prepared for designer),
WorldforgePack.resolve_src exe-relative fallback (assets/ is
.gdignore'd so packs ship loose; ALSO means a new pack drop swaps
into a built tester zip with no re-export). PROVEN: both artifacts
boot exit 0; tester exe on world_walk validated the loose pack (8
hashes) + rendered 170104 placements + arena ready. pretester gains
the export step (TODO retired). PASSAGE-RULE PACK INTAKEN same seam
(3b5ac3d; WF 7b08f35 two-wide rule): west-city 1-wide slaloms sealed,
2-wide streets open, ~60 sole-access corridors preserved, flood
34433, porosity still 11, world_walk re-proven. **M7 CLOSED
2026-07-29 ~02:45: pretester_check ALL GREEN 10.9 min — 11 fixed
gates + 25-row battery byte-identical + export step (both artifacts
boot exit 0).** CITIES ARC ACCEPTED
2026-07-29 ~03:05 ("hallelujah! finnaly works"): the WF agent's
WYSIWYG re-export (flood 34739, +306 reopened — 481 one-wide
inter-house strips walk, 474 reachable, 7 legal courtyard islands;
seal machinery deleted upstream, -428 lines; collision = art outline
minus declared pass cells, bidirectional gate, exceptions empty) +
the game's per-building y-sort space (v2 mini-layers after the
alt-tile route dropped roofs) = the designer walks between houses.
Porosity diag re-pinned 44 (33 gateway pass cells + 11 legacy,
per-drop pin, eyeball-verified 2-wide `ss` gateways). world_walk
re-proven PASS on the reopened pack. LANE RULE added to Authority
(game sessions never execute other repos' plans — asks/prompts
instead). Eight-holds round-12 docks verdict = designer, WF-side.** LESSON: never edit sim data while
a battery runs (yw rows landed post-edit by luck — sequence edits
between runs). REMAINING game-side: intake the WF passage-rule dusk
re-export when the designer's WF agent ships it (supersedes the v57
export; world_walk re-proof + designer city walk). Audio verdicts
DEFERRED to Resonance Forge intake by designer call. BOSS PACK
INTAKEN 2026-07-29 (~12:45): established-boss-pack-13-v1 (13 bosses,
48x48 native, cast+death rows, review-only export from the assembler
dist zip) validated structurally — tools/validate_boss_pack.py: 1248
PNGs, hard alpha, every sliced frame pixel-identical to its
full-sheet region, frame-0 non-empty per anim/dir/boss; README's
"48x192 direction animation sheets" line is a typo (actual 960x48) —
and committed raw at assets/assembler-boss-pack/ (.gdignore'd; boot
clean). NO game wiring: importer/library single-cell assumption +
per-sheet scale story = the deck's boss-sheets card = M8/Phase B
scope talk. RULED (designer, 2026-07-29 ~12:50, Tier 1): keep the
raw drop as-is, wire in only when a boss sprite is naturally needed;
polished exact re-exports expected later (same shape — revalidate
with the tool before replacing the directory). Warden-skin audition
path + 48px-skin-vs-24px-hurtbox honesty note parked with the card.
M8 EARLY-START 2026-07-29 (~13:20): TESTER-PROFILE LOCKDOWN SWEEP
LIVE — tools/lockdown_lint.py (one-flag gate proven at source:
dev_tools single assignment from the tester feature tag, console
single gated construction, free-speed/bot/audit gated on their
checked lines, god/slow-mo/verdict console-only, preset feature tag +
exclusions pinned) + tools/lockdown_probe.ps1 (artifact probes: dev
exe + --bot writes a report = positive control; tester exe REFUSES
bot/audit CLI with clean normal boot; tester session evidence free of
dev markers; --script surface confirmed DEAD on release templates —
no preset change needed). Both are permanent pretester steps (39
steps, ALL GREEN 12.5 min, battery byte-identical). Hardened:
audit_min gated at its declaration (was gated only by nesting).
FIXED (the probe's first catch): dodge_proof._resolve_scenario used
FileAccess.file_exists, which cannot see PCK-remapped resources —
exported dev builds could never run the documented --bot CLI; now
ResourceLoader.exists (project mode identical; battery byte-identical
proves it). M8 accept line "tester debug profile verified" is
MECHANIZED. FEEDBACK RETURN PATH LIVE same seam (~13:45): session
lifecycle evidence (game/drivers/session_log.gd — session_start/
heartbeat-30s/end lines w/ build id + wall clock + dev_profile flag;
alt-F4 bounded by last beat; PREDELETE closes T-reset sessions);
feedback bundle (game/drivers/feedback_bundle.gd — options-menu
"feedback: save bundle" row zips session.jsonl+terrain.jsonl+
settings.cfg+bundle_info to Desktop via ZIPPacker, reveals in
Explorer, HUD toast shows path+code); summary code WS1-MMM-SSDD-KKKC
(Crockford b32 + checksum; encode-side contamination exclusion —
dev_profile sessions and their windows never count;
tools/decode_summary_code.py = designer-side decoder, checksum
REFUSES typos). Telemetry field deliberately named dev_profile so
the lockdown lint's "dev_tools only in main.gd" pin stays maximally
strict. tests/feedback/feedback_bundle_test.gd (scan/exclusion/code/
checksum/zip) in pretester (15 fixed gates) + CI Linux job. Toast +
row are DESIGNER-EYES pending next launch (render gate). Taste
answers pending (Tier 1 when given): bundle location (Desktop
default), comments box now-vs-later, summary-code paste destination.
ONBOARDING SCREEN LIVE (~14:15, last block while designer at work):
ui/onboarding_screen.gd shown ONCE per app run (static var; T reset
never re-shows), TESTER PROFILE ONLY, over the paused arena —
CORE-31 pause with driver.pause_locked (new) so Esc cannot unpause
under the overlay; the start buttons are the only unpause path.
Lowest-speed loadout selector = M8 accept line (start standard 4.0 /
start lowest 3.0 — real buttons); choice logged as a "loadout"
evidence line via session_log.log_loadout (lowest-speed segments
attributable per CORE-53). ALL COPY IS PLACEHOLDER, designer voice
pending — constraints documented in the file (quiet-lab: no
coaching; NEVER ask for a play duration — re-engagement stays
voluntary). Dev profile boots straight in, unchanged. Fixed gates +
artifact boots + lockdown probe ALL GREEN with the screen aboard.
DESIGNER-EYES pending: onboarding layout, toast, bundle row (render
gate). CORE-50 RUNTIME-VERIFICATION MECHANIZED (~15:00, long pass
while designer at work): game/dev/core50_verify.gd = dev-gated
--verify=core50-low|core50-high CLI (audit-pattern: repoints the
Config autoload at an injected settings profile BEFORE wiring reads
it — real settings.cfg untouched; asserts at _ready end that every
mechanizable option landed in its runtime object: effect density/
opacity/flash → EffectLibrary, damage numbers + 3 feedback channels,
3 audio buses mute+dB, hitbox visibility, UI-scale theme, persisted
remap → live InputMap). BOTH profiles are pretester steps — they
differ on every asserted value, so the pair proves options CHANGE
behavior. Lint pins the verify gate line; probe F proves the tester
exe refuses --verify. notes/CORE50_RUNTIME_CHECKLIST.md = the
mechanized-vs-designer-eyes map (render half is one tester-build
pass, checkboxes waiting). EVIDENCE REPORT TOOL LIVE same pass:
tools/evidence_report.py <bundle.zip|session.jsonl> = designer-side
Gate-1 facts (per-session durations w/ last-beat bounding, loadout
speeds, gaps, dev-profile exclusion, contamination scan, summary-code
recompute vs stored — MEASUREMENTS ONLY; the re-engagement
operational definition stays a planning §6 lock). Cross-language
code parity pinned by the WS1-00F-0202-002N vector in BOTH the godot
test and the py selftest; selftest is a pretester step. GATE AT FULL
STRENGTH: 17 fixed steps + 25-row battery BYTE-IDENTICAL + export +
probe = ALL GREEN 12.6 min. M8 engineering now blocked ONLY on
designer answers (comments box) + designer-side items (copy voice
pass, laptop pass, rested human pass, itch publish, recruitment).
DUSK B65 INTAKEN 2026-07-30 (~03:15) — FIRST RELEASE-TRANSPORT INTAKE
(doc 18 §5; sl-0016 blessing): GitHub release
small-cold-coastal-pack-dusk@b65 fetched from tilok1234/WorldForge;
zipSha256 + manifestSha256 + 8-file parity + sourceCommit 4497729 ALL
verified locally BEFORE the drop. Runbook §2 green by exit code (pack
test, porosity diag, boot, determinism smoke). Flood 34739→34641 = 85
scattered cells SEALED, 0 opened, 13 more stranded off-flood (WF
furniture-claims-ground retune; walkable-unreachable stays LEGAL under
WYSIWYG). Porosity pin 44 UNCHANGED — the 44 route cells verified
BYTE-IDENTICAL to the accepted gateway set (no re-pin needed). 24-row
battery ON-MATRIX and reports/ BYTE-IDENTICAL INCLUDING world_walk:
the b65 delta touches no battery path (world_walk re-proof PASS is a
genuine regeneration, mtime-verified, world_builder hash gate on the
new pack). pretester_check itself NOT run this seam — its machine-wide
Godot guard tripped on the designer's editor open on ANOTHER project
(AI_training_lab; different .godot, no cache race) — so the runbook
gates ran individually, same commands + exit codes; re-run the full
gate at the next exclusive seam. Planning lock pinned to b65 +
sync log sl-0020 appended (sl-0004 delivery closed). OPEN: designer
city walk = the acceptance (feel item, theirs).
AUDIO ERA OPENS 2026-07-30 (~04:00, same night): three Tier 1 chat
rulings built same-hour — COMMENTS BOX (options TextEdit →
comments.txt in the bundle + comment_chars stamp; SUPPLEMENTARY by
quiet-lab law, never CORE-54; typing suppresses letter hotkeys AND
gameplay input via HumanSampler.suppress neutral frames — a 't'
mid-sentence cannot reset the run; box-owned pause on focus, releases
only its own pause; Esc = leave-box + resume by design); MUSIC
CHANNEL (fourth bus + options row + [audio] music, core50-asserted
both profiles); MUSIC PLAYER (music_view: playlist queue in listed
order looping the whole set; DUCKS −9 dB under KeyThreats cues via
audio_cue_view.key_threat_cue, fast attack / slow release; duck rides
player volume_db, composing with the user row). RESONANCE FORGE V1
INTAKEN same seam — SECOND release-transport intake (doc 18 §5):
resonance-forge-godot-audio-v1-23a6c659199b, zip sha vs notes +
sidecar, ALL 178 manifest files hash-true, consumed files re-hashed
after copy. RF addon/autoload NOT enabled (no middleware — the game
consumes files through its own machinery). 7 cues from RF's critical
set → audio/cues/ (mapping + rationale notes/AUDIO_CUE_MAP.md;
placeholders retired from the map, kept as recorded fallback); 4
music masters (581 MB WAV) NOT committed — the immutable release is
the archive, shipped audio is ffmpeg OGG q6 (21.5 MB, hashes in the
intake commit); playlist na01→na04. Godot --import pass run (11
sidecars). Gates: boot post-import ERROR-free, settings + feedback
(both extended), smoke, goldens x10, five pack/kit tests, core50
pair — ALL GREEN by exit code; battery structurally unaffected
(bot_runner never loads the main scene, sim untouched — goldens
prove). FULL pretester at next fully-exclusive seam. DESIGNER-EARS
now runnable (the deferred audio pass runs against REAL audio):
eyes-closed classes, in-play feel, cue-mapping + duck taste.
DESIGNER-EYES pending: comments box render. b65 city walk verdict
still unrecorded. ATTACK-SOUND PASS same night (86873a5, designer
ear feedback): player_fire + enemy_fire on ATTACK_STARTED (13
variations round-robin, zero sim change), telegraph_ranged corrected
warning→charge, FIFTH channel AttackSfx (own row + off); designer:
music "sounds good", corrected build "sounds great" (Tier 1,
provisional); NATURAL-TESTING mode chosen — verdicts accumulate in
play. Same seam: .gitattributes byte-exactness pin (f5c9c10),
per-project godot_guard (a4ffbcc), clean audio-era artifacts CUT +
probed (builds/wildshot-322066c-*.zip, 58.7 MB tester).
GATE 1 REWRITTEN — ABSORBED 2026-07-30 (~04:30; ask sl-0023,
planning 593cc27, deck cards staged for rested ratification):
stranger-tester items RETIRED WITH CAUSE from the owed list
(recruitment scheduling, itch testers-channel push, stranger-aimed
onboarding polish); EXPORT PIPELINE + LOCKDOWN stay a standing gate.
NEXT TARGET = THE LOOP MILESTONE (unguided b65-town→boss run, loot
that matters, real death cost, immediate retry pull; exit = fun for
the designer daily for a week; feel/stakes over polish; test scenes
accrete into content). Digest rows CORE-53/55 + SPEC-A + tripwire +
quiet-lab updated with ruling provenance. FLAGGED planning-side in
the completion line: docs/08 CORE-53/55 rows + docs/12 Gate-1 prose
still carried pre-rewrite text (TRUTH-UP SINCE LANDED planning-side —
amendment rows + docs/12 supersession banner verified 2026-07-30 late;
flag cleared at the b72 intake). Loop-assembly
engineering starts from designer direction (talk-before-build; the
bar card is theirs to word).
LOOP V1 (L1 SKELETON) ENGINEERING COMPLETE 2026-07-30 (~06:45; ask
sl-0025 / docs/19 §3; commits 86459d1→f7b0be6): SERIAL 13 —
PlayerState gold/xp(within-level)/level/max_hp/max_mana/per-frame
weapon tiers 1–6/unique mask; ActorState armor_tier; STREAM_LOOT
(drawn ONLY by death-sweep drop rolls — loop_test PROVES rng_enemy
untouched by loot); serialized ground drops; THE damage path grew
flat armor mitigation (floor 1; §2.11 schedule bypasses by contract)
+ kill awards (XP→level-ups, lean growth + full refill [T]; ONE fixed
rng_loot draw sequence per kill); LootStep last in step order (TTL +
walk-over pickup, upgrades-only auto-equip); tier×level damage in the
fire path with IDENTITY DEFAULTS — proof_rusher/husk reproduced
BYTE-IDENTICAL post-change; goldens regenerated deliberately +
verified 10x. Seven defs' drop tables filled (danger-proportional,
all [T]; data/progression.tres = THE one tuning file). CHARACTER:
user://character.json OUTSIDE the sim — permadeath TOGGLE at creation
only (docs/19 ruling 1); normal death = 25% [T] carried-gold cost +
the run-back, equipment never taken; hardcore = file deleted, T lands
on the creation screen; applied setup-phase BEFORE the recorder
snapshot; heartbeat/quit/death saves (never harvests while dead — the
cost-applied profile is protected). Death rides the Law-8 recap +
one-key retry. SURFACES: LOOT band 15 (assertions extended),
drop_view (shape by kind, tint by tier [T]), HUD lv/xp/gold + three
frame tiers + armor, LEVEL-UP/UNIQUE toasts. GRADIENT v1 hand-
authored on the b65 geography (every spawn flood-reach-verified; the
town component measures EXACTLY manifest flood 34641 — free pack
cross-check; wf data peeked, not consumed — intake deferred per
spec): rings ~20-30 / ~37-53 / ~64-94 tiles, the KING at 105. BONE
RELIQUARY KING live (docs/19 ruling 4): the Warden kit at 900 HP [T]
(floors 594/297 pinned in loop_test), roster index 7 append-only,
48px sheet via tools/import_boss_actor.py → res://assembler_boss/
(assembler-library SECOND INSTANCE — manifest-driven cell 48, REAL
cast/death rows, no aliases; render scale only, the 24px-hurtbox
honesty note stands), Reliquary Coil placeholder unique (35%
independent roll, tier-6-slot model [T] until designer specs).
PROOFS: loop_ring1/2/3 + proof_brk_site ALL PASS 3.0 ability-off
seeds 1,2,3 — TWO layout iterations, never weakened (v1 failed
seed-identical convergence: kiting merged clusters → spaced beyond
kite-drift; ring3 also recomposed 3-pressure→2-pressure pulls, final
ZERO hits). Battery 24→28 rows; loop_test joined the fixed gates.
LEDGER #16 OPENED (replay headers lack the character block — profile
replays REFUSE verification honestly; proofs unaffected).
data/scenarios/loop.tres = THE RUN ("THE LOOP" picker row). L2 =
daily-play tuning; the bar clock starts when the designer calls the
skeleton judgeable (weekly GIFs fall out free). DESIGNER-EYES/PLAY
pending: creation screen + drops/HUD render pass, THE RUN itself,
every [T] rate.
B71 OVERWORLD INTAKEN 2026-07-30 (~13:05; re-issued delivery sl-0034
— b70 retired UNINTAKEN, never fetched): wildshot-overworld-pack-dusk
@b71 via the release transport, zip + manifest + 8-file parity +
sourceCommit 6363271 verified pre-drop; staged blobs byte-true.
FIRST STYLED PACK: path values {0,1,2} (1784 city-lane band cells,
330 trail cells) — the game chain reads NO semantic path values, so
the 0/1/2 contract is ACCEPTED with zero code change. CLIFF LINE
CONFIRMED GAME-SIDE: zero path-band cells on rock AND zero walkable
cells at any terrace level >= 1 — the pack ships no terrace layer, so
the adapter-v4 quantization was REPLICATED from WF resolve.ts AT the
source commit over the intaken grid (1456 terraced-peak cells, all
non-walkable; NOTE: the chunk 'elevation' layer is raw field
elevation 141–896, NOT terrace level — the first check used it
naively and was caught + redone; lesson for future styled intakes).
Tops stay blocked BY DESIGN; the tops+ramps arc is designer-pending —
nothing "fixed". Lands BESIDE b65 (which world loads is scenario
routing; world_walk re-proof BYTE-IDENTICAL — b65 untouched). Addon
validation green: flood recompute 45184 == manifest; spawn = harbor
capital 109,182 (matches b70's manifest). Porosity: 60 route cells,
ALL reading as two-wide gateways/gatehouse footprints — PINNED 60 for
this drop (per-pack doctrine; b65 stays 44). Boot + smoke green.
repro_*.wsr SERIAL-13 regen noise swept into the intake commit (was
dirty-stamping exports). Lock pin added beside b65's; completion
line appended ref sl-0034.
B72 OVERWORLD INTAKEN 2026-07-30 (~23:55 local; delivery sl-0035 —
roads-only delta, IN-PLACE SUPERSEDE of b71 at the same path; b71's
lock pin RETIRED by per-pack call, its release stays immutable
archive): wildshot-overworld-pack-dusk@b72 via the release transport,
GitHub digest + zip + manifest + 8-file parity + tag→sourceCommit
bbc10cdb verified pre-drop; staged blobs re-hashed byte-true;
normalized-recipe.json byte-identical to b71 (same recipe, newer
generator behavior — the delta is generator-side). EVERY ROAD IS A
BAND LINE NOW: path census value-2 1784→2166 (+382 — country roads
carry the band), trails 330→361; the 0/1/2 acceptance holds with ZERO
code change. Addon flood recompute 45202 == manifest (independent
Python BFS agrees); spawn 109,182 unchanged (harbor capital).
POROSITY RE-PINNED 60→64 deliberately: exactly +4 route cells (zero
removed) = two two-wide landmark footprints (structure.ruin
182-183,190; structure.stone_circle 249-250,116), both on-flood, no
band beneath — reads as sl-0035's severed-landmarks fix; WYSIWYG-
legal (b65 keeps 44). CLIFF RE-CONFIRM: the adapter-v4 replica was
CALIBRATED on the b71 blobs first (reproduced the recorded 1456
exactly) then run on b72 — relief IDENTICAL (1456 = {169,820,467} by
level), zero path-on-rock (any value), zero walkable at terrace >= 1;
the carver grading carries forward exactly as delivered. Boot + smoke
green; FULL pretester ALL GREEN 19.4 min (17 fixed steps + 28-row
battery byte-identical incl world_walk + export + lockdown probe).
Nothing routes to the overworld yet; mechanical intake only, NO feel
verdicts (designer post-shift). Lock game pin b71→b72; completion
line ref sl-0035.
CROSSHAIR SCALE PASS 2026-07-31 (~00:10 local; ask sl-0042,
taste-rule pending on screen): the hardware cursor never inherited
the integer viewport stretch — an 11-physical-px speck at 2-3x
content scale (designer standing complaint). main.gd now scales the
kit cursor nearest-neighbor by the live integer content scale
(floor-min of window/base, min 1 — the stretch's own factor), kit
hotspot 5,5 re-centered to the scaled pixel, re-applied on window
size_changed (fullscreen/resize tracked). Pack assets untouched
(manifest-hashed); render-only — aim reads viewport mouse, zero
mechanics/hurtbox change. Lint (main.gd pins) + boot + smoke green
(hashes unchanged). If contrast still fails after sizing → upstream
kit ask, never a hand-edit.
ROAD LAYER VERDICT 2026-07-31 (~01:45 local; ask sl-0047): the render
chain was NEVER broken — five probes (tres alignment 81/81, tmj
census 2570/2570 resolved, runtime build 2570 cells set src 59
correct coords, pixel decode 32/30/32 opaque tiles, RENDERED
screenshots showing band roads on screen) prove b72 roads draw
end-to-end; reports/road_render_audit_b72_*.png committed. The
designer's bare-street screenshots were THE LOOP = the B65 world,
which carries NO city-band data by upstream design (its road layer =
943 dirt-path trail cells, placing all along — pre-band corridors
are carved ground, not road cells). The real gap: NOTHING ROUTED TO
b72. FIX (data-only): scenarios/overworld_walk.tres — "Overworld
Walk: harbor capital (dusk b72)" picker row (auto-enumerated), pack
spawn 109,182, zero enemies (pure look-walk for the taste-rule);
world_walk untouched (battery pins stand). PLUS world_builder now
prints per-layer placement counts at every load (suspect-c
instrumentation made permanent — a zero-placement layer is loud,
never silent). roadTypesLegacy: grep-proven consulted NOWHERE in
game code (manifest data only; importer honors fam.tiles, which are
fully populated post-restoration; tres carries all road tiles) —
nothing to un-honor game-side. Format+lint+boot+smoke green, smoke
hashes unchanged; battery untouched. Designer taste-rule on the
overworld look = theirs, on screen.
B76 OVERWORLD + TILEFORGE 9B8B2A2 PAIRED INTAKE 2026-08-01 (~00:40
local; delivery sl-0061 — PAIRED DROP + CONTRACT CHANGE, in-place
supersede of b74; b75 superseded pre-intake, never landed; b74/b75
releases stay immutable archive): BOTH releases fetched by tag +
verified pre-drop (WF zip = GitHub digest = logged 98c3170d, manifest
8a838922, 8-file parity, tag→4291f796 — the pack manifest carries no
sourceCommit field, tag target IS that check; TF zip e09ea40e =
digest, tag→9b8b2a2ebf, 186 files); staged blobs re-hashed byte-true
after every copy (pack 9 / raw drop 186 / consumed 185). PAIRING
CROSS-CHECKED: the pack's tileforge block == the TF release's own
bytes (packageId dusk-9b8b2a2-seed103991 = theme+commit+seed;
manifestSha256 c8b11de5 == sha256 of the package's manifest;
packageSha256 == the TF zip sha). SCOPE REPRODUCED INDEPENDENTLY from
the immutable b75 archive (re-fetched, 25f9d5c1 verified): world.json
byte-identical modulo exactly 6 identity fields, walkability
byte-identical, tmj delta = 5 inserted tilesets (+296 tiles:
gravelway/flagway/corduroy/threshold/roadjoint) renumbering 57,790
cells identity-preservingly + EXACTLY 47 road-layer joint
substitutions (31 street_paving + 16 dirt_path), zero anomalies. THE
ARCHITECTURAL ACT: world_builder resolves the tileforge package BY
THE PACK'S PIN from the new TILEFORGE_PACKAGES registry —
res://tileforge (the M1 ae1eecb import) stays BYTE-UNTOUCHED (b65/THE
LOOP render unchanged; the legacy default rebuild proven
byte-identical), dusk-9b8b2a2-seed103991 imported BESIDE it at
res://tileforge_packages/ (raw drop
assets/tileforge/tileforge-dusk-complete-9b8b2a2; consumed instance
minus the inert Unity .cs; tres 87 sources built by the package's own
shipped importer via run_import --package= — the driver grew the
param, default path unchanged; export include filter + .gitattributes
-text pin extended). Identity refusal stays loud (pin + available
ids). PATH 0..3 ACCEPTED ZERO-CODE (grep re-proof: the chain reads no
semantic path values — no 0..2 pin ever existed; sl-0043 precedent
holds): pack census {0:63278, 1:230, 2:567, 3:1461}; the delivery's
570/229/1466 are WORLD-side counts — the world→pack seam (same class
as world flood 45063 vs pack flood 45156) accounts the −3/+1/−5,
pinned by the b75 archive diff (1461 predates b76). POROSITY 60→60,
composition ±2, every cell typed (sl-0052 precedent): ADDED
(70,127)+(71,127) = poi.crypt [70,126] two-wide pass door (walkable
ss under solid SS, on-flood); REMOVED (66,109)+(67,109) = b74's
poi.witch_circle door (footprint withdrawn, cells stay open
walkable); b74's two off-flood route cells (15-16,29) reconnected
(off-flood 11→9); pin 60 stands deliberate, b65 keeps 44, diag exit 0
both. CLIFF LINE: the adapter-v4 replica rebuilt AT 4291f796,
calibrated on b74 = the recorded 1456={169,820,467} EXACT; b76 =
1447={170,810,467} — first histogram movement since b71, typed to 30
rock-edge material repaints (rock 2554→2548, b75 re-dressing); HARD
INVARIANTS EXACT: zero band-on-rock (any value), zero walkable at
terrace>=1; the tmj's own cliff layer places 1447 = replica agrees
with the shipped render. RENDER PROOF MECHANIZED: b76_picker_probe
(supersedes b74's) builds BOTH worlds in one run — b76 via the new
package (166,150 placements; road 2301 cells, EXACTLY 47 from the
road_joint source: the joints draw; the GAME-GUIDE 2.4/2.8 roadJoints
rule is needed nowhere game-side — tmj-driven rendering gets them
free as delivered) AND b65 via the legacy import (170,207). Picker
row relabeled b76; boot clean; FULL pretester ALL GREEN 16.9 min (17
fixed steps + 28-row battery byte-identical incl world_walk + export
+ lockdown probe). roadTypes 5-8 = unused vocabulary pending their
own designed round. Lock: b74 game pin superseded in place by b76 +
NEW game←tileforge pairing pin; sync log sl-0064 (sl-0063 was taken
by a concurrent planning entry between routing and close). NO feel
verdicts
(mechanical night intake); the designer's on-screen joints/street
look = the open taste line (the sl-0052/sl-0053 arc continues on
b76).
B77 OVERWORLD INTAKEN 2026-08-01 (~01:55 local; delivery sl-0066 =
the sl-0063 prop-walkability arc; NORMAL in-place supersede of b76,
SAME tileforge pin — sl-0064's per-pin registry holds, zero TF work):
zip = GitHub digest = logged c9083012, manifest 5166341a, 8-file
parity, tag→1a20bd22, asset byte-size exactly b76's (fixed-width
walkability flips); post-copy re-hash byte-true. WALKABILITY-ONLY
CONFIRMED GAME-SIDE: tmj/map-data/recipe/minimap byte-identical to
b76 (git shows exactly 4 pack files changed), slice differs only in
its generation-identity echo, world.json = 3 generator identity
fields, prop/material/elevation/path chunk layers byte-identical
(the density-kept claim reproduced). DELTA 100% TYPED BY SPECIES:
1044 grid cells OPENED, zero sealed, zero flood cells lost — stump
509 / fallen_log 490 / bone_pile 44 / loot_pile 1, the four sl-0063
carpet conversions exactly, zero cells without a prop; flood
45156→46493 (+1337 = 905 newly-walkable + 432 unlocked
stranded-pocket cells — the designer's 'getting blocked' pockets
joining the flood; independent lsb-first BFS exact; 139 opened cells
stay legal walkable-unreachable; world-side 903/425 vs pack 905/432
= the established world→pack seam). POROSITY: the route-cell set is
IDENTICAL — 60→60, zero adds/removes (prop flips touch no structure
cells), pin 60 stands with NO re-pin needed; off-flood route cells
9→6 — the dock trio (194-196,240) reconnected by unsealed pockets;
b65 keeps 44; diag exit 0 both. CLIFF CARRIES: material + elevation
byte-identical (terrace field 1447), zero opened cells on rock —
zero band-on-rock and zero walkable at terrace≥1 both hold. THE ONE
sl-0066 GAME-SIDE CHECK — PROVEN ON SCREEN, MECHANIZED:
tests/worldforge_pack/canopy_render_probe.gd (committed, windowed)
replicates main's exact construction (world_builder output +
sort_layers reparented into a y-sorted ACTORS-band space + the
player as an ACTORS-band ranger sprite); at walkable crown cell
(110,176), 0/8525 screen pixels inside the crown tile's opaque mask
differ between ranger-present and ranger-hidden frames — the
props-overhang crown draws OVER the player with zero leak-through —
while 4075 out-of-mask pixels differ (the player renders where crown
art is transparent); evidence committed
reports/canopy_render_audit_b77_{under,reference}.png (the under
shot: ranger's lower body swallowed by foliage, control ranger fully
visible on open grass); ACTORS 30 < CANOPY 32 stays boot-asserted
band law. b77 ships 2,352 reachable walkable crown cells —
walk-under is live at scale. Picker row relabeled b77 +
b77_picker_probe PASS (both worlds resolve their pins; road 2301
cells / 47 joints carried — tmj byte-identical). Boot clean; FULL
pretester ALL GREEN 14.3 min (17 fixed + 28-row battery
byte-identical incl world_walk + export + lockdown probe). Lock: b76
game pin superseded in place by b77 (the game←tileforge 9b8b2a2
pairing pin carries unchanged); sync log sl-0067. NO feel verdicts
(mechanical intake): the DESIGNER'S NAVIGATION WALK is the
acceptance per sl-0066's own terms — the 'getting blocked' complaint
is the test. sl-0065 (dev map overlay ask) was not in this session's
paste — open, untouched.**
DEV MAP OVERLAY LIVE 2026-08-01 (~03:15 local; ask sl-0065 executed
hands-free; game 87bdc15; sync log sl-0069): game/dev/map_overlay.gd
— N cycles off -> corner minimap (96 px, dimmed, above the hints
line; Law 6 even in dev) -> fullscreen map (dark backdrop, integer
nearest upscale, fractional only if the map outsizes the viewport).
Texture = the active pack's OWN minimap.png raw (zero new art;
exports ship pack dirs wholesale — resolve_src fallback covers built
dev exes). White dot + black ring at the live sim position; facing
tick = the current free-aim vector, re-normalized after map scale so
a non-square minimap cannot skew it. PACK-RELATIVE: ratio = actual
texture / actual grid (b65 + b77 both 256x256 = 1 px/cell; nothing
assumes it) — every pack-routed picker world gets the map, THE LOOP
included (b65 ships minimap.png — consumer-test bonus find); arena
scenarios get NO node (hidden by absence: N inert, hint absent — the
hints line lists map only when the overlay exists). TWO-PROFILE LAW
console-style: gated construction + gated toggle in main.gd;
lockdown_lint pins grown (MapOverlay ctor sites = the one gated main
block + the two tests/dev_map harnesses, tests/* tester-exclusion
already pinned; map_toggle input line carries the gate) and
NEGATIVE-TESTED live (ungating either -> exactly the 2 findings,
then re-green). Key N (no-F-row law), remappable action map_toggle.
NEW FIXED GATE tests/dev_map/dev_map_test.gd — 18th fixed step + CI
Linux row: minimap present/loadable/uniformly grid-proportional for
every pack scenario, spawn maps in-bounds, mapping-math pins,
load-refusal contract (main.gd cannot compile under --script — it
reads the Config autoload — so the test replicates the two-line
routing; lint + boot pin main's side; lesson recorded). RENDER
PROVEN (headless sees no render bugs): windowed
tests/dev_map/map_overlay_probe.gd committed
reports/dev_map_audit_b77_{corner,full}.png — dot verified at the
harbor-capital spawn by eyes on the PNGs. RESOLUTION: 256 px reads
adequate at content scale — NO WF ask opened; the designer's
on-screen verdict is the rule (if it fails their eyes, THAT becomes
the WF ask — upscale hacks stay banned). Zero sim change (smoke
hashes unchanged); boot clean; FULL pretester ALL GREEN 17.1 min (18
fixed steps + 28-row battery byte-identical + export + lockdown
probe on REBUILT artifacts). Part II player map stays deferred (doc
13 §3); the overlay is throwaway-by-design and graduates only
through that designed round. NO feel verdicts (night engineering);
the designer's first N-press on the overworld walk is the
acceptance.**
PINCH DIAGNOSIS DELIVERED 2026-08-01 (~04:15 local; ask sl-0070
executed hands-free, NO FIXES; game e991118; sync log sl-0072 — the
planning commit header misnames it sl-0071, record-fix d17fc25:
sl-0071 was taken concurrently by the deck sweep 283a4e9; the
write-time id guard placed the entry correctly): the b77 walk
finding ("visual gaps between solid props refuse passage") is typed.
DELIVERABLES: tools/diag_pinch.py (committed census baseline — the
measure any fix lever is judged against), tests/pinch_probe/
pinch_move_probe.gd (real Kinematics at TERRAIN_RADIUS 0.25, 3.0
t/s), reports/pinch_diagnosis_b77.{md,json}. Species mapping
cross-checked EXACT vs the sl-0067 intake (carpet 509/490/44/1).
CENSUS: 2,003 corner-touch pinches (diagonal solid pair, both shared
orthos open — zero-width for any circle); 1,901 prop-involved; 1,143
with both open sides on the flood (811 wild / 332 settlement). ALL
1,143 are SHORTCUT-denials — component-boundary count is ZERO, so
opening any changes no connectivity, only path length (lever A is
flood-safe by construction). Detours: 6/6/102 min/med/max; 22 sites
force >40 tiles. 1-wide lanes: 3,635 cells (2,296 prop, on-flood).
TYPING: DATA-closed EMPTY — zero causeless solids after full
attribution (lessons: 173 "mystery" grass solids were FENCE cells —
read the fence chunk layer; 752 were wetland BOG, de-facto solid
terrain, 22/1082 swamp cells walk). GEOMETRY-closed = the whole
complaint class. FEEL-closed empty for the player body. MOVEMENT
(probe on shipped kinematics): corner-SLIDES around lone corners (24
vs 15 open ticks through the zone, then free), 1-wide lanes at
open-ground speed (90 vs 90; +4.4% misaligned), honest HARD-STOP
only at zero-width — exact double-tangency wedge rest, late-60-tick
motion 0.0000, zero shiver. No movement bug; the stop IS the
geometry. LEVER PICK = DESIGNER'S (facts in the report): A = WF
clearance re-gen (sl-0063's recorded follow-up; relocate-never-
delete; connectivity provably unchanged; pain order 22>40 → 94>20 →
dense regions); B = corner-sliding ALREADY SHIPPED, cannot open
zero-width; C = sub-cell colliders, breaks the WYSIWYG/flood
contract, deliberate act only. No WF ask opened (the pick precedes
upstream work). CONCURRENT planning sweep sl-0071 (deck deal) landed
mid-session: two new pillars, Gate-1 rewrite RATIFIED, loop frame
RATIFIED, crosshair RATIFIED+closed, eyes-closed audio evidence
CAPTURED planning-side — the notes/AUDIO_CUE_MAP.md review slot now
OWES the write from that evidence (queued, unrouted this session).**
CROSSHAIR STYLES + SIZE LIVE 2026-08-01 (~05:30 local; ask sl-0077
executed hands-free; game 4b4c6ec; the designer's deck-note on the
ratified crosshair card): ui/crosshair_styles.gd — style 0 "classic"
= the ratified kit cursor VERBATIM at native 11 px (byte-identity is
a mechanized test pin); styles dot / ring / cross-x drawn at request
time in the kit's OWN two colors sampled from its pixels (kit
re-drop re-skins all styles; silhouette-only differentiation,
CORE-50 + doc-13 cursor spec: odd, lit true-center, light core + 1px
dark rim — all mechanized per style x size). Size ladder 9/11/13/15.
Two options cycle rows, BOTH profiles (player-facing, ungated),
[ui] persisted, applied live via the sl-0042 content-scale path
(general hotspot = true center; ratified 5*k+pad reproduced at 11).
ZERO SIM IMPACT PROVEN: smoke hashes byte-identical pre/post.
tests/crosshair/crosshair_styles_test.gd = 19TH FIXED STEP + CI row,
writes committed evidence reports/crosshair_styles_preview.png (four
silhouettes distinct at every size, checked by eyes). core50_verify
grew both rows on both profiles; settings test round-trips the keys;
checklist rows added. RIDER DONE: AUDIO_CUE_MAP eyes-closed slot
carries the 2026-08-01 deck evidence line (seven classes
distinguishable) — the sl-0071 queued hand-off discharged. GATE
INTERRUPTED ONCE, honestly: the designer's play window blocked the
pretester (guard exit 2); clock stopped for the wait, designer
closed it, gate re-ran ALL GREEN 16.8 min (19 fixed + 28-row battery
byte-identical + export + probe). DESIGNER-EYES pending: the four
styles on screen (preview sheet committed). Icon Tier-0 stays
sequenced after the Loop acceptance per the ask's own note.**
THE FIT RULE LIVE 2026-08-01 (~06:30 local; ask sl-0078 — the
DESIGNER-DIRECTED COLLISION CHANGE, deliberate design act invoked;
game 549e587; SERIAL 13→14, next bump 15): "if there is more then
enough for the character sprite to go between it it should be able
to go between it" — BOTH HALVES BUILT. (1) PROP DISCS:
game/arena/prop_colliders.gd measures every solid prop cell's OWN
sprite base at load (lowest-opaque 6px band → width + centroid; THIN
0.85 per "when in doubt, thinner"; bounds 0.06–0.42) — b77 opens
7,560 prop cells (236 tiles measured), b65 opens 6,996 (252): THE
LOOP + world_walk carry the rule. Cause guards keep structures/
fences/cliffs/water/rock/bog full-cell (round-1 scope). (2) PLAYER
BODY: PlayerMove.TERRAIN_RADIUS 0.25 → 0.15625 = the ranger's FEET
exactly (frame-0 rows 19-22 = 10 px = 5/32 t, art-derived, not
tuned). HURTBOX 0.35 BYTE-UNTOUCHED (combat-safety addendum; dodge
fairness intact). PROJECTILE COHERENCE (addendum accepted): shots
collide with walk_grid + the same discs — one truth for walking and
shooting. ARCHITECTURE: SimWorld.walk_grid + prop_discs (defaults =
bitgrid/{} — arena worlds byte-unchanged); the bitgrid stays the
CONSERVATIVE FLOOR (enemies grid-walk it, floods/porosity/spawns/
upstream contracts keep their meaning; b77 stays current, ZERO
upstream work); ONE attach point in ScenarioLoader = main/DodgeBot/
soak/replay-verify walk identical collision by construction;
Kinematics grew disc contacts in the ONE shared slide (curved
clamps, strict-tangency rest, corner slip curls around trunks;
empty dict = byte-identical enemy path). DODGEBOT: candidate walks
on the true model; threat projection now TERRAIN-AWARE (shots die
on walls/discs in the model — the ttl-only over-estimate cost real
dodges at fit-rule margins); POSITIONING heuristics deliberately
stay conservative on the bitgrid — a pocket the sprite fits is NOT
a pocket to live in (the 0.35 hurtbox cannot dodge inside
sprite-width gaps; loop_ring2 parked in a b65 thicket and was
clipped t434 by the ringer radial at 0.011 — the forensics run is
the record). ONE LAYOUT ITERATION under never-weaken: the ring2/
loop ringer spawn left the thicket lip it predated (195.5,129.5 →
199.5,126.5, mirrored loop.tres + proof; re-proof 0 hits, near
0.130). MECHANIZED ACCEPTANCE SHADOW (tests/pinch_probe/
fit_rule_probe.gd): the census desert red-line lane CROSSES t=51,
the worst tree-band pinch (detour 62) CROSSES t=23, while
legacy-0.25 AND the enemy model stay blocked at both — the
asymmetry is proven, the zero-width class opens exactly where art
shows ground. CONSEQUENCES DISCHARGED: goldens re-recorded +
verified x10; smoke PASS (wall floor self-derived 1.15625 — the
constant-derived assert doing its job); FINAL BATTERY 28/28
ON-MATRIX with forest_walk [primary] RE-PINNED FAIL→PASS (the
deliberate-change signature; rusher/first_contact primary stay
FAIL; MUST-FAIL canary still FAILS); stale repro leftovers of
already-resolved failures swept from reports/. FULL pretester ALL
GREEN 16.9 min (19 fixed + 28-row battery byte-identical + export +
lockdown probe on rebuilt artifacts). NEW TACTICAL REGIME recorded:
prop thickets are walkable-but-shot-exposed — enterable cover that
sheds chasers but not projectiles; the L2 daily-play read on it is
the designer's. ACCEPTANCE = the designer's walk along their own
three red-line screenshots; game relaunched for them at close. NO
feel verdicts (engineering session).**
ICON PACK V0.1 INTAKEN 2026-08-01 (~11:45 local; delivery sl-0083 —
raw drop, boss-pack precedent, NO WIRING by ruling until the Loop
acceptance run sl-0082): Forge_design_component_review.zip sha256 =
the delivery record verified PRE-DROP (2,348,689 bytes); vendored
assets/wildshot-icons-proto_0.1.0/ — 479 files re-hashed byte-true
from disk after staging: 470 glyphs + 6 CORE-50 proof sheets +
atlas.json/atlas.png + manifest.json (census note: the delivery
one-liner omitted atlas.png; same verified bytes, recorded for
exactness). Census reproduces planning's docs/21 assessment
EXACTLY: 470 unique ids all 16x16, manifest parity perfect both
directions, palette dusk/15 roles, kinds item 216 / skill 90 /
collect 70 / input 20 / map 16 / access 15 / hud 12 / stat 9 /
quest 8 / emblem 7 / frame 4 / currency 3; atlas frames == the id
set, atlas.png == its declared 10x47 16px layout. PASSPORT beside
the drop (assets/wildshot-icons-proto_0.1.0.passport.json): tool
provenance (designer icon forge, other-PC build — tool-source push
stays owed, the b7eae05f lesson), zipSha256, per-file sha256s for
all 479 files (the manifest ships none — the passport is the byte
pin). FIXED GATE tools/validate_icon_pack.py = 20TH FIXED STEP +
CI lint row (assets/** -text keeps checkouts byte-exact): manifest
contract (exists/decodes/16x16/unique ids/glyph parity both
directions/atlas coherence) + passport hash parity; NEGATIVE-TESTED
(corrupt byte + deleted sheets → exit 1, both findings named). Boot
clean; pretester ALL GREEN 3.5 min this seam = 20 fixed steps +
export + lockdown probe with the battery DELIBERATELY SKIPPED (zero
sim change — assets/ is .gdignore'd; smoke + goldens x10 in the
fixed steps prove hashes unmoved; full 28-row gate rides the next
exclusive seam). Lock pin added planning-side (first
game←icon-forge pin); sync log sl-0085. NOTHING renders the icons
(the sl-0077 Tier-0 sequencing note stands). Designer-side
unchanged from sl-0083: tool-source push owed; deutan-sheet eyeball
rides the wiring round. NO feel verdicts (hands-free mechanical
intake).**
CI LINT REPAIR same seam (~12:05 local; found watching the icon
row's first CI run): the ubuntu lint job's gdformat step had been
RED since the b76/b77 seams — the b76 paired intake created the
per-pin consumed tree tileforge_packages/ (generated, byte-pinned)
and the format exemption never grew with it (3 package .gd files),
plus the b77 picker probe shipped unformatted (1 authored file).
Nobody noticed: the session gate is the pretester, which does not
run gdformat, and the Windows CI jobs queue for hours. FIX: ci.yml
exemption extended to tileforge_packages/ (never hand-format a
consumed package — it is byte-pinned); b77_picker_probe.gd
formatted (one print reflow, zero logic); local check 126/126;
pretester -SkipBattery re-run ALL GREEN 3.2 min (smoke + goldens
x10 hashes unmoved). POST-PUSH VERIFIED (run 30694311402): lint job
SUCCESS with the icon row EXECUTING on a fresh Linux checkout — the
assets/** -text chain + passport hashes + pillow decode proven
end-to-end; the gate's CI half is genuinely live. Handoff gotcha
#26 added (check the lint job after every push — it is the fast
signal; grow the exemption with every generated tree).**
WINDOWED-CLOSE TEARDOWN CLEANED 2026-08-01 (~12:35 local; hands-free
engineering, zero sim change): every windowed close (artifact boot
checks in the export step + lockdown probe, and the designer's own
play windows) had been printing shutdown noise — ~ImageTexture
"RenderingServer::get_singleton() is null" + "2 RIDs of type Texture
were leaked" — invisible to every headless gate (headless
DisplayServer no-ops the cursor path; all 15 project-mode gate
commands proven signature-free by solo full-stderr sweep; emitters =
dev artifact, tester artifact, windowed project boots, all exit 0).
TYPED BY MINIMAL PROJECT on the pinned binary
(4.6.2.stable.official.71f334935): ONE Input.set_custom_mouse_cursor
call leaks exactly 2 Texture RIDs at exit — two engine holders
outlive RenderingServer (one destructs late = the ERROR, one never
destructs = the silent second RID); replacement applies add nothing;
null-clear exits clean. Engine retention, not a game reference leak.
FIX = LIFECYCLE, NOT SUPPRESSION: main releases the cursor at
NOTIFICATION_EXIT_TREE (tree teardown precedes server teardown on
every quit path; T-reset reload re-applies via the style sentinel).
Every other ImageTexture audited node/scope-held (map_overlay,
sphere fallback, assembler test) — freed with the tree by
construction; no static caches, no autoload textures, no workers.
VERIFIED: gdformat + lockdown lint clean; pretester ALL GREEN 3.3
min on rebuilt artifacts (20 fixed + export + probe); 15/15
five-boot matrix (dev/tester/project windowed) exit 0 with ZERO leak
signatures; reports/ git-clean (proof outputs untouched; bot_runner
never loads main.gd — battery provably unaffected, SERIAL stays 14).
Windowed closes are silent now — remaining stderr is the
RealtimeDriver's designed slew telemetry. Gotcha #27 recorded (sweep
solo with full stderr, characterize in a minimal project before
touching code, fix lifecycle — never filter stderr).**
NPC SLICE ROSTER INTAKEN 2026-08-01 (~12:50 local; delivery sl-0089 —
raw drop beside the other assembler packs, NO WIRING until slice
build post-Loop-acceptance): wildshot-npc-slice-v1@bf6269c fetched
by tag from the ASSEMBLER'S FIRST RELEASE; GH computed digest ==
local sha256 == the delivery record (301,736 bytes); tag → bf6269ca
= the assembler main tip (compare IDENTICAL) and the manifest's own
provenance block (sl-0045 publish gate) claims cleanPushedSource at
the same commit — independently confirmed, the b7eae05f class
closed end-to-end and exercised from the consumer side for the
first time. 70 files staged (32 character sheets + 32 regen recipes
+ library + NPC_BRIEF + README + review pair). HASH DOCTRINE
INVERTED vs icons: the manifest SHIPS per-file sha256s — 69/69
VERIFIED at staging (not generated) + 32/32 character-entry
cross-checks; the passport pins only manifest.json + the verified
provenance. FIXED GATE tools/validate_npc_pack.py = 21ST FIXED STEP
+ CI row (manifest pin, provenance, shipped-hash parity both
directions, unique ids, 480x96 sheets in the 20x4 layout — 24x24
logical at exportScale 1 — binary alpha, recipes/library/
contact-map parse); NEGATIVE-TESTED (corrupt sheet + deleted recipe
+ edited manifest → exit 1, all three named). ROUTED SCALE CHECK
REPORTED, zero changes: FULL consistency with the enemy-pack
consumption — 24px @1x == cell 24 × export_scale 1, same direction
order down/left/right/up, same rows=dirs / cols=anim-spans
semantics (the exact frame_contract geometry assembler_library
derives); NPC anims SUPERSET with real cast/death rows (the
library's cast→attack / death→hurt aliases become real for NPCs);
wiring-time work = manifest-schema translation only (character-pack
v3 vs frame_contract; small adapter or third library instance).
Boot clean; pretester ALL GREEN 3.1 min (21 fixed + export + probe;
battery deliberately skipped — zero sim change, smoke + goldens x10
hashes unmoved; full gate rides the next exclusive seam). Lock pin
added (second game←assembler pin); sync log sl-0092. RIDER
DISCHARGED BY CONFIRMATION: the docs/08+12 truth-up flag already
carries its inline cleared annotation (b72 intake) — no stale flag
stands, no edit; the milestone tail reflects the loop era.
Designer-side per sl-0089: approval [P], on-screen taste rides
slice wiring; watch-items (named-vs-villager blur → quest markers;
dark-outfit dusk contrast → one-field regen) ride the wiring round.
NO feel verdicts (hands-free mechanical intake).**
DUSK CONTENT PACK INTAKEN + THE OVERWORLD REFERENCE PASS AUTHORED
2026-08-01 (~14:20 local; delivery sl-0093 — docs/20 step 1, both
halves one seam; REFERENCE ONLY, no importer, no sim consumption):
wildshot-overworld-pack-dusk-content-c0bf28638648 fetched by tag
from world_filler (GH digest == local sha 13e0759d... == the
record; sourceCommit 6be201e contained in wf main; manifest sha ==
the release notes == the artifact-id's own prefix). 8 files
vendored; the manifest files table (4 payload sha256s) VERIFIED at
staging; passport pins manifest + 3 renders. B77 BASE PAIRING
VERIFIED BOTH IDENTIFIERS (generationIdentitySha256 bd4b9317... ==
the vendored generator block; base.artifactSha256 == sha256 of the
vendored world.json 32f9e741...; format 8; 256x256) and MECHANIZED
as a loud refusal in tools/validate_content_pack.py = 22ND FIXED
STEP + CI row (also pins the EIGHT designer locks at exact cells,
rule census 112/11/4, 9189 territory cells, the 41-failure honest
record, 23 unbound anchors, report 9/9 gates); NEGATIVE-TESTED.
THE REFERENCE PASS: notes/OVERWORLD_REFERENCE_PASS.md = the step-3
importer-spec input (brackets Green 1-7 / Dry 8-15 / Wet 16-22 /
Snow 23-30 per sl-0087, zone=level flat tiers, wf dangerBand
deliberately unused; vocabulary marauder→rusher, prowler→husk,
night_shade→leadshot [nightOnly recorded], mire_creeper→
blightcaster, frost_wraith→ringer; boss identity reserved for the
designer's lore act). FIVE picker scenarios on REAL pack site cells
(all 24 authored cells walkability-verified): overworld_green/dry/
wet/cold + overworld_green_boss (the hand-placed 249,244 site,
Warden kit stand-in, approach outside the pack's 6x6 arena box);
the 180,143 border camp TUNED playably in wet (blightcaster+rusher
entry-wet); cold camps tabled; ruined city UNMARKED (zero authored
cells in the box). PROOFS ALL FIVE PASS reactive 3.0 ability-off
seeds 1,2,3 x 3600; BATTERY 28→33 ROWS; cold margin 0.121 == the
lab solo-ringer margin exactly. THE COLD FINDING (six failed
layouts, all recorded with numbers): (1) NO ACTIVATION LEASH —
every mobile pull converges from t0; multi-pull zone density waits
on activation/territory semantics (maxActive/respawnPressure = THE
importer spawn-surface question); (2) husk-volley alignment clips
ringer orbits at fit-rule margins on b77 ground (FIRST@1350
invariant across support casts) — pairing viability is
terrain-class-dependent; (3) point-openness ≠ orbit-openness (the
157,39 site scores 0.97 yet pins at margin 0.000 — cliff bands;
wf's clearance term is the upstream home for a real model). Snow
ships as the zone-heavy solo demo. Lock: the doc-17 world_filler
NONE placeholder REPLACED by the first real pin; sync log sl-0094.
Fixed gates + export + probe ALL GREEN 3.3 min (battery skipped
deliberately — the five NEW rows ran at authoring; full 33-row gate
rides the next exclusive seam). STEP 2 ARMED: the designer's feel
session on the five picker rows — the danger ramp, the boss spot,
the territory texture. NO feel verdicts (hands-free session).**
THE BALANCE CALCULATOR LIVE 2026-08-01 (~15:05 local; ask sl-0095 —
docs/22 block 9, the stat talk's closing deliverable; PAPER-FIRST,
zero sim contact): data/balance_frame.json = the ONE versioned
game-owned file mirroring the docs/22 tables (game owns the file,
planning owns the design; docs/22 never amended game-side).
Concrete numbers DERIVED [P] inside the nine ruled blocks: weapon
DPS budgets 12 × 1.4^t with the three frames at ±10% (slow-heavy
+~7-10%, fast-light ≈ budget, long-reach −~9%); enemy typical hits
10/16/26/40 with obtainable armor at exactly 0.5× every bracket
(plateau flags all clear incl the T5 capstone at 0.65×); trash HP
24/32/48/64 back-solved to 4 reference hits at every band; armor-
slot HP 30/38/49/63/81 (+25-30% steps); class curves sword 120+16 /
staff 100+13 / bow 90+11 with speed 100/105/110 cap 115; XP stepped
100/400/800/1400 = 20,600 to cap-30 (~33-37 kills/level); the six-
pair grammar; unique one-break + chassis 70-90%. Game-side
conventions FLAGGED [P] for planning's sweep (hits reference =
the budget-exact fast-light frame; class↔frame mapping sword=
slow-heavy/bow=fast-light/staff=long-reach; TTD = one tanked
stream at 1/1.2s). tools/balance_calc.py = 23RD FIXED STEP + CI
row, hard-coding the ruled constants as the design contract (data
drift FAILS loudly); ALL FIVE GATES PASS: TTK 2.0-3.3s invariant
per class, TTD 47→26s tapering (the world sharpens faster than you
toughen), armor liveness clean, pattern fairness holds at every
tier (arc owns clumps, pierce owns lines, stream owns movers; none
best everywhere), 4 hits + ≤3-digit numbers, item validator green;
NEGATIVE-TESTED per the routing (smuggled un-paired uplift +
two-break unique → exit 1, findings named — TECH-16 discharged on
paper). GATE NOTE (gotcha #19 honored): the designer's play window
(godot.exe --path ., opened 14:25 mid-session — possibly the
overworld feel session) blocked the pretester; the calculator gate
+ negative tests + ps1/yaml parses ran individually green (same
commands + exit codes, the recorded fallback); the full 23-step +
33-row gate rides the next exclusive seam. NO WIRING — the stat
frame enters the sim at slice build; the numbers exist before the
code does. Sync log sl-0096. SEAM CLOSED same day (~15:07): the
designer closed their play window and said go — FULL pretester ALL
GREEN 24.4 min at full strength (23 fixed steps + 33-row battery
byte-identical incl the five overworld rows' first canonical run +
export + lockdown probe). The deferred-gate debt from the
sl-0094/0096 sessions is cleared.**
THE ACCEPTANCE TRIPLE + THE SLICE PIVOT swept 2026-08-01 (~15:30
docs sweep; the rulings landed in the designer's ~14:25 play/stat
session, planning-side): (1) sl-0097 — THE WALK FORMALLY ACCEPTED,
the designer's words: "yeah this is like playing another game, very
good" — the sl-0078/0081 fit-rule red-line acceptance DISCHARGES,
sl-0067's b77 navigation walk RESOLVES, the opposite-failure probe
(squeezing through visually-solid props) surfaced nothing. (2)
sl-0098 [Tier 1] — THE WORLD IS THE TEST: Slice v0.1 IS the loop;
the separate Loop-acceptance gate DISSOLVES; the b65 town loop
RETIRES WITH HONOR as the mechanism proof (run lifecycle / death
cost / loot-that-matters proven); THE PACK-WIRING HOLD LIFTS —
icons (sl-0083) + NPCs (sl-0089) wire INTO the slice build; Slice
v0.1 = THE ONE milestone, Green Country first; the docs/19 bar
judges LIVING IN THE BUILT WORLD (leave a settlement, fight, loot,
level in-bracket, die to the CORE-43 city-fee death and walk back;
the world persists and refills, NO run framing) over the designer's
week, then the warm watched first-touches; CORE-55 amendment
planning-side; scope tripwire superseded in place above. (3)
sl-0099 — DOCS/20 STEP 2 VERDICT: the designer played ALL FIVE
sl-0094 scenarios — directed placement PASSES (ramp / boss spot /
territory texture / border camp all unremarked); ONE finding:
enemy density too low, self-dispositioned as slice tuning
(planning connect: low BY CONSTRUCTION — the sl-0094 cold finding's
no-activation-leash; the docs/23 S0 leash + the density tweak are
ONE work item); sl-0041 rehearsal arc RESOLVES; docs/20 step 3 =
docs/23 S0 work. THE BUILD GO = the designer's next word; the
slice session reads planning docs/23 FIRST. Docs sweep this seam:
README (slice scope, pack/tool inventory, 23/33 gate), designer
queue banner, runbook header, this file's tripwire + CORE-55 row,
HANDOFF rewritten for the slice-era cold start.**
SLICE S0 FOUNDATIONS COMPLETE 2026-08-01 (~22:45 local; ask sl-0100
executed as FOUR SEALED SEAMS, gates green per seam, never two open;
session record planning notes/sessions/2026-08-01-slice-s0.md; game
695f898→4acca00→8c0ce7a→5ad9dbb): **SEAM 1 — THE STAT FRAME IN THE
SIM (SERIAL 15):** docs/22 blocks 1–8 as code on the class-backed
lane (class_id 0/1/2 sword/staff/bow; -1 = legacy lane, byte-
identical BY CONSTRUCTION — floor battery reproduced byte-identical);
THE formula max(attack−armor, ceil(attack·0.2)) integer-exact in THE
damage path (hostile lane armed for future enemy armor at armor 0
identity); balance_frame.json = the single tuning source, loader
REFUSES ruled-shape drift (negative-tested); class curves + stepped
XP (20,600 to cap 30, NO damage from levels, refill [T]); three
class weapon frames (arc-3 @0.6/s, bolt @2.0/s, pierce-3 @1.2/s;
patterns 4/5/6 on existing friendly sprites) on the json tier
tables, .tres T1 pinned vs table; paired-trade grammar + ring slot
end-to-end (content = chapter work); armor slot = defense+HP per
tier; MOVEMENT-INTEGRATOR HARD CAP 3.45 t/s (115) — smuggled writes
clamped, negative-tested; GAME-SIDE [P] SPEED ANCHOR: stat 100 ==
3.0 t/s (the CORE-53 proof floor) → bases 3.0/3.15/3.3 — THE FEEL
FLAG: class walk speeds sit under the old 4.0 lab preset; the ruled
one-line revisit stands. Profile v2 (class at creation, class frame
replaces the lab trio, v1 = fresh start); HUD class lane + bars on
real maxes; ledger #16 amended. **THE CAP LANE BORN (block 6:
proofs at floor AND cap FOREVER):** battery split floor/cap115; the
maiden sweep caught proof_ringer cap FAIL (seed-invariant 4-hit
graze @t2033 — full-3.45 lattice coarsens past the 0.121 radial
gap); a half-duty policy rescue was built, DISPROVEN at lane scale
(re-routed first_contact cap into a new 0.048 graze), REVERTED to
the record byte-for-byte; **ringer cap FAIL PINNED as a documented
baseline** (floor = the CORE-33 mandate PASSES; repros committed; a
verdict MOVE = the sim changed); canary fails at BOTH speeds.
stat_frame_test = fixed step. **SEAM 2 — LIVING-WORLD PLUMBING v1
(SERIAL 16; docs/23 a–d; docs/20 step 3 DISCHARGED):** site_step =
activation leash (wake ≤22 / sleep >30 hysteresis; wake spawns the
dormant population at deterministic bitgrid-probed slots; sleep
FOLDS live members back with current hp BY ID — no kill events, no
loot; kills+damage persist) + away-only depth-keyed respawn (arms
ONLY dormant — nothing pops in faces STRUCTURALLY; zone bases [T]
green 10800/dry 9000/wet 7200/cold 5400, pressure multiplier,
bosses ×3 lazy); enemy_step TETHER 12 (disengage + walk home,
windup canceled; 12 > every class weapon reach ~9.4 — no shoot-
from-safety exists); content_importer reads the vendored pack's
territories+placements DIRECTLY as spawn tables (193 sites = 92
territories + 97 encounters inheriting covering/nearest territory
tables + 4 world bosses on the Warden kit stand-in; 15 territory-
less encounters counted-skipped; 11 dungeon bindings recorded for
chapter work; reference-pass vocabulary, nightOnly carried
unconsumed; loud negative-tested refusals). **THE SLICE PICKER ROW
LIVE** (slice_overworld: b77 + content pack + persistent_world;
capital spawn CLEAN — zero sites within 26). proof_slice_leash =
battery row 34 (iterated twice under never-weaken: first spawn WAS
a site cell — wake ring on the bot's head 9 hits @t21; second
exposed tether edge-guarding vs a passive bot, vacuous near −1;
final = INSIDE the lonely husk camp's envelope, seed 98,225
isolated 31 tiles: real fight, one wake, PASS floor 1.975 / cap
2.053). living_world_test = fixed step; export ships the content
pack loose beside the exe. The sl-0099 density finding is now
authored DATA × the leash. **SEAM 3 — OVERWORLD DEATH (SERIAL 17;
CORE-43, sl-0098 NO RUN FRAMING):** THE damage path takes the [T]
25% carried-gold slice IN-SIM at the death tick + arms the
settlement respawn (240t [T]); player_respawn (first in step)
revives at respawn_cell on timer or EARLY via the ability key while
dead (meaningless to a corpse otherwise — replay-honest, zero
format change); full refill — THE WALK BACK is the price;
persistent worlds keep RUNNING through death (recap unpaused,
hides on respawn; RecapTracker re-arms per death — Law 8 holds for
death #2+); dead-in-place stands for labs/proofs/HARDCORE;
"never cheaper than teleporting" satisfied by absence (recorded).
**SEAM 4 — WIRING (view-only, zero sim change; the sl-0098 hold
discharged):** import_npcs.py translates the character-v3 manifest
into the assembler_library shape (the sl-0092 adapter, mechanical —
same 24px/20×4 contract) → res://npcs/ + a THIRD library instance;
npc_view = PURE VIEW (CORE-35 absolute): zone quest-givers at
content-pack giver-slot cells (walkability-nudged — 3 authored
cells sit on doorstep solids), the crowd on a deterministic golden-
angle spiral around the settlement spawn, inside the y-sorted
ActorSortSpace; WINDOWED RENDER EVIDENCE committed + read
(reports/npc_render_audit_capital.png — the crowd stands on the
plaza). Icons: atlas pair → res://icons/ (470 glyphs / 2 files);
icon_atlas.gd cuts by id; wired cheap = equipped weapon TIER GLYPH
top-right (class lane) + class emblems on the creation screen.
npc_icon_wiring_test = fixed step. **S0 GATE: FULL PRETESTER ALL
GREEN 42.4 min on an exclusive seam — 26 fixed steps + 67-run
battery (34 floor + 31 cap + 2 pinned FAILs) byte-identical +
export + lockdown probe; artifact-verified: balance_frame.json IS
in the export (zero stat-frame errors on the dev exe boot), the
content pack ships loose beside the exe.** Green Country is alive
and walkable with the stat frame underneath. **S0 STOPS HERE by
routing — S1 (Green chapter content) needs its own designer word.**
DESIGNER-EYES/PLAY pending: THE SLICE row itself (leave the
capital, fight the living sites, level, die, walk back), class
choice + emblems on creation, walk-speed feel (the block-6 revisit
lever), NPC crowd on screen (sl-0089 watch-items now judgeable),
weapon tier glyph. NO feel verdicts (hands-free engineering
session).**
SPEED ANCHOR RE-RULED same night (sl-0102, ~22:00 local; the
block-6 feel reservation FIRED after the designer's S0 walk — "a
tad slow ... a little bit higher since we got so low cap"): stat
100 == 3.6 t/s [T] (was 3.0) — ONE constant
(StatFrame.SPEED_TILES_PER_100), proportions 100/105/110 + cap 115
unchanged → sword 3.60 (the CORE-53 floor) / staff 3.78 / bow 3.96
(== the old lab feel) / cap 4.14 (the max build now beats the old
lab standard — the chase has a prize). BOTH proof lanes
re-baselined at 3.6/4.14 per the block-6 law. Watched rows resolved
DELIBERATELY: the 3.45 ringer-cap PINNED FAIL retired WITH the
anchor (both ringer lanes PASS — the graze was lattice-specific);
rusher [primary] re-pinned FAIL→PASS at the faster floor;
first_contact [primary] stays FAIL; canaries FAIL both new speeds
(cap lane calibrated). Legacy lane untouched by construction.
ALSO same night (view-only, 098a679): GIF recorder rebuilt
START-TO-FINISH (G starts, G stops, every frame between streams to
disk) — the last-10s ring silently ate the front of every longer
recording; the designer asked for the whole recording three times
(the sl-0078 law). NO feel verdicts pending beyond the standing
queue; the new speeds ARE the designer's own re-rule.**
S1 SEAM 1 — THE GREEN ROSTER LIVE 2026-08-02 (~00:30 local; ask
sl-0104, docs/23 enemy split; hands-free): the zone's 14 families
as archetype DATA ROWS at indexes 8–21 (docs/23 order: slime/
goblin/boar/wolf/bat/shroom/wasp/beetle/moth/snail/porcupine/
scarecrow/treant/bandit) — CORE-44 spread 7 melee-chaser / 2 aimed
/ 1 flanker-intercept / 2 anchor-fan / 1 chaser-radial / 1 hazard;
ZERO new patterns: every row REUSES its archetype's PatternDef
VERBATIM with the archetype's exact telegraph lead (slash 10 /
aimed 12 / fan 30 / radial 36 / dart 40 / blight arm 45) — the
recap's pattern→lead law holds roster-wide and is now MECHANIZED
(one lead per pattern id across every def/phase/hazard,
negative-tested; Law-4 ordering untouched; projectile_map + audio
map byte-untouched — the ratified CVD hue language carries whole).
Green-band stats [T] (hp 10–48 center ~24, speeds 0.9–3.1 all
under the 3.6 floor, xp avg ≈3 = the balance_frame per-kill;
equipment drop_chance 0.0 = THE SEAM-2 BOUNDARY, pinned in test).
ALL 54 VARIANTS PLAY (docs/23 variability ruling): actor_sheet_map
grew a `variants` dict (full catalog lists, canonical = family
default); the assembler importer imports variant lists wholesale
(8→59 sheets; "boss:*" ids structurally skipped — the boss library
namespace); enemy_actors_view picks PER ENEMY by sim id modulo
count (deterministic, view-only, cosmetic — the split assigns
identity, never behaviour). TERRITORIES RE-TABLED role-preservingly
(the importer's ZONE_VOCAB layer, not new format): green marauder →
the melee eight / prowler → the ranged five / mire_creeper →
shroom (mud pockets = spore ground); each set sums EXACTLY 100 so
entry weight = placeholder × set stays integer-exact; zone tables
are AUTHORITATIVE (out-of-table id = loud refusal, negative-tested);
all 44 green territories re-tabled, other zones byte-untouched on
the flat vocab; encounters inherit automatically. DENSITY ×1.5 [T]
green-only (pack+maxActive, sl-0099 disposition — the leash makes
it safe). tests/green_roster/green_roster_test.gd = 27TH FIXED STEP
+ CI row (roster order, lead law, grammar bounds, variant parity
BOTH directions vs the catalog index + imported library, re-table
integer-exact pins incl. density 3→5/2-6→3-9, proof-camp premises,
3 negatives). PROOFS: proof_green_camp (most isolated MIXED
territory, 185,244, near 0.899) + proof_green_ranged (most isolated
of all, 108,138, prowler-only → pure ranged set, near 0.121) PASS
floor+cap seeds 1,2,3; proof_slice_leash RE-BASELINED deliberately
(husk camp → ranged Green set at density; 1.975 → 0.120, honest
PASS both lanes); battery 34→36 rows / 69 runs. Sim bytes untouched
by the append (smoke + goldens x10 byte-identical pre-commit); boot
clean; living_world/loop/stat_frame/assembler/wiring all green.
DESIGNER-EYES pending: the Green countryside itself (walk out of
the capital — every camp now wears the zone's real skins).**
THE BATTERY RUNS N-WIDE 2026-08-02 (~00:45 local; the designer-
approved tooling ask, docs/23 tooling lane; rode between seams as
routed): tools/battery_runner.ps1 = a worker pool over the
battery's independent replay runs — default workers = PHYSICAL CORE
COUNT (auto-detect, 8 here), HARD CAP 10 (the designer's ceiling),
longest-rows-first from a machine-local timing table
(reports/battery_timings.json, gitignored); every verdict
DOUBLE-GATED (PASS/FAIL marker AND exit code); coverage untouched —
the pretester's table stays authoritative, -Workers 1 = the serial
path, and the reports/-clean byte gate stays the final word (a
cache race can only surface as a loud FAIL, never a silent wrong
verdict). ADOPTION PROOF: the full parallel battery reproduced the
serially-produced committed record BYTE-IDENTICAL — 69 runs in 9.5
min wall, FULL GATE ALL GREEN 12.5 min (was ~40-45 serial; the
≲10-min battery target met). **THE FIRST FULL RUN CAUGHT A RED ROW
HIDING IN THE GREEN RECORD (fix f40decf):** the sl-0102 re-anchor
had committed loop_ring2's floor-lane FAIL as the record (1
seed-invariant husk pinch graze @t316, near 0.028 — the 3.45→3.6
floor move walked the deterministic dance into a point-blank
squeeze) and no full gate ran after that re-baseline. Diagnosed by
probe (the husk, NOT the ringer), fixed per the ring2 precedent
(never-weaken layout iteration: husk 198.5,131.5 → 196.5,134.5,
walkable/in-aggro/composition intact, MIRRORED in loop.tres),
re-proven 0 hits both lanes (0.148 floor / 0.123 cap). NEW LAW
(gotcha #32): a re-baseline is not done until the full gate runs on
it — the fast battery makes that cheap. Second full gate ALL GREEN
12.5 min sealed seam 1 + the adoption together.**
S1 SEAM 2 — T1 LOOT LIVE IN GREEN 2026-08-02 (~01:30 local; sl-0104
seam 2; hands-free): the Loop-v1 drop machinery meets the docs/22
frame in Green. GREEN DROP TABLES [T]: fodder 0.03 / light 0.06 /
big bodies 0.10–0.12, tiers T1 with a T2 trickle from the big five
only (boar/porcupine/scarecrow/shroom/treant) — the green test's
seam-2 boundary pin FLIPPED deliberately to "live and small-honest"
(chance ≤0.15, tier_max ≤2, rings big-bodies-only). THE RING SLOT
GETS CONTENT (block 4/7): DropKinds.RING + EnemyDef.drop_w_ring
(default 0 = every pre-slice def's kill-roll draw SEQUENCE
byte-identical — proven by the smoke hash landing UNCHANGED
c0498aae/5daf14c6 and the battery byte gate); the ring branch picks
among stat-frame ring items AT the drawn tier; TWO T1 RINGS in
balance_frame.json (Ring of Haste +2 spd/−8 hp, Ring of Claws +2
dmg/−2 def — both sanctioned pairs, validator green); walk-over
equips ONLY an empty slot ([T] — rings are a choice, not a ladder;
swap semantics = a designer call later); legacy (class −1) players
refuse rings. PROFILES KEY RINGS BY ID now (ring_id replaces
ring_index in character.json — items[] evolves chapter by chapter
and a raw index would silently re-point saves; the sim keeps the
integer index, serialization untouched; no version bump — no
profile could hold a ring before tonight). THE ONE ITEM-TEXT
GRAMMAR (docs/22 "every number visible" + block-7 "every tooltip
reads the same way"): game/views/item_text.gd = the single
compose point — weapon "T1 Bow — 6 dmg @ 2.0/s" (tier table +
cadence), armor "T1 Armor — +5 def, +30 hp", ring "Ring of Haste —
+2 spd / −8 hp", unique/ability/gold lines; pickup TOASTS speak it
(gold stays silent — the HUD counter is its readout) and the
GROUND LABEL shows it for the nearest drop within 1.8 t (drop_view;
LOOT band — the label rides UNDER threat, Law 1 outranks
convenience); ring shape = orange circle outline, tint-by-tier
family. Exact grammar lines are TEST-PINNED (loop_test §10);
ring mechanics negative-tested (occupied slot grounds, legacy
refuses); loop_test grew §9/§10 (drops/…/rings/text/hash);
stat_frame_test round-trips ring_id both ways. WINDOWED EVIDENCE
committed: reports/loot_label_audit.png (all six kinds + the label
line, read by eyes; the probe's first run caught a type-inference
parse error in the label code — the hang-is-a-parse-error gotcha
re-earned). Zero new fixed steps (existing gates grew).
DESIGNER-EYES pending: drops in the field, toast/label taste, the
two ring concepts, every [T] rate.**
S1 SEAM 3 — OLD TUSK LIVE 2026-08-02 (~02:00 local; sl-0104 seam 3;
docs/23 naming act; SERIAL 17→18, next bump 19): the hand-placed
Green world boss IS the boar — the Warden stand-in RETIRES at his
site. THE KIT (special never a task; the Warden three-phase recipe
as floor, zero new sim mechanisms): 480 hp [T] / radius 0.55 / P1
THE CHARGER (3.0 chaser; TUSK SWEEP pattern 22 = 5x70° heavy cone
dmg 12 lead 30 — never stand in front) / P2 THE RAGE (≤66%: 3.2,
quicker sweeps + GORE RUSH pattern 23 = three staggered-speed tusks
down one INTERCEPT line dmg 14 lead 40 — committed straight running
punished) / P3 THE MIRE (≤33%: wounded 2.6, blight_zone mud casts —
the SHARED mud/spore vocabulary arm 45, pattern→lead law holds —
plus densest sweeps). Elite amber language throughout (Law 3);
sweep joined the melee cue class; Law-4 = 15 rows monotone; speeds
all under the 3.6 floor. Sprite boar:blood (no boar among the 13
48px bosses — Mirejaw is Longjaw's future skin; boss-art polish =
a designer round). THE FIRST SLICE UNIQUE — OLD TUSK'S HIDE
(block-8 break (c), validator-priced): T2-chassis armor, defense
12 vs the T2 budget 8, hp +38, paid with a REAL −6 speed ("the
souvenir: his stubbornness"); 35% independent roll (no pity, the
coil precedent) + guaranteed T2 equipment (chance 1.0). MECHANISM:
PlayerState.armor_item_index (SERIAL 18, hashed) — a worn unique
REPLACES the armor-tier ladder in recompute (its speed cost counts
before the hard cap); UniqueDef.items_id binds drop→items row;
profiles persist BY ID (armor_item_id); unique grammar line
publishes the numbers ("UNIQUE: Old Tusk's Hide — +12 def, +38 hp
/ −6 spd", exact-pinned). WIRING: roster 22 append-only; importer
ZONE_BOSS green→22 (other zones keep the stand-in until named);
overworld_green_boss re-pointed (row re-baselined deliberately);
proof_old_tusk = schedule-paced full fight (P2 @t910 / P3 @t1820 /
kill t2600, the 3d19a6c precedent) PASS BOTH LANES FIRST RUN.
Battery 37 rows / 71 runs. Goldens re-recorded + verified x10;
zone-aware boss pins in living_world + green_roster; stat_frame
override checks (equip/unequip exact, −6 real, hash); loop_test
Hide pickup + exact line. DESIGNER-EYES/ROUNDS pending: the fight
itself (feel rounds are scheduled work), Hide numbers, [T] rates.**
S1 SEAM 4 — THE WARREN OPEN 2026-08-02 (~02:50 local; sl-0104 seam
4; docs/23 dungeon truth — "place them there for now, fix it
later"): the Green dungeon interior at its bound entrance, a
COMMITTED INSTANCE. data/arena_warren.json = the stand-in tunnels
(48x32, three carved bands: entrance room → chamber A → the long
chamber B → the SE throne room; 2-3-wide shafts; dungeonfloor/wall
families, solid props honest). DOORS ARE WALK-ON (the loot
walk-over language): main.gd DUNGEON_DOORS — the mouth is the
pack's LOCKED green binding's ACCESS CELL 194,240 (the binding cell
193,239 IS the giant-skeleton POI, solid by WYSIWYG — the first
door draft learned that from the test); the ladder up (warren 2,2)
lands one cell east of the mouth (196,240); profile harvests BEFORE
every transition; arrival spawns sit ≥2 t off doors (no ping-pong);
one-shot door_spawn consumed BEFORE the recorder snapshot (replays
carry true initial state); CORE-43 death in the tunnels = the gold
slice + the warren-mouth respawn — the tunnels are the walk back.
THE LAYOUT EARNED ITS SECOND ITERATION UNDER NEVER-WEAKEN:
v1's three thin-walled bands put every pack within aggro of the
entrance — AGGRO IS EUCLIDEAN AND WALLS DO NOT BLOCK IT, so the
opening became a 15-body killbox (bot DEAD @t414, 13 hits — a
human at the floor dies there too; CORE-33 binds in dungeons). v2
= a LINEAR crawl with DISTANCE DISCIPLINE: every room's pack >12 t
from the previous room's fight zone (separations 20.1/15.0/14.2,
script-verified pre-authoring), shafts deliberately EMPTY (pickets
chained fights), 21 ordinaries goblin-court heavy ("explains the
zone's goblins"), the throne room widened and the court THINNED TWICE (final: 2
goblins, NO porcupine — v2's court still shredded the floor lane
15 hits @t624: the porcupine radial + Grubb's ring = DOUBLE RADIAL
in a 7-tall room, no orbit space at 3.6; one radial per boss room
is the recorded lesson). KING GRUBB at the bottom (roster 23; goblin:chief): 420 hp
[T], P1 THE COURT (keep-range scepter volleys pattern 24: 3x12°
aimed, lead 24), P2 THE TANTRUM (+ the king's ring pattern 25:
8x45° slow radial, lead 36 — the gaps ARE the answer indoors), P3
THE PANIC (chases at 2.9, denser everything). Elite amber; Law-4 =
17 rows monotone. PROOFS: proof_warren (the opening) +
proof_king_grubb (schedule: P2 @t960 / P3 @t1800 / kill t2520,
court alive) — battery 39 rows / 75 runs. Warren pins in the green
test: binding/access cells vs the pack (the first door draft
learned the binding cell is the SOLID POI from the test, not on
screen), the REAL ArenaBuilder collision derivation, EVERY
authored spawn lands on floor (zero skipped), door cells walk both
sides. NEW DUNGEON LAW recorded: room packs sit beyond aggro of
the previous room's fight zone, verified numerically at authoring.
DESIGNER-EYES pending: the descent, room feel, Grubb's court
(boss rounds scheduled).**
