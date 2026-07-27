extends Resource
## Scenario definition (docs/12 §2.10 spawn/reset panel, TECH-10 lab
## subset): player spawn + inert stand-in layout + enemy spawn lists +
## default seed on the one lab arena. Full encounter authoring stays
## deferred (Stages 3–7).

@export var id: StringName = &""
@export var display_name: String = ""
## Arena definition this scenario plays on (visuals + collision derive
## from it together). Default: the lab arena.
@export var arena: String = "res://data/arena_lab.json"
@export var player_spawn: Vector2 = Vector2(24.0, 16.0)
@export var standin_positions: PackedVector2Array = PackedVector2Array()
## EnemyDef id (String) -> PackedVector2Array of tile positions. Spawn
## ORDER is def-roster order then array order — never Dictionary key
## order (§2.4 stable iteration; scenario_loader owns the loop).
@export var enemy_spawns: Dictionary = {}
## Extra EnemyDefs appended AFTER the standard roster (indexes stay
## stable). Exists for the §2.11 bot canaries — deliberately unfair
## defs that must never enter the shipped roster.
@export var extra_enemy_defs: Array[Resource] = []
@export var default_seed: int = 1
