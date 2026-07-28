extends Node2D
## Projectile renderer. Patterns mapped in data/projectile_map.tres draw
## their pack sprite (one MultiMeshInstance2D per mapped pattern, native
## 1x px, oriented sprites rotate to their authored heading, the pack's
## own palette untinted — it owns the per-style hostile signature).
## UNMAPPED patterns keep the honest sphere fallback sized exactly to
## the collision circle (Law 8). Hostile nodes sit in the hostile band,
## friendly in the player band — separate nodes, structural (CORE-51
## Laws 2/3, §2.5). A view-side guard upscales any hostile sprite whose
## declared hitbox coverage falls below the live shot's circle (hostile
## visuals never under-render; friendly under-render is deliberate and
## player-favorable). Positions interpolate prev→curr per §2.9.
## View-only: reads the pool, never mutates.

const ActorState := preload("res://sim/actor_state.gd")
const RenderLayers := preload("res://game/render_layers.gd")

const TILE := 32.0
const SPHERE_TEX_PX := 16
## Long-axis stretch per tile/s of speed (14 t/s Longbolt ≈ 1.7x).
const STRETCH_PER_SPEED := 0.05
## Friendly shots render at 3/4 of their collision circle (designer call:
## smaller). Under-rendering FRIENDLY visuals is player-favorable and
## Law-8-benign; hostile shots may never render smaller than their
## hitboxes, and stay at full size.
const FRIENDLY_VISUAL_SCALE := 0.75
## Wheelblade-style two-frame spin period (~150 ms per pack notes).
const ALT_FRAME_TICKS := 9

var world: RefCounted = null
var clock: RefCounted = null
## ProjectileSprites library + projectile_map resource; when either is
## missing every pattern falls back to spheres.
var sprites: RefCounted = null
var pattern_map: Resource = null
## EffectLibrary (M6 ledger #9): FRIENDLY-channel alpha only. Hostile
## rendering below never reads it — the §2.6 clamp is structural.
var effects: RefCounted = null

var _friendly := MultiMeshInstance2D.new()
var _hostile := MultiMeshInstance2D.new()
var _allocated := false
## pattern_id -> {mmi, entry, base_tex, alt_tex, count, friendly}
var _mapped: Dictionary = {}
var _friendly_base_alpha := 1.0


func _ready() -> void:
	var sphere := _make_sphere_texture()
	_setup_mmi(_friendly, Color(0.82, 0.9, 1.0), sphere)
	_setup_mmi(_hostile, Color(1.0, 0.36, 0.28), sphere)
	# §2.5 bands: hostile projectiles above damage numbers above player
	# shots — structural, not tree-order luck.
	_friendly.z_index = RenderLayers.PLAYER_PROJECTILES
	_hostile.z_index = RenderLayers.HOSTILE_PROJECTILES
	add_child(_friendly)
	add_child(_hostile)
	_build_mapped_nodes()


## One MMI per mapped pattern, textured from the pack, banded by the
## sprite's own §2.5 band declaration.
func _build_mapped_nodes() -> void:
	if sprites == null or pattern_map == null:
		return
	for pid in pattern_map.shots:
		var sid := String(pattern_map.shots[pid])
		if not sprites.has_sprite(sid):
			push_error("projectile_view: pattern %d maps to missing sprite '%s'" % [int(pid), sid])
			continue
		var entry: Dictionary = sprites.entry(sid)
		var mmi := MultiMeshInstance2D.new()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_2D
		var quad := QuadMesh.new()
		quad.size = Vector2(2.0, 2.0)
		mm.mesh = quad
		mmi.multimesh = mm
		mmi.texture = entry.tex
		mmi.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mmi.z_index = (
			RenderLayers.PLAYER_PROJECTILES
			if int(entry.band) <= 5
			else RenderLayers.HOSTILE_PROJECTILES
		)
		add_child(mmi)
		var alt_tex: Texture2D = null
		if pattern_map.alts.has(pid):
			var aid := String(pattern_map.alts[pid])
			if sprites.has_sprite(aid):
				alt_tex = sprites.entry(aid).tex
		_mapped[int(pid)] = {
			"mmi": mmi,
			"entry": entry,
			"base_tex": entry.tex,
			"alt_tex": alt_tex,
			"count": 0,
			"friendly": int(entry.band) <= 5,
		}


func _process(_delta: float) -> void:
	if world == null:
		return
	var pool: RefCounted = world.projectiles
	if not _allocated:
		_friendly.multimesh.instance_count = pool.CAPACITY
		_hostile.multimesh.instance_count = pool.CAPACITY
		for pid: int in _mapped:
			_mapped[pid].mmi.multimesh.instance_count = pool.CAPACITY
		_allocated = true
	var interp: bool = clock != null and clock.interp_enabled
	var alpha: float = clock.alpha() if clock != null else 1.0
	# FRIENDLY-channel opacity (EffectLibrary): applied to the friendly
	# sphere MMI and friendly-band mapped nodes only. The hostile MMI and
	# hostile-band nodes are never modulated here — §2.6 clamp.
	var fa: float = effects.friendly_alpha() if effects != null else 1.0
	if not is_equal_approx(fa, _friendly_base_alpha):
		_friendly_base_alpha = fa
		_friendly.modulate.a = fa
		for pid: int in _mapped:
			var mn: Dictionary = _mapped[pid]
			if bool(mn.friendly):
				mn.mmi.modulate = Color(1.0, 1.0, 1.0, fa)
	var px: PackedFloat32Array = pool.pos_x
	var py: PackedFloat32Array = pool.pos_y
	var qx: PackedFloat32Array = pool.prev_x
	var qy: PackedFloat32Array = pool.prev_y
	var vx: PackedFloat32Array = pool.vel_x
	var vy: PackedFloat32Array = pool.vel_y
	var dx_: PackedFloat32Array = pool.dir_x
	var dy_: PackedFloat32Array = pool.dir_y
	var rad: PackedFloat32Array = pool.radius
	var fac: PackedByteArray = pool.faction
	var act: PackedByteArray = pool.active
	var pat: PackedInt32Array = pool.pattern_id
	var mm_f: MultiMesh = _friendly.multimesh
	var mm_h: MultiMesh = _hostile.multimesh
	var n_f := 0
	var n_h := 0
	for pid: int in _mapped:
		var node: Dictionary = _mapped[pid]
		node.count = 0
		# Two-frame spin (Wheelblade): global phase from the sim tick —
		# deterministic and uniform across instances.
		if node.alt_tex != null:
			var phase: int = (int(world.tick) / ALT_FRAME_TICKS) % 2
			node.mmi.texture = node.alt_tex if phase == 1 else node.base_tex
	for s in pool.CAPACITY:
		if act[s] == 0:
			continue
		var x: float = px[s]
		var y: float = py[s]
		if interp:
			x = qx[s] + (x - qx[s]) * alpha
			y = qy[s] + (y - qy[s]) * alpha
		var pos := Vector2(x, y) * TILE
		var mapped: Dictionary = _mapped.get(pat[s], {})
		if not mapped.is_empty():
			var entry: Dictionary = mapped.entry
			var hw := float(entry.w) * 0.5
			var hh := float(entry.h) * 0.5
			# Law 2/8 guard: a hostile sprite may never render smaller
			# than the live shot's hitbox — upscale on declared shortfall.
			if fac[s] == ActorState.FACTION_HOSTILE and int(entry.hitbox_d) > 0:
				var need := rad[s] * 2.0 * TILE
				if float(entry.hitbox_d) < need:
					var fix := need / float(entry.hitbox_d)
					hw *= fix
					hh *= fix
			var xf: Transform2D
			if bool(entry.oriented):
				var dir := Vector2(dx_[s], dy_[s])
				if dir.length_squared() < 0.0001:
					dir = Vector2.RIGHT
				xf = Transform2D(dir * hw, Vector2(-dir.y, dir.x) * hh, pos)
			else:
				xf = Transform2D(Vector2(hw, 0.0), Vector2(0.0, hh), pos)
			var k: int = mapped.count
			mapped.mmi.multimesh.set_instance_transform_2d(k, xf)
			mapped.count = k + 1
			continue
		var sc: float = rad[s] * TILE
		if fac[s] == ActorState.FACTION_HOSTILE:
			# Unmapped hostile: the honest sphere, sized to the hitbox.
			mm_h.set_instance_transform_2d(
				n_h, Transform2D(Vector2(sc, 0.0), Vector2(0.0, sc), pos)
			)
			n_h += 1
		else:
			# Friendly spheres stretch along travel: at 14 t/s a shot
			# moves ~75% of its diameter per frame and strobes as dots;
			# elongation reads as motion (genre-standard). Cross-axis
			# stays honest to the collision circle.
			var fsc := sc * FRIENDLY_VISUAL_SCALE
			var vxs: float = vx[s]
			var vys: float = vy[s]
			var vlen := sqrt(vxs * vxs + vys * vys)
			var xf2: Transform2D
			if vlen > 0.01:
				var dir2 := Vector2(vxs / vlen, vys / vlen)
				var stretch: float = fsc * (1.0 + vlen * STRETCH_PER_SPEED)
				xf2 = Transform2D(dir2 * stretch, Vector2(-dir2.y, dir2.x) * fsc, pos)
			else:
				xf2 = Transform2D(Vector2(fsc, 0.0), Vector2(0.0, fsc), pos)
			mm_f.set_instance_transform_2d(n_f, xf2)
			n_f += 1
	mm_f.visible_instance_count = n_f
	mm_h.visible_instance_count = n_h
	for pid: int in _mapped:
		var node2: Dictionary = _mapped[pid]
		node2.mmi.multimesh.visible_instance_count = node2.count


static func _setup_mmi(mmi: MultiMeshInstance2D, color: Color, tex: Texture2D) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)  # unit quad; instance scale = radius*TILE
	mm.mesh = quad
	mmi.multimesh = mm
	mmi.modulate = color
	mmi.texture = tex


## Small white sphere: filled circle with an up-left highlight and a hard
## pixel edge (Nearest filtering keeps it crisp). Faction color comes from
## node modulate.
static func _make_sphere_texture() -> ImageTexture:
	var img := Image.create(SPHERE_TEX_PX, SPHERE_TEX_PX, false, Image.FORMAT_RGBA8)
	var c := (SPHERE_TEX_PX - 1) / 2.0
	for y in SPHERE_TEX_PX:
		for x in SPHERE_TEX_PX:
			var d := Vector2(x - c, y - c).length() / c
			if d > 1.0:
				continue
			var hl := Vector2(x - c + c * 0.35, y - c + c * 0.35).length() / c
			var b := clampf(1.1 - 0.5 * hl, 0.55, 1.0)
			img.set_pixel(x, y, Color(b, b, b, 1.0))
	return ImageTexture.create_from_image(img)
