#Requires -Version 7
<#
assemble.ps1 — builds wildshot-projectiles-ALL-v0: the five candidate packs
(v0 shaded, min flat, eclipse void-heart, mono disc library, ray capsules)
aggregated into ONE packet with ONE comparison preview.

Sources are the sibling pack folders (regenerate them first via their own
tools/generate.ps1 if edited); this script only copies, merges manifests,
and composes the preview. Deterministic, no RNG.

    pwsh tools/assemble.ps1
#>
param([string]$PackDir = (Split-Path $PSScriptRoot -Parent))
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path $PackDir -Parent
$SOURCES = [ordered]@{
    v0      = Join-Path $root 'wildshot-projectiles-v0'
    min     = Join-Path $root 'wildshot-projectiles-min-v0'
    eclipse = Join-Path $root 'wildshot-projectiles-eclipse-v0'
    mono    = Join-Path $root 'wildshot-projectiles-mono-v0'
    ray     = Join-Path $root 'wildshot-projectiles-ray-v0'
}

# ---------------- copy sprites + merge manifests ----------------
$allRows = @()
$styleBlocks = [ordered]@{}
foreach ($style in $SOURCES.Keys) {
    $src = $SOURCES[$style]
    if (-not (Test-Path (Join-Path $src 'manifest.json'))) { throw "missing source pack: $src" }
    $dstSprites = Join-Path $PackDir "sprites\$style"
    if (Test-Path $dstSprites) { Remove-Item -Recurse -Force $dstSprites }
    Copy-Item -Recurse (Join-Path $src 'sprites') $dstSprites
    $mf = Get-Content (Join-Path $src 'manifest.json') -Raw | ConvertFrom-Json
    $styleBlocks[$style] = [ordered]@{
        source_pack = $mf.pack + ' ' + $mf.version
        docs        = "../$(Split-Path $src -Leaf)/README.md"
    }
    foreach ($row in $mf.sprites) {
        $newFile = "sprites/$style/" + ($row.file -replace '^sprites/', '')
        $allRows += [ordered]@{
            id = "${style}:$($row.id)"; style = $style; file = $newFile
            faction = $row.faction; band = $row.band; canvas_px = $row.canvas_px
            frames = $row.frames; hitbox_diameter_px = $row.hitbox_diameter_px
            covers_hitbox = $row.covers_hitbox; oriented = $row.oriented
            suggested_pattern_ids = $row.suggested_pattern_ids; role = $row.role
        }
    }
    Write-Host "merged $style ($(@($mf.sprites).Count) rows)"
}

# backdrops for the viewer (copy once from v0)
$bdDst = Join-Path $PackDir 'preview\backdrops'
if (-not (Test-Path $bdDst)) { New-Item -ItemType Directory -Force $bdDst | Out-Null }
Copy-Item (Join-Path $SOURCES['v0'] 'preview\backdrops\*') $bdDst -Force

# ---------------- the ONE preview sheet ----------------
# rows = styles, columns = Phase-A slots, on dusk + winter, zones row at 1x.
$SLOTS = @('husk', 'leadshot', 'fanmaw', 'ringer', 'elite', 'longbolt', 'scatter', 'wheel', 'nova')
$FILES = [ordered]@{
    v0      = @('hostile/orb.png','hostile/dart.png','hostile/fang.png','hostile/burr.png','hostile/heavy-orb.png','friendly/longbolt.png','friendly/scattercast-pellet.png','friendly/wheelblade.png','friendly/nova-ring.png')
    min     = @('hostile/orb.png','hostile/dart.png','hostile/fang.png','hostile/burr.png','hostile/heavy-orb.png','friendly/longbolt.png','friendly/scattercast-pellet.png','friendly/wheelblade.png','friendly/nova-ring.png')
    eclipse = @('hostile/orb.png','hostile/dart.png','hostile/fang.png','hostile/burr.png','hostile/heavy-orb.png','friendly/longbolt.png','friendly/scattercast-pellet.png','friendly/wheelblade.png','friendly/nova-ring.png')
    mono    = @('hostile/disc-d12-plain.png','hostile/disc-d12-dash.png','hostile/disc-d13-pair.png','hostile/disc-d13-triad.png','hostile/disc-d16-ring.png','friendly/bolt-single.png','friendly/pellet-single.png','friendly/ring.png','friendly/nova-ring.png')
    ray     = @('hostile/cap-w12-l20-plain.png','hostile/cap-w12-l26-plain.png','hostile/cap-w13-l18-band.png','hostile/cap-w13-l18-pair.png','hostile/cap-w16-l24-plain.png','friendly/bolt-single.png','friendly/pellet-single.png','friendly/cross-a.png','friendly/nova-ring.png')
}

function Load-Png([string]$path) {
    $fs = [System.IO.File]::OpenRead($path)
    try { $img = [System.Drawing.Bitmap]::new($fs) } finally { $fs.Dispose() }
    return $img
}
function Scale-Nearest([System.Drawing.Bitmap]$src, [int]$n) {
    $dst = [System.Drawing.Bitmap]::new($src.Width * $n, $src.Height * $n, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $src.Height; $y++) {
        for ($x = 0; $x -lt $src.Width; $x++) {
            $c = $src.GetPixel($x, $y)
            if ($c.A -eq 0) { continue }
            for ($j = 0; $j -lt $n; $j++) {
                for ($i = 0; $i -lt $n; $i++) { $dst.SetPixel($x * $n + $i, $y * $n + $j, $c) }
            }
        }
    }
    return $dst
}

$DUSK = [System.Drawing.Color]::FromArgb(255, 67, 112, 106)
$WINT = [System.Drawing.Color]::FromArgb(255, 148, 189, 159)

$cell = 118; $rowH = 108; $gutter = 96
$cols = $SLOTS.Count
$panelH = 5 * $rowH + 52
$zonesH = 96 + 56
$W = $gutter + $cell * $cols + 12
$H = $panelH * 2 + $zonesH
$sheet = [System.Drawing.Bitmap]::new($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::SingleBitPerPixelGridFit
$font = [System.Drawing.Font]::new('Consolas', 9)
$fontB = [System.Drawing.Font]::new('Consolas', 10, [System.Drawing.FontStyle]::Bold)

$panels = @(@($DUSK, [System.Drawing.Brushes]::White, 'dusk ground'), @($WINT, [System.Drawing.Brushes]::Black, 'winter ground'))
for ($p = 0; $p -lt 2; $p++) {
    $oyP = $p * $panelH
    $bg = [System.Drawing.SolidBrush]::new($panels[$p][0])
    $g.FillRectangle($bg, 0, $oyP, $W, $panelH); $bg.Dispose()
    $g.DrawString(('wildshot-projectiles-all-v0 — five styles x Phase-A slots, 4x on ' + $panels[$p][2]), $fontB, $panels[$p][1], 8, $oyP + 6)
    for ($ci = 0; $ci -lt $cols; $ci++) {
        $g.DrawString($SLOTS[$ci], $font, $panels[$p][1], $gutter + $ci * $cell + 34, $oyP + 28)
    }
    $si = 0
    foreach ($style in $FILES.Keys) {
        $oyR = $oyP + 46 + $si * $rowH
        $g.DrawString($style, $fontB, $panels[$p][1], 8, $oyR + 40)
        for ($ci = 0; $ci -lt $cols; $ci++) {
            $img = Load-Png (Join-Path $PackDir ("sprites\$style\" + ($FILES[$style][$ci] -replace '/', '\')))
            $sc = if ($SLOTS[$ci] -eq 'nova') { 2 } else { 4 }
            $up = Scale-Nearest $img $sc
            $ox = $gutter + $ci * $cell + [int](($cell - $up.Width) / 2)
            $oy = $oyR + [int](($rowH - $up.Height) / 2)
            $g.DrawImage($up, $ox, $oy, $up.Width, $up.Height)
            $up.Dispose(); $img.Dispose()
        }
        $si++
    }
}

# zones strip: hazard + rune per style at 1x on dusk
$oyZ = $panelH * 2
$bg = [System.Drawing.SolidBrush]::new($DUSK)
$g.FillRectangle($bg, 0, $oyZ, $W, $zonesH); $bg.Dispose()
$g.DrawString('zones at 1x per style (hazard + blast rune)', $fontB, [System.Drawing.Brushes]::White, 8, $oyZ + 6)
$zi = 0
foreach ($style in $FILES.Keys) {
    foreach ($zf in @('hostile/hazard-zone.png', 'friendly/blast-rune-zone.png')) {
        $img = Load-Png (Join-Path $PackDir ("sprites\$style\" + ($zf -replace '/', '\')))
        $ox = 12 + $zi * 106
        $g.DrawImage($img, $ox, $oyZ + 28, 96, 96)
        $img.Dispose()
        $zi++
    }
    $g.DrawString($style, $font, [System.Drawing.Brushes]::White, 12 + ($zi - 2) * 106 + 60, $oyZ + 128)
}
$g.Dispose()
$prevDir = Join-Path $PackDir 'preview'
if (-not (Test-Path $prevDir)) { New-Item -ItemType Directory -Force $prevDir | Out-Null }
$outPng = Join-Path $prevDir 'all-styles.png'
$sheet.Save($outPng, [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
Write-Host "wrote $outPng"

# ---------------- merged manifest ----------------
$manifest = [ordered]@{
    pack         = 'wildshot-projectiles-all'
    version      = 'v0'
    generated_by = 'tools/assemble.ps1 (aggregates the five source packs; regenerate sources first)'
    px_per_tile  = 32
    scale        = 'native 1x'
    filtering    = 'nearest'
    styles       = $styleBlocks
    note         = 'One packet, five interchangeable styles. Per-style contracts, Phase-A mappings and integration notes live in each source pack README (paths under styles.*.docs). Common law: hostile signature per style, Law-8 coverage asserted by each source generator, §2.5 bands (5 friendly / 7 hostile / 8 hazard rim+arm), hostile channels clamped at every density setting.'
    sprites      = $allRows
}
$json = $manifest | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText((Join-Path $PackDir 'manifest.json'), $json, [System.Text.UTF8Encoding]::new($false))
Write-Host "wrote $(Join-Path $PackDir 'manifest.json')"
Write-Host "DONE: $($allRows.Count) merged rows across $($SOURCES.Keys.Count) styles."
