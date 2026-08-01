"""Fixed validation gate for the icon-pack raw drop (wildshot-icons-proto).

Validates the pack at assets/wildshot-icons-proto_0.1.0 (or argv[1]) against
BOTH its own manifest and the intake passport written at the sl-0083 seam
(<pack>.passport.json, or argv[2]): every manifest file exists + decodes +
is exactly 16x16, ids unique, glyph parity both directions, atlas coherent,
and every on-disk byte matches the passport's per-file sha256s (the shipped
manifest carries no checksums — the passport is the byte pin). Exit 0 = clean.

Fixed pretester step + CI row. On a future re-drop the new zip gets a fresh
intake seam (new passport, deliberate act) — this tool never regenerates
hashes, it only refuses drift.

    python tools/validate_icon_pack.py [pack-dir] [passport.json]
"""

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image

PACK = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/wildshot-icons-proto_0.1.0")
PASSPORT = Path(sys.argv[2] if len(sys.argv) > 2 else str(PACK) + ".passport.json")
GLYPH_SIZE = 16
findings: list[str] = []


def fail(msg: str) -> None:
    findings.append(msg)


passport = json.load(open(PASSPORT, encoding="utf-8"))
if passport.get("formatVersion") != 1:
    fail(f"passport formatVersion {passport.get('formatVersion')}")
pfiles: dict = passport["files"]
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
drift = [
    rel
    for rel in sorted(set(pfiles) & on_disk)
    if hashlib.sha256((PACK / rel).read_bytes()).hexdigest() != pfiles[rel]
]
if drift:
    fail(f"sha256 drift vs passport: {drift[:5]}")

manifest = json.load(open(PACK / "manifest.json", encoding="utf-8"))
if manifest["set"] != passport["set"] or manifest["version"] != passport["version"]:
    fail(
        f"manifest identity {manifest['set']}@{manifest['version']} != "
        f"passport {passport['set']}@{passport['version']}"
    )
if manifest["size"] != GLYPH_SIZE or passport["canonicalGlyphSize"] != GLYPH_SIZE:
    fail(f"canonical glyph size {manifest['size']}/{passport['canonicalGlyphSize']} != {GLYPH_SIZE}")

glyphs = manifest["glyphs"]
if len(glyphs) != passport["census"]["glyphs"]:
    fail(f"manifest glyph count {len(glyphs)} != passport census {passport['census']['glyphs']}")

ids = [g["id"] for g in glyphs]
dupes = sorted({i for i in ids if ids.count(i) > 1})
if dupes:
    fail(f"duplicate glyph ids: {dupes[:5]}")

# every manifest file exists + decodes + is exactly 16x16
listed = set()
for g in glyphs:
    rel = g["file"]
    listed.add(rel)
    if g["size"] != GLYPH_SIZE:
        fail(f"{g['id']}: declared size {g['size']}")
    p = PACK / rel
    if not p.is_file():
        fail(f"{g['id']}: missing file {rel}")
        continue
    try:
        im = Image.open(p)
        im.load()
    except Exception as e:  # decode failure IS the finding
        fail(f"{g['id']}: {rel} does not decode ({e})")
        continue
    if im.size != (GLYPH_SIZE, GLYPH_SIZE):
        fail(f"{g['id']}: {rel} is {im.size}, not ({GLYPH_SIZE}, {GLYPH_SIZE})")

# glyph parity, disk side: no unlisted glyph files
unlisted = sorted({r for r in on_disk if r.startswith("glyphs/")} - listed)
if unlisted:
    fail(f"on-disk glyphs not in manifest: {unlisted[:5]}")

# non-glyph PNGs (proof sheets, atlas) must decode too — no dim contract
for rel in sorted(on_disk - listed):
    if rel.endswith(".png"):
        try:
            im = Image.open(PACK / rel)
            im.load()
        except Exception as e:
            fail(f"{rel} does not decode ({e})")

# atlas coherence: identity, frame ids == glyph ids, sheet dims match layout
atlas = json.load(open(PACK / "atlas.json", encoding="utf-8"))
if atlas["set"] != manifest["set"] or atlas["version"] != manifest["version"]:
    fail(f"atlas identity {atlas['set']}@{atlas['version']} != manifest")
if atlas["size"] != GLYPH_SIZE:
    fail(f"atlas glyph size {atlas['size']}")
frame_ids = set(atlas["frames"])
if frame_ids != set(ids):
    fail(
        f"atlas frames != manifest ids "
        f"(+{sorted(frame_ids - set(ids))[:3]} -{sorted(set(ids) - frame_ids)[:3]})"
    )
atlas_img = Image.open(PACK / atlas["image"])
atlas_img.load()
cols = atlas["cols"]
rows = -(-len(atlas["frames"]) // cols)
want = (cols * GLYPH_SIZE, rows * GLYPH_SIZE)
if atlas_img.size != want:
    fail(f"atlas image {atlas_img.size} != layout {want} ({cols} cols x {rows} rows)")

sheet_count = sum(1 for r in on_disk if r.startswith("sheets/"))
print(
    f"checked {len(glyphs)} glyphs + {sheet_count} sheets + atlas at {PACK} "
    f"({len(on_disk)} files byte-pinned vs passport)"
)
if findings:
    print(f"\nFAIL — {len(findings)} findings:")
    for f in findings:
        print(" -", f)
    sys.exit(1)
print("PASS — icon pack structurally clean and byte-true to the intake passport")
