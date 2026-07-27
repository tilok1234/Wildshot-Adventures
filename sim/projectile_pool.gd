extends RefCounted
## Fixed-capacity SoA projectile pool (docs/12 §2.6), preallocated to 1024,
## free-list despawn. M3 form: damage, pattern identity, motion programs
## (pure functions of ticks-since-spawn), and the per-projectile hit
## registry for pierce/return weapons. Everything here is state and
## serializes — including registries and free-list order (allocation order
## decides slot reuse, which decides iteration order).
##
## PackedArray assignment shares storage in Godot 4.6 — systems alias these
## fields as locals for speed; snapshots must use duplicate().

const CAPACITY := 1024
## Hit-registry slots per projectile (§2.6): fixed 8. Overflow rule is
## deterministic — when all 8 are used, unregistered targets take no damage
## (DamageBlocked, reason registry_full).
const REG_SLOTS := 8

## Motion programs (§2.6): velocity is a pure function of ticks-since-spawn
## and the authored params — never of any entity's position (CORE-32; this
## purity is what makes the dodge bot's closed-form projection possible).
enum Program {
	STRAIGHT,
	DECELERATE,
	SINE,
	BOOMERANG,
}

var pos_x := PackedFloat32Array()
var pos_y := PackedFloat32Array()
var vel_x := PackedFloat32Array()
var vel_y := PackedFloat32Array()
## Launch direction (unit), fixed at spawn — the reference axis for
## DECELERATE/SINE/BOOMERANG programs.
var dir_x := PackedFloat32Array()
var dir_y := PackedFloat32Array()
var radius := PackedFloat32Array()
var ttl := PackedInt32Array()
var faction := PackedByteArray()
var active := PackedByteArray()
var damage := PackedInt32Array()
var pattern_id := PackedInt32Array()
var program := PackedByteArray()
var prog_a := PackedFloat32Array()
var prog_b := PackedFloat32Array()
var prog_c := PackedFloat32Array()
var spawn_tick := PackedInt32Array()
## 0 = despawn on first hit; N>0 = pierces, damaging each target at most N
## passes (registry-gated).
var max_passes := PackedByteArray()
## Hit registry, REG_SLOTS per projectile: entity id + pass byte
## (bits 0–6 = pass count, bit 7 = in-contact-last-tick, so one crossing
## counts one pass no matter how many ticks the overlap lasts).
var reg_id := PackedInt64Array()
var reg_pass := PackedByteArray()
var reg_count := PackedByteArray()
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
	dir_x.resize(CAPACITY)
	dir_y.resize(CAPACITY)
	radius.resize(CAPACITY)
	ttl.resize(CAPACITY)
	faction.resize(CAPACITY)
	active.resize(CAPACITY)
	damage.resize(CAPACITY)
	pattern_id.resize(CAPACITY)
	program.resize(CAPACITY)
	prog_a.resize(CAPACITY)
	prog_b.resize(CAPACITY)
	prog_c.resize(CAPACITY)
	spawn_tick.resize(CAPACITY)
	max_passes.resize(CAPACITY)
	reg_id.resize(CAPACITY * REG_SLOTS)
	reg_pass.resize(CAPACITY * REG_SLOTS)
	reg_count.resize(CAPACITY)
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
func spawn(
	px: float,
	py: float,
	vx: float,
	vy: float,
	r: float,
	ttl_ticks: int,
	fac: int,
	dmg: int,
	pattern: int,
	prog: int,
	pa: float,
	pb: float,
	pc: float,
	tick_now: int,
	passes: int
) -> int:
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
	var vlen := sqrt(vx * vx + vy * vy)
	dir_x[s] = vx / vlen if vlen > 0.0 else 1.0
	dir_y[s] = vy / vlen if vlen > 0.0 else 0.0
	radius[s] = r
	ttl[s] = ttl_ticks
	faction[s] = fac
	damage[s] = dmg
	pattern_id[s] = pattern
	program[s] = prog
	prog_a[s] = pa
	prog_b[s] = pb
	prog_c[s] = pc
	spawn_tick[s] = tick_now
	max_passes[s] = passes
	reg_count[s] = 0
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
	dir_x[s] = 0.0
	dir_y[s] = 0.0
	radius[s] = 0.0
	ttl[s] = 0
	faction[s] = 0
	damage[s] = 0
	pattern_id[s] = 0
	program[s] = 0
	prog_a[s] = 0.0
	prog_b[s] = 0.0
	prog_c[s] = 0.0
	spawn_tick[s] = 0
	max_passes[s] = 0
	var base := s * REG_SLOTS
	for k in REG_SLOTS:
		reg_id[base + k] = 0
		reg_pass[base + k] = 0
	reg_count[s] = 0
	live_count -= 1
	_free[_free_top] = s
	_free_top += 1


func serialize_into(buf: StreamPeerBuffer) -> void:
	buf.put_u32(CAPACITY)
	buf.put_data(pos_x.to_byte_array())
	buf.put_data(pos_y.to_byte_array())
	buf.put_data(vel_x.to_byte_array())
	buf.put_data(vel_y.to_byte_array())
	buf.put_data(dir_x.to_byte_array())
	buf.put_data(dir_y.to_byte_array())
	buf.put_data(radius.to_byte_array())
	buf.put_data(ttl.to_byte_array())
	buf.put_data(faction)
	buf.put_data(active)
	buf.put_data(damage.to_byte_array())
	buf.put_data(pattern_id.to_byte_array())
	buf.put_data(program)
	buf.put_data(prog_a.to_byte_array())
	buf.put_data(prog_b.to_byte_array())
	buf.put_data(prog_c.to_byte_array())
	buf.put_data(spawn_tick.to_byte_array())
	buf.put_data(max_passes)
	buf.put_data(reg_id.to_byte_array())
	buf.put_data(reg_pass)
	buf.put_data(reg_count)
	buf.put_u32(live_count)
	buf.put_u32(_free_top)
	buf.put_data(_free.to_byte_array())
