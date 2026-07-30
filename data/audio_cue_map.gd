extends Resource
## Law-7 audio cue map (docs/12 M6, CORE-50): key threat class →
## {wav: String | wavs: Array, bus: String, volume_db?: float,
## gap_ticks?: int}. `wavs` rotates variations round-robin (no RNG);
## volume_db defaults 0; gap_ticks overrides the per-class retrigger
## gate. The KeyThreats bus is the separate eyes-closed channel; Sfx
## carries self-feedback (fire classes live here — never on the threat
## channel, never ducking the music). Swapping cues = editing this
## file + dropping files, zero code (the flash_view/projectile_map
## pattern). The prose map + review record: notes/AUDIO_CUE_MAP.md.

@export var cues: Dictionary = {}
## Telegraph pattern ids classed as MELEE windups (distinct cue — the
## close-range threat reads differently eyes-closed).
@export var melee_patterns: Array[int] = []
