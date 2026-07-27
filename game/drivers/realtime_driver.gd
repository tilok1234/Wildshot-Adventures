extends Node
## RealtimeDriver (docs/12 §2.1): steps the sim from wall time with a fixed
## accumulator in _process — never _physics_process. Catch-up is capped at 5
## ticks per render frame; any backlog beyond that is dropped (slew) and
## logged. Pause = this driver stops stepping: nothing gameplay exists
## outside ticks, so full freeze with zero queued actions is structural
## (CORE-31), and pause is always legal in single-player (CORE-50).

signal pause_changed(paused: bool)

const SimWorld := preload("res://sim/sim_world.gd")
const HumanSampler := preload("res://input/human_sampler.gd")

const MAX_TICKS_PER_FRAME := 5

var world: SimWorld = null
var sampler: HumanSampler = null
## Returns the mouse position in world TILE coordinates; supplied by the
## scene (view-side transform knowledge stays out of input and sim).
var mouse_tile_provider: Callable = Callable()
var paused: bool = false
var slew_count: int = 0
var _accumulator: float = 0.0


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause_toggle"):
		paused = not paused
		pause_changed.emit(paused)
	if paused or world == null:
		return
	_accumulator += delta
	var ticks := 0
	while _accumulator >= SimWorld.DT and ticks < MAX_TICKS_PER_FRAME:
		world.step([_sample_frame()])
		_accumulator -= SimWorld.DT
		ticks += 1
	if _accumulator >= SimWorld.DT:
		var dropped := int(_accumulator / SimWorld.DT)
		_accumulator -= dropped * SimWorld.DT
		slew_count += 1
		push_warning(
			"RealtimeDriver: dropped %d ticks after catch-up cap (slew #%d)" % [dropped, slew_count]
		)


## Interpolation weight for views: how far into the next tick real time has
## progressed (0..1). Task of §2.9's prev/curr toggle.
func alpha() -> float:
	return clampf(_accumulator / SimWorld.DT, 0.0, 1.0)


func _sample_frame() -> RefCounted:
	if sampler == null or world.players.is_empty():
		return null
	var mouse_tile: Vector2 = (
		mouse_tile_provider.call() if mouse_tile_provider.is_valid() else Vector2.ZERO
	)
	return sampler.sample(mouse_tile, world.players[0].pos)
