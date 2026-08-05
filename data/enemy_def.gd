extends Resource
## EnemyDef (docs/12 §2.7, §3.4): lean CORE-40 stats + a movement policy +
## emitter slots. Pure data — behavior is the sim's explicit 5-state
## machine (sim/systems/enemy_step.gd); no behavior trees. Health totals
## stay honest (CORE-36); no accuracy/evasion/crit fields exist or may be
## added (CORE-40).
##
## FLANKER landed with Leadshot (M6): orbit-in — spiral to the
## range_min..range_max band, circle-strafe inside it, chirality from
## id parity. ORBIT is declared for the §2.7 grammar and anchors until
## a roster row needs it.

enum MovementPolicy { CHASER, KEEP_RANGE, ORBIT, ANCHOR, FLANKER }

## Melee-CLASS slot ceiling (tiles): a pattern slot triggering at or
## under this range is a close swing. One truth for the sim's press
## gate (enemy_step) and the DodgeBot's body model (dodge_policy).
const MELEE_TRIGGER_MAX := 2.0

## sl-0213 RANGE-BAND VOCABULARY: "melee" names ENGAGEMENT DISTANCE,
## never weapon type (every enemy is a projectile fighter). The band
## words are the vocabulary; a def declares the distance its kit wants.
## &"" = undeclared (pre-vocabulary defs — each combat wave fills its
## own families as it rebuilds them).
const BANDS := {
	&"point_blank": [0.0, 2.0],
	&"close": [2.0, 6.0],
	&"mid": [6.0, 10.0],
	&"long": [10.0, 999.0],
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var hp: int = 20
@export var body_radius: float = 0.3
## Tiles/second (§3.4 column; kiteable at the 3.0 player floor by proof).
@export var move_speed: float = 2.0
## Body-touch damage; 0 = none. Applies on its own cooldown, any state.
@export var contact_damage: int = 0
## Ticks between contact applications. Authored, [T].
@export var contact_cooldown_ticks: int = 30
## Engage when the nearest player is within this many tiles.
@export var aggro_range: float = 12.0
@export var movement_policy: MovementPolicy = MovementPolicy.CHASER
## KEEP_RANGE band (tiles): retreat inside range_min, approach outside
## range_max, hold between.
@export var range_min: float = 0.0
@export var range_max: float = 0.0
## THE PRESS (close-fighter wave 1, sl-0213): while any melee-class
## pattern slot's gate is open (cooldown allows a fire), the movement
## policy resolves to CHASER — the enemy commits in for its swing; the
## swing re-arms the gate and the base policy resumes. A pure function
## of (tick, serialized cooldowns): zero new state (GDD-16). Composes
## archetypes without new policies: FLANKER+press = the wolf's
## circling lunge; KEEP_RANGE+press = the goblin's flee-and-pelt.
@export var press_on_melee_gate: bool = false
## sl-0213: this kit's declared engagement band — a BANDS key, or &""
## for undeclared. Data vocabulary only in v1 (tests validate it; no
## sim system reads it): the word exists so records, tests, and future
## UI say "melee" as a DISTANCE, never a weapon type.
@export var range_band: StringName = &""
## EmitterSlot resources; empty = melee-only.
@export var emitters: Array[Resource] = []
## PhaseList resource (docs/12 §3.5 elite): when set, the active phase's
## policy + emitter set supersede the flat fields above and `emitters`
## stays empty. null = ordinary single-phase enemy.
@export var phases: Resource = null

## ---- Loop v1 drop table (docs/19; every number [T]). Defaults drop
## NOTHING and grant no XP, so pre-loop scenarios and tests are
## untouched until data deliberately fills a def.
@export var xp_value: int = 0
@export var gold_min: int = 0
@export var gold_max: int = 0
## Chance [0,1] that ONE equipment drop rolls on death.
@export var drop_chance: float = 0.0
@export var drop_w_weapon: int = 3
@export var drop_w_armor: int = 2
@export var drop_w_ability: int = 1
## S1 seam 2: ring-drop weight. Default 0 keeps every pre-slice def's
## kill-roll draw SEQUENCE byte-identical (the weight only joins the
## kind roll when set).
@export var drop_w_ring: int = 0
@export var drop_tier_min: int = 1
@export var drop_tier_max: int = 1
## Boss-tied uniques (docs/19 ruling 2): parallel arrays, each rolled
## independently — no pity, reward breadth is the dry-streak answer.
@export var unique_drops: Array[Resource] = []
@export var unique_chances: Array[float] = []


## Active phase for a current HP: first entry whose floor the HP still
## exceeds; the last phase catches everything at or below its ceiling.
## Pure function of (def, hp) — the sim's single phase-resolution rule.
func phase_for_hp(cur_hp: int) -> int:
	var list: Array = phases.phases
	for i in list.size():
		var floor_hp := roundi(float(hp) * float(list[i].hp_floor_pct) / 100.0)
		if cur_hp > floor_hp:
			return i
	return list.size() - 1


## PhaseDef entry for a phase index; null when this def is unphased.
func phase_entry(index: int) -> Resource:
	if phases == null:
		return null
	return phases.entry(index)


## Emitter slots active at a phase index (the flat set when unphased).
func active_emitters(index: int) -> Array:
	var pe := phase_entry(index)
	if pe == null:
		return emitters
	var pemit: Array = pe.emitters
	return pemit


## Movement policy active at a phase index (the flat one when unphased).
func active_policy(index: int) -> int:
	var pe := phase_entry(index)
	if pe == null:
		return int(movement_policy)
	return int(pe.movement_policy)
