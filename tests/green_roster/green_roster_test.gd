extends SceneTree
## S1 GREEN ROSTER contracts (sl-0104 seam 1, docs/23 enemy split):
## - roster indexes 8..21 = the 14 Green families in docs/23 order
##   (append-only contract via the REAL ScenarioLoader path);
## - THE PATTERN->LEAD LAW roster-wide: one telegraph lead per pattern
##   id across every def, phase, and hazard (the recap keys lead by
##   pattern — sharing a pattern with a different lead would lie to
##   Law 8); NEGATIVE-TESTED;
## - Green rows stay inside the proven grammar: archetype patterns
##   only, proven policies, speeds under the 3.6 CORE-53 floor,
##   Green-band hp, xp set, equipment drops EMPTY (the seam-2
##   boundary — loot arrives with the T1 tables, deliberately);
## - variant map parity BOTH directions vs the raw catalog index (54
##   Green looks, docs/23 variability ruling) and every variant
##   imported in res://assembler/; NEGATIVE-TESTED;
## - the importer re-table on the vendored pack: green territories
##   re-tabled role-preservingly (weights integer-exact), density
##   1.5 applied, other zones byte-untouched, zone-table authority
##   refuses out-of-table ids loudly; NEGATIVE-TESTED;
## - the two green proof camps' premises pinned (site cells, roster
##   shapes, walkable bot spawns on the live b77 grid).
## Exit 0 = green.

const ScenarioLoader := preload("res://game/scenario_loader.gd")
const ContentImporter := preload("res://game/arena/content_importer.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const ArenaBuilder := preload("res://game/arena/arena_builder.gd")

const PACK := "res://assets/wildshot-overworld-pack-dusk-content/"
const WF_PACK := "res://assets/worldforge-packs/wildshot-overworld-pack-dusk/"
const FAMILY_INDEX := "res://assets/assembler-pack/indexes/enemy-families.json"

const GREEN_IDS: Array[String] = [
	"slime",
	"goblin",
	"boar",
	"wolf",
	"bat",
	"shroom",
	"wasp",
	"beetle",
	"moth",
	"snail",
	"porcupine",
	"scarecrow",
	"treant",
	"bandit",
]
## Green role -> catalog family (wolf/scarecrow/bandit families are
## shared with lab defs; the family is the sprite identity).
const GREEN_FAMILY := {
	"slime": "slime",
	"goblin": "goblin",
	"boar": "boar",
	"wolf": "wolf",
	"bat": "bat",
	"shroom": "shroom",
	"wasp": "wasp",
	"beetle": "beetle",
	"moth": "moth",
	"snail": "snail",
	"porcupine": "porcupine",
	"scarecrow": "scarecrow",
	"treant": "treant",
	"bandit": "bandit",
}
const PROVEN_PATTERNS := [10, 11, 12, 13, 14]  # + hazard 15 via slot.hazard
const PROVEN_POLICIES := [0, 1, 3, 4]  # CHASER/KEEP_RANGE/ANCHOR/FLANKER
const FLOOR_SPEED := 3.6

var fails: Array[String] = []


func check(cond: bool, name: String) -> void:
	if not cond:
		fails.append(name)


## One lead per pattern id across defs+phases; hazards key on their
## own pattern id and must agree on BOTH arm and slot windup. Returns
## the conflict list (empty = law holds).
func _lead_conflicts(defs: Array) -> Array[String]:
	var leads := {}
	var conflicts: Array[String] = []
	for def: Resource in defs:
		var slot_sets: Array = []
		if def.phases != null:
			for pe: Resource in def.phases.phases:
				slot_sets.append(pe.emitters)
		else:
			slot_sets.append(def.emitters)
		for slots: Array in slot_sets:
			for slot: Resource in slots:
				var key: String
				var val: String
				if slot.hazard != null:
					key = "hazard:%d" % int(slot.hazard.pattern_id)
					val = (
						"arm=%d windup=%d" % [int(slot.hazard.arm_ticks), int(slot.telegraph_ticks)]
					)
				else:
					key = "pattern:%d" % int(slot.pattern.pattern_id)
					val = "lead=%d" % int(slot.telegraph_ticks)
				if leads.has(key) and String(leads[key]) != val:
					conflicts.append(
						(
							"%s: %s has %s vs recorded %s"
							% [String(def.id), key, val, String(leads[key])]
						)
					)
				leads[key] = val
	return conflicts


func _site_at(sites: Array, x: float, y: float) -> Dictionary:
	for s: Dictionary in sites:
		var c: Vector2 = s.cell
		if c == Vector2(x, y):
			return s
	return {}


func _init() -> void:
	# 1. Roster contract through the REAL loader path.
	var grid: RefCounted = Bitgrid.new()
	grid.setup(96, 32)
	var world: RefCounted = ScenarioLoader.build_world(
		load("res://data/scenarios/lab_default.tres"), 1, grid
	)
	var defs: Array = world.enemy_defs
	check(defs.size() >= 22, "roster carries the Green 14 (>=22 defs)")
	for i in GREEN_IDS.size():
		check(
			String(defs[8 + i].id) == GREEN_IDS[i],
			"index %d = %s (docs/23 order)" % [8 + i, GREEN_IDS[i]]
		)

	# 2. THE PATTERN->LEAD LAW over the whole roster.
	var conflicts := _lead_conflicts(defs)
	for c: String in conflicts:
		printerr("pattern-lead conflict: " + c)
	check(conflicts.is_empty(), "one lead per pattern id across the whole roster")

	# 2n. NEGATIVE: a doctored lead must be caught and named.
	var doctored: Array = [load("res://data/enemies/rusher.tres")]
	var fake: Resource = load("res://data/enemies/rusher.tres").duplicate(true)
	fake.emitters[0].telegraph_ticks = 11
	doctored.append(fake)
	check(_lead_conflicts(doctored).size() == 1, "negative: lead mismatch is caught")

	# 3. Green rows stay inside the proven grammar.
	for i in GREEN_IDS.size():
		var d: Resource = defs[8 + i]
		var label := String(d.id)
		check(d.phases == null, label + ": ordinary (no phases)")
		check(float(d.move_speed) < FLOOR_SPEED, label + ": kiteable under the 3.6 floor")
		check(int(d.hp) >= 10 and int(d.hp) <= 48, label + ": Green-band hp")
		check(int(d.xp_value) > 0, label + ": xp set")
		# Seam 2 flipped the boundary pin DELIBERATELY: T1 loot is live.
		# Chances stay small-honest; tiers stay in the Green bracket
		# (T1, T2 trickle from the big bodies only).
		check(
			float(d.drop_chance) > 0.0 and float(d.drop_chance) <= 0.15,
			label + ": T1 drop chance live and small-honest"
		)
		check(
			int(d.drop_tier_min) == 1 and int(d.drop_tier_max) <= 2,
			label + ": drops stay in the Green bracket"
		)
		check(
			int(d.drop_w_ring) == 0 or int(d.drop_w_ring) > 0 and int(d.drop_tier_max) == 2,
			label + ": rings only from the big bodies"
		)
		check(int(d.movement_policy) in PROVEN_POLICIES, label + ": proven policy")
		for slot: Resource in d.emitters:
			if slot.hazard != null:
				check(
					int(slot.hazard.pattern_id) == 15, label + ": hazard is the proven blight zone"
				)
			else:
				check(
					int(slot.pattern.pattern_id) in PROVEN_PATTERNS,
					label + ": pattern from the proven archetype set"
				)

	# 4. Variant parity: sheet map vs the raw catalog index vs the
	# imported library — both directions, 54 total.
	var sheet_map: Resource = load("res://data/actor_sheet_map.tres")
	var fam_json: Variant = JSON.parse_string(FileAccess.get_file_as_string(FAMILY_INDEX))
	check(fam_json is Dictionary, "raw family index readable")
	var by_family := {}
	for f: Dictionary in fam_json.get("families", []):
		by_family[String(f.id)] = f
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://assembler/manifest.json")
	)
	var imported := {}
	for entry: Dictionary in manifest.get("actors", []):
		imported[String(entry.id)] = true
	var total_variants := 0
	for gid: String in GREEN_IDS:
		var role := "enemy_" + gid
		var fam := String(GREEN_FAMILY[gid])
		var fentry: Dictionary = by_family.get(fam, {})
		check(not fentry.is_empty(), role + ": family exists in the catalog")
		var want: Array[String] = []
		for v: Dictionary in fentry.get("variants", []):
			want.append(fam + ":" + String(v.id))
		var got_list: Array = sheet_map.variants.get(role, [])
		check(got_list.size() == want.size(), role + ": FULL variant list (docs/23 ruling)")
		for k in mini(got_list.size(), want.size()):
			check(String(got_list[k]) == want[k], role + ": variant %d matches catalog order" % k)
		for vid in got_list:
			check(imported.has(String(vid)), role + ": variant imported (" + String(vid) + ")")
		total_variants += got_list.size()
		var canonical := fam + ":" + String(fentry.get("default_variant", ""))
		check(
			String(sheet_map.map.get(role, "")) == canonical, role + ": canonical = family default"
		)
	check(total_variants == 54, "54 Green looks total (docs/23)")

	# 4n. NEGATIVE: an unlisted/unimported variant id must be caught.
	check(not imported.has("slime:nonexistent"), "negative: unknown variant not in the library")

	# 5. Importer re-table on the vendored pack.
	var got := ContentImporter.build_sites(PACK)
	check(bool(got.ok), "importer green on the vendored pack")
	var report: Dictionary = got.report
	var retabled: Dictionary = report.get("retabled", {})
	check(int(retabled.get("green", 0)) == 44, "all 44 green territories re-tabled")
	check(retabled.size() == 1, "ONLY green re-tabled (other zones untouched)")
	var sites: Array = got.sites
	# The known mixed territory: dry_grass.62657.0 (marauder 20 +
	# prowler 40, pack 2-6, maxActive 3) — integer-exact expansion +
	# density 1.5.
	var known := _site_at(sites, 202.5, 253.5)
	check(not known.is_empty(), "known mixed territory present (202,253)")
	if not known.is_empty():
		var kd: PackedInt32Array = known.roster_defs
		var kw: PackedInt32Array = known.roster_weights
		var want_defs := PackedInt32Array([8, 9, 11, 12, 15, 10, 17, 18, 21, 16, 14, 19, 20])
		var want_w := PackedInt32Array(
			[560, 400, 280, 240, 160, 120, 120, 120, 1280, 1040, 880, 480, 320]
		)
		check(kd == want_defs, "re-table defs integer-exact (role-preserving order)")
		check(kw == want_w, "re-table weights = placeholder x set, integer-exact")
		check(int(known.pack_min) == 3 and int(known.pack_max) == 9, "density 1.5 on pack size")
		check(int(known.max_active) == 5, "density 1.5 on max_active (3 -> 5)")
	# Zone discipline: green sites draw ONLY Green defs; non-green
	# sites stay on the flat vocab (0..7); bosses untouched.
	var green_ok := true
	var other_ok := true
	for s: Dictionary in sites:
		var rd: PackedInt32Array = s.roster_defs
		if String(s.kind) == "boss":
			# S1 seam 3: green's boss is OLD TUSK (def 22); other zones
			# keep the Warden stand-in until their chapters.
			var want_def := 22 if String(s.zone) == "green" else 6
			check(
				rd.size() == 1 and rd[0] == want_def,
				"boss site carries its zone's identity (green = Old Tusk)"
			)
			continue
		for di in rd:
			if String(s.zone) == "green":
				if di < 8 or di > 21:
					green_ok = false
			elif di < 0 or di > 7:
				other_ok = false
	check(green_ok, "green sites draw only the Green 14")
	check(other_ok, "non-green sites keep the flat vocab (0..7)")

	# 5n. NEGATIVE: zone-table authority — a green territory carrying a
	# valid FLAT id that is not in the green table must refuse loudly.
	var bad_dir := "user://green_roster_test/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(bad_dir))
	var terr_json: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(PACK + "territories.json")
	)
	for t: Dictionary in terr_json.territories:
		if String(t.id) == "territory.region.dry_grass.62657.0":
			t.roster[0].enemyId = "enemy.frost_wraith"
	for pair: Array in [
		["content-plan.json", FileAccess.get_file_as_string(PACK + "content-plan.json")],
		["territories.json", JSON.stringify(terr_json)],
		["placements.json", FileAccess.get_file_as_string(PACK + "placements.json")],
	]:
		var f := FileAccess.open(bad_dir + String(pair[0]), FileAccess.WRITE)
		f.store_string(String(pair[1]))
		f.close()
	var bad := ContentImporter.build_sites(bad_dir)
	check(not bool(bad.ok), "negative: out-of-table id in a re-tabled zone refuses the pack")

	# 6. The two green proof camps' premises hold on the live pack.
	var camp := _site_at(sites, 185.5, 244.5)
	check(not camp.is_empty(), "proof_green_camp site present (185,244)")
	if not camp.is_empty():
		var cd: PackedInt32Array = camp.roster_defs
		check(cd.size() == 13, "camp draws the full mixed table")
	var ranged := _site_at(sites, 108.5, 138.5)
	check(not ranged.is_empty(), "proof_green_ranged site present (108,138)")
	if not ranged.is_empty():
		var rd2: PackedInt32Array = ranged.roster_defs
		var ranged_only := true
		for di in rd2:
			if not (di in [21, 16, 14, 19, 20]):
				ranged_only = false
		check(ranged_only and rd2.size() == 5, "ranged camp draws the pure ranged set")
		check(int(camp.max_active) == 9, "camp density (6 -> 9)")
		check(int(ranged.max_active) == 8, "ranged camp density (5 -> 8)")
	var wf := WorldforgePack.validate(WF_PACK)
	check(bool(wf.ok), "b77 validates")
	if bool(wf.ok):
		var bg: RefCounted = wf.bitgrid
		check(not bg.is_solid(180, 244), "camp proof bot spawn walkable")
		check(not bg.is_solid(103, 138), "ranged proof bot spawn walkable")

	# 7. S1 seam 4 — THE WARREN: the committed-instance interior at
	# the pack's LOCKED green dungeon binding. Pins: the binding cell
	# is where the pack says (193,239, access 194,240), the arena
	# builds, EVERY authored spawn lands on floor (zero skipped —
	# scenario_loader skips solid-cell spawns loudly, so a count
	# mismatch = a layout bug), King Grubb sits at roster 23, and the
	# door table's cells are walkable on both sides.
	var plac_json: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(PACK + "placements.json")
	)
	var green_binding := Vector2i(-1, -1)
	var green_access := Vector2i(-1, -1)
	for pl: Dictionary in plac_json.placements:
		if String(pl.get("rule", "")) == "dungeon_binding.v1" and bool(pl.get("locked", false)):
			var cell: Array = pl.cell
			if String(pl.get("id", "")).contains("grass.54237"):
				green_binding = Vector2i(int(cell[0]), int(cell[1]))
				var ac: Array = pl.accessCell
				green_access = Vector2i(int(ac[0]), int(ac[1]))
	check(green_binding == Vector2i(193, 239), "green locked binding at 193,239")
	check(green_access == Vector2i(194, 240), "green binding access at 194,240")
	check(String(defs[23].id) == "king_grubb", "index 23 = king_grubb")

	# Menu pass seam G (sl-0156): the unique reveal's source predicate
	# is STRUCTURAL — unique drop tables ride PHASED BOSS defs only.
	# If a non-boss def ever grows a unique table, this pin goes red
	# FIRST and the pickup event gets real source plumbing then.
	for udi in defs.size():
		var ud: Resource = defs[udi]
		if not (ud.unique_drops as Array).is_empty():
			check(
				ud.phases != null,
				"def %d (%s): unique table on a phased boss only" % [udi, String(ud.id)]
			)
	var warren: Resource = load("res://data/scenarios/the_warren.tres")
	# The REAL collision derivation (walls + solid props + trees) —
	# the same path the battery's arena rows walk.
	var tf_manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://tileforge/tileforge-manifest.json")
	)
	var wdef := ArenaBuilder.load_def(String(warren.arena))
	check(not wdef.is_empty(), "warren arena json parses")
	var wgrid: RefCounted = Bitgrid.new()
	wgrid.setup(int(wdef.width), int(wdef.height))
	for c: Vector2i in ArenaBuilder.solid_cells(wdef, tf_manifest):
		wgrid.set_solid(c.x, c.y)
	var authored := 0
	var wspawns: Dictionary = warren.enemy_spawns
	for eid: String in wspawns:
		var pv: PackedVector2Array = wspawns[eid]
		authored += pv.size()
	var wworld: RefCounted = ScenarioLoader.build_world(warren, 7, wgrid)
	check(wworld.enemies.size() == authored, "every warren spawn lands on floor (zero skipped)")
	check(int(warren.persistent_world), "warren death = the CORE-43 shape (mouth respawn)")
	check(not wgrid.is_solid(2, 2), "the ladder-up cell is floor")
	check(not wgrid.is_solid(7, 5), "the warren arrival spawn is floor")
	if bool(wf.ok):
		var bg2: RefCounted = wf.bitgrid
		# The DOOR is the binding's ACCESS cell — the binding cell
		# itself is the giant-skeleton POI, solid by WYSIWYG.
		check(bg2.is_solid(193, 239), "the binding cell is the POI (solid, as shipped)")
		check(not bg2.is_solid(194, 240), "the warren mouth (access cell) walks")
		check(not bg2.is_solid(196, 240), "the return arrival cell walks")

	if fails.is_empty():
		print("green_roster_test: PASS (roster/lead-law/grammar/variants/re-table/proof-premises)")
		quit(0)
	else:
		for m: String in fails:
			printerr("green_roster_test FAIL: " + m)
		quit(1)
