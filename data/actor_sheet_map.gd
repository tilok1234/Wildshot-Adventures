extends Resource
## Lab roster → assembler actor id (docs/12 §2.14 Amendment v2, docs/14).
## Keys are lab roles ("player", enemy ids at M5+); values are pack ids —
## players by actor id, enemies by "<family>:<variant>" catalog key
## (designer-picked 2026-07-27: Rusher=wolf:gray, Husk=skeleton:archer).
## Every actor NOT named here stays untouched by the lab (scope tripwire).

@export var map: Dictionary = {}

## S1 (sl-0104 seam 1, docs/23 variability ruling): roles listed here
## carry their family's FULL catalog variant list — every variant
## imports and plays inside the zone. Values are Arrays of
## "<family>:<variant>" ids in catalog order; the view picks one PER
## ENEMY deterministically (sim id modulo count — cosmetic only, the
## split assigns identity, never behaviour). Roles absent here render
## their single `map` entry exactly as before.
@export var variants: Dictionary = {}
