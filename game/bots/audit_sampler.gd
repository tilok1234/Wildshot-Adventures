extends "res://input/human_sampler.gd"
## Scripted audit input (M5 stress-density screenshot audit): fire held
## from tick 0 on Scattercast with rotating aim and a circling strafe —
## maximum player VFX (shots, muzzle/impact flashes, damage-number spam)
## while the hostile ring pours aimed fire in. Deterministic; one more
## equal InputSource (§2.8).

const MOVE_X: Array[int] = [1, 1, 0, -1, -1, -1, 0, 1]
const MOVE_Y: Array[int] = [0, 1, 1, 1, 0, -1, -1, -1]

var _tick := 0


func sample(_mouse_tile: Vector2, _player_pos: Vector2) -> InputFrame:
	var f := InputFrame.new()
	var leg := (_tick / 40) % 8
	f.move_x = MOVE_X[leg]
	f.move_y = MOVE_Y[leg]
	f.normalized = true
	var q := InputFrame.quantize_aim(Vector2.RIGHT.rotated(_tick * 0.05))
	f.aim_x = q.x
	f.aim_y = q.y
	f.fire_held = true
	if _tick == 0:
		f.weapon_select = 2
	_tick += 1
	return f
