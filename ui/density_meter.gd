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


func _ready() -> void:
	_ring.resize(SAMPLE_WINDOW)
	_label.add_theme_font_size_override("font_size", 10)
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

	var over_total: bool = total > budgets.combined_max
	var over_hostile: bool = hostile > budgets.hostile_ordinary_max
	var over_enemies: bool = enemies > budgets.enemies_max
	var over_effects: bool = effects > budgets.effects_max
	_label.text = (
		"DENSITY\nproj %d/%d  (H %d/%d  F %d)\npeak5s %d\nenemies %d/%d\neffects %d/%d\nworst-case: pending roster (M5)"
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
		]
	)
	var over := over_total or over_hostile or over_enemies or over_effects
	_label.add_theme_color_override("font_color", _warn if over else _ok)
