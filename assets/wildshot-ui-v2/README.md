# Wildshot v2 UI pack

Pixel-art menu system for a 640x360 top-down ARPG (render scale x2/x3 in engine; font is 10px 'Wildshot Pixel', never subpixel).

## What is in here
- menus/<hue>/*.png - the 7 v2 menus (character, errands, quest offer, bank, vendor, loot bag, options) captured at 1x in each of the 4 hues: dusk (default), teal, slate, moss. Hues are hue-rotations of the dusk palette with gold accents + status colors pinned.
- surfaces/*.png - hue-independent surfaces on the v1 gilded chrome: HUD (bars + tracker), confirm dialog, tooltip, toast line.
- manifest.json - image index (file, spec_id, hue) + the full resolved 4x palettes (w* keys = chrome token roles, bg* = composite surfaces).
- menu-specs.json - THE SOURCE OF TRUTH: every menu as a declarative JSON spec (see 'spec_guide' entry inside it for the schema: panel fields, block kinds, live data sources, action grammar).
- assets/uikit/ - pixel chrome pieces + font. assets/icons/ - the 470-glyph item/quest icon atlas (atlas.json maps name -> {x,y,w,h}, 16px cells).

## How to use as an AI agent
1. To RENDER a menu: read its spec in menu-specs.json; blocks compose top-down (columns nest); every item row follows the one item-text grammar 'T<tier> <Name> - <stats>' with a 16px atlas icon.
2. To AUTHOR a new menu: copy a spec, keep ids stable, use only documented block kinds/actions; chrome 'panel2' = the ornate v2 look (carved frame + gold studs + title plaque via title/title_icon).
3. To RE-SKIN: apply a palette from manifest.json as CSS vars (--w0..--wV, --bg*) or hue-rotate dusk with the pinned-key list (w3,w4,w6,wN,wU + rad/lip/barTicks).
4. Legendary reveals: the rarity WORD (default UNIQUE) slams in as a gold word-mark, then a tattoo-style ribbon banner carries the item icon + name + stat line. See cinematics/ frames for the target look.

Palette anchors: gold #f2c14e / #ffd968, cream text #ffedd0, dusk body #443354->#302640, parchment #e8d6a8 (quest detail + ribbon faces), hp red / mana blue pinned.