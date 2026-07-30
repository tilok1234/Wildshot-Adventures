extends Resource
## Music playlist (M8, designer-ruled 2026-07-30): stream paths played
## as a queue in listed order, looping the whole queue (music_view).
## The Resonance Forge intake fills this — tracks land under
## audio/music/ (assets/ is .gdignore'd raw-drop land; importers copy
## OUT of it), then this file lists them. Zero code per track.

@export var tracks: Array[String] = []
