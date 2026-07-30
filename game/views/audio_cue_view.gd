extends Node
## Law-7 audio cue emitter (docs/12 M6, CORE-51 Law 7, CORE-50):
## consumes the driver's per-frame event relay and plays the cue-map
## class for each KEY THREAT — the eyes-closed second channel — plus
## the attack-release feedback classes (M8, designer-ruled 2026-07-30:
## player_fire / enemy_fire on ATTACK_STARTED). One AudioStreamPlayer
## per class, routed to the class's bus (KeyThreats is separate from
## Sfx so the threat channel survives any mix). An entry may carry a
## `wavs` ARRAY — variations rotate round-robin (deterministic
## counter, no RNG) — plus optional volume_db and gap_ticks (per-class
## retrigger gate). Presentation-only: reads events, never the sim;
## headless runs instantiate it harmlessly (no device, no output).

## A KeyThreats-bus cue actually played (post retrigger gate) — the
## music duck rides this (M8, designer-ruled 2026-07-30).
signal key_threat_cue

const SimEvents := preload("res://sim/events.gd")
const ActorState := preload("res://sim/actor_state.gd")

## Default min ticks between retriggers of one class (~130 ms at 60
## tps). Fire classes override via gap_ticks — Longbolt's cadence cap
## is 6.5 ticks, so player_fire must gate BELOW that to sound every
## shot while still coalescing a multi-projectile volley to one cue.
const CLASS_GAP_TICKS := 8

var driver: Node = null
var world: RefCounted = null
## data/audio_cue_map.tres (class -> {wav|wavs, bus, volume_db?, gap_ticks?}).
var cue_map: Resource = null
## data/projectile_map.tres — its `zones` keys identify which telegraph
## pattern ids are hazard PLACEMENTS (cast cue) vs volley windups.
var pattern_map: Resource = null

var _players: Dictionary = {}
var _streams: Dictionary = {}
var _gaps: Dictionary = {}
var _rr: Dictionary = {}
var _last_tick: Dictionary = {}


func _ready() -> void:
	if cue_map == null:
		return
	for cls: String in cue_map.cues:
		var entry: Dictionary = cue_map.cues[cls]
		var paths: Array = entry.wavs if entry.has("wavs") else [entry.wav]
		var streams: Array[AudioStream] = []
		for path: Variant in paths:
			var stream: AudioStream = load(String(path))
			if stream == null:
				push_error("audio_cue_view: missing cue wav for '%s': %s" % [cls, String(path)])
				continue
			streams.append(stream)
		if streams.is_empty():
			continue
		var p := AudioStreamPlayer.new()
		p.stream = streams[0]
		p.volume_db = float(entry.get("volume_db", 0.0))
		var bus := String(entry.bus)
		if AudioServer.get_bus_index(bus) >= 0:
			p.bus = bus
		add_child(p)
		_players[cls] = p
		_streams[cls] = streams
		_gaps[cls] = int(entry.get("gap_ticks", CLASS_GAP_TICKS))
		_rr[cls] = 0


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
			SimEvents.Type.ATTACK_STARTED:
				# Release feedback: the player's shot vs an enemy volley
				# leaving the barrel (the windup cue is the telegraph).
				if ev.has("player"):
					_play("player_fire")
				else:
					_play("enemy_fire")
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
	if t - int(_last_tick.get(cls, -1000)) < int(_gaps.get(cls, CLASS_GAP_TICKS)):
		return
	_last_tick[cls] = t
	var streams: Array[AudioStream] = _streams[cls]
	if streams.size() > 1:
		var i := int(_rr[cls])
		p.stream = streams[i]
		_rr[cls] = (i + 1) % streams.size()
	p.play()
	if String(p.bus) == "KeyThreats":
		key_threat_cue.emit()
