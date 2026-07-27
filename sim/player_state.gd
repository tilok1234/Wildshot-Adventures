extends "res://sim/actor_state.gd"
## Player sim state, v0 class shell (docs/12 §3.2): hp 100, mana 100 (mana
## exists only for the CORE-34 ability slot — primary fire costs nothing,
## ever; CORE-32), baseline speed 4.0 tiles/s, body radius 0.35.
## SimWorld.players is an ARRAY of these (GDD-16 co-op insurance) — no player
## singleton or get_player() global exists anywhere.

var mana: int = 100


func serialize_into(buf: StreamPeerBuffer) -> void:
	super.serialize_into(buf)
	buf.put_32(mana)
