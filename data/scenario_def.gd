extends Resource
## Scenario definition (docs/12 §2.10 spawn/reset panel, TECH-10 lab
## subset): player spawn + inert stand-in layout + default seed on the
## one lab arena. EnemyDef spawn lists join at M5; full encounter
## authoring stays deferred (Stages 3–7).

@export var id: StringName = &""
@export var display_name: String = ""
@export var player_spawn: Vector2 = Vector2(24.0, 16.0)
@export var standin_positions: PackedVector2Array = PackedVector2Array()
@export var default_seed: int = 1
