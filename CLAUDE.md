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

## Scope tripwire (rewritten 2026-07-30 with Gate 1, sl-0023)

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
overworld look = theirs, on screen.**
