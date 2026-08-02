extends SceneTree
## THE CHARACTER SHEET parity law (sl-0106, seam B): screen ==
## recompute EXACT — every row the sheet model emits is a direct read
## of live player state (recompute's own output) or the profile;
## perturbing state MUST move the row (proving live reads, no
## caches). Quest-log rows mirror sim quest state exactly. Item lines
## speak the one grammar. Starhook row included. NEGATIVE-TESTED.
## Exit 0 = green.

const SimWorld := preload("res://sim/sim_world.gd")
const Bitgrid := preload("res://sim/collision/bitgrid.gd")
const StatFrame := preload("res://sim/systems/stat_frame.gd")
const CharacterProfile := preload("res://game/drivers/character_profile.gd")
const CharacterSheet := preload("res://ui/character_sheet.gd")
const ScenarioLoader := preload("res://game/scenario_loader.gd")
const InputFrame := preload("res://sim/input_frame.gd")

var fails: Array[String] = []


func check(cond: bool, name: String) -> void:
	if not cond:
		fails.append(name)


func _row(rows: Array, label: String) -> String:
	for r: Array in rows:
		if String(r[0]) == label:
			return String(r[1])
	return "<missing>"


func _init() -> void:
	# A real class world through the REAL loader + profile path.
	var grid: RefCounted = Bitgrid.new()
	grid.setup(64, 32)
	var world: RefCounted = ScenarioLoader.build_world(
		load("res://data/scenarios/lab_default.tres"), 1, grid
	)
	var prof := CharacterProfile.create(false, "staff")
	prof.gold = 77
	prof.starhook_level = 3
	prof.starhook_catches = 4
	prof.starhook_skins = 1
	CharacterProfile.apply_to_world(world, prof)
	var p: RefCounted = world.players[0]

	# 1. Parity: every sheet number equals live state exactly.
	var rows: Array = CharacterSheet.sheet_rows(world, prof)
	check(_row(rows, "class") == "staff  lv %d" % p.level, "class row exact")
	check(_row(rows, "hp") == "%d / %d" % [p.hp, p.max_hp], "hp row exact")
	check(_row(rows, "mana") == "%d / %d" % [p.mana, p.max_mana], "mana row exact")
	check(_row(rows, "speed") == "%.2f t/s" % p.move_speed, "speed row exact")
	check(_row(rows, "armor") == str(p.armor), "armor row exact")
	check(_row(rows, "gold") == str(p.gold) and p.gold == 77, "gold row exact")
	check(_row(rows, "atk spd") == str(p.attack_speed_stat), "attack-speed row exact")
	check(_row(rows, "range") == str(p.range_stat), "range row exact")
	check(_row(rows, "weapon").begins_with("T1 Staff"), "weapon row speaks the grammar")
	check(_row(rows, "worn") == "—" and _row(rows, "ring") == "—", "empty slots read as —")
	check(
		_row(rows, "starhook") == "lv 3  rod cane  catches 4  ✦starlit",
		"starhook row exact (profile lane)"
	)

	# 2. Perturbation: state moves -> the row moves (live reads).
	p.gold = 123
	p.hp = 41
	var rows2: Array = CharacterSheet.sheet_rows(world, prof)
	check(_row(rows2, "gold") == "123", "gold row tracks live state")
	check(_row(rows2, "hp") == "41 / %d" % p.max_hp, "hp row tracks live state")
	# Equip the Hide -> the worn row names it and armor shows 12.
	var items: Array = world.stat_frame.items
	for ii in items.size():
		if String(items[ii].get("id", "")) == "u-old-tusks-hide":
			p.armor_item_index = ii
	StatFrame.recompute(world, p)
	var rows3: Array = CharacterSheet.sheet_rows(world, prof)
	check(_row(rows3, "worn") == "Old Tusk's Hide", "the Hide names itself when worn")
	check(_row(rows3, "armor") == "12", "armor row shows the override exactly")

	# 3. Quest-log rows mirror sim state: take two quests via real
	# interact presses at the capital giver cell... synthetic here —
	# set the masks directly and read back.
	p.quests_taken_mask = 0b00011
	p.quest_progress_arr = PackedInt32Array()
	p.quest_progress_arr.resize(world.quest_defs.size())
	p.quest_progress_arr[0] = 3
	var qrows: Array = CharacterSheet.quest_rows(world)
	check(qrows.size() == 3, "two carried quests + the capacity line")
	check(String(qrows[0]).contains("(3/8)"), "progress n/m exact")
	check(String(qrows[0]).begins_with("[zone_hub]"), "reason tag rides the log line")
	check(String(qrows[2]) == "hands: 2/5 · done: 0", "capacity line exact")
	p.quests_done_mask = 0b00001
	var qrows2: Array = CharacterSheet.quest_rows(world)
	check(String(qrows2[qrows2.size() - 1]) == "hands: 1/5 · done: 1", "done count tracks")

	# 3.5 THE EQUIPMENT PANE (sl-0116/0128): worn rows + bag rows speak
	# the one grammar — tooltip parity IS drop-line parity (test-pinned);
	# op codes match bag_step's contract exactly.
	var ItemText: GDScript = load("res://game/views/item_text.gd")
	var BagStep: GDScript = load("res://sim/systems/bag_step.gd")
	var erows: Array = CharacterSheet.equipment_rows(world)
	check(erows.size() == 3, "pane: weapon/armor/ring rows present")
	var wrow: Dictionary = erows[0]
	check(int(wrow.op) == 0, "pane: the weapon row is replace-only (no op)")
	var arow: Dictionary = erows[1]
	check(
		int(arow.op) == BagStep.OP_DEEQUIP_ARMOR and String(arow.line) == "Old Tusk's Hide",
		"pane: worn unique armor row carries the de-equip op"
	)
	p.bag = PackedInt32Array([5, 0, 0, 2, 2, 0])
	var brows: Array = CharacterSheet.bag_rows(world)
	check(brows.size() == 2, "pane: bag rows mirror the bag")
	var b0: Dictionary = brows[0]
	check(
		String(b0.line) == ItemText.drop_line(world, {"kind": 5, "a": 0, "b": 0}),
		"pane: bag line IS the grammar line (tooltip parity)"
	)
	check(String(b0.tip).begins_with(String(b0.line)), "pane: tooltip leads with the grammar line")
	check(
		int(b0.equip_op) == BagStep.OP_EQUIP_BASE and int(b0.drop_op) == BagStep.OP_DROP_BASE,
		"pane: slot-0 op codes exact"
	)
	var b1: Dictionary = brows[1]
	check(
		(
			int(b1.equip_op) == BagStep.OP_EQUIP_BASE + 1
			and int(b1.drop_op) == BagStep.OP_DROP_BASE + 1
		),
		"pane: slot-1 op codes exact"
	)
	p.bag = PackedInt32Array()

	# 4. NEGATIVE: a legacy (bot-shaped) world renders without a class
	# row crash and shows the legacy shape.
	var lw: RefCounted = SimWorld.new()
	lw.setup(3, grid)
	lw.set_progression(load("res://data/progression.tres"))
	lw.set_stat_frame(StatFrame.load_frame())
	(
		lw
		. set_weapons(
			[
				load("res://data/weapons/longbolt.tres"),
				load("res://data/weapons/scattercast.tres"),
				load("res://data/weapons/wheelblade.tres"),
			]
		)
	)
	lw.add_player(Vector2(10.5, 10.5))
	var lrows: Array = CharacterSheet.sheet_rows(lw, {})
	check(_row(lrows, "class").begins_with("—"), "legacy world renders the — class row")
	check(
		CharacterSheet.equipment_rows(lw).is_empty() and CharacterSheet.bag_rows(lw).is_empty(),
		"NEGATIVE: legacy world gets no pane rows (bag never engages)"
	)

	if fails.is_empty():
		print("char_sheet_test: PASS (parity-exact/perturbation/quest-log/legacy/pane)")
		quit(0)
	else:
		for m: String in fails:
			printerr("char_sheet_test FAIL: " + m)
		quit(1)
