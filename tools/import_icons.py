#!/usr/bin/env python3
"""Icon-pack importer (slice S0 seam 4, sl-0100; wiring cleared by
sl-0098). Copies the vendored atlas pair (atlas.png + atlas.json)
OUT of .gdignore'd assets/ into the consumed res://icons/ tree —
ui/icon_atlas.gd cuts AtlasTexture regions from it at runtime, so
every one of the 470 glyphs is reachable through two files. Source
integrity is the fixed gate's job (tools/validate_icon_pack.py +
the intake passport); re-run after any pack re-drop."""

import shutil
import sys
from pathlib import Path

SRC = Path("assets/wildshot-icons-proto_0.1.0")
DST = Path("icons")


def main() -> int:
    DST.mkdir(exist_ok=True)
    for name in ("atlas.png", "atlas.json"):
        shutil.copyfile(SRC / name, DST / name)
    print(f"import_icons: atlas pair -> {DST}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
