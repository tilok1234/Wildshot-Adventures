## One-shot probe (b76 intake, sl-0061): the Overworld Walk picker row's
## pack must validate as the b76 drop — addon validator, flood, spawn,
## behavior version — AND both committed worlds must build through
## world_builder's package registry: b76 resolves dusk-9b8b2a2-seed103991
## (road layer 2301 cells, exactly 47 from the road_joint source — the
## paired-drop render proof), b65 resolves the legacy M1 import
## unchanged. Not part of the battery; run ad hoc:
##   godot_console --headless --path . --script tests/worldforge_pack/b76_picker_probe.gd
extends SceneTree

const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const WorldBuilder := preload("res://game/arena/world_builder.gd")

const B65_PACK := "res://assets/worldforge-packs/small-cold-coastal-pack-dusk/"
const NEW_PKG := "res://tileforge_packages/dusk-9b8b2a2-seed103991/"


func _init() -> void:
	var scenario: Resource = load("res://data/scenarios/overworld_walk.tres")
	var pack_path: String = scenario.get("worldforge_pack")
	print("picker row -> ", pack_path, " (", scenario.get("display_name"), ")")
	if not String(scenario.get("display_name")).contains("b76"):
		printerr("FAIL: picker row label is not b76")
		quit(1)
		return
	var result: Dictionary = WorldforgePack.validate(pack_path)
	if not result.ok:
		printerr("FAIL: pack did not validate:\n" + "\n".join(result.log))
		quit(1)
		return
	var manifest_text := FileAccess.get_file_as_string(pack_path + "manifest.json")
	var manifest: Dictionary = JSON.parse_string(manifest_text)
	var behavior: int = int(manifest["generator"]["behaviorVersion"])
	var flood: int = int(manifest["walkability"]["floodCount"])
	var spawn: Array = manifest["walkability"]["spawnCell"]
	print("validated: behavior=", behavior, " flood=", flood, " spawn=", spawn)
	if behavior != 76 or flood != 45156 or int(spawn[0]) != 109 or int(spawn[1]) != 182:
		printerr("FAIL: picker row does not load the b76 drop")
		quit(1)
		return

	# Both-worlds render proof: the registry resolves each pack's pin.
	var root_76 := Node2D.new()
	get_root().add_child(root_76)
	var arena_76 := WorldBuilder.build_world_arena(root_76, pack_path)
	if arena_76.is_empty():
		printerr("FAIL: b76 world did not build (identity/registry)")
		quit(1)
		return
	var road: TileMapLayer = root_76.get_node_or_null("road")
	if road == null:
		printerr("FAIL: b76 road layer missing")
		quit(1)
		return
	var used := road.get_used_cells()
	var pkg_manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(NEW_PKG + "tileforge-manifest.json")
	)
	var joint_index := -1
	var index := 0
	for fam_key: String in pkg_manifest.families:
		if String(pkg_manifest.families[fam_key].image).get_basename() == "road_joint":
			joint_index = index
		index += 1
	var joint_sid: int = road.tile_set.get_source_id(joint_index)
	var joint_cells := 0
	for cell: Vector2i in used:
		if road.get_cell_source_id(cell) == joint_sid:
			joint_cells += 1
	print("b76 road layer: %d cells, %d from road_joint" % [used.size(), joint_cells])
	if used.size() != 2301 or joint_cells != 47:
		printerr("FAIL: b76 road layer expected 2301 cells with 47 joints")
		quit(1)
		return

	var root_65 := Node2D.new()
	get_root().add_child(root_65)
	var arena_65 := WorldBuilder.build_world_arena(root_65, B65_PACK)
	if arena_65.is_empty() or int(arena_65.placements) <= 0:
		printerr("FAIL: b65 world did not build through the legacy package")
		quit(1)
		return
	print("b65 world builds via legacy import: %d placements" % int(arena_65.placements))

	print("PASS: Overworld Walk picker row loads the b76 overworld (flood 45156, spawn 109,182); both worlds resolve their pinned tileforge packages")
	quit(0)
