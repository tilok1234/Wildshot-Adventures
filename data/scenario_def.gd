extends Resource
## Scenario definition (docs/12 §2.10 spawn/reset panel, TECH-10 lab
## subset): player spawn + inert stand-in layout + enemy spawn lists +
## default seed on the one lab arena. Full encounter authoring stays
## deferred (Stages 3–7).

@export var id: StringName = &""
@export var display_name: String = ""
@export var player_spawn: Vector2 = Vector2(24.0, 16.0)
@export var standin_positions: PackedVector2Array = PackedVector2Array()
## EnemyDef id (String) -> PackedVector2Array of tile positions. Spawn
## ORDER is def-roster order then array order — never Dictionary key
## order (§2.4 stable iteration; scenario_loader owns the loop).
@export var enemy_spawns: Dictionary = {}
@export var default_seed: int = 1
