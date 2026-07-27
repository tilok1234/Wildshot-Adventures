<#
.SYNOPSIS
    Hours logging (PROD-01). Log ALL project work: code, art, design, planning.
.EXAMPLE
    tools/hourslog.ps1 start
    tools/hourslog.ps1 note "authored Fanmaw pattern"
    tools/hourslog.ps1 stop
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('start', 'stop', 'note')]
    [string]$Action,

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$NoteWords
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$csvPath = Join-Path $repoRoot 'notes/hours.csv'

if (-not (Test-Path $csvPath)) {
    New-Item -ItemType Directory -Force (Split-Path -Parent $csvPath) | Out-Null
    Set-Content -Path $csvPath -Value 'timestamp,action,note' -Encoding utf8
}

# Warn on double start / stop without start (log anyway; hours.csv is hand-fixable).
$lastState = ''
foreach ($line in (Get-Content $csvPath | Select-Object -Skip 1)) {
    $parts = $line -split ',', 3
    if ($parts.Count -ge 2 -and $parts[1] -in @('start', 'stop')) { $lastState = $parts[1] }
}
if ($Action -eq 'start' -and $lastState -eq 'start') {
    Write-Warning 'Previous session was never stopped — logging start anyway; fix notes/hours.csv by hand if needed.'
}
if ($Action -eq 'stop' -and $lastState -ne 'start') {
    Write-Warning 'No open session found — logging stop anyway; fix notes/hours.csv by hand if needed.'
}

$ts = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
$note = ($NoteWords -join ' ') -replace '"', '""'
Add-Content -Path $csvPath -Value "$ts,$Action,`"$note`"" -Encoding utf8
Write-Host "$ts  $Action  $note"
