extends Resource
## Scenario definition (docs/12 §2.10 spawn/reset panel, TECH-10 lab
## subset): player spawn + inert stand-in layout + enemy spawn lists +
## default seed on the one lab arena. Full encounter authoring stays
## deferred (Stages 3–7).

@export var id: StringName = &""
@export var display_name: String = ""
## Arena definition this scenario plays on (visuals + collision derive
## from it together). Default: the lab arena.
@export var arena: String = "res://data/arena_lab.json"
## When set, this scenario plays on a WorldForge game pack instead of an
## arena def (the generated-test-arena ruling): validated + rendered by
## game/arena/world_builder.gd; collision comes from walkability.json.
@export var worldforge_pack: String = ""
## When set, the world_filler content pack at this dir becomes the
## living-world spawn tables (docs/23 S0 (d): territories + placements
## via game/arena/content_importer.gd — leash-gated sites, no new
## authoring format). Empty = no sites (every pre-slice scenario).
@export var content_pack: String = ""
## Persistent-world scenario (sl-0098: NO run framing — the world
## persists and refills). With a NORMAL-mode character aboard, death
## becomes the CORE-43 overworld shape: in-sim gold cost + respawn at
## the settlement + the walk back; T never rebuilds the world's
## meaning (it still reseeds — a lab tool, not a run). Hardcore and
## profile-free (bot) play keep dead-in-place.
@export var persistent_world: bool = false
@export var player_spawn: Vector2 = Vector2(24.0, 16.0)
@export var standin_positions: PackedVector2Array = PackedVector2Array()
## EnemyDef id (String) -> PackedVector2Array of tile positions. Spawn
## ORDER is def-roster order then array order — never Dictionary key
## order (§2.4 stable iteration; scenario_loader owns the loop).
@export var enemy_spawns: Dictionary = {}
## Extra EnemyDefs appended AFTER the standard roster (indexes stay
## stable). Exists for the §2.11 bot canaries — deliberately unfair
## defs that must never enter the shipped roster.
@export var extra_enemy_defs: Array[Resource] = []
## Test damage schedule (§2.11 elite transition proofs; planning log
## 2026-07-28): {tick: int, amount: int} entries the sim applies to the
## scenario's elite at exact tick equality through the one damage path
## (source tag -4). Amounts are final HP deltas. TEST SCENARIOS ONLY
## (tests/bot_scenarios) — no tester-reachable scenario may declare one
## (M7 pre-tester-build checklist line).
@export var damage_schedule: Array[Dictionary] = []
## S1 seam 6 (sl-0105): STARHOOK rift node cells (center coords) —
## authored spawn spots [T]; an INTERACT press at an ACTIVE node casts
## instantly (sl-0115 — the cast IS the aggro). Empty = none here.
@export var rift_nodes: PackedVector2Array = PackedVector2Array()
## sl-0115: authored node biomes, parallel to rift_nodes (0 nebula /
## 1 void / 2 comet; short or absent entries read nebula). The portal
## shows its biome before the cast.
@export var rift_node_biomes: PackedInt32Array = PackedInt32Array()
## sl-0115 (deck tap shk3spwn): this world rolls AMBIENT rift spawns —
## anywhere on walkable land, anytime (gather_step, rng_misc; tuning
## in balance_frame starhook.ambient [T]). Proof worlds stay false.
@export var rift_ambient: bool = false
## sl-0198 THE FORAGING BUILD: this world rolls AMBIENT forage-node
## spawns — ON candidate forage-prop cells (the pack-derived pool;
## WYSIWYG shimmer marks live nodes), capped world-wide [T]
## (gather_step, rng_misc's second consumer; tuning in balance_frame
## forage [T]). Proof worlds stay false.
@export var forage_ambient: bool = false
## True on rift-fight scenarios: the driver applies the RIFTER
## mini-class shape (sl-0105) instead of the main character, and the
## split-screen presentation mounts.
@export var starhook_rift: bool = false
## sl-0115 (amended sl-0123 — the drag is cut): the rift arena's LINE
## rules resource (drains, deep edge, three lives, graces —
## data/rift_line_def.gd). Required when starhook_rift; ignored
## elsewhere.
@export var rift_line: String = ""
## sl-0115: the arena's biome (indexes balance_frame starhook.biomes)
## and rarity step — set by the six rift scenarios; the fish table and
## the pattern-variant def follow from them.
@export var rift_biome: int = 0
@export var rift_rare: bool = false
## sl-0186: PATH rifts (the dungeon shape) are WALKED content — the
## standard clamped follow camera, full-screen galaxy, no split panes.
## The fixed one-room fit presentation stays the FIT rifts' law (the
## 12x13 arenas, Law 1 by construction); a 64x44 serpentine under that
## camera rendered as one room-sized window the player walked out of.
@export var rift_path: bool = false
## sl-0130 THE BANK: the settlement stash station cell (center
## coords). ZERO = no bank in this world (every pre-bank scenario).
## Deposit/withdraw ride recorded bag_op codes, legal only within
## bag_step's BANK_RADIUS of this cell; the panel is walk-up view.
@export var bank_cell: Vector2 = Vector2.ZERO
## sl-0131 VENDORS v1: station cells + parallel stock-set names
## (balance_frame vendors.stocks keys). Empty = no vendors here.
@export var vendor_cells: PackedVector2Array = PackedVector2Array()
@export var vendor_stocks: PackedStringArray = PackedStringArray()
## THE GEAR SEAM (sl-0177/0178): the tackle vendor station cell
## (center coords) — the rifter's gear shop, fish-priced. ZERO = no
## tackle vendor here (every pre-gear scenario). Ops ride recorded
## bag_op codes within VENDOR_RADIUS; the panel is the station view.
@export var tackle_cell: Vector2 = Vector2.ZERO
## THE NIGHT SEAM (sl-0221): the settlement table — ids, arrival
## cells, and SET-HOME waypost station cells, PARALLEL by index.
## Settlement 0 must be the capital with its cell == player_spawn
## (the default home preserves today's respawn exactly; test-pinned
## on the slice). Empty = no settlements: death keeps respawn_cell,
## the recall op refuses (labs, proofs, rifts, dungeons).
@export var settlement_ids: PackedStringArray = PackedStringArray()
@export var settlement_cells: PackedVector2Array = PackedVector2Array()
@export var waypost_cells: PackedVector2Array = PackedVector2Array()
@export var default_seed: int = 1
