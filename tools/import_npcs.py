#!/usr/bin/env python3
"""NPC slice-roster importer (slice S0 seam 4, sl-0100; wiring cleared
by sl-0098). Copies the vendored pack's 32 character sheets OUT of
.gdignore'd assets/ into the consumed res://npcs/ tree and translates
the character-pack v3 manifest's sheet block into the
assembler_library shape (actors / frame_contract / cell /
export_scale) — the sl-0092 intake report's predicted adapter, made
mechanical. Station metadata (group/zone/role/name) rides on each
actor entry; game/views/npc_view.gd consumes it.

Source integrity is the fixed gate's job (tools/validate_npc_pack.py
verifies the manifest's own sha256s every pretester run); this
importer just consumes. Re-run after any pack re-drop."""

import json
import shutil
import sys
from pathlib import Path

SRC = Path("assets/wildshot-npc-slice-v1")
DST = Path("npcs")


def main() -> int:
    manifest = json.loads((SRC / "manifest.json").read_text(encoding="utf-8"))
    sheet = manifest["sheet"]
    chars = manifest["characters"]
    DST.mkdir(exist_ok=True)
    actors = []
    for c in chars:
        src_png = SRC / c["file"]
        dst_name = Path(c["file"]).name
        shutil.copyfile(src_png, DST / dst_name)
        actors.append(
            {
                "id": c["id"],
                "sheet": dst_name,
                "name": c.get("name", c["id"]),
                "group": c.get("group", ""),
                "zone": c.get("zone", ""),
                "role": c.get("role", ""),
            }
        )
    out = {
        "source": "wildshot-npc-slice-v1 (assembler bf6269c; sl-0089 intake)",
        "cell": int(manifest["logicalFrame"]["width"]),
        "export_scale": int(manifest.get("exportScale", 1)),
        "frame_contract": {
            "dirs": sheet["directions"],
            "anims": [
                {"id": a["id"], "ms": int(a["ms"]), "frames": int(a["frames"])}
                for a in sheet["animations"]
            ],
        },
        "actors": actors,
    }
    (DST / "manifest.json").write_text(
        json.dumps(out, indent="\t") + "\n", encoding="utf-8"
    )
    print(f"import_npcs: {len(actors)} actors -> {DST}/ (cell {out['cell']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
