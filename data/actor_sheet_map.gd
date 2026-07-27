extends Resource
## Lab roster → Sprite Forge actor id (docs/12 §2.14). Keys are lab roles
## ("player", enemy ids at M5+); values are actor ids from
## assets/spriteforge/manifest.json. Hand-picked from the 231-actor pack —
## every actor NOT named here stays untouched by the lab (scope tripwire).

@export var map: Dictionary = {}
