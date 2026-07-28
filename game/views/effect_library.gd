extends RefCounted
## EffectLibrary policy core (docs/12 §2.6, CORE-50, ledger #9): the ONE
## place cosmetic/friendly rendering intensity is decided. Views consult
## it for spawn gating (effect density), alpha scaling (effect opacity),
## and the flash-reduction mode. STRUCTURAL CLAMP: hostile projectiles,
## telegraphs, and hazard markers never read this object — no hostile
## rendering path may consult it for visibility reduction, so an
## accessibility option can never manufacture a Law 1/Law 8 violation.
## Settings persist under [effects] in settings.cfg (§2.13); the density
## audit forces everything to full without touching the file.

## Cosmetic-instance keep fraction (options presets 1.0 / 0.66 / 0.33).
var density := 1.0
## Cosmetic/friendly alpha scale (options presets 1.0 / 0.7 / 0.4).
var opacity := 1.0
## Photosensitivity mode (CORE-50): pops render smaller, dimmer, and
## shorter — further reducing whatever the defaults allow (the 9-row
## acceptance's photosensitivity line).
var flash_reduction := false

var _acc := 0.0


## Bresenham-fraction spawn gate for cosmetic instances: exact long-run
## keep ratio with no RNG — view-side only, the sim never sees it.
func keep_cosmetic() -> bool:
	_acc += density
	if _acc >= 0.9999:
		_acc -= 1.0
		return true
	return false


## Alpha for cosmetic pops (flashes, cast rings).
func cosmetic_alpha() -> float:
	return opacity * (0.7 if flash_reduction else 1.0)


## Alpha for friendly-channel rendering (player shots, friendly zones).
func friendly_alpha() -> float:
	return opacity


func flash_size_scale() -> float:
	return 0.6 if flash_reduction else 1.0


func flash_life_scale() -> float:
	return 0.75 if flash_reduction else 1.0
