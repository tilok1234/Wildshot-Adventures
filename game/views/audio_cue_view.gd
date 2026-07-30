extends Node
## Law-7 audio cue emitter (docs/12 M6, CORE-51 Law 7, CORE-50):
## consumes the driver's per-frame event relay and plays the cue-map
## class for each KEY THREAT — the eyes-closed second channel. One
## AudioStreamPlayer per class, routed to the class's bus (KeyThreats
## is separate from Sfx so the threat channel survives any mix).
## Per-class rate limiting keeps stress density from machine-gunning a
## cue into noise. Presentation-only: reads events, never the sim;
## headless runs instantiate it harmlessly (no device, no output).

## A KeyThreats-bus cue actually played (post retrigger gate) — the
## music duck rides this (M8, designer-ruled 2026-07-30).
signal key_threat_cue

const SimEvents := preload("res://sim/events.gd")
const ActorState := preload("res://sim/actor_state.gd")

## Min ticks between retriggers of one class (~130 ms at 60 tps).
const CLASS_GAP_TICKS := 8

var driver: Node = null
var world: RefCounted = null
## data/audio_cue_map.tres (class -> {wav, bus}).
var cue_map: Resource = null
## data/projectile_map.tres — its `zones` keys identify which telegraph
## pattern ids are hazard PLACEMENTS (cast cue) vs volley windups.
var pattern_map: Resource = null

var _players: Dictionary = {}
var _last_tick: Dictionary = {}


func _ready() -> void:
	if cue_map == null:
		return
	for cls: String in cue_map.cues:
		var entry: Dictionary = cue_map.cues[cls]
		var stream: AudioStream = load(String(entry.wav))
		if stream == null:
			push_error("audio_cue_view: missing cue wav for '%s'" % cls)
			continue
		var p := AudioStreamPlayer.new()
		p.stream = stream
		var bus := String(entry.bus)
		if AudioServer.get_bus_index(bus) >= 0:
			p.bus = bus
		add_child(p)
		_players[cls] = p


func _process(_delta: float) -> void:
	if driver == null or world == null or _players.is_empty():
		return
	var player_ids := {}
	for p: RefCounted in world.players:
		player_ids[p.id] = true
	for ev: Dictionary in driver.frame_events:
		match int(ev.type):
			SimEvents.Type.TELEGRAPH_STARTED:
				if int(ev.get("faction", -1)) != ActorState.FACTION_HOSTILE:
					continue
				var pid := int(ev.get("pattern", 0))
				if pattern_map != null and pattern_map.zones.has(pid):
					_play("hazard_cast")
				elif cue_map.melee_patterns.has(pid):
					_play("telegraph_melee")
				else:
					_play("telegraph_ranged")
			SimEvents.Type.HAZARD_ARMED:
				if int(ev.get("faction", -1)) == ActorState.FACTION_HOSTILE:
					_play("hazard_armed")
			SimEvents.Type.PHASE_CHANGED:
				_play("phase_change")
			SimEvents.Type.DAMAGE_APPLIED:
				if player_ids.has(int(ev.target)):
					_play("player_hit")
			SimEvents.Type.ENTITY_KILLED:
				if bool(ev.get("player", false)):
					_play("player_death")


func _play(cls: String) -> void:
	var p: AudioStreamPlayer = _players.get(cls)
	if p == null:
		return
	var t: int = world.tick
	if t - int(_last_tick.get(cls, -1000)) < CLASS_GAP_TICKS:
		return
	_last_tick[cls] = t
	p.play()
	if String(p.bus) == "KeyThreats":
		key_threat_cue.emit()
