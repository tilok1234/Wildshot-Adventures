extends SceneTree
## Projectile-pack importer: validates the raw drop at
## assets/projectile-pack/ and copies the sprites named by
## data/projectile_map.tres into res://projectiles/.
##
## Usage: godot --headless --path . --script addons/projectile_importer/import_pack.gd
## then: godot --headless --path . --import

const ProjectilePack := preload("res://addons/projectile_importer/projectile_pack.gd")

const SRC := "res://assets/projectile-pack/"
const DST := "res://projectiles/"


func _init() -> void:
	var pmap: Resource = load("res://data/projectile_map.tres")
	if pmap == null:
		push_error("import_pack: data/projectile_map.tres missing")
		quit(1)
		return
	var need := ProjectilePack.needed_from_map(pmap)
	var report := ProjectilePack.import(SRC, DST, need.needed, need.hostile_shots)
	for line: String in report.log:
		if report.ok:
			print("projectile_import: ", line)
		else:
			push_error("projectile_import: " + line)
	quit(0 if report.ok else 1)
