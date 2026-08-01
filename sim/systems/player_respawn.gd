extends RefCounted
## Ordered system (FIRST in the step): CORE-43 OVERWORLD DEATH (slice
## S0 seam 3, sl-0100) — the persistent-world half of dying. THE
## damage path already took the gold slice and armed respawn_at_tick
## at the death tick; this system revives the player AT THE
## SETTLEMENT (world.respawn_cell) when the timer lands, or EARLY
## when they press the ability key while dead (the one-key retry —
## the key is otherwise meaningless to a corpse, so the input stream
## stays replay-honest with zero format change). Full refill on
## revive: the WALK BACK is the rest of the price, never attrition
## (docs/19 feel law carried). Inert in every world where
## persistent_respawn is off — dead-in-place stands for labs, proofs,
## and hardcore.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

const SimEvents := preload("res://sim/events.gd")

## Auto-respawn delay in ticks [T] (~4 s — the Law-8 recap stays
## readable; the world does not wait longer than that).
const RESPAWN_DELAY_TICKS := 240


static func run(world: RefCounted) -> void:
	if not world.persistent_respawn:
		return
	var frames: Array = world.current_frames
	for i in world.players.size():
		var p: RefCounted = world.players[i]
		if not p.dead or p.respawn_at_tick < 0:
			continue
		var confirm := false
		if i < frames.size() and frames[i] != null:
			confirm = bool(frames[i].ability_pressed)
		if not (confirm or world.tick >= p.respawn_at_tick):
			continue
		p.pos = world.respawn_cell
		p.prev_pos = world.respawn_cell
		p.vel = Vector2.ZERO
		p.dead = false
		p.respawn_at_tick = -1
		p.hp = p.max_hp
		p.mana = p.max_mana
		(
			world
			. events
			. append(
				{
					"type": SimEvents.Type.PLAYER_RESPAWNED,
					"tick": world.tick,
					"player": p.id,
					"pos": world.respawn_cell,
				}
			)
		)
