extends Resource
## Stress budgets (docs/12 §2.6, TECH-03 [P/T]) — enforced by the density
## meter, exercised by the M6 stress-density acceptance. Damage-number
## instances count against effects_max. The scenario-composition rule:
## worst-case sustained hostile projectiles (Σ volley × TTL / cooldown
## across a scenario's roster) must fit hostile_ordinary_max.

@export var hostile_ordinary_max: int = 150
@export var hostile_elite_max: int = 300
@export var combined_max: int = 600
@export var enemies_max: int = 24
@export var effects_max: int = 150
