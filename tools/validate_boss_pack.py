"""Structural validator for assembler boss-pack raw drops (established-boss-pack-*).

Validates the pack at assets/assembler-boss-pack/ (or argv[1]) against ITS OWN
manifests (root + per-boss): counts, declared dims, contract agreement, hard
alpha, frame-0 non-empty, and slice coherence (every individual frame must be
pixel-identical to its region of the full sheet). The pack ships no checksums,
so this structural pass IS the boundary validation. Exit 0 = clean.

Run on every re-drop before replacing the committed directory:
    python tools/validate_boss_pack.py <extracted-drop-dir>
"""

import json
import sys
from pathlib import Path

from PIL import Image

PACK = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/assembler-boss-pack")
findings: list[str] = []
notes: list[str] = []


def fail(msg: str) -> None:
    findings.append(msg)


def alpha_values(im: Image.Image) -> set:
    ch = im.getchannel("A")
    data = ch.get_flattened_data() if hasattr(ch, "get_flattened_data") else ch.getdata()
    return set(data)


def pixels(im: Image.Image) -> list:
    return list(im.get_flattened_data() if hasattr(im, "get_flattened_data") else im.getdata())


root = json.load(open(PACK / "manifest.json"))
roster = root["roster"]
anims = root["animations"]
cell = root["nativeFrameSize"]
dirs = root["directionOrder"]
full_w = root["fullAnimationSheet"]["width"]
full_h = root["fullAnimationSheet"]["height"]
cols = root["fullAnimationSheet"]["columns"]

if len(roster) != root["bossCount"]:
    fail(f"roster size {len(roster)} vs bossCount {root['bossCount']}")
if sum(a["frames"] for a in anims) != cols:
    fail(f"anim frames sum {sum(a['frames'] for a in anims)} != columns {cols}")
if full_w != cols * cell or full_h != len(dirs) * cell:
    fail(f"full sheet decl {full_w}x{full_h} != {cols * cell}x{len(dirs) * cell}")

total_png = 0
excluded = set(root.get("excludedBossIds", []))


def img(path: Path) -> Image.Image | None:
    if not path.is_file():
        fail(f"missing file: {path.relative_to(PACK)}")
        return None
    return Image.open(path).convert("RGBA")


for entry in roster:
    bid = entry["id"]
    if bid in excluded:
        fail(f"excluded boss {bid} present in roster")
    folder = PACK / entry["folder"]
    m = json.load(open(folder / "manifest.json"))
    if m["id"] != bid:
        fail(f"{bid}: per-boss manifest id {m['id']}")

    listed = set(m["files"])
    on_disk = {p.name for p in folder.glob("*.png")}
    if not (len(listed) == m["pngCount"] == entry["pngCount"]):
        fail(f"{bid}: files list {len(listed)} vs pngCount {m['pngCount']}/{entry['pngCount']}")
    if listed != on_disk:
        fail(
            f"{bid}: files list vs disk mismatch "
            f"(+{sorted(on_disk - listed)[:3]} -{sorted(listed - on_disk)[:3]})"
        )
    total_png += len(on_disk)

    ap = m["animationPilot"]
    prof = ap["profile"]
    if prof["animations"] != anims:
        fail(f"{bid}: animationPilot contract differs from root manifest")
    if prof["frameSize"] != cell or prof["sheetColumns"] != cols:
        fail(f"{bid}: frameSize/sheetColumns {prof['frameSize']}/{prof['sheetColumns']}")
    if m["directionOrder"] != dirs or prof["directionOrder"] != dirs:
        fail(f"{bid}: directionOrder differs from root")

    full = img(folder / ap["fullSheet"])
    if full is None:
        continue
    if full.size != (full_w, full_h):
        fail(f"{bid}: full sheet {full.size} != ({full_w},{full_h})")
        continue
    soft = alpha_values(full) - {0, 255}
    if soft:
        fail(f"{bid}/full: soft alpha values {sorted(soft)[:5]}")

    # direction sheets are one direction's full frame row (README's 48x192 is a typo)
    for d in dirs:
        ds = img(folder / ap["directionSheets"][d])
        if ds is not None and ds.size != (full_w, cell):
            fail(f"{bid}: direction sheet {d} unexpected size {ds.size}")

    for a in anims:
        ash = img(folder / ap["animationSheets"][a["id"]])
        want = (a["frames"] * cell, len(dirs) * cell)
        if ash is not None and ash.size != want:
            fail(f"{bid}: anim sheet {a['id']} {ash.size} != {want}")

    for a in anims:
        base_col = a["column"]
        for row_i, d in enumerate(dirs):
            frame_files = ap["frames"][a["id"]][d]
            if len(frame_files) != a["frames"]:
                fail(f"{bid}: {a['id']}/{d} frame count {len(frame_files)}")
                continue
            for fi, fname in enumerate(frame_files):
                fim = img(folder / fname)
                if fim is None:
                    continue
                if fim.size != (cell, cell):
                    fail(f"{bid}: frame {fname} size {fim.size}")
                    continue
                region = full.crop(
                    (
                        (base_col + fi) * cell,
                        row_i * cell,
                        (base_col + fi + 1) * cell,
                        (row_i + 1) * cell,
                    )
                )
                if pixels(fim) != pixels(region):
                    fail(f"{bid}: {fname} differs from full-sheet region")
                if fi == 0 and fim.getchannel("A").getextrema()[1] == 0:
                    fail(f"{bid}: {a['id']}/{d} frame 0 is EMPTY")

    dp = m["directionPilot"]
    dprof = dp["profile"]
    dsheet = img(folder / dp["sheet"])
    if dsheet is not None and dsheet.size != (dprof["sheetWidth"], dprof["sheetHeight"]):
        fail(f"{bid}: static direction sheet {dsheet.size}")
    for d in dirs:
        sf = img(folder / dp["frames"][d])
        if sf is None:
            continue
        if sf.size != (cell, cell):
            fail(f"{bid}: static {d} size {sf.size}")
        if sf.getchannel("A").getextrema()[1] == 0:
            fail(f"{bid}: static {d} is EMPTY")

if total_png != root["pngCount"]:
    fail(f"total PNGs {total_png} != declared {root['pngCount']}")

undeclared = [
    p.name for p in (PACK / "bosses").iterdir() if p.name not in {e["id"] for e in roster}
]
if undeclared:
    fail(f"undeclared boss folders present: {undeclared}")

print(f"checked {len(roster)} bosses, {total_png} PNGs at {PACK}")
for n in notes:
    print("NOTE:", n)
if findings:
    print(f"\nFAIL — {len(findings)} findings:")
    for f in findings:
        print(" -", f)
    sys.exit(1)
print("PASS — pack is structurally clean")
