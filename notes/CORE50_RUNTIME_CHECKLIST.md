# CORE-50 option runtime-verification (M8 accept line)

> M8 accept: "Every CORE-50 baseline option demonstrably changes runtime
> behavior in the tester build." Two halves: the WIRING half is
> mechanized (`--verify=core50-low` / `core50-high`, both pretester
> steps — each option's injected value must land in the runtime object
> it drives, and the two profiles differ on every asserted value, so the
> pair proves options CHANGE behavior). The RENDER half — what it looks
> like on screen — is designer eyes, one pass in the TESTER build,
> checkboxes below. Date + build id the pass when done.
>
> **ERA NOTE (2026-08-02, post-S1 interact/UI seams):** options open on
> **O OR Esc — one merged pause+options menu** (sl-0109); read "(O)"
> below as either key. New since this list was written: the "debug
> readout" options row (hides the bottom-left dev text line;
> settings-persisted, NOT part of the mechanized core50 pair — it is
> not a CORE-50 baseline option), and the remappable `interact` (F) +
> `char_sheet` (C) actions ride the SAME persisted-remap machinery the
> remap row already asserts. The onboarding row's 3.0/4.0 speed wording
> is the LAB-preset era record — class speeds since sl-0100/0102 come
> from creation (3.60/3.78/3.96, cap 4.14); re-word at that row's own
> pass.

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
| Crosshair style + size (sl-0077) | main._crosshair_style/_crosshair_size applied state (+ tests/settings round-trip) |
| Remapping (persisted path -> live InputMap) | injected move_up=J is live (+ tests/settings round-trip) |
| Hold/toggle fire | sim-side autofire latch, smoke-mechanized since M3 (CORE-32 proofs) |
| Rift split ratio (sl-0125) | [ui] rift_split settings round-trip in the gate; NOT core50-verified (deliberate: the row only applies inside rift scenarios, which core50's default-scenario boot never enters) — the render truth is the four-capture evidence + the designer-eyes row below |

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
- [ ] Rift split ratio (sl-0125): cast into any rift, flip "rift
      split" in options mid-dive — the panes and the galaxy camera
      re-fit live at both ratios; nothing hostile ever leaves the
      galaxy pane (Law 1 both ways).
- [ ] Crosshair styles (sl-0077): all four silhouettes readable on
      every floor; size steps visibly 9/11/13/15; "classic" at 11 is
      the exact ratified look (preview: reports/crosshair_styles_preview.png).
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
