extends "res://sim/actor_state.gd"
## Player sim state, v0 class shell (docs/12 §3.2): hp 100, mana 100 (mana
## exists only for the CORE-34 ability slot — primary fire costs nothing,
## ever; CORE-32), baseline speed 4.0 tiles/s, body radius 0.35.
## SimWorld.players is an ARRAY of these (GDD-16 co-op insurance) — no player
## singleton or get_player() global exists anywhere.

var mana: int = 100
## Sim-side autofire latch (§2.8): toggled by the frame's toggle edge, so
## it appears in replays and the HUD indicator reads sim state.
var autofire_on: bool = false
## Index into SimWorld.weapon_frames.
var equipped_weapon: int = 0
## Cadence gate: firing is legal when tick >= this.
var next_fire_tick: int = 0


func serialize_into(buf: StreamPeerBuffer) -> void:
	super.serialize_into(buf)
	buf.put_32(mana)
	buf.put_u8(1 if autofire_on else 0)
	buf.put_u8(equipped_weapon)
	buf.put_64(next_fire_tick)
