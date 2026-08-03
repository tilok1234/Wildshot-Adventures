extends RefCounted
## THE TACKLE CATALOG (sl-0177/0178 — the gear seam): pure lookups over
## the stat frame's starhook block. A leaf constant module (the
## drop_kinds discipline): bag_step, damage, the profile, the loader,
## and the vendor panel all read the ONE catalog through here, so the
## shelf order, the species index space, and the ownership bit
## contract cannot fork. Nothing here mutates state or draws RNG.
##
## Contracts:
## - starhook.rods order is APPEND-ONLY (rod ladder indexes + owned
##   mask bits serialize);
## - starhook.tackle.items order is APPEND-ONLY (owned mask bits);
## - the SHELF = every PRICED row, rods first (rods order) then items
##   (items order) — recorded buy ops carry shelf row indexes, so this
##   derivation is part of the recorded-format contract;
## - species indexes are RUN-SCOPED (biome-major: three commons then
##   the rare, per biome) — the PROFILE keys fish by ID STRING, so a
##   future species re-roster (the fish-first word) is data-only.

const ROW_ROD := 0
const ROW_ITEM := 1


static func rods(frame: Dictionary) -> Array:
	return frame.get("starhook", {}).get("rods", [])


static func items(frame: Dictionary) -> Array:
	return frame.get("starhook", {}).get("tackle", {}).get("items", [])


static func tackle(frame: Dictionary) -> Dictionary:
	return frame.get("starhook", {}).get("tackle", {})


## Starhook level required to USE a tier ([T] ladder {1:1,2:3,3:5,4:8}).
static func tier_level(frame: Dictionary, tier: int) -> int:
	var tl: Dictionary = tackle(frame).get("tier_levels", {})
	return int(tl.get(str(tier), 99))


## The species index space: biome-major, three commons then the rare.
static func species_ids(frame: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for biome: Dictionary in frame.get("starhook", {}).get("biomes", []):
		for fr: Dictionary in biome.get("fish", []) as Array:
			out.append(String(fr.get("id", "")))
		out.append(String(biome.get("rare", {}).get("id", "")))
	return out


static func species_index(frame: Dictionary, species: String) -> int:
	return species_ids(frame).find(species)


static func species_name(frame: Dictionary, index: int) -> String:
	var i := 0
	for biome: Dictionary in frame.get("starhook", {}).get("biomes", []):
		for fr: Dictionary in biome.get("fish", []) as Array:
			if i == index:
				return String(fr.get("name", fr.get("id", "")))
			i += 1
		if i == index:
			return String(biome.get("rare", {}).get("name", biome.get("rare", {}).get("id", "")))
		i += 1
	return ""


## Every PRICED catalog row in shelf order (rods then items) —
## UNRESOLVED (price by species id string). Rows: {row_kind, index}.
static func shelf_rows(frame: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rlist := rods(frame)
	for ri in rlist.size():
		if (rlist[ri] as Dictionary).has("price"):
			out.append({"row_kind": ROW_ROD, "index": ri})
	var ilist := items(frame)
	for ii in ilist.size():
		if (ilist[ii] as Dictionary).has("price"):
			out.append({"row_kind": ROW_ITEM, "index": ii})
	return out


## The catalog row dict behind a shelf row.
static func row_data(frame: Dictionary, row: Dictionary) -> Dictionary:
	var idx := int(row.get("index", -1))
	if int(row.get("row_kind", -1)) == ROW_ROD:
		var rlist := rods(frame)
		return rlist[idx] if idx >= 0 and idx < rlist.size() else {}
	var ilist := items(frame)
	return ilist[idx] if idx >= 0 and idx < ilist.size() else {}


## Resolve a price dict (species id -> count) into index space.
## Returns {} on any unknown species (callers refuse loudly).
static func resolve_price(frame: Dictionary, price: Dictionary) -> Dictionary:
	var out := {}
	for sp: String in price:
		var si := species_index(frame, sp)
		if si < 0:
			return {}
		out[si] = int(price[sp])
	return out


## True when the fish array covers the resolved price.
static func can_afford(fish: PackedInt32Array, price_idx: Dictionary) -> bool:
	for si: int in price_idx:
		if si >= fish.size() or fish[si] < int(price_idx[si]):
			return false
	return true


## Ownership bit test for a shelf row against a player's masks.
static func owned(p: RefCounted, row: Dictionary) -> bool:
	var idx := int(row.get("index", -1))
	if idx < 0 or idx > 62:
		return true  # out-of-mask rows read owned = never granted twice
	if int(row.get("row_kind", -1)) == ROW_ROD:
		return (p.rods_owned_mask & (1 << idx)) != 0
	return (p.tackle_owned_mask & (1 << idx)) != 0
