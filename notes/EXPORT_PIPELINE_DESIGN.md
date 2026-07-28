# Export pipeline design (M7 last item; prereqs verified 2026-07-28)

Prereqs CONFIRMED: full 4.6.2 template set installed (incl.
windows_release_x86_64 + console wrapper). No export_presets.cfg yet.
This note is the one-shot plan for the next session.

## Two profiles (docs/12 §2.10)

- **dev**: everything as-is. Preset "windows-dev", debug export.
- **tester**: release export with custom feature tag `tester`. The
  §2.10 whitelist is enforced by GATING these behind
  `not OS.has_feature("tester")` in main.gd (one guard helper, not
  scattered ifs):
  - god/invulnerability console command (SET_GOD)
  - runtime stat editor (speed steps/presets beyond the tester-visible
    lowest-speed loadout — the PRESET stays, the free editor goes)
  - slow-mo divisor command
  - arbitrary spawn / scenario hot-edit paths (picker STAYS — it is
    tester-facing by design; verify nothing sim-mutating rides it)
  - F5 hot-reload (if wired)
  - damage-schedule scenarios: tests/bot_scenarios are not shipped
    (picker only lists data/scenarios — verify the export excludes
    tests/ via preset resource filters)
  - debug console: strip sim-mutating commands, keep verdict? NO —
    verdict is builder tooling; tester keeps: nothing of the console.
    Gate the whole console behind the tag.
- Defense in depth stays: Telemetry contamination flags (§2.10)
  regardless of gating.

## export_presets.cfg

Two presets, Windows Desktop, embed_pck. Resource filters: exclude
tests/*, reports/*, assets/* raw drops (projectiles/, assembler/,
audio/, worldforge packs under assets/ ARE shipped? world packs load
from assets/worldforge-packs at runtime — INCLUDE that path, exclude
the other raw drops: assets/projectile-pack, assets/
wildshot-projectiles-sphere-v0, assets/assembler-pack, assets/
tileforge — the imported copies (projectiles/, assembler/) ship
instead). Verify with a load-all boot on the exported build.

## tools/export.ps1

1. Version stamp: git describe --always → build id (HUD already
   shows it via ProjectSettings? verify how build id reaches HUD —
   §2.10 says stamped; if not yet wired, wire const from an
   auto-generated build_info.gd, deterministic).
2. godot --headless --export-release "windows-tester" out path (and
   --export-debug "windows-dev").
3. Zip: wildshot-<describe>-tester.zip.
4. Smoke the artifact: run the exported exe --quit-after 120 headed?
   (headless flag may not exist in release template — run windowed
   briefly + check exit/log).
5. Butler push: PREPARE the command, designer runs it (their itch
   credentials; PIPE-testers unlisted page).

## Acceptance (M7 line)

pretester_check.ps1 gains an "export + artifact boots" step (replace
the current TODO note); tester zip runs on a clean Windows machine
without dev setup; no sim-mutating tool reachable (manual sweep +
grep for the feature guard on every gated site).
