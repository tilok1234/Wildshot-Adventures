extends RefCounted
## Typed sim-event vocabulary (docs/12 §2.1): every spawn/despawn/hit flows
## through SimWorld.events as {"type": Type, "tick": int, ...}. Views, logs,
## and bots consume this one queue and never mutate sim. M2 carries the
## minimal rig subset — the full 13-event skeleton incl. despawn reasons
## lands at M4 (§2.10). No crit event exists anywhere (CORE-40).

enum Type {
	PROJECTILE_SPAWNED,
	PROJECTILE_DESPAWNED,
	HIT_LANDED,
}
