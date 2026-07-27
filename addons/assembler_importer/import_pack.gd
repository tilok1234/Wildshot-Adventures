extends SceneTree
## Assembler game-pack importer (planning docs/14, binding): validates the
## raw drop at assets/assembler-pack/ per §4 and copies the roster named
## in data/actor_sheet_map.tres into res://assembler/. Everything derives
## from the manifest's frame_contract — no hardcoded layout. Built and
## fixture-tested BEFORE the first real export, so the pack drops in with
## zero lead time; any spec drift fails loudly here.
##
## Usage: godot --headless --path . --script addons/assembler_importer/import_pack.gd
## then: godot --headless --path . --import

const AssemblerPack := preload("res://addons/assembler_importer/assembler_pack.gd")

const SRC := "res://assets/assembler-pack/"
const DST := "res://assembler/"


func _init() -> void:
	var sheet_map: Resource = load("res://data/actor_sheet_map.tres")
	if sheet_map == null:
		push_error("import_pack: data/actor_sheet_map.tres missing")
		quit(1)
		return
	var roster: Array[String] = []
	for role: String in sheet_map.map:
		var id := String(sheet_map.map[role])
		if not roster.has(id):
			roster.append(id)
	roster.sort()
	var report := AssemblerPack.import(SRC, DST, roster)
	for line: String in report.log:
		if report.ok:
			print("import_pack: ", line)
		else:
			push_error("import_pack: " + line)
	quit(0 if report.ok else 1)
