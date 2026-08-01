# Parallel battery worker pool (S1 tooling ask, designer-approved
# 2026-08-01 evening; docs/23 tooling lane). The battery's replay/proof
# runs are independent processes writing disjoint report files — they
# run N-wide here. COVERAGE IS LAW: the caller's table is authoritative
# (not one row trimmed), every verdict is gated on BOTH the PASS/FAIL
# marker and the runner's exit code (0=PASS, 1=FAIL; 2/3/none = row
# failure), and the pretester's reports/-clean byte gate stays the
# final word — a cache race can only surface as a loud FAIL, never a
# silently wrong verdict.
#
# WORKER POLICY (ruled): default = physical core count (auto-detect),
# HARD CAP 10 (the designer's ceiling). Scheduling = longest rows
# first from the per-run timing table (reports/battery_timings.json,
# machine-local, gitignored); unknown rows schedule first.
#
# Dot-source this file, then call Invoke-BatteryParallel. It PRINTS
# nothing — the caller owns all output formatting.

function Get-PhysicalCoreCount {
    try {
        $sum = (Get-CimInstance Win32_Processor -ErrorAction Stop |
            Measure-Object -Property NumberOfCores -Sum).Sum
        if ($sum -ge 1) { return [int]$sum }
    } catch {}
    return 4
}

function Invoke-BatteryParallel {
    param(
        [object[]]$Battery,   # rows: scen, seeds, ticks, out, policy, wantFloor, wantCap
        [int]$Workers,
        [string]$Godot,
        [string]$TimingPath
    )

    # Expand table rows into the flat run list (floor lane always;
    # cap lane when the row declares a cap expectation).
    $runs = New-Object System.Collections.ArrayList
    $order = 0
    foreach ($b in $Battery) {
        $scen = $b[0]; $seeds = $b[1]; $ticks = $b[2]; $out = $b[3]; $pol = $b[4]
        $lanes = @(, @("3.6", $out, $b[5]))
        if ($b[6]) {
            $capout = if ($out) { $out -replace "\.json$", "_cap115.json" } else { "res://reports/dodge_${scen}_cap115.json" }
            $lanes += , @("4.14", $capout, $b[6])
        }
        foreach ($lane in $lanes) {
            $speed = $lane[0]; $rout = $lane[1]; $want = $lane[2]
            $tag = if ($pol) { " [$pol]" } else { "" }
            if ($speed -ne "3.6") { $tag += " [cap115]" }
            $ga = @("--headless", "--path", ".", "--script", "game/bots/bot_runner.gd", "--",
                "--scenario=$scen", "--speed=$speed", "--seeds=$seeds", "--ticks=$ticks")
            if ($rout) { $ga += "--out=$rout" }
            if ($pol) { $ga += "--policy=$pol" }
            [void]$runs.Add([pscustomobject]@{
                    Key   = "$scen$tag"
                    Name  = "battery: $scen$tag (expect $want)"
                    Args  = $ga
                    Want  = $want
                    Order = $order
                })
            $order++
        }
    }

    # Longest-first schedule from the timing table; unknown rows first
    # (a new row is assumed long until measured).
    $timings = @{}
    if ($TimingPath -and (Test-Path $TimingPath)) {
        try {
            $tj = Get-Content $TimingPath -Raw | ConvertFrom-Json
            foreach ($p in $tj.PSObject.Properties) { $timings[$p.Name] = [double]$p.Value }
        } catch {}
    }
    $scheduled = $runs | Sort-Object -Descending {
        if ($timings.ContainsKey($_.Key)) { [double]$timings[$_.Key] } else { [double]::MaxValue }
    }

    $throttle = [Math]::Max(1, [Math]::Min($Workers, 10))
    $results = $scheduled | ForEach-Object -ThrottleLimit $throttle -Parallel {
        $run = $_
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $out = & $using:Godot @($run.Args) 2>&1
        $code = $LASTEXITCODE
        $sw.Stop()
        $m = $out | Select-String -Pattern "\((PASS|FAIL)\)" | Select-Object -Last 1
        $got = if ($m) { $m -replace '.*\((PASS|FAIL)\).*', '$1' } else { "NONE" }
        $codeOk = if ($run.Want -eq "PASS") { $code -eq 0 } else { $code -eq 1 }
        [pscustomobject]@{
            Key     = $run.Key
            Name    = $run.Name
            Want    = $run.Want
            Got     = $got
            Code    = $code
            Ok      = (($got -eq $run.Want) -and $codeOk)
            Seconds = $sw.Elapsed.TotalSeconds
            Order   = $run.Order
        }
    }

    # Merge timings back (median-free: last observed wall time is a
    # good-enough scheduler key; the table converges run over run).
    foreach ($r in $results) { $timings[$r.Key] = [Math]::Round($r.Seconds, 1) }
    if ($TimingPath) {
        try { $timings | ConvertTo-Json | Set-Content $TimingPath } catch {}
    }

    return $results | Sort-Object Order
}
