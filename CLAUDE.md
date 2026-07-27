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
day start): movement feel at 3.0/4.0 (F2/F3), ranger facing, pause
freeze, F7 interp A/B. M3 ENGINEERING COMPLETE 2026-07-27 (8a0f2d4→
d172a25; session record in planning notes/sessions/2026-07-27.md):
three WeaponFrame.tres (§3.3 values, Longbolt 6.5t cap), fire path
with sim-side autofire latch + HUD indicator, motion programs
(straight/decel/sine/boomerang) + 8-slot hit registry (max-passes,
registry_full block), one damage-resolution path + death sweep,
terrain collision + corner-snag JSONL, CORE-32 proofs mechanized in
the smoke test (fire-vs-no-fire position equality; zero RNG in fire
path), .wsr replay capture (F10 live) + ReplaySource + golden replay
per frame verified 10x consecutive + Windows CI gate (activated M3,
one milestone early — flagged in planning log for veto), remap UI
(F1) + Config autoload + settings.cfg persistence (test green), F9
GIF ring buffer + tools/gif.ps1. OPEN designer-owned M3 items: stand
up itch page + devlog thread + bare Discord (accounts/public posts),
post the first weekly GIF (F9 → tools/gif.ps1) — cadence starts there
and never stops. Next code milestone: M4 (docs/12 §4 — debug console
+ overlay, density meter, event skeleton completion, death recap +
debug emitter, scenario picker, ability slot + mana, HP/mana HUD,
UI/text scaling, fresh-hands verdict command).**
