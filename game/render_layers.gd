extends RefCounted
## Named z-bands (docs/12 §2.5, CORE-51 Laws 1/2/6): every view node
## declares its band; hostile threat-carrying elements render above every
## friendly/player band BY CONSTRUCTION. Load-time band assertions and the
## stress-density occlusion audit activate at M5/M6 with live hostiles.
##
## Law 1: threat renders above beauty — hostile shots/telegraphs never
## occluded. Law 2: player shots visually subordinate to enemy fire.
## Law 6: quiet floors — contrast reserved for gameplay.

const FLOOR := 0  # TileMapLayers (default z)
const FRIENDLY_GROUND := 10  # friendly decals + placed zones (Blast Rune)
const HOSTILE_HAZARD_FILL := 20  # spatial grounding only, never sole signal
const ACTORS := 30
const CANOPY := 32  # tree crowns: occlude bodies (depth), never bars or any threat band
const HP_BARS := 35  # overhead bars: general presentation (CORE-35), below all hostile bands
const PLAYER_PROJECTILES := 40  # + ALL player VFX
const DAMAGE_NUMBERS := 50  # non-occluding: BELOW all hostile bands
const HOSTILE_PROJECTILES := 60
const HOSTILE_TELEGRAPH_RIMS := 70  # rims/arm-progress/windups/impact flashes
const HUD := 80  # CanvasLayer, above world bands structurally
const DEBUG_OVERLAY := 90


## Load-time band assertions (§2.5, activated M5): the Laws-1/2 ordering
## is structural and cannot silently reorder — every hostile band above
## every friendly/informational band, damage numbers below all hostile
## bands. Called at scene boot; a violation is a loud boot error.
static func assert_bands() -> bool:
	var ok := true
	ok = ok and HOSTILE_TELEGRAPH_RIMS > HOSTILE_PROJECTILES
	ok = ok and HOSTILE_PROJECTILES > DAMAGE_NUMBERS  # Law 1: threat above info
	ok = ok and HOSTILE_PROJECTILES > PLAYER_PROJECTILES  # Law 2: player fire subordinate
	ok = ok and DAMAGE_NUMBERS > PLAYER_PROJECTILES  # numbers over own VFX, never over threats
	ok = ok and PLAYER_PROJECTILES > HP_BARS
	ok = ok and HP_BARS > CANOPY  # bars read through foliage
	ok = ok and CANOPY > ACTORS  # crowns occlude bodies (depth cue), nothing above
	ok = ok and ACTORS > HOSTILE_HAZARD_FILL  # hazard FILL grounds under bodies; the RIM warns above
	ok = ok and HOSTILE_HAZARD_FILL > FRIENDLY_GROUND
	ok = ok and FRIENDLY_GROUND > FLOOR
	if not ok:
		push_error("render_layers: band ordering violated (CORE-51 Laws 1/2) — fix the constants")
	return ok
