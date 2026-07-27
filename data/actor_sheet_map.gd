extends Resource
## Lab roster → assembler actor id (docs/12 §2.14 Amendment v2, docs/14).
## Keys are lab roles ("player", enemy ids at M5+); values are pack ids —
## players by actor id, enemies by "<family>:<variant>" catalog key
## (designer-picked 2026-07-27: Rusher=wolf:gray, Husk=skeleton:archer).
## Every actor NOT named here stays untouched by the lab (scope tripwire).

@export var map: Dictionary = {}
