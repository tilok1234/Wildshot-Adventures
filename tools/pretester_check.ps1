# Pre-tester-build checklist (docs/12 M7): every gate, one command.
# Runs the full verification stack and compares the canonical proof
# battery against the EXPECTED table below. Exit 0 = ship-ready per
# the current record. POLICY OF RECORD: REACTIVE (designer ruling
# 2026-07-29, Decision Deck register; ledger #11 closed). Canonical
# unsuffixed rows run reactive by default; the wolf-pair primary
# baseline rows stay watched — if a primary row's verdict MOVES, the
# sim changed under us. RE-PINNED 2026-08-01 (sl-0078 fit-rule
# collision, the deliberate sim change): forest_walk [primary]
# flipped FAIL->PASS (slimmer body + prop discs freed the primary
# model's forest pockets); rusher + first_contact [primary] stay
# FAIL. loop_ring2 layout iterated once under never-weaken (ringer
# off the thicket lip it predated).
#
# Usage: pwsh tools/pretester_check.ps1 [-SkipBattery] [-Workers N]
#
# BATTERY PARALLELIZATION (S1 tooling ask, designer-approved; docs/23
# tooling lane): the battery rows run in a worker pool
# (tools/battery_runner.ps1) — default workers = physical core count,
# HARD CAP 10 (the designer's ceiling), longest rows first from the
# machine-local timing table. -Workers 1 = the serial path. Adoption
# proof 2026-08-02: the parallel pass reproduced the serial record
# BYTE-IDENTICAL across all 69 runs (reports/ git-clean) with every
# verdict marker+exit-code gated. Coverage is LAW: the table below
# stays authoritative, no row is ever trimmed by the pool.

param([switch]$SkipBattery, [int]$Workers = 0)

$ErrorActionPreference = "Continue"
$godot = "$env:USERPROFILE\bin\godot_console.exe"
$fails = @()
$t0 = Get-Date

# PRECONDITION: exclusive PROJECT access. Concurrent Godot instances
# race the shared .godot/ cache and can flake determinism-critical
# steps (observed 2026-07-28: goldens verify failed beside a running
# soak, passed clean solo). Refuse to run rather than flake. The race
# is per-project: provably-foreign instances (absolute --path to
# another project) do not block — tools/godot_guard.ps1 (2026-07-30).
. "$PSScriptRoot\godot_guard.ps1"
$others = Get-BlockingGodot (Split-Path -Parent $PSScriptRoot)
if ($others) {
    Write-Host "PRE-TESTER CHECK: refusing to run - Godot instance(s) that can race this project:"
    $others | ForEach-Object { Write-Host ("  pid {0}  {1}" -f $_.ProcessId, $_.CommandLine) }
    Write-Host "Close them (game window, soak, batteries) and re-run."
    exit 2
}

function Step($name, $script) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $ok = & $script
    $sw.Stop()
    $mark = if ($ok) { "PASS" } else { "FAIL" }
    Write-Host ("{0,-42} {1}  ({2:n1}s)" -f $name, $mark, $sw.Elapsed.TotalSeconds)
    if (-not $ok) { $script:fails += $name }
}

Step "RNG lint (sim/ clean)" {
    $hits = Get-ChildItem sim -Recurse -Filter *.gd | Select-String -Pattern "randi\(|randf\(|randomize\(|RandomNumberGenerator"
    if ($hits) { $hits | ForEach-Object { Write-Host "  RNG: $_" }; return $false }
    return $true
}

Step "walkability diag (per-drop pin)" {
    python tools/diag_walkability_grid.py *> $null
    return $LASTEXITCODE -eq 0
}

Step "evidence report selftest" {
    python tools/evidence_report.py --selftest *> $null
    return $LASTEXITCODE -eq 0
}

Step "lockdown lint (one-flag gate)" {
    $lout = python tools/lockdown_lint.py 2>&1
    if ($LASTEXITCODE -ne 0) {
        $lout | Select-Object -Last 8 | ForEach-Object { Write-Host "  $_" }
        return $false
    }
    return $true
}

# sl-0083 icon-pack raw drop (unwired by ruling): manifest contract +
# per-file sha256s vs the intake passport — refuses byte drift.
Step "icon pack validate (manifest+passport)" {
    $iout = python tools/validate_icon_pack.py 2>&1
    if ($LASTEXITCODE -ne 0) {
        $iout | Select-Object -Last 8 | ForEach-Object { Write-Host "  $_" }
        return $false
    }
    return $true
}

# sl-0089 NPC slice roster raw drop (unwired by ruling): the manifest
# ships its own per-file sha256s — verified, plus the passport's
# manifest pin and the 480x96 / 20x4 / 24px sheet contract.
Step "npc pack validate (manifest+passport)" {
    $nout = python tools/validate_npc_pack.py 2>&1
    if ($LASTEXITCODE -ne 0) {
        $nout | Select-Object -Last 8 | ForEach-Object { Write-Host "  $_" }
        return $false
    }
    return $true
}

# sl-0093 dusk content pack (REFERENCE ONLY, docs/20 step 1): files-table
# + passport pins, designer locks at exact cells, and the b77 base
# pairing — refuses loudly if either side drifts.
Step "content pack validate (pairing+locks)" {
    $cout = python tools/validate_content_pack.py 2>&1
    if ($LASTEXITCODE -ne 0) {
        $cout | Select-Object -Last 8 | ForEach-Object { Write-Host "  $_" }
        return $false
    }
    return $true
}

# sl-0095 balance calculator (docs/22 block 9, paper-first): the five
# ruled gates over data/balance_frame.json — TTK/TTD bands, armor
# plateau, pattern fairness, chunky hits, the item validator.
Step "balance calculator (docs/22 gates)" {
    $bout = python tools/balance_calc.py 2>&1
    if ($LASTEXITCODE -ne 0) {
        $bout | Select-Object -Last 8 | ForEach-Object { Write-Host "  $_" }
        return $false
    }
    return $true
}

$tests = @(
    @("pixel-match", "tests/pixel_match/pixel_match.gd"),
    @("assembler pack + slice", "tests/assembler_pack/assembler_pack_test.gd"),
    @("projectile pack + map", "tests/projectile_pack/projectile_pack_test.gd"),
    @("worldforge pack validator", "tests/worldforge_pack/worldforge_pack_test.gd"),
    @("dev map minimap consumer", "tests/dev_map/dev_map_test.gd"),
    @("uikit validate", "tests/uikit/uikit_validate.gd"),
    @("crosshair styles + preview", "tests/crosshair/crosshair_styles_test.gd"),
    @("settings persistence", "tests/settings/settings_persist.gd"),
    @("feedback bundle + summary code", "tests/feedback/feedback_bundle_test.gd"),
    @("loop contracts (drops/curve/pickup)", "tests/loop/loop_test.gd"),
    @("stat frame (docs/22 in the sim)", "tests/stat_frame/stat_frame_test.gd"),
    @("living world (leash/respawn/importer)", "tests/living_world/living_world_test.gd"),
    @("green roster (S1 re-table/variants)", "tests/green_roster/green_roster_test.gd"),
    @("quests v1 (S1 accept/progress/turn-in)", "tests/quests/quest_test.gd"),
    @("npc + icon wiring (seam 4)", "tests/wiring/npc_icon_wiring_test.gd"),
    @("determinism smoke (all contracts)", "tests/determinism/determinism_smoke.gd"),
    @("golden replays x10", "tests/replay_fixtures/verify_replays.gd")
)
# Inline loop — NO closures: $LASTEXITCODE inside GetNewClosure
# scriptblocks resolves unreliably in pwsh (observed: goldens step
# flaked FAIL in-loop while the identical explicit step passed).
foreach ($t in $tests) {
    $tname = $t[0]
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $tout = & $godot --headless --path . --script $t[1] 2>&1
    $ok = ($LASTEXITCODE -eq 0)
    $sw.Stop()
    Write-Host ("{0,-42} {1}  ({2:n1}s)" -f $tname, $(if ($ok) { "PASS" } else { "FAIL" }), $sw.Elapsed.TotalSeconds)
    if (-not $ok) {
        $fails += $tname
        $tout | Select-Object -Last 12 | ForEach-Object { Write-Host "    | $_" }
    }
}

Step "boot clean (no ERROR)" {
    $out = & $godot --headless --path . --quit-after 90 2>&1
    $errs = $out | Select-String -Pattern "ERROR"
    $ready = $out | Select-String -Pattern "arena ready"
    if ($errs) { $errs | Select-Object -First 3 | ForEach-Object { Write-Host "  $_" } }
    return ($ready -and -not $errs)
}

# CORE-50 runtime verification (M8): both profiles must PASS by marker
# AND exit code — together they prove every mechanized option CHANGES
# wired behavior, not just holds a value.
foreach ($vp in @("core50-low", "core50-high")) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $vout = & $godot --headless --path . -- --verify=$vp 2>&1
    $vok = ($LASTEXITCODE -eq 0) -and ($vout | Select-String -Pattern "core50 verify \($vp\): PASS")
    $sw.Stop()
    Write-Host ("{0,-42} {1}  ({2:n1}s)" -f "core50 wiring ($vp)", $(if ($vok) { "PASS" } else { "FAIL" }), $sw.Elapsed.TotalSeconds)
    if (-not $vok) { $fails += "core50 wiring ($vp)" }
}

if (-not $SkipBattery) {
    # scenario, seeds, ticks, out (or ""), policy (or ""), expected at
    # the floor, expected at the 115 cap ("" = floor-only row).
    # SPEEDS (sl-0102 re-anchor [T]: stat 100 == 3.6 t/s): floor lane
    # --speed=3.6 (the CORE-53 floor = the slowest class base), cap
    # lane --speed=4.14 (the 115 hard cap). Report names keep the
    # dodge_*_cap115 suffix — 115 is the STAT, unchanged by ruling.
    # CAP LANE (docs/22 block 6, slice S0 seam 1): DodgeBot proofs run
    # at BOTH the CORE-53 floor and the ruled +15% hard cap FOREVER.
    # Primary rows stay floor-only (watch-baselines of the alternative
    # model, not proofs of record). The MUST-FAIL canary fails at BOTH
    # speeds (geometric box; re-verified at the sl-0102 re-baseline).
    # sl-0102 RE-PINS (deliberate, speed-moved-by-ruling): proof_ringer
    # cap = PASS at 4.14 (the old 3.45 pin was a lattice-specific graze
    # @t2033 — retired WITH the anchor; the half-duty fix-and-revert
    # story lives in the S0 session file); proof_rusher [primary] =
    # PASS at the 3.6 floor (the conservative model gains the margin
    # it lacked at 3.0). first_contact [primary] stays FAIL.
    # NEW PIN — meet_leadshot cap FAIL at 4.14 (seed-invariant 1-hit
    # graze @t647, near 0.013; repros committed): the INTERCEPT dart
    # aims where you are GOING — a bot at constant full commitment is
    # perfectly predictable, the purest form of the full-speed lattice
    # class (the retired ringer pin's sibling; humans tap-modulate out
    # of it, the 16-heading model cannot). The FLOOR row (the CORE-33
    # mandate) PASSES. All pins WATCHED: any verdict move off THIS
    # table = the sim (or policy) changed under us.
    $battery = @(
        @("canary_trivial","1,2,3,4,5",3600,"","","PASS","PASS"),
        @("canary_undodgeable","1,2,3",1800,"","","FAIL","FAIL"),
        @("proof_rusher","1,2,3,4,5",3600,"","","PASS","PASS"),
        @("proof_husk_archer","1,2,3,4,5",3600,"","","PASS","PASS"),
        @("proof_fanmaw","203,204,205,206,207",3600,"","","PASS","PASS"),
        @("proof_fanmaw_inside","205,206,207,208,209",3600,"","","PASS","PASS"),
        @("proof_ringer","204,205,206,207,208",3600,"","","PASS","PASS"),
        @("proof_leadshot","206,207,208,209,210",3600,"","","PASS","PASS"),
        @("proof_blightcaster","207,208,209,210,211",3600,"","","PASS","PASS"),
        @("proof_yw_p1","208,209,210,211,212",3600,"","","PASS","PASS"),
        @("proof_yw_p2","209,210,211,212,213",3600,"","","PASS","PASS"),
        @("proof_yw_p3","210,211,212,213,214",3600,"","","PASS","PASS"),
        @("proof_yw_full","211,212,213,214,215",3600,"","","PASS","PASS"),
        @("forest_walk","1,2,3",3600,"res://reports/dodge_forest_walk_composition.json","","PASS","PASS"),
        @("world_walk","1,2,3",3600,"res://reports/dodge_world_walk_composition.json","","PASS","PASS"),
        @("first_contact","1,2,3",3600,"res://reports/dodge_first_contact_composition.json","","PASS","PASS"),
        @("second_contact","10,11,12,13,14",3600,"res://reports/dodge_second_contact_composition.json","","PASS","PASS"),
        @("proof_rusher","1,2,3,4,5",3600,"","primary","PASS",""),
        @("forest_walk","1,2,3",3600,"res://reports/dodge_forest_walk_composition_primary.json","primary","PASS",""),
        @("first_contact","1,2,3",3600,"res://reports/dodge_first_contact_composition_primary.json","primary","FAIL",""),
        @("lab_default","1,2,3",3600,"","","PASS","PASS"),
        @("meet_blightcaster","1,2,3",3600,"","","PASS","PASS"),
        @("meet_leadshot","1,2,3",3600,"","","PASS","FAIL"),
        @("meet_yard_warden","1,2,3",3600,"","","PASS","PASS"),
        @("loop_ring1","1,2,3",3600,"","","PASS","PASS"),
        @("loop_ring2","1,2,3",3600,"","","PASS","PASS"),
        @("loop_ring3","1,2,3",3600,"","","PASS","PASS"),
        @("proof_brk_site","1,2,3",3600,"","","PASS","PASS"),
        @("overworld_green","1,2,3",3600,"res://reports/dodge_overworld_green_composition.json","","PASS","PASS"),
        @("overworld_dry","1,2,3",3600,"res://reports/dodge_overworld_dry_composition.json","","PASS","PASS"),
        @("overworld_wet","1,2,3",3600,"res://reports/dodge_overworld_wet_composition.json","","PASS","PASS"),
        @("overworld_cold","1,2,3",3600,"res://reports/dodge_overworld_cold_composition.json","","PASS","PASS"),
        @("overworld_green_boss","1,2,3",3600,"res://reports/dodge_overworld_green_boss_composition.json","","PASS","PASS"),
        @("proof_slice_leash","1,2,3",3600,"","","PASS","PASS"),
        @("proof_green_camp","1,2,3",3600,"","","PASS","PASS"),
        @("proof_green_ranged","1,2,3",3600,"","","PASS","PASS"),
        @("proof_old_tusk","1,2,3",3600,"","","PASS","PASS"),
        @("proof_warren","1,2,3",3600,"","","PASS","PASS"),
        @("proof_king_grubb","1,2,3",3600,"","","PASS","PASS")
    )
    . "$PSScriptRoot\battery_runner.ps1"
    if ($Workers -le 0) { $Workers = Get-PhysicalCoreCount }
    $Workers = [Math]::Min($Workers, 10)
    $bsw = [System.Diagnostics.Stopwatch]::StartNew()
    $bres = Invoke-BatteryParallel -Battery $battery -Workers $Workers -Godot $godot `
        -TimingPath (Join-Path (Split-Path -Parent $PSScriptRoot) "reports/battery_timings.json")
    $bsw.Stop()
    foreach ($r in $bres) {
        Write-Host ("{0,-42} {1}  ({2:n1}s)" -f $r.Name, $(if ($r.Ok) { "PASS" } else { "FAIL" }), $r.Seconds)
        if (-not $r.Ok) { $fails += $r.Name }
    }
    Write-Host ("battery: {0} runs on {1} workers in {2:n1} min wall" -f @($bres).Count, $Workers, $bsw.Elapsed.TotalMinutes)
    Step "battery byte-identical (reports/ clean)" {
        $dirty = git status --porcelain reports/ | Where-Object { $_ -notmatch "repro_.*\.wsr" }
        if ($dirty) { $dirty | ForEach-Object { Write-Host "  dirty: $_" }; return $false }
        return $true
    }
}

Step "export + artifact boots (dev + tester)" {
    pwsh tools/export.ps1 -BuildProfile both -Quiet
    return $LASTEXITCODE -eq 0
}

# M8 lockdown sweep: probes the artifacts the export step just built —
# dev runs the bot (positive control), tester refuses bot/audit CLI,
# session evidence stays free of dev-tool markers.
Step "lockdown probe (tester artifact)" {
    $pout = pwsh tools/lockdown_probe.ps1 -Quiet 2>&1
    if ($LASTEXITCODE -ne 0) {
        $pout | Select-Object -Last 8 | ForEach-Object { Write-Host "  $_" }
        return $false
    }
    return $true
}

Write-Host ""
$dt = (Get-Date) - $t0
if ($fails.Count -eq 0) {
    Write-Host ("PRE-TESTER CHECK: ALL GREEN ({0:n1} min)" -f $dt.TotalMinutes)
    exit 0
} else {
    Write-Host ("PRE-TESTER CHECK: {0} FAILURE(S) ({1:n1} min):" -f $fails.Count, $dt.TotalMinutes)
    $fails | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
