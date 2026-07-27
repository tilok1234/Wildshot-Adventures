extends RefCounted
## Hand-rolled PCG32 (docs/12 §2.4): the only randomness source allowed inside
## the sim. Serializable, deterministic, named streams owned by SimWorld.
## Global engine RNG is banned under sim/ and CI greps for it.

const MULT: int = 6364136223846793005
const MASK64: int = -1  # all 64 bits; GDScript ints are 64-bit

var state: int = 0
var inc: int = 0


func seed_stream(init_state: int, stream_id: int) -> void:
	state = 0
	inc = ((stream_id << 1) | 1) & MASK64
	next_u32()
	state = (state + init_state) & MASK64
	next_u32()


func next_u32() -> int:
	var old := state
	state = (old * MULT + inc) & MASK64
	var xorshifted := ((old >> 18) ^ old) >> 27
	var rot := (old >> 59) & 31
	return ((xorshifted >> rot) | (xorshifted << ((-rot) & 31))) & 0xFFFFFFFF


## Uniform integer in [0, bound) without modulo bias.
func next_bounded(bound: int) -> int:
	var threshold := (0x100000000 - bound) % bound
	while true:
		var r := next_u32()
		if r >= threshold:
			return r % bound
	return 0


## Uniform float in [0, 1) with 32-bit resolution.
func next_unit() -> float:
	return float(next_u32()) / 4294967296.0
