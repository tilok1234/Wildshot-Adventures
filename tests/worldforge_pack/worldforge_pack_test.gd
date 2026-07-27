extends SceneTree
## WorldForge game-pack consumer test (consumer-prep half, docs/15):
## builds a synthetic packFormat-1 fixture whose connected-walkable count
## is derived BY HAND (16x12; border ring solid; 14x10=140 interior;
## minus a 2x2 block = 136; minus a walled-off 2-cell pocket + its
## 10-cell wall = 124 CONNECTED, 126 total-walkable — the pocket proves
## flood != total). Round-trips it through the shared validator, asserts
## the decoded bitgrid cell-by-cell where it matters, then proves every
## guard can FAIL: wrong floodCount, tampered file hash, manifest BOM.
##
## Run: godot --headless --path . --script tests/worldforge_pack/worldforge_pack_test.gd

const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")

const FIX := "user://worldforge_fixture/"
const W := 16
const H := 12
const SPAWN := Vector2i(2, 2)
const FLOOD_HAND_DERIVED := 124

enum Mode { NORMAL, BAD_FLOOD, BAD_HASH, BOM }


func _init() -> void:
	var failed := false

	_write_fixture(FIX + "normal/", Mode.NORMAL)
	var ok_report := WorldforgePack.validate(FIX + "normal/")
	for line: String in ok_report.log:
		print("fixture: ", line)
	if not ok_report.ok:
		printerr("FAIL: valid fixture rejected")
		failed = true
	else:
		var grid: RefCounted = ok_report.bitgrid
		if int(ok_report.width) != W or int(ok_report.height) != H:
			printerr("FAIL: decoded dims wrong")
			failed = true
		if Vector2i(ok_report.spawn) != SPAWN:
			printerr("FAIL: spawn cell wrong")
			failed = true
		var spots := [
			[0, 0, true],  # border solid
			[4, 4, true],  # block solid
			[5, 5, true],
			[2, 2, false],  # spawn walkable
			[12, 2, false],  # pocket interior walkable (but disconnected)
			[11, 2, true],  # pocket wall solid
			[8, 8, false],  # open field walkable
		]
		for spot: Array in spots:
			if grid.is_solid(int(spot[0]), int(spot[1])) != bool(spot[2]):
				printerr("FAIL: bitgrid at (%d,%d) != %s" % [spot[0], spot[1], spot[2]])
				failed = true

	_write_fixture(FIX + "bad_flood/", Mode.BAD_FLOOD)
	var bf := WorldforgePack.validate(FIX + "bad_flood/")
	if bf.ok or not _log_has(bf.log, "flood fill"):
		printerr("FAIL: wrong floodCount was not caught")
		failed = true

	_write_fixture(FIX + "bad_hash/", Mode.BAD_HASH)
	var bh := WorldforgePack.validate(FIX + "bad_hash/")
	if bh.ok or not _log_has(bh.log, "sha256 mismatch"):
		printerr("FAIL: tampered file hash was not caught")
		failed = true

	_write_fixture(FIX + "bom/", Mode.BOM)
	var bb := WorldforgePack.validate(FIX + "bom/")
	if bb.ok or not _log_has(bb.log, "BOM"):
		printerr("FAIL: manifest BOM was not caught")
		failed = true

	if failed:
		quit(1)
		return
	print(
		(
			"PASS: worldforge pack validator (flood %d hand-verified; 3 guards fail correctly)"
			% FLOOD_HAND_DERIVED
		)
	)
	quit(0)


static func _log_has(log: Array, needle: String) -> bool:
	for line: String in log:
		if line.contains(needle):
			return true
	return false


func _write_fixture(dir: String, mode: Mode) -> void:
	for d in [dir, dir + "resolved"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))

	# Walkability bits: walkable=1. Border ring + 2x2 block at (4,4) +
	# the pocket wall ring (11..14, 1..3) solid; pocket (12,2),(13,2)
	# walkable but sealed.
	var walk := PackedByteArray()
	walk.resize((W * H + 7) / 8)
	for y in H:
		for x in W:
			var solid := x == 0 or y == 0 or x == W - 1 or y == H - 1
			if x >= 4 and x <= 5 and y >= 4 and y <= 5:
				solid = true
			var in_pocket_box := x >= 11 and x <= 14 and y >= 1 and y <= 3
			var in_pocket := (x == 12 or x == 13) and y == 2
			if in_pocket_box and not in_pocket:
				solid = true
			if not solid:
				var bit := y * W + x
				walk[bit >> 3] = walk[bit >> 3] | (1 << (bit & 7))

	var flood := FLOOD_HAND_DERIVED + (1 if mode == Mode.BAD_FLOOD else 0)
	var wjson := {
		"walkabilityFormat": 1,
		"width": W,
		"height": H,
		"encoding": "base64-bitpacked-row-major-lsb-first",
		"grid": Marshalls.raw_to_base64(walk),
		"floodCount": flood,
		"spawnCell": [SPAWN.x, SPAWN.y],
	}
	_write_json(dir + "walkability.json", wjson)

	var data: Array = []
	data.resize(W * H)
	data.fill(1)
	var tmj := {
		"width": W,
		"height": H,
		"tilesets": [{"firstgid": 1, "source": "dusk.tsj"}],
		"layers": [{"name": "ground", "width": W, "height": H, "data": data}],
	}
	_write_json(dir + "resolved/resolved-map.tmj", tmj)
	_write_json(dir + "resolved/tileforge-map-data.json", {"stub": true})
	_write_json(dir + "resolved/tileforge-slice.json", {"stub": true})
	_write_json(dir + "world.json", {"artifactFormat": 8, "settlements": [], "pois": []})
	_write_json(dir + "normalized-recipe.json", {"name": "fixture-world"})
	_write_json(dir + "validation-report.json", {"status": "pass"})
	var mini := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	mini.fill(Color(0.3, 0.5, 0.3))
	mini.save_png(ProjectSettings.globalize_path(dir + "minimap.png"))

	var rels := [
		"world.json",
		"normalized-recipe.json",
		"validation-report.json",
		"resolved/resolved-map.tmj",
		"resolved/tileforge-map-data.json",
		"resolved/tileforge-slice.json",
		"walkability.json",
		"minimap.png",
	]
	var files := {}
	for rel: String in rels:
		files[rel] = FileAccess.get_sha256(dir + rel)
	var manifest := {
		"pack": "worldforge-game-pack",
		"packFormat": 1,
		"world": "fixture-world",
		"artifactFormat": 8,
		"baseArtifactSha256": String(files["world.json"]),
		"adapter": {"tileforge": 6},
		"generator":
		{
			"behaviorVersion": 38,
			"recipeCompilerVersion": 19,
			"seed": 7,
			"recipeSha256": "fixture",
			"generationIdentitySha256": "fixture",
		},
		"tileforge":
		{
			"packageId": "fixture",
			"theme": "dusk",
			"packageSha256": "fixture",
			"manifestSha256": "fixture",
		},
		"dimensions": {"width": W, "height": H, "chunkWidth": 32, "chunkHeight": 32},
		"walkability": {"format": 1, "floodCount": flood, "spawnCell": [SPAWN.x, SPAWN.y]},
		"files": files,
	}
	var text := JSON.stringify(manifest, "\t")
	var f := FileAccess.open(dir + "manifest.json", FileAccess.WRITE)
	if mode == Mode.BOM:
		f.store_buffer(PackedByteArray([0xEF, 0xBB, 0xBF]))
	f.store_string(text)
	f.close()

	if mode == Mode.BAD_HASH:
		# Tamper AFTER hashing: world.json bytes no longer match the manifest.
		var wf := FileAccess.open(dir + "world.json", FileAccess.WRITE)
		wf.store_string(
			JSON.stringify({"artifactFormat": 8, "settlements": [], "pois": [], "x": 1})
		)
		wf.close()


static func _write_json(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
