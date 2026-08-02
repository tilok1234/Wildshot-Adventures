extends Resource
## Quest definition (S1 seam 5, sl-0104; docs/23 disposition 5:
## GENERIC FIRST — kill/fetch/visit off the giver slots, each carrying
## its slot's REASON tag; the villager-reason pillar for free.
## Hand-authoring is reserved for where it feels needed, later).
## Pure data — the sim's quest_step owns behavior; ids are the
## profile's stable keys (append-only list in scenario_loader).

enum Kind { KILL, VISIT, COLLECT }

@export var id: StringName = &""
## One line the giver says — plain words, the reason visible.
@export var text: String = ""
## The giver slot's REASON tag (content-plan vocabulary: zone_hub /
## waystation / ...). Shown with the quest line everywhere.
@export var reason: String = ""
## The giver's cell (content-pack giver-slot cell, center coords).
## Accept AND turn-in happen here, walk-up, one active at a time.
@export var giver_cell: Vector2 = Vector2.ZERO
@export var kind: Kind = Kind.KILL
## KILL: roster def indexes that count.
@export var target_defs: PackedInt32Array = PackedInt32Array()
## VISIT: reaching within visit_radius of this cell completes.
@export var target_cell: Vector2 = Vector2.ZERO
@export var visit_radius: float = 6.0
## KILL/COLLECT: how many.
@export var count: int = 1
@export var reward_gold: int = 20
@export var reward_xp: int = 25
