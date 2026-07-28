extends Resource
## A placed ground hazard an EmitterSlot casts (M6 Blightcaster, docs/12
## §3.4): the zone appears at the target's position, arms over arm_ticks
## — the arming zone IS the §3.4 telegraph ("45 ticks = full arm time")
## — then pulses damage every hit_interval_ticks from the arm tick until
## linger_ticks after arming. Multi-hit pressure with zero dice
## (CORE-40): leave the circle or burn. Escape math at lowest speed:
## center to edge = radius + player radius ≈ 1.63 tiles; 45 ticks at
## 3.0 t/s = 2.25 tiles — honestly dodgeable with margin (CORE-33).

@export var pattern_id: int = 15
@export var radius: float = 1.5
@export var damage: int = 12
@export var arm_ticks: int = 45
## Zone lifetime AFTER arming; 0 = one-shot (pulse once at arm, gone).
@export var linger_ticks: int = 120
## Pulse period while lingering. Authored, [T].
@export var hit_interval_ticks: int = 30
