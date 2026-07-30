# Shared exclusive-access check (2026-07-30). The .godot/ import-cache
# race is PER-PROJECT (HANDOFF gotcha 19): a Godot instance explicitly
# running ANOTHER project (absolute --path elsewhere) cannot race this
# repo and does not block. Everything ambiguous DOES block — no
# command line, no --path (project manager), or a relative --path
# (cwd unknowable) — conservative by construction. Evidence: the
# 2026-07-30 night's full gate runs beside a foreign-project editor,
# all deterministic, goldens byte-identical (b65 + audio commits).
function Get-BlockingGodot {
    param([string]$RepoRoot)
    $root = (Resolve-Path $RepoRoot).Path.TrimEnd('\')
    Get-CimInstance Win32_Process -Filter "Name like 'godot%'" | Where-Object {
        $cl = $_.CommandLine
        if (-not $cl) { return $true }
        if ($cl -notmatch '--path\s+"?([^"\s]+)"?') { return $true }
        $p = $Matches[1]
        if (-not [IO.Path]::IsPathRooted($p)) { return $true }
        $full = ""
        try { $full = (Resolve-Path $p -ErrorAction Stop).Path.TrimEnd('\') } catch { return $true }
        return $full -ieq $root
    }
}
