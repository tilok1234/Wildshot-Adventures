extends Resource
## Loop v1 unique item (docs/19 ruling 2: boss-only, boss-tied, aimed
## grinding). [T] PLACEHOLDER MODEL until the designer specs the real
## first unique: picking it up sets the unique bit and boosts its frame
## slot to tier 6 (the tier table's top row). An honest stopgap — the
## drop, the toast, and the grind target are real; the item's identity
## is not yet.

@export var uid: StringName = &""
@export var display_name: String = ""
## Weapon frame slot this unique boosts (0=longbolt, 1=scattercast,
## 2=wheelblade).
@export var frame_slot: int = 0
