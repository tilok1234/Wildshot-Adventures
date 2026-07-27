extends RefCounted
## Shared view-time state (docs/12 §2.9): the interpolation alpha sourced
## from the RealtimeDriver plus the prev/curr render toggle. Strictly
## view-side — the sim never sees any of this, and toggling it can never
## perturb gameplay. The tester-build default is decided by the §6 item 1
## A/B on a high-refresh display; interpolation ON is only the dev default.

var driver: Node = null
var interp_enabled: bool = true


func alpha() -> float:
	return driver.alpha() if driver != null else 1.0
