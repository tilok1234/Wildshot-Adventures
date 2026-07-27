extends SceneTree
## UI kit importer, phase 2 (planning docs/13 §6 + kit README): builds
## res://ui/theme.tres from res://uikit/manifest.json — StyleBoxTexture
## per 9-slice piece, kit icons, pixel font (AA off, hinting none, 10 px)
## embedded via load_dynamic_font. The pressed state gets the README's
## 1 px down/right content inset. Run AFTER import_uikit.gd + --import.
##
## Usage: godot --headless --path . --script addons/uikit_importer/build_theme.gd

const KIT := "res://uikit/"
const OUT := "res://ui/theme.tres"

var _pieces := {}


func _init() -> void:
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(KIT + "manifest.json"))
	if manifest == null:
		push_error("build_theme: run import_uikit.gd first")
		quit(1)
		return
	for piece: Dictionary in manifest.pieces:
		_pieces[String(piece.id)] = piece

	var theme := Theme.new()

	var font := FontFile.new()
	font.load_dynamic_font(KIT + String(manifest.font.file))
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	theme.default_font = font
	theme.default_font_size = int(manifest.font.size_px)

	var text := Color("#cfc4ec")
	var text_bright := Color("#f2ead8")

	theme.set_stylebox("panel", "PanelContainer", _sbox("panel"))
	theme.set_stylebox("panel", "Panel", _sbox("panel"))
	theme.set_stylebox("panel", "PopupPanel", _sbox("popup_panel"))
	theme.set_stylebox("panel", "TooltipPanel", _sbox("tooltip_panel"))

	theme.set_stylebox("normal", "Button", _sbox("button_normal"))
	theme.set_stylebox("hover", "Button", _sbox("button_hover"))
	theme.set_stylebox("pressed", "Button", _sbox("button_pressed", Vector2i(1, 1)))
	theme.set_stylebox("disabled", "Button", _sbox("button_disabled"))
	theme.set_stylebox("focus", "Button", _sbox("button_focus"))
	theme.set_color("font_color", "Button", text)
	theme.set_color("font_hover_color", "Button", text_bright)
	theme.set_color("font_pressed_color", "Button", text_bright)
	theme.set_color("font_disabled_color", "Button", Color("#8f7cce"))

	theme.set_color("font_color", "Label", text)

	theme.set_icon("checked", "CheckBox", _tex("check_on"))
	theme.set_icon("unchecked", "CheckBox", _tex("check_off"))
	theme.set_color("font_color", "CheckBox", text)

	theme.set_stylebox("slider", "HSlider", _sbox("slider_track"))
	theme.set_stylebox("grabber_area", "HSlider", _sbox("slider_track"))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _sbox("slider_track"))
	theme.set_icon("grabber", "HSlider", _tex("slider_grabber"))
	theme.set_icon("grabber_highlight", "HSlider", _tex("slider_grabber_focus"))

	theme.set_stylebox("scroll", "VScrollBar", _sbox("scroll_track"))
	theme.set_stylebox("grabber", "VScrollBar", _sbox("scroll_grabber"))
	theme.set_stylebox("grabber_highlight", "VScrollBar", _sbox("scroll_grabber"))
	theme.set_stylebox("grabber_pressed", "VScrollBar", _sbox("scroll_grabber"))

	theme.set_stylebox("normal", "LineEdit", _sbox("lineedit_normal"))
	theme.set_stylebox("focus", "LineEdit", _sbox("lineedit_focus"))
	theme.set_color("font_color", "LineEdit", text_bright)

	theme.set_stylebox("tab_selected", "TabContainer", _sbox("tab_selected"))
	theme.set_stylebox("tab_unselected", "TabContainer", _sbox("tab_unselected"))
	theme.set_stylebox("panel", "TabContainer", _sbox("panel"))
	theme.set_color("font_selected_color", "TabContainer", text_bright)
	theme.set_color("font_unselected_color", "TabContainer", text)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := ResourceSaver.save(theme, OUT)
	if err != OK:
		push_error("build_theme: save failed (%d)" % err)
		quit(1)
		return
	print("build_theme: -> ", OUT)
	quit(0)


func _sbox(id: String, content_inset := Vector2i.ZERO) -> StyleBoxTexture:
	var piece: Dictionary = _pieces[id]
	var sb := StyleBoxTexture.new()
	sb.texture = load(KIT + String(piece.file))
	var m: Array = piece.margins
	sb.texture_margin_left = float(m[0])
	sb.texture_margin_top = float(m[1])
	sb.texture_margin_right = float(m[2])
	sb.texture_margin_bottom = float(m[3])
	sb.content_margin_left = float(m[0]) + 2.0 + content_inset.x
	sb.content_margin_top = float(m[1]) + content_inset.y
	sb.content_margin_right = float(m[2]) + 2.0 - content_inset.x
	sb.content_margin_bottom = float(m[3]) - content_inset.y
	return sb


func _tex(id: String) -> Texture2D:
	return load(KIT + String(_pieces[id].file))
