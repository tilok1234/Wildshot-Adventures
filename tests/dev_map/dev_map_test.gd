extends SceneTree
## sl-0065 dev-map consumer test (fixed gate): every scenario that
## names a WorldForge pack must ship the pack's own minimap.png (raw,
## loadable, uniformly grid-proportional — the pack-relative mapping
## contract the overlay draws with), and pack-less scenarios must
## resolve to NO minimap path (the overlay hides by absence). Also
## pins the overlay's one pure mapping function and its load-refusal
## contract. Pure JSON/PNG reads — Linux-safe.
##
## Run: godot --headless --path . --script tests/dev_map/dev_map_test.gd

const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const MapOverlay := preload("res://game/dev/map_overlay.gd")


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

	print("dev map consumer test: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
