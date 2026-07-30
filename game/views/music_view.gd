extends Node
## Music playback (M8, designer-ruled 2026-07-30): plays the
## data/music_playlist.tres tracks as a queue in listed order, looping
## the whole queue — per-area assignment later is a different data rule
## on the same machinery. Routed to the Music bus (own CORE-50 volume
## row). Duck-under-threats (same ruling): every KeyThreats cue the
## audio_cue_view actually plays pushes music down by DUCK_DB, fast
## attack / slow release — Law 7's threat channel sits on top of the
## mix by construction. The duck rides the PLAYER's volume_db so it
## composes with (never fights) the user's Music bus volume row.
## View-only: wall-clock timing is legal here; the sim never sees any
## of this. Empty playlist = silent no-op (the state until the
## Resonance Forge pack lands).

const DUCK_DB := -9.0
## How long after the last threat cue the duck holds before releasing.
const HOLD_MS := 350
## dB per second toward the duck floor (attack) and back out (release).
const ATTACK_RATE := 120.0
const RELEASE_RATE := 14.0

## data/music_playlist.tres (tracks: Array[String] of stream paths).
var playlist: Resource = null
## The audio_cue_view whose key_threat_cue signal drives the duck.
var cue_view: Node = null

var _player: AudioStreamPlayer = null
var _streams: Array[AudioStream] = []
var _idx := -1
var _duck_until_ms := -1


func _ready() -> void:
	if playlist != null:
		for path: String in playlist.tracks:
			var stream: AudioStream = load(path)
			if stream == null:
				push_error("music_view: missing track '%s'" % path)
				continue
			_streams.append(stream)
	if _streams.is_empty():
		set_process(false)
		return
	_player = AudioStreamPlayer.new()
	if AudioServer.get_bus_index("Music") >= 0:
		_player.bus = "Music"
	_player.finished.connect(_next)
	add_child(_player)
	if cue_view != null:
		cue_view.connect("key_threat_cue", _on_threat_cue)
	_next()


func _next() -> void:
	_idx = (_idx + 1) % _streams.size()
	_player.stream = _streams[_idx]
	_player.play()


func _on_threat_cue() -> void:
	_duck_until_ms = Time.get_ticks_msec() + HOLD_MS


func _process(delta: float) -> void:
	var target := DUCK_DB if Time.get_ticks_msec() < _duck_until_ms else 0.0
	var rate := ATTACK_RATE if target < _player.volume_db else RELEASE_RATE
	_player.volume_db = move_toward(_player.volume_db, target, rate * delta)
