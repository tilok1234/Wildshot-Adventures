extends Node
## Armed-mode GIF recorder (docs/12 §2.10/§2.12): press gif_dump (default
## G) to START capturing, press again to STOP and dump the ring (last
## ~10 s, 30 fps, base res) as a PNG sequence for tools/gif.ps1.
##
## Why armed instead of always-on: viewport readback measured 32 ms per
## capture on the dev machine (GPU→CPU sync stall) — an always-on ring
## halves the frame rate of the whole game. While armed the game still
## pays that cost (fps visibly dips during capture); that is the accepted
## price for devlog moments. Async RenderingDevice readback is the
## recorded improvement path (ledger #7). Purely view-side; headless
## captures nothing.

const FPS := 30
const SECONDS := 10
const CAPACITY := FPS * SECONDS

var armed := false

var _ring: Array[Image] = []
var _head := 0
var _count := 0
var _every_other := false


func _ready() -> void:
	_ring.resize(CAPACITY)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("gif_dump"):
		armed = not armed
		if armed:
			_head = 0
			_count = 0
			print("gif_recorder: recording (press again to stop + dump)")
		else:
			_dump()
	if not armed:
		return
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
