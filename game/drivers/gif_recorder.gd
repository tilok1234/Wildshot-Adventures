extends Node
## GIF ring buffer (docs/12 §2.10/§2.12): keeps the last ~10 s of frames
## (half-rate, 30 fps at base res) in memory; the gif_dump action
## (default G) dumps them as a PNG sequence to user://gif_frames/ for
## tools/gif.ps1 (ffmpeg) to convert — the weekly devlog GIF pipeline
## (PIPE-testers; the PNG path is ledger entry #7). Purely view-side;
## headless runs capture nothing.

const FPS := 30
const SECONDS := 10
const CAPACITY := FPS * SECONDS

var _ring: Array[Image] = []
var _head := 0
var _count := 0
var _every_other := false


func _ready() -> void:
	_ring.resize(CAPACITY)


func _process(_delta: float) -> void:
	# Half-rate capture: every second rendered frame at 60 fps ≈ 30 fps.
	_every_other = not _every_other
	if _every_other:
		return
	var tex := get_viewport().get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img == null or img.is_empty():
		return  # headless — nothing to capture
	_ring[_head] = img
	_head = (_head + 1) % CAPACITY
	_count = mini(_count + 1, CAPACITY)

	if Input.is_action_just_pressed("gif_dump"):
		_dump()


func _dump() -> void:
	if _count == 0:
		print("gif_recorder: ring empty, nothing to dump")
		return
	var dir := "user://gif_frames/dump_%d" % Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var start := (_head - _count + CAPACITY) % CAPACITY
	for i in _count:
		var img := _ring[(start + i) % CAPACITY]
		img.save_png("%s/frame_%04d.png" % [dir, i])
	var os_path := ProjectSettings.globalize_path(dir)
	print("gif_recorder: %d frames -> %s" % [_count, os_path])
	print('gif_recorder: convert with  tools/gif.ps1 -FramesDir "%s"' % os_path)
