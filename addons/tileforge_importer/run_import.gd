extends SceneTree
## Headless driver for the shipped TileForge EditorScript importer.
## Usage: godot --headless --path . --script addons/tileforge_importer/run_import.gd
##        [-- --package=res://tileforge_packages/<id>/]
## Default package dir is the M1 import at res://tileforge/. Every
## package build ships its own tileforge_importer.gd; the driver runs
## the TARGET dir's copy so each tres is built by its package's own
## authority. The shipped script extends EditorScript (File > Run in
## the editor); its _run() body only uses runtime-safe APIs (JSON,
## TileSet, ResourceSaver), so we rebase it onto RefCounted, repoint
## its hardcoded res://tileforge/ paths at the target dir, and call
## _run() directly — instantiating an EditorScript outside the editor
## hangs. Run `godot --headless --import` first so the atlas PNGs are
## imported.


func _init() -> void:
	var dir := "res://tileforge/"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--package="):
			dir = arg.trim_prefix("--package=")
			if not dir.ends_with("/"):
				dir += "/"
	var source := FileAccess.get_file_as_string(dir + "tileforge_importer.gd")
	if source.is_empty():
		push_error("run_import: tileforge_importer.gd not found in " + dir)
		quit(1)
		return
	var script := GDScript.new()
	var patched := source.replace("extends EditorScript", "extends RefCounted")
	patched = patched.replace("@tool\n", "")
	patched = patched.replace("res://tileforge/", dir)
	script.source_code = patched
	if script.reload() != OK:
		push_error("run_import: rebased importer failed to parse")
		quit(1)
		return
	var importer: RefCounted = script.new()
	importer._run()
	if not FileAccess.file_exists(dir + "tileforge.tres"):
		push_error("run_import: tileforge.tres was not created in " + dir)
		quit(1)
		return
	print("run_import: tileforge.tres built in " + dir)
	quit(0)
