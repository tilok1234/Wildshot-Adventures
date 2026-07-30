# tools/export.ps1 — M7 export pipeline (docs/12 §2.10; design:
# notes/EXPORT_PIPELINE_DESIGN.md). Two profiles from export_presets.cfg:
#   dev    — debug export, everything as-is (tests/ included, console live)
#   tester — release export with custom feature tag "tester": main.gd's
#            dev_tools gate strips console/god/slow-mo/free-speed/bot+audit
#            CLI; preset filters exclude tests/ and every raw asset drop.
# WorldForge packs ship as LOOSE FILES beside the exe (assets/ is
# .gdignore'd so it can never enter the PCK; WorldforgePack.resolve_src
# falls back to <exe dir>/assets/... at runtime). A new pack drop can be
# swapped into an existing build without re-exporting.
#
# Usage: tools/export.ps1 [-BuildProfile dev|tester|both] [-SkipBootCheck] [-Quiet]

param(
    [ValidateSet("dev", "tester", "both")][string]$BuildProfile = "both",
    [switch]$SkipBootCheck,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo
$godot = "$env:USERPROFILE\bin\godot_console.exe"

# Exclusive access (same reasoning as pretester_check: concurrent Godot
# instances race .godot/ and can corrupt the import cache mid-export).
# Per-project doctrine via the shared guard (tools/godot_guard.ps1).
. "$PSScriptRoot\godot_guard.ps1"
$others = Get-BlockingGodot (Split-Path -Parent $PSScriptRoot)
if ($others) {
    Write-Host "export: refusing to run - Godot instance(s) that can race this project:"
    $others | ForEach-Object { Write-Host ("  pid {0}  {1}" -f $_.ProcessId, $_.CommandLine) }
    exit 2
}

# 1. Build-id stamp: rewrite build_info.gd for the export, restore after.
#    ([IO.File]::WriteAllText writes UTF-8 with NO BOM - Set-Content adds
#    a BOM and Godot silently rejects BOM'd scripts/resources.)
$buildId = (git describe --always --dirty).Trim()
$biPath = Join-Path $repo "build_info.gd"
$biDefault = [IO.File]::ReadAllText($biPath)
$stamped = $biDefault -replace 'const BUILD_ID := ".*"', ('const BUILD_ID := "' + $buildId + '"')

$profiles = if ($BuildProfile -eq "both") { @("dev", "tester") } else { @($BuildProfile) }
$zips = @()
try {
    [IO.File]::WriteAllText($biPath, $stamped)
    foreach ($p in $profiles) {
        $preset = "windows-$p"
        $outDir = Join-Path $repo "builds\$p"
        $exe = Join-Path $outDir "wildshot-$p.exe"
        if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
        New-Item -ItemType Directory -Force $outDir | Out-Null
        $flag = if ($p -eq "dev") { "--export-debug" } else { "--export-release" }
        if (-not $Quiet) { Write-Host "export: $preset -> $exe (build $buildId)" }
        & $godot --headless --path . $flag $preset $exe 2>&1 | ForEach-Object {
            if (-not $Quiet -and $_ -match "ERROR|WARNING|savepack|Wrote") { Write-Host "  $_" }
        }
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $exe)) {
            Write-Host "export: $preset FAILED (exit $LASTEXITCODE)"
            exit 1
        }
        # 2. Loose worldforge packs beside the exe (resolve_src fallback).
        Copy-Item (Join-Path $repo "assets\worldforge-packs") `
            (Join-Path $outDir "assets\worldforge-packs") -Recurse
        # 3. Zip: wildshot-<describe>-<profile>.zip
        $zip = Join-Path $repo ("builds\wildshot-{0}-{1}.zip" -f $buildId, $p)
        if (Test-Path $zip) { Remove-Item $zip -Force }
        Compress-Archive -Path "$outDir\*" -DestinationPath $zip
        $zips += $zip
        if (-not $Quiet) {
            Write-Host ("export: {0} ({1:n1} MB)" -f $zip, ((Get-Item $zip).Length / 1MB))
        }
    }
} finally {
    [IO.File]::WriteAllText($biPath, $biDefault)
}

# 4. Artifact boot check: run each exported exe briefly (windowed - the
#    release template has no headless server); exit 0 within the timeout
#    proves the pack loads, autoloads boot, and the arena builds.
if (-not $SkipBootCheck) {
    foreach ($p in $profiles) {
        $exe = Join-Path $repo "builds\$p\wildshot-$p.exe"
        $proc = Start-Process -FilePath $exe -ArgumentList "--quit-after", "120" -PassThru
        if (-not $proc.WaitForExit(60000)) {
            $proc.Kill()
            Write-Host "export: $p artifact boot TIMED OUT"
            exit 1
        }
        if ($proc.ExitCode -ne 0) {
            Write-Host "export: $p artifact boot FAILED (exit $($proc.ExitCode))"
            exit 1
        }
        if (-not $Quiet) { Write-Host "export: $p artifact boots clean (exit 0)" }
    }
}

# 5. Butler push is DESIGNER-run (their itch credentials; unlisted
#    PIPE-testers channel). Prepared command:
if (-not $Quiet -and ($BuildProfile -in @("tester", "both"))) {
    $tz = $zips | Where-Object { $_ -match "tester" } | Select-Object -First 1
    Write-Host ""
    Write-Host "designer push (when ready):"
    Write-Host "  butler push `"$tz`" sarepat/wildshot-adventures:pipe-testers --userversion $buildId"
}
exit 0
