extends Resource
## A hostile fire pattern (docs/12 §2.7): a pattern id + a volley of
## ShotDefs — the same resource family the player's WeaponFrame uses
## (§2.6), so authored angle offsets, motion programs, and pierce rules
## are one vocabulary for both factions. The volley orients on the aim
## vector the firing enemy computes (M5: aimed at nearest player at the
## fire tick); fans and radials are authored angle offsets, never
## random (CORE-32 determinism applies to hostile fire too).
##
## Pattern-id namespace: 1..6 player weapons (4..6 = the S0 class
## frames), 10..15 ordinary enemy patterns, 16..21 Yard Warden elite
## (§3.5), 22..24 Old Tusk (S1 seam 3), 100 debug emitter; -1 nova,
## -2 hazard, -3 contact, -4 test damage schedule (§2.11
## transition-proof hook — never a gameplay source).

## How the aim vector is computed at the fire tick (M6): CURRENT aims
## at the nearest player's position; INTERCEPT solves the closed-form
## lead against the target's serialized velocity using the FIRST shot's
## speed; ROTOR (§3.5 elite rotating radial) ignores the target and
## aims at a world-frame angle that advances with the tick —
## rotor_deg_per_tick x fire tick, a pure function of the tick with no
## state and no RNG. Deterministic all three ways — the honest counter
## to INTERCEPT is changing direction during the telegraph; to ROTOR,
## walking the gaps as they sweep.
enum AimMode { CURRENT, INTERCEPT, ROTOR }

@export var id: StringName = &""
## Unique pattern id carried by every projectile this pattern spawns —
## events, death recap, and telemetry read it.
@export var pattern_id: int = 0
@export var aim_mode: AimMode = AimMode.CURRENT
## ROTOR only: degrees the volley's base angle advances per tick.
@export var rotor_deg_per_tick: float = 0.0
## Array of ShotDef resources, fired together as one volley.
@export var shots: Array[Resource] = []
