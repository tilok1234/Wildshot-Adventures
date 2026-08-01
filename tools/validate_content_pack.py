"""Fixed validation gate for the world_filler content-pack raw drop
(wildshot-overworld-pack-dusk-content, REFERENCE ONLY per docs/20 step 1).

Validates the pack at assets/wildshot-overworld-pack-dusk-content (or argv[1])
against its own manifest + the intake passport (<pack>.passport.json, argv[2]),
and REFUSES LOUDLY if the pack's base no longer matches the vendored b77 world
(wf verifyPack semantics replicated: generation identity, world.json sha,
format, dims). The manifest's files table pins the 4 payloads; the passport
pins manifest.json + the 3 renders. Structural pins: placement rule census,
the eight designer locks at their exact cells, territory cell totals, report
gates all-pass on the same base. Exit 0 = clean.

    python tools/validate_content_pack.py [pack-dir] [passport.json]
"""

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image

PACK = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/wildshot-overworld-pack-dusk-content")
PASSPORT = Path(sys.argv[2] if len(sys.argv) > 2 else str(PACK) + ".passport.json")
B77_WORLD = Path("assets/worldforge-packs/wildshot-overworld-pack-dusk/world.json")
LOCKS = {
    "placement.world_boss.region.dry_grass.29992.0": (50, 133),
    "placement.world_boss.region.mud.31157.0": (198, 124),
    "placement.world_boss.region.mud.57087.0": (249, 244),
    "placement.world_boss.region.snow.4982.0": (118, 19),
    "placement.dungeon.region.grass.54237.0": (193, 239),
    "placement.dungeon.region.dry_grass.28429.0": (17, 131),
    "placement.dungeon.region.gravel.3995.0": (153, 19),
    "placement.dungeon.region.mud.37835.0": (193, 163),
}
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
if manifest["pack"] != "worldfiller-content-pack" or manifest["packFormat"] != 3:
    fail(f"pack identity {manifest['pack']} format {manifest['packFormat']}")
if manifest["sourceCommit"] != passport["source"]["sourceCommit"]:
    fail("manifest sourceCommit != passport")

# file-set parity: 4 hashed payloads + manifest + the passport-pinned renders
listed = dict(manifest["files"].items())
renders = dict(passport["renderSha256"].items())
on_disk = {p.relative_to(PACK).as_posix() for p in PACK.rglob("*") if p.is_file()}
want = set(listed) | set(renders) | {"manifest.json"}
if on_disk != want:
    fail(f"file-set mismatch +{sorted(on_disk - want)[:4]} -{sorted(want - on_disk)[:4]}")
for rel, sha in sorted({**listed, **renders}.items()):
    p = PACK / rel
    if not p.is_file():
        fail(f"missing file: {rel}")
        continue
    if hashlib.sha256(p.read_bytes()).hexdigest() != sha:
        fail(f"sha256 drift vs pin: {rel}")

# base pairing vs the vendored b77 world — the LOUD refusal (wf verifyPack)
base = manifest["base"]
if not B77_WORLD.is_file():
    fail(f"vendored base world missing: {B77_WORLD}")
else:
    world = json.loads(B77_WORLD.read_text("utf-8"))
    wid = world["generator"]["generationIdentitySha256"]
    if base["generationIdentitySha256"] != wid:
        fail(
            f"content pack was directed against base {base['generationIdentitySha256'][:12]}... "
            f"but the vendored world is {wid[:12]}... — regenerate or re-pin"
        )
    if base["artifactSha256"] != hashlib.sha256(B77_WORLD.read_bytes()).hexdigest():
        fail("base.artifactSha256 != sha256 of the vendored world.json — the base world drifted")
    if base["artifactFormat"] != world["formatVersion"]:
        fail(f"base.artifactFormat {base['artifactFormat']} != world formatVersion {world['formatVersion']}")
    dims = world["dimensions"]
    if (base["width"], base["height"]) != (dims["width"], dims["height"]):
        fail("base dims != vendored world dims")

# payload structure: counts, rule census, locks, territories, report gates
counts = manifest["counts"]
pj = json.loads((PACK / "placements.json").read_text("utf-8"))
placements = pj["placements"]
if len(placements) != counts["placements"]:
    fail(f"placements {len(placements)} != manifest count {counts['placements']}")
by_rule: dict[str, int] = {}
for p in placements:
    by_rule[p["rule"]] = by_rule.get(p["rule"], 0) + 1
if by_rule != {"encounter_site.v1": 112, "dungeon_binding.v1": 11, "world_boss.v1": 4}:
    fail(f"placement rule census moved: {by_rule}")
by_id = {p["id"]: p for p in placements}
for lid, cell in LOCKS.items():
    p = by_id.get(lid)
    if p is None:
        fail(f"designer lock missing: {lid}")
    elif not p.get("locked") or tuple(p["cell"]) != cell:
        fail(f"designer lock moved: {lid} at {p['cell']} locked={p.get('locked')}")
if len(pj["unboundAnchors"]) != counts["unboundAnchors"]:
    fail(f"unbound anchors {len(pj['unboundAnchors'])} != {counts['unboundAnchors']}")
if len(pj["failures"]) != counts["placementFailures"]:
    fail(f"placement failures {len(pj['failures'])} != {counts['placementFailures']}")

tj = json.loads((PACK / "territories.json").read_text("utf-8"))
terrs = tj["territories"]
if len(terrs) != counts["territories"]:
    fail(f"territories {len(terrs)} != manifest count {counts['territories']}")
cell_sum = sum(t["cellCount"] for t in terrs)
if cell_sum != 9189:
    fail(f"territory cell total {cell_sum} != 9189 (the sl-0093 record)")
if len(tj["failures"]) != counts["territoryFailures"]:
    fail(f"territory failures {len(tj['failures'])} != {counts['territoryFailures']}")

report = json.loads((PACK / "report.json").read_text("utf-8"))
if not report.get("ok"):
    fail("report.ok is false")
gates = report.get("gates", [])
bad_gates = [g["id"] for g in gates if g.get("status") != "pass"]
if len(gates) != 9 or bad_gates:
    fail(f"report gates: {len(gates)} listed, failing {bad_gates}")
if report["base"]["generationIdentitySha256"] != base["generationIdentitySha256"]:
    fail("report base identity != manifest base identity")

cp = json.loads((PACK / "content-plan.json").read_text("utf-8"))
zones = cp.get("zones", [])
if len(zones) != 4 or sorted(z["family"] for z in zones) != ["cold", "dry", "green", "wet"]:
    fail(f"zone census moved: {[z.get('id') for z in zones]}")
if len(cp.get("giverSlots", [])) != 16 or len(cp.get("gatherSpots", [])) != 24:
    fail(f"plan payload counts moved: givers {len(cp.get('giverSlots', []))} gathers {len(cp.get('gatherSpots', []))}")

for rel in sorted(renders):
    try:
        im = Image.open(PACK / rel)
        im.load()
    except Exception as e:
        fail(f"{rel} does not decode ({e})")

print(
    f"checked {len(placements)} placements ({by_rule.get('world_boss.v1', 0)} bosses, "
    f"{by_rule.get('dungeon_binding.v1', 0)} dungeons), {len(terrs)} territories "
    f"({cell_sum} cells), 8 locks, base pairing vs b77, {len(renders)} renders at {PACK}"
)
if findings:
    print(f"\nFAIL — {len(findings)} findings:")
    for f in findings:
        print(" -", f)
    sys.exit(1)
print("PASS — content pack byte-true, designer locks held, base pairing intact (b77)")
