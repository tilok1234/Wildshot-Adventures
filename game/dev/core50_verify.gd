extends RefCounted
## CORE-50 option runtime-verification (docs/12 §4 M8 accept line: "every
## baseline option demonstrably changes runtime behavior"). Dev-gated CLI
## (--verify=core50-low | core50-high), same shape as --audit: main.gd
## repoints the Config autoload at an injected settings profile BEFORE any
## wiring reads it — the designer's real settings.cfg is never touched —
## then asserts at the end of _ready that every mechanizable option
## actually landed in the runtime objects it claims to drive. Running BOTH
## profiles (pretester does) proves the options CHANGE behavior, not just
## hold a value. The render-side half (how things look) stays designer
## eyes: notes/CORE50_RUNTIME_CHECKLIST.md maps every option to its
## mechanized-or-eyes verification.

## Profile values chosen so low/high differ on EVERY asserted option.
const PROFILES := {
	"core50-low":
	{
		"effects": {"density": 2, "opacity": 2, "flash_reduction": true},
		"feedback": {"damage_numbers": 0, "impact": false, "kill": false, "blocked": false},
		"audio": {"master": 3, "sfx": 3, "keythreats": 3, "music": 3, "attacksfx": 3},
		"ui":
		{
			"scale": 1,
			"hitboxes": false,
			"fullscreen": false,
			"crosshair_style": 1,
			"crosshair_size": 9,
			"game_zoom": 0,
		},
		"dev": {"scenario": "res://data/scenarios/first_contact.tres", "seed": 1},
	},
	"core50-high":
	{
		"effects": {"density": 0, "opacity": 0, "flash_reduction": false},
		"feedback": {"damage_numbers": 2, "impact": true, "kill": true, "blocked": true},
		"audio": {"master": 0, "sfx": 1, "keythreats": 2, "music": 1, "attacksfx": 2},
		"ui":
		{
			"scale": 2,
			"hitboxes": true,
			"fullscreen": false,
			"crosshair_style": 2,
			"crosshair_size": 15,
			"game_zoom": 2,
		},
		"dev": {"scenario": "res://data/scenarios/first_contact.tres", "seed": 1},
	},
}
## core50-high additionally injects a remap (move_up -> J) and asserts it
## reached the live InputMap through the persisted-remap path.
const HIGH_REMAP_ACTION := "move_up"
const HIGH_REMAP_KEYCODE := KEY_J

## What the profile indices must become in the wired objects (mirrors
## main.gd EFFECT_*_LEVELS / AUDIO_LEVELS — asserted against those
## constants at runtime, so a retune there fails here loudly).


## Returns true (and injects) only for a known profile name. main.gd's
## single call site carries the one-flag gate on its declaration line
## (the lockdown lint pins it there).
static func inject_if_known(profile: String) -> bool:
	if not PROFILES.has(profile):
		return false
	Config.settings_path = "user://%s.cfg" % profile
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Config.settings_path))
	var vals: Dictionary = PROFILES[profile]
	for section: String in vals:
		var keys: Dictionary = vals[section]
		for key: String in keys:
			Config.set_setting(section, key, keys[key])
	if profile == "core50-high":
		Config.set_setting(
			"input_remaps", HIGH_REMAP_ACTION, {"kind": "key", "code": int(HIGH_REMAP_KEYCODE)}
		)
		Config.apply_saved_remaps()
	return true


## Assert the wired state against the injected profile. Returns failure
## messages (empty = PASS). Duck-typed member access — this module must
## not preload main.gd (main preloads it).
static func verify(m: Node, profile: String) -> Array[String]:
	var fails: Array[String] = []
	var vals: Dictionary = PROFILES[profile]

	var density_levels: Array = m.get("EFFECT_DENSITY_LEVELS")
	var opacity_levels: Array = m.get("EFFECT_OPACITY_LEVELS")
	var audio_levels: Array = m.get("AUDIO_LEVELS")

	# Effect scaler -> EffectLibrary (the ONE cosmetic policy point).
	var lib: RefCounted = m.get("effects_lib")
	var fx: Dictionary = vals.effects
	if not is_equal_approx(float(lib.get("density")), float(density_levels[int(fx.density)])):
		fails.append(
			(
				"effects density idx %d not wired (lib=%f)"
				% [int(fx.density), float(lib.get("density"))]
			)
		)
	if not is_equal_approx(float(lib.get("opacity")), float(opacity_levels[int(fx.opacity)])):
		fails.append(
			(
				"effects opacity idx %d not wired (lib=%f)"
				% [int(fx.opacity), float(lib.get("opacity"))]
			)
		)
	if bool(lib.get("flash_reduction")) != bool(fx.flash_reduction):
		fails.append("flash_reduction not wired")

	# Damage numbers + per-channel feedback toggles.
	var fs: Dictionary = m.get("feedback_settings")
	var fb: Dictionary = vals.feedback
	if int(fs.damage_numbers) != int(fb.damage_numbers):
		fails.append(
			(
				"damage_numbers mode %d not wired (got %d)"
				% [int(fb.damage_numbers), int(fs.damage_numbers)]
			)
		)
	for key: String in ["impact", "kill", "blocked"]:
		if bool(fs[key]) != bool(fb[key]):
			fails.append("feedback %s not wired" % key)

	# Separate audio channels (Law 7 / CORE-50): mute flag + dB level.
	var buses: Array = m.get("AUDIO_BUSES")
	var au: Dictionary = vals.audio
	for bus: String in buses:
		var want_idx := int(au[bus.to_lower()])
		var lin := float(audio_levels[want_idx])
		var bi := AudioServer.get_bus_index(bus)
		if bi < 0:
			fails.append("audio bus %s missing" % bus)
			continue
		if AudioServer.is_bus_mute(bi) != (lin <= 0.0):
			fails.append("audio %s mute state wrong for idx %d" % [bus, want_idx])
		var want_db := linear_to_db(maxf(lin, 0.0001))
		if absf(AudioServer.get_bus_volume_db(bi) - want_db) > 0.01:
			fails.append(
				"audio %s at %.1f dB, want %.1f" % [bus, AudioServer.get_bus_volume_db(bi), want_db]
			)

	# Hitbox indicator (CORE-50 optional visible hitboxes).
	var hitboxes: Node2D = m.get("hitboxes")
	if hitboxes.visible != bool(vals.ui.hitboxes):
		fails.append("hitbox visibility not wired")

	# UI/text scaling: the scaled theme reaches the HUD surfaces.
	var options_menu: Control = m.get("options_menu")
	var th: Theme = options_menu.theme
	if th == null or not is_equal_approx(th.default_base_scale, float(vals.ui.scale)):
		fails.append("ui scale %d not applied to HUD theme" % int(vals.ui.scale))
	elif th.default_font_size != 10 * int(vals.ui.scale):
		fails.append("ui font size not scaled")

	# sl-0077 crosshair style + size -> the applied cursor state (main
	# caches what it handed Input.set_custom_mouse_cursor — the cursor
	# itself has no getter; the render half stays designer eyes).
	if int(m.get("_crosshair_style")) != int(vals.ui.crosshair_style):
		fails.append(
			(
				"crosshair style %d not wired (applied %d)"
				% [int(vals.ui.crosshair_style), int(m.get("_crosshair_style"))]
			)
		)
	if int(m.get("_crosshair_size")) != int(vals.ui.crosshair_size):
		fails.append(
			(
				"crosshair size %d not wired (applied %d)"
				% [int(vals.ui.crosshair_size), int(m.get("_crosshair_size"))]
			)
		)

	# sl-0222 game zoom -> the live follow camera (the accessibility
	# row's runtime object; first_contact is an arena world, so the
	# follow camera exists on both profiles).
	var zoom_levels: Array = m.get("GAME_ZOOM_LEVELS")
	var fcam: Camera2D = m.get("_follow_cam")
	if fcam == null:
		fails.append("follow camera missing — game zoom unverifiable")
	elif not is_equal_approx(fcam.zoom.x, float(zoom_levels[int(vals.ui.game_zoom)])):
		fails.append(
			"game zoom idx %d not wired (camera %.2f)" % [int(vals.ui.game_zoom), fcam.zoom.x]
		)

	# Remap path (full remapping from start): high profile only.
	if profile == "core50-high":
		var bound := Config.binding_text(HIGH_REMAP_ACTION)
		if bound != OS.get_keycode_string(HIGH_REMAP_KEYCODE):
			fails.append("injected remap not live (move_up = %s)" % bound)

	return fails
