extends RefCounted
## Typed sim-event vocabulary (docs/12 §2.1/§2.10): every attack, spawn,
## despawn, hit, damage, and kill flows through SimWorld.events as
## {"type": Type, "tick": int, ...}. Views, logs, and bots consume this one
## queue and never mutate sim. M3 carries the combat-resolution subset; the
## remaining §2.10 skeleton rows (telegraphs, hazards, ability/resource)
## land at M4/M6. No crit event exists anywhere, and none may be added
## (CORE-40).

enum Type {
	ATTACK_STARTED,
	PROJECTILE_SPAWNED,
	PROJECTILE_DESPAWNED,
	HIT_LANDED,
	DAMAGE_APPLIED,
	DAMAGE_BLOCKED,
	ENTITY_KILLED,
}

## PROJECTILE_DESPAWNED carries one of these (§2.6 typed despawn reasons).
enum DespawnReason {
	TTL,
	HIT,
	TERRAIN,
}

## DAMAGE_BLOCKED reasons. REGISTRY_FULL is the §2.6 deterministic overflow
## rule: all 8 registry slots used ⇒ unregistered targets take no damage.
enum BlockReason {
	REGISTRY_FULL,
}
