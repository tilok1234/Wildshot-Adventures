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
## PLAYER pattern ids (sl-0115): the friendly namespace DECLARED —
## the old `pid < 10` range rule died when the player set outgrew it
## (rod patterns 9 + 29). Everything not listed here is HOSTILE and
## the Law-2/8 covers_hitbox guard binds it. The default is the
## historic range so an un-migrated map behaves identically.
@export var player_patterns: PackedInt32Array = PackedInt32Array([1, 2, 3, 4, 5, 6, 7, 8, 9])
@export var arm_strip: String = ""
## Nova cast-flash ring sprite (M6 EffectLibrary pass, ledger #9) —
## drawn expanding to the ability's radius on ABILITY_CAST; friendly
## cosmetic channel (density/opacity governed).
@export var nova_ring: String = ""
