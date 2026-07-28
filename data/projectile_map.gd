extends Resource
## Pattern id → projectile-pack sprite id (docs/12 M-FX curation; the
## pack's own suggested_pattern_ids seeded this). Sprite ids are
## style-qualified ("v0:hostile-orb") — restyling the game = remapping
## this file, never touching code. Unmapped patterns render as the
## honest sphere fallback. `alts` holds the second spin frame where the
## pack ships one (Wheelblade); `zones` skins hazard circles by pattern;
## `arm_strip` is the 8-step arm-progress ring (§2.5 band 8).

@export var shots: Dictionary = {}
@export var alts: Dictionary = {}
@export var zones: Dictionary = {}
@export var arm_strip: String = ""
## Nova cast-flash ring sprite (M6 EffectLibrary pass, ledger #9) —
## drawn expanding to the ability's radius on ABILITY_CAST; friendly
## cosmetic channel (density/opacity governed).
@export var nova_ring: String = ""
