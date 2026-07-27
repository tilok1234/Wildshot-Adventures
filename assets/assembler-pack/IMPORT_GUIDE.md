# Generic enemy importer

1. Load `indexes/enemy-families.json` for family selection and fallbacks.
2. Load `indexes/enemy-variants.json` and map each record by its `key`.
3. Store `family` and `variant` ids in save data, not array positions.
4. Load the record's `sheet` path.
5. Slice using the manifest's cell, direction order, animation start column,
   frame count, and frame duration.
6. Use nearest-neighbor filtering and transparent blending.

Pseudo-code:

```text
families = load_json("indexes/enemy-families.json")
variants = index_by_key(load_json("indexes/enemy-variants.json").variants)

function resolve_enemy(family_id, variant_id):
    family = families.find(family_id)
    key = family_id + ":" + variant_id
    if not variants.has(key):
        key = family_id + ":" + family.default_variant
    return variants[key]
```

This data-driven route imports every current variation without embedding the
assembler renderer in the game. A renderer port is useful only if the game
must create new colors or geometry that were not exported ahead of time.
