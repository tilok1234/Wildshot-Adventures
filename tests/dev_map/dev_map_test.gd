extends SceneTree
## sl-0065 dev-map consumer test (fixed gate): every scenario that
## names a WorldForge pack must ship the pack's own minimap.png (raw,
## loadable, uniformly grid-proportional — the pack-relative mapping
## contract the overlay draws with), and pack-less scenarios must
## resolve to NO minimap path (the overlay hides by absence). Also
## pins the overlay's one pure mapping function, its load-refusal
## contract, (sl-0175) the quest-marker model: available givers
## (bang), turn-in givers (ring, wins per cell), tracked-quest VISIT
## objectives (diamond) with tracker-identical binding, and
## (sl-0218) the activity-indicator models: KILL/COLLECT soft
## REGIONS (nearest-cluster over synthetic sites — exact geometry
## pins) and the quest-mob mark def set (tracker-identical binding,
## KILL only). Pure JSON/PNG reads + pure statics over stub state —
## Linux-safe.
##
## Run: godot --headless --path . --script tests/dev_map/dev_map_test.gd

const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const MapOverlay := preload("res://game/dev/map_overlay.gd")
const QuestMobMarks := preload("res://game/views/quest_mob_marks.gd")

const CAPITAL := Vector2(109.5, 182.5)
const WAYSTATION := Vector2(91.5, 110.5)
const SHEPHERD := Vector2(18.5, 13.5)


class StubPlayer:
	var pos := Vector2.ZERO
	var class_id := 1
	var quests_taken_mask := 0
	var quests_done_mask := 0
	var quest_progress_arr := PackedInt32Array()


class StubWorld:
	var players: Array = []
	var quest_defs: Array = []
	var site_defs: Array = []


## Synthetic sites with controlled geometry (sl-0218): A/B form a
## bandit pair 10 t apart near the waystation, C is a far unlinked
## bandit camp, D a shroom-only pocket beside the station, E an
## empty-roster site (matches nothing, not even COLLECT).
static func _stub_sites(w: StubWorld) -> StubWorld:
	w.site_defs = [
		{"cell": Vector2(100.0, 100.0), "roster_defs": PackedInt32Array([21])},
		{"cell": Vector2(110.0, 100.0), "roster_defs": PackedInt32Array([21])},
		{"cell": Vector2(200.0, 200.0), "roster_defs": PackedInt32Array([21])},
		{"cell": Vector2(95.0, 105.0), "roster_defs": PackedInt32Array([13])},
		{"cell": Vector2(90.0, 90.0), "roster_defs": PackedInt32Array()},
	]
	return w


static func _stub(taken: int, prog: PackedInt32Array, class_id := 1) -> StubWorld:
	var w := StubWorld.new()
	var p := StubPlayer.new()
	p.class_id = class_id
	p.quests_taken_mask = taken
	p.quest_progress_arr = prog
	w.players = [p]
	for qp: String in [
		"res://data/quests/green_cull.tres",
		"res://data/quests/green_mud_pocket.tres",
		"res://data/quests/green_west_road.tres",
		"res://data/quests/green_provisions.tres",
		"res://data/quests/green_far_field.tres",
	]:
		w.quest_defs.append(load(qp))
	return w


static func _kind_cells(markers: Array, kind: String) -> Array:
	var out: Array = []
	for m: Dictionary in markers:
		if String(m.kind) == kind:
			out.append(m.cell)
	return out


func _init() -> void:
	var failed := false
	var pack_rows := 0
	var packless_rows := 0
	for f in DirAccess.get_files_at("res://data/scenarios"):
		var fname := String(f).trim_suffix(".remap")
		if not fname.ends_with(".tres"):
			continue
		var sc: Resource = load("res://data/scenarios/" + fname)
		if String(sc.worldforge_pack).is_empty():
			packless_rows += 1
			continue
		# The same routing main's _scenario_minimap_path performs (main
		# cannot compile under --script — it reads the Config autoload —
		# so the contract is replicated; the lint + boot gates pin
		# main's side).
		var src := WorldforgePack.resolve_src(String(sc.worldforge_pack))
		var mm_path := src + "minimap.png"
		pack_rows += 1
		if not FileAccess.file_exists(mm_path):
			printerr("FAIL: %s pack ships no minimap.png (%s)" % [fname, mm_path])
			failed = true
			continue
		var img := Image.load_from_file(mm_path)
		if img == null or img.is_empty():
			printerr("FAIL: %s minimap.png does not load" % fname)
			failed = true
			continue
		var manifest: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(src + "manifest.json")
		)
		var gw := int(manifest.dimensions.width)
		var gh := int(manifest.dimensions.height)
		var rx := float(img.get_width()) / float(gw)
		var ry := float(img.get_height()) / float(gh)
		if rx <= 0.0 or not is_equal_approx(rx, ry):
			printerr(
				(
					"FAIL: %s minimap %dx%d vs grid %dx%d — a non-uniform ratio skews the dot"
					% [fname, img.get_width(), img.get_height(), gw, gh]
				)
			)
			failed = true
		var wjson: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(src + "walkability.json")
		)
		var spawn_arr: Array = wjson.get("spawnCell", [0, 0])
		var spawn := Vector2(float(spawn_arr[0]), float(spawn_arr[1]))
		var px := MapOverlay.tile_to_map_px(
			spawn, Vector2i(gw, gh), Vector2i(img.get_width(), img.get_height())
		)
		var in_tex := (
			px.x >= 0.0
			and px.y >= 0.0
			and px.x < float(img.get_width())
			and px.y < float(img.get_height())
		)
		if not in_tex:
			printerr("FAIL: %s spawn %s maps outside the texture (%s)" % [fname, spawn, px])
			failed = true
		print(
			(
				"dev_map: %s -> %dx%d px over %dx%d cells (ratio %.2f)"
				% [fname, img.get_width(), img.get_height(), gw, gh, rx]
			)
		)
	if pack_rows < 2:
		printerr(
			(
				"FAIL: expected >=2 pack-routed scenarios (world_walk + overworld_walk), got %d"
				% pack_rows
			)
		)
		failed = true
	if packless_rows == 0:
		printerr("FAIL: expected at least one arena-built scenario in the picker")
		failed = true

	# Mapping-math pins (the overlay's one pure function).
	var ident := MapOverlay.tile_to_map_px(
		Vector2(109.5, 182.5), Vector2i(256, 256), Vector2i(256, 256)
	)
	if ident != Vector2(109.5, 182.5):
		printerr("FAIL: identity mapping drifted (%s)" % ident)
		failed = true
	var doubled := MapOverlay.tile_to_map_px(
		Vector2(10, 20), Vector2i(256, 256), Vector2i(512, 512)
	)
	if doubled != Vector2(20, 40):
		printerr("FAIL: 2x-texture mapping drifted (%s)" % doubled)
		failed = true

	# Hide-by-absence: the overlay refuses empty/missing paths.
	var ov: Control = MapOverlay.new()
	var bad: bool = ov.load_minimap("") or ov.load_minimap("res://data/scenarios/nope/minimap.png")
	ov.free()
	if bad:
		printerr("FAIL: overlay accepted a missing minimap")
		failed = true

	# ---- sl-0175 quest-marker model pins (pure statics, real defs).
	# Fresh hands: every giver cell offers — three avail bangs (both
	# capital errands share one cell; both waystation errands share
	# one), zero rings, zero diamonds.
	var fresh: Array = MapOverlay.quest_markers(_stub(0, PackedInt32Array([0, 0, 0, 0, 0])))
	var fresh_avail: Array = _kind_cells(fresh, "avail")
	if fresh_avail.size() != 3 or fresh.size() != 3:
		printerr("FAIL: fresh-hands markers %s (want 3 avail only)" % str(fresh))
		failed = true
	for want: Vector2 in [CAPITAL, WAYSTATION, SHEPHERD]:
		if not fresh_avail.has(want):
			printerr("FAIL: fresh-hands avail marker missing at %s" % str(want))
			failed = true
	# The probe staging (mud done / west 3 of 6 / far carried): the
	# capital ring WINS over cull's avail at the shared cell; the
	# waystation still bangs (provisions untaken); the shepherd's only
	# errand is carried — no giver marker; far field's VISIT objective
	# diamonds; KILL west road honestly draws nothing.
	var staged: Array = MapOverlay.quest_markers(_stub(0b10110, PackedInt32Array([0, 1, 3, 0, 0])))
	var ok_staged: bool = (
		staged.size() == 3
		and _kind_cells(staged, "turn_in") == [CAPITAL]
		and _kind_cells(staged, "avail") == [WAYSTATION]
		and _kind_cells(staged, "objective") == [Vector2(108.5, 138.5)]
	)
	if not ok_staged:
		printerr("FAIL: staged markers drifted: %s" % str(staged))
		failed = true
	# Tracked binding == the HUD tracker's: two carried VISIT errands
	# diamond both untracked; tracking one narrows objectives to it;
	# tracking an untaken id falls back to all; tracking a carried
	# COMPLETE errand yields no diamond (the ring is the guidance).
	var two_visits := 0b10010
	var zeros := PackedInt32Array([0, 0, 0, 0, 0])
	if _kind_cells(MapOverlay.quest_markers(_stub(two_visits, zeros)), "objective").size() != 2:
		printerr("FAIL: untracked should diamond every carried VISIT errand")
		failed = true
	var only_far: Array = _kind_cells(
		MapOverlay.quest_markers(_stub(two_visits, zeros), "green_far_field"), "objective"
	)
	if only_far != [Vector2(108.5, 138.5)]:
		printerr("FAIL: tracked far_field should narrow objectives to it (%s)" % str(only_far))
		failed = true
	var untaken_track: Array = _kind_cells(
		MapOverlay.quest_markers(_stub(two_visits, zeros), "green_cull"), "objective"
	)
	if untaken_track.size() != 2:
		printerr("FAIL: tracking an untaken id must fall back to all carried")
		failed = true
	var done_track: Array = MapOverlay.quest_markers(
		_stub(0b00010, PackedInt32Array([0, 1, 0, 0, 0])), "green_mud_pocket"
	)
	if not (
		_kind_cells(done_track, "objective").is_empty()
		and _kind_cells(done_track, "turn_in") == [CAPITAL]
	):
		printerr("FAIL: tracked complete errand should ring, never diamond (%s)" % str(done_track))
		failed = true
	# Legacy lane draws nothing (labs and proofs stay marker-free).
	if not MapOverlay.quest_markers(_stub(0b10110, zeros, -1)).is_empty():
		printerr("FAIL: legacy-lane player must draw zero markers")
		failed = true

	# ---- sl-0218 region model pins (synthetic sites, exact geometry).
	# west_road (KILL bandit=21) carried: seed = site A (nearest to the
	# waystation giver), links B (10 t <= LINK 15), never far C —
	# centroid (105,100), enclose 5, radius clamped up to R_MIN 10.
	var wr: Array = MapOverlay.quest_regions(_stub_sites(_stub(0b00100, zeros)))
	var ok_wr: bool = (
		wr.size() == 1
		and Vector2(wr[0].center) == Vector2(105.0, 100.0)
		and absf(float(wr[0].radius) - 10.0) < 0.01
	)
	if not ok_wr:
		printerr("FAIL: west_road region drifted: %s" % str(wr))
		failed = true
	# provisions (COLLECT) carried: any populated site matches (A/B/C/D,
	# never empty-roster E); seed D beside the station, links A then B —
	# centroid (305/3, 305/3), enclose 8.4984, radius 12.4984.
	var pv: Array = MapOverlay.quest_regions(_stub_sites(_stub(0b01000, zeros)))
	var ok_pv: bool = (
		pv.size() == 1
		and Vector2(pv[0].center).distance_to(Vector2(305.0 / 3.0, 305.0 / 3.0)) < 0.01
		and absf(float(pv[0].radius) - 12.4984) < 0.01
	)
	if not ok_pv:
		printerr("FAIL: provisions region drifted: %s" % str(pv))
		failed = true
	# Both carried -> two regions; tracked west_road narrows to one;
	# a finished-but-unturned errand renders no region (the ring is
	# the guidance); VISIT never regions (the diamond exists); legacy
	# and site-less worlds stay empty.
	if MapOverlay.quest_regions(_stub_sites(_stub(0b01100, zeros))).size() != 2:
		printerr("FAIL: two carried KILL/COLLECT errands should region both")
		failed = true
	var wr_tracked: Array = MapOverlay.quest_regions(
		_stub_sites(_stub(0b01100, zeros)), "green_west_road"
	)
	if not (wr_tracked.size() == 1 and Vector2(wr_tracked[0].center) == Vector2(105.0, 100.0)):
		printerr("FAIL: tracked west_road should narrow regions to it (%s)" % str(wr_tracked))
		failed = true
	if not (
		MapOverlay
		. quest_regions(_stub_sites(_stub(0b00100, PackedInt32Array([0, 0, 6, 0, 0]))))
		. is_empty()
	):
		printerr("FAIL: a complete unturned KILL errand must render no region")
		failed = true
	if not MapOverlay.quest_regions(_stub_sites(_stub(0b00010, zeros))).is_empty():
		printerr("FAIL: VISIT errands never region (the diamond is the guidance)")
		failed = true
	if not MapOverlay.quest_regions(_stub_sites(_stub(0b01100, zeros, -1))).is_empty():
		printerr("FAIL: legacy-lane player must render zero regions")
		failed = true
	if not MapOverlay.quest_regions(_stub(0b01100, zeros)).is_empty():
		printerr("FAIL: a site-less world must render zero regions")
		failed = true

	# ---- sl-0218 quest-mob mark model pins (tracker-identical
	# binding; KILL only; a finished errand un-marks its mobs).
	var both := 0b00101  # cull (9/11/21) + west_road (21)
	var marks: Dictionary = QuestMobMarks.marked_defs(_stub(both, zeros))
	if marks.size() != 3 or not (marks.has(9) and marks.has(11) and marks.has(21)):
		printerr("FAIL: carried KILL errands should mark the union (%s)" % str(marks))
		failed = true
	var narrowed: Dictionary = QuestMobMarks.marked_defs(_stub(both, zeros), "green_west_road")
	if narrowed.size() != 1 or not narrowed.has(21):
		printerr("FAIL: tracked west_road should narrow marks to bandit (%s)" % str(narrowed))
		failed = true
	var fallback: Dictionary = QuestMobMarks.marked_defs(_stub(both, zeros), "green_provisions")
	if fallback.size() != 3:
		printerr("FAIL: tracking an unbindable id must fall back to the union")
		failed = true
	var cull_done: Dictionary = QuestMobMarks.marked_defs(
		_stub(both, PackedInt32Array([8, 0, 0, 0, 0]))
	)
	if cull_done.size() != 1 or not cull_done.has(21):
		printerr("FAIL: a complete cull should un-mark its mobs (%s)" % str(cull_done))
		failed = true
	if not QuestMobMarks.marked_defs(_stub(0b11010, zeros)).is_empty():
		printerr("FAIL: VISIT/COLLECT errands never mark mobs")
		failed = true
	if not QuestMobMarks.marked_defs(_stub(both, zeros, -1)).is_empty():
		printerr("FAIL: legacy-lane player must mark zero mobs")
		failed = true

	print("dev map consumer test: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
