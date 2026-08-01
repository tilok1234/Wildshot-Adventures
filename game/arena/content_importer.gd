extends RefCounted
## THE CONTENT-PACK IMPORTER (docs/20 step 3 == docs/23 S0 (d), sl-0100
## seam 2): reads the vendored world_filler content pack's territories +
## placements DIRECTLY as living-world spawn tables — no new authoring
## format. The hand-authored reference pass
## (notes/OVERWORLD_REFERENCE_PASS.md) is this module's spec:
## - zone membership from content-plan.json zones[].memberRegionIds
##   (the wf dangerBand stays deliberately unused — zone=level flat
##   tiers is the ruled model);
## - the placeholder-roster vocabulary maps onto the standard def
##   roster (indexes are scenario_loader's append-only contract);
##   S1 (sl-0104): zones in ZONE_VOCAB re-table each placeholder onto
##   the zone's REAL roster role-preservingly (docs/23 enemy split);
## - nightOnly is carried-but-unconsumed vocabulary (no night system):
##   night rosters spawn as normal presence, the reference-pass
##   precedent.
## TERRITORIES become roaming-population sites (seedCell + authored
## roster/packSize/maxActive). ENCOUNTER placements become point sites
## inheriting their covering territory's table (else nearest seedCell
## in the same region; else counted-skip — the census test pins the
## number). WORLD-BOSS placements become boss sites (Warden kit
## stand-in, docs/20 — identity stays the designer's lore act) on a
## lazy timer. DUNGEON bindings are recorded and skipped (interiors
## are chapter work by design, docs/23).

## wf placeholder roster id -> standard def roster index
## (0=rusher 1=husk_archer 2=fanmaw 3=ringer 4=leadshot 5=blightcaster
## 6=yard_warden 7=bone_reliquary_king — scenario_loader.gd contract).
const ENEMY_VOCAB := {
	"enemy.marauder": 0,
	"enemy.prowler": 1,
	"enemy.night_shade": 4,
	"enemy.mire_creeper": 5,
	"enemy.frost_wraith": 3,
}
const BOSS_DEF_INDEX := 6  # yard_warden kit stand-in (docs/20)
## S1 seam 3: zones whose world boss has its REAL identity (docs/23
## naming act). Missing zones keep the Warden stand-in until their
## chapter names them.
const ZONE_BOSS := {"green": 22}  # old_tusk

## S1 GREEN RE-TABLE (sl-0104 seam 1): zones with a row here map each
## wf placeholder id onto a WEIGHTED SET of the zone's real roster —
## role-preserving (the pack's authored melee/ranged/hazard mix per
## territory survives; the families diversify inside it). Each set
## sums to EXACTLY 100 so entry weight = placeholder weight x set
## weight keeps every cross-role ratio integer-exact. A zone listed
## here is AUTHORITATIVE: a roster id missing from its table is an
## unknown id (loud refusal), never a silent flat-vocab fallback.
## Def indexes 8..21 = the Green 14 (scenario_loader contract).
const ZONE_VOCAB := {
	"green":
	{
		"enemy.marauder":
		[[8, 28], [9, 20], [11, 14], [12, 12], [15, 8], [10, 6], [17, 6], [18, 6]],
		"enemy.prowler": [[21, 32], [16, 26], [14, 22], [19, 12], [20, 8]],
		"enemy.mire_creeper": [[13, 100]],
	},
}
## Zone density multiplier on pack_size + max_active [T] (sl-0099:
## "enemy density too low", self-dispositioned as slice tuning — the
## leash exists now, so Green rises deliberately).
const ZONE_DENSITY := {"green": 1.5}

## Depth-keyed respawn bases in ticks [T] (docs/23 (c): lazy in Green,
## fast in Snow — W-3). Keyed by the pack's own zone prefixes.
const ZONE_RESPAWN_TICKS := {
	"green": 10800,
	"dry": 9000,
	"wet": 7200,
	"cold": 5400,
}
## respawnPressure multiplier on the zone base (this pack ships all
## "medium" — the vocabulary is honored so a re-authored drop tunes
## without code).
const PRESSURE_MULT := {"low": 1.5, "medium": 1.0, "high": 0.75}
## Boss sites respawn at zone base x this (lazy by design [T] — a
## world boss should not be waiting again on the walk back).
const BOSS_RESPAWN_MULT := 3

const DEFAULT_ZONE_TICKS := 10800


## Exported builds ship the content pack loose beside the exe like the
## worldforge packs (assets/ is .gdignore'd; tools/export.ps1 copies
## it). Same resolve shape as WorldforgePack.resolve_src.
static func resolve_src(src: String) -> String:
	if FileAccess.file_exists(src + "manifest.json"):
		return src
	if src.begins_with("res://") and not OS.has_feature("editor"):
		var beside := OS.get_executable_path().get_base_dir().path_join(src.trim_prefix("res://"))
		if not beside.ends_with("/"):
			beside += "/"
		if FileAccess.file_exists(beside + "manifest.json"):
			return beside
	return src


## Build site defs from the pack at `src` (dir path ending in /).
## Returns {ok, sites, report, log}; ok=false REFUSES loudly (a
## missing/corrupt pack must never quietly produce a dead world).
static func build_sites(src: String) -> Dictionary:
	src = resolve_src(src)
	var log: Array[String] = []
	var plan: Variant = _read_json(src + "content-plan.json")
	var terr: Variant = _read_json(src + "territories.json")
	var plac: Variant = _read_json(src + "placements.json")
	if not (plan is Dictionary and terr is Dictionary and plac is Dictionary):
		push_error("content_importer: pack unreadable at " + src)
		return {"ok": false, "sites": [], "report": {}, "log": log}

	# regionId -> zone prefix ("green"/"dry"/"wet"/"cold").
	var region_zone: Dictionary = {}
	var zones: Array = plan.get("zones", [])
	for z: Dictionary in zones:
		var zid := String(z.get("id", ""))
		var parts := zid.split(".")
		var prefix := parts[1] if parts.size() >= 2 else zid
		var members: Array = z.get("memberRegionIds", [])
		for rid in members:
			region_zone[String(rid)] = prefix

	var sites: Array = []
	var unknown_ids: Dictionary = {}
	# cell "x,y" -> site array index; seed list per region for the
	# nearest fallback.
	var cell_owner: Dictionary = {}
	var region_territories: Dictionary = {}

	var retabled: Dictionary = {}
	var territories: Array = terr.get("territories", [])
	for t: Dictionary in territories:
		var zone := String(region_zone.get(String(t.get("regionId", "")), ""))
		var zone_table: Dictionary = ZONE_VOCAB.get(zone, {})
		var roster: Array = t.get("roster", [])
		var roster_defs := PackedInt32Array()
		var roster_weights := PackedInt32Array()
		for r: Dictionary in roster:
			var eid := String(r.get("enemyId", ""))
			var w := int(r.get("weightPercent", 1))
			if not zone_table.is_empty():
				# Re-tabled zone: the zone table is authoritative.
				if not zone_table.has(eid):
					unknown_ids[eid] = true
					push_error(
						(
							"content_importer: roster enemyId '%s' not in the '%s' zone table"
							% [eid, zone]
						)
					)
					continue
				for pair: Array in zone_table[eid]:
					roster_defs.append(int(pair[0]))
					roster_weights.append(w * int(pair[1]))
				continue
			if not ENEMY_VOCAB.has(eid):
				unknown_ids[eid] = true
				push_error("content_importer: unknown roster enemyId '" + eid + "'")
				continue
			roster_defs.append(int(ENEMY_VOCAB[eid]))
			roster_weights.append(w)
		if roster_defs.is_empty():
			log.append("territory %s: empty mapped roster, skipped" % String(t.get("id", "?")))
			continue
		if not zone_table.is_empty():
			retabled[zone] = int(retabled.get(zone, 0)) + 1
		var seed_cell: Array = t.get("seedCell", [0, 0])
		var pack_size: Array = t.get("packSize", [2, 6])
		var density := float(ZONE_DENSITY.get(zone, 1.0))
		var site := {
			"cell": Vector2(float(int(seed_cell[0])) + 0.5, float(int(seed_cell[1])) + 0.5),
			"roster_defs": roster_defs,
			"roster_weights": roster_weights,
			"pack_min": roundi(float(int(pack_size[0])) * density),
			"pack_max": roundi(float(int(pack_size[1])) * density),
			"max_active": roundi(float(int(t.get("maxActive", 6))) * density),
			"respawn_ticks": _respawn_ticks(zone, String(t.get("respawnPressure", "medium")), 1),
			"kind": "territory",
			"zone": zone,
		}
		var site_index := sites.size()
		sites.append(site)
		region_territories[String(t.get("regionId", ""))] = (
			region_territories.get(String(t.get("regionId", "")), []) + [site_index]
		)
		var cells: Dictionary = t.get("cells", {})
		var runs: Array = cells.get("runs", [])
		for run: Array in runs:
			var rx := int(run[0])
			var ry := int(run[1])
			var rl := int(run[2])
			for dx in rl:
				var key := "%d,%d" % [rx + dx, ry]
				if not cell_owner.has(key):
					cell_owner[key] = site_index

	var encounters_mapped := 0
	var encounters_skipped := 0
	var bosses := 0
	var dungeons_skipped := 0
	var placements: Array = plac.get("placements", [])
	for pl: Dictionary in placements:
		var rule := String(pl.get("rule", ""))
		var cell: Array = pl.get("cell", [0, 0])
		var cx := int(cell[0])
		var cy := int(cell[1])
		if rule == "dungeon_binding.v1":
			dungeons_skipped += 1
			continue
		if rule == "world_boss.v1":
			var bzone := String(region_zone.get(String(pl.get("regionId", "")), ""))
			var boss_def := int(ZONE_BOSS.get(bzone, BOSS_DEF_INDEX))
			(
				sites
				. append(
					{
						"cell": Vector2(float(cx) + 0.5, float(cy) + 0.5),
						"roster_defs": PackedInt32Array([boss_def]),
						"roster_weights": PackedInt32Array([1]),
						"pack_min": 1,
						"pack_max": 1,
						"max_active": 1,
						"respawn_ticks": _respawn_ticks(bzone, "medium", BOSS_RESPAWN_MULT),
						"kind": "boss",
						"zone": bzone,
					}
				)
			)
			bosses += 1
			continue
		if rule != "encounter_site.v1":
			log.append("placement rule '%s' unconsumed" % rule)
			continue
		# Encounter site: inherit the covering territory's table, else
		# the nearest territory seed in the same region.
		var owner: int = int(cell_owner.get("%d,%d" % [cx, cy], -1))
		if owner < 0:
			var rid := String(pl.get("regionId", ""))
			var candidates: Array = region_territories.get(rid, [])
			var best_d := 1.0e18
			for si: int in candidates:
				var sdef: Dictionary = sites[si]
				var scell: Vector2 = sdef.cell
				var d := scell.distance_to(Vector2(float(cx), float(cy)))
				if d < best_d:
					best_d = d
					owner = si
		if owner < 0:
			encounters_skipped += 1
			log.append("encounter at %d,%d: no territory in region, skipped" % [cx, cy])
			continue
		var tdef: Dictionary = sites[owner]
		(
			sites
			. append(
				{
					"cell": Vector2(float(cx) + 0.5, float(cy) + 0.5),
					"roster_defs": tdef.roster_defs,
					"roster_weights": tdef.roster_weights,
					"pack_min": int(tdef.pack_min),
					"pack_max": int(tdef.pack_max),
					"max_active": int(tdef.max_active),
					"respawn_ticks": int(tdef.respawn_ticks),
					"kind": "encounter",
					"zone": String(tdef.zone),
				}
			)
		)
		encounters_mapped += 1

	var report := {
		"territories": territories.size(),
		"sites": sites.size(),
		"encounters_mapped": encounters_mapped,
		"encounters_skipped": encounters_skipped,
		"bosses": bosses,
		"dungeons_skipped": dungeons_skipped,
		"unknown_ids": unknown_ids.size(),
		"retabled": retabled,
	}
	print(
		(
			"content_importer: %d sites (%d territories + %d encounters + %d bosses; %d dungeon bindings recorded for chapter work, %d encounters skipped)"
			% [
				sites.size(),
				territories.size(),
				encounters_mapped,
				bosses,
				dungeons_skipped,
				encounters_skipped,
			]
		)
	)
	return {"ok": unknown_ids.is_empty(), "sites": sites, "report": report, "log": log}


static func _respawn_ticks(zone: String, pressure: String, mult: int) -> int:
	var base := int(ZONE_RESPAWN_TICKS.get(zone, DEFAULT_ZONE_TICKS))
	var pm := float(PRESSURE_MULT.get(pressure, 1.0))
	return int(base * pm) * mult


static func _read_json(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return null
	return JSON.parse_string(text)
