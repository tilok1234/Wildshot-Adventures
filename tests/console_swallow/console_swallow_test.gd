extends SceneTree
## sl-0206 console input-swallow test (fixed gate): THE LAW —
## console-open swallows ALL non-console input, gameplay and dev
## hotkeys both; close restores. Layers:
##   1. the REAL sampler contract: suppress sends neutral frames while
##      device keys are held and keeps training edges (no stale edge
##      fires when the swallow lifts);
##   2. the guard replica over the REAL binding table: every registered
##      action evaluates swallowed under console-open except the
##      sanctioned console_toggle (the close key IS console input);
##      main cannot compile under --script (the dev_map precedent), so
##      the composition is replicated here and main's side is pinned
##      textually below;
##   3. source pins: main.gd's predicate + suppress lines, a swallow
##      guard on EVERY main poll site (span walk — survives gdformat
##      reflow), the esc_intercept console-first close, and ZERO device
##      polls outside the sanctioned poller files (the gif-recorder
##      leak class: pollers live where the guard lives).
##
## Run: godot --headless --path . --script tests/console_swallow/console_swallow_test.gd

const InputMapDefaults := preload("res://input/input_map_defaults.gd")
const HumanSampler := preload("res://input/human_sampler.gd")
const DebugConsole := preload("res://ui/debug_console.gd")

const SANCTIONED_POLLERS := [
	"res://game/main.gd",
	"res://input/human_sampler.gd",
	"res://game/drivers/realtime_driver.gd",
]
const POLL_TOKENS := [
	"Input.is_action",
	"Input.is_key_pressed",
	"Input.is_physical_key_pressed",
	"Input.is_mouse_button_pressed",
]
const GUARD_TOKENS := ["not typing", "not box_typing", "not console_open"]

var failed := false


func _fail(msg: String) -> void:
	printerr("FAIL: " + msg)
	failed = true


static func _all_actions() -> Array[String]:
	var out: Array[String] = []
	for a: String in InputMapDefaults.KEY_ACTIONS:
		out.append(a)
	for a: String in InputMapDefaults.ALT_KEY_ACTIONS:
		out.append(a)
	for a: String in InputMapDefaults.MOUSE_ACTIONS:
		out.append(a)
	return out


static func _gd_files(dir: String, out: Array) -> void:
	for d in DirAccess.get_directories_at(dir):
		_gd_files(dir + "/" + String(d), out)
	for f in DirAccess.get_files_at(dir):
		if String(f).ends_with(".gd"):
			out.append(dir + "/" + String(f))


func _init() -> void:
	InputMapDefaults.register()

	# --- 1. the sampler's suppress contract (the REAL object) ---------
	var sampler := HumanSampler.new()
	Input.action_press("move_right")
	Input.action_press("fire")
	Input.action_press("interact")
	sampler.suppress = true
	var nf := sampler.sample(Vector2(5, 0), Vector2.ZERO)
	if nf.move_x != 0 or nf.move_y != 0 or nf.fire_held or nf.interact_pressed:
		_fail(
			(
				"suppressed frame must be neutral (move %d,%d fire %s interact %s)"
				% [nf.move_x, nf.move_y, nf.fire_held, nf.interact_pressed]
			)
		)
	sampler.suppress = false
	var live := sampler.sample(Vector2(5, 0), Vector2.ZERO)
	if live.move_x != 1 or not live.fire_held:
		_fail("unsuppressed frame must carry held device state (positive control)")
	if live.interact_pressed:
		_fail("interact held THROUGH the swallow must not edge when it lifts")
	Input.action_release("interact")
	sampler.sample(Vector2(5, 0), Vector2.ZERO)
	Input.action_press("interact")
	var edged := sampler.sample(Vector2(5, 0), Vector2.ZERO)
	if not edged.interact_pressed:
		_fail("fresh interact press after the swallow lifts must edge (positive control)")
	Input.action_release("move_right")
	Input.action_release("fire")
	Input.action_release("interact")

	# --- 2. the guard replica over the real binding table -------------
	# The console is driven by its `visible` property — the exact
	# predicate main reads. toggle()'s focus calls need a live tree
	# (nodes added during SceneTree._init are not in-tree yet), so its
	# body is source-pinned below instead — the dev_map precedent.
	# _ready() is invoked directly: it builds the children and sets the
	# real initial hidden state.
	var console: PanelContainer = DebugConsole.new()
	console._ready()
	if console.visible:
		_fail("the console must construct hidden")
	console.visible = true
	for action: String in _all_actions():
		Input.action_press(action)
		if not Input.is_action_pressed(action):
			_fail("positive control: %s must register as pressed" % action)
		var console_open := console.visible
		var box_typing := false
		var typing := console_open or box_typing
		match action:
			"console_toggle":
				# Sanctioned: the close key IS console input.
				if not ((not box_typing) and Input.is_action_pressed(action)):
					_fail("console_toggle must stay LIVE while the console is open")
			"pause_toggle":
				# Esc reaches the driver by design; esc_intercept closes
				# the console first — pinned at the source layer below.
				pass
			"fullscreen_toggle":
				if (not console_open) and Input.is_action_pressed(action):
					_fail("fullscreen_toggle must be swallowed while the console is open")
			_:
				if (not typing) and Input.is_action_pressed(action):
					_fail("%s must be swallowed while the console is open" % action)
		Input.action_release(action)
	console.visible = false
	Input.action_press("scenario_reset")
	var still_open := console.visible
	if not ((not still_open) and Input.is_action_pressed("scenario_reset")):
		_fail("close must restore the swallowed bindings (T live again after close)")
	Input.action_release("scenario_reset")
	console.free()

	# --- 3. source pins ----------------------------------------------
	# CRLF-normalized: multi-line pins must survive Windows checkouts.
	var main_src := FileAccess.get_file_as_string("res://game/main.gd").replace("\r\n", "\n")
	for pin: String in [
		"var console_open := console != null and console.visible",
		"var box_typing := comments_box != null and comments_box.has_focus()",
		"var typing := console_open or box_typing",
		"driver.sampler.suppress = typing or over_pane",
		'if not box_typing and console != null and Input.is_action_just_pressed("console_toggle")',
		'if not console_open and Input.is_action_just_pressed("fullscreen_toggle")',
	]:
		if not main_src.contains(pin):
			_fail("main.gd lost the sl-0206 pin: " + pin)
	var esc_pin := (
		"func _close_topmost_menu() -> bool:"
		+ "\n\tif console != null and console.visible:"
		+ "\n\t\tconsole.toggle()"
		+ "\n\t\treturn true"
	)
	if not main_src.contains(esc_pin):
		_fail("main.gd _close_topmost_menu must close the console FIRST (esc_intercept)")
	# Every main poll site carries a swallow guard. The span walk keeps
	# the check honest through gdformat reflow — the enclosing if may
	# sit lines above the poll (the options_toggle block).
	var lines := main_src.split("\n")
	for i in lines.size():
		if not lines[i].contains("Input.is_action_just_pressed"):
			continue
		var span := ""
		for j in range(maxi(0, i - 8), i + 1):
			span += lines[j] + "\n"
		var guarded := false
		for g: String in GUARD_TOKENS:
			if span.contains(g):
				guarded = true
		if not guarded:
			_fail("main.gd:%d polls without a swallow guard: %s" % [i + 1, lines[i].strip_edges()])
	# Pollers live where the guard lives: ZERO device polls outside the
	# sanctioned files (the gif-recorder class — a bare poll anywhere
	# else bypasses the swallow and leaks into console typing).
	var gds: Array = []
	for base: String in ["res://game", "res://ui", "res://input", "res://autoload"]:
		_gd_files(base, gds)
	for path: String in gds:
		if path in SANCTIONED_POLLERS:
			continue
		var src := FileAccess.get_file_as_string(path)
		for tok: String in POLL_TOKENS:
			if src.contains(tok):
				_fail(
					(
						"%s polls device input (%s) — poll from main behind the swallow guard"
						% [path, tok]
					)
				)
	# toggle() owns visibility + focus — the close-restores mechanism
	# (exercised live by the game; needs a real tree, so pinned here).
	var con_src := FileAccess.get_file_as_string("res://ui/debug_console.gd").replace("\r\n", "\n")
	if not (con_src.contains("visible = not visible") and con_src.contains("_input.grab_focus()")):
		_fail("debug_console.toggle() must flip visibility and own the focus")
	# The driver's ONE poll is the pause key and it runs the intercept
	# (console/menu close) before the press can mean pause.
	var drv := FileAccess.get_file_as_string("res://game/drivers/realtime_driver.gd").replace(
		"\r\n", "\n"
	)
	if drv.count("Input.is_action") != 1:
		_fail("realtime_driver must poll exactly the pause key and nothing else")
	if not drv.contains("esc_intercept.is_valid() and bool(esc_intercept.call())"):
		_fail("the pause poll must run esc_intercept first (console/menu close)")

	print("console swallow test: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
