extends SceneTree
## Projectile-pack consumer test: round-trips the REAL drop through the
## shared import logic with the REAL projectile_map — proving manifest
## sanity, every mapped sprite's existence + pixel dimensions +
## frame-strip math, and the Law-2/8 hostile-coverage guard. The map and
## the pack cannot drift apart silently.
##
## Run: godot --headless --path . --script tests/projectile_pack/projectile_pack_test.gd

const ProjectilePack := preload("res://addons/projectile_importer/projectile_pack.gd")


func _init() -> void:
	if not DirAccess.dir_exists_absolute(
		ProjectSettings.globalize_path("res://assets/wildshot-projectiles-sphere-v0")
	):
		print("projectile pack not dropped yet — nothing to validate")
		quit(0)
		return
	var pmap: Resource = load("res://data/projectile_map.tres")
	if pmap == null:
		printerr("FAIL: data/projectile_map.tres missing")
		quit(1)
		return
	var need := ProjectilePack.needed_from_map(pmap)
	var report := ProjectilePack.import(
		"res://assets/wildshot-projectiles-sphere-v0/",
		"user://projectile_check/",
		need.needed,
		need.hostile_shots
	)
	for line: String in report.log:
		print("projectile-pack: ", line)
	if not report.ok:
		printerr("FAIL: projectile pack failed validation")
		quit(1)
		return
	print("PASS: projectile pack + map consistent (%d sprites)" % need.needed.size())
	quit(0)
