extends Resource
## EnemyDef (docs/12 §2.7, §3.4): lean CORE-40 stats + a movement policy +
## emitter slots. Pure data — behavior is the sim's explicit 5-state
## machine (sim/systems/enemy_step.gd); no behavior trees. Health totals
## stay honest (CORE-36); no accuracy/evasion/crit fields exist or may be
## added (CORE-40).
##
## ORBIT and FLANKER are declared for the §2.7 policy grammar but land
## with their M6 roster rows (Leadshot flanker); until then they anchor.

enum MovementPolicy { CHASER, KEEP_RANGE, ORBIT, ANCHOR, FLANKER }

@export var id: StringName = &""
@export var display_name: String = ""
@export var hp: int = 20
@export var body_radius: float = 0.3
## Tiles/second (§3.4 column; kiteable at the 3.0 player floor by proof).
@export var move_speed: float = 2.0
## Body-touch damage; 0 = none. Applies on its own cooldown, any state.
@export var contact_damage: int = 0
## Ticks between contact applications. Authored, [T].
@export var contact_cooldown_ticks: int = 30
## Engage when the nearest player is within this many tiles.
@export var aggro_range: float = 12.0
@export var movement_policy: MovementPolicy = MovementPolicy.CHASER
## KEEP_RANGE band (tiles): retreat inside range_min, approach outside
## range_max, hold between.
@export var range_min: float = 0.0
@export var range_max: float = 0.0
## EmitterSlot resources; empty = melee-only.
@export var emitters: Array[Resource] = []
