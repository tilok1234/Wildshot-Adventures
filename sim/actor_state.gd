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
## Applied velocity this tick in tiles/s — the REAL post-slide result
## (a wall-pinned actor reads zero), written by the movement systems
## every tick. Sim-readable serialized state (SERIAL 10, M6 Leadshot
## intercept), unlike prev_pos below.
var vel: Vector2 = Vector2.ZERO
## Tick this actor last took damage — gates out-of-combat regen (§3.2).
var last_damaged_tick: int = -1000000
## Players die in place (dead flag; recap + restart own the flow).
## Enemies never set this — they are removed by the death sweep.
var dead: bool = false
## Armor tier 0–5 (Loop v1, docs/19; CORE-40 lean armor/defense stat):
## flat damage reduction via progression data in THE damage path.
## 0 = none — the default preserves pre-loop behavior exactly. Enemies
## keep 0 in v1; the field lives here so future enemy armor is a data
## change (SERIAL 13).
var armor_tier: int = 0
## Armor VALUE — the defense number THE docs/22 formula subtracts
## (SERIAL 15, stat frame): derived for class-backed players
## (StatFrame.recompute), plain data for future enemy armor. 0 makes
## the formula identity, so every pre-frame actor is byte-unchanged.
var armor: int = 0


func serialize_into(buf: StreamPeerBuffer) -> void:
	buf.put_64(id)
	buf.put_double(pos.x)
	buf.put_double(pos.y)
	buf.put_double(radius)
	buf.put_32(hp)
	buf.put_u8(faction)
	buf.put_double(move_speed)
	buf.put_double(vel.x)
	buf.put_double(vel.y)
	buf.put_64(last_damaged_tick)
	buf.put_u8(1 if dead else 0)
	buf.put_u8(armor_tier)
	buf.put_32(armor)
