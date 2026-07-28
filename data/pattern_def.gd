extends Resource
## A hostile fire pattern (docs/12 §2.7): a pattern id + a volley of
## ShotDefs — the same resource family the player's WeaponFrame uses
## (§2.6), so authored angle offsets, motion programs, and pierce rules
## are one vocabulary for both factions. The volley orients on the aim
## vector the firing enemy computes (M5: aimed at nearest player at the
## fire tick); fans and radials are authored angle offsets, never
## random (CORE-32 determinism applies to hostile fire too).
##
## Pattern-id namespace: 1..3 player weapons, 10+ enemy patterns,
## 100 debug emitter; -1 nova, -2 hazard, -3 contact.

## How the aim vector is computed at the fire tick (M6): CURRENT aims
## at the nearest player's position; INTERCEPT solves the closed-form
## lead against the target's serialized velocity using the FIRST shot's
## speed. Deterministic either way — the honest counter to INTERCEPT is
## changing direction during the telegraph.
enum AimMode { CURRENT, INTERCEPT }

@export var id: StringName = &""
## Unique pattern id carried by every projectile this pattern spawns —
## events, death recap, and telemetry read it.
@export var pattern_id: int = 0
@export var aim_mode: AimMode = AimMode.CURRENT
## Array of ShotDef resources, fired together as one volley.
@export var shots: Array[Resource] = []
