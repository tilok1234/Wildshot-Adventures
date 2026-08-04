extends Node2D
## sl-0190 — NAMES OVER FUNCTIONAL NPCS ("vendors and quest npcs and
## the alike is really hard to spot"). Nameplates over the
## INTERACTABLE class ONLY: the station-table entries that carry a
## def_cell — pinned station bodies (bank / merchant / trader /
## tackle keeper), zone quest givers, and the sl-0204 capital hub
## giver. Crowd NPCs stay unlabeled by the designer's own scoping,
## structurally: crowd rows carry no def_cell.
##
## V1 labels = ROLE WORDS auto-derived from the interact registry
## (zero authoring); data/npc_names.json is THE NAME TABLE underneath
## — the designer's proper-name pass fills it per actor id, data-only.
## Display [T]: icon above name (the plate top kisses the quest
## icon's bottom at LIFT 18), always-on (the ask is visibility), the
## same HP_BARS structural occlusion as the icons — the body's own
## sprite, props, and canopy crowns can never cover it. Pure view
## (CORE-35): never selection, never hover, reads sim nothing — the
## station table is deterministic pack data.
##
## sl-0205 ("the npc names are really broken-"): the kit font is a
## strict-grid pixel TTF whose own license line is the law — "use at
## 10 px (or integer multiples)". The plates rendered at 8 px, the
## game's ONLY off-grid consumer: with AA/hinting/subpixel all OFF
## (the kit import), 0.8-scale rasterization drops and merges stems
## and letterforms genuinely mutate ('Banker' grew a collapsed 'k',
## 'Trader' lost its T-arm). Text renders at the font's native 10
## now; the plate carries the font's own 12 px line.

const RenderLayers := preload("res://game/render_layers.gd")

const TILE := 32.0
## The quest icon sits at LIFT 18 (bottom) — the plate stacks under
## it, over the head (24 px @1x body: head top 12 above center).
## FONT_SIZE 10 = the kit font's native grid (sl-0205 — never render
## it off-grid); PLATE_H 12 = the font's own line height. Baseline
## sits at PLATE_TOP + 9: 7 px cap height under a 2 px top pad, 1 px
## clear of the 2 px descender.
const PLATE_TOP := -19.0
const PLATE_H := 12.0
const FONT_SIZE := 10
const TEXT_COLOR := Color(0.96, 0.92, 0.85)
const BACK_COLOR := Color(0.04, 0.05, 0.08, 0.55)

## Role words per pinned station id (the interact registry's own
## vocabulary — sl-0130 bank, sl-0131 vendors, sl-0177 tackle).
const ROLE_LABELS := {
	"capital-stash-keeper": "Banker",
	"capital-general-merchant": "Merchant",
	"settlement-trader": "Trader",
	"dock-fisher-teacher": "Tackle Keeper",
}
const GIVER_LABEL := "Quest Giver"

var stations: Array[Dictionary] = []
var names: Dictionary = {}

var _font: Font = null


func _ready() -> void:
	z_index = RenderLayers.HP_BARS
	var theme: Theme = load("res://ui/theme.tres")
	_font = theme.default_font if theme != null else ThemeDB.fallback_font


## ---- PURE MODEL (probe/test-testable without a scene) ----
## The plated set: exactly the interactable-bodied stations (def_cell
## marks them — pinned bodies + zone givers; crowd rows carry none).
static func plated(all_stations: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for st: Dictionary in all_stations:
		if st.has("def_cell"):
			out.append(st)
	return out


## Name resolution: the designer's table wins; the registry's role
## word rules otherwise; unknown functional ids read as quest givers
## (the only other def_cell class today).
static func label_for(id: String, name_table: Dictionary) -> String:
	if name_table.has(id):
		return String(name_table[id])
	if ROLE_LABELS.has(id):
		return String(ROLE_LABELS[id])
	return GIVER_LABEL


## The name table (data/npc_names.json): malformed = loud + empty,
## absent = empty (role labels rule).
static func load_name_table() -> Dictionary:
	if not FileAccess.file_exists("res://data/npc_names.json"):
		return {}
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/npc_names.json")
	)
	if not parsed is Dictionary or not (parsed as Dictionary).get("names") is Dictionary:
		push_error("npc_nameplates: data/npc_names.json malformed — role labels rule")
		return {}
	return (parsed as Dictionary).names


func _draw() -> void:
	if _font == null:
		return
	for st: Dictionary in plated(stations):
		var label := label_for(String(st.id), names)
		if label.is_empty():
			continue
		var px: Vector2 = (Vector2(st.cell) * TILE).round()
		var w: float = _font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, FONT_SIZE).x
		draw_rect(
			Rect2(px + Vector2(-w * 0.5 - 2.0, PLATE_TOP), Vector2(w + 4.0, PLATE_H)), BACK_COLOR
		)
		draw_string(
			_font,
			px + Vector2(-w * 0.5, PLATE_TOP + 9.0),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			FONT_SIZE,
			TEXT_COLOR
		)
