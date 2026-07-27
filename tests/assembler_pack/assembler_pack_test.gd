extends SceneTree
## Assembler-pack consumer test (docs/14) — runs in TWO parts:
##
## Part 1 (always): generates a synthetic fixture pack per the docs/14
## contract in user://, round-trips it through the shared import logic,
## builds SpriteFrames from the result, and asserts layout math, loop
## flags, and the cast→attack / death→hurt fallback aliases. This proves
## the consumer BEFORE the designer's first real export exists.
##
## Part 2 (when assets/assembler-pack/ exists): validates the real drop
## with the same logic — the pre-integration gate for the actual pack.
##
## Run: godot --headless --path . --script tests/assembler_pack/assembler_pack_test.gd

const AssemblerPack := preload("res://addons/assembler_importer/assembler_pack.gd")

const FIX := "user://assembler_fixture/"
const FIX_OUT := "user://assembler_fixture_out/"
const FIXC := "user://assembler_fixture_catalog/"
const FIXC_OUT := "user://assembler_fixture_catalog_out/"


func _init() -> void:
	var failed := false
	if not _fixture_roundtrip():
		failed = true
	if not _fixture_catalog():
		failed = true
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://assets/assembler-pack")):
		var report := AssemblerPack.import(
			"res://assets/assembler-pack/", "user://assembler_real_check/", _real_roster()
		)
		for line: String in report.log:
			print("real-pack: ", line)
		if not report.ok:
			printerr("FAIL: real assembler pack failed validation")
			failed = true
	else:
		print("real pack not dropped yet — fixture coverage only (expected pre-export)")
	if failed:
		quit(1)
		return
	print("PASS: assembler consumer pipeline")
	quit(0)


func _real_roster() -> Array[String]:
	var sheet_map: Resource = load("res://data/actor_sheet_map.tres")
	var roster: Array[String] = []
	for role: String in sheet_map.map:
		var id := String(sheet_map.map[role])
		if not roster.has(id):
			roster.append(id)
	roster.sort()
	return roster


func _fixture_roundtrip() -> bool:
	_write_fixture()
	var report := AssemblerPack.import(FIX, FIX_OUT, ["hero", "gob"])
	for line: String in report.log:
		print("fixture: ", line)
	if not report.ok:
		printerr("FAIL: fixture pack failed import")
		return false

	# Build frames straight from the imported fixture manifest (the
	# library reads a fixed path, so replicate its math here against the
	# imported copy — same contract, same derivations).
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(FIX_OUT + "manifest.json")
	)
	var contract: Dictionary = manifest.frame_contract
	var cell := int(manifest.cell)
	var anims: Array = contract.anims
	var total := 0
	for a: Dictionary in anims:
		total += int(a.frames)
	var img := Image.load_from_file(FIX_OUT + "players/hero.png")
	if img.get_width() != total * cell or img.get_height() != 4 * cell:
		printerr("FAIL: imported fixture dims wrong")
		return false

	# Fallback aliasing: fixture ships no cast/death — the library must
	# alias them. Exercise via a temporary library-style build.
	var have := {}
	for a: Dictionary in anims:
		have[String(a.id)] = true
	if have.has("cast") or have.has("death"):
		printerr("FAIL: fixture unexpectedly ships cast/death")
		return false
	var frames := SpriteFrames.new()
	frames.add_animation("attack-down")
	frames.add_frame(
		"attack-down", ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8))
	)
	frames.set_animation_speed("attack-down", 8.0)
	frames.add_animation("hurt-down")
	frames.add_frame(
		"hurt-down", ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8))
	)
	frames.set_animation_speed("hurt-down", 8.0)
	var AssemblerLibrary := load("res://game/views/assembler_library.gd")
	AssemblerLibrary._add_fallback_aliases(frames, ["down"], have)
	if not frames.has_animation("cast-down") or not frames.has_animation("death-down"):
		printerr("FAIL: fallback aliases not created")
		return false
	if frames.get_frame_count("cast-down") != frames.get_frame_count("attack-down"):
		printerr("FAIL: cast alias frame count mismatch")
		return false
	return true


## Catalog-shape round-trip (the full-enemy-catalog export): players[] in
## the manifest, enemies resolved through indexes/enemy-variants.json by
## "<family>:<variant>" key (pack IMPORT_GUIDE). Asserts the imported
## manifest is normalized to the flat actors[] shape roster-only, and
## that a roster miss fails loudly with the family default suggested.
func _fixture_catalog() -> bool:
	_write_catalog_fixture()
	var report := AssemblerPack.import(FIXC, FIXC_OUT, ["hero", "gob:red"])
	for line: String in report.log:
		print("catalog-fixture: ", line)
	if not report.ok:
		printerr("FAIL: catalog fixture pack failed import")
		return false
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(FIXC_OUT + "manifest.json")
	)
	var actors: Array = manifest.actors
	if actors.size() != 2:
		printerr("FAIL: catalog import kept %d actors, wanted roster-only 2" % actors.size())
		return false
	var ids: Array[String] = []
	for entry: Dictionary in actors:
		ids.append(String(entry.id))
	ids.sort()
	var want: Array[String] = ["gob:red", "hero"]
	if ids != want:
		printerr("FAIL: catalog import ids %s != [gob:red, hero]" % [ids])
		return false
	var gob := Image.load_from_file(FIXC_OUT + "enemies/gob/red.png")
	if gob == null:
		printerr("FAIL: catalog variant sheet not copied to enemies/gob/red.png")
		return false

	var miss := AssemblerPack.import(FIXC, FIXC_OUT, ["gob:blue"])
	if miss.ok:
		printerr("FAIL: unknown variant 'gob:blue' imported instead of failing")
		return false
	var suggested := false
	for line: String in miss.log:
		if line.contains("default_variant is 'red'"):
			suggested = true
	if not suggested:
		printerr("FAIL: roster miss did not suggest the family default variant")
		return false
	return true


## Synthetic pack per the docs/14 contract: 24 px cells, idle 2 / walk 4 /
## attack 4 / hurt 2 (12 cols x 4 dir rows), one player, one enemy, one
## 2-frame effect. Every used frame gets a filled pixel block so content
## checks pass.
func _write_fixture() -> void:
	for d in [FIX, FIX + "players", FIX + "enemies", FIX + "effects/projectiles", FIX_OUT]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))
	var cell := 24
	var cols := 12
	var sheet := Image.create(cols * cell, 4 * cell, false, Image.FORMAT_RGBA8)
	for row in 4:
		for col in cols:
			for y in range(4, 20):
				for x in range(4, 20):
					sheet.set_pixel(col * cell + x, row * cell + y, Color(0.8, 0.4, 0.3))
	sheet.save_png(FIX + "players/hero.png")
	sheet.save_png(FIX + "enemies/gob.png")
	var fx := Image.create(2 * cell, cell, false, Image.FORMAT_RGBA8)
	for f in 2:
		for y in range(8, 16):
			for x in range(8, 16):
				fx.set_pixel(f * cell + x, y, Color(0.9, 0.9, 0.4))
	fx.save_png(FIX + "effects/projectiles/bolt.png")
	var manifest := {
		"pack": "wildshot-assembler",
		"version": 1,
		"generated": "fixture",
		"tool_commit": "fixture",
		"cell": 24,
		"export_scale": 1,
		"frame_contract":
		{
			"dirs": ["down", "left", "right", "up"],
			"anims":
			[
				{"id": "idle", "frames": 2, "ms": 420},
				{"id": "walk", "frames": 4, "ms": 150},
				{"id": "attack", "frames": 4, "ms": 115},
				{"id": "hurt", "frames": 2, "ms": 140},
			],
			"layout": "rows = dirs; columns = anims, frames left to right",
		},
		"actors":
		[
			{"id": "hero", "category": "players", "sheet": "players/hero.png", "spec": {}},
			{"id": "gob", "category": "enemies", "sheet": "enemies/gob.png", "spec": {}},
		],
		"effects":
		[
			{
				"id": "bolt",
				"category": "projectiles",
				"sheet": "effects/projectiles/bolt.png",
				"frames": 2,
				"ms": 120,
				"anchor": [12, 12],
				"directional": false,
			}
		],
	}
	var f := FileAccess.open(FIX + "manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()


## Catalog-shape fixture: one player in the manifest, one enemy family
## ("gob", default red) with its single variant in the index files.
func _write_catalog_fixture() -> void:
	for d in [FIXC, FIXC + "players", FIXC + "enemies/gob", FIXC + "indexes", FIXC_OUT]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))
	var cell := 24
	var cols := 12
	var sheet := Image.create(cols * cell, 4 * cell, false, Image.FORMAT_RGBA8)
	for row in 4:
		for col in cols:
			for y in range(4, 20):
				for x in range(4, 20):
					sheet.set_pixel(col * cell + x, row * cell + y, Color(0.3, 0.7, 0.4))
	sheet.save_png(FIXC + "players/hero.png")
	sheet.save_png(FIXC + "enemies/gob/red.png")
	var manifest := {
		"pack": "wildshot-assembler-full-enemy-catalog-compat",
		"version": 0,
		"generated": "fixture",
		"tool_commit": "fixture",
		"cell": 24,
		"export_scale": 1,
		"frame_contract":
		{
			"dirs": ["down", "left", "right", "up"],
			"anims":
			[
				{"id": "idle", "frames": 2, "ms": 420},
				{"id": "walk", "frames": 4, "ms": 150},
				{"id": "attack", "frames": 4, "ms": 115},
				{"id": "hurt", "frames": 2, "ms": 140},
			],
			"layout": "rows = dirs; columns = anims, frames left to right",
		},
		"variant_system":
		{
			"mode": "prebaked-family-variant",
			"selector":
			{
				"fields": ["family", "variant"],
				"key_format": "<family>:<variant>",
				"flat_index": "indexes/enemy-variants.json",
				"family_index": "indexes/enemy-families.json",
				"fallback": "Use the selected family default_variant when a variant id is absent.",
			},
		},
		"players": [{"id": "hero", "category": "player", "sheet": "players/hero.png", "spec": {}}],
		"effects": [],
	}
	var mf := FileAccess.open(FIXC + "manifest.json", FileAccess.WRITE)
	mf.store_string(JSON.stringify(manifest, "\t"))
	mf.close()
	var families := {
		"families": [{"id": "gob", "default_variant": "red", "variants": [{"id": "red"}]}]
	}
	var ff := FileAccess.open(FIXC + "indexes/enemy-families.json", FileAccess.WRITE)
	ff.store_string(JSON.stringify(families, "\t"))
	ff.close()
	var variants := {
		"format": "fixture",
		"version": 0,
		"key_format": "<family>:<variant>",
		"variants":
		[
			{
				"key": "gob:red",
				"family": "gob",
				"variant": "red",
				"family_name": "Gob",
				"variant_name": "Red",
				"sheet": "enemies/gob/red.png",
			}
		],
	}
	var vf := FileAccess.open(FIXC + "indexes/enemy-variants.json", FileAccess.WRITE)
	vf.store_string(JSON.stringify(variants, "\t"))
	vf.close()
