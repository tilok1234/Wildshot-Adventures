extends AnimatedSprite2D
## View-layer actor renderer (docs/12 §2.14): plays Sprite Forge animation
## sets for one sim actor. Facing is derived VIEW-SIDE from sim velocity —
## and from aim during attacks once the fire path lands (M3). The sim knows
## nothing about facing or frames; animation state is presentation and
## never feeds back into sim. Renders at 0.5 scale: sheets are 64 px cells
## (32 logical px × 2), so one cell spans exactly one 32 px tile on screen.
## Positions interpolate prev→curr per the §2.9 toggle and round to whole
## base-res pixels view-side only. Pause freezes the animation clock too —
## the frozen frame matches the frozen sim.

const TILE := 32.0
## The speed the walk row's fps is authored against (§3.2 baseline).
const BASELINE_SPEED := 4.0

var actor: RefCounted = null
var clock: RefCounted = null
## Set by the caller from the source library (assembler 1x = 1.0).
var render_scale := 1.0
var _facing := "down"

const RenderLayers := preload("res://game/render_layers.gd")


func _ready() -> void:
	scale = Vector2(render_scale, render_scale)
	z_index = RenderLayers.ACTORS


func _process(_delta: float) -> void:
	if actor == null:
		return
	var shown: Vector2 = actor.pos
	if clock != null and clock.interp_enabled:
		shown = actor.prev_pos.lerp(actor.pos, clock.alpha())
	position = (shown * TILE).round()

	if clock != null and clock.paused():
		if is_playing():
			pause()
		return
	# An attack one-shot holds until it finishes — locomotion never
	# stomps the swing mid-animation (enemy_actors_view triggers these).
	if String(animation).begins_with("attack-") and is_playing():
		return
	var vel: Vector2 = actor.pos - actor.prev_pos
	if vel.length_squared() > 0.000001:
		_facing = _dir_from(vel)
		_play_if_changed("walk-" + _facing)
		# Footfall rate tracks live ground speed (view-side, PROVISIONAL):
		# walk fps is authored for the 4.0 t/s baseline; scale by actual
		# tiles/s so 3.0 strolls and 5.5 sprints don't foot-slide.
		speed_scale = vel.length() * 60.0 / BASELINE_SPEED
	else:
		_play_if_changed("idle-" + _facing)
		speed_scale = 1.0


## One-shot attack read: face the aim, play the attack row; _process
## resumes idle/walk when it ends. Presentation only — never sim-fed.
func play_attack(aim: Vector2) -> void:
	if aim.length_squared() > 0.000001:
		_facing = _dir_from(aim)
	speed_scale = 1.0
	play("attack-" + _facing)


func _play_if_changed(anim: String) -> void:
	if animation != StringName(anim) or not is_playing():
		play(anim)


static func _dir_from(v: Vector2) -> String:
	if absf(v.x) >= absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"
