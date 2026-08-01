# CORE-50 option runtime-verification (M8 accept line)

> M8 accept: "Every CORE-50 baseline option demonstrably changes runtime
> behavior in the tester build." Two halves: the WIRING half is
> mechanized (`--verify=core50-low` / `core50-high`, both pretester
> steps — each option's injected value must land in the runtime object
> it drives, and the two profiles differ on every asserted value, so the
> pair proves options CHANGE behavior). The RENDER half — what it looks
> like on screen — is designer eyes, one pass in the TESTER build,
> checkboxes below. Date + build id the pass when done.

## Mechanized (green in pretester on every run — no eyes needed)

| Option | Wired object asserted |
|---|---|
| Effect density (100/66/33%) | EffectLibrary.density |
| Effect opacity (100/70/40%) | EffectLibrary.opacity |
| Flash reduction | EffectLibrary.flash_reduction |
| Damage numbers off/reduced/full | feedback_settings.damage_numbers |
| Impact / kill / blocked feedback toggles | feedback_settings.* |
| Audio Master / Sfx / KeyThreats (incl. off=mute) | AudioServer mute + dB per bus |
| Hitbox indicator | hitboxes.visible |
| UI/text scale x1/x2 | scaled theme base_scale + font_size on every HUD surface |
| Remapping (persisted path -> live InputMap) | injected move_up=J is live (+ tests/settings round-trip) |
| Hold/toggle fire | sim-side autofire latch, smoke-mechanized since M3 (CORE-32 proofs) |

## Designer eyes — one pass in the TESTER build (render gate)

Launch the tester exe, flip each in options (O), confirm the LOOK:

- [ ] Effect density/opacity at 33%/40%: player-side cosmetics visibly
      thin out; hostile fire NEVER dims (structural clamp — if any
      hostile shot dims, that is a Law-1 bug, stop and flag).
- [ ] Flash reduction: impact/kill pops stop flashing.
- [ ] Damage numbers: off shows none, reduced shows fewer/smaller,
      full shows all.
- [ ] Hitbox indicator: sim-true circles appear/disappear (H and the
      options row agree).
- [ ] UI scale x2: every HUD surface doubles (bars, meter, options,
      recap, hints) — nothing clips off-screen at 1280x720.
- [ ] Audio rows: each bus audibly steps 100/70/40/off independently
      (five buses since M8: Master/Sfx/KeyThreats/Music/AttackSfx);
      KeyThreats off silences telegraphs but Sfx stays. Real audio is
      LIVE since the Resonance Forge intake (2026-07-30); the
      eyes-closed/feel verdicts accumulate in natural-testing mode
      (notes/AUDIO_CUE_MAP.md) — this row is only "the knob works".
- [ ] Remap in tester build: rebind fire, confirm it takes + persists
      across relaunch.
- [ ] Onboarding screen: lowest-speed button actually starts at 3.0
      (speed readout bottom-left), standard at 4.0; screen never
      reappears after T reset; Esc does nothing while it is up.
- [ ] Feedback row: save bundle -> zip lands on Desktop, Explorer
      reveals it, toast shows the summary code.

Pass record: ____________________ (date, build id, PROVISIONAL if not
a rested day-start session — two-tier rule applies to any feel notes
taken alongside; the checkboxes themselves are mechanics, Tier 1.)
