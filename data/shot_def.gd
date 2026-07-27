extends Resource
## One shot in a weapon volley (docs/12 §2.6). Angles are authored offsets
## from the aim vector — patterns are deterministic and authored, never
## random (CORE-32: no bloom, no drift). Program params feed the §2.6
## motion programs (pure functions of ticks-since-spawn).

@export var angle_offset_deg: float = 0.0
@export var speed: float = 10.0
@export var radius: float = 0.15
@export var damage: int = 1
@export var ttl_ticks: int = 60
## sim/projectile_pool.gd Program enum value.
@export var program: int = 0
@export var prog_a: float = 0.0
@export var prog_b: float = 0.0
@export var prog_c: float = 0.0
## 0 = despawn on first hit; N = pierce, max N damage passes per target
## via the hit registry.
@export var max_passes: int = 0
## Spawn distance along the aim vector, in tiles — shots appear at the
## muzzle, not inside the body. Still a pure function of (aim, pos).
@export var spawn_offset: float = 0.0
