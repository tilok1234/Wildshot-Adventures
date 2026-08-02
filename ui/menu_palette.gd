extends RefCounted
## THE MENU PASS palette (sl-0155 pack): the dusk hue's chrome tokens,
## mirrored from assets/wildshot-ui-v2/manifest.json palettes.dusk (the
## workbench's CSS token model). This module is the ONE swap point for
## the doc-13 theme model — a future hue/art pack re-skins menus by
## replacing these constants (structure stays frozen; the seam-A
## finding: the v2 look is DRAWN chrome over tokens, not kit pixels).
## View/UI-side only.

## Body gradient (bgPanel: w5 -> wV).
const BODY_TOP := Color("#443354")
const BODY_BOTTOM := Color("#302640")
## Carved frame: outer dark carve (lipC) + inner lighter lip (w8).
const EDGE_DARK := Color("#161020")
const EDGE_LIP := Color("#5c4a74")
## Gold accents (w3 / wN / w4) — pinned across hues by the pack.
const GOLD := Color("#f2c14e")
const GOLD_BRIGHT := Color("#ffd968")
const GOLD_DIM := Color("#a06f22")
## Text roles (the spec_guide swatches).
const TEXT_BRIGHT := Color("#f2ead8")
const TEXT_BASE := Color("#cfc4ec")
const TEXT_DIM := Color("#8f7cce")
## Item slots (bgSlot / bgSlotHov / wH edge).
const SLOT_BG := Color("#2a2136")
const SLOT_HOVER := Color("#453558")
const SLOT_EDGE := Color("#4a3a5e")
## Title plaque gradient (plqGrad) + inset panels.
const PLAQUE_TOP := Color("#554466")
const PLAQUE_BOTTOM := Color("#3a2c48")
const INSET_BG := Color("#2a2136")
## Tab strip (bgTabSel top/bottom for the selected tab).
const TAB_SEL_TOP := Color("#6e5a88")
const TAB_SEL_BOTTOM := Color("#554466")
const TAB_BG := Color("#241f38")
## Parchment (quest detail + ribbon faces, README anchor #e8d6a8) +
## derived ink/line tones for readable text on it [T view-only].
const PARCHMENT := Color("#e8d6a8")
const PARCHMENT_EDGE := Color("#a8905e")
const PARCHMENT_INK := Color("#463822")
const PARCHMENT_DIM := Color("#7a6845")
## Status anchors.
const BLUE := Color("#3f7de8")
