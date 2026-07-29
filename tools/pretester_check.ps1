# Pre-tester-build checklist (docs/12 M7): every gate, one command.
# Runs the full verification stack and compares the canonical proof
# battery against the EXPECTED table below. Exit 0 = ship-ready per
# the current record. POLICY OF RECORD: REACTIVE (designer ruling
# 2026-07-29, Decision Deck register; ledger #11 closed). Canonical
# unsuffixed rows run reactive by default; the three wolf-pair
# primary FAILs stay watched as explicit [primary] baseline rows —
# if primary ever PASSES one, the sim changed under us.
#
# Usage: pwsh tools/pretester_check.ps1 [-SkipBattery]

param([switch]$SkipBattery)

$ErrorActionPreference = "Continue"
$godot = "$env:USERPROFILE\bin\godot_console.exe"
$fails = @()
$t0 = Get-Date

# PRECONDITION: exclusive project access. Concurrent Godot instances
# race the shared .godot/ cache and can flake determinism-critical
# steps (observed 2026-07-28: goldens verify failed beside a running
# soak, passed clean solo). Refuse to run rather than flake.
$others = Get-Process godot, godot_console -ErrorAction SilentlyContinue
if ($others) {
    Write-Host "PRE-TESTER CHECK: refusing to run - other Godot instance(s) on this machine:"
    $others | ForEach-Object { Write-Host ("  pid {0}  {1}" -f $_.Id, $_.ProcessName) }
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

Step "walkability diag (11 route cells)" {
    python tools/diag_walkability_grid.py *> $null
    return $LASTEXITCODE -eq 0
}

$tests = @(
    @("pixel-match", "tests/pixel_match/pixel_match.gd"),
    @("assembler pack + slice", "tests/assembler_pack/assembler_pack_test.gd"),
    @("projectile pack + map", "tests/projectile_pack/projectile_pack_test.gd"),
    @("worldforge pack validator", "tests/worldforge_pack/worldforge_pack_test.gd"),
    @("uikit validate", "tests/uikit/uikit_validate.gd"),
    @("settings persistence", "tests/settings/settings_persist.gd"),
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
        @("forest_walk","1,2,3",3600,"res://reports/dodge_forest_walk_composition_primary.json","primary","FAIL"),
        @("first_contact","1,2,3",3600,"res://reports/dodge_first_contact_composition_primary.json","primary","FAIL"),
        @("lab_default","1,2,3",3600,"","","PASS"),
        @("meet_blightcaster","1,2,3",3600,"","","PASS"),
        @("meet_leadshot","1,2,3",3600,"","","PASS"),
        @("meet_yard_warden","1,2,3",3600,"","","PASS")
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
