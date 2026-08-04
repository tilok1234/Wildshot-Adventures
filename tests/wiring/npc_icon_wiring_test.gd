extends SceneTree
## SEAM-4 WIRING contracts (sl-0100; packs cleared by sl-0098): the
## consumed NPC tree (res://npcs/ — importer-translated manifest in
## the assembler_library shape) builds SpriteFrames for all 32 looks;
## stations are deterministic, zone-matched, and walkable on the real
## b77 grid; the consumed icon atlas serves every id the UI requests.
## NEGATIVE-TESTED (corrupt manifest refused; unknown icon id nulls
## loudly). Exit 0 = green.

const AssemblerLibrary := preload("res://game/views/assembler_library.gd")
const NpcView := preload("res://game/views/npc_view.gd")
const NpcNameplates := preload("res://game/views/npc_nameplates.gd")
const IconAtlas := preload("res://ui/icon_atlas.gd")
const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")

const CONTENT_PACK := "res://assets/wildshot-overworld-pack-dusk-content/"
const SPAWN := Vector2(109.5, 182.5)

var fails: Array[String] = []


func check(cond: bool, name: String) -> void:
	if not cond:
		fails.append(name)


func _init() -> void:
	# 1. The consumed NPC tree: manifest + all 32 sheets + frames.
	var lib: RefCounted = AssemblerLibrary.new()
	lib.manifest_path = "res://npcs/manifest.json"
	lib.sheet_root = "res://npcs/"
	check(lib.load_manifest(), "npc manifest loads (run tools/import_npcs.py)")
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://npcs/manifest.json")
	)
	check(manifest is Dictionary, "npc manifest parses")
	var md: Dictionary = manifest
	check(int(md.cell) == 24 and int(md.export_scale) == 1, "24px @1x — the enemy-pack scale")
	var contract: Dictionary = md.frame_contract
	var dirs: Array = contract.dirs
	var anims: Array = contract.anims
	check(dirs.size() == 4, "four directions")
	var cols := 0
	for a: Dictionary in anims:
		cols += int(a.frames)
	check(cols == 20, "anim spans fill the 20-column sheet")
	var actors: Array = md.actors
	check(actors.size() == 32, "32 looks (13 named + 10 givers + 9 ambient)")
	var groups := {}
	for a: Dictionary in actors:
		groups[a.group] = int(groups.get(a.group, 0)) + 1
		var frames: SpriteFrames = lib.build_sprite_frames(String(a.id))
		if frames == null:
			fails.append("frames build: " + String(a.id))
			continue
		check(frames.has_animation("idle-down"), "idle-down exists: " + String(a.id))
		check(frames.has_animation("death-down"), "real death row rides: " + String(a.id))
	check(int(groups.get("named-role", 0)) == 13, "13 named roles")
	check(int(groups.get("zone-quest-giver", 0)) == 10, "10 zone quest-givers")
	check(int(groups.get("ambient-villager", 0)) == 9, "9 ambient villagers")

	# 2. Stations: deterministic, zone-matched, walkable on real b77.
	var wf := WorldforgePack.validate("res://assets/worldforge-packs/wildshot-overworld-pack-dusk/")
	check(bool(wf.ok), "b77 validates")
	if bool(wf.ok):
		var plan: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(CONTENT_PACK + "content-plan.json")
		)
		var grid: RefCounted = wf.bitgrid
		var st_a: Array = NpcView.compute_stations(md, plan, grid, SPAWN)
		var st_b: Array = NpcView.compute_stations(md, plan, grid, SPAWN)
		check(st_a.size() == 32, "all 32 looks get a station")
		check(JSON.stringify(str(st_a)) == JSON.stringify(str(st_b)), "stations deterministic")
		var giver_points: Array[Vector2] = []
		var givers: Array = plan.get("giverSlots", [])
		for g: Dictionary in givers:
			var gid := String(g.get("id", ""))
			if not gid.begins_with("giver.zone."):
				continue
			var cell: Array = g.get("cell", [0, 0])
			giver_points.append(Vector2(float(int(cell[0])) + 0.5, float(int(cell[1])) + 0.5))
		var at_giver := 0
		var near_spawn := 0
		for st: Dictionary in st_a:
			var c: Vector2 = st.cell
			check(not grid.is_solid(int(floorf(c.x)), int(floorf(c.y))), "station walkable")
			for gp: Vector2 in giver_points:
				if c.distance_to(gp) <= 5.0:
					at_giver += 1
					break
			if c.distance_to(SPAWN) <= 30.0:
				near_spawn += 1
		check(
			at_giver >= 8,
			"zone quest-givers stand at their giver slots, nudge-tolerant (%d)" % at_giver
		)
		check(near_spawn >= 20, "the settlement crowd gathers at the capital (%d)" % near_spawn)

		# sl-0176: the giver map (authored def cell -> body station
		# cell) that anchors overhead icons to the body the player
		# actually sees. Every zone-giver/pinned station answers for
		# its authored cell; nudges stay small; the Green givers stand
		# at their authored cells; the dry caravan scout is the pack's
		# REAL doorstep nudge (per-pack pin, b77 — a pack drop that
		# moves it gets re-pinned deliberately, never silently).
		var gmap: Dictionary = NpcView.giver_cell_map(st_a)
		check(gmap.size() >= 10, "giver map covers zone givers + pinned bodies (%d)" % gmap.size())
		for def_cell: Vector2 in gmap:
			var body: Vector2 = gmap[def_cell]
			check(
				def_cell.distance_to(body) <= 4.5,
				"giver body within nudge reach of its authored cell (%s)" % str(def_cell)
			)
			check(
				not grid.is_solid(int(floorf(body.x)), int(floorf(body.y))),
				"giver-map body cell walkable (%s)" % str(body)
			)
		check(
			gmap.get(Vector2(91.5, 110.5)) == Vector2(91.5, 110.5),
			"green waystation giver stands at its authored cell"
		)
		check(
			gmap.get(Vector2(25.5, 251.5)) == Vector2(25.5, 250.5),
			"dry caravan scout nudge carried into the giver map (b77 pin)"
		)
		# sl-0204: the capital hub giver — def stays the spawn-parked
		# authored cell (the sim's interact truth), the BODY pins one
		# cell north; the errand bang rides a giver's head at last.
		check(
			gmap.get(Vector2(109.5, 182.5)) == Vector2(109.5, 181.5),
			"capital hub giver body pinned one cell off the spawn (sl-0204)"
		)
		var hub_st := {}
		for st: Dictionary in st_a:
			if String(st.id) == "warden-representative":
				hub_st = st
		check(
			hub_st.has("def_cell") and hub_st.def_cell == Vector2(109.5, 182.5),
			"the Wardens' representative answers for the capital slot"
		)
		check(
			NpcNameplates.label_for("warden-representative", {}) == "Quest Giver",
			"the hub giver plates as Quest Giver (zero authoring)"
		)
		# sl-0205: the kit font's own license line is the law — "use at
		# 10 px (or integer multiples)". Off-grid sizes mangle the
		# strict-grid glyphs (AA/hinting/subpixel are OFF by kit spec).
		check(
			int(NpcNameplates.FONT_SIZE) >= 10 and int(NpcNameplates.FONT_SIZE) % 10 == 0,
			"plate text renders on the kit font's 10px grid (sl-0205)"
		)

		# sl-0190: NAMEPLATES — the plated set is EXACTLY the
		# def_cell-carrying stations (the interactable-bodied class:
		# pinned bodies + zone givers); the crowd is STRUCTURALLY
		# unlabeled (no def_cell) and the bodiless capital slot never
		# appears (not a body). Role labels derive from the interact
		# registry; the designer's name table wins when filled
		# (data-only, data/npc_names.json).
		var plated: Array[Dictionary] = NpcNameplates.plated(st_a)
		check(plated.size() == gmap.size(), "plates == interactable bodies (%d)" % plated.size())
		var plate_ids := {}
		for pst: Dictionary in plated:
			plate_ids[String(pst.id)] = true
		for pid: String in NpcNameplates.ROLE_LABELS:
			check(plate_ids.has(pid), "pinned station plated: " + pid)
		check(NpcNameplates.label_for("capital-stash-keeper", {}) == "Banker", "bank role word")
		check(NpcNameplates.label_for("settlement-trader", {}) == "Trader", "trader role word")
		check(
			NpcNameplates.label_for("capital-general-merchant", {}) == "Merchant",
			"merchant role word"
		)
		check(
			NpcNameplates.label_for("dock-fisher-teacher", {}) == "Tackle Keeper",
			"tackle role word"
		)
		check(
			NpcNameplates.label_for("green-zone-giver-x", {}) == "Quest Giver",
			"giver fallback role word (zero authoring)"
		)
		check(
			(
				NpcNameplates.label_for("capital-stash-keeper", {"capital-stash-keeper": "Maro"})
				== "Maro"
			),
			"the name table wins (the designer's proper-name hook)"
		)
		check(
			NpcNameplates.load_name_table().is_empty(),
			"npc_names.json ships EMPTY (role labels rule v1)"
		)
		var crowd_plated := 0
		for st: Dictionary in st_a:
			if not st.has("def_cell") and plate_ids.has(String(st.id)):
				crowd_plated += 1
		check(crowd_plated == 0, "the crowd is never plated")

	# 3. Icons: every id the UI requests exists and cuts a region.
	var need: Array[String] = ["currency.gold"]
	for fam: String in [
		"item.weapon.sword.arming", "item.weapon.bow.recurve", "item.weapon.staff.longstaff"
	]:
		for t in range(1, 6):
			need.append("%s.t%d" % [fam, t])
	for id: String in need:
		check(IconAtlas.has_icon(id), "icon exists: " + id)
		var tex: Texture2D = IconAtlas.icon(id)
		check(tex != null and tex.get_width() == 16, "icon cuts 16px: " + id)

	# 4. Negatives: corrupt manifest refused; unknown icon id nulls.
	var bad_dir := "user://wiring_test/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(bad_dir))
	var bf := FileAccess.open(bad_dir + "manifest.json", FileAccess.WRITE)
	bf.store_string("{ broken")
	bf.close()
	var bad_lib: RefCounted = AssemblerLibrary.new()
	bad_lib.manifest_path = bad_dir + "manifest.json"
	bad_lib.sheet_root = bad_dir
	check(not bad_lib.load_manifest(), "corrupt npc manifest refused")
	check(IconAtlas.icon("no.such.icon") == null, "unknown icon id returns null, loudly")

	# NEVER-BIND PIN (sl-0123 sweep item; correction #8 — the arena
	# part of starhooking has NO coined name, and the glyph's is one):
	# the icon pack's 'item.unique.undertow' glyph stays pack data and
	# is NEVER bound — no game/ui/data source may reference its id.
	# The glyph itself remaining in the atlas is fine (vendored packs
	# are immutable); BINDING it is the violation.
	var banned := "item.unique." + "undertow"
	for scan_dir: String in ["res://game", "res://ui", "res://input", "res://sim", "res://data"]:
		_scan_for_banned(scan_dir, banned)

	if fails.is_empty():
		print("npc_icon_wiring_test: PASS (npcs/stations/icons/never-bind/negatives)")
		quit(0)
	else:
		for m: String in fails:
			printerr("npc_icon_wiring_test FAIL: " + m)
		quit(1)


## Recursive source scan for a banned glyph id (never-bind pin).
func _scan_for_banned(dir_path: String, banned: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		var full := dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_scan_for_banned(full, banned)
		elif entry.ends_with(".gd") or entry.ends_with(".tres") or entry.ends_with(".json"):
			if FileAccess.get_file_as_string(full).contains(banned):
				fails.append("never-bind violated: %s references '%s'" % [full, banned])
		entry = dir.get_next()
	dir.list_dir_end()
