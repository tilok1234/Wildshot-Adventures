extends SceneTree
## Feedback bundle + summary code contract test (M8): fixture jsonl in,
## exact code out; dev-session contamination excluded; alt-F4 session
## bounded by its last heartbeat; zip contains the evidence + info stamp;
## decoder-facing checksum stable. Exit 0 = green.

const FeedbackBundle := preload("res://game/drivers/feedback_bundle.gd")

const FIXTURE := "user://logs/test_feedback_fixture.jsonl"

var fails: Array[String] = []


func check(cond: bool, name: String) -> void:
	if not cond:
		fails.append(name)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://logs"))
	# sl-0201 (the CI repair's third find): save_bundle packs
	# BUNDLE_FILES — on a dev machine those real logs always exist, so
	# this test silently rode the DEVELOPER'S OWN session.jsonl; on a
	# pristine runner none exist and the bundle came back empty
	# ("no evidence files found"). Provision any ABSENT evidence file
	# with fixture bytes (real logs are NEVER touched) and sweep only
	# what we created at the end — the packing checks now mean the
	# same thing in both environments.
	var provisioned: Array[String] = []
	for src: String in FeedbackBundle.BUNDLE_FILES:
		if not FileAccess.file_exists(src):
			var pf := FileAccess.open(src, FileAccess.WRITE)
			pf.store_line('{"kind": "ci_fixture"}')
			pf.close()
			provisioned.append(src)
	var lines := [
		# tester session 1: 10 min clean close, one death, two kills
		{"kind": "session_start", "dev_profile": false, "unix": 1000},
		{"kind": "enemy_kill", "tick": 100},
		{"death_tick": 500},
		{"kind": "enemy_kill", "tick": 900},
		{"kind": "session_end", "unix": 1600},
		# dev session between: everything inside must be excluded
		{"kind": "session_start", "dev_profile": true, "unix": 2000},
		{"death_tick": 100},
		{"kind": "enemy_kill", "tick": 50},
		{"kind": "session_end", "unix": 5000},
		# tester session 2: alt-F4 — no end line; last heartbeat bounds it
		{"kind": "session_start", "dev_profile": false, "unix": 6000},
		{"kind": "session_heartbeat", "unix": 6300},
		{"death_tick": 700},
	]
	var f := FileAccess.open(FIXTURE, FileAccess.WRITE)
	for l: Dictionary in lines:
		f.store_line(JSON.stringify(l))
	f.close()

	var totals := FeedbackBundle.scan_log(FIXTURE)
	check(int(totals.minutes) == 15, "minutes 10+5 == 15 (got %d)" % int(totals.minutes))
	check(int(totals.sessions) == 2, "tester sessions == 2 (got %d)" % int(totals.sessions))
	check(int(totals.deaths) == 2, "deaths exclude dev (got %d)" % int(totals.deaths))
	check(int(totals.kills) == 2, "kills exclude dev (got %d)" % int(totals.kills))

	# Exact code pin: 15 min, 2 sessions, 2 deaths, 2 kills.
	var code := FeedbackBundle.encode_code(15, 2, 2, 2)
	check(code == FeedbackBundle.summary_code(FIXTURE), "summary_code matches scan")
	check(code.begins_with("WS1-") and code.length() == 17, "code shape (got %s)" % code)
	var body := code.replace("WS1-", "").replace("-", "")
	var sum := 0
	for i in 10:
		sum += FeedbackBundle.B32.find(body[i])
	check(body[10] == FeedbackBundle.B32[sum % 32], "checksum char")

	# Zero/cap behavior stays inside the format.
	check(FeedbackBundle.encode_code(0, 0, 0, 0).length() == 17, "zero code shape")
	check(
		FeedbackBundle.encode_code(999999, 9999, 9999, 999999).length() == 17, "capped code shape"
	)

	# Bundle zip: fixture-only log path, temp destination. No comment →
	# no comments.txt, comment_chars 0.
	var dest := ProjectSettings.globalize_path("user://logs")
	var result := FeedbackBundle.save_bundle(dest, FIXTURE)
	check(bool(result.ok), "bundle ok (%s)" % String(result.get("error", "")))
	var reader := ZIPReader.new()
	if reader.open(String(result.path)) == OK:
		var names := reader.get_files()
		check("bundle_info.json" in names, "zip has bundle_info.json")
		check("session.jsonl" in names, "zip has session.jsonl")
		check(not "comments.txt" in names, "no comments.txt without a comment")
		var info: Variant = JSON.parse_string(
			reader.read_file("bundle_info.json").get_string_from_utf8()
		)
		check(
			(
				info != null
				and String(info.get("summary_code", "")) == FeedbackBundle.summary_code(FIXTURE)
			),
			"bundle_info carries the bundled log's summary code"
		)
		check(info != null and int(info.get("comment_chars", -1)) == 0, "comment_chars 0")
		reader.close()
	else:
		check(false, "zip readable")
	DirAccess.remove_absolute(String(result.path))

	# Comment ride-along (M8 comments box): trimmed text lands as
	# comments.txt; the stamp counts its chars. SUPPLEMENTARY by
	# quiet-lab law — the zip carries it, nothing counts it as CORE-54
	# evidence.
	var result2 := FeedbackBundle.save_bundle(dest, FIXTURE, "  the wolves feel fair  ")
	check(bool(result2.ok), "comment bundle ok")
	var reader2 := ZIPReader.new()
	if reader2.open(String(result2.path)) == OK:
		var names2 := reader2.get_files()
		check("comments.txt" in names2, "zip has comments.txt")
		var note := reader2.read_file("comments.txt").get_string_from_utf8()
		check(note == "the wolves feel fair", "comment trimmed verbatim (got '%s')" % note)
		var info2: Variant = JSON.parse_string(
			reader2.read_file("bundle_info.json").get_string_from_utf8()
		)
		check(
			info2 != null and int(info2.get("comment_chars", -1)) == note.length(),
			"comment_chars matches"
		)
		reader2.close()
	else:
		check(false, "comment zip readable")
	DirAccess.remove_absolute(String(result2.path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE))
	for src: String in provisioned:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(src))

	if fails.is_empty():
		print("feedback_bundle_test: PASS (scan/exclusion/code/checksum/zip/comment)")
		quit(0)
	else:
		for m: String in fails:
			printerr("feedback_bundle_test FAIL: " + m)
		quit(1)
