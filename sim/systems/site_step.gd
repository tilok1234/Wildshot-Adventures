extends RefCounted
## Ordered system: LIVING-WORLD PLUMBING v1 (docs/23 S0, sl-0100 seam
## 2). Three of the four ruled pieces live here; the importer is
## game-side (content_importer.gd) and the tether gate sits in
## enemy_step (it needs the AI loop's locals):
## - ACTIVATION LEASH: sites spawn dormant; a site WAKES when any
##   living player comes within WAKE_RADIUS (its population spawns
##   around the site cell) and SLEEPS when every player is beyond
##   SLEEP_RADIUS (wake + hysteresis) — live members fold back into
##   the dormant population WITH their current hp (damage persists;
##   kills persist: dead members simply never fold back).
## - DEPTH-KEYED RESPAWN: an emptied site re-arms only while DORMANT
##   (the player is away — nothing ever pops in anyone's face,
##   structurally) and refills to a fresh full pack when the timer
##   lands. Timers are zone-keyed by the importer (lazy Green, fast
##   Snow, W-3).
## - Spawn placement is deterministic (angular slots probed outward on
##   the conservative bitgrid — enemies are grid-walkers, sl-0078);
##   pack draws use rng_enemy (authored variation, §2.4).
## Site-less worlds (site_defs empty) return immediately — every
## pre-slice scenario is byte-identical by construction.
##
## `world` is duck-typed SimWorld (preload-cycle avoidance).

## Leash radii in tiles [T]: wake just past the default-zoom half
## screen (~18 t) so packs materialize off-screen; sleep = wake +
## hysteresis so pacing the boundary cannot strobe a site.
const WAKE_RADIUS := 22.0
const SLEEP_RADIUS := 30.0
## Tether [T]: a site member farther than this from its site cell
## disengages and walks home (enemy_step's gate); nobody migrates.
const TETHER_RADIUS := 12.0
## Deterministic spawn probe rings (tiles out from the site cell).
const SPAWN_RINGS: Array[float] = [2.0, 2.8, 3.6, 4.4]


static func run(world: RefCounted) -> void:
	var defs: Array = world.site_defs
	if defs.is_empty():
		return
	var t: int = world.tick
	var players: Array = world.players
	var folded: Dictionary = {}
	for i in defs.size():
		var def: Dictionary = defs[i]
		var site: Dictionary = world.sites[i]
		var home: Vector2 = def.cell
		# Nearest LIVING player distance (co-op safe, GDD-16).
		var best := 1.0e18
		for p: RefCounted in players:
			if p.dead:
				continue
			best = minf(best, p.pos.distance_to(home))
		var awake := bool(site.awake)
		if not awake and best <= WAKE_RADIUS:
			site.awake = true
			_spawn_population(world, i, def, site)
		elif awake and best > SLEEP_RADIUS:
			site.awake = false
			_fold_population(world, i, site, folded)
		# Away-only respawn: arm/refill strictly while dormant.
		if not bool(site.awake):
			var pop: PackedInt32Array = site.pop_def
			if pop.is_empty():
				if int(site.respawn_at) < 0:
					site.respawn_at = t + int(def.respawn_ticks)
				elif t >= int(site.respawn_at):
					fill_population(world, def, site)
					site.respawn_at = -1
	if not folded.is_empty():
		# Folded members leave the array WITHOUT dying — no kill event,
		# no sweep, no loot; they are the site's dormant stock now.
		world.enemies = world.enemies.filter(
			func(e: RefCounted) -> bool: return not folded.has(e.id)
		)


## Draw a fresh full pack into a site's dormant population (setup +
## respawn refills). Population size is bounded by max_active at draw
## time — the whole stock spawns on wake. Single-option draws consume
## NO rng (boss sites never touch the stream).
static func fill_population(world: RefCounted, def: Dictionary, site: Dictionary) -> void:
	var pack_min := int(def.pack_min)
	var pack_max := mini(int(def.pack_max), int(def.max_active))
	pack_min = mini(pack_min, pack_max)
	var size := pack_min
	if pack_max > pack_min:
		size = pack_min + world.rng_enemy.next_bounded(pack_max - pack_min + 1)
	var roster_defs: PackedInt32Array = def.roster_defs
	var roster_weights: PackedInt32Array = def.roster_weights
	var weight_sum := 0
	for w in roster_weights:
		weight_sum += w
	var pop_def := PackedInt32Array()
	var pop_hp := PackedInt32Array()
	for m in size:
		var pick := 0
		if roster_defs.size() > 1 and weight_sum > 0:
			var roll: int = world.rng_enemy.next_bounded(weight_sum)
			var acc := 0
			for ri in roster_defs.size():
				acc += roster_weights[ri]
				if roll < acc:
					pick = ri
					break
		var def_index := roster_defs[pick]
		pop_def.append(def_index)
		pop_hp.append(int(world.enemy_defs[def_index].hp))
	site.pop_def = pop_def
	site.pop_hp = pop_hp


## Wake: spawn every dormant member at deterministic angular slots
## probed outward on the bitgrid (fallback: the site cell itself —
## site cells are pack-verified walkable). Damaged survivors keep
## their stored hp.
static func _spawn_population(
	world: RefCounted, site_index: int, def: Dictionary, site: Dictionary
) -> void:
	var pop_def: PackedInt32Array = site.pop_def
	var pop_hp: PackedInt32Array = site.pop_hp
	var home: Vector2 = def.cell
	var n := pop_def.size()
	var grid: RefCounted = world.bitgrid
	for m in n:
		var angle := TAU * float(m) / float(maxi(1, n))
		var pos := home
		for r: float in SPAWN_RINGS:
			var probe: Vector2 = home + Vector2(cos(angle), sin(angle)) * r
			if not grid.is_solid(int(floorf(probe.x)), int(floorf(probe.y))):
				pos = Vector2(floorf(probe.x) + 0.5, floorf(probe.y) + 0.5)
				break
		var e: RefCounted = world.add_enemy(pop_def[m], pos)
		e.hp = pop_hp[m]
		e.site_index = site_index
	site.pop_def = PackedInt32Array()
	site.pop_hp = PackedInt32Array()


## Sleep: fold this site's LIVING members back into the dormant
## population with their current hp; their ids join `folded` and the
## caller removes them from the enemies array in one filter pass.
static func _fold_population(
	world: RefCounted, site_index: int, site: Dictionary, folded: Dictionary
) -> void:
	var pop_def := PackedInt32Array()
	var pop_hp := PackedInt32Array()
	for e: RefCounted in world.enemies:
		if e.site_index == site_index and e.hp > 0:
			pop_def.append(e.def_index)
			pop_hp.append(e.hp)
			folded[e.id] = true
	site.pop_def = pop_def
	site.pop_hp = pop_hp
