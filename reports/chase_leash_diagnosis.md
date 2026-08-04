# Chase-leash diagnosis (sl-0219a) — measured 2026-08-05

The designer's finding: *"i think we need to look at how long enemies
chases you and stuff like that, cause rn i feel like they start
cluttering up and ganging unreasonably up on you if you run around
the map not killing everything."*

Measured before touching anything. Instrument:
`tests/chase_leash/chase_leash_probe.gd` — a class-floor walker
(3.6 t/s, real Kinematics input frames, BFS-routed around terrain)
lapping a real five-site corridor on the b77 slice (sites
123/128/129/98/99, the x~62 chain, y 98.5–127.5; every site inside
every route point's 30-t sleep envelope, seed 100).

## The static truth (from source)

| mechanism | value | where |
|---|---|---|
| aggro trigger | **12.0 t uniform** on every ordinary def (bosses 14, rift mobs 8); Euclidean, walls do not block; checked **only in IDLE** | `EnemyDef.aggro_range`, `enemy_step.run` |
| chase give-up by player distance | **does not exist** | `enemy_step` REPOSITION has no distance check |
| chase give-up by timer | **does not exist** | no such state anywhere |
| territory tether | 12.0 t from the site cell — beyond it: forced IDLE + walk home | `SiteStep.TETHER_RADIUS` |
| return home | **stops the tick home_dist <= 12** — the mob parks at the RIM, never re-centers | the tether block guards on `home_dist > TETHER` only |
| re-centering | only via sleep-fold: every player > 30 t from the site cell | `SiteStep.SLEEP_RADIUS` |
| wake | any player <= 22 t of the site cell spawns the pack at rings 2.0–4.4 | `SiteStep.WAKE_RADIUS`, `SPAWN_RINGS` |
| speeds | greens 0.9–3.1 t/s, all under the 3.6 class floor | defs |
| non-site enemies (labs, Warren, rift dungeon, door spawns) | no tether, no give-up: **chase forever** by construction | `e.site_index < 0` skips the block |

## The measured truth (probe, seed 100)

**Phase 1 — three road laps (t 0–2855, ~48 s at 60 tps).** Engagement
saturates in 6 s and never decays: engaged 15 → 28 by t=360, then
**27–30 engaged steady across all three laps**. Live population along
the one corridor: 30–39. The near-8 gang re-forms on **every**
mid-road pass — peaks 24 / 24 / 24 on laps 1/2/3 (no habituation, no
decay: the corridor re-collects identically each lap because its
chasers parked at the road-facing rims).

**Phase 2 — stand mid-road 240 t (4 s).** The train catches and
holds: near-8 = 21 sustained. This is the designer's "ganging
unreasonably".

**Phase 3 — walk 20+ t off-road NE and hold 300 t (5 s).** near-8 falls
21 → 0 purely by the speed gap (outrunning, the only honest shed
today), and live falls 39 → 20 (sites > 30 t behind sleep-fold — the
only re-centering mechanism today). But **15 mobs remain engaged the
entire 300-t hold** at 20+ t from the player: chasers advancing
toward a player they can never reach, several terrain-wedged
mid-chase — with no give-up, a wedged chaser stays engaged forever
and re-presses the moment a route opens.

**Phase 4 — rim census (20 live site members).** 5 near home (<=6 t),
**15 displaced (>6 t), 10 rim-parked (>10 t), max home-distance
exactly 12.0 — the tether line.** The tether's stop-inside leaves
the population ratcheted to the player-facing rim: effectively the
whole camp has moved up to ~12 t toward the road and re-aggros
instantly on the next pass.

## The gang-train mechanism, named

1. Wake (<= 22) spawns every corridor site as you pass — one road =
   30–39 live bodies.
2. Aggro (12, IDLE-only) engages them; **nothing by player distance
   ever disengages them** — only the tether line or a 30-t
   sleep-fold.
3. All speeds sit under the class floor, so a moving player accretes
   a trailing train; every slow, turn, or fight lets it catch
   (near-8 = 21–24).
4. Give-up-at-the-rim parks each site's chasers at the road edge
   (census: max exactly 12.0). Next pass re-collects the full rim
   population instantly — laps 2 and 3 measure identical to lap 1.
5. Kiting inside a quest area keeps everything within 30 —
   nothing ever sleeps, nothing ever re-centers.

## Levers (sl-0219b builds behind [T]s)

- **A. GIVE-UP DISTANCE** — an engaged *site member* whose nearest
  living player exceeds GIVE_UP_RADIUS disengages. Fires from
  REPOSITION; a windup completes (an unkept telegraph cannot kill,
  Law 8). Hysteresis is structural: give-up > aggro.
- **B. FULL RETURN-HOME** — a disengaged site member beyond
  RETURN_RADIUS of its home walks all the way back (not just inside
  the rim). RETURN_RADIUS > max spawn ring 4.4 so fresh wakes never
  shuffle. Kills the rim ratchet AND releases terrain-wedged
  chasers.
- Scope: **site members only** — labs, the Warren, the rift dungeon
  and every authored proof keep chase-forever by construction
  (`site_index < 0`), so the non-slice battery is byte-identical by
  construction.
- Untouched: TETHER 12 (load-bearing: > every class weapon reach
  ~9.4 — no shoot-from-safety), WAKE/SLEEP 22/30, aggro 12, speeds.
  sl-0213 (close-fighter re-arm) stays separately queued.

Fairness frame satisfied by construction: a kiting player sheds
pursuers honestly (give-up + walk home), a standing player still gets
pressured (aggro/wake untouched), no permanent trains (the world
re-centers itself).

---

## AFTER (sl-0219b built: GIVE_UP_RADIUS 18 [T] + RETURN_RADIUS 5 [T])

Same probe, same seed, same route — the sim change is the only
variable:

| measure | before | after |
|---|---|---|
| engaged during active corridor laps | 27–30, zero decay | 22–27, decays at road ends |
| near-8 gang standing mid-road | 21 | 22 (**unchanged by design** — a standing player still gets pressured) |
| engaged after walking 20+ t off-road | **15, pinned forever** (terrain-wedged chasers included) | **4**, each explainable as live proximity to a territory disc |
| rim census: near home (<=6 t) | 5 / 20 | 12 / 23 |
| rim census: rim-parked (>10 t) | **10** | 3 |
| max home-distance | **exactly 12.0 (parked at the tether line)** | 10.2 (mid-walk, transient — the walk home completes) |

The corridor still presses while you are in it (wake/aggro/tether
untouched); leaving it now actually ends it. Both numbers [T] — the
designer's run around the map is the acceptance.
