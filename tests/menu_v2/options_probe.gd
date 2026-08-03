## One-shot WINDOWED render probe (menu pass seam F): the OPTIONS
## menu restyled onto the options_v2 panel2 chrome with a
## representative row set (ability buttons, toggles, cycles, the
## remap list, the comments box — main wires the real ones), plus
## the gold-on-dark toast chip. Committed captures, read by eyes:
##   reports/options_v2_audit.png / options_v2_audit_scale2.png
## Run WITHOUT --headless:
##   godot_console --path . --script tests/menu_v2/options_probe.gd
extends SceneTree

const OptionsMenu := preload("res://ui/options_menu.gd")
const MenuPalette := preload("res://ui/menu_palette.gd")


func _init() -> void:
	_run()


func _run() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.09, 0.14)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(bg)
	var hud := CanvasLayer.new()
	get_root().add_child(hud)
	var theme: Theme = load("res://ui/theme.tres")
	var menu := OptionsMenu.new()
	menu.theme = theme
	hud.add_child(menu)
	var toast := Label.new()
	toast.text = "provisions turned in — +20 gold · +25 xp"
	var toast_box := StyleBoxFlat.new()
	toast_box.bg_color = MenuPalette.PLAQUE_BOTTOM
	toast_box.border_color = MenuPalette.GOLD_DIM
	toast_box.set_border_width_all(1)
	toast_box.content_margin_left = 8.0
	toast_box.content_margin_right = 8.0
	toast_box.content_margin_top = 2.0
	toast_box.content_margin_bottom = 2.0
	toast.add_theme_stylebox_override("normal", toast_box)
	toast.add_theme_color_override("font_color", MenuPalette.GOLD_BRIGHT)
	toast.theme = theme
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.offset_top = 24.0
	hud.add_child(toast)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	await _settle(1)
	# A representative row set (main wires the real rows the same way).
	menu.add_button_row("ability", ["Nova", "Quickdraw", "Rune"], func(_i: int) -> void: pass)
	menu.add_toggle_row("fullscreen", false, func(_on: bool) -> void: pass)
	menu.add_toggle_row("hitbox display", false, func(_on: bool) -> void: pass)
	menu.add_cycle_row("damage numbers", ["off", "reduced", "full"], 1, func(_i: int) -> void: pass)
	menu.add_cycle_row("rift split", ["half", "two-thirds"], 0, func(_i: int) -> void: pass)
	menu.add_comment_row(
		"comments (lands in the feedback bundle)", "what felt wrong? what felt great?"
	)
	menu.visible = true
	await _settle(10)
	var shot := get_root().get_texture().get_image()
	shot.save_png(ProjectSettings.globalize_path("res://reports/options_v2_audit.png"))
	var th2: Theme = theme.duplicate()
	th2.default_base_scale = 2.0
	th2.default_font_size = 20
	menu.theme = th2
	await _settle(14)
	var shot2 := get_root().get_texture().get_image()
	shot2.save_png(ProjectSettings.globalize_path("res://reports/options_v2_audit_scale2.png"))
	print("options_probe: wrote options_v2_audit(.png|_scale2.png)")
	quit(0)


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
