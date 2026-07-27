<#
.SYNOPSIS
    4-week rolling average vs the PROD-01 floor (default 40 h/week).
    A breach triggers the floor reset, the docs/12 §4 slip ladder, and roadmap
    re-derivation — by rule, not mood. First meaningful run: end of week 4,
    when the first rolling window closes.
#>
param(
    [double]$FloorHours = 40.0,
    [int]$WindowDays = 28
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$csvPath = Join-Path $repoRoot 'notes/hours.csv'
if (-not (Test-Path $csvPath)) { Write-Error "No hours log at $csvPath"; exit 1 }

$sessions = @()
$openStart = $null
foreach ($row in Import-Csv $csvPath) {
    $t = [datetime]::ParseExact($row.timestamp, 'yyyy-MM-ddTHH:mm:ss', $null)
    switch ($row.action) {
        'start' {
            if ($null -ne $openStart) {
                Write-Warning "start at $($row.timestamp) while a session was already open — previous start discarded"
            }
            $openStart = $t
        }
        'stop' {
            if ($null -ne $openStart) {
                $sessions += [pscustomobject]@{ Start = $openStart; Stop = $t; Hours = ($t - $openStart).TotalHours }
                $openStart = $null
            }
            else {
                Write-Warning "stop at $($row.timestamp) with no open session — ignored"
            }
        }
    }
}
if ($null -ne $openStart) { Write-Warning "Session opened $openStart is still running — not counted yet." }

$now = Get-Date
$windowStart = $now.AddDays(-$WindowDays)
$inWindow = @($sessions | Where-Object { $_.Stop -gt $windowStart })
$total = ($inWindow | Measure-Object -Property Hours -Sum).Sum
if (-not $total) { $total = 0.0 }
$weekly = $total / ($WindowDays / 7.0)

$firstStart = if ($sessions.Count) { $sessions[0].Start } elseif ($null -ne $openStart) { $openStart } else { $now }
$daysOfData = [math]::Min($WindowDays, ($now - $firstStart).TotalDays)

'Hours report — {0:yyyy-MM-dd HH:mm}' -f $now
'Closed sessions in last {0} days : {1}  ({2:N1} h total)' -f $WindowDays, $inWindow.Count, $total
'Rolling weekly average           : {0:N1} h/week  (floor: {1:N0})' -f $weekly, $FloorHours

if ($daysOfData -lt $WindowDays) {
    'NOTE: only {0:N1} days of data — the first full window closes at end of week 4; the average understates until then.' -f $daysOfData
}
elseif ($weekly -lt $FloorHours) {
    Write-Warning ('FLOOR BREACH: {0:N1} < {1:N0} h/week — PROD-01 floor reset + docs/12 §4 slip ladder + roadmap re-derivation trigger BY RULE.' -f $weekly, $FloorHours)
    exit 2
}
