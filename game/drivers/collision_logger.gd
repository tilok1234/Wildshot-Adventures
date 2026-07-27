extends Node
## Terrain-collision / corner-snag JSONL log (docs/12 §2.10, M3 slice):
## consumes the driver's per-frame event relay and appends one line per
## terrain impact — tile cell, impact position, pattern id, near-corner
## flag. Driver-side file IO; the sim never touches files. Add AFTER the
## driver in the tree so the same frame's events are visible.
##
## Near-corner: impact point within CORNER_EPS tiles of a tile corner on
## both axes — the population the M8 "corner-snag log clean" checklist row
## audits.

const SimEvents := preload("res://sim/events.gd")

const LOG_PATH := "user://logs/terrain.jsonl"
const CORNER_EPS := 0.15

var driver: Node = null
var snag_count: int = 0
var _file: FileAccess = null


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://logs"))
	_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if _file == null:
		push_warning("collision_logger: cannot open %s" % LOG_PATH)


func _process(_delta: float) -> void:
	if driver == null or _file == null:
		return
	var wrote := false
	for ev: Dictionary in driver.frame_events:
		if int(ev.type) != SimEvents.Type.PROJECTILE_DESPAWNED:
			continue
		if int(ev.reason) != SimEvents.DespawnReason.TERRAIN:
			continue
		wrote = true
		var pos: Vector2 = ev.pos
		var fx := absf(pos.x - roundf(pos.x))
		var fy := absf(pos.y - roundf(pos.y))
		var near_corner := fx < CORNER_EPS and fy < CORNER_EPS
		if near_corner:
			snag_count += 1
		var cell: Vector2i = ev.cell
		(
			_file
			. store_line(
				(
					JSON
					. stringify(
						{
							"tick": int(ev.tick),
							"cell": [cell.x, cell.y],
							"pos": [snappedf(pos.x, 0.001), snappedf(pos.y, 0.001)],
							"pattern": int(ev.pattern),
							"near_corner": near_corner,
						}
					)
				)
			)
		)
	# Flush only when something was written — an every-frame flush is an
	# OS call (and an AV-scan trigger) for nothing.
	if wrote:
		_file.flush()
