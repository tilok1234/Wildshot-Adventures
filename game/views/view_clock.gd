extends RefCounted
## Shared view-time state (docs/12 §2.9): the interpolation alpha sourced
## from the RealtimeDriver plus the prev/curr render toggle. Strictly
## view-side — the sim never sees any of this, and toggling it can never
## perturb gameplay. Dev default is SNAP (first §6 item 1 A/B data point,
## 2026-07-27: designer on a 60 Hz panel — interp's one-tick visual delay
## read as "not reactive enough to dodge with"). The tester-build default
## is still the formal A/B's output on a high-refresh display.

var driver: Node = null
var interp_enabled: bool = false


func alpha() -> float:
	return driver.alpha() if driver != null else 1.0


func paused() -> bool:
	return driver != null and driver.paused
