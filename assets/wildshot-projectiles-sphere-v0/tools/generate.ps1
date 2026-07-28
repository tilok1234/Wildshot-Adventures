#Requires -Version 7
<#
generate.ps1 — deterministic pixel generator for wildshot-projectiles-SPHERE-v0.

Shaded orbs at full color-system scale: a 24-step hue wheel (deterministic
HSV with per-region value tuning — raw wheel steps are perceptually uneven)
x 3 tones (pastel / base / deep) + white/gray/black neutrals = 75 color
identities, each in 4 sizes = 300 hostile orbs. Every orb: one color
identity, NW-offset highlight, deepening edge, near-BLACK outline (never
pure #000 — world law). Hard binary-alpha silhouette.

Friendly stays exclusively desaturated silver (and smaller than hitbox) —
the faction split rides on saturation/value; the M6 Law-3 stress test is
the arbiter, own-hue bright outlines are the recorded fallback.

    pwsh tools/generate.ps1
#>
param([string]$PackDir = (Split-Path $PSScriptRoot -Parent))
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function New-Bmp([int]$w, [int]$h) {
    [System.Drawing.Bitmap]::new($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
}
function Save-Png([System.Drawing.Bitmap]$bmp, [string]$path) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}
function SS([double]$v, [double]$e0, [double]$e1) {
    $t = ($v - $e0) / ($e1 - $e0)
    if ($t -lt 0) { $t = 0.0 } elseif ($t -gt 1) { $t = 1.0 }
    return $t * $t * (3.0 - 2.0 * $t)
}
function MixC([array]$a, [array]$b, [double]$t) {
    @([int][math]::Round($a[0] + ($b[0] - $a[0]) * $t),
      [int][math]::Round($a[1] + ($b[1] - $a[1]) * $t),
      [int][math]::Round($a[2] + ($b[2] - $a[2]) * $t))
}
function HsvToRgb([double]$h, [double]$s, [double]$v) {
    $h = (($h % 360) + 360) % 360
    $c = $v * $s
    $x = $c * (1 - [math]::Abs((($h / 60.0) % 2) - 1))
    $m = $v - $c
    $rgb = switch ([int][math]::Floor($h / 60.0)) {
        0 { @($c, $x, 0) } 1 { @($x, $c, 0) } 2 { @(0, $c, $x) }
        3 { @(0, $x, $c) } 4 { @($x, 0, $c) } default { @($c, 0, $x) }
    }
    @([int][math]::Round(255 * ($rgb[0] + $m)), [int][math]::Round(255 * ($rgb[1] + $m)), [int][math]::Round(255 * ($rgb[2] + $m)))
}
function Scale-Nearest([System.Drawing.Bitmap]$src, [int]$n) {
    $dst = New-Bmp ($src.Width * $n) ($src.Height * $n)
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
function Assert-Covers([System.Drawing.Bitmap]$bmp, [double]$hx, [double]$hy, [double]$hr, [string]$id) {
    for ($y = 0; $y -lt $bmp.Height; $y++) {
        for ($x = 0; $x -lt $bmp.Width; $x++) {
            $ddx = ($x + 0.5) - $hx; $ddy = ($y + 0.5) - $hy
            if (($ddx * $ddx + $ddy * $ddy) -le ($hr * $hr)) {
                if ($bmp.GetPixel($x, $y).A -ne 255) { throw "COVERS FAIL: $id at $x,$y" }
            }
        }
    }
}

# ---------- the color system ----------
# (named HUEWHEEL, not WHEEL — the friendly $wheel bitmap below would alias
# it, PowerShell variable names being case-insensitive)
$HUEWHEEL = [ordered]@{
    red = 2; vermilion = 15; orange = 28; amber = 42; gold = 52; yellow = 62
    chartreuse = 78; lime = 95; green = 115; emerald = 135; jade = 152; teal = 168
    cyan = 184; sky = 200; azure = 214; blue = 227; sapphire = 240; indigo = 256
    violet = 271; purple = 286; orchid = 301; magenta = 316; pink = 331; rose = 346
}
function BaseSV([double]$ang) {
    # per-region tuning: yellows/limes run hot, blues run dark
    $s = 0.80; $v = 0.90
    if ($ang -ge 40 -and $ang -le 105) { $v = 0.86; $s = 0.84 }
    if ($ang -ge 200 -and $ang -le 262) { $v = 0.94 }
    return @($s, $v)
}
$IDENTS = [ordered]@{}
foreach ($name in $HUEWHEEL.Keys) {
    $ang = [double]$HUEWHEEL[$name]
    $sv = BaseSV $ang
    $IDENTS[$name] = HsvToRgb $ang $sv[0] $sv[1]
    $IDENTS["$name-pastel"] = HsvToRgb $ang ($sv[0] * 0.42) ([math]::Min(1.0, $sv[1] * 1.08))
    $IDENTS["$name-deep"] = HsvToRgb $ang ([math]::Min(1.0, $sv[0] * 1.05)) ($sv[1] * 0.52)
    $IDENTS["$name-dark"] = HsvToRgb $ang ([math]::Min(1.0, $sv[0] * 1.05)) ($sv[1] * 0.34)
}
# neutral ramp — "black as well": tones for the achromatic family
$IDENTS['white'] = @(235, 238, 242)
$IDENTS['gray'] = @(150, 155, 165)
$IDENTS['slate'] = @(108, 114, 126)
$IDENTS['charcoal'] = @(76, 72, 86)
$IDENTS['black'] = @(55, 50, 60)
$IDENTS['onyx'] = @(34, 30, 42)

$WHITE = @(255, 255, 255)
$DARKEN = @(36, 18, 30)
$OUTLINE = @(18, 14, 20)     # near-black (world law: never pure #000)
$F_BASE = @(198, 212, 224)   # friendly silver
$F_OUTM = @(116, 138, 156)

function New-ShadedOrb {
    param([int]$Canvas, [double]$ArtR, [array]$BaseC)
    $hiC = MixC $BaseC $WHITE 0.62
    $deepC = MixC $BaseC $DARKEN 0.42
    $c = $Canvas / 2.0
    $hx = $c - $ArtR * 0.30; $hy = $c - $ArtR * 0.30
    # outline thins with radius so tiny orbs keep a visible body
    $outW = [math]::Max(0.85, [math]::Min(1.15, $ArtR * 0.26))
    $outIn = $ArtR - $outW
    $bmp = New-Bmp $Canvas $Canvas
    for ($y = 0; $y -lt $Canvas; $y++) {
        for ($x = 0; $x -lt $Canvas; $x++) {
            $px = $x + 0.5; $py = $y + 0.5
            $ddx = $px - $c; $ddy = $py - $c
            $dist = [math]::Sqrt($ddx * $ddx + $ddy * $ddy)
            if ($dist -gt $ArtR) { continue }
            $col = $BaseC
            $col = MixC $col $deepC (0.75 * (SS $dist ($ArtR * 0.30) $outIn))
            $hdx = $px - $hx; $hdy = $py - $hy
            $hd = [math]::Sqrt($hdx * $hdx + $hdy * $hdy)
            $col = MixC $col $hiC (0.85 * (1.0 - (SS $hd ($ArtR * 0.12) ($ArtR * 0.62))))
            $col = MixC $col $OUTLINE (SS $dist ($outIn - 0.45) ($outIn + 0.45))
            $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $col[0], $col[1], $col[2]))
        }
    }
    return $bmp
}

# fresh output tree
if (Test-Path (Join-Path $PackDir 'sprites')) { Remove-Item -Recurse -Force (Join-Path $PackDir 'sprites') }
$sprites = @()
$dirS = Join-Path $PackDir 'sprites'
$made = @{}

# ---------------- hostile: 7 sizes x 75 identities ----------------
# d6/d8/d10 are the small tier (Phase B swarms/spray; d10 fits an r0.15
# hostile shot). d12..d20 map today's §3.4 radii + elite tiers.
$SIZES = @(6, 8, 10, 12, 13, 16, 20)
$count = 0
foreach ($Dia in $SIZES) {
    foreach ($ident in $IDENTS.Keys) {
        $bmp = New-ShadedOrb -Canvas $Dia -ArtR ($Dia / 2.0) -BaseC $IDENTS[$ident]
        Assert-Covers $bmp ($Dia / 2.0) ($Dia / 2.0) ($Dia / 2.0 - 0.05) "hostile/orb-d$Dia-$ident"
        $rel = "sprites/hostile/orb-d$Dia-$ident.png"
        Save-Png $bmp (Join-Path $PackDir ($rel -replace '/', '\'))
        $made[$rel] = $bmp
        $sprites += [ordered]@{ id = "hostile-orb:d$Dia-$ident"; file = $rel; faction = 'hostile'; band = 7
            canvas_px = @($Dia, $Dia); frames = 1; hitbox_diameter_px = $Dia; covers_hitbox = $true; oriented = $false
            suggested_pattern_ids = @(); role = "shaded orb d$Dia px, color '$ident'" }
        $count++
    }
}
Write-Host "COVERS: all $count hostile orbs PASS"

# ---------------- zones + arm ring ----------------
$G_RIM = @(255, 233, 168)
$REDC = $IDENTS['red']
$haz = New-Bmp 96 96
for ($y = 0; $y -lt 96; $y++) {
    for ($x = 0; $x -lt 96; $x++) {
        $ddx = ($x + 0.5) - 48.0; $ddy = ($y + 0.5) - 48.0
        $dist = [math]::Sqrt($ddx * $ddx + $ddy * $ddy)
        if ($dist -gt 48.0) { continue }
        $col = $null; $alpha = 255
        if ($dist -gt 44.5) { $col = MixC $REDC $G_RIM (SS $dist 44.5 45.6) }
        elseif ($dist -le 2.6) { $col = MixC $REDC $DARKEN 0.5; $alpha = 235 }
        else { $col = $REDC; $alpha = 55 }
        $haz.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $col[0], $col[1], $col[2]))
    }
}
for ($y = 0; $y -lt 96; $y++) {
    for ($x = 0; $x -lt 96; $x++) {
        $ddx = ($x + 0.5) - 48.0; $ddy = ($y + 0.5) - 48.0
        $dist = [math]::Sqrt($ddx * $ddx + $ddy * $ddy)
        if ($dist -gt 44.9 -and $dist -le 47.5 -and $haz.GetPixel($x, $y).A -ne 255) { throw "hazard rim not opaque at $x,$y" }
    }
}
Write-Host 'COVERS: hostile/hazard-zone rim band PASS'
Save-Png $haz (Join-Path $dirS 'hostile\hazard-zone.png')
$made['sprites/hostile/hazard-zone.png'] = $haz
$sprites += [ordered]@{ id = 'hostile-hazard-zone'; file = 'sprites/hostile/hazard-zone.png'; faction = 'hostile'; band = 8
    canvas_px = @(96, 96); frames = 1; hitbox_diameter_px = 96; covers_hitbox = $false; oriented = $false
    suggested_pattern_ids = @(); role = '1.5-tile-radius ground zone; bright rim opaque at true boundary' }

$strip = New-Bmp (96 * 8) 96
for ($k = 0; $k -lt 8; $k++) {
    $sweep = 45.0 * ($k + 1)
    for ($y = 0; $y -lt 96; $y++) {
        for ($x = 0; $x -lt 96; $x++) {
            $ddx = ($x + 0.5) - 48.0; $ddy = ($y + 0.5) - 48.0
            $dist = [math]::Sqrt($ddx * $ddx + $ddy * $ddy)
            if ($dist -lt 39.5 -or $dist -gt 43.0) { continue }
            $a = [math]::Atan2($ddx, -$ddy) * 180.0 / [math]::PI
            if ($a -lt 0) { $a += 360.0 }
            if ($a -le $sweep) { $strip.SetPixel(96 * $k + $x, $y, [System.Drawing.Color]::FromArgb(255, 255, 233, 168)) }
            else { $strip.SetPixel(96 * $k + $x, $y, [System.Drawing.Color]::FromArgb(50, 255, 233, 168)) }
        }
    }
}
Save-Png $strip (Join-Path $dirS 'hostile\hazard-arm-strip8.png')
$made['sprites/hostile/hazard-arm-strip8.png'] = $strip
$sprites += [ordered]@{ id = 'hostile-hazard-arm'; file = 'sprites/hostile/hazard-arm-strip8.png'; faction = 'hostile'; band = 8
    canvas_px = @(768, 96); frames = 8; frame_w = 96; hitbox_diameter_px = 96; covers_hitbox = $false; oriented = $false
    suggested_pattern_ids = @(); role = 'arm-progress ring, 8 steps CW from 12 o''clock (§2.5 band 8)' }

# ---------------- friendly (unchanged silver language) ----------------
$bolt = New-ShadedOrb -Canvas 10 -ArtR 4.0 -BaseC $F_BASE
Save-Png $bolt (Join-Path $dirS 'friendly\bolt.png')
$made['sprites/friendly/bolt.png'] = $bolt
$sprites += [ordered]@{ id = 'friendly-bolt'; file = 'sprites/friendly/bolt.png'; faction = 'friendly'; band = 5
    canvas_px = @(10, 10); frames = 1; hitbox_diameter_px = 10; covers_hitbox = $false; oriented = $false
    suggested_pattern_ids = @(1); role = 'Longbolt (§3.3): round shaded silver; view travel-stretch supplies elongation' }

$pellet = New-ShadedOrb -Canvas 8 -ArtR 3.2 -BaseC $F_BASE
Save-Png $pellet (Join-Path $dirS 'friendly\pellet.png')
$made['sprites/friendly/pellet.png'] = $pellet
$sprites += [ordered]@{ id = 'friendly-pellet'; file = 'sprites/friendly/pellet.png'; faction = 'friendly'; band = 5
    canvas_px = @(8, 8); frames = 1; hitbox_diameter_px = 8; covers_hitbox = $false; oriented = $false
    suggested_pattern_ids = @(2); role = 'Scattercast (§3.3): art d6.4 inside hd8 — deliberately smaller (Law 2/8)' }

$wheel = New-Bmp 13 13
for ($y = 0; $y -lt 13; $y++) {
    for ($x = 0; $x -lt 13; $x++) {
        $px = $x + 0.5; $py = $y + 0.5
        $ddx = $px - 6.5; $ddy = $py - 6.5
        $dist = [math]::Sqrt($ddx * $ddx + $ddy * $ddy)
        if ($dist -gt 5.7 -or $dist -lt 2.1) { continue }
        $col = $F_BASE
        $hd = [math]::Sqrt(($px - 4.6) * ($px - 4.6) + ($py - 4.6) * ($py - 4.6))
        $col = MixC $col (MixC $F_BASE $WHITE 0.55) (0.7 * (1.0 - (SS $hd 1.2 4.8)))
        $col = MixC $col $OUTLINE ((SS $dist 4.7 5.6) + (1.0 - (SS $dist 2.1 3.0)))
        $wheel.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $col[0], $col[1], $col[2]))
    }
}
Save-Png $wheel (Join-Path $dirS 'friendly\wheel-ring.png')
$made['sprites/friendly/wheel-ring.png'] = $wheel
$sprites += [ordered]@{ id = 'friendly-wheel-ring'; file = 'sprites/friendly/wheel-ring.png'; faction = 'friendly'; band = 5
    canvas_px = @(13, 13); frames = 1; hitbox_diameter_px = 13; covers_hitbox = $false; oriented = $false
    suggested_pattern_ids = @(3); role = 'Wheelblade (§3.3): shaded silver annulus, art d11.4 inside hd13' }

$nova = New-Bmp 48 48
for ($y = 0; $y -lt 48; $y++) {
    for ($x = 0; $x -lt 48; $x++) {
        $ddx = ($x + 0.5) - 24.0; $ddy = ($y + 0.5) - 24.0
        $dist = [math]::Sqrt($ddx * $ddx + $ddy * $ddy)
        if ($dist -lt 16.0 -or $dist -gt 20.5) { continue }
        $col = MixC $F_BASE $F_OUTM ((SS $dist 19.4 20.5) + (1.0 - (SS $dist 16.0 17.1)))
        $nova.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(205, $col[0], $col[1], $col[2]))
    }
}
Save-Png $nova (Join-Path $dirS 'friendly\nova-ring.png')
$made['sprites/friendly/nova-ring.png'] = $nova
$sprites += [ordered]@{ id = 'friendly-nova-ring'; file = 'sprites/friendly/nova-ring.png'; faction = 'friendly'; band = 5
    canvas_px = @(48, 48); frames = 1; hitbox_diameter_px = 0; covers_hitbox = $false; oriented = $false
    suggested_pattern_ids = @(-1); role = 'Nova Burst cast flash (§3.6)' }

$rune = New-Bmp 96 96
for ($y = 0; $y -lt 96; $y++) {
    for ($x = 0; $x -lt 96; $x++) {
        $ddx = ($x + 0.5) - 48.0; $ddy = ($y + 0.5) - 48.0
        $dist = [math]::Sqrt($ddx * $ddx + $ddy * $ddy)
        if ($dist -gt 48.0) { continue }
        $col = $null; $alpha = 255
        if ($dist -gt 45.6) { $col = MixC $F_BASE $F_OUTM ((SS $dist 47.0 48.0) + (1.0 - (SS $dist 45.6 46.6))); $alpha = 225 }
        elseif ($dist -le 2.6) { $col = $WHITE }
        elseif ($dist -le 5.0) { $col = $F_BASE; $alpha = 200 }
        else { $col = $F_BASE; $alpha = 24 }
        if ($null -ne $col) { $rune.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $col[0], $col[1], $col[2])) }
    }
}
Save-Png $rune (Join-Path $dirS 'friendly\blast-rune-zone.png')
$made['sprites/friendly/blast-rune-zone.png'] = $rune
$sprites += [ordered]@{ id = 'friendly-blast-rune'; file = 'sprites/friendly/blast-rune-zone.png'; faction = 'friendly'; band = 5
    canvas_px = @(96, 96); frames = 1; hitbox_diameter_px = 96; covers_hitbox = $false; oriented = $false
    suggested_pattern_ids = @(-2); role = 'Blast Rune 1.5-tile zone (§3.6)' }

Write-Host 'sprites written'

# ================================================================ previews ===

$DUSK = [System.Drawing.Color]::FromArgb(255, 67, 112, 106)
$WINT = [System.Drawing.Color]::FromArgb(255, 148, 189, 159)

function Draw-Grid {
    param([string]$path)
    $hueNames = @($HUEWHEEL.Keys)
    $cell = 88; $rowH = 104; $gutter = 96
    $cols = $hueNames.Count
    # rows per panel: d13 and d8 across all hues x 4 tones, size ladder, friendly+neutrals
    $panelH = 10 * $rowH + 56
    $W = $gutter + $cell * $cols + 12
    $sheet = New-Bmp $W ($panelH * 2)
    $g = [System.Drawing.Graphics]::FromImage($sheet)
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::SingleBitPerPixelGridFit
    $font = [System.Drawing.Font]::new('Consolas', 8)
    $panels = @(@($DUSK, [System.Drawing.Brushes]::White, 'dusk'), @($WINT, [System.Drawing.Brushes]::Black, 'winter'))
    for ($p = 0; $p -lt 2; $p++) {
        $oyP = $p * $panelH
        $bg = [System.Drawing.SolidBrush]::new($panels[$p][0])
        $g.FillRectangle($bg, 0, $oyP, $W, $panelH); $bg.Dispose()
        $g.DrawString(('wildshot-projectiles-sphere-v0 — 24-hue wheel x 4 tones + neutral ramp, 4x on ' + $panels[$p][2] + ' ground'), $font, $panels[$p][1], 8, $oyP + 6)
        for ($ci = 0; $ci -lt $cols; $ci++) {
            $g.DrawString($hueNames[$ci], $font, $panels[$p][1], $gutter + $ci * $cell + 8, $oyP + 24)
        }
        $toneRows = @(
            @('base d13', '', 13), @('pastel d13', '-pastel', 13), @('deep d13', '-deep', 13), @('dark d13', '-dark', 13),
            @('base d8', '', 8), @('pastel d8', '-pastel', 8), @('deep d8', '-deep', 8), @('dark d8', '-dark', 8)
        )
        for ($ti = 0; $ti -lt $toneRows.Count; $ti++) {
            $oyR = $oyP + 40 + $ti * $rowH
            $g.DrawString([string]$toneRows[$ti][0], $font, $panels[$p][1], 8, $oyR + 38)
            $rowDia = [int]$toneRows[$ti][2]
            for ($ci = 0; $ci -lt $cols; $ci++) {
                $up = Scale-Nearest $made[("sprites/hostile/orb-d$rowDia-" + $hueNames[$ci] + $toneRows[$ti][1] + ".png")] 4
                $ox = $gutter + $ci * $cell + [int](($cell - $up.Width) / 2)
                $g.DrawImage($up, $ox, $oyR + [int](($rowH - $up.Height) / 2), $up.Width, $up.Height)
                $up.Dispose()
            }
        }
        # size ladder: full 7-size run for three sample hues
        $oyR = $oyP + 40 + 8 * $rowH
        $g.DrawString('sizes', $font, $panels[$p][1], 8, $oyR + 38)
        $ladder = @('red', 'azure', 'jade')
        $li = 0
        foreach ($lh in $ladder) {
            foreach ($Dia in $SIZES) {
                $up = Scale-Nearest $made["sprites/hostile/orb-d$Dia-$lh.png"] 4
                $ox = $gutter + $li * $cell + [int](($cell - $up.Width) / 2)
                $g.DrawImage($up, $ox, $oyR + [int](($rowH - $up.Height) / 2), $up.Width, $up.Height)
                $up.Dispose(); $li++
            }
            $li++  # gap column between hues
        }
        # friendly + neutral ramp
        $oyR = $oyP + 40 + 9 * $rowH
        $g.DrawString('friendly + neutral ramp', $font, $panels[$p][1], 8, $oyR + 38)
        $fr = @(
            @('sprites/friendly/bolt.png', 4), @('sprites/friendly/pellet.png', 4), @('sprites/friendly/wheel-ring.png', 4), @('sprites/friendly/nova-ring.png', 2),
            @('sprites/hostile/orb-d13-white.png', 4), @('sprites/hostile/orb-d13-gray.png', 4), @('sprites/hostile/orb-d13-slate.png', 4),
            @('sprites/hostile/orb-d13-charcoal.png', 4), @('sprites/hostile/orb-d13-black.png', 4), @('sprites/hostile/orb-d13-onyx.png', 4))
        for ($ci = 0; $ci -lt $fr.Count; $ci++) {
            $up = Scale-Nearest $made[[string]$fr[$ci][0]] ([int]$fr[$ci][1])
            $ox = $gutter + $ci * $cell + [int](($cell - $up.Width) / 2)
            $g.DrawImage($up, $ox, $oyR + [int](($rowH - $up.Height) / 2), $up.Width, $up.Height)
            $up.Dispose()
        }
    }
    $g.Dispose()
    Save-Png $sheet $path
    Write-Host "wrote $path"
    $sheet.Dispose()
}
Draw-Grid (Join-Path $PackDir 'preview\lineup-4x.png')

function Draw-Zones {
    param([string]$path)
    $W = 4 * 212 + 16; $H = 262
    $sheet = New-Bmp $W $H
    $g = [System.Drawing.Graphics]::FromImage($sheet)
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::SingleBitPerPixelGridFit
    $font = [System.Drawing.Font]::new('Consolas', 10)
    $bg = [System.Drawing.SolidBrush]::new($DUSK)
    $g.FillRectangle($bg, 0, 0, $W, $H); $bg.Dispose()
    $g.DrawString('zones + arm progress at 2x on dusk ground', $font, [System.Drawing.Brushes]::White, 8, 6)
    $frames = @(-1, 2, 6, -2)
    for ($i = 0; $i -lt 4; $i++) {
        $tile = New-Bmp 96 96
        $tg = [System.Drawing.Graphics]::FromImage($tile)
        if ($frames[$i] -eq -2) { $tg.DrawImage($made['sprites/friendly/blast-rune-zone.png'], 0, 0, 96, 96) }
        else {
            $tg.DrawImage($made['sprites/hostile/hazard-zone.png'], 0, 0, 96, 96)
            if ($frames[$i] -ge 0) {
                $srcRect = [System.Drawing.Rectangle]::new(96 * $frames[$i], 0, 96, 96)
                $tg.DrawImage($made['sprites/hostile/hazard-arm-strip8.png'], [System.Drawing.Rectangle]::new(0, 0, 96, 96), $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
            }
        }
        $tg.Dispose()
        $t2 = Scale-Nearest $tile 2
        $g.DrawImage($t2, 12 + $i * 212, 34, $t2.Width, $t2.Height)
        $lbl = @('hazard zone', 'arming 3/8', 'arming 7/8', 'blast rune (friendly)')[$i]
        $g.DrawString($lbl, $font, [System.Drawing.Brushes]::White, 12 + $i * 212 + 40, 232)
        $tile.Dispose(); $t2.Dispose()
    }
    $g.Dispose()
    Save-Png $sheet $path
    Write-Host "wrote $path"
    $sheet.Dispose()
}
Draw-Zones (Join-Path $PackDir 'preview\zones-2x.png')

# ================================================================ manifest ===

$manifest = [ordered]@{
    pack           = 'wildshot-projectiles-sphere'
    version        = 'v0'
    generated_by   = 'tools/generate.ps1 (deterministic; no RNG)'
    px_per_tile    = 32
    scale          = 'native 1x'
    filtering      = 'nearest'
    philosophy     = 'shaded orbs at color-system scale: 24-hue wheel (deterministic HSV, per-region value tuning) x 4 tones (pastel/base/deep/dark) + a 6-step neutral ramp (white/gray/slate/charcoal/black/onyx) = 102 color identities x 7 sizes (d6/d8/d10 small tier + d12/d13/d16/d20) = 714 hostile orbs. Each orb: one color identity, NW highlight, deepening edge, near-black outline that thins with radius (never pure #000). Friendly is exclusively desaturated silver. Round everything: no rotation needed, friendly works with the existing view stretch — the most drop-in candidate.'
    color_system   = [ordered]@{
        wheel = @($HUEWHEEL.Keys)
        tones = @('base', 'pastel (suffix -pastel)', 'deep (suffix -deep)', 'dark (suffix -dark)')
        neutrals = @('white', 'gray', 'slate', 'charcoal', 'black', 'onyx')
        note = 'hue-per-family is the designer''s pick; pastels sit closest to friendly silver — prefer base/deep for primary threats. -dark and the charcoal/black/onyx end run close to ground value on dusk — they read via highlight + outline silhouette, best used on pale grounds or for heavy menace accents; judge in the swarm before assigning them to primary threats.'
    }
    phase_a_mapping = [ordered]@{
        'pattern 1 (Longbolt)'    = 'friendly/bolt.png'
        'pattern 2 (Scattercast)' = 'friendly/pellet.png'
        'pattern 3 (Wheelblade)'  = 'friendly/wheel-ring.png'
        'pattern 10 (Husk aimed)' = 'hostile/orb-d12-red.png (suggested — designer picks per-family hues)'
        'Leadshot intercept'      = 'hostile/orb-d12-violet.png (suggested)'
        'Fanmaw fan'              = 'hostile/orb-d13-orange.png (suggested)'
        'Ringer radial'           = 'hostile/orb-d13-magenta.png (suggested)'
        'Yard Warden'             = 'hostile/orb-d16-amber.png / orb-d20-amber.png (suggested)'
        'Blightcaster / hazards'  = 'hostile/hazard-zone.png + hazard-arm-strip8.png'
        'Nova Burst'              = 'friendly/nova-ring.png'
        'Blast Rune'              = 'friendly/blast-rune-zone.png (+ arm strip modulated cool)'
    }
    contract       = [ordered]@{
        hostile_signature = 'PROPOSED (designer-directed): saturated shaded body + near-black outline on every hostile shot; friendly is exclusively desaturated silver. The M6 Law-3 hostile-vs-friendly stress test at density is the arbiter; recorded fallback: own-hue bright outlines (one generator edit). CORE-50 holds because size + volley pattern also separate families. Adopting this pack amends the §2.6 placeholder line in the planning repo.'
        hitbox_mapping    = 'hitbox_diameter_px maps to the sim collision diameter. Hostile orbs are full-bleed (outline on the boundary; covers_hitbox asserted). Friendly art is smaller than its canvas/hitbox by design.'
        layering          = '§2.5 bands: 5 friendly, 7 hostile shots, 8 hazard rim/arm; hostile channels clamp fully visible at every density/opacity setting.'
    }
    sprites        = $sprites
}
$json = $manifest | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText((Join-Path $PackDir 'manifest.json'), $json, [System.Text.UTF8Encoding]::new($false))
Write-Host "wrote $(Join-Path $PackDir 'manifest.json')"
Write-Host "DONE: $($sprites.Count) manifest rows."
