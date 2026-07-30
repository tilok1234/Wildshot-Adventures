"""Boss-actor importer (Loop v1, docs/19 ruling 4; boss-pack ruling
2026-07-29: wire in only when a boss is naturally needed).

Copies ONE boss's full animation sheet out of the raw drop
(assets/ is .gdignore'd) into res://assembler_boss/ and writes a
game-side manifest in the assembler-library shape (cell 48 native;
render happens at 1 world px per sheet px — the size IS the render
scale story; hurtboxes stay sim-authored per the parked honesty note).

Usage: python tools/import_boss_actor.py [boss-id ...]
Default: bone-reliquary-king.
"""

import hashlib
import json
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PACK = REPO / "assets" / "assembler-boss-pack"
OUT = REPO / "assembler_boss"

bosses = sys.argv[1:] or ["bone-reliquary-king"]

pack_manifest = json.load(open(PACK / "manifest.json", encoding="utf-8"))
anims = sorted(pack_manifest["animations"], key=lambda a: a["column"])
cols = sum(a["frames"] for a in anims)
full = pack_manifest["fullAnimationSheet"]
assert cols == full["columns"], (cols, full)
assert pack_manifest["nativeFrameSize"] == 48

OUT.mkdir(exist_ok=True)
actors = []
for boss in bosses:
    src = PACK / "bosses" / boss / f"{boss}-animation-v1-full.png"
    assert src.is_file(), src
    dst = OUT / f"{boss}.png"
    shutil.copyfile(src, dst)
    sha = hashlib.sha256(dst.read_bytes()).hexdigest()
    actors.append({"id": f"boss:{boss}", "sheet": f"{boss}.png", "sha256": sha})
    print(f"imported {boss} ({sha[:12]}...)")

manifest = {
    "source": "assets/assembler-boss-pack (established-boss-pack-13-v1)",
    "cell": pack_manifest["nativeFrameSize"],
    "export_scale": 1,
    "frame_contract": {
        "dirs": pack_manifest["directionOrder"],
        "anims": [{"id": a["id"], "frames": a["frames"], "ms": a["ms"]} for a in anims],
    },
    "actors": actors,
}
with open(OUT / "manifest.json", "w", encoding="utf-8", newline="\n") as f:
    json.dump(manifest, f, indent=1)
    f.write("\n")
print(f"assembler_boss/manifest.json written ({len(actors)} actor(s), {cols} columns)")
