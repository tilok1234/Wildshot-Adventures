extends Node
## Death recap tracker (docs/12 §2.10, CORE-51 Law 8): keeps the last
## 5 seconds of incoming player hits (from the driver's event relay) plus
## hostile telegraph timings; on player death, assembles the recap —
## killing pattern, its origin-ish position, telegraph lead time, and the
## full recent-hit trace — auto-appends it to user://logs/session.jsonl,
## and signals the UI. Driver-side; sim ignorant.

signal recap_ready(recap: Dictionary)

const SimEvents := preload("res://sim/events.gd")

const TRACE_TICKS := 300  # 5 s

var driver: Node = null
var world: RefCounted = null

var _hits: Array[Dictionary] = []
var _last_telegraph_tick := {}
var _done := false


func _process(_delta: float) -> void:
	if driver == null or world == null or _done:
		return
	var player_ids := {}
	for p: RefCounted in world.players:
		player_ids[p.id] = true
	for ev: Dictionary in driver.frame_events:
		match int(ev.type):
			SimEvents.Type.TELEGRAPH_STARTED:
				_last_telegraph_tick[int(ev.id)] = int(ev.tick)
			SimEvents.Type.DAMAGE_APPLIED:
				if player_ids.has(int(ev.target)):
					(
						_hits
						. append(
							{
								"tick": int(ev.tick),
								"amount": int(ev.amount),
								"pattern": int(ev.pattern),
								"pos": ev.pos,
							}
						)
					)
			SimEvents.Type.ENTITY_KILLED:
				if bool(ev.get("player", false)):
					_emit_recap(int(ev.tick))
	var cutoff: int = world.tick - TRACE_TICKS
	while not _hits.is_empty() and int(_hits[0].tick) < cutoff:
		_hits.pop_front()


func _emit_recap(death_tick: int) -> void:
	_done = true
	var killer: Dictionary = _hits[-1] if not _hits.is_empty() else {}
	# Emitter telegraphs use id -100; real enemies (M5) will carry their
	# own telegraph ids — extend the lookup then.
	var telegraph_lead := -1
	if _last_telegraph_tick.has(-100) and not killer.is_empty():
		telegraph_lead = int(killer.tick) - int(_last_telegraph_tick[-100])
	var recap := {
		"death_tick": death_tick,
		"killer": killer,
		"telegraph_lead_ticks": telegraph_lead,
		"trace": _hits.duplicate(),
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://logs"))
	var f := FileAccess.open("user://logs/session.jsonl", FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open("user://logs/session.jsonl", FileAccess.WRITE)
	if f != null:
		f.seek_end()
		var line := recap.duplicate(true)
		for h: Dictionary in line.trace:
			h.pos = [snappedf(h.pos.x, 0.01), snappedf(h.pos.y, 0.01)]
		if not line.killer.is_empty():
			line.killer = line.killer.duplicate()
			line.killer.pos = [snappedf(killer.pos.x, 0.01), snappedf(killer.pos.y, 0.01)]
		f.store_line(JSON.stringify(line))
		f.close()
	recap_ready.emit(recap)
