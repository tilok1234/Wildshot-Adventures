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
const HP_BARS := 35  # overhead bars: general presentation (CORE-35), below all hostile bands
const PLAYER_PROJECTILES := 40  # + ALL player VFX
const DAMAGE_NUMBERS := 50  # non-occluding: BELOW all hostile bands
const HOSTILE_PROJECTILES := 60
const HOSTILE_TELEGRAPH_RIMS := 70  # rims/arm-progress/windups/impact flashes
const HUD := 80  # CanvasLayer, above world bands structurally
const DEBUG_OVERLAY := 90
