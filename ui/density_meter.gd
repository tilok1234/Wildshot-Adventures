extends PanelContainer
## Density meter (docs/12 §2.10): live projectile count with per-faction
## split, 5-second peak, live enemies, effect instances — each against
## data/budgets.tres, red-lined when over. Doubles as the CORE-51 Law 5
## stress meter and the CORE-36 elite-honesty check. The sustained
## worst-case composition readout (§2.6 rule) activates when EnemyDefs
## exist (M5) — shown as pending until then, never silently omitted.
## View-only.

const SAMPLE_WINDOW := 300  # 5 s at 60 fps

var world: RefCounted = null
## Callable returning live effect-instance count (flashes now; damage
## numbers join at their task — counted against effects_max).
var effects_counter: Callable = Callable()
var budgets: Resource = null

var _label := Label.new()
var _ring := PackedInt32Array()
var _head := 0
var _warn := Color(1.0, 0.42, 0.35)
var _ok := Color(0.81, 0.77, 0.93)
var _worst_by_def := {}


## Sustained worst-case hostile projectiles for one EnemyDef (§2.6/§3.4
## composition rule): sum over slots of shots x ttl / cooldown — the
## steady-state shot count one enemy keeps alive if it fires forever.
## Phased defs (§3.5 elite) report their worst PHASE. Hazard-caster
## slots (pattern null — M6 Blightcaster) contribute nothing here:
## zones are not pool projectiles, and reading them as volleys was a
## null deref whenever a caster entered the boot scenario.
func _worst_case(defs: Array, def_index: int) -> float:
	if _worst_by_def.has(def_index):
		return _worst_by_def[def_index]
	var total := 0.0
	var def: Resource = defs[def_index]
	var phase_res: Resource = def.phases
	if phase_res == null:
		total = _emitters_sustained(def.emitters)
	else:
		var plist: Array = phase_res.phases
		for pe: Resource in plist:
			var pemit: Array = pe.emitters
			total = maxf(total, _emitters_sustained(pemit))
	_worst_by_def[def_index] = total
	return total


func _emitters_sustained(emitters: Array) -> float:
	var total := 0.0
	for slot: Resource in emitters:
		var pattern: Resource = slot.pattern
		if pattern == null:
			continue
		var shots: Array = pattern.shots
		var max_ttl := 0
		for shot: Resource in shots:
			max_ttl = maxi(max_ttl, int(shot.ttl_ticks))
		total += shots.size() * float(max_ttl) / float(maxi(1, int(slot.cooldown_ticks)))
	return total


func _ready() -> void:
	_ring.resize(SAMPLE_WINDOW)
	add_child(_label)


func _process(_delta: float) -> void:
	if world == null or budgets == null:
		return
	var pool: RefCounted = world.projectiles
	var fac: PackedByteArray = pool.faction
	var act: PackedByteArray = pool.active
	var hostile := 0
	for s in pool.CAPACITY:
		if act[s] == 1 and fac[s] == 1:
			hostile += 1
	var total: int = pool.live_count
	var friendly := total - hostile
	_ring[_head] = total
	_head = (_head + 1) % SAMPLE_WINDOW
	var peak := 0
	for v in _ring:
		peak = maxi(peak, v)
	var enemies: int = world.enemies.size()
	var effects: int = effects_counter.call() if effects_counter.is_valid() else 0
	# §2.6 composition rule, live (activated M5): the sustained hostile
	# ceiling this scenario's LIVE enemies could hold if all fired forever.
	var defs: Array = world.enemy_defs
	var worst := 0.0
	for e: RefCounted in world.enemies:
		var def_index: int = e.def_index
		if def_index >= 0:
			worst += _worst_case(defs, def_index)

	var over_total: bool = total > budgets.combined_max
	var over_hostile: bool = hostile > budgets.hostile_ordinary_max
	var over_enemies: bool = enemies > budgets.enemies_max
	var over_effects: bool = effects > budgets.effects_max
	var over_worst: bool = worst > float(budgets.hostile_ordinary_max)
	_label.text = (
		"DENSITY\nproj %d/%d  (H %d/%d  F %d)\npeak5s %d\nenemies %d/%d\neffects %d/%d\nsustained worst-case %.0f/%d"
		% [
			total,
			budgets.combined_max,
			hostile,
			budgets.hostile_ordinary_max,
			friendly,
			peak,
			enemies,
			budgets.enemies_max,
			effects,
			budgets.effects_max,
			worst,
			budgets.hostile_ordinary_max,
		]
	)
	var over := over_total or over_hostile or over_enemies or over_effects or over_worst
	_label.add_theme_color_override("font_color", _warn if over else _ok)
