extends RefCounted
## WorldForge game-pack logic (planning docs/15 + WorldForge
## GAME_INTEGRATION_PLAN §3, packFormat 1): validation + walkability
## decode, shared by the CLI importer and the CI test. CONSUMER-PREP
## HALF ONLY (2026-07-28 re-ruling): this validates a pack and decodes
## its collision grid; rendering resolved layers into TileMapLayers and
## using POI/spawn data are the consumption half, which waits for a real
## pack + its own ruling (post-Gate-1 by default).
##
## Trust chain mirrored from the exporter's own refusal rules:
## 1. manifest sane (UTF-8 no BOM, pack id, packFormat 1);
## 2. every manifest-listed file exists AND its sha256 matches;
## 3. walkability decodes (frozen encoding string), dims match the
##    manifest, spawnCell is walkable, and ONE FLOOD FILL from spawnCell
##    reproduces floodCount exactly — the contract's own verification
##    affordance (§3.3);
## 4. resolved-map.tmj is structurally sound (dims, layer data lengths,
##    no flip bits on gids);
## 5. world.json parses and its artifactFormat is the manifest's.
##
## Flood connectivity is 4-neighbor, matching the traverse semantics the
## contract's parity chain reports; a real pack whose floodCount
## disagrees will fail HERE loudly, never silently.

const Bitgrid := preload("res://sim/collision/bitgrid.gd")

const PACK_ID := "worldforge-game-pack"
const PACK_FORMAT := 1
const WALK_ENCODING := "base64-bitpacked-row-major-lsb-first"


## Exported builds ship packs as LOOSE FILES beside the exe (assets/ is
## .gdignore'd raw-drop land and never enters the PCK; loose packs also
## let a new pack drop swap into a tester build without re-exporting).
## A res:// pack dir that does not resolve falls back to
## <exe dir>/<same relative path>. Editor runs and headless tools see
## the working tree and take the first branch untouched.
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


## Returns {ok, log, bitgrid, spawn, width, height}. bitgrid is the
## sim-ready collision grid (solid = NOT walkable) — the future
## consumption half receives it as-is.
static func validate(src: String) -> Dictionary:
	src = resolve_src(src)
	var log: Array[String] = []
	var fail := func(msg: String) -> Dictionary:
		log.append(msg)
		return {"ok": false, "log": log}

	var bytes := FileAccess.get_file_as_bytes(src + "manifest.json")
	if bytes.is_empty():
		return fail.call("manifest.json missing at " + src)
	if bytes.size() >= 3 and bytes[0] == 0xEF and bytes[1] == 0xBB and bytes[2] == 0xBF:
		return fail.call("manifest.json has a UTF-8 BOM")
	var manifest: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if manifest == null:
		return fail.call("manifest.json is not valid JSON")
	if String(manifest.get("pack", "")) != PACK_ID:
		return fail.call("pack id '%s' != '%s'" % [String(manifest.get("pack", "")), PACK_ID])
	if int(manifest.get("packFormat", -1)) != PACK_FORMAT:
		return fail.call("packFormat %d != %d" % [int(manifest.get("packFormat", -1)), PACK_FORMAT])

	# 2. File + hash parity — the byte-honesty gate. The base artifact's
	# hash must also BE the world.json file hash (manifest self-consistency).
	var files: Dictionary = manifest.get("files", {})
	if files.is_empty():
		return fail.call("manifest.files is empty")
	for rel: String in files:
		var path := src + rel
		if not FileAccess.file_exists(path):
			return fail.call("manifest-listed file missing: " + rel)
		var got := FileAccess.get_sha256(path)
		if got != String(files[rel]):
			return fail.call("sha256 mismatch on %s" % rel)
	if String(manifest.get("baseArtifactSha256", "")) != String(files.get("world.json", "?")):
		return fail.call("baseArtifactSha256 != files['world.json'] — manifest inconsistent")

	# 2b. The exporter refuses to pack unvalidated worlds; re-check.
	var report_json: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(src + "validation-report.json")
	)
	if report_json == null:
		return fail.call("validation-report.json missing or invalid")
	if String(report_json.get("status", "")) != "pass":
		return fail.call(
			"validation-report status '%s' != 'pass'" % String(report_json.get("status", ""))
		)

	# 3. Walkability → bitgrid + flood verification.
	var dims: Dictionary = manifest.get("dimensions", {})
	var width := int(dims.get("width", 0))
	var height := int(dims.get("height", 0))
	var wjson: Variant = JSON.parse_string(FileAccess.get_file_as_string(src + "walkability.json"))
	if wjson == null:
		return fail.call("walkability.json missing or invalid")
	if int(wjson.get("walkabilityFormat", -1)) != 1:
		return fail.call("walkabilityFormat %d != 1" % int(wjson.get("walkabilityFormat", -1)))
	if String(wjson.get("encoding", "")) != WALK_ENCODING:
		return fail.call(
			"walkability encoding '%s' unsupported" % String(wjson.get("encoding", ""))
		)
	if int(wjson.width) != width or int(wjson.height) != height:
		return fail.call(
			(
				"walkability %dx%d != manifest dimensions %dx%d"
				% [int(wjson.width), int(wjson.height), width, height]
			)
		)
	var raw := Marshalls.base64_to_raw(String(wjson.grid))
	var need_bytes := (width * height + 7) / 8
	if raw.size() < need_bytes:
		return fail.call("walkability grid %d bytes < needed %d" % [raw.size(), need_bytes])
	var grid := Bitgrid.new()
	grid.setup(width, height)
	for y in height:
		for x in width:
			var bit := y * width + x
			var walkable := (raw[bit >> 3] >> (bit & 7)) & 1
			if walkable == 0:
				grid.set_solid(x, y)

	var mwalk: Dictionary = manifest.get("walkability", {})
	var spawn_arr: Array = wjson.get("spawnCell", [0, 0])
	var spawn := Vector2i(int(spawn_arr[0]), int(spawn_arr[1]))
	if grid.is_solid(spawn.x, spawn.y):
		return fail.call("spawnCell %s is not walkable" % spawn)
	var want_flood := int(wjson.get("floodCount", -1))
	if int(mwalk.get("floodCount", -2)) != want_flood:
		return fail.call("manifest floodCount disagrees with walkability.json")
	var got_flood := _flood_count(grid, spawn, width, height)
	if got_flood != want_flood:
		return fail.call("flood fill %d != declared floodCount %d" % [got_flood, want_flood])

	# 4. resolved-map.tmj structural soundness.
	var tmj: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(src + "resolved/resolved-map.tmj")
	)
	if tmj == null:
		return fail.call("resolved/resolved-map.tmj missing or invalid")
	if int(tmj.get("width", -1)) != width or int(tmj.get("height", -1)) != height:
		return fail.call("tmj dimensions disagree with the manifest")
	var tilesets: Array = tmj.get("tilesets", [])
	if tilesets.is_empty():
		return fail.call("tmj has no tilesets")
	for layer: Dictionary in tmj.get("layers", []):
		if not layer.has("data"):
			continue
		var data: Array = layer.data
		if data.size() != width * height:
			return fail.call(
				(
					"tmj layer '%s' has %d cells, expected %d"
					% [String(layer.get("name", "?")), data.size(), width * height]
				)
			)
		for gid_v in data:
			if int(gid_v) & 0xF0000000:
				return fail.call(
					"tmj layer '%s' uses flip bits (forbidden)" % String(layer.get("name", "?"))
				)

	# 5. world.json artifact sanity. The artifact's own field is named
	# formatVersion (real-pack contract); the manifest calls it
	# artifactFormat — they must agree.
	var world_json: Variant = JSON.parse_string(FileAccess.get_file_as_string(src + "world.json"))
	if world_json == null:
		return fail.call("world.json missing or invalid")
	var want_fmt := int(manifest.get("artifactFormat", -1))
	if int(world_json.get("formatVersion", -2)) != want_fmt:
		return fail.call(
			(
				"world.json formatVersion %d != manifest artifactFormat %d"
				% [int(world_json.get("formatVersion", -2)), want_fmt]
			)
		)

	log.append(
		(
			"pack '%s' valid: %dx%d, flood %d from %s, %d files hash-verified"
			% [String(manifest.get("world", "?")), width, height, got_flood, spawn, files.size()]
		)
	)
	return {
		"ok": true,
		"log": log,
		"bitgrid": grid,
		"spawn": spawn,
		"width": width,
		"height": height,
	}


## 4-neighbor flood count over walkable cells from start.
static func _flood_count(grid: RefCounted, start: Vector2i, width: int, height: int) -> int:
	var seen := {}
	var queue: Array[Vector2i] = [start]
	seen[start] = true
	var count := 0
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		count += 1
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if n.x < 0 or n.y < 0 or n.x >= width or n.y >= height:
				continue
			if seen.has(n) or grid.is_solid(n.x, n.y):
				continue
			seen[n] = true
			queue.push_back(n)
	return count
