extends SceneTree
## sl-0208 diagnostic probe (ungated; the measurement behind the
## smoke's melee-whiff re-pin): slash hits + death tick for a lone
## rusher vs a STANDING player at the old 0.35 body and the new
## halved hurtbox, same staging. Recorded at the seam:
## 0.350 -> hits=13 volleys=5 death t307; 0.175 -> hits=4 volleys=63
## alive at t2400. The designer's melee word owns what happens next.
##
## Run: godot --headless --path . --script tests/determinism/rusher_lethality_probe.gd

const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const SimWorld := preload("res://sim/sim_world.gd")
const SimEvents := preload("res://sim/events.gd")


func _build_bitgrid() -> RefCounted:
	var grid := Bitgrid.new()
	grid.setup(32, 32)
	for x in 32:
		grid.set_solid(x, 0)
		grid.set_solid(x, 31)
	for y in 32:
		grid.set_solid(0, y)
		grid.set_solid(31, y)
	return grid


func _run(radius_override: float) -> Dictionary:
	var rdef: Resource = load("res://data/enemies/rusher.tres")
	var world := SimWorld.new()
	world.setup(21, _build_bitgrid())
	world.set_enemy_defs([rdef])
	var player := world.add_player(Vector2(24.0, 16.0))
	player.radius = radius_override
	world.add_enemy(0, Vector2(16.0, 16.0))
	var hits := 0
	var death_tick := -1
	var volleys := 0
	for t in 2400:
		world.step([null])
		for ev: Dictionary in world.events:
			match int(ev.type):
				SimEvents.Type.ATTACK_STARTED:
					volleys += 1
				SimEvents.Type.DAMAGE_APPLIED:
					if int(ev.target) == player.id:
						hits += 1
				SimEvents.Type.ENTITY_KILLED:
					if bool(ev.get("player", false)) and death_tick < 0:
						death_tick = int(ev.tick)
		if death_tick >= 0:
			break
	return {"hits": hits, "death": death_tick, "volleys": volleys}


func _init() -> void:
	var old := _run(0.35)
	var new := _run(0.175)
	print("old 0.350: hits=%d volleys=%d death_tick=%d" % [old.hits, old.volleys, old.death])
	print("new 0.175: hits=%d volleys=%d death_tick=%d" % [new.hits, new.volleys, new.death])
	quit(0)
