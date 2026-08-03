extends Node2D
## NPC presence layer (slice S0 seam 4, sl-0100: "NPCs stationed in
## settlements — presence over motion", W-8). PURE VIEW: no sim actor,
## no AI, no interaction surface, nothing an aim or damage path could
## ever read (CORE-35 stays absolute). Each of the 32 pack looks
## stands at a deterministic station playing idle:
## - ZONE QUEST-GIVERS at their zone's content-pack giver-slot cells
##   (in slot order; the pack authored those cells);
## - everyone else (named roles, ambient crowd, multi-zone looks,
##   giver overflow) scattered around the settlement spawn on a
##   deterministic golden-angle spiral, walkability-probed on the
##   conservative bitgrid.
## Sits inside main's y-sorted ActorSortSpace so players walk in
## front of and behind NPCs like any other body. Quest wiring is
## chapter work — today they hold the ground the quests will stand
## on.

const AssemblerLibrary := preload("res://game/views/assembler_library.gd")

const TILE := 32.0
## NPC manifest zone -> content-plan giver-slot zone prefix.
const ZONE_MAP := {
	"green-country": "green",
	"dry-reach": "dry",
	"wetland": "wet",
	"snow-country": "cold",
}

var _stations: Array[Dictionary] = []


## sl-0176: authored def cell -> body station cell for every station
## that answers for an authored cell (zone givers + pinned bodies).
## The overhead giver icons anchor to the BODY the player actually
## sees; the sim's interact radius stays on the authored cell.
func giver_map() -> Dictionary:
	return giver_cell_map(_stations)


static func giver_cell_map(stations: Array[Dictionary]) -> Dictionary:
	var out: Dictionary = {}
	for st: Dictionary in stations:
		if st.has("def_cell"):
			out[st.def_cell] = st.cell
	return out


## Build stations + sprites. `content_pack` = the resolved pack dir;
## `bitgrid` = the world's conservative grid; `spawn` = the
## settlement spawn cell the crowd scatters around.
func setup(lib: RefCounted, content_pack: String, bitgrid: RefCounted, spawn: Vector2) -> bool:
	var npc_manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://npcs/manifest.json")
	)
	if not npc_manifest is Dictionary:
		push_error("npc_view: res://npcs/manifest.json missing — run tools/import_npcs.py")
		return false
	var plan: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(content_pack + "content-plan.json")
	)
	if not plan is Dictionary:
		push_error("npc_view: content pack unreadable at " + content_pack)
		return false
	_stations = compute_stations(npc_manifest, plan, bitgrid, spawn)
	for st: Dictionary in _stations:
		var frames: SpriteFrames = lib.build_sprite_frames(String(st.id))
		if frames == null:
			continue
		var spr := AnimatedSprite2D.new()
		spr.sprite_frames = frames
		spr.scale = Vector2.ONE * lib.render_scale()
		var cell: Vector2 = st.cell
		spr.position = cell * TILE
		spr.play("idle-down")
		# sl-0132: deterministic per-NPC phase offset + a tiny rate
		# wobble [T ±10%] — the crowd stops breathing in lockstep.
		# Stable station-cell hash (the arena_builder variant_hash
		# discipline: not RNG, same look every boot, replay-free);
		# future vendor/banker bodies inherit this loop for free.
		var h := _phase_hash(int(cell.x), int(cell.y))
		var idle_n := frames.get_frame_count("idle-down")
		if idle_n > 0:
			spr.set_frame_and_progress(h % idle_n, float((h / 7) % 97) / 97.0)
		spr.speed_scale = 0.9 + 0.2 * (float((h / 13) % 89) / 89.0)
		add_child(spr)
	return true


## Deterministic position hash (the arena_builder.gd variant_hash fold
## — any stable per-cell choice is seam-safe; NOT RNG, no stream).
static func _phase_hash(x: int, y: int) -> int:
	var h := x * 374761393 + y * 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return (h ^ (h >> 16)) & 0x7FFFFFFF


## Deterministic station table — static + pure so the wiring test pins
## sl-0130/0131: manifest ids pinned to authored station cells
## (matching the slice scenario's sim-side cells: bank 112.5,182.5;
## vendors 106.5,182.5 + 106.5,180.5). The body marks the ground;
## the sim owns the interaction.
const PINNED_STATIONS := {
	"capital-stash-keeper": Vector2(112.5, 182.5),
	"capital-general-merchant": Vector2(106.5, 182.5),
	"settlement-trader": Vector2(106.5, 180.5),
	# sl-0177/0178: the tackle keeper — the pack's own dock-fisher
	# body marks the gear shop (matching slice tackle_cell).
	"dock-fisher-teacher": Vector2(110.5, 178.5),
}


## it without a scene. Returns [{id, cell: Vector2 (center)}].
static func compute_stations(
	npc_manifest: Dictionary, plan: Dictionary, bitgrid: RefCounted, spawn: Vector2
) -> Array[Dictionary]:
	# Zone giver cells in slot order, skipping slots parked on the
	# spawn cell itself (the capital system slots all point there —
	# the crowd spiral owns that ground).
	var zone_cells: Dictionary = {}
	var givers: Array = plan.get("giverSlots", [])
	for g: Dictionary in givers:
		var gid := String(g.get("id", ""))
		if not gid.begins_with("giver.zone."):
			continue
		var zid := String(g.get("zoneId", ""))
		var zparts := zid.split(".")
		var zkey := zparts[1] if zparts.size() >= 2 else zid
		var cell: Array = g.get("cell", [0, 0])
		var cv := Vector2(float(int(cell[0])) + 0.5, float(int(cell[1])) + 0.5)
		if cv.distance_to(spawn) < 2.0:
			continue
		if not zone_cells.has(zkey):
			zone_cells[zkey] = []
		(zone_cells[zkey] as Array).append(cv)
	var used: Dictionary = {}
	var out: Array[Dictionary] = []
	var crowd: Array[String] = []
	var actors: Array = npc_manifest.get("actors", [])
	for a: Dictionary in actors:
		var aid := String(a.get("id", ""))
		var group := String(a.get("group", ""))
		var zone := String(a.get("zone", ""))
		var zkey := String(ZONE_MAP.get(zone, ""))
		# sl-0130: bodies pinned to station cells (the stash keeper at
		# the bank cell; vendors join at sl-0131) — the body marks the
		# ground, the sim owns the interaction (CORE-35 pure view).
		if PINNED_STATIONS.has(aid):
			var pin: Vector2 = PINNED_STATIONS[aid]
			out.append({"id": aid, "cell": _nudge_walkable(bitgrid, pin), "def_cell": pin})
			continue
		if group == "zone-quest-giver" and not zkey.is_empty() and zone_cells.has(zkey):
			var cells: Array = zone_cells[zkey]
			var next_i := int(used.get(zkey, 0))
			if next_i < cells.size():
				used[zkey] = next_i + 1
				# Giver cells are pack-authored at structures — some sit
				# on solid footprint cells (doorsteps). Nudge to the
				# nearest walkable cell, deterministically. The authored
				# cell rides along (def_cell) so overhead icons can
				# anchor to the body the nudge placed (sl-0176).
				var authored: Vector2 = cells[next_i]
				out.append(
					{"id": aid, "cell": _nudge_walkable(bitgrid, authored), "def_cell": authored}
				)
				continue
		crowd.append(aid)
	# Settlement crowd: golden-angle spiral, walkability-probed.
	var spiral_i := 0
	for aid: String in crowd:
		var cell := _spiral_cell(bitgrid, spawn, spiral_i)
		spiral_i = int(cell.z) + 1
		out.append({"id": aid, "cell": Vector2(cell.x, cell.y)})
	return out


## Nearest walkable cell center to `cell` (itself if open): scans
## rings of increasing radius in fixed row-major order — deterministic.
static func _nudge_walkable(bitgrid: RefCounted, cell: Vector2) -> Vector2:
	var cx := int(floorf(cell.x))
	var cy := int(floorf(cell.y))
	if not bitgrid.is_solid(cx, cy):
		return cell
	for r in range(1, 5):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				if not bitgrid.is_solid(cx + dx, cy + dy):
					return Vector2(float(cx + dx) + 0.5, float(cy + dy) + 0.5)
	return cell


## Next walkable golden-angle spiral cell from `start_i` (z = the
## index consumed, so callers keep the sequence deterministic).
static func _spiral_cell(bitgrid: RefCounted, spawn: Vector2, start_i: int) -> Vector3:
	for i in range(start_i, start_i + 80):
		var r := 1.8 + 0.32 * float(i)
		var theta := float(i) * 2.399963
		var probe: Vector2 = spawn + Vector2(cos(theta), sin(theta)) * r
		var cx := int(floorf(probe.x))
		var cy := int(floorf(probe.y))
		if not bitgrid.is_solid(cx, cy):
			return Vector3(float(cx) + 0.5, float(cy) + 0.5, float(i))
	return Vector3(spawn.x, spawn.y, float(start_i))


func station_count() -> int:
	return _stations.size()
