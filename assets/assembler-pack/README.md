# Wildshot Full Enemy Catalog Pack (native 1x)

This compatibility pack contains:

- 4 Production player sheets;
- 57 enemy families;
- 202 pre-baked enemy variations;
- 206 total native sprite sheets.

Every game sprite sheet is transparent, native 1x, and sliced into 24x24 cells.

## Install

Copy the `assembler-pack` folder into your game's asset directory:

```text
assets/assembler-pack/
```

Read `manifest.json` or the smaller files beneath `indexes/`. Do not scan
filenames or hardcode variant counts.

## Importing the variation system

The current enemy "modulation" system is a catalog of procedural family and
variant definitions. This pack pre-bakes every result so your game does not
need to run or port the assembler's JavaScript renderer.

Runtime selection:

```text
key = family_id + ":" + variant_id
record = enemy_variant_index[key]
sheet = load(record.sheet)
```

If a saved variant no longer exists, load the family's `default_variant`.
Depend only on stable family ids, variant ids, and sheet paths. The
`source_parameters_audit_only` object documents how the assembler produced a
variation but is not a stable game-facing rendering API.

## Current animation layout

- Sheet: 288x96
- Cell: 24x24
- Rows: Down, Left, Right, Up
- Idle: columns 0-1, 420 ms
- Walk: columns 2-5, 150 ms
- Attack: columns 6-9, 115 ms
- Hurt: columns 10-11, 140 ms

```text
x = (animation.start_column + frame_index) * 24
y = direction_row * 24
width = 24
height = 24
```

Use nearest-neighbor filtering. No floor shadow or effect is baked into the
actor PNGs.

## Compatibility status

This is manifest version 0 using the current approved 12-column contract. It
does not claim the future Cast/16-column Wildshot v1 contract. The importer
must derive animations and dimensions from `frame_contract`.

Compact effects and runtime procedural enemy recoloring are separate future
lanes. Neither is needed to use all 202 enemy variations
in a game today.

## Publishing

No public-distribution license has been selected in the assembler repository.
This pack is prepared for private development and testing. Replace LICENSE
with the intended asset license before redistribution or shipping.
