extends SceneTree
## sl-0078 fit-rule probe (on-demand): walks REAL b77 red-line sites
## with the shipped collision — the sl-0070 census's screenshot-class
## desert pinch and the worst tree-band pinch — and proves the player
## now crosses where the sprite visibly fits, while the ENEMY model
## (full conservative grid) still refuses the same gaps (the accepted
## round-1 asymmetry). The designer's own walk is the acceptance; this
## is its mechanized shadow.
## Run: godot_console --headless --path . --script tests/pinch_probe/fit_rule_probe.gd

const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const PropColliders := preload("res://game/arena/prop_colliders.gd")
const Kinematics := preload("res://sim/systems/kinematics.gd")
const PlayerMove := preload("res://sim/systems/player_move.gd")

const PACK := "res://assets/worldforge-packs/wildshot-overworld-pack-dusk/"
## Census sites (reports/pinch_diagnosis_b77.json): a desert
## screenshot-class corner-touch and the oak+oak detour-62 tree pinch.
## Walks press the desired diagonal through each pinch's open pair.
const SITES: Array = [
	{
		"name": "desert cactus/boulder lane",
		"from": Vector2(61.5, 141.5),
		"to": Vector2(59.5, 143.5)
	},
	{
		"name": "tree-band oak pinch (detour 62)",
		"from": Vector2(21.5, 91.5),
		"to": Vector2(22.5, 92.5)
	},
]
const SPEED := 3.0
const DT := 1.0 / 60.0
const TICKS := 420


func _walk(grid: RefCounted, discs: Dictionary, r: float, from: Vector2, to: Vector2) -> Dictionary:
	var pos := from
	var reached := -1
	for t in TICKS:
		var dir := to - pos
		if dir.length() < 0.3:
			reached = t
			break
		pos = Kinematics.move_circle(grid, pos, r, dir.normalized() * SPEED * DT, discs)
	return {"reached": reached, "final": pos}


func _init() -> void:
	var wf := WorldforgePack.validate(PACK)
	if not bool(wf.ok):
		printerr("FAIL: b77 pack invalid")
		quit(1)
		return
	var built := PropColliders.build(PACK, wf.bitgrid)
	if built.is_empty():
		printerr("FAIL: prop colliders did not build")
		quit(1)
		return
	var failed := false
	for site: Dictionary in SITES:
		var fit := _walk(
			built.walk_grid, built.discs, PlayerMove.TERRAIN_RADIUS, site.from, site.to
		)
		var legacy := _walk(wf.bitgrid, {}, 0.25, site.from, site.to)
		var enemy := _walk(wf.bitgrid, {}, 0.25, site.from, site.to)
		var ok: bool = int(fit.reached) >= 0 and int(legacy.reached) < 0 and int(enemy.reached) < 0
		print(
			(
				"%s [%s]: fit-rule player %s (t=%d, end %s); legacy-0.25 %s; enemy-model %s"
				% [
					"PASS" if ok else "FAIL",
					String(site.name),
					"CROSSES" if int(fit.reached) >= 0 else "blocked",
					int(fit.reached),
					str(Vector2(fit.final).snapped(Vector2(0.01, 0.01))),
					"blocked" if int(legacy.reached) < 0 else "crossed?!",
					"blocked" if int(enemy.reached) < 0 else "crossed?!",
				]
			)
		)
		if not ok:
			failed = true
	print("fit rule probe: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
