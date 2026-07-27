extends SceneTree
## WorldForge game-pack validator CLI (consumer-prep half, docs/15).
## Validates a pack in place and reports; imports NOTHING into the
## project — the consumption half (TileMapLayers, scenarios, POIs) waits
## for a real pack + its own ruling per the 2026-07-28 re-ruling.
##
## Usage: godot --headless --path . --script addons/worldforge_importer/import_pack.gd \
##        -- --pack=res://assets/worldforge-packs/<world>-pack/

const WorldforgePack := preload("res://addons/worldforge_importer/worldforge_pack.gd")
const BootArgs := preload("res://autoload/boot_args.gd")


func _init() -> void:
	var args := BootArgs.parse_user_args()
	var src := String(args.get("pack", ""))
	if src.is_empty():
		printerr("worldforge_import: --pack=<dir> required")
		quit(2)
		return
	if not src.ends_with("/"):
		src += "/"
	var report := WorldforgePack.validate(src)
	for line: String in report.log:
		if report.ok:
			print("worldforge_import: ", line)
		else:
			push_error("worldforge_import: " + line)
	quit(0 if report.ok else 1)
