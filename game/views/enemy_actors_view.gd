extends Node2D
## Real-enemy renderer (M5): one AnimatedActor per live EnemyState with a
## def, sheet-mapped via data/actor_sheet_map.tres role "enemy_<def id>".
## Removal on death is presentation cleanup only — the sim's death sweep
## is the authority, and the kill flash covers the visual beat until the
## pack's death rows land (alias contract, docs/14). On ATTACK_STARTED
## the sprite faces its aim and plays the attack row, so shots visibly
## leave the way the archer points (Law 8 legibility). General
## presentation only: no selection, no focus, no state that could feed
## aiming or damage (CORE-35).

const AnimatedActor := preload("res://game/views/animated_actor.gd")
const SimEvents := preload("res://sim/events.gd")

var world: RefCounted = null
var clock: RefCounted = null
var driver: Node = null
## AssemblerLibrary instance shared with the player actor.
var lib: RefCounted = null
var sheet_map: Resource = null

var _views: Dictionary = {}
var _frames_by_def: Dictionary = {}


func _process(_delta: float) -> void:
	if world == null or lib == null:
		return
	var seen := {}
	for e: RefCounted in world.enemies:
		var def_index: int = e.def_index
		if def_index < 0:
			continue
		seen[e.id] = true
		if _views.has(e.id):
			continue
		var frames := _frames_for(def_index)
		if frames == null:
			continue
		var av := AnimatedActor.new()
		av.sprite_frames = frames
		av.actor = e
		av.clock = clock
		av.render_scale = lib.render_scale()
		av.play("idle-down")
		add_child(av)
		_views[e.id] = av
	for id: int in _views.keys():
		if not seen.has(id):
			_views[id].queue_free()
			_views.erase(id)
	if driver != null:
		for ev: Dictionary in driver.frame_events:
			if int(ev.type) == SimEvents.Type.ATTACK_STARTED and ev.has("enemy"):
				var av: Node = _views.get(int(ev.enemy))
				if av != null:
					av.play_attack(ev.aim)


## SpriteFrames per def, built once. A missing mapping errors ONCE and
## caches null — the sim enemy still runs (hitbox view shows it); the
## error names the role to add to actor_sheet_map.tres.
func _frames_for(def_index: int) -> SpriteFrames:
	if _frames_by_def.has(def_index):
		return _frames_by_def[def_index]
	var def: Resource = world.enemy_defs[def_index]
	var role := "enemy_" + String(def.id)
	var actor_id := String(sheet_map.map.get(role, ""))
	var frames: SpriteFrames = null
	if actor_id.is_empty() or not lib.has_actor(actor_id):
		push_error(
			(
				"enemy_actors_view: no imported sheet for role '%s' (map it in actor_sheet_map.tres)"
				% role
			)
		)
	else:
		frames = lib.build_sprite_frames(actor_id)
	_frames_by_def[def_index] = frames
	return frames
