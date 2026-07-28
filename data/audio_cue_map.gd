extends Resource
## Law-7 audio cue map (docs/12 M6, CORE-50): key threat class →
## {wav: String, bus: String}. The KeyThreats bus is the separate
## eyes-closed channel; Sfx carries self-feedback. Swapping placeholder
## cues for designed ones = editing this file + dropping WAVs, zero
## code (the flash_view/projectile_map pattern). The prose map with the
## eyes-closed review record lives at notes/AUDIO_CUE_MAP.md.

@export var cues: Dictionary = {}
## Telegraph pattern ids classed as MELEE windups (distinct cue — the
## close-range threat reads differently eyes-closed).
@export var melee_patterns: Array[int] = []
