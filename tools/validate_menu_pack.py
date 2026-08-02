"""Fixed validation gate for the menu-system v2 raw drop (wildshot-ui-v2).

Validates the pack at assets/wildshot-ui-v2 (or argv[1]) against the intake
passport written at the sl-0155 seam (<pack>.passport.json, or argv[2]):
exact file-set parity + per-file sha256s both directions, manifest identity
+ four hue palettes + every image entry resolving on disk, menu-specs.json
carrying the v2 spec ids the menu pass builds from, the 20 uikit chrome
pieces at their planning-verified dimensions with binary alpha, the
designer font present, and the icon-parity claim re-checked LIVE against
the wired wildshot-icons-proto atlas (the zip's icons were byte-identical
and deliberately NOT re-vendored — if the wired atlas ever moves, this
gate goes loud instead of the claim silently rotting). Exit 0 = clean.

On a future re-drop the new zip gets a fresh intake seam (new passport,
deliberate act) — this tool never regenerates hashes, it only refuses
drift.

    python tools/validate_menu_pack.py [pack-dir] [passport.json]
"""

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image

PACK = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/wildshot-ui-v2")
PASSPORT = Path(sys.argv[2] if len(sys.argv) > 2 else str(PACK) + ".passport.json")
findings: list[str] = []


def fail(msg: str) -> None:
    findings.append(msg)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


passport = json.load(open(PASSPORT, encoding="utf-8"))
if passport.get("formatVersion") != 1:
    fail(f"passport formatVersion {passport.get('formatVersion')}")
pfiles: dict = passport["fileHashes"]
zip_sha = passport["source"]["zipSha256"]
if len(zip_sha) != 64 or set(zip_sha) - set("0123456789abcdef"):
    fail("passport zipSha256 malformed")

# passport byte pin: exact file-set parity + per-file sha256, both from disk
on_disk = {p.relative_to(PACK).as_posix() for p in PACK.rglob("*") if p.is_file()}
extra, missing = sorted(on_disk - set(pfiles)), sorted(set(pfiles) - on_disk)
if extra:
    fail(f"files on disk not in passport: {extra[:5]}")
if missing:
    fail(f"passport files missing on disk: {missing[:5]}")
drift = [rel for rel in sorted(set(pfiles) & on_disk) if sha256(PACK / rel) != pfiles[rel]]
if drift:
    fail(f"sha256 drift vs passport: {drift[:5]}")

# manifest: identity + hues + palettes + image entries resolve on disk
manifest = json.load(open(PACK / "manifest.json", encoding="utf-8"))
if manifest.get("rev") != passport.get("rev"):
    fail(f"manifest rev {manifest.get('rev')} != passport rev {passport.get('rev')}")
HUES = ["dusk", "teal", "slate", "moss"]
if manifest.get("hues") != HUES:
    fail(f"manifest hues {manifest.get('hues')} != {HUES}")
palettes = manifest.get("palettes", {})
PINNED_KEYS = ["w3", "w4", "w6", "wN", "wU", "rad", "lip", "barTicks"]
for hue in HUES:
    pal = palettes.get(hue)
    if not isinstance(pal, dict):
        fail(f"palette missing for hue {hue}")
        continue
    for key in PINNED_KEYS:
        if key not in pal:
            fail(f"palette {hue} missing pinned key {key}")
    # gold accents + status colors are pinned ACROSS hues by design
    if pal.get("w3") != "#f2c14e" or pal.get("wN") != "#ffd968":
        fail(f"palette {hue} gold anchors moved: w3={pal.get('w3')} wN={pal.get('wN')}")
for entry in manifest.get("images", []):
    rel = entry["file"]
    if rel not in on_disk:
        fail(f"manifest image not on disk: {rel}")

# menu-specs: parses + the ids the menu pass builds from are present
specs_doc = json.load(open(PACK / "menu-specs.json", encoding="utf-8"))
spec_ids = {s.get("id") for s in specs_doc.get("specs", [])}
REQUIRED_SPECS = {
    "c_menu_v2",
    "errands_v2",
    "quest_offer_v2",
    "bank_v2",
    "vendor_v2",
    "loot_v2",
    "options_v2",
    "hud",
    "toast_demo",
    "tooltip_demo",
    "confirm_demo",
    "legendary_stampede_demo",
    "spec_guide",
}
missing_specs = sorted(REQUIRED_SPECS - spec_ids)
if missing_specs:
    fail(f"menu-specs missing required ids: {missing_specs}")

# uikit chrome: the 20 shipped pieces at planning-verified dims, binary alpha
UIKIT_DIMS = {
    "button_normal.png": (12, 14),
    "button_hover.png": (12, 14),
    "button_pressed.png": (12, 14),
    "button_disabled.png": (12, 14),
    "button_focus.png": (12, 14),
    "panel.png": (12, 12),
    "panel_inset.png": (12, 12),
    "popup_panel.png": (12, 12),
    "tab_selected.png": (12, 12),
    "tab_unselected.png": (12, 12),
    "check_on.png": (12, 12),
    "check_off.png": (12, 12),
    "lineedit_normal.png": (12, 12),
    "lineedit_focus.png": (12, 12),
    "icon_close.png": (12, 12),
    "bar_frame.png": (64, 8),
    "bar_fill_hp.png": (8, 4),
    "bar_fill_mana.png": (8, 4),
    "tooltip_panel.png": (8, 8),
    "item_hover.png": (8, 8),
}
for name, want in UIKIT_DIMS.items():
    p = PACK / "assets" / "uikit" / name
    if not p.is_file():
        fail(f"uikit piece missing: {name}")
        continue
    try:
        im = Image.open(p)
        im.load()
    except Exception as e:  # decode failure IS the finding
        fail(f"uikit {name} does not decode ({e})")
        continue
    if im.size != want:
        fail(f"uikit {name} is {im.size}, not {want}")
        continue
    alpha_bytes = im.convert("RGBA").getchannel("A").tobytes()
    bad = sum(1 for v in alpha_bytes if v not in (0, 255))
    if bad:
        fail(f"uikit {name} alpha not binary ({bad} px)")

if not (PACK / "assets" / "uikit" / "wildshot_pixel.ttf").is_file():
    fail("wildshot_pixel.ttf missing")
if "PROD-03" not in passport.get("font", {}).get("license", ""):
    fail("passport font license record missing PROD-03")

# every capture/surface/cinematic png decodes
for rel in sorted(on_disk):
    if rel.endswith(".png"):
        try:
            im = Image.open(PACK / rel)
            im.load()
        except Exception as e:  # decode failure IS the finding
            fail(f"{rel} does not decode ({e})")

# icon parity claim re-checked LIVE against the wired pack
parity = passport.get("iconParity", {})
wired = Path(parity.get("wiredPack", "assets/wildshot-icons-proto_0.1.0"))
want_sha = parity.get("wiredAtlasPngSha256", "")
if not (wired / "atlas.png").is_file():
    fail(f"wired icon pack atlas missing: {wired}/atlas.png")
elif sha256(wired / "atlas.png") != want_sha:
    fail("wired icon atlas.png no longer matches the intake parity record")

print(
    f"checked {len(on_disk)} files byte-pinned vs passport at {PACK} "
    f"({len(UIKIT_DIMS)} chrome pieces dim+alpha true, {len(REQUIRED_SPECS)} spec ids, "
    f"4 palettes, icon parity live)"
)
if findings:
    print(f"\nFAIL — {len(findings)} findings:")
    for f in findings:
        print(" -", f)
    sys.exit(1)
print("PASS — menu-system v2 pack structurally clean and byte-true to the intake passport")
