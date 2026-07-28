extends Resource
## One emitter slot on an EnemyDef: {PatternDef, trigger, telegraph}
## (docs/12 §2.7). The trigger is a range condition: the slot is ready
## when its cooldown gate is open AND the nearest player is within
## trigger_range. All timers in ticks. cooldown_ticks is the FIRE-to-FIRE
## period (§3.4 roster column); the telegraph runs inside it, so windup
## may begin telegraph_ticks before the gate reopens.

## PatternDef resource this slot fires.
@export var pattern: Resource = null
## HazardDef this slot casts INSTEAD of a volley (M6 Blightcaster):
## when set, `pattern` stays null and firing places the hazard at the
## nearest player's position (§3.4 delayed ground hazard).
@export var hazard: Resource = null
## Fire only when the nearest player is within this many tiles.
@export var trigger_range: float = 7.0
## TELEGRAPH_STARTED leads the volley by exactly this many ticks
## (prominence scales with danger — CORE-51 Law 4).
@export var telegraph_ticks: int = 12
## Fire-to-fire period.
@export var cooldown_ticks: int = 90
## Post-fire stand-still before repositioning resumes. Authored, [T].
@export var recover_ticks: int = 20
