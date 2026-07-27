extends Resource
## One equipped-ability definition (docs/12 §3.6, CORE-34: exactly one
## active per character, mana-fed, granted by the ability item — the
## skill tree grants no actives). The three Phase A test abilities are
## hard-coded KINDS behind data params (TECH-06 deferred, ledger #1;
## Quickdraw's cadence multiplier is ledger #2 — no stat pipeline).
## No encounter may require any of these (CORE-34; verified at M6 by a
## no-ability full clear, and every dodgeability proof runs ability-off).

enum Kind {
	NOVA,
	CADENCE_BUFF,
	PLACED_ZONE,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var mana_cost: int = 30
@export var kind: int = Kind.NOVA
## NOVA: damage + radius. CADENCE_BUFF: duration_ticks (multiplier is
## hard-coded 2/3 cadence — ledger #2). PLACED_ZONE: damage + radius +
## arm_ticks + place_range (tiles along aim).
@export var damage: int = 0
@export var radius: float = 0.0
@export var duration_ticks: int = 0
@export var arm_ticks: int = 0
@export var place_range: float = 0.0
