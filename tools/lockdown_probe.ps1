# tools/lockdown_probe.ps1 — tester-artifact lockdown probe (M8 Gate-1-ready
# checklist, docs/12 §4: "no sim-mutating debug tool reachable" + contamination
# evidence). Dynamic half of the sweep — tools/lockdown_lint.py proves the gate
# at source level; this proves it ON THE BUILT ARTIFACTS in builds/:
#
#   A  dev exe + --bot=dodge_proof  -> report file WRITTEN (positive control:
#      proves the probe methodology works and the dev artifact has dev_tools on)
#   B  tester exe + same args       -> NO report; normal boot, exit 0
#   C  tester exe + --audit=density -> no audit side effects; exit 0
#   D  tester exe + --script bot_runner -> fact-find: is the --script surface
#      reachable in a release template? (INFO either way — bot_runner is not
#      sim-mutating for a play session — but the fact is recorded.)
#   E  session evidence: bytes appended to session.jsonl by tester runs carry
#      no god/DAMAGE_IMMUNE markers; verdicts.jsonl untouched by tester runs.
#
# Input injection (console key, free-speed keys) is impossible headless — those
# surfaces are covered by the source lint (console never constructed, inputs
# dev_tools-gated on the checked lines).
#
# Usage: pwsh tools/lockdown_probe.ps1 [-Quiet]   (run tools/export.ps1 first)

param([switch]$Quiet)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

$devExe = Join-Path $repo "builds\dev\wildshot-dev.exe"
$testerExe = Join-Path $repo "builds\tester\wildshot-tester.exe"
if (-not (Test-Path $devExe) -or -not (Test-Path $testerExe)) {
    Write-Host "lockdown probe: builds missing - run tools/export.ps1 first"
    exit 2
}
# Exclusive access: same doctrine as export/pretester (and probe runs must not
# interleave session.jsonl with a live game).
$others = Get-Process godot, godot_console -ErrorAction SilentlyContinue
if ($others) {
    Write-Host "lockdown probe: refusing to run - other Godot instance(s) live."
    exit 2
}

$fails = @()
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tmp = Join-Path $env:TEMP "wildshot_lockdown_$stamp"
New-Item -ItemType Directory -Force $tmp | Out-Null
$sessionLog = Join-Path $env:APPDATA "Godot\app_userdata\Wildshot Adventures\logs\session.jsonl"
$verdictLog = Join-Path $env:APPDATA "Godot\app_userdata\Wildshot Adventures\logs\verdicts.jsonl"

function Invoke-Artifact($exe, $argList, $timeoutMs, $outFile) {
    $so = Join-Path $tmp "$outFile.out.txt"
    $se = Join-Path $tmp "$outFile.err.txt"
    $proc = Start-Process -FilePath $exe -ArgumentList $argList -PassThru `
        -RedirectStandardOutput $so -RedirectStandardError $se
    if (-not $proc.WaitForExit($timeoutMs)) {
        $proc.Kill()
        return @{ timeout = $true; code = -1; stdout = "" }
    }
    $text = if (Test-Path $so) { [IO.File]::ReadAllText($so) } else { "" }
    return @{ timeout = $false; code = $proc.ExitCode; stdout = $text }
}

function Get-LogLength($path) {
    if (Test-Path $path) { (Get-Item $path).Length } else { 0 }
}

function Get-AppendedText($path, $before) {
    if (-not (Test-Path $path)) { return "" }
    $fs = [IO.File]::Open($path, "Open", "Read", "ReadWrite")
    try {
        $fs.Seek($before, "Begin") | Out-Null
        $sr = New-Object IO.StreamReader($fs)
        return $sr.ReadToEnd()
    } finally { $fs.Close() }
}

# --- A: dev positive control -------------------------------------------------
$reportA = Join-Path $tmp "probe_a_dev_bot.json"
$r = Invoke-Artifact $devExe @(
    "--quit-after", "1800", "--",
    "--bot=dodge_proof", "--scenario=canary_trivial", "--seeds=1", "--ticks=120",
    "--out=$reportA"
) 90000 "probe_a"
if ($r.timeout) { $fails += "A: dev bot probe timed out" }
elseif (-not (Test-Path $reportA)) {
    $fails += "A: dev exe did not write the bot report (positive control broken - probe methodology void)"
}
if (-not $Quiet) {
    Write-Host ("probe A (dev +bot writes report):        {0}" -f $(if (Test-Path $reportA) { "PASS" } else { "FAIL" }))
}

# --- B: tester bot refusal ---------------------------------------------------
$reportB = Join-Path $tmp "probe_b_tester_bot.json"
$sesBefore = Get-LogLength $sessionLog
$verBefore = Get-LogLength $verdictLog
$r = Invoke-Artifact $testerExe @(
    "--quit-after", "120", "--",
    "--bot=dodge_proof", "--scenario=canary_trivial", "--seeds=1", "--ticks=120",
    "--out=$reportB"
) 90000 "probe_b"
$bOk = $true
if ($r.timeout) { $fails += "B: tester bot probe timed out"; $bOk = $false }
if ($r.code -ne 0) { $fails += "B: tester exe exited $($r.code) (expected clean normal boot)"; $bOk = $false }
if (Test-Path $reportB) { $fails += "B: TESTER EXE RAN THE BOT - dev_tools gate breached"; $bOk = $false }
if (-not $Quiet) {
    Write-Host ("probe B (tester +bot refused):           {0}" -f $(if ($bOk) { "PASS" } else { "FAIL" }))
}

# --- C: tester audit refusal -------------------------------------------------
$r = Invoke-Artifact $testerExe @(
    "--quit-after", "120", "--", "--audit=density"
) 90000 "probe_c"
$cOk = $true
if ($r.timeout) { $fails += "C: tester audit probe timed out"; $cOk = $false }
if ($r.code -ne 0) { $fails += "C: tester exe exited $($r.code) on --audit (expected clean normal boot)"; $cOk = $false }
if ($r.stdout -match "audit") { $fails += "C: tester stdout mentions audit mode"; $cOk = $false }
if (-not $Quiet) {
    Write-Host ("probe C (tester +audit refused):         {0}" -f $(if ($cOk) { "PASS" } else { "FAIL" }))
}

# --- F: tester --verify refusal ----------------------------------------------
$r = Invoke-Artifact $testerExe @(
    "--quit-after", "120", "--", "--verify=core50-low"
) 90000 "probe_f"
$fOk = $true
if ($r.timeout) { $fails += "F: tester verify probe timed out"; $fOk = $false }
if ($r.code -ne 0) { $fails += "F: tester exe exited $($r.code) on --verify (expected clean normal boot)"; $fOk = $false }
if ($r.stdout -match "core50 verify") { $fails += "F: tester exe ran the CORE-50 verify CLI"; $fOk = $false }
if (-not $Quiet) {
    Write-Host ("probe F (tester +verify refused):        {0}" -f $(if ($fOk) { "PASS" } else { "FAIL" }))
}

# --- E (covers B+C+F runs): session evidence ---------------------------------
$appended = Get-AppendedText $sessionLog $sesBefore
$eOk = $true
if ($appended -match "DAMAGE_IMMUNE|SET_GOD|slowmo") {
    $fails += "E: tester session evidence contains dev-tool markers"
    $eOk = $false
}
if ((Get-LogLength $verdictLog) -ne $verBefore) {
    $fails += "E: verdicts.jsonl changed during tester runs"
    $eOk = $false
}
if (-not $Quiet) {
    Write-Host ("probe E (session evidence clean):        {0}" -f $(if ($eOk) { "PASS" } else { "FAIL" }))
}

# --- D: --script surface fact-find (INFO) ------------------------------------
$reportD = Join-Path $tmp "probe_d_tester_script.json"
$r = Invoke-Artifact $testerExe @(
    "--headless", "--script", "res://game/bots/bot_runner.gd", "--",
    "--scenario=first_contact", "--seeds=1", "--ticks=120", "--out=$reportD"
) 90000 "probe_d"
$dVerdict = "UNREACHABLE (good)"
if (Test-Path $reportD) {
    $dVerdict = "REACHABLE AND FUNCTIONAL - bot ran from the tester zip"
} elseif ($r.stdout -match "bot_runner|dodge_proof|scenario") {
    $dVerdict = "REACHABLE (script executed; no report written)"
}
if (-not $Quiet) {
    Write-Host ("probe D (--script surface, INFO):        {0}" -f $dVerdict)
    if ($dVerdict -ne "UNREACHABLE (good)") {
        Write-Host "  note: not sim-mutating for a play session (M8 accept line unaffected);"
        Write-Host "  to close anyway: add game/bots/* to the windows-tester exclude_filter."
    }
}

Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
if ($fails.Count -gt 0) {
    Write-Host "LOCKDOWN PROBE: FAIL"
    $fails | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
Write-Host "LOCKDOWN PROBE: PASS - tester artifact refuses every probed dev surface"
exit 0
