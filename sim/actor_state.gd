extends RefCounted
## Mutable sim state for one actor. Plain data, no Node, no engine coupling
## (docs/12 §2.1). Units: positions in tiles (1 tile = 32 px view-side),
## speeds in tiles/s, timers in ticks. Stable entity id, never reused per run.

const FACTION_FRIENDLY := 0
const FACTION_HOSTILE := 1

var id: int = 0
var pos: Vector2 = Vector2.ZERO
## Previous-tick position, stored for view-side interpolation only (§2.9).
## No sim system may read it, so it is excluded from serialize/state_hash.
var prev_pos: Vector2 = Vector2.ZERO
var radius: float = 0.35
var hp: int = 100
var faction: int = FACTION_FRIENDLY
var move_speed: float = 4.0


func serialize_into(buf: StreamPeerBuffer) -> void:
	buf.put_64(id)
	buf.put_double(pos.x)
	buf.put_double(pos.y)
	buf.put_double(radius)
	buf.put_32(hp)
	buf.put_u8(faction)
	buf.put_double(move_speed)
