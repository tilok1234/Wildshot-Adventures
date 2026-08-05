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

> **STARHOOK v2 — THE PROTOTYPE MERGE (sl-0115) 2026-08-02 (~15:30
> local; hands-free; SERIAL 21→22, next bump 23):** the designer's
> overnight prototype #2 rules the SHAPE (INDEX corrections = law;
> every number [T]; refinement rounds follow). BUILT: 50/50 split
> (world capture LEFT w/ the line INTO the world rift + portal pulse;
> galaxy RIGHT under a FIXED camera — interior 10x11 of the new 12x13
> arena fills the pane 1:1, walls off-pane, Law 1 by construction);
> THE PULL as a real .tres (data/rift_pull.tres: 1.35 t/s, ±0.45 rad
> osc @0.004/tick ~26 s, player ×1.0 / catch ×0.3 / HOSTILE shots
> ×0.15 — friendly bolts fly true, CORE-32; enemies drift only in
> moving states — Law 4 outranks the prototype's drift-while-
> telegraphing, recorded deviation); LINE STABILITY = HP with THREE
> HARD LIVES (integer-exact drains through THE damage path, pattern
> -5: passive 0.4/s = 1 hp per exactly 150 ticks, deep-edge +2.2/s,
> 0.8 t strip; snap = life burned + full re-spool + 90 t grace +
> LINE_SNAPPED; third snap = the normal dive-lost death; hit grace
> 30 t blocks bullets only — drains never pause; the drains NEVER
> count as proof hits, CORE-33 is about attacks); CAST IS INSTANT
> (interact at a portal — the cast IS the aggro; stillness cast
> retired; forage stillness stands); AMBIENT RIFTS (rng_misc's first
> consumer — interval/chance/cap/ring in balance_frame
> starhook.ambient [T]; ambient nodes = serialized state, consumed
> away; authored nodes carry biomes, slice 12 = 0,1,2 cycled);
> THREE BIOMES as pattern-variant .tres (void ring 12x30 @3.4, comet
> spray 6.3 + dart cd ×0.8 — SAME pattern ids, SAME leads: one
> hostile language) on 4 new defs at roster 26-29 (append-only) + 6
> scenarios (rift_<biome>_<rarity>) superseding rift_common/rare;
> THE WIN IS PURELY THE KILL (reel cut, correction #7): kill banks
> gold directly (no ground drops in rifts) + draws the biome FISH
> (rng_loot weighted 45/35/20; rare rarity = the rare species;
> CATCH_LANDED + world.rift_catches serialized) + auto-exit after
> 150 t linger (the mouth door stays as the flee path); FISH PERSIST
> PER-SPECIES (profile starhook_fish{} — species-currency, deck tap
> shk2ctch); FOUR RODS (Heavyline 88 t/16 dmg/9 t/s + Twinreed 28 t/
> 2x±3°/3 dmg/15 t/s — 30→60 tps converted; patterns 9/29;
> Heavyline's hitstop+shake REFUSED, CORE-32; unlocks 1/3/5/8 [T]),
> R SWAPS (rod_swap=R by the designer's word — replay_save moved
> R→J; the swap rides the recorded weapon_select byte: ZERO replay-
> format change, WSR stays v2; locked selects refused sim-side; the
> equipped rod persists by id); THE BAIT FIGHTER is the star
> (corrections #1/#2): an 11x12 code-drawn micro sprite + glow pad,
> the prototype's 20x12 star-fish pixel map tinted per biome/gold-
> rare replaces assembler actors in rifts; galaxy backdrop/rim/deep
> shimmer/flow arrows/portals per biome; the line sags↔tauts, red
> under strain, travelling spark, drawn INTO the world rift and OUT
> of the galaxy rift (correction #4), world-canvas z 40 so hostile
> bands stay above (Law 1); overworld portals + [F]-cast prompt live
> (rift_nodes_view — nodes finally RENDER). DodgeBot models the pull
> (self incl. the stay candidate, hostile shots in projection) +
> deep-edge keep-out as positioning penalty; dodge_proof counts
> bullet hits only. PROOFS: all four rift rows (nebula/rare/void/
> comet) PASS floor+cap seeds 1,2,3 x 3600 FIRST RUN in the new room
> with the pull aboard — margins 0.120-0.122, comet floor 0.079
> (honest tier-3-watch); battery 41→43 rows. Goldens re-recorded +
> verified x10 (SERIAL 22). gather_test REBUILT (instant cast/
> ambient/pull/drains/grace/snap/clear/fish/rods/refusals/hash/
> rifter/slice premises, negatives incl. loader biome-table + pull
> refusals). Evidence committed + read:
> reports/rift_galaxy_audit_{base,desktop}.png (integer stretch =
> desktop is pixel-exact 3x base by construction). NOT this seam (by
> routing): gear drops (NEXT), skill tree (post-class-trees), node
> drift/despawn, vendors; water fishing PARKED (correction #3).
> Length-roll catch-card flavor + divider spark = refinement-round
> material. NO feel verdicts — the designer's refinement rounds +
> Green days own the cast feel, split ratio, drains, lives, rod
> gates, ambient cadence, and every [T] above. SEAM CLOSE: full
> pretester ALL GREEN 15.0 min (30 fixed + 43-row/83-run battery
> byte-identical + export + lockdown probe); one mid-gate catch
> fixed loudly (the projectile importer's pid<10 friendly-namespace
> range rule died at rod pattern 29 — the map now DECLARES
> player_patterns; undeclared = hostile under the covers_hitbox
> guard, fail-safe proven live).**

> **THE DRAG IS CUT (sl-0123, the designer's word after casting;
> 2026-08-02 ~15:45 local):** arena combat in the galaxy view is
> NORMAL combat — no movement drag on the bait fighter, the catch,
> or any shot; full responsiveness. The rift's pull lives in THE
> LINE ONLY: the strain clock (passive drain), the deep-edge strip,
> bullet hits straining the line, and the line's visual tension.
> The rift_pull entity-drag system RETIRED CLEAN: data/rift_pull.*
> superseded by data/rift_line.* (drains/deep-edge/lives/graces
> only — no zeroed multipliers left behind), SimWorld.rift_line,
> ScenarioDef.rift_line; the movement/enemy/projectile integrators
> and DodgeBot's projection carry zero pull code; the sl-0115
> hostile-only-drift and Law-4-drift deviations are MOOT. Deep edge
> stays [T] (drain + bot keep-out + shimmer); the backdrop flow
> arrows DROPPED [T call] — they advertised a current that no
> longer moves anything; the line's tension + the deep shimmer are
> the strain story. gather_test pins the absence (a still fighter
> never moves; NO shot of either faction drifts — any smuggled
> future drag fails loudly). NEVER-BIND PIN mechanized (sweep item;
> correction #8): the icon pack's item.unique.undertow glyph is a
> retired word — the wiring test scans game/ui/input/sim/data
> sources and REDS on any reference (the glyph purges at the next
> icons release upstream). Dodge proofs + goldens re-recorded
> deliberately; full gate per gotcha-32 order. The real
> desktop-scale evidence capture (screen crop, not the base-res
> viewport texture) replaced the byte-identical twins.**

> **THE SPLIT RATIO GOES [T] (sl-0125; view-only, ZERO sim bytes —
> smoke hashes byte-identical to the sl-0123 record):** the
> world/galaxy split is a LIVE-FLIPPABLE options cycle row ("rift
> split": half & half / two-thirds galaxy; both profiles, [ui]
> rift_split persisted, settings round-trip in the gate). THE ARENA
> CELLS STAY IDENTICAL — main._apply_rift_split() re-anchors the
> panes and re-fits the fixed camera (zoom = min(pane_w/320,
> 360/352): half = 1.0 exactly as built; two-thirds = 1.0227
> height-fit, interior centered with backdrop-skirted margins — Law
> 1 by construction at either ratio); the world pane keeps the
> line/body/portal readable at 1/3 width (the overlay reads its
> live pane width). The galaxy backdrop grew a 1-tile skirt so the
> fitted camera never shows void. EVIDENCE: FOUR real distinct
> captures (two scales PER ratio; base = viewport render, desktop =
> topmost-forced SCREEN crop with the galaxy-color honesty guard) —
> reports/rift_galaxy_audit_{half,twothirds}_{base,desktop}.png —
> discharging the evidence-twins debt; the sl-0115 pair retired.
> The designer flips it in play and rules; the INDEX amends when
> they pick.**

> **THE GREEN-DAYS PASS (2026-08-02 evening; nine routed seams
> sl-0119..0132 ALL LANDED as sealed gated seams, game
> 42d8260..912049f; resolutions sl-0134..0142; SERIAL 22→25, WSR
> v2→v3, next bump 26):** C SHEET ON SCREEN (screen-anchored +
> viewport-clamped + errand scroll [T]; the zero-size PRESET_CENTER
> artifact typed — top-left pinned at the camera-held player; the
> onboarding screen carried the same bug, rider-fixed; three-scale
> evidence w/ letterbox-aware honesty guards). QUEST PULL (giver
> glyphs quest.available/turn_in at AUTHORED cells; corner+full map
> markers — VISIT diamond / turn-in ring, shape-first; HUD tracker
> top-right, id-slug names, cap 5; C stays THE log; honest gaps
> flagged: KILL/COLLECT carry no objective cell, the zone-hub giver
> has no body, the only minimap is dev-only). BOSS SPRITES (Grubb →
> boss:goblin-war-crown, importer run with BOTH ids; actor_sheet_map
> `scales` dict — Old Tusk ×1.25 [T] pixel-even; sim/hurtbox
> untouched, control-boar evidence). NPC DESYNC (per-cell
> variant-hash phases + 0.9–1.1 wobble [T]; 32 sprites / 15 phases /
> 28 speeds; lockstep = probe exit 1). FIRING RATE ×1.25 EXACT
> (sl-0120: the routed ~1.5× is IMPOSSIBLE under the ruled
> hits-band [3,5] — ceiling ~1.304×; cadences 80/24/40, rates
> 0.75/2.5/1.5 exact, damage recalculated [17,24,34,48,67]/
> [5,7,10,13,18]/[8,11,15,20,28], five calculator gates PASS, TTK
> held sword 2.67 / staff 2.00–2.67 / bow 2.00; TTD untouched; THE
> LEVER for more = trash_hp or the band, PLANNING-SIDE; feel flag
> stands). THE BAG (sl-0116+0128, SERIAL 23 + WSR v3: triples cap
> 20 [T] hashed; F picks INTO the bag — auto-equip + upgrades-only
> RETIRED class-lane; equip = a DECISION on the recorded bag_op
> byte; replaced items return TO the bag; armor/ring de-equip;
> weapon replace-only [T]; equipment pane in C, tooltip==drop_line
> TEST-PINNED, mouse sanctioned w/ suppress-over-pane; death keeps
> the bag; profile by-id; legacy lane NEVER bags — battery
> byte-identical by construction; ledger #16 amended). LOOT BAGS
> (sl-0129, SERIAL 24: a kill's non-gold roll = ONE corpse bag,
> same rng_loot sequence; gold stays walk-over; walk-over panel,
> click-to-loot-one, B loot-all [T — G is the GIF key]; bag TTL 2×
> [T]; leftovers stay on full; LOOT_PICKED per item — COLLECT
> counts; CLASS-LANE WORLDS ONLY, legacy keeps loose drops).
> THE BANK (sl-0130, SERIAL 25: walk-up stash at the PINNED keeper
> 112.5,182.5 — the pack's banker slot sits ON the spawn cell,
> collision recorded; ops 52/72+, radius 1.2 sim-side, cap 12 [T];
> BANK_FULL loud; DEATH NEVER TOUCHES THE BANK test-pinned;
> profile by-id). VENDORS v1 (sl-0131, NO bump: balance_frame
> `vendors` block — sell 50% / buy 200% [T], tier value tables;
> fixed catalogs general+trader on pinned bodies 106.5,182.5 +
> 106.5,180.5; ops 84/104+; buy refuses poor/full-bag with gold
> untouched; fish-currency FUTURE). Gates: -SkipBattery per
> view-only seam (icon-intake precedent), FULL gate before every
> sim commit (gotcha-32) — final state 30 fixed + 83/83
> byte-identical + export + probe ALL GREEN. NOT this pass (by
> routing): the gear seam (planning's next paste), class trees,
> water fishing. NO feel verdicts — every number [T], the
> designer's Green days own all of it.**

## Hours-log rule (PROD-01)

- `tools/hourslog.ps1 start` before ANY project work — code, art, design,
  planning; `stop` after. Dev hours ≠ game-running hours: everything is
  logged.
- `tools/hours_report.ps1` runs weekly; the first meaningful run is end of
  week 4, when the first 4-week rolling window closes. A rolling average below
  40 h/week triggers the PROD-01 floor reset, the docs/12 §4 slip ladder, and
  roadmap re-derivation — by rule, not mood.

## Weekly GIF cadence (from M3)

One 30–60 s GIF per week (G starts, G stops — start-to-finish frames
since 098a679; `tools/gif.ps1` converts), posted to the
devlog and one community. This is a deliverable, not marketing garnish — it
primes the tester-recruitment pipeline both Gate 1 cycles draw from.

## Engine pin

- **Godot 4.6.2 stable**, pinned (dev machine: `~/bin/godot`). Upgrades only
  between Gate 1 cycles.
- Typed GDScript only; no middleware; **no Godot physics in gameplay** (custom
  sim-owned collision). C#/GDExtension escape hatch is confined to the sim
  module and triggers only if the M2 stress scene fails budget.

## Milestone position (current)

**Era: Slice v0.1 — the world is the test (sl-0098).** Green Country is
live end-to-end on the docs/22 stat frame: the living world (activation
leash, tether 12, give-up 18 / return 5, away-only respawn), overworld
death = the CORE-43 25% [T] gold fee + respawn at the player's SET HOME
(waypost stations bind it; capital default = the spawn, sl-0221), the
RECALL cast (P, 2 s, overworld-only, 45 s cooldown), the Green roster
(14 families / 54 variants) + Old Tusk + the Warren + King Grubb,
quests v1 (multi-active cap 5, offer dialogue, map/HUD/mob-mark pull),
loot bags + bank + vendors + tackle, the C menu family on panel2,
starhook (rift fights, 15 boss kits, the rift dungeon path, 12 rods +
tackle gear, the creel), foraging (gather bar), the game-zoom
accessibility option (1x/1.5x/2x, sl-0222/0223), dev map overlay +
console toolbelt + jump commands, hitbox 0.175 + the cadence
re-composition.

**State:** SERIAL 28 / WSR v3 (next bump 29). Battery 62 rows / 121-run
pool (floor 3.6 + cap 4.14 lanes; two pinned [primary] FAILs + canaries
by design). Gate = tools/pretester_check.ps1: 33 fixed steps + battery
+ export + lockdown probe; CI green. Engine Godot 4.6.2 pinned.

**Open designer-owned:** the slice week on the docs/19 bar (Green days);
every [T] number; the sl-0186 dungeon re-walk; the 1.5x zoom
pixel-integrity call; refinement pastes follow their play.

> The full append-only milestone history lives at
> `notes/MILESTONE_HISTORY.md` — append THERE at each session close,
> never here. This block re-truths to the live era at each close.
