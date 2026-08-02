extends RefCounted
## One tick of player intent, quantized at sample time (docs/12 §2.4).
## Human, replay, and bot sources all produce exactly this shape — the sim
## cannot tell them apart (§2.8). Aim is quantized to 1/4096; movement is
## {-1, 0, 1} per axis with a normalize flag for diagonals.

const AIM_QUANT := 4096.0

var move_x: int = 0
var move_y: int = 0
var normalized: bool = false
var aim_x: int = 0  # quantized: round(aim.x * 4096)
var aim_y: int = 0
var fire_held: bool = false
var autofire_toggle_edge: bool = false
var ability_pressed: bool = false
var weapon_select: int = 0
## THE INTERACT VERB (sl-0112): one general-purpose deliberate press —
## item pickup/equip, giver accept/turn-in, world interactables. Edge,
## not held (the sampler tracks it like ability).
var interact_pressed: bool = false


static func quantize_aim(v: Vector2) -> Vector2i:
	return Vector2i(roundi(v.x * AIM_QUANT), roundi(v.y * AIM_QUANT))


func aim_vector() -> Vector2:
	return Vector2(aim_x / AIM_QUANT, aim_y / AIM_QUANT)


func move_vector() -> Vector2:
	var v := Vector2(move_x, move_y)
	if normalized and v.length_squared() > 1.0:
		v = v.normalized()
	return v


## Serialized size in bytes — the replay stream is tick_count x players x
## this (input/replay_format.gd). 16 since WSR VERSION 2 (sl-0112:
## interact joined the recorded stream).
const SERIALIZED_SIZE := 16


func serialize_into(buf: StreamPeerBuffer) -> void:
	buf.put_8(move_x + 1)
	buf.put_8(move_y + 1)
	buf.put_8(1 if normalized else 0)
	buf.put_32(aim_x)
	buf.put_32(aim_y)
	buf.put_8(1 if fire_held else 0)
	buf.put_8(1 if autofire_toggle_edge else 0)
	buf.put_8(1 if ability_pressed else 0)
	buf.put_8(weapon_select)
	buf.put_8(1 if interact_pressed else 0)


static func deserialize_from(buf: StreamPeerBuffer) -> RefCounted:
	var f := new()
	f.move_x = buf.get_8() - 1
	f.move_y = buf.get_8() - 1
	f.normalized = buf.get_8() == 1
	f.aim_x = buf.get_32()
	f.aim_y = buf.get_32()
	f.fire_held = buf.get_8() == 1
	f.autofire_toggle_edge = buf.get_8() == 1
	f.ability_pressed = buf.get_8() == 1
	f.weapon_select = buf.get_8()
	f.interact_pressed = buf.get_8() == 1
	return f
