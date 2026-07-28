"""WorldForge pack walkability auditor (ledger #15 diagnostic).

Prints an ASCII layer-vs-walkability grid for a region plus a full-map
porosity summary. The instrument that convicted the porous-collision
bug; the re-exported pack must be acquitted by it.

Usage:
  python tools/diag_walkability_grid.py [pack_dir] [x0 y0 x1 y1] [allowed]

Defaults: the shipped dusk pack, region 208 126 248 148 (the town the
evidence came from), allowed=11. Exit 1 if walkable structure cells
exceed `allowed` — the WorldForge stamp (a1304b9) deliberately keeps
exactly 11 walkable structure cells in this pack: 9 bridge/crossing
cells + 2 ruined-city trail breaches (routes must walk; ratified at
intake 2026-07-28). A regression above that count is porosity again.
"""

import base64
import json
import sys

pack = (
    sys.argv[1]
    if len(sys.argv) > 1
    else r"assets\worldforge-packs\small-cold-coastal-pack-dusk"
)
region = [int(a) for a in sys.argv[2:6]] if len(sys.argv) >= 6 else [208, 126, 248, 148]
allowed = int(sys.argv[6]) if len(sys.argv) > 6 else 11

w = json.load(open(pack + r"\walkability.json"))
W, H = w["width"], w["height"]
raw = base64.b64decode(w["grid"])


def walkable(x, y):
    i = y * W + x
    return (raw[i // 8] >> (i % 8)) & 1


tmj = json.load(open(pack + r"\resolved\resolved-map.tmj"))
layers = {L["name"]: L["data"] for L in tmj["layers"] if L.get("type") == "tilelayer"}

x0, y0, x1, y1 = region
print("legend: S=structure(solid) s=structure(WALKABLE) W=wall F=fence")
print("        p=props(solid) P=props(WALKABLE) o=overhang(solid) O=overhang(WALKABLE)")
print("        #=other-solid .=open-walkable   region", (x0, y0), "-", (x1, y1))
print("     " + "".join(str(x % 10) for x in range(x0, x1)))
for y in range(y0, y1):
    row = ""
    for x in range(x0, x1):
        idx = y * W + x
        wk = walkable(x, y)
        ch = "." if wk else "#"
        if layers["structures"][idx]:
            ch = "s" if wk else "S"
        elif layers.get("wall") and layers["wall"][idx]:
            ch = "W"
        elif layers.get("fence") and layers["fence"][idx]:
            ch = "F"
        elif layers.get("props-overhang") and layers["props-overhang"][idx]:
            ch = "O" if wk else "o"
        elif layers.get("props") and layers["props"][idx]:
            ch = "P" if wk else "p"
        row += ch
    print(f"{y:4d} {row}")

structures = layers["structures"]
n = sum(1 for g in structures if g)
on_walk = sum(1 for idx, g in enumerate(structures) if g and walkable(idx % W, idx // W))
flood = w["floodCount"]
total_walk = sum(1 for y in range(H) for x in range(W) if walkable(x, y))
print()
print(f"summary: structure tiles={n}, ON WALKABLE={on_walk} (allowed: {allowed} route cells)")
print(f"         walkable cells={total_walk}, floodCount={flood}, spawnCell={w['spawnCell']}")
if on_walk > allowed:
    walk_cells = [
        (idx % W, idx // W)
        for idx, g in enumerate(structures)
        if g and walkable(idx % W, idx // W)
    ]
    print("REGRESSION - walkable structure cells:", walk_cells)
sys.exit(1 if on_walk > allowed else 0)
