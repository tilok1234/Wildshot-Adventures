"""b77 prop-pinch diagnosis probe (sl-0070). DIAGNOSIS ONLY - no fixes.

Quantifies, over a WorldForge overworld pack:
  1. CORNER-TOUCH PINCHES: diagonal solid-solid cell pairs whose two
     shared orthogonal neighbors are BOTH open. The shared corner point
     is a geometrically ZERO-WIDTH gap for any collision circle: art
     smaller than the cell shows a walkable lane, the sim honestly
     refuses it.
  2. 1-WIDE LANES (near-pinch): open cells flanked by solids on both
     sides of one axis (N+S or E+W) - passable at TERRAIN_RADIUS 0.25
     with 0.25 clearance per side, the tight-corridor feel case.
  3. Cause attribution per solid cell (prop species / structure /
     water / rock / mystery) - a solid with NO visible cause is the
     DATA-closed candidate class; everything prop-caused with open
     diagonals is GEOMETRY/FEEL territory.
  4. Connectivity class per pinch: same-component (the corner denies a
     SHORTCUT - a detour exists, length measured by BFS) vs
     component-boundary (the corner is the ONLY meeting point).
  5. Region bucketing (16x16 cells) by prop-solid density + settlement
     vs wild zoning, so the numbers land per prop-dense region.

Usage: python tools/diag_pinch.py [pack_dir]
Writes reports/pinch_diagnosis_b77.json + prints the summary. Re-run
after any fix lever lands to measure the delta against this baseline.
"""

import base64
import json
import sys
from collections import Counter, deque
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PACK = Path(sys.argv[1]) if len(sys.argv) > 1 else (
    REPO / "assets/worldforge-packs/wildshot-overworld-pack-dusk"
)
OUT = REPO / "reports/pinch_diagnosis_b77.json"
DETOUR_CAP = 120

wj = json.load(open(PACK / "walkability.json", encoding="utf-8"))
W, H = int(wj["width"]), int(wj["height"])
raw = base64.b64decode(wj["grid"])
walk = [[(raw[(y * W + x) >> 3] >> ((y * W + x) & 7)) & 1 == 1 for x in range(W)] for y in range(H)]
spawn = tuple(wj["spawnCell"])

world = json.load(open(PACK / "world.json", encoding="utf-8"))
prop_types = world["propTypes"]
palette = world["semanticPalette"]
cw, chh = world["dimensions"]["chunkWidth"], world["dimensions"]["chunkHeight"]

prop = [[0] * W for _ in range(H)]
structure = [[0] * W for _ in range(H)]
material = [[0] * W for _ in range(H)]
river = [[0] * W for _ in range(H)]
fence = [[0] * W for _ in range(H)]
for ch in world["chunks"]:
    cx, cy = ch["coord"]
    for name, grid in (("prop", prop), ("structure", structure), ("material", material), ("river", river), ("fence", fence)):
        layer = ch["layers"][name]
        for ly in range(chh):
            for lx in range(cw):
                grid[cy * chh + ly][cx * cw + lx] = layer[ly][lx]

ROCK = palette.index("terrain.rock")
SWAMP = palette.index("terrain.swamp")
WATER = {palette.index("water.deep"), palette.index("water.shallow")}

# Cliff cells from the shipped render truth (resolved-map.tmj cliff
# layer, 1447 placements at b77): terraced peaks are solid with
# non-rock materials underfoot, so cause attribution needs the layer.
tmj = json.load(open(PACK / "resolved/resolved-map.tmj", encoding="utf-8"))
cliff = [[0] * W for _ in range(H)]
for layer_def in tmj["layers"]:
    if layer_def.get("name") == "cliff" and "data" in layer_def:
        for i, gid in enumerate(layer_def["data"]):
            if gid:
                cliff[i // W][i % W] = 1


def species(x, y):
    v = prop[y][x]
    return prop_types[v - 1] if v > 0 else ""


def cause(x, y):
    """Visible cause of a solid cell, priority order."""
    if prop[y][x] > 0:
        return "prop:" + species(x, y)
    if structure[y][x] > 0:
        return "structure"
    if fence[y][x] > 0:
        return "fence"
    if material[y][x] in WATER or river[y][x]:
        return "water"
    if material[y][x] == ROCK:
        return "rock"
    if cliff[y][x]:
        return "cliff"
    if material[y][x] == SWAMP:
        return "swamp-bog"
    return "mystery"


def is_open(x, y):
    return 0 <= x < W and 0 <= y < H and walk[y][x]


def is_solid(x, y):
    return 0 <= x < W and 0 <= y < H and not walk[y][x]


# 4-connected components over ALL open cells (not just spawn flood).
comp = [[-1] * W for _ in range(H)]
ncomp = 0
comp_size = []
for sy in range(H):
    for sx in range(W):
        if not walk[sy][sx] or comp[sy][sx] != -1:
            continue
        q = deque([(sx, sy)])
        comp[sy][sx] = ncomp
        size = 0
        while q:
            x, y = q.popleft()
            size += 1
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if is_open(nx, ny) and comp[ny][nx] == -1:
                    comp[ny][nx] = ncomp
                    q.append((nx, ny))
        comp_size.append(size)
        ncomp += 1
flood_comp = comp[spawn[1]][spawn[0]]

# Settlement zones (anchor + radius, Euclidean).
settlements = [(s["anchor"][0], s["anchor"][1], s["radius"]) for s in world["settlements"]]


def zone(x, y):
    for ax, ay, r in settlements:
        if (x - ax) ** 2 + (y - ay) ** 2 <= r * r:
            return "settlement"
    return "wild"


def bfs_detour(a, b):
    """Shortest open 4-connected path length a->b, capped."""
    if a == b:
        return 0
    seen = {a}
    q = deque([(a, 0)])
    while q:
        (x, y), d = q.popleft()
        if d >= DETOUR_CAP:
            return DETOUR_CAP + 1
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if n == b:
                return d + 1
            if is_open(n[0], n[1]) and n not in seen:
                seen.add(n)
                q.append((n, d + 1))
    return -1  # disconnected


# ---- Census 1: corner-touch pinches --------------------------------------
pinches = []
for y in range(H - 1):
    for x in range(W - 1):
        a, b = (x, y), (x + 1, y + 1)          # NW+SE solids
        c, d = (x + 1, y), (x, y + 1)          # NE+SW open
        for (s1, s2), (o1, o2), orient in (((a, b), (c, d), "nw-se"), ((c, d), (a, b), "ne-sw")):
            if not (is_solid(*s1) and is_solid(*s2) and is_open(*o1) and is_open(*o2)):
                continue
            c1, c2 = cause(*s1), cause(*s2)
            same = comp[o1[1]][o1[0]] == comp[o2[1]][o2[0]]
            in_flood = (comp[o1[1]][o1[0]] == flood_comp) + (comp[o2[1]][o2[0]] == flood_comp)
            detour = bfs_detour(o1, o2) if same else -1
            pinches.append({
                "solids": [list(s1), list(s2)],
                "opens": [list(o1), list(o2)],
                "orient": orient,
                "causes": [c1, c2],
                "prop_involved": c1.startswith("prop:") or c2.startswith("prop:"),
                "both_prop": c1.startswith("prop:") and c2.startswith("prop:"),
                "zone": zone(*s1),
                "same_component": same,
                "opens_in_flood": in_flood,
                "detour": detour,
            })

# ---- Census 2: 1-wide lane cells -----------------------------------------
lane_cells = []
for y in range(H):
    for x in range(W):
        if not walk[y][x]:
            continue
        ns = is_solid(x, y - 1) and is_solid(x, y + 1)
        ew = is_solid(x - 1, y) and is_solid(x + 1, y)
        if not (ns or ew):
            continue
        flank = ((x, y - 1), (x, y + 1)) if ns else ((x - 1, y), (x + 1, y))
        cz = [cause(*f) for f in flank]
        lane_cells.append({
            "cell": [x, y],
            "axis": "ns-flanked" if ns else "ew-flanked",
            "causes": cz,
            "prop_involved": any(s.startswith("prop:") for s in cz),
            "zone": zone(x, y),
            "in_flood": comp[y][x] == flood_comp,
        })

# ---- Census 3: mystery solids (DATA-closed candidates) -------------------
mystery = [
    [x, y] for y in range(H) for x in range(W)
    if not walk[y][x] and cause(x, y) == "mystery"
]

# ---- Region buckets (16x16) ----------------------------------------------
RB = 16
buckets = {}
for y in range(H):
    for x in range(W):
        k = (x // RB, y // RB)
        b = buckets.setdefault(k, {"prop_solid": 0, "pinch": 0, "lane": 0})
        if not walk[y][x] and prop[y][x] > 0:
            b["prop_solid"] += 1
for p in pinches:
    x, y = p["solids"][0]
    buckets[(x // RB, y // RB)]["pinch"] += 1
for lc in lane_cells:
    x, y = lc["cell"]
    buckets[(x // RB, y // RB)]["lane"] += 1

# ---- Screenshot-site hunt: cactus near boulders at a pinch ---------------
cactus_idx = prop_types.index("prop.cactus") + 1
sites = []
for y in range(H):
    for x in range(W):
        if prop[y][x] != cactus_idx:
            continue
        boulders = [
            (bx, by)
            for by in range(max(0, y - 3), min(H, y + 4))
            for bx in range(max(0, x - 3), min(W, x + 4))
            if species(bx, by) in ("prop.boulder", "prop.rock_outcrop") and is_solid(bx, by)
        ]
        near_pinch = [
            p for p in pinches
            if abs(p["solids"][0][0] - x) <= 3 and abs(p["solids"][0][1] - y) <= 3
        ]
        if len(boulders) >= 2 and near_pinch:
            sites.append({"cactus": [x, y], "boulders": boulders, "pinches": len(near_pinch)})

# ---- Derived sets ---------------------------------------------------------
pf = [p for p in pinches if p["prop_involved"]]
pf_flood = [p for p in pf if p["opens_in_flood"] == 2]
shortcut = [p for p in pf_flood if p["same_component"]]
boundary = [p for p in pf_flood if not p["same_component"]]
detours = sorted(p["detour"] for p in shortcut if p["detour"] > 0)
pair_counter = Counter(tuple(sorted(p["causes"])) for p in pf_flood)
lane_prop = [l for l in lane_cells if l["prop_involved"]]
lane_prop_flood = [l for l in lane_prop if l["in_flood"]]
top_buckets = sorted(buckets.items(), key=lambda kv: -kv[1]["prop_solid"])[:8]

# ---- Samples: ASCII neighborhoods for the typed report -------------------
TREES = {
    "prop.oak", "prop.birch", "prop.pine", "prop.willow",
    "prop.dead_tree", "prop.fruit_tree", "prop.giant_shroom",
}


def glyph(x, y):
    if walk[y][x]:
        return "," if prop[y][x] > 0 else "."
    c = cause(x, y)
    if c.startswith("prop:"):
        sp = c[5:]
        if sp in TREES:
            return "T"
        return {"prop.cactus": "c", "prop.boulder": "b", "prop.rock_outcrop": "r"}.get(sp, "p")
    return {
        "structure": "S", "fence": "F", "water": "W", "rock": "R",
        "cliff": "C", "swamp-bog": "%", "mystery": "?",
    }[c]


def ascii_patch(cx, cy, rad=4):
    rows = []
    for y in range(cy - rad, cy + rad + 1):
        row = ""
        for x in range(cx - rad, cx + rad + 1):
            row += glyph(x, y) if 0 <= x < W and 0 <= y < H else " "
        rows.append(row)
    return rows


samples = []
# (a) screenshot-class sites: cactus + boulders, most pinches near.
for s in sorted(sites, key=lambda s: -s["pinches"])[:3]:
    x, y = s["cactus"]
    samples.append({
        "kind": "screenshot-class (cactus + boulders)",
        "at": [x, y],
        "classification": "GEOMETRY-closed",
        "ascii": ascii_patch(x, y),
    })
# (b) worst detours among prop-involved flood pinches.
for p in sorted(shortcut, key=lambda p: -p["detour"])[:3]:
    x, y = p["solids"][0]
    samples.append({
        "kind": "worst-detour pinch (%s + %s)" % tuple(p["causes"]),
        "at": [x, y],
        "detour": p["detour"],
        "classification": "GEOMETRY-closed",
        "ascii": ascii_patch(x, y),
    })
# (c) pinches inside the two densest prop regions.
for (bx, by), _b in top_buckets[:2]:
    hits = [
        p for p in pf_flood
        if p["solids"][0][0] // RB == bx and p["solids"][0][1] // RB == by
    ]
    if hits:
        p = max(hits, key=lambda p: p["detour"])
        x, y = p["solids"][0]
        samples.append({
            "kind": "dense-region pinch (%s + %s)" % tuple(p["causes"]),
            "at": [x, y],
            "detour": p["detour"],
            "classification": "GEOMETRY-closed",
            "ascii": ascii_patch(x, y),
        })
# (d) 1-wide lane cells in dense regions (FEEL class; probe verdict rides
# the movement report).
lane_picks = [
    lc for lc in lane_prop_flood
    if (lc["cell"][0] // RB, lc["cell"][1] // RB) in [k for k, _ in top_buckets[:4]]
][:2]
for lc in lane_picks:
    x, y = lc["cell"]
    samples.append({
        "kind": "1-wide lane (%s | %s)" % tuple(lc["causes"]),
        "at": [x, y],
        "classification": "open-but-tight (FEEL class - movement probe)",
        "ascii": ascii_patch(x, y),
    })

# ---- Cross-check: species mapping sanity (carpet counts, sl-0067) --------
carpet_counts = Counter(
    species(x, y) for y in range(H) for x in range(W) if walk[y][x] and prop[y][x] > 0
)

# ---- Summary --------------------------------------------------------------
def pct(n, d):
    return f"{100.0 * n / d:.1f}%" if d else "-"


print(f"pack {PACK.name}: {W}x{H}, spawn {spawn}, open components {ncomp} (flood comp size {comp_size[flood_comp]})")
print(f"species cross-check (carpet cells): stump={carpet_counts.get('prop.stump', 0)} fallen_log={carpet_counts.get('prop.fallen_log', 0)} bone_pile={carpet_counts.get('prop.bone_pile', 0)} loot_pile={carpet_counts.get('prop.loot_pile', 0)}")
print()
print(f"CORNER-TOUCH PINCHES: {len(pinches)} total; prop-involved {len(pf)} ({pct(len(pf), len(pinches))}); prop-involved with BOTH open sides on the flood {len(pf_flood)}")
print(f"  of those: SHORTCUT-denied (same component, detour exists) {len(shortcut)}; COMPONENT-BOUNDARY (corner is the only meeting point) {len(boundary)}")
if detours:
    mid = detours[len(detours) // 2]
    print(f"  detour tiles around a denied shortcut: min {detours[0]}, median {mid}, max {'>' + str(DETOUR_CAP) if detours[-1] > DETOUR_CAP else detours[-1]}")
    for th in (10, 20, 40):
        n = sum(1 for d in detours if d > th)
        print(f"    detour > {th}: {n} ({pct(n, len(detours))})")
print(f"  top solid-pair causes: {pair_counter.most_common(8)}")
zone_c = Counter(p["zone"] for p in pf_flood)
print(f"  zones: {dict(zone_c)}")
print()
print(f"1-WIDE LANE CELLS: {len(lane_cells)} total; prop-involved {len(lane_prop)}; prop-involved on-flood {len(lane_prop_flood)}")
print()
print(f"MYSTERY SOLIDS (no visible cause = DATA-closed candidates): {len(mystery)}")
if mystery[:10]:
    print(f"  first: {mystery[:10]}")
print()
print("TOP PROP-DENSE 16x16 REGIONS (cells region-x*16, region-y*16):")
for (bx, by), b in top_buckets:
    print(f"  region ({bx:2d},{by:2d}) @cells ({bx*RB:3d},{by*RB:3d}): prop-solid {b['prop_solid']:3d}  pinches {b['pinch']:3d}  lane-cells {b['lane']:3d}")
print()
print(f"SCREENSHOT-SITE CANDIDATES (cactus + >=2 boulders + pinch within 3): {len(sites)}")
for s in sites[:6]:
    print(f"  cactus @ {s['cactus']}, boulders {len(s['boulders'])}, pinches near {s['pinches']}")
print()
print("SAMPLES (legend: . open  , carpet-prop  T tree  c cactus  b boulder  r outcrop  p other-prop  S structure  F fence  W water  R rock  C cliff  % swamp-bog  ? mystery):")
for smp in samples:
    extra = f"  detour {smp['detour']}" if "detour" in smp else ""
    print(f"  [{smp['kind']}] @ {smp['at']} -> {smp['classification']}{extra}")
    for row in smp["ascii"]:
        print("      " + row)

OUT.parent.mkdir(exist_ok=True)
json.dump(
    {
        "pack": PACK.name,
        "dimensions": [W, H],
        "spawn": list(spawn),
        "open_components": ncomp,
        "flood_component_size": comp_size[flood_comp],
        "pinches_total": len(pinches),
        "pinches_prop_involved": len(pf),
        "pinches_prop_flood": len(pf_flood),
        "pinches_shortcut_denied": len(shortcut),
        "pinches_component_boundary": len(boundary),
        "detour_distribution": detours,
        "pair_causes_top": [[list(k), v] for k, v in pair_counter.most_common(12)],
        "zones": dict(zone_c),
        "lane_cells_total": len(lane_cells),
        "lane_cells_prop": len(lane_prop),
        "lane_cells_prop_flood": len(lane_prop_flood),
        "mystery_solids": mystery,
        "top_regions": [
            {"region": list(k), "cells": [k[0] * RB, k[1] * RB], **v} for k, v in top_buckets
        ],
        "screenshot_sites": sites,
        "samples": samples,
        "pinches": pinches,
        "lane_cells": lane_cells,
    },
    open(OUT, "w", encoding="utf-8"),
    indent=1,
)
print(f"\nwritten: {OUT.relative_to(REPO)}")
