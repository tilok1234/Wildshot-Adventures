# Audio Cue Map (Law 7 / CORE-50 — M6)

Written per docs/12 M6: each key threat class → distinct placeholder cue
→ bus. Machine version: `data/audio_cue_map.tres` (consumed by
`game/views/audio_cue_view.gd`); placeholder WAVs generated
deterministically by `tools/gen_cue_wavs.py` (mono 22050 Hz 16-bit,
conservative amplitude, fade envelopes) into `audio/placeholder/` —
NOT under `assets/` (that tree is .gdignore'd raw-drop territory).
Swapping designed cues in =
new WAVs + editing the .tres, zero code. Buses: **KeyThreats** is the
separate eyes-closed threat channel; **Sfx** carries self-feedback.
Per-channel volumes (Master/Sfx/KeyThreats at 100/70/40/off) live in
the options menu and persist under `[audio]` (CORE-50 separate
channels, key threats audible).

| Class | Trigger (event) | Cue contour | Bus |
|---|---|---|---|
| telegraph_ranged | hostile TELEGRAPH_STARTED, volley windup (any non-melee, non-zone pattern) | short rising two-step blip 600→900 Hz | KeyThreats |
| telegraph_melee | hostile TELEGRAPH_STARTED, melee windup (`melee_patterns` = [11] slash) | sharp high double tick 1250 Hz | KeyThreats |
| hazard_cast | hostile TELEGRAPH_STARTED whose pattern is a zone id (projectile_map.zones keys: 15 blight, 18 warden) | descending sweep 750→380 Hz ("thrown down") | KeyThreats |
| hazard_armed | hostile HAZARD_ARMED (zone goes live) | low noisy thump ~170 Hz | KeyThreats |
| phase_change | PHASE_CHANGED (elite phase flip) | three ascending notes 420/630/840 Hz | KeyThreats |
| player_hit | DAMAGE_APPLIED to a player | mid noisy thud 290→210 Hz | Sfx |
| player_death | ENTITY_KILLED (player) | long fall 520→140 Hz | Sfx |

Design notes:
- Classes are distinct by CONTOUR (direction + rhythm + register), not
  loudness — distinguishable eyes-closed and at reduced volume.
- Per-class retrigger gate: 8 ticks (~130 ms) so stress density cannot
  machine-gun one cue into noise (`CLASS_GAP_TICKS`).
- Friendly telegraphs (Blast Rune −2) are deliberately silent — the
  channel is for THREATS; the cast already has visual + resource
  feedback.
- Classification is data-driven: zone ids come from
  `projectile_map.zones`, melee ids from `audio_cue_map.melee_patterns`
  — new enemies land in the right class by data alone.

## Eyes-closed sanity review (pattern-review line, M6 acceptance)

**PENDING — designer, rested session:** play one mixed encounter
(second_contact or the Warden) eyes closed; confirm the seven classes
are tellable apart and that key threats read through a busy mix.
Record verdict + date here.
