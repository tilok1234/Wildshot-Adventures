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
## Optional boss library (Loop v1): same class, 48 px manifest. Tried
## when the primary library lacks the mapped actor id; render scale
## comes from whichever library served the sheet.
var lib_boss: RefCounted = null
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
		var got := _frames_for(def_index, int(e.id))
		if got.frames == null:
			continue
		var av := AnimatedActor.new()
		av.sprite_frames = got.frames
		av.actor = e
		av.clock = clock
		av.render_scale = float(got.scale)
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


## {frames, scale} per (def, variant), built lazily. S1 (sl-0104):
## roles with a `variants` list rotate their family's FULL catalog —
## the variant is picked PER ENEMY from its sim id (deterministic,
## cosmetic only; the split assigns identity, never behaviour). A
## missing mapping errors ONCE and caches null — the sim enemy still
## runs (hitbox view shows it); the error names the role to add to
## actor_sheet_map.tres. The boss library is consulted when the
## primary lacks the actor id (Loop v1).
func _frames_for(def_index: int, enemy_id: int) -> Dictionary:
	var def: Resource = world.enemy_defs[def_index]
	var role := "enemy_" + String(def.id)
	var ids: Array = sheet_map.variants.get(role, [])
	if ids.is_empty():
		ids = [sheet_map.map.get(role, "")]
	var variant := enemy_id % ids.size()
	var cache: Dictionary = _frames_by_def.get_or_add(def_index, {})
	if cache.has(variant):
		return cache[variant]
	var actor_id := String(ids[variant])
	var got := {"frames": null, "scale": 1.0}
	if not actor_id.is_empty() and lib.has_actor(actor_id):
		got.frames = lib.build_sprite_frames(actor_id)
		got.scale = lib.render_scale()
	elif not actor_id.is_empty() and lib_boss != null and lib_boss.has_actor(actor_id):
		got.frames = lib_boss.build_sprite_frames(actor_id)
		got.scale = lib_boss.render_scale()
	else:
		push_error(
			(
				"enemy_actors_view: no imported sheet for role '%s' (map it in actor_sheet_map.tres)"
				% role
			)
		)
	# sl-0122: per-def boss render scale [T] — view-only (the sim
	# radius/hurtbox never moves); lands in the per-(def,variant) cache.
	got.scale = float(got.scale) * float(sheet_map.scales.get(role, 1.0))
	cache[variant] = got
	return got
