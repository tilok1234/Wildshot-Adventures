extends Node
## Session lifecycle evidence (docs/12 §4 M8): the wall-clock half of the
## re-engagement record. Appends session_start on boot, session_heartbeat
## every 30 s (an alt-F4'd session is still bounded by its last beat), and
## session_end on a clean close — all to user://logs/session.jsonl, the
## same stream the recap tracker feeds. Driver-side; sim ignorant; wall
## clock is legal here (nothing under sim/ ever reads it).
##
## Contamination honesty: every line carries dev_profile — the offline
## evidence tool excludes builder-profile sessions from tester evidence by
## this field (M8 "contamination auto-exclusion"), and replay-dirty state
## rides the heartbeat so a dirtied run marks its own window.

const BuildInfo := preload("res://build_info.gd")

const HEARTBEAT_SECS := 30.0

var world: RefCounted = null
var dev_profile := false
var scenario_id := ""

var _session_id := ""
var _beat_accum := 0.0
var _started_unix := 0


## One appender for the whole evidence stream (recap tracker predates it
## and keeps its own; new writers use this).
static func append_line(line: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://logs"))
	var f := FileAccess.open("user://logs/session.jsonl", FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open("user://logs/session.jsonl", FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(line))
	f.close()


func _ready() -> void:
	_started_unix = int(Time.get_unix_time_from_system())
	# Unique enough per machine: wall second + a run-scoped suffix. NOT
	# sim data — uniqueness only has to hold within one tester's log.
	_session_id = "%d-%d" % [_started_unix, Time.get_ticks_msec() % 1000]
	append_line(
		{
			"kind": "session_start",
			"session": _session_id,
			"utc": Time.get_datetime_string_from_system(true),
			"unix": _started_unix,
			"build": BuildInfo.BUILD_ID,
			"dev_profile": dev_profile,
			"scenario": scenario_id,
		}
	)


func _process(delta: float) -> void:
	_beat_accum += delta
	if _beat_accum < HEARTBEAT_SECS:
		return
	_beat_accum = 0.0
	append_line(
		{
			"kind": "session_heartbeat",
			"session": _session_id,
			"unix": int(Time.get_unix_time_from_system()),
			"secs": int(Time.get_unix_time_from_system()) - _started_unix,
			"replay_dirty": world != null and bool(world.replay_dirty),
		}
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		close_session()


## Idempotent: the scene rebuild (T reset) frees this node — PREDELETE
## writes the end line for that session; the fresh node starts the next.
func close_session() -> void:
	if _session_id.is_empty():
		return
	append_line(
		{
			"kind": "session_end",
			"session": _session_id,
			"unix": int(Time.get_unix_time_from_system()),
			"secs": int(Time.get_unix_time_from_system()) - _started_unix,
		}
	)
	_session_id = ""
