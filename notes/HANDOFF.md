# Session Handoff — updated 2026-08-05 (THE ACTIVITY PASS sl-0216/0218/0219: vocabulary guard + quest activity indicators + the chase-leash diagnose-then-tune; resolutions sl-0224..0226)

> **NEWEST FIRST — THE ACTIVITY PASS (2026-08-05 night, hands-free;
> four sealed gated seams aa65ec7 / 7b6b9a7 / 3f2a996 / d2900e8;
> resolutions sl-0224..0226; SERIAL 27 / WSR v3 UNTOUCHED all
> session):** (1) **THE DUNGEON VOCABULARY GUARD** (sl-0216,
> view/console): every starhook surface says RIFT DUNGEON (picker row
> + both toasts); the bare `dungeon` console jump RETIRED into a
> reservation hint (the plain word belongs to future overworld
> dungeons — the Warren class); the inverted phrase
> (dungeon-before-rift) purged from 12 living-source sites and BANNED
> by scan (dungeon_walk_test §4: concatenation-built pattern per the
> sl-0123 precedent + starhook display_name rule + main.gd
> one-route/hint text pins; NEGATIVE-TESTED x3). File/test ids STAY
> [P] (already rift_dungeon_* prefixed). (2) **QUEST ACTIVITY
> INDICATORS** (sl-0218, view over quest data, zero sim): quest-mob
> marks (game/views/quest_mob_marks.gd, both profiles, HP_BARS band,
> CORE-35 general presentation; tracker-identical binding — tracked
> narrows, none = all carried [T]; a finished errand un-marks; KILL
> only) — ships AMBER DOT (sl-0184 objective family; green belongs
> to turn-in) with the designer's green-dot lean + an amber chevron
> captured beside it in evidence, style = one line [T]; kill/collect
> soft REGIONS on both map scales (map_overlay.quest_regions) — **the
> routed whole-species centroid REFUTED BY DATA** (93 matching sites
> spread p50=106 t; re-tabled species live zone-wide) so the honest
> neighbor shipped: single-linkage NEAREST CLUSTER from the quest's
> own giver (LINK 15 / CAP 10 / PAD 4 / clamp 10-30 [T]; west_road's
> blob lands WEST of the station — data agreeing with fiction);
> COLLECT = every populated site; the sl-0184 honest gap closes;
> exact-geometry model pins in dev_map_test; lockdown lint's
> MapOverlay allowlist grew with the probe (its catch); SIX evidence
> PNGs committed + read (the woken meadow camp: a marked bandit
> beside unmarked ranged kin — the discrimination in one frame).
> (3) **THE CHASE-LEASH** (sl-0219, diagnose-first then sim values):
> the gang train MEASURED on a real five-site b77 corridor (committed
> probe tests/chase_leash/ + reports/chase_leash_diagnosis.md) —
> aggro 12.0 UNIFORM, IDLE-only; NO player-distance give-up existed;
> the tether walk-home STOPPED AT THE RIM (census max home-dist
> EXACTLY 12.0; 10/20 rim-parked); engagement saturates in 6 s and
> holds 27-30 of 30-39 for 48 s with ZERO decay, near-8 gang
> 24/24/24 identically every lap, 21 sustained standing, 15 still
> engaged through a 5-s hold 20+ t away (terrain-wedged chasers
> press forever). THE TUNE: SiteStep.GIVE_UP_RADIUS 18.0 [T]
> (hysteresis structural — 18 > aggro 12/14, pinned vs the real
> roster; a windup completes, Law 8) + RETURN_RADIUS 5.0 [T] (full
> re-center past the rim; > spawn ring 4.4 — wakes never shuffle),
> SITE MEMBERS ONLY — labs/Warren/rift-dungeon/proofs keep
> chase-forever BY CONSTRUCTION, PROVEN: the full 121-run battery
> reproduced BYTE-IDENTICAL (zero re-records; goldens + smoke
> byte-identical; the three canary repro strays = the recorded
> pool-race noise class, restored). AFTER (same probe/seed):
> off-road engaged 15→4 (each explainable as live proximity),
> rim-parked 10→3, standing near-8 21→22 (pressure UNCHANGED by
> design) — the fairness frame exactly. living_world_test +8 pins.
> Gates: -SkipBattery 3.0 min x3 + the gotcha-43 pair on the sim
> seam (diagnostic full → commit → SEAL full ALL GREEN 14.6 min on
> the committed tree). sl-0213 stays its own word. **NO feel
> verdicts — mark style, region params, both leash radii: ALL [T];
> the designer's run around the map is the acceptance.**

> **PREVIOUS — sl-0200 + sl-0201 (2026-08-04 afternoon,
> hands-free):** (0a) **CI IS GREEN FOR THE FIRST TIME IN THE REPO'S
> RECORDED RUN HISTORY** — the 6h auto-cancel on every push since
> 08-01 was the CROSSHAIR row (gotcha-47's CI sibling: load() of the
> kit cursor nulls on a fresh checkout with no .godot/imported; the
> abort idles the SceneTree forever), NOT the dungeon-walk row (it
> never executed). Three layers: kit_image() raw-PNG fallback +
> job timeout-minutes 15/30/45, a CI --import pass, and
> feedback_bundle_test provisioning absent evidence (it had been
> riding the developer's REAL session.jsonl locally). The pipeline
> now concludes green in ~50 s — watch the WHOLE run, not just lint.
> (0b) **THE STARHOOK POOL IS 15 KITS** (sl-0200: +8 routed, SEVEN
> shipped at roster 40-46; SERIAL 27 untouched — defs are data):
> three anchors (gap_carousel g1 / decel_orchard g3 / FOUR-PHASE
> pulse_cross g4), three flankers (sickle_weaver g1 /
> dart_skirmisher g2 / two-phase halo_lasher g3), and **tide_stalker
> g3 — THE one sanctioned TRUE PURSUER** (policy 0, pursuit
> 2.4/2.8/3.2 strictly under the 3.6 floor, wake rings off the
> advance; six lanes green incl. explicit CORNER-AUDIT battery rows
> — the wall-pin class mechanized). **The second pursuer candidate
> (shadow_hound) FAILED the fairness floor across seven proof
> iterations and was REPORTED, NOT SHIPPED** (the sl-0200 routing's
> own clause; the structural finding: a close-materializing fan from
> a pursuing body cannot be proven floor-fair in the one-room box —
> single-threat phases are the pursuer-fair grammar). Pools 5/5/5
> per biome, catch 70/80 held; battery 54→62 rows; goldens
> UNTOUCHED; strobe 15 kits zero flips; the designer's dives rule
> every [T].

> **WHERE THE PROJECT STANDS IN ONE BREATH:** REFINEMENT ROUND 1 IS
> LANDED, GATED, AND PUSHED (2026-08-04 night session; resolutions
> sl-0192..0197): **(1) THE DUNGEON WAS INVISIBLE, NOT SMALL**
> (sl-0186, game 4733560) — the serpentine's props spoke a foreign
> dialect ('species' vs 'name') and the resolver ABORT erased every
> floor and wall tile while collision stayed real; the one-room fixed
> rift camera framed 4.0% of the arena; a stale static cast-capture
> mounted split panes over console jumps. Fixed (dialect + hardened
> builder + rift_path follow-camera routing + capture lifecycle +
> path-mode rendering with the backdrop UNDER the authored tiles);
> THE LESSON IS A GATE STEP NOW (dungeon_walk_test: arena render
> resolution for EVERY scenario + the full serpentine traversed on
> real Kinematics) — **the designer RE-WALKS before sl-0186 closes
> for good**. (2) **THE EIGHT KITS ARE SHORT, DENSE, AND ALIVE**
> (sl-0187+0188, game 427bd32) — gate 7 re-pinned [20,60]s, HP
> re-derived 30–45s each, cooldowns ~×0.7; the standing-there statue
> typed (keep-range satisfaction + long cooldowns) and killed via the
> designer's own split: ROOM-PATTERN = ANCHOR (ring_nest, decel_wall,
> zone_constellation, pulse_lattice — the choreography fills the
> room; the anchored decel_wall also can never leave the dungeon boss
> room again) vs BEHAVIOURAL = FLANKER with climbing speed ladders
> ≤3.2 (twin_helix, sine_shoal, boomerang_veil, cross_burst); the law
> amended to NEVER-A-CHASER (gather_test family pins); proofs
> re-paced + re-recorded both lanes, one never-weaken iteration
> (sine_shoal's frozen-entry-beat graze — the entry beat 30→40 moved
> what no P2 param could); strobe re-probed all-zero. (3) **NAMES
> OVER FUNCTIONAL NPCS** (sl-0190, game 4f7a660) — role-label plates
> (Banker/Merchant/Trader/Tackle Keeper/Quest Giver) over exactly the
> def_cell station class, icon-above-name at the icons' anchor,
> data/npc_names.json ships empty as the designer's proper-name hook;
> the crowd is structurally unplateable. (4) **THE JUMPS + THE
> TOOLBELT** (sl-0189+0191) — `rift list|<boss_id>|catch|dungeon`
> jumps + `level/gold/gear/tackle/fish/tp` grants riding NEW
> dirty-stamping SimWorld commands (replays refuse, verdicts
> auto-PROVISIONAL — the god contract; zero format growth; smoke pair
> byte-identical). NO feel verdicts anywhere — every number/key/name
> [T]; the designer's replay of the round is the next word. Starhook
> names still ride the COSMIC VOCABULARY RAIL (sl-0182). **(5) THE
> FORAGING BUILD LANDED BEHIND THE ROUND (sl-0198, the sl-0168 spec;
> SERIAL 26→27, WSR v3 untouched)** — F at a shimmer-marked ambient
> forage node → the gather bar (interrupts on move/hit) → a loot bag
> of per-species MATERIALS into the forage WALLET (zero bag
> capacity; profile by species name, ghost-tolerant; visible as
> plain-named inventory tiles under the bag). The stillness verb +
> anti-AFK rule RETIRED. Nodes spawn ambiently on the ~1.9k-cell
> prop pool (candidacy never simultaneity — cap starts 15 [T] in
> the ruled 12-18 band, world-wide); the old 12 forage POIs are
> ordinary pool members.

**COLD START — this handoff assumes NO prior context.** Read the game
repo's `CLAUDE.md` first (auto-loads; BINDING contract + the
authoritative milestone tracker — its milestone tail is the full
append-only history this file deliberately does not repeat). This file
carries the current session state and the hard-won lessons the
contract doesn't. Nothing repo-side gates on the Claude account; git
identity and gh auth are machine-local; this file + `CLAUDE.md` +
planning `docs/23` are the complete context carrier. (Serialization is
**SERIAL 27** — 23 the bag, 24 loot bags, 25 the bank, 26 the gear
seam, 27 THE FORAGING BUILD (sl-0198: ambient forage nodes
pos+species on the world; the gather bar target+ticks + the
forage_mats wallet on PlayerState; the sl-0105 stillness fields
RETIRED). **WSR VERSION 3** (InputFrame 17 bytes; v2 replays refuse
loudly — the foraging verb rides EXISTING inputs, zero format
growth). NEXT BUMP IS **28**. Smoke record pair since SERIAL 27:
316bc4c7cc5004be / 30fa8ce4fb8f7b27.)

## §0 What this project is (60 seconds)

Wildshot Adventures: a solo-developed RotMG-inspired top-down realtime
bullet-hell ARPG in **Godot 4.6.2 (pinned), typed GDScript, custom
deterministic sim, no Godot physics in gameplay**. Serialization
SERIAL 27 (next bump 28); replay format WSR v3; goldens current;
local gates green.

Current phase: **THE SLICE ERA** (sl-0098: the world is the test).
**Slice v0.1 is the ONE milestone**: the four-zone dusk overworld
(b77) as a small scale of the full game — living in the built world
(leave a settlement, fight, loot, level in-bracket, die to the
CORE-43 city-fee death and walk back; the world persists and refills,
NO run framing) is what the docs/19 three-sentence bar judges, over
the designer's week, then 2–3 warm watched first-touches. Build
order: chapter by chapter, **Green Country first** (planning
docs/23). S0 foundations + S1 Green Country + the menu pass + the
gear seam + the starhook boss batch are ALL COMPLETE; the designer
is PLAYING, and their verdicts route the refinement rounds. **S2
does not start without its own word.**

- **Game repo (you are here):** `C:\Users\headc\Documents\Wildshot-Adventures`,
  branch `main`. Implements; never reinterprets design.
- **Planning repo (design authority):**
  `C:\Users\headc\Documents\Wildshot_adventure_final_planning` — ONE
  branch, `claude/questionnaire-note-taking-9vl2sl` (no main; do not
  create one). Its `tools/sync_log.json` is the cross-repo logbook
  (entries through **sl-0189** as of this writing);
  `tools/ecosystem.lock.json` holds the pins. A planning-side sweep
  agent commits between (and DURING) game sessions — always
  `git pull --ff-only` before planning writes, and verify the next
  free sl-#### id AT WRITE TIME (gotcha 25; it has raced repeatedly,
  most recently mid-close when sl-0182 landed under a prepared
  entry).
- **Key planning docs for the slice:** `docs/23-SLICE_BUILD_PLAN.md`
  (THE build plan + the starhook expansion charter + the naming
  rail) · `docs/22-STAT_SYSTEM.md` (the nine ruled blocks — mirrored
  game-side in `data/balance_frame.json`) · `docs/19` (the bar).
- **The ecosystem map** (planning `docs/16-ECOSYSTEM_MAP.md`) names
  all seven repos and the hard cross-repo rules. **LANE RULE: game
  sessions NEVER execute other repos' plans/work.** Upstream needs
  become recorded asks. Reading other repos for context is fine;
  INTAKING their delivered packs is game-repo work.

## §0.2 The era history (compressed — CLAUDE.md's tail is the record)

- **M0–M8**: the lab era — deterministic sim, the proof battery +
  DodgeBot, replay/goldens, export + lockdown, packs intaken
  (worlds b65/b77 + tileforge pairing, enemy/boss/NPC/icon/menu/
  audio packs, per-pack pins + passports).
- **S0 (sl-0100..0103)**: the stat frame in the sim (class lane;
  legacy lane byte-frozen), the living world (leash/tether/respawn
  over the content pack's 193 sites), CORE-43 overworld death, NPCs
  + icons wired. Speed anchor re-ruled: stat 100 == **3.6 t/s**
  (floor lane 3.6 / cap lane 4.14 forever).
- **S1 (sl-0104/0105/0113)**: the Green roster (14 families, all
  variants), T1 loot + the one item-text grammar, OLD TUSK + his
  Hide, THE WARREN + KING GRUBB (the two dungeon laws: pack
  separations beyond euclidean aggro, ONE radial per boss room),
  quests v1, STARHOOK v2 (the designer's prototype #2 IS the built
  game — read planning `notes/reference/starhook-proto2/INDEX.md`
  before touching starhook; its corrections are law), the interact
  verb (F) + the C sheet + HUD relayout.
- **Starhook laws that stand:** THE DRAG IS CUT (sl-0123 — arena
  combat is NORMAL combat; the rift's pull lives in THE LINE only:
  strain clock / deep edge / three lives / graces; gather_test pins
  the absence — reintroducing drag would be a NEW designed system);
  the split ratio is [T] live-flippable (sl-0125); the win is the
  kill; fish persist per-species; water fishing PARKED (sl-0111).
- **THE GREEN-DAYS PASS (sl-0119..0132)**: C-sheet fixed, quest
  pull kit, boss sprites, NPC desync, firing ×1.25 exact, THE BAG
  (cap 20, recorded bag_op byte, WSR v3), LOOT BAGS ([B] loot-all),
  THE BANK (112.5,182.5), VENDORS v1 (106.5,182.5 + 106.5,180.5).
- **THE MENU PASS v2 (sl-0143..0157)**: panel2 chrome everywhere,
  the two-tab C menu, the offer dialogue (accept = recorded op),
  stations F-open, Esc/O menu-first, the unique reveal, the
  interactability sweep (notes/INTERACT_SWEEP.md + its addendum).
- **THE GEAR SEAM (sl-0177/0178, SERIAL 26)**: rods are starhooking
  weapons (12-rod catalog over four family norms; originals = the
  free level-grant spine, EXACT-pinned; new rods purchase/drop-only
  behind ownership bits); rift chest/helm (single-stat rows; the
  drain's 1-hp chunks ride THE formula's floor — the clock never
  mitigates); THE TACKLE KEEPER at 110.5,178.5 (fish-priced,
  recorded ops 144..175 buy / 176..191 equip; the fish wallet is
  IN-SIM); rare catches drop Green-grade pieces; profile all BY ID
  with unknown-species preservation (the fish-first word);
  balance_calc GATE 6 validates the catalog including the .tres
  frames. Design record: notes/TACKLE_SEAM.md (+ its supersession
  banner).
- **THE STARHOOK BOSS EXPANSION + DUNGEON TEST (sl-0180/0181,
  three gated waves)**: casts DRAW A FIGHT (per-biome weighted
  pools [T], catch-heavy, fail-safe fallback); EIGHT kits at roster
  30-37 (descriptive placeholder ids awaiting the cosmic-rail
  naming; hp 1400-2800 — ALL RE-DERIVE at the sl-0187 20-60 s
  re-rule); EIGHT new patterns (ids 30-37; the first hostile
  SINE/BOOMERANG/DECELERATE uses — the bot's closed-form projection
  models all four programs; two precessing rotors; the alternating
  half-gap ring; a galaxy zone); fight-length GATE 7; the
  per-pattern NO-STROBE probe; PHASED-ONLY catch landing (mob
  deaths bank gold, never end a dive); THE CONSTELLATION (fish
  stacks under the bag — the wallet stays the ONE truth, zero cap
  impact) + THE RIFTER PANEL (C tab; click-cycles owned gear via
  the recorded op; equip legal anywhere, buy at the station); the
  DUNGEON PATH (64x44 serpentine, phaseless mobs, decel_wall at
  the end, the slow dungeon line 0.1/s [T], console `dungeon`) —
  **BROKEN IN REAL PLAY per sl-0186, diagnosis owns round 1**.
  Design record: notes/RIFT_BOSS_POOL.md (+ its supersession
  banner).
- **THE QUEST-PULL FINDINGS (sl-0175/0176, view-only)**: map
  markers mirror the overhead giver-icon model on BOTH map surfaces
  (gold BANG available / green RING turn-in / amber DIAMOND tracked
  VISIT; one model); giver icons anchor the BODY cell at LIFT 18
  (occlusion structural 35>32>30). KILL/COLLECT still carry no
  objective cell; the capital giver still has no body — both
  planning's calls.
- **THE FORAGING BUILD (sl-0198, SERIAL 27)**: F-press gather bar at
  shimmer-marked ambient nodes (the rift spawner's second rng_misc
  consumer; the ~1.9k prop cells = candidacy, cap 15 [T] world-wide);
  materials land per-species in the forage WALLET (zero bag capacity,
  profile by name, ghost-tolerant; plain-named inventory tiles). The
  sl-0105 stillness verb + anti-AFK RETIRED. The trade-in shop is
  FUTURE.
- **THE POOL EXTENSION + CI GREEN (sl-0200/0201)**: the boss pool is
  15 kits at roster 30-37 + 40-46 (7A/7F/1P); tide_stalker = THE one
  sanctioned pursuer (gather_test pins the list + the strict <3.6
  ceiling + one-chaser-max); shadow_hound = the recorded FAILED
  pursuer experiment (never shipped); patterns 38-40/42-45 (id 41
  retired with the hound); pools 5/5/5; CI runs green whole (~50 s)
  since the sl-0201 three-layer repair.

## §0.5 Working with the designer

Solo dev, handle mmoabsurd (publicly **sarepat** — itch page
https://sarepat.itch.io/wildshot-adventures is LIVE with devlog +
GIFs). Big nerd, goes hard. Works a 15:00–23:00 shift — **"rested"
keys on hours into THEIR waking day, never wall clock** (home at
midnight ≈ their 17:00). They iterate by PLAYING: ship, then relaunch
the game for them (`Start-Process` detached `~/bin/godot.exe
--path .`; window opens BEHIND — front it via user32
SetForegroundWindow; kill old godot first — the console wrapper
spawns an engine child named plain "godot" — but NEVER kill a window
they are actively playing). **Compact keyboard: NO F1–F12 keys,
ever.** Standing authority to commit and push both repos at every
clean seam.

- **Two-tier verdicts:** in-session designer calls count immediately;
  feel items additionally get one rested ratification. Marathons +
  dirty runs stay PROVISIONAL regardless. Feel verdicts accept rested
  humans only — never a bot.
- **THE DECISION DECK is the decision register** (planning
  `tools/decision_deck.html` + register JSON). **PLAIN-LANGUAGE RULE:
  anything written FOR the designer uses zero repo jargon** — say
  what each option concretely does. They asked twice; it's law.
- **NAMING (sl-0182):** inside the starhook lane names are WANTED on
  the COSMIC vocabulary rail (galaxy/dimension/nebula/constellation/
  star/rift...); fishing-metaphor words fail the rail. The
  no-coined-names law stands unchanged OVERWORLD; the designer's
  naming act rules everywhere.
- Private by temperament — public surface stays game-forward. They
  licensed nudging the weekly-GIF cadence, one line at natural seams.
- When they ship a pack mid-task, integrating it beats finishing your
  plan. When they ask to SEE something, render and send it (4×
  nearest-neighbor reads well). When THEY show YOU something, treat
  it as primary evidence — read the frames.
- **When they state a want three times, build THAT** (sl-0078 law).
- **Their feel words name SYSTEMS, not necessarily the one you're
  holding** — check which lever they're actually touching before
  diagnosing yours. Their honest self-corrections are rulings too
  (sl-0187: "i think i exagurated the length").
- GIF flow they use: G starts, G again stops (any length; ● REC
  badge while on); `tools/gif.ps1 -FramesDir <dump>` converts; full
  recordings are BIG (~80 MB/30 s) — cut posting-size versions with
  ffmpeg fps/scale filters on request.

## §1 Where things stand (2026-08-05, the activity pass landed)

**Everything routed through sl-0208 is LANDED AND PUSHED.** THE
COMBAT RESHAPE (paste B; sl-0208 then sl-0207; game df624d4/1f6e964/
5a87cca; resolutions sl-0214/0215): the hurtbox halved to 0.175 with
every rift-kit margin rising EXACTLY +0.175 (the PLANNING ENVELOPE —
gotcha 49 — keeps the record's dances while true-body gains land as
margin); the melee-whiff finding measured + pinned (a lone rusher
cannot kill a standing player now — the sl-0213 projectile-ecosystem
word owns that tuning round); cadences re-composed x1.51/1.54/1.6
DPS-budget-neutral with per-class DEXTERITY ladders (calc gate 8
bounds the ripple ≤9.5%), the hits-band re-pinned [3,5]→[5,8]
(hits = TTK × rate — reported loudly), rods verified untouched, the
battery byte-identical (the seam never touches the legacy lane).
The designer play-accepted the quick three same night (sl-0212).
Before that, the quick-three session (sl-0204/0205/0206, game
a01bbe5/563eb32/5ca812c): the INPUT-SWALLOW LAW (console-open swallows every
non-console binding — the `typing` predicate never knew the console;
the gif recorder carried a bare G poll; both mechanized as the 33rd
fixed step + a repo-wide poll scan), the capital hub giver's BODY
(the errand bang rode bare plaza ground — the spawn-parked slot was
excluded from zone assignment; the Wardens' representative now
stands one cell north [T], casting provisional), and NAMEPLATES ON
THE FONT GRID (the sl-0190 plates rendered the 10px-em kit pixel
font at 8px — the game's only off-grid consumer; letterforms
genuinely mutated; 10/12/baseline+9 now, license-line pin in the
wiring test). Before that, the afternoon session: three CI-repair
commits (24a0cac / ed77943 / 8f2bd7d — sl-0201) + the sl-0200 seam
(e5a5f30, 59 files) sealed by a post-commit full gate. The
one-command ship gate `tools/pretester_check.ps1` runs ALL GREEN —
**33 fixed steps + the two-lane battery (62 rows / 121-run pool)
byte-identical + export both artifacts + lockdown probe — 17.5 min
at the sl-0200 seal; view-only seams ride `-SkipBattery` (~3 min)**.
No deferred-gate debt. **CI is GREEN whole (~50 s per push) since
sl-0201** — `gh run list` after every push; watch the run conclusion
itself now, not just lint (gotcha #26's watching gap is what hid a
6h hang for three days).

The round's engineering is DONE; the acceptance is the designer's:
**re-walk the dungeon** (sl-0186's own routed term) and **replay
the eight kits** at the new lengths/families — the `rift` jumps +
the toolbelt put every fight one console line away at proper gear.

## §2 Open — designer-side (do not nag; the deck + planning carry these)

- **RE-WALK THE DUNGEON** (`dungeon` or `rift dungeon` in the dev
  console) — sl-0186 resolves for good on their walk, not before.
  The serpentine now RENDERS (their 'invisible walls' were unplaced
  tiles over real collision) under a follow camera.
- **REPLAY THE EIGHT KITS** (`rift <boss_id>` jumps straight in;
  `gear`/`tackle`/`level max` set up proper loadouts) — 20-60s
  lengths, anchor-vs-flanker life, all [T] and theirs to move.
- **DIVE THE SEVEN NEW KITS (sl-0200)** — `rift gap_carousel|
  sickle_weaver|dart_skirmisher|decel_orchard|halo_lasher|
  tide_stalker|pulse_cross`; 25-50s each; **tide_stalker is the one
  TRUE PURSUER** (their "maybe 1 or 2 pursuiters" word landed at
  ONE: the second candidate failed the fairness floor under proofs
  and was reported, not shipped — their word routes any rematch of
  the experiment); pool weights/grades/ladders/biome pins ALL [T].
- **NAMES, whenever words come** (the cosmic rail): boss kit names,
  rod names, species names, the tackle keeper's sign — everything
  is data-keyed for renames; the constellation is already live.
- **PLAY surfaces still awaiting their hands** (all [T]): the
  tackle shop + gear loop (prices, rates, rod feel, the two
  acquisition shapes — free-spine-vs-purchase and rare-drop rates),
  the boss pool weights ("a boss sighting is an event" — flip the
  weights if it isn't), the constellation + rifter panel, the menu
  pass keys/timings/placements, quest markers' shapes/colors/lift,
  **FORAGING IN GREEN (sl-0198)**: the shimmer hunt (cap 15 /
  interval / chance), the bar length (45t), the 1-2 yields, the
  shimmer look — every knob [T] in the balance_frame `forage`
  block; `forage tp` jumps to a live shimmer for a quick look.
- **PLAY THE COMBAT RESHAPE (sl-0208/0207, all [T])**: the halved
  hitbox in real dodging; the new fire rates from level 1 (bow
  4.0/s — the Quickdraw-start wish); the dexterity steps at levels
  8/16/23 (bow skips 16 — the granularity finding); the Ring of
  the Quick Hand; Quickdraw stacking (bow peaks 7.5/s at L23).
  Their verdicts route re-tunes through the calculator.
- **LIVING IN GREEN** — the chapter gate: feel one-liners as they
  play; batch tuning numbers into single gate runs.
- **THE S2 GO WORD** — the next chapter starts only on its routing.
- Weekly GIF (a hooked boss or the fixed dungeon walk is prime
  material).
- Standing: rested ratification stack (M2 formal close, six
  ordinaries, marathon-provisional verdicts), CORE-50 render
  checklist pass, onboarding copy voice, icon tool-source push from
  the other PC, crosshair styles on screen, b65 city walk (feel
  menu).

## §3 Open — engineering

- **REFINEMENT ROUND 1 (routed, builds on its paste — sl-0186..
  0189):** (1) THE DUNGEON DIAGNOSIS FIRST — what actually loads vs
  data/arena_rift_path.json (did the serpentine load at all? default
  arena rect? walkability-vs-render mismatch? shafts blocking?);
  name the cause honestly, fix, commit REAL-WALK evidence captures;
  the designer re-walks before resolution. Lesson candidate to
  record at resolution: script proofs prove the sim's fights, never
  the designer's WALK — a human-shaped load check belongs in the
  gate for walked content. (2) Gate 7 re-pins [20,60] s; all eight
  kits' hp re-derive through the calculator (intense = shorter AND
  denser); goldens re-record only if a recorded run shifts.
  (3) Boss life: assign each kit ROOM-PATTERN or BEHAVIOURAL [P at
  build], rebuild their life, re-run all proofs + the no-strobe
  probe per changed kit (the one-room law is AMENDED for rift
  bosses by the designer's word; the fairness floor is absolute).
  (4) The console jump family: every boss kit by id + dungeons + a
  plain catch + a list form (the `dungeon` one-flag precedent).
- **THE FORAGING SEAM (sl-0168) — BUILT (sl-0198, SERIAL 27)**: the
  F-press gather bar + ambient shimmer nodes + materials-as-
  species-currency landed whole; the cosmetic TRADE-IN SHOP stays
  FUTURE (the counts store correctly from day one; the sizing
  record: notes/FORAGE_SEAM_SIZING.md).
- **THE COMBAT RESHAPE — BUILT (sl-0208/0207, SERIAL 27 held)**: the
  hitbox halving landed with the margins table
  (reports/hitbox_margins_sl0208.md) and the cadence re-composition
  landed budget-neutral (calc gate 8). What it OPENED: the sl-0213
  melee-contribution round (close-range fighters' blade patterns
  were shaped against the fat body — a lone rusher cannot kill a
  standing player now; measured in rusher_lethality_probe, pinned in
  the smoke; pattern-data tuning on planning's routing — pins RED
  deliberately when the re-tune lands).
- **Queued-not-routed:** class trees (sl-0169 partial: pattern law +
  5/15/25 skeleton + sword L5; the rest waits on designer testing);
  water fishing PARKED; S2 on its own word.
- Recorded honest gaps (planning owns the calls): KILL/COLLECT
  quests have no objective cell; the capital zone-hub giver has no
  NPC body; crowd NPCs have no interact response BY DESIGN
  (villager one-liners incremental [T]); a drop underfoot AT a
  station answers on both layers in one press (watch item [T]);
  the reveal's dragon stage waits on a sheet; the tester-facing
  map = the doc-13 Part II round; the ×1.5 firing wish SHIPPED at
  sl-0207 (the hits band moved [3,5]→[5,8] by the routing's own
  lever — the sl-0120 blocker resolved, reported); bosses are
  biome-PINNED v1
  and ignore cast rarity v1; a physical-fish-items flip (fish as
  real bag items) would be its own sim seam; drain/grace/lives
  gear stats are a named future family.
- Density and every rate are DATA ([T] everywhere) — expect batched
  tuning from play.
- Intakes as deliveries land (runbook + per-pack pins + paired-TF
  doctrine; passport + fixed-gate pattern; NPC/icon re-drops re-run
  import_*.py + the wiring test).
- Ledger: OPEN = #16 (replay character block — grown through
  SERIAL 26's gear fields; profile replays refuse verification
  honestly) and #17 (fit-rule round-1 scope). #7 amended (async
  readback stays the improvement path).
- Tooling candidate (recorded, unrouted): lane-suffixed repro
  filenames in the battery pool.

## §4 Session rituals (the gates)

Before every commit, per touched area:
- format: `python -m gdtoolkit.formatter <files>` (it REFLOWS —
  re-grep before editing formatted files).
- smoke: `godot_console --headless --path . --script tests/determinism/determinism_smoke.gd`.
- goldens: any sim/serialization change ⇒ bump SERIAL_VERSION
  (next bump is **28**), regenerate + verify ×10, say so in the
  commit. InputFrame layout changes additionally bump
  `input/replay_format.gd` VERSION (now **3**; old .wsr refuse
  loudly; committed repro/golden replays re-record deliberately
  WITH the bump).
- boot: `godot_console --headless --path . --quit-after 90` grep
  "arena ready|ERROR" (use "ERROR", not "SCRIPT ERROR").
- proofs: re-run canaries + every touched proof with CANONICAL SEEDS
  (table below), BOTH LANES; commit reports
  (`git add -f reports/...`). Unchanged scenarios must reproduce
  BYTE-IDENTICAL.
- the one-command gate: `pwsh tools/pretester_check.ps1` = **33
  fixed steps + the 121-run two-lane battery (62 rows; pinned FAILs
  are expectations) + export + lockdown — ~17 min ALL GREEN**
  (tools/battery_runner.ps1 pool: default = physical cores, cap 10,
  longest-first; every verdict marker+exit-code gated; the
  reports/-clean byte gate is the final word). `-Workers 1` =
  serial. A pool row failure ALWAYS re-verifies solo before
  diagnosis — but remember gotcha #32's catch. Exit 0 = ship-ready.
  It REFUSES to run beside another same-project Godot instance
  (incl. the designer's game window — wait, never kill; individual
  steps are the recorded fallback). View-only seams may run
  `-SkipBattery` (~3.1 min) per the icon-intake precedent; every
  SIM seam gets the full gate, and a re-baseline is not done until
  the full gate runs ON THE COMMITTED TREE (gotchas 32 + 43).
- godot binaries: `~/bin/godot_console.exe` (headless) / `godot.exe`
  (play, detached + front).
- hourslog start/stop/note around ALL work (PROD-01); honest stops at
  seams (incl. waits on the designer's window).
- One approved decision = one commit; push BOTH repos at clean seams.
- Cross-repo events ⇒ sync-log entry planning-side (doc 18; no
  event, no entry). Gotcha #25 before appending — the log RACES
  (a live planning seat took an id out from under a prepared entry
  mid-close this batch; the write-time guard caught it).
- After any push: `gh run list` → the lint job concluding is the
  fast signal (gotcha #26).

### Canonical proof battery (state 2026-08-05 — 62 rows / 121-run
### pool; POLICY OF RECORD = REACTIVE; SERIAL 27; WSR v3; Warden 575;
### b65 flood 34641; b77 current; HURTBOX 0.175 since sl-0208 with
### the bot PLANNING at the proven 0.35 envelope — gotcha 49; the
### whole record re-baselined with margins +0.175 across the board,
### the table committed at reports/hitbox_margins_sl0208.md).
### TWO LANES FOREVER (docs/22 block 6): floor --speed=3.6 (the
### CORE-53 floor), cap --speed=4.14 (the 115 hard cap; reports keep
### dodge_*_cap115 names). Primary rows stay floor-only
### watch-baselines: rusher PASS, forest_walk PASS, first_contact
### FAIL. meet_leadshot cap RE-PINNED FAIL→PASS at sl-0208 (the
### sl-0102 INTERCEPT graze lands inside the old shell and misses
### the true body — same dance, no hit; the halving in one row).
### All pins WATCHED: a verdict move = the sim (or policy) changed
### under us.

| scenario | seeds | ticks | expected (reactive record, floor/cap) |
|---|---|---|---|
| canary_trivial | 1,2,3,4,5 | 3600 | PASS / PASS (MUST-PASS) |
| canary_undodgeable | 1,2,3 | 1800 | FAIL / FAIL (MUST-FAIL, geometric 4-wall box) |
| proof_rusher / husk_archer | 1..5 | 3600 | PASS / PASS |
| proof_fanmaw / fanmaw_inside / ringer / leadshot / blightcaster | ladders 203..211 | 3600 | PASS / PASS |
| forest_walk / world_walk / first_contact / second_contact compositions | 1,2,3 (2nd: 10..14) | 3600 | PASS / PASS |
| proof_yw_p1/p2/p3/full (575 schedule) | ladders 208..215 | 3600 | PASS / PASS ×4 |
| proof_rusher **[primary]** / forest_walk **[primary]** | 1..5 / 1,2,3 | 3600 | PASS (watch-baselines) |
| first_contact **[primary]** | 1,2,3 | 3600 | **FAIL — the standing primary baseline** |
| lab_default + meet_blightcaster/leadshot/yard_warden | 1,2,3 | 3600 | PASS / PASS (meet_leadshot cap re-pinned FAIL→PASS at sl-0208) |
| loop_ring1/2/3 + proof_brk_site | 1,2,3 | 3600 | PASS / PASS |
| overworld_green/dry/wet/cold + green_boss compositions | 1,2,3 | 3600 | PASS / PASS |
| proof_old_tusk / proof_warren / proof_king_grubb | 1,2,3 | 3600 | PASS / PASS |
| proof_slice_leash / proof_green_camp / proof_green_ranged | 1,2,3 | 3600 | PASS / PASS |
| proof_rift_catch / _rare / _void / _comet (the line's rules aboard; drains never count as hits) | 1,2,3 | 3600 | PASS / PASS |
| **proof_boss_twin_helix / ring_nest / sine_shoal / boomerang_veil / decel_wall / zone_constellation / cross_burst / pulse_lattice** (sl-0180: schedule-paced full fights, every flip mid-flight; margins 0.120–0.123; zone_constellation floor near reads −0.000 = the M6 hazard-proximity reporting nit, hits=0 is the verdict) | 1,2,3 | 3600 | PASS / PASS ×8 (the sl-0187 20-60 s lengths + sl-0188 life families live; margins ~0.28-0.41 since the sl-0208 re-baseline) |
| **proof_dungeon_corridor (darter pair) / proof_dungeon_lurker (solo) / proof_dungeon_bossroom** (sl-0180 wave 2 — proofs prove THE FIGHTS THE PLAYER GETS: the play path's packs sit 20+ apart, tether-sequential) | 1,2,3 | 3600 | PASS / PASS ×3 (the sl-0186 render fix landed — the serpentine draws under a follow camera; the designer's re-walk stays the open acceptance) |
| **proof_boss_gap_carousel / sickle_weaver / dart_skirmisher / decel_orchard / halo_lasher / tide_stalker / tide_stalker_corner / pulse_cross** (sl-0200: the pool extension, same schedule-paced shape; tide_stalker = THE sanctioned pursuer, every phase strictly <3.6; the _corner row = the explicit wall-pin audit — bait spawned IN the worst stub pocket, pursuit on top) | 1,2,3 | 3600 | PASS / PASS ×8 |

Runner: `godot_console --headless --path . --script game/bots/bot_runner.gd -- --scenario=<id> --speed=3.6 --seeds=<list> --ticks=<n> [--out=res://reports/<name>.json] [--policy=primary|orbit|axis]`
(default policy = reactive; compositions need the explicit --out
names; cap runs use --speed=4.14 + an explicit --out=..._cap115.json).

## Hard-won gotchas (cost real debugging — read ALL of them)

1. **A silently hanging `--script` run = a PARSE ERROR.** Godot prints
   to stderr and the SceneTree idles FOREVER. Kill it, re-run unpiped
   at tiny scale. Then kill orphaned godot_console processes — NOTE
   the console wrapper spawns an engine child named plain "godot";
   process-kill filters must include both names. ALSO: main.gd cannot
   compile under `--script` runs (it reads the Config autoload) — a
   test that preloads main.gd hangs exactly this way (sl-0065 lesson).
2. GDScript type inference fails on duck-typed member access — hoist
   typed locals ALWAYS (bit again at S0 seam 2: `e.pos.distance_to`
   on a duck-typed loop var). `as` binds looser than `!=`. `sqrtf`
   doesn't exist (it's `sqrt`).
3. NEVER write .tres/.json/.gd/.cfg via PowerShell Set-Content (UTF-8
   BOM ⇒ Godot silently loads null). Use the Write tool or
   `[IO.File]::WriteAllText` (no BOM).
4. gdformat REFLOWS code — re-grep the actual text before Edit. It
   also WRAPS long lines, which can break single-line lint anchors
   (lockdown lint pins) — keep pinned lines short (sl-0065 lesson).
5. NO F-row keys. Current (MENU-PASS ERA): **Esc/O run MENU-FIRST**
   (sl-0145: one press closes the topmost open menu — drop-confirm,
   offer, the C menu, open stations — via driver.esc_intercept;
   NOTHING open = the one pause+options menu, the sl-0109 law
   beneath; the CORE-31 pause bit stays the driver's), **F interact**
   (pickups-into-bag / givers offer+turn-in / rift casts / FORAGE
   GATHERS at shimmer nodes (sl-0198: the bar interrupts on move/hit;
   a rift node wins a shared press) /
   BANK+VENDOR+TACKLE MENUS — stations never walk-over now,
   sl-0145/0147; F-as-confirm accepts in the open offer window),
   **C = THE MENU** (ONE window, two tabs: character + quest log;
   opens on the last-used tab; mouse sanctioned in it), **L =
   quest-log deep-link**, **B loot-all** (loot bags STAY walk-over
   by the designer's own word), right-click drop = CONFIRM dialog
   then the toast, I interp, [ ] speed presets, -/= free step
   (dev-only), G gif (start/stop, start-to-finish), R rod swap
   (rifts; cycles SELECTABLE rods — level + ownership), J replay,
   T reset, M meter, H hitboxes, N map (dev-only, pack scenarios
   only), ` console (dev-only; `dungeon` jumps the dungeon path —
   sl-0189 grew this into the full jump family; sl-0198 adds
   `forage <n>|tp`), Alt+Enter
   fullscreen, Space = ability AND respawn-now while dead
   (persistent worlds). E stays RATIFIED autofire — never rebind it
   casually. Any-input SKIPS the unique reveal while it plays.
6. Sim = pure core: no Nodes/clock/RNG; prev_pos is presentation-only;
   PackedArrays share storage — `.duplicate()` for snapshots.
7. When a proof fails: read the heatmap in the report JSON first
   (a whole-run heat blob in one spot = the bot PARKED somewhere);
   replay the run LIVE with a scratch forensics driver before
   theorizing; then iterate the ARENA/LAYOUT or the POLICY, never
   weaken the proof. Layout iterations on loop content must be
   MIRRORED in both the proof tres and data/scenarios/loop.tres.
   ADDENDUM (S0 cap-lane lesson): GLOBAL policy scoring knobs are
   whack-a-mole across 30+ rows — prefer PINNING a lattice-class
   FAIL with cause over policy surgery mid-seam.
8. Smoke micro-worlds use the LAB bitgrid — keep scripted movement in
   the proven-open pocket (x 16–31, y 8–20). The wall-slide floor
   derives from PlayerMove.TERRAIN_RADIUS (now 1.15625) — a retune
   moves the contract with it.
9. The undodgeable canary is GEOMETRIC (4 emitters boxing spawn). If a
   smarter policy starts passing it, the canary must get harder;
   never ship with MUST-FAIL passing. (Verified failing at 3.6 AND
   4.14.)
10. DodgeBot semantics: ANCHOR enemies = data-derived keep-out discs,
    excluded from the orbit centroid; hazard zones are crossable
    between pulses; negative hazard clearance is legal play. The
    verdict field is the evidence.
11. Windows console pipes can swallow a run's tail — check the report
    JSON on disk before re-running. **GATES READ EXIT CODES, NOT
    PROSE.** (Re-earned THIS batch: a gate piped to `tail` reported
    exit 0 around a FAIL verdict — the pipe ate the code; run gates
    unpiped to a log file and echo `$?`.)
12. **NEVER edit sim data while a battery runs** — each battery row is
    its own Godot process reading the working tree. Same for docs
    during the pretester's export step. Md-only edits are
    gate-neutral (no step reads them) — everything else waits.
13. **Headless boots CANNOT see render bugs.** Designer eyes are the
    render gate — or a windowed probe writing committed PNG evidence;
    read the captures yourself before shipping. (And per sl-0186's
    pending lesson: script proofs don't prove the designer's WALK
    either.)
14. **Porosity diag pins are PER-PACK-DROP** (b65 = 44, overworld =
    60 at b77) — a drop that moves a number gets eyeballed and
    re-pinned deliberately, never silently; type every changed cell.
    Walkable-unreachable cells are LEGAL under WYSIWYG.
15. The verdict console command enforces sources (feel rejects
    bot-proof); god/slow-mo stamp runs replay-dirty. Feel notes are
    PROVISIONAL until the two-tier rested pass.
16. Godot user data: `%APPDATA%\Godot\app_userdata\Wildshot Adventures\`
    — logs/session.jsonl (evidence stream), logs/terrain.jsonl,
    gif_frames/ (G dumps; tools/gif.ps1 converts), replays/,
    character.json (v2: class-backed; v1 reads as no-character;
    carries ring_id/armor_item_id, quests BY ID, the starhook block
    (level/xp/rod/skins/catches/fish{}) + the gear-era keys
    (starhook_rods/tackle/chest/helm — all BY ID; unknown fish
    species keys are PRESERVED on harvest, the fish-first word)).
17. The designer's screen recordings land in
    `%LOCALAPPDATA%\Packages\Microsoft.ScreenSketch_*\TempState\Recordings\`
    — extract frames with ffmpeg and READ them; their footage
    outranks your theories. Their annotated screenshots land in
    planning `notes/evidence/`.
18. **New importable resources (wav/ogg/png) need a
    `godot_console --headless --path . --import` pass** before the
    boot gate. Commit the generated `.import`/`.uid` sidecars — .uid
    files can materialize at the NEXT editor scan (sweep them at the
    following seam if one appears post-commit).
19. **The pretester's Godot guard is per-project** (godot_guard.ps1):
    provably-foreign instances don't block; same-PROJECT instances
    (the designer's game window) genuinely do — wait for them (clock
    honestly stopped), never kill their window. Running the gate
    steps individually (same commands, exit codes) is the recorded
    fallback. Batteries CAN run beside their play window in practice
    — but goldens-verify and the export step are the flake-prone
    ones; defer those to exclusive seams.
20. **Release-transport intakes (doc 18 §5)**: verify zipSha256 (=
    GitHub's computed asset digest) + manifest seal + per-file hashes
    + tag→sourceCommit — ALL LOCALLY, BEFORE the drop; re-hash after
    copy. Mismatch = incident + STOP. Where a manifest ships its own
    hashes, VERIFY them — the passport pins only what the manifest
    can't (itself).
21. **Fresh-clone byte-exactness**: `.gitattributes` pins the
    hash-gated trees (assets/audio/reports/replay fixtures +
    `tileforge_packages/`) `-text`. The repo-wide `* -text` flip is
    DELIBERATELY not done.
22. **`git add -f reports/` sweeps EVERYTHING untracked there** —
    stale repro_*.wsr from already-fixed failures ride in. Check
    `git diff --cached --name-status`, delete stale artifacts instead
    of committing them. RETIRED-PIN evidence gets `git rm`'d in the
    retiring commit. (Failed proof-iteration repros get swept BEFORE
    the gate — the wave-2 pattern.)
23. **TileForge packages are PER-PIN**: every world pack pins the
    exact package build it was resolved against;
    `world_builder.TILEFORGE_PACKAGES` is the registry. NEVER swap
    `res://tileforge/` in place. Import new builds BESIDE it.
24. **The fit rule's terrain has TWO truths (sl-0078)**: player +
    projectiles walk `walk_grid` + prop discs (art-true); enemies,
    floods, spawn checks, porosity, and every POSITIONING heuristic
    in the bot stay on the conservative `bitgrid`. Prop thickets are
    walkable-but-shot-exposed. Any new bot heuristic picks its grid
    deliberately. Kinematics with an empty discs dict is
    byte-identical legacy behavior.
25. **Planning sync-log appends race the live planning session**:
    verify the next free sl-#### id AT WRITE TIME (raced AGAIN this
    batch — a prepared sl-0182 entry found the id taken by the live
    seat's naming ruling; the write-time tail guard is what caught
    it), splice with the FILE'S OWN EOL convention (mixed — splice
    textually, never re-dump the whole json: a re-dump normalized
    5.8k lines once; content survived, the diff noise is the
    lesson), re-parse + verify after every append, commit promptly,
    NAME THE REAL ID in the commit message.
26. **CI lint is a second gate nobody watches live** — the pretester
    does NOT run gdformat; an intake that adds a generated .gd tree
    must extend ci.yml's format-exemption filter. Never hand-format
    a consumed package tree. AMENDED sl-0201: watching ONLY lint hid
    a 6h pixel-match hang for three days — the pipeline is green
    whole (~50 s) now; after any push `gh run list` and read the RUN
    conclusion. The hang class (gotcha 47's CI sibling: import-cache
    load() null → abort → idle) is capped by job timeout-minutes and
    the CI --import pass; any future wedge reads as a fast red.
27. **Headless gates cannot see windowed-only teardown** — the 4.6.2
    cursor API leaks 2 Texture RIDs per final applied cursor at exit;
    main releases the cursor at NOTIFICATION_EXIT_TREE — keep that
    handler. Method for any shutdown ERROR/RID-leak: sweep the gate
    commands solo with full stderr, characterize in a minimal
    project BEFORE touching code, fix lifecycle — never filter
    stderr.
28. **The activation leash EXISTS since S0 seam 2** (site_step.gd:
    wake 22 / sleep 30 / tether 12, away-only respawn). Two riders
    STILL standing: pairing viability is TERRAIN-CLASS-dependent,
    and point-openness is NOT orbit-openness — site suitability for
    orbit-class fights still needs a real clearance model (upstream
    wf conversation material).
29. **Gate scripts: the EXIT CODE must cover EVERY verdict.**
    Batteries print per-row; scripts COMPARE per-row and fail loudly
    on any mismatch.
30. **Never spawn a scenario player ON or NEAR a site cell** — the
    leash wakes the site and the wake ring materializes the pack on
    their head. Probe candidate spawns against site positions.
    Related: a passive bot outside the TETHER pins melee packs at
    the line (vacuous near −1 "pass") — proofs must fight INSIDE
    the envelope; players cannot exploit this (tether 12 > max
    weapon reach ~9.4).
31. **The full-speed lattice class is real and speed-specific**: a
    bot committed to constant full speed loses to (a) razor
    radial-gap threading and (b) INTERCEPT prediction (the live
    4.14 meet_leadshot pin). Humans tap-modulate out of both. Every
    new anchor re-rolls which rows it bites — that's WHY both lanes
    re-run on any speed change, and why pins are per-anchor.
32. **A RE-BASELINE IS NOT DONE UNTIL THE FULL GATE RUNS ON IT.**
    (The sl-0102 lesson — the parallel battery's first full run
    caught a committed red row.) The fast gate makes the rule cheap:
    regenerate → full gate → commit, always in that order.
33. **Pool lanes race on shared repro filenames.** Floor and cap
    lanes both write `repro_<scenario>_s<seed>.wsr` — whichever
    finishes last wins the file, so a committed repro's SIZE can
    change without any sim change. Repros are diagnostic-only; the
    arbiter for "did the sim move" is a fresh serial re-run.
    Lane-suffixed names stay the recorded tooling candidate.
34. **PowerShell kill filters can match YOUR OWN runs.** Name kill
    filters tightly (`--script <exact path>` + not-my-PID), and
    after ANY kill, verify your just-made edits actually landed.
35. **`$LASTEXITCODE` LIES in ad-hoc PowerShell gate loops** — never
    trust an improvised ps1 loop's exit codes: use Git Bash for
    quick gate sweeps or the pretester itself. Diagnose a surprising
    all-red by re-running ONE test with output visible.
36. **Desktop-capture probes: the content letterboxes inside the
    client area** — map base pixels through the integer scale PLUS
    the centering offset, and put signature points on STATIC pixels;
    every probe carries the letterbox-aware two-point pattern.
37. **SceneTree-script probes defer _ready to the first frame** — a
    property fed right after add_child gets overwritten by _ready's
    defaults. Feed AFTER the first `await process_frame`.
38. **THE BAG ERA IS THE CLASS LANE'S** (sl-0116/0129 doctrine): the
    legacy lane (class_id < 0) keeps pre-bag behavior VERBATIM —
    press-equip, per-item ground drops on kills, no
    bag/bank/vendor/tackle ops (bag_step's lane guard). That is what
    keeps the whole proof battery byte-identical; a test premise
    that assumes kills drop loose items must ask WHICH LANE first.
    (The rift branch adds its own gate: only PHASED defs land
    catches — phaseless rift mobs bank gold and stop.)
39. **A MarginContainer force-layouts EVERY child** — layout-free
    chrome needs an OUTER plain Control with an inner content
    MarginContainer (the ui/panel2.gd shape).
40. **add_theme_*_override fires THEME_CHANGED synchronously** — a
    _notification(THEME_CHANGED) handler that re-applies overrides
    recurses to stack overflow. Reentry-guard it.
41. **The Config autoload NODE exists under --script runs even
    though the global NAME never compiles there** — UI that probes
    must exercise reaches Config via get_node_or_null("/root/Config")
    AND probes NULL the _cfg field before feeding state (re-earned
    at the boss batch: the ui_family probe had been reading the
    DESIGNER'S real last-tab setting into committed evidence).
42. **Desktop-capture probes vs the OS: Windows notification banners
    render ABOVE even ALWAYS_ON_TOP windows** — a persistent toast
    rode into committed screen crops twice. AND `window_set_size` is
    silently IGNORED while the window is effectively maximized —
    force `window_set_mode(WINDOW_MODE_WINDOWED)` first. The
    recorded shape: WINDOWED 1440x1080 at (0,0); read every capture
    by eyes before committing regardless.
43. **Deliberate evidence re-records COMMIT WITH THE SEAM, then the
    gate SEALS on the committed tree.** The reports/-clean check
    reads tracked-modified evidence PNGs as dirty — a pre-commit
    full gate on a tree with re-captured evidence fails ONLY on
    that; the honest order is: functional tree final → gate
    (diagnostic) → commit everything including evidence → full gate
    again on the committed tree (the seal). Untracked new evidence
    is invisible to the check (reports/* is gitignored; tracked
    files ride `git add -f`).
44. **Proofs prove THE FIGHTS THE PLAYER GETS.** A proof composition
    denser than anything the content ships proves the wrong thing —
    the wave-2 corridor proof composed pair+lurker at once (no
    shipped fight zone does; spacing 20+ & tether-sequential,
    verified) and manufactured a wall-pin FAIL. Split proofs to the
    shipped fights; iterate the PROOF's spawn to real-but-fair
    (never-weaken binds the CONTENT, not the proof composition);
    and remember the sibling (sl-0186 RESOLVED into gotcha 45): sim
    proofs don't prove the designer's WALK.

45. **The walk check is a GATE STEP now (sl-0186's lesson
    mechanized).** dungeon_walk_test resolves EVERY arena-routed
    scenario's render (every wall cell carries wall art, every prop
    places, every SOLID cell covered — an invisible wall is a RED
    gate) and traverses the serpentine on real Kinematics. The
    original defect: the dungeon JSON spoke the WorldForge dialect
    ('species') where the arena schema reads 'name' — the resolver
    ABORT erased the whole placement set while solid_cells (flags
    only) kept collision real. arena_builder now NAMED-SKIPS
    malformed entries instead of aborting; new arena JSONs must
    speak the arena dialect.

46. **The frozen-entry-beat firing position (kit-authoring class).**
    A phase's FIRST volley fires from where the boss froze at the
    entry beat — cadence and phase-speed changes CANNOT move it (the
    sine_shoal cap graze reproduced byte-identically through two P2
    param edits). The lawful lever is the entry beat itself (longer
    = MORE telegraph across the flip, never less; 30→40 dissolved
    it). Check this class FIRST when a kit proof fails
    seed-invariantly right after a phase flip. AMENDED sl-0200: for
    a PURSUING kit the entry-beat lever only SLIDES the hit (+12t
    for +12 entry, byte-tracked) — a chaser's body keeps closing
    while the volley re-arms, so a braided double entry (two
    emitters) or a close-materializing fan stays razor at the floor
    no matter the beat. The pursuer-fair grammar proven by the
    shadow_hound failure + the tide_stalker pass: SINGLE-THREAT
    PHASES with long-lead volleys that exist at range.

47. **A RUNTIME abort in a --script test reads as a hang** (the
    hang-is-a-parse-error gotcha's sibling): an invalid index (etc.)
    aborts _init and the SceneTree never quits — same symptom, no
    parse error printed at launch. Run godot_console unpiped and
    look for 'SCRIPT ERROR' mid-run, not just at load. Related
    tooling trap: plain godot.exe is a GUI-SUBSYSTEM binary — in
    ForEach-Object -Parallel runspaces (no console) it DETACHES:
    zero output, zero exit code, orphaned engine processes. Scripted
    parallel runs use godot_console.exe, always (the battery runner
    was called with the wrong binary once; 18 detached processes).

48. **Pollers live where the guard lives (sl-0206).** `Input.is_action*`
    polling IGNORES GUI focus — a bare poll anywhere fires while the
    designer types in the console or comments box (the gif recorder
    carried one for weeks; T-in-console reset whole worlds because
    the `typing` predicate never included the console). ALL device
    polls sit in main.gd behind the swallow guard (`typing` =
    console-open OR box focus; `sampler.suppress` carries gameplay),
    plus human_sampler + the driver's single pause poll. The
    console_swallow fixed step REDs any poll outside those three
    files AND any unguarded poll line in main — route new keys
    through main, never poll from a view/driver. Sanctioned
    exceptions are deliberate: console_toggle stays live while open
    (the close key), Esc closes the console FIRST via esc_intercept.

49. **Bot-planning inputs re-roll EVERY deterministic dance
    (sl-0208).** The proofs are deterministic dances; ANY change to
    the policy's planning numbers (threat radii, pads, margins) —
    even a strictly-favorable one — re-rolls all of them, and a
    re-rolled dance can land in a fresh seed-invariant pocket (three
    radial/chase proofs regressed when the halved hurtbox planned
    tighter). The recorded answer: PLAN AT THE PROVEN ENVELOPE,
    REALIZE ON THE TRUE BODY (dodge_policy.PLAN_ENVELOPE — the
    sl-0078 conservative-positioning doctrine's ranged sibling). The
    survival predicate stays numerically the record's, dances
    reproduce, and true-body gains land as pure margin. A future
    hurtbox tune rides the envelope for free; genuinely retuning the
    PLANNER is its own deliberate re-baseline, never a side effect.

50. **Seconds derive from DT — the sim runs 60 tps (sl-0219a).** The
    sl-0115 merge converted 30→60 tps (sim_world DT = 1/60); tick
    counts are the truth in every probe and report, and a seconds
    claim converted at the old rate ships silently wrong (the
    chase-leash diagnosis said "95 s" for 2855 ticks for an hour —
    corrected to 48 s). Convert through DT, never from memory.
    Sibling trap re-earned the same hour: `var x := <duck-typed
    expr>` is a PARSE error ("cannot infer") that kills every
    DEPENDENT script — the failing checks then scatter across
    UNRELATED test sections and read as logic bugs (the gotcha-1/45
    class); run the test unpiped and grep SCRIPT ERROR before
    believing any partial-fail set.

## Ledger + scope

Ledger (`notes/TECH_DEBT_LEDGER.md`): OPEN = #16 (replay character
block — grown through SERIAL 26's gear fields; the boss batch grew
it ZERO; profile replays refuse verification honestly) and #17
(fit-rule round-1 scope: arena-def props still full-cell); #7
amended (async readback stays the improvement path); #1–#15 closed
or deferred with recorded exits. The scope tripwire is **SLICE
V0.1** (sl-0098 — the world is the test): slice work flows from
designer direction under talk-before-build via planning docs/23;
anything outside the slice bill's needs is refused and ledgered or
flagged to planning. S1 + the menu pass + the gear seam + the
starhook boss batch are COMPLETE; **REFINEMENT ROUND 1 (sl-0186..
0189) is the routed next and the dungeon diagnosis leads it**; the
foraging seam builds behind it at the next free SERIAL; S2 waits on
its own word; water fishing stays PARKED. The tester-build export
pipeline + lockdown stay a STANDING GATE (green at every full gate
of the batch; no standing debt).
