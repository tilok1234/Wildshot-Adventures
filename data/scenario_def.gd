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
## When set, this scenario plays on a WorldForge game pack instead of an
## arena def (the generated-test-arena ruling): validated + rendered by
## game/arena/world_builder.gd; collision comes from walkability.json.
@export var worldforge_pack: String = ""
## When set, the world_filler content pack at this dir becomes the
## living-world spawn tables (docs/23 S0 (d): territories + placements
## via game/arena/content_importer.gd — leash-gated sites, no new
## authoring format). Empty = no sites (every pre-slice scenario).
@export var content_pack: String = ""
## Persistent-world scenario (sl-0098: NO run framing — the world
## persists and refills). With a NORMAL-mode character aboard, death
## becomes the CORE-43 overworld shape: in-sim gold cost + respawn at
## the settlement + the walk back; T never rebuilds the world's
## meaning (it still reseeds — a lab tool, not a run). Hardcore and
## profile-free (bot) play keep dead-in-place.
@export var persistent_world: bool = false
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
## Test damage schedule (§2.11 elite transition proofs; planning log
## 2026-07-28): {tick: int, amount: int} entries the sim applies to the
## scenario's elite at exact tick equality through the one damage path
## (source tag -4). Amounts are final HP deltas. TEST SCENARIOS ONLY
## (tests/bot_scenarios) — no tester-reachable scenario may declare one
## (M7 pre-tester-build checklist line).
@export var damage_schedule: Array[Dictionary] = []
@export var default_seed: int = 1
