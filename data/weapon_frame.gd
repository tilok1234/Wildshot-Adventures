extends Resource
## A weapon frame (docs/12 §2.6/§3.3): cadence + a volley of ShotDefs.
## The three Phase A frames are three data files, zero code — the
## gate-failure fallback path is .tres edits (REGISTER: frame roster).
## Ordinary primary attacks consume no resource of any kind (CORE-32).

@export var id: StringName = &""
@export var display_name: String = ""
## Unique pattern id carried by every projectile this frame spawns —
## events, death recap, and telemetry read it.
@export var pattern_id: int = 0
@export var cadence_ticks: int = 30
## Array of ShotDef resources, fired together as one volley.
@export var shots: Array[Resource] = []
## docs/22 block 3 frame archetype ("slow_heavy" / "fast_light" /
## "long_reach"): class-backed players draw per-shot damage from the
## balance_frame.json tier table for this archetype. Empty = a lab
## frame — the Loop v1 damage math applies unchanged.
@export var archetype: StringName = &""
