"""Fixed validation gate for the NPC slice roster raw drop (wildshot-npc-slice-v1).

Validates the pack at assets/wildshot-npc-slice-v1 (or argv[1]) against BOTH
its own manifest and the intake passport (<pack>.passport.json, or argv[2]).
The manifest ships per-file sha256s (the sl-0045 assembler publish gate), so
hash parity here verifies the pack's OWN pins; the passport contributes the
one hash the manifest cannot carry - its own - plus the verified provenance.
Checks: every file exists + decodes/parses, sheets exactly 480x96 in the
manifest's 20x4 layout (24x24 logical frames at exportScale 1 - the enemy-pack
treatment), ids unique, declared binary alpha, hash parity. Exit 0 = clean.

    python tools/validate_npc_pack.py [pack-dir] [passport.json]
"""

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image

PACK = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/wildshot-npc-slice-v1")
PASSPORT = Path(sys.argv[2] if len(sys.argv) > 2 else str(PACK) + ".passport.json")
LOGICAL = 24
SHEET_W, SHEET_H = 480, 96
COLS, ROWS = 20, 4
findings: list[str] = []


def fail(msg: str) -> None:
    findings.append(msg)


passport = json.load(open(PASSPORT, encoding="utf-8"))
if passport.get("formatVersion") != 1:
    fail(f"passport formatVersion {passport.get('formatVersion')}")

manifest_bytes = (PACK / "manifest.json").read_bytes()
if hashlib.sha256(manifest_bytes).hexdigest() != passport["manifestSha256"]:
    fail("manifest.json sha256 != passport pin (the manifest itself drifted)")
manifest = json.loads(manifest_bytes.decode("utf-8"))

prov = manifest.get("provenance", {})
if prov.get("sourceCommit") != passport["source"]["sourceCommit"]:
    fail(f"provenance sourceCommit {prov.get('sourceCommit')} != passport")
if not prov.get("cleanPushedSource"):
    fail("provenance cleanPushedSource is not true")

lf = manifest["logicalFrame"]
if (lf["width"], lf["height"]) != (LOGICAL, LOGICAL):
    fail(f"logicalFrame {lf} != {LOGICAL}x{LOGICAL}")
if int(manifest.get("exportScale", 1)) != 1:
    fail(f"exportScale {manifest.get('exportScale')} != 1 (enemy-pack treatment)")

sheet = manifest["sheet"]
anim_frames = sum(int(a["frames"]) for a in sheet["animations"])
if sheet["columns"] != COLS or anim_frames != COLS:
    fail(f"sheet columns {sheet['columns']} / anim frames {anim_frames} != {COLS}")
if sheet["rows"] != ROWS or len(sheet["directions"]) != ROWS:
    fail(f"sheet rows {sheet['rows']} / directions {len(sheet['directions'])} != {ROWS}")
if (sheet["width"], sheet["height"]) != (SHEET_W, SHEET_H):
    fail(f"sheet decl {sheet['width']}x{sheet['height']} != {SHEET_W}x{SHEET_H}")
if COLS * LOGICAL != SHEET_W or ROWS * LOGICAL != SHEET_H:
    fail("layout math broken: cols*cell / rows*cell do not give the sheet dims")

# hash parity: the manifest's own per-file pins, both directions
listed = {f["path"]: f for f in manifest["files"]}
on_disk = {p.relative_to(PACK).as_posix() for p in PACK.rglob("*") if p.is_file()}
extra = sorted(on_disk - set(listed) - {"manifest.json"})
missing = sorted(set(listed) - on_disk)
if extra:
    fail(f"files on disk not in the manifest files block: {extra[:5]}")
if missing:
    fail(f"manifest files missing on disk: {missing[:5]}")
for rel in sorted(set(listed) & on_disk):
    data = (PACK / rel).read_bytes()
    if len(data) != listed[rel]["bytes"] or hashlib.sha256(data).hexdigest() != listed[rel]["sha256"]:
        fail(f"sha256/bytes drift vs the manifest pin: {rel}")

# characters: ids unique, counts agree, every sheet decodes at spec
chars = manifest["characters"]
counts = manifest["counts"]
group_sum = sum(v for k, v in counts.items() if k != "total")
if not (len(chars) == counts["total"] == group_sum == passport["census"]["characters"]):
    fail(f"character counts disagree: {len(chars)} / {counts} / passport")
ids = [c["id"] for c in chars]
dupes = sorted({i for i in ids if ids.count(i) > 1})
if dupes:
    fail(f"duplicate character ids: {dupes[:5]}")
binary_alpha = bool(manifest.get("binaryAlpha"))
for c in chars:
    rel = c["file"]
    if (c["width"], c["height"]) != (SHEET_W, SHEET_H):
        fail(f"{c['id']}: declared {c['width']}x{c['height']}")
    if rel not in listed or listed[rel]["sha256"] != c["sha256"]:
        fail(f"{c['id']}: character sha256 disagrees with the files block")
    p = PACK / rel
    if not p.is_file():
        fail(f"{c['id']}: missing file {rel}")
        continue
    try:
        im = Image.open(p)
        im.load()
    except Exception as e:
        fail(f"{c['id']}: {rel} does not decode ({e})")
        continue
    if im.size != (SHEET_W, SHEET_H):
        fail(f"{c['id']}: {rel} is {im.size}, not ({SHEET_W}, {SHEET_H})")
        continue
    if int(c.get("frameCount", COLS * ROWS)) != COLS * ROWS:
        fail(f"{c['id']}: frameCount {c.get('frameCount')} != {COLS * ROWS}")
    if binary_alpha:
        ch = im.convert("RGBA").getchannel("A")
        data = ch.get_flattened_data() if hasattr(ch, "get_flattened_data") else ch.getdata()
        soft = set(data) - {0, 255}
        if soft:
            fail(f"{c['id']}: soft alpha values {sorted(soft)[:5]} (manifest declares binaryAlpha)")

# every other file decodes/parses by kind
for rel in sorted(on_disk - {c["file"] for c in chars} - {"manifest.json"}):
    p = PACK / rel
    if rel.endswith(".png"):
        try:
            im = Image.open(p)
            im.load()
        except Exception as e:
            fail(f"{rel} does not decode ({e})")
    elif rel.endswith(".json"):
        try:
            json.loads(p.read_text("utf-8"))
        except Exception as e:
            fail(f"{rel} does not parse ({e})")

print(
    f"checked {len(chars)} characters + {len(on_disk) - len(chars)} support files at {PACK} "
    f"({len(listed)} manifest hash pins + the passport's manifest pin verified)"
)
if findings:
    print(f"\nFAIL — {len(findings)} findings:")
    for f in findings:
        print(" -", f)
    sys.exit(1)
print("PASS — NPC pack structurally clean and byte-true to its shipped manifest pins")
