extends "res://sim/actor_state.gd"
## Enemy sim state (M5): 5-state machine bookkeeping on top of ActorState.
## def_index points into SimWorld.enemy_defs (definitions live outside
## serialization like weapon_frames; the replay header's data hash covers
## them). def_index -1 = inert stand-in (M2 stress bodies): no AI runs.

enum AIState { IDLE, REPOSITION, WINDUP, FIRE, RECOVER }

var def_index: int = -1
var ai_state: int = AIState.IDLE
## WINDUP: the fire tick. RECOVER: the tick repositioning resumes.
var state_until: int = 0
## Emitter slot currently winding up (-1 none).
var winding_slot: int = -1
## Per-slot next-allowed-FIRE tick, parallel to def.emitters.
var cooldowns: PackedInt64Array = PackedInt64Array()
## Contact damage may re-apply from this tick.
var next_contact_tick: int = 0
## Spawn tick — TTK telemetry reads kill tick minus this.
var spawned_at_tick: int = 0
## Resolved PhaseList phase (§3.5 elite; stays 0 for unphased defs).
## Serialized (SERIAL 12): transition side effects (cooldown re-arm,
## PHASE_CHANGED, windup interrupt) fire exactly once per crossing, so
## the edge-detection state must restore with the run.
var phase_index: int = 0


func serialize_into(buf: StreamPeerBuffer) -> void:
	super.serialize_into(buf)
	buf.put_8(def_index)
	buf.put_u8(ai_state)
	buf.put_64(state_until)
	buf.put_8(winding_slot)
	buf.put_u8(cooldowns.size())
	for c in cooldowns:
		buf.put_64(c)
	buf.put_64(next_contact_tick)
	buf.put_64(spawned_at_tick)
	buf.put_u8(phase_index)
