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
# Usage: pwsh tools/pretester_check.ps1 [-SkipBattery]

param([switch]$SkipBattery)

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
    # scenario, seeds, ticks, out (or ""), policy (or ""), expected
    $battery = @(
        @("canary_trivial","1,2,3,4,5",3600,"","","PASS"),
        @("canary_undodgeable","1,2,3",1800,"","","FAIL"),
        @("proof_rusher","1,2,3,4,5",3600,"","","PASS"),
        @("proof_husk_archer","1,2,3,4,5",3600,"","","PASS"),
        @("proof_fanmaw","203,204,205,206,207",3600,"","","PASS"),
        @("proof_fanmaw_inside","205,206,207,208,209",3600,"","","PASS"),
        @("proof_ringer","204,205,206,207,208",3600,"","","PASS"),
        @("proof_leadshot","206,207,208,209,210",3600,"","","PASS"),
        @("proof_blightcaster","207,208,209,210,211",3600,"","","PASS"),
        @("proof_yw_p1","208,209,210,211,212",3600,"","","PASS"),
        @("proof_yw_p2","209,210,211,212,213",3600,"","","PASS"),
        @("proof_yw_p3","210,211,212,213,214",3600,"","","PASS"),
        @("proof_yw_full","211,212,213,214,215",3600,"","","PASS"),
        @("forest_walk","1,2,3",3600,"res://reports/dodge_forest_walk_composition.json","","PASS"),
        @("world_walk","1,2,3",3600,"res://reports/dodge_world_walk_composition.json","","PASS"),
        @("first_contact","1,2,3",3600,"res://reports/dodge_first_contact_composition.json","","PASS"),
        @("second_contact","10,11,12,13,14",3600,"res://reports/dodge_second_contact_composition.json","","PASS"),
        @("proof_rusher","1,2,3,4,5",3600,"","primary","FAIL"),
        @("forest_walk","1,2,3",3600,"res://reports/dodge_forest_walk_composition_primary.json","primary","PASS"),
        @("first_contact","1,2,3",3600,"res://reports/dodge_first_contact_composition_primary.json","primary","FAIL"),
        @("lab_default","1,2,3",3600,"","","PASS"),
        @("meet_blightcaster","1,2,3",3600,"","","PASS"),
        @("meet_leadshot","1,2,3",3600,"","","PASS"),
        @("meet_yard_warden","1,2,3",3600,"","","PASS"),
        @("loop_ring1","1,2,3",3600,"","","PASS"),
        @("loop_ring2","1,2,3",3600,"","","PASS"),
        @("loop_ring3","1,2,3",3600,"","","PASS"),
        @("proof_brk_site","1,2,3",3600,"","","PASS")
    )
    foreach ($b in $battery) {
        $scen = $b[0]; $seeds = $b[1]; $ticks = $b[2]; $out = $b[3]; $pol = $b[4]; $want = $b[5]
        $tag = if ($pol) { " [$pol]" } else { "" }
        $bname = "battery: $scen$tag (expect $want)"
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $ba = @("--headless","--path",".","--script","game/bots/bot_runner.gd","--","--scenario=$scen","--speed=3.0","--seeds=$seeds","--ticks=$ticks")
        if ($out) { $ba += "--out=$out" }
        if ($pol) { $ba += "--policy=$pol" }
        $res = & $godot @ba 2>&1 | Select-String -Pattern "\((PASS|FAIL)\)" | Select-Object -Last 1
        $got = $res -replace '.*\((PASS|FAIL)\).*','$1'
        $ok = ($got -eq $want)
        $sw.Stop()
        Write-Host ("{0,-42} {1}  ({2:n1}s)" -f $bname, $(if ($ok) { "PASS" } else { "FAIL" }), $sw.Elapsed.TotalSeconds)
        if (-not $ok) { $fails += $bname }
    }
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
