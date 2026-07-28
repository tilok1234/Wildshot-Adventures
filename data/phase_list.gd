extends Resource
## Ordered phase set for an elite EnemyDef (docs/12 §3.5): each entry is
## a PhaseDef whose hp_floor_pct descends to 0. The sim resolves the
## active phase as a pure function of current HP (sim/systems/
## enemy_step.gd); this resource is definition data and never mutates.

@export var phases: Array[Resource] = []


func entry(index: int) -> Resource:
	return phases[clampi(index, 0, phases.size() - 1)]
