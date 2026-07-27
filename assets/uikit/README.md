# wildshot-ui kit v1 (gilded)

Doc 13-UI_STYLE_KIT_SPEC deliverable. Authored at 1x base-res pixels for the 640x360 viewport,
integer scaling only, binary alpha throughout, no animated pieces.

## Contents
- Tier 1: panels, button x5 states, checkbox, slider, focus ring, bars + fills, cursors, autofire + 8 icons, font.
- Tier 2: tabs, popup panel + item hover, scrollbar, LineEdit x2, tooltip, icon_export, icon_replay.
- manifest.json lists every piece with kind / 9-slice margins (left,top,right,bottom) / hotspots.

## Palette (role-keyed; theme variants remap under same ids)
chrome_dark #2f2557 - chrome_mid #4a3d80 - chrome_light #8f7cce - accent_1 (gold) #f2c14e - accent_2 (blue) #3f7de8
Derived pixel shades (outline #1c1030, gold trim #ffd968/#c9932e/#a06f22, text #cfc4ec/#f2ead8, HP #d63a4e, mana #3f7de8, check green #7ee85a) are polish-pass material, not contract.
NOTE: the gilded theme intentionally waives the doc-13 Law 6 quiet-chrome baseline (owner call, 2026-07-27); keep hostile telegraphs full-saturation #ff5233+ so they still outshine the gold trim.

## State rules (CORE-50)
hover = value step, pressed = inverted bevel + 1px content inset, disabled = dimmed flat,
focus = drawn 1px bright outline (button_focus / focus_ring / *_focus drawn OVER the base state).
No state differs by hue alone. HP vs mana fills differ by pattern (ticks vs diagonal), not hue alone.

## Godot import (addons/uikit_importer)
- PNGs: texture filter NEAREST (no mipmaps). StyleBoxTexture per nineslice piece using manifest margins.
- Fills: tile horizontally (AXIS_STRETCH_MODE_TILE) inside bar_frame's 2px padding.
- Font: FontFile, antialiasing OFF, hinting None, use at 10px or integer multiples (7px cap height, 12px line).
- Cursors: Input.set_custom_mouse_cursor(tex, shape, hotspot) - hotspots in manifest.
- Buttons: content margin +1px down/right on pressed for the 1px content inset.

## License
Everything self-produced for Wildshot Adventures, 2026-07-27. Art: CC0. Font: CC0 (font/LICENSE).
