extends RefCounted
## Feedback bundle + summary code (docs/12 §4 M8): the tester evidence
## return path. save_bundle() zips the evidence stream + settings beside a
## bundle_info stamp into a findable location (Desktop by default);
## summary_code() compresses the machine's TESTER-session totals into a
## short paste-able code for testers who will not return files. Both are
## view/telemetry-side; the sim never sees any of this.
##
## Summary code format (Crockford base32, no I/L/O/U):
##   WS1-MMM-SSDD-KKKC
##   MMM = total tester minutes (capped 32767)   SS = session count (1023)
##   DD  = death count (capped 1023)             KKK = enemy kills (32767)
##   C   = checksum char (sum of value chars mod 32)
## Dev-profile sessions (session_start.dev_profile true) and every line
## inside their windows are EXCLUDED — contamination auto-exclusion is
## encode-side law, not a decoder courtesy. tools/decode_summary_code.py
## mirrors this format.

const BuildInfo := preload("res://build_info.gd")

const B32 := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
const SESSION_LOG := "user://logs/session.jsonl"
const BUNDLE_FILES: Array[String] = [
	"user://logs/session.jsonl",
	"user://logs/terrain.jsonl",
	"user://settings.cfg",
]


## Zip the evidence into dest_dir (default: the OS desktop). Returns
## {ok, path, code, error}. A non-empty comment rides along as
## comments.txt — SUPPLEMENTARY by quiet-lab law: never CORE-54
## evidence (that stays the unprompted Discord/itch harvest).
static func save_bundle(dest_dir := "", log_path := SESSION_LOG, comment := "") -> Dictionary:
	var dir := dest_dir
	if dir.is_empty():
		dir = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	if dir.is_empty():
		dir = OS.get_user_data_dir()
	var stamp := Time.get_datetime_string_from_system(true).replace(":", "").replace("-", "")
	var code := summary_code(log_path)
	var zip_path := dir.path_join("wildshot-feedback-%s-%s.zip" % [BuildInfo.BUILD_ID, stamp])
	var packer := ZIPPacker.new()
	var err := packer.open(zip_path)
	if err != OK:
		return {"ok": false, "path": zip_path, "code": code, "error": "cannot write zip (%d)" % err}
	var packed := 0
	for src: String in BUNDLE_FILES:
		var bytes := FileAccess.get_file_as_bytes(src)
		if bytes.is_empty():
			continue
		packer.start_file(src.get_file())
		packer.write_file(bytes)
		packer.close_file()
		packed += 1
	var note := comment.strip_edges()
	if not note.is_empty():
		packer.start_file("comments.txt")
		packer.write_file(note.to_utf8_buffer())
		packer.close_file()
	var info := {
		"build": BuildInfo.BUILD_ID,
		"utc": Time.get_datetime_string_from_system(true),
		"summary_code": code,
		"files": packed,
		"comment_chars": note.length(),
	}
	packer.start_file("bundle_info.json")
	packer.write_file(JSON.stringify(info, "\t").to_utf8_buffer())
	packer.close_file()
	packer.close()
	return {
		"ok": packed > 0,
		"path": zip_path,
		"code": code,
		"error": "" if packed > 0 else "no evidence files found"
	}


## Machine totals from the evidence stream, tester sessions only.
static func summary_code(log_path := SESSION_LOG) -> String:
	var totals := scan_log(log_path)
	return encode_code(
		int(totals.minutes), int(totals.sessions), int(totals.deaths), int(totals.kills)
	)


## Walk the jsonl once: session windows from start/heartbeat/end lines
## (last beat bounds an alt-F4'd session), dev windows excluded together
## with every recap/kill line falling inside them. Recap lines predate
## the "kind" field — a death is any line with death_tick.
static func scan_log(log_path: String) -> Dictionary:
	var out := {"minutes": 0, "sessions": 0, "deaths": 0, "kills": 0}
	var text := FileAccess.get_file_as_string(log_path)
	if text.is_empty():
		return out
	var dev_open := false
	var secs_total := 0
	var open_start := -1
	var open_last := -1
	for raw: String in text.split("\n", false):
		var line: Variant = JSON.parse_string(raw)
		if line == null:
			continue
		var d: Dictionary = line
		match String(d.get("kind", "")):
			"session_start":
				if open_start >= 0 and not dev_open:
					secs_total += open_last - open_start
				dev_open = bool(d.get("dev_profile", false))
				open_start = int(d.get("unix", -1))
				open_last = open_start
				if not dev_open:
					out.sessions += 1
			"session_heartbeat", "session_end":
				open_last = int(d.get("unix", open_last))
			_:
				if dev_open:
					continue
				if d.has("death_tick"):
					out.deaths += 1
				elif String(d.get("kind", "")) == "enemy_kill":
					out.kills += 1
	if open_start >= 0 and not dev_open:
		secs_total += open_last - open_start
	out.minutes = secs_total / 60
	return out


static func encode_code(minutes: int, sessions: int, deaths: int, kills: int) -> String:
	var body := (
		_b32(clampi(minutes, 0, 32767), 3)
		+ _b32(clampi(sessions, 0, 1023), 2)
		+ _b32(clampi(deaths, 0, 1023), 2)
		+ _b32(clampi(kills, 0, 32767), 3)
	)
	var sum := 0
	for i in body.length():
		sum += B32.find(body[i])
	var chk := B32[sum % 32]
	return "WS1-%s-%s-%s" % [body.substr(0, 3), body.substr(3, 4), body.substr(7, 3) + chk]


static func _b32(v: int, width: int) -> String:
	var s := ""
	var x := v
	for _i in width:
		s = B32[x % 32] + s
		x /= 32
	return s
