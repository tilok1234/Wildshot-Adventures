# Wildshot NPC Slice v1

This is a local NPC intake/export package made from deterministic Player recipes at clean, pushed assembler commit `bf6269ca6fc07b3d95a826c95ec6c9c29c6daf53`. It does not modify the assembler's saved-player library.

## Runtime sheets

- Native frame: 24x24 pixels.
- Full sheet: 480x96 pixels.
- Rows: Down, Left, Right, Up.
- Columns: Idle 2, Walk 4, Attack 4, Cast 4, Hurt 2, Death 4.
- Presentation: Form shade, no added outline, effects off, transparent background, no baked shadow, binary alpha.

Use `characters/<id>.png` directly in the game. The matching Player recipe is embedded in `manifest.json` and repeated under `recipes/` for easy retuning or regeneration. `assembler-library.json` is a version-3 library payload containing the same 32 entries.

## Review

`review/contact-sheet.png` shows Down / Idle frame 1 for all 32 looks. Gold bars are named/system roles, green bars are zone quest-givers, and purple bars are ambient villagers. `review/contact-sheet-map.json` maps every cell to its stable id.

## Scope note

This is an NPC-only character export/intake pack, not the public Wildshot game-pack release. The separate game-pack license and effect-inclusion gates remain unchanged.
