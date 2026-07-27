extends RefCounted
## Fixed-capacity SoA projectile pool (docs/12 §2.6), preallocated to 1024,
## free-list despawn. M2 rig subset: straight-motion fields only — damage,
## pattern_id, pierce, motion programs, and the hit registry land at M3.
## This pool is the SEED of the M3 pool, not throwaway: fields append, the
## SoA layout and free-list stay.
##
## PackedArray assignment shares storage in Godot 4.6 — systems alias these
## fields as locals for speed; snapshots must use duplicate().

const CAPACITY := 1024

var pos_x := PackedFloat32Array()
var pos_y := PackedFloat32Array()
var vel_x := PackedFloat32Array()
var vel_y := PackedFloat32Array()
var radius := PackedFloat32Array()
var ttl := PackedInt32Array()
var faction := PackedByteArray()
var active := PackedByteArray()
## Previous-tick positions, view interpolation only (§2.9) — excluded from
## serialization; no sim system reads them.
var prev_x := PackedFloat32Array()
var prev_y := PackedFloat32Array()

var live_count: int = 0
var _free := PackedInt32Array()
var _free_top: int = 0


func setup() -> void:
	pos_x.resize(CAPACITY)
	pos_y.resize(CAPACITY)
	vel_x.resize(CAPACITY)
	vel_y.resize(CAPACITY)
	radius.resize(CAPACITY)
	ttl.resize(CAPACITY)
	faction.resize(CAPACITY)
	active.resize(CAPACITY)
	prev_x.resize(CAPACITY)
	prev_y.resize(CAPACITY)
	_free.resize(CAPACITY)
	for i in CAPACITY:
		# Reversed so pop order is slot 0, 1, 2, ... — early spawns land in
		# low slots and slot-ascending iteration tracks spawn order.
		_free[i] = CAPACITY - 1 - i
	_free_top = CAPACITY
	live_count = 0


## Returns the slot, or -1 when the pool is exhausted (caller decides; the
## soak harness watches for exhaustion — §2.11).
func spawn(px: float, py: float, vx: float, vy: float, r: float, ttl_ticks: int, fac: int) -> int:
	if _free_top == 0:
		return -1
	_free_top -= 1
	var s := _free[_free_top]
	pos_x[s] = px
	pos_y[s] = py
	prev_x[s] = px
	prev_y[s] = py
	vel_x[s] = vx
	vel_y[s] = vy
	radius[s] = r
	ttl[s] = ttl_ticks
	faction[s] = fac
	active[s] = 1
	live_count += 1
	return s


func despawn(s: int) -> void:
	if active[s] == 0:
		return
	active[s] = 0
	pos_x[s] = 0.0
	pos_y[s] = 0.0
	prev_x[s] = 0.0
	prev_y[s] = 0.0
	vel_x[s] = 0.0
	vel_y[s] = 0.0
	radius[s] = 0.0
	ttl[s] = 0
	faction[s] = 0
	live_count -= 1
	_free[_free_top] = s
	_free_top += 1


func serialize_into(buf: StreamPeerBuffer) -> void:
	# Free-list order is state: it decides which slot the next spawn takes,
	# which decides iteration order — so it hashes too.
	buf.put_u32(CAPACITY)
	buf.put_data(pos_x.to_byte_array())
	buf.put_data(pos_y.to_byte_array())
	buf.put_data(vel_x.to_byte_array())
	buf.put_data(vel_y.to_byte_array())
	buf.put_data(radius.to_byte_array())
	buf.put_data(ttl.to_byte_array())
	buf.put_data(faction)
	buf.put_data(active)
	buf.put_u32(live_count)
	buf.put_u32(_free_top)
	buf.put_data(_free.to_byte_array())
