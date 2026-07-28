extends Resource
## One phase of a PhaseList elite (docs/12 §3.5): the policy + emitter
## set active while the elite's HP sits in this phase's band. A phase is
## active while hp > hp_floor_pct% of the def's max HP (the last phase
## floors at 0). Transitions ride HP% only — HP never regenerates, so
## phase progression is monotone by construction (CORE-36 honest health).

@export var id: StringName = &""
## Phase active while hp > this percent of max HP. Ordered descending
## across the PhaseList; the final entry is 0.0.
@export var hp_floor_pct: float = 0.0
@export var movement_policy: int = 0  # EnemyDef.MovementPolicy
## Tiles/second while this phase is active; -1 inherits the def's.
@export var move_speed: float = -1.0
## KEEP_RANGE band for this phase (unused by other policies).
@export var range_min: float = 0.0
@export var range_max: float = 0.0
## Ticks after phase entry before any slot may BEGIN its windup — the
## transition breathing beat. Telegraphs are always fully honored across
## transitions: first fire >= entry + this + the slot's telegraph.
@export var entry_cooldown_ticks: int = 0
## EmitterSlot resources active during this phase.
@export var emitters: Array[Resource] = []
