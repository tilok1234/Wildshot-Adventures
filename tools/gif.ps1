# tools/gif.ps1 — PNG sequence -> GIF via ffmpeg (docs/12 §2.10, §2.12).
# The back half of the F9 ring-buffer pipeline; the weekly devlog GIF
# deliverable runs through this (PIPE-testers, weekly cadence from M3).
#
# Usage: tools/gif.ps1 -FramesDir <dump dir printed by F9> [-OutGif out.gif]
#        [-Fps 30] [-NoScale]
# Default output upscales 2x nearest-neighbor so 640x360 pixels stay crisp
# on the devlog.

param(
    [Parameter(Mandatory = $true)][string]$FramesDir,
    [string]$OutGif = "",
    [int]$Fps = 30,
    [switch]$NoScale
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "ffmpeg not found on PATH. Install it (winget install ffmpeg) and retry."
    exit 1
}
if (-not (Test-Path (Join-Path $FramesDir "frame_0000.png"))) {
    Write-Error "No frame_0000.png in '$FramesDir' — pass the dump dir the F9 console line printed."
    exit 1
}
if ($OutGif -eq "") {
    $stamp = Get-Date -Format "yyyy-MM-dd_HHmm"
    $OutGif = Join-Path (Split-Path $FramesDir -Parent) "wildshot_$stamp.gif"
}

$input_pattern = Join-Path $FramesDir "frame_%04d.png"
$palette = Join-Path $FramesDir "palette.png"
$scale = if ($NoScale) { "scale=iw:ih" } else { "scale=iw*2:ih*2:flags=neighbor" }

# Two-pass palette for quality at GIF's 256 colors.
ffmpeg -hide_banner -loglevel error -y -framerate $Fps -i $input_pattern `
    -vf "$scale,palettegen=stats_mode=diff" $palette
ffmpeg -hide_banner -loglevel error -y -framerate $Fps -i $input_pattern -i $palette `
    -lavfi "$scale,paletteuse=dither=bayer:bayer_scale=4" $OutGif

Remove-Item $palette -ErrorAction SilentlyContinue
$size_mb = [math]::Round((Get-Item $OutGif).Length / 1MB, 2)
Write-Output "GIF written: $OutGif ($size_mb MB)"
