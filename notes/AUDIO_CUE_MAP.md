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
Per-channel volumes (Master/Sfx/KeyThreats/Music/AttackSfx at
100/70/40/off) live in the options menu and persist under `[audio]`
(CORE-50 separate channels, key threats audible). AttackSfx
(designer-ruled 2026-07-30) carries fire feedback ONLY, so attack
noise turns off without losing hit/death feedback or threat cues.

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

**DEFERRED (designer call, 2026-07-29): audio judgment waits for the
Resonance Forge integration — the placeholder cues will not be
separately ratified; both the eyes-closed test and the in-play feel
verdict run against real audio at Forge intake.** Original protocol
(unchanged, runs then): play one mixed encounter
(second_contact or the Warden) eyes closed; confirm the seven classes
are tellable apart and that key threats read through a busy mix.
Record verdict + date here.

2026-07-30 (chat, Tier 1, marathon — provisional per two-tier):
first-mapping enemy-attack cue REJECTED + player-attack silence
REJECTED (both corrected same seam: charge windup + fire classes);
corrected build **"sounds great"**; music queue + duck **"sounds
good"**. Designer chose NATURAL TESTING during continued work — the
formal eyes-closed pass and the rested ratification stay open and
accumulate organically; do not nag.

## Music channel (M8, designer-ruled 2026-07-30, Tier 1)

Rulings: tracks play as a QUEUE in listed order, looping the whole
queue (per-area assignment stays a future data change on the same
machinery); music DUCKS under threat cues (−9 dB, fast attack / slow
release, ~0.35 s hold after the last cue) so the KeyThreats channel
sits on top of the mix by construction.

Machine half: `data/music_playlist.tres` (stream paths, filled at the
2026-07-30 intake below) → `game/views/music_view.gd` → **Music**
bus (fourth CORE-50 channel: own options row + `[audio] music`
persistence, core50-verify asserted). The duck rides the player's
volume_db, composing with — never fighting — the user's channel
volume.

## RESONANCE FORGE INTAKE (2026-07-30, release transport, doc 18 §5)

Artifact `resonance-forge-godot-audio-v1-23a6c659199b`
(tilok1234/music_soundeffects release; sourceCommit 23a6c659199b...;
zipSha256 F786126B9DD15159550783BABD4EE2E7DD2EADE80A9D9FB06B1759E1CBF8F8C1)
— verified locally at intake: zip hash vs notes + sidecar, then ALL
178 package_manifest files hash-true. The pack's addon/autoload
(`ResonanceAudio`) is deliberately NOT enabled — no middleware; the
game consumes FILES through its own cue map + music_view.

Cue mapping (agent-chosen from the pack's own `critical: true` threat
set; the designer's deferred eyes-closed + feel pass judges it — any
swap is a one-line .tres edit). Copied BYTE-IDENTICAL to
`audio/cues/` (placeholders retired from the map; `audio/placeholder/`
+ `tools/gen_cue_wavs.py` stay in-repo as the recorded fallback until
the ear pass accepts):

| Class | RF file | Why |
|---|---|---|
| telegraph_ranged | enemy_laser_charge.wav | the windup charge (CORRECTED 2026-07-30 from _warning — designer ear) |
| telegraph_melee | boss_telegraphs_attack.wav | sharp "attack now" contour |
| hazard_cast | plasma_rifle_warning.wav | third distinct warning contour |
| hazard_armed | plasma_rifle_explosion.wav | detonation thump, zone-live |
| phase_change | boss_telegraphs_phase_change.wav | exact intent match |
| player_hit | shield_break_hit.wav | player-side impact family |
| player_death | shield_break_break.wav | the break |
| player_fire | plasma_rifle_fire + v01–v12 | attack release (designer-ruled audible 2026-07-30) |
| enemy_fire | enemy_laser_fire + v01–v12 | enemy volley release, same ruling |

Fire classes (ATTACK_STARTED hook — once per release, both factions
emit it): `wavs` arrays rotate round-robin (deterministic counter, no
RNG); volume_db −7 (RF's own mastered level); gap_ticks 4 (player —
under Longbolt's 6.5-tick cadence, still coalescing one volley to one
cue) / 6 (enemy). Both live on the **AttackSfx** bus — never
KeyThreats (no threat-channel spam, no music-duck spam), separable to
off on their own row.

Music: four approved seamless loops (na01 Embertrail 100 bpm G,
na02 Wayfarer's Glen 96 bpm D, na03 Mossbound Roads 92 bpm E mix,
na04 Rising Frontier 104 bpm A), queue order = na01→na04. Masters are
138–156 MB WAVs (48 kHz, ~8 min each, 581 MB total) and are NOT
committed — the immutable release is the archive; the repo carries
ffmpeg OGG Vorbis q6 conversions (~21.5 MB total) under
`audio/music/` (command: `ffmpeg -i <wav> -c:a libvorbis -q:a 6`;
ogg sha256s in the intake commit). Tracks import NON-looping so the
queue's `finished` advance works; the "seamless loop" property is
unused under the queue ruling.

Unused pack inventory (recorded, zero wired): enemy_laser
warning/impact/cooldown, plasma_rifle charge/impact/ui/cooldown,
shield_break hit variants v01–v12 + warning, boss_telegraphs
attention/enrage, pickups ×8 (written under the zero-reward law;
since Loop v1 (2026-07-30) walk-over loot pickups DO exist — wiring
pickup cues is a future designer taste call, zero wired today),
ui_feedback ×14 (menu sounds are a future taste call), the manifest's
music_states table (MENU/EXPLORE/COMBAT/... — superseded by the queue
ruling; revisit post-Gate-1 if ever), mix/crossfade defaults,
24-voice pool. The intake-day "player fire stays silent (Law 2)"
inference was OVERRULED by designer ruling 2026-07-30 — attacks are
audible; the Law-2 hierarchy holds through bus separation instead
(−7 dB defaults, AttackSfx row with off).
