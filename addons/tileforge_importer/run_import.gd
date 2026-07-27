extends SceneTree
## Headless driver for the shipped TileForge EditorScript importer.
## Usage: godot --headless --path . --script addons/tileforge_importer/run_import.gd
## The shipped script extends EditorScript (File > Run in the editor); its
## _run() body only uses runtime-safe APIs (JSON, TileSet, ResourceSaver), so
## we rebase it onto RefCounted and call _run() directly — instantiating an
## EditorScript outside the editor hangs. Run `godot --headless --import`
## first so the atlas PNGs are imported.


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://tileforge/tileforge_importer.gd")
	if source.is_empty():
		push_error("run_import: tileforge_importer.gd not found")
		quit(1)
		return
	var script := GDScript.new()
	script.source_code = source.replace("extends EditorScript", "extends RefCounted").replace(
		"@tool\n", ""
	)
	if script.reload() != OK:
		push_error("run_import: rebased importer failed to parse")
		quit(1)
		return
	var importer: RefCounted = script.new()
	importer._run()
	if not FileAccess.file_exists("res://tileforge/tileforge.tres"):
		push_error("run_import: tileforge.tres was not created")
		quit(1)
		return
	print("run_import: tileforge.tres built")
	quit(0)
