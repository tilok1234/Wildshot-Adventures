extends Resource
## Loop v1 progression tables (docs/19 §3) — EVERY number here is [T]:
## the designer tunes in play. Sim math consuming these lives in
## sim/systems/progress.gd; the death gold cost is applied PROFILE-side
## between runs (game/drivers/character_profile.gd), never by the sim.
## Identity defaults: tier 1 = ×1.0, level 1 = no bonus — pre-loop
## behavior is reproduced exactly by a fresh character.

## XP to go from level n to n+1 = xp_base + xp_step * (n - 1).
@export var xp_base: int = 50
@export var xp_step: int = 75
@export var max_hp_per_level: int = 8
@export var mana_per_level: int = 2
## Percent damage per level above 1 (multiplies with the tier factor).
@export var damage_pct_per_level: float = 2.0
## Damage multiplier by weapon tier 1–6 (6 = unique-boosted).
@export var tier_damage_mult: Array[float] = [1.0, 1.25, 1.55, 1.9, 2.3, 3.0]
## Flat damage reduction by armor tier 0–5 (floor 1 damage per hit).
@export var armor_flat_per_tier: Array[int] = [0, 1, 2, 4, 6, 9]
## Normal-mode death: percent of CARRIED gold lost on respawn.
@export var death_gold_pct: int = 25
## Walk-over pickup radius, tiles.
@export var pickup_radius: float = 0.5
## Ground drops expire after this many ticks (60 s).
@export var drop_ttl_ticks: int = 3600
