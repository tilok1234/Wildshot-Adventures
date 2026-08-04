extends Node
## START-TO-FINISH GIF recorder (2026-08-01, the designer's want,
## stated three times: "the whole recording from start to finish"):
## press gif_dump (G) to START, press again to STOP. Frames STREAM to
## the dump dir as they are captured — no ring, no trailing-window
## truncation, no length cap (disk-bound: ~6 MB/s of PNGs at 30 fps
## 640x360) — and the dump is complete the instant recording stops,
## so nothing downstream can race a flush. The pre-S0 ring design
## (last-10-s trailing window) is RETIRED: it silently threw away the
## start of every recording longer than 10 s.
##
## Armed cost (unchanged in kind, ledger #7): the 32 ms viewport
## readback stalls the game while REC is on — footage inherits that
## slowdown; async RenderingDevice readback stays the recorded
## improvement path. The per-frame PNG encode (~2-5 ms at 640x360)
## rides the same accepted dip. Purely view-side; headless captures
## nothing.

const FPS := 30

var armed := false

var _dir := ""
var _index := 0
var _every_other := false


## sl-0206: main polls gif_dump (behind the input-swallow guard) and
## calls this — the bare Input poll that used to live in _process
## leaked the G key into console typing. Pollers live where the
## guard lives.
func toggle_recording() -> void:
	armed = not armed
	if armed:
		_dir = "user://gif_frames/dump_%d" % Time.get_ticks_msec()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
		_index = 0
		print("gif_recorder: recording START-TO-FINISH (press again to stop)")
	else:
		var os_path := ProjectSettings.globalize_path(_dir)
		print("gif_recorder: %d frames -> %s" % [_index, os_path])
		print('gif_recorder: convert with  tools/gif.ps1 -FramesDir "%s"' % os_path)


func _process(_delta: float) -> void:
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
	img.save_png("%s/frame_%04d.png" % [_dir, _index])
	_index += 1
