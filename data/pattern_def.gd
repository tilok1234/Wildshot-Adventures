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

@export var id: StringName = &""
## Unique pattern id carried by every projectile this pattern spawns —
## events, death recap, and telemetry read it.
@export var pattern_id: int = 0
## Array of ShotDef resources, fired together as one volley.
@export var shots: Array[Resource] = []
