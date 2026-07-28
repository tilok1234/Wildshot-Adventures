extends Node
## RealtimeDriver (docs/12 §2.1): steps the sim from wall time with a fixed
## accumulator in _process — never _physics_process. Catch-up is capped at
## TWO ticks per render frame (2026-07-28 movement-bug fix: the old 5-tick
## burst advanced a third of a tile in ONE render frame after any hitch —
## felt as a micro-teleport, reported as "walking bugs out near
## structures" where render load spikes). Backlog beyond the cap is shed
## as TIME STRETCH: game time briefly runs slower than wall time instead
## of jumping — still logged (slew) so stutter stays evidenced. Pause =
## this driver stops stepping: nothing gameplay exists outside ticks, so
## full freeze with zero queued actions is structural (CORE-31), and
## pause is always legal in single-player (CORE-50).

signal pause_changed(paused: bool)

const SimWorld := preload("res://sim/sim_world.gd")
const HumanSampler := preload("res://input/human_sampler.gd")

const MAX_TICKS_PER_FRAME := 2
## A render frame longer than this is a SPIKE: logged with context to
## user://logs/spikes.jsonl and counted on the HUD, so stutter reports
## come with evidence from the session they happened in.
const SPIKE_MS := 24.0

var world: SimWorld = null
var sampler: HumanSampler = null
## Optional always-on replay recorder (§2.4): fed the exact frames the sim
## steps with. begin() it against the world before play starts.
var recorder: RefCounted = null
## Returns the mouse position in world TILE coordinates; supplied by the
## scene (view-side transform knowledge stays out of input and sim).
var mouse_tile_provider: Callable = Callable()
var paused: bool = false
## Slow motion = driver divisor (§2.1): wall time is divided before the
## accumulator, dt never changes, so slow-mo runs stay replay-valid.
var time_divisor: float = 1.0
var slew_count: int = 0
var spike_count: int = 0
var _spike_file: FileAccess = null
## Microseconds spent inside world.step() during the latest _process —
## driver-side instrumentation for the stress rig and the M4 density meter.
## Engine timing lives HERE, never in the sim (§2.1).
var frame_sim_usec: int = 0
## Sim events from ALL ticks stepped this render frame, in tick order.
## world.events only holds the latest tick (cleared per step), and catch-up
## frames step several ticks — event consumers (loggers, views, the M4
## console) read THIS, never world.events directly.
var frame_events: Array[Dictionary] = []
var _accumulator: float = 0.0


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause_toggle"):
		paused = not paused
		pause_changed.emit(paused)
	if paused or world == null:
		return
	if delta * 1000.0 > SPIKE_MS:
		_log_spike(delta)
	frame_events.clear()
	_accumulator += delta / maxf(1.0, time_divisor)
	var ticks := 0
	var t0 := Time.get_ticks_usec()
	while _accumulator >= SimWorld.DT and ticks < MAX_TICKS_PER_FRAME:
		var frames := [_sample_frame()]
		if recorder != null:
			recorder.record_frames(frames)
		world.step(frames)
		if recorder != null:
			recorder.after_step()
		frame_events.append_array(world.events)
		_accumulator -= SimWorld.DT
		ticks += 1
	frame_sim_usec = int(Time.get_ticks_usec() - t0) if ticks > 0 else 0
	if _accumulator >= SimWorld.DT:
		var shed := int(_accumulator / SimWorld.DT)
		_accumulator -= shed * SimWorld.DT
		slew_count += 1
		push_warning(
			(
				"RealtimeDriver: time-stretched %d ticks at the catch-up cap (slew #%d)"
				% [shed, slew_count]
			)
		)


## Interpolation weight for views: how far into the next tick real time has
## progressed (0..1). Task of §2.9's prev/curr toggle.
func alpha() -> float:
	return clampf(_accumulator / SimWorld.DT, 0.0, 1.0)


## One JSONL line per spike: how long the frame was, what the sim cost
## LAST frame (a spike caused by sim would show it), and what was live.
## The data that turns "it stutters" into a diagnosis.
func _log_spike(delta: float) -> void:
	spike_count += 1
	if _spike_file == null:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://logs"))
		_spike_file = FileAccess.open("user://logs/spikes.jsonl", FileAccess.WRITE)
		if _spike_file == null:
			return
	(
		_spike_file
		. store_line(
			(
				JSON
				. stringify(
					{
						"wall_ms": snappedf(delta * 1000.0, 0.1),
						"tick": world.tick,
						"prev_sim_ms": snappedf(frame_sim_usec / 1000.0, 0.01),
						"live": world.projectiles.live_count,
						"events": frame_events.size(),
						"uptime_s": snappedf(Time.get_ticks_msec() / 1000.0, 0.1),
					}
				)
			)
		)
	)
	_spike_file.flush()


func _sample_frame() -> RefCounted:
	if sampler == null or world.players.is_empty():
		return null
	var mouse_tile: Vector2 = (
		mouse_tile_provider.call() if mouse_tile_provider.is_valid() else Vector2.ZERO
	)
	return sampler.sample(mouse_tile, world.players[0].pos)
