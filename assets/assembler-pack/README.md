# Wildshot Assembler Compatibility Pack (native 1x)

This is a ready-to-use game-development pack containing 4 Production characters
and 6 enemies. Every sprite sheet is native 1x with transparent 24x24 cells.

## Install

Copy the `assembler-pack` folder into your game's asset directory. The proposed
Wildshot location is:

```text
assets/assembler-pack/
```

Load `manifest.json` as the source of truth. Do not hardcode the sheet width.

## Current frame layout

- Sheet: 288x96 pixels
- Cell: 24x24 pixels
- Rows: Down, Left, Right, Up
- Idle: columns 0-1, 420 ms per frame
- Walk: columns 2-5, 150 ms per frame
- Attack: columns 6-9, 115 ms per frame
- Hurt: columns 10-11, 140 ms per frame

Source rectangle:

```text
x = (animation.start_column + frame_index) * 24
y = direction_row * 24
width = 24
height = 24
```

Use nearest-neighbor filtering and place the 24x24 cell at the actor's chosen
world origin. The PNGs have transparent backgrounds and no baked floor shadow.

## Compatibility status

This is manifest version 0: a practical current-contract pack, not the final
Wildshot v1. It does not contain Cast, Death, or compact effect sheets. Those
features will be added through separately reviewed assembler slices. Your
importer should read `frame_contract` so the future 16-column v1 layout can be
accepted without rewriting animation slicing.

## Publishing

No public-distribution license has been selected in the assembler repository.
This pack is prepared for private game development and testing. Choose and
replace the included LICENSE text before distributing or shipping the assets.
