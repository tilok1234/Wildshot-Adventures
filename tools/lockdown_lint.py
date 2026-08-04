"""Tester-profile lockdown lint (M8 Gate-1-ready checklist, docs/12 SS4).

Statically proves the ONE-FLAG dev_tools gate (game/main.gd SS2.10) still
holds: every sim-mutating dev affordance is reachable only behind
`dev_tools` (= not OS.has_feature("tester")), and the tester export preset
carries the feature tag + exclusion filters that make the gate bite.

This is the source-side half of the sweep; tools/lockdown_probe.ps1 probes
the BUILT artifacts. Both run inside tools/pretester_check.ps1.

Assertions are anchored to exact source text (gdformat reflows — anchors
chosen to survive it). If a refactor moves an anchor, the lint fails loudly
and must be re-pinned DELIBERATELY — that is the point: the gate cannot
drift silently. Exit 0 = gate proven.
"""

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
findings: list[str] = []


def fail(msg: str) -> None:
    findings.append(msg)


main_gd = (REPO / "game/main.gd").read_text(encoding="utf-8")
main_lines = main_gd.splitlines()

# 1. The flag itself: assigned exactly once, from the feature tag, never
#    written again.
decl = [l for l in main_lines if re.search(r"^var dev_tools\b", l)]
if len(decl) != 1 or 'not OS.has_feature("tester")' not in decl[0]:
    fail(f"dev_tools declaration drifted: {decl}")
writes = [l for l in main_lines if re.search(r"\bdev_tools\s*=[^=]", l) and "var dev_tools" not in l]
if writes:
    fail(f"dev_tools reassigned: {writes}")
repo_gd = {p: p.read_text(encoding="utf-8") for p in REPO.glob("**/*.gd") if ".godot" not in p.parts and "addons" not in p.parts}
for p, text in repo_gd.items():
    if p.name != "main.gd" and "dev_tools" in text:
        fail(f"dev_tools referenced outside main.gd: {p.relative_to(REPO)}")
    if p.name != "main.gd" and 'has_feature("tester")' in text:
        fail(f'has_feature("tester") outside main.gd (second gate?): {p.relative_to(REPO)}')

# 2. Debug console: constructed exactly once in main, inside an
#    `if dev_tools:` block, plus the sl-0206 input-swallow test harness
#    (tests/* is excluded from the tester artifact — the exclusion
#    filter itself is pinned in section 9 below).
ctor_lines = [i for i, l in enumerate(main_lines) if "DebugConsole.new()" in l]
all_ctors = sorted(
    (p.relative_to(REPO), text.count("DebugConsole.new()"))
    for p, text in repo_gd.items()
    if "DebugConsole.new()" in text
)
if all_ctors != [
    (Path("game/main.gd"), 1),
    (Path("tests/console_swallow/console_swallow_test.gd"), 1),
]:
    fail(f"DebugConsole constructed outside the sanctioned sites: {all_ctors}")
if ctor_lines:
    i = ctor_lines[0]
    ctor_indent = len(main_lines[i]) - len(main_lines[i].lstrip("\t"))
    gated = False
    for j in range(i - 1, max(i - 12, -1), -1):
        line = main_lines[j]
        if not line.strip():
            continue
        indent = len(line) - len(line.lstrip("\t"))
        if indent < ctor_indent:
            gated = line.strip().startswith("if dev_tools:")
            break
    if not gated:
        fail("DebugConsole.new() is not directly inside an `if dev_tools:` block")

# 2b. Dev map overlay (sl-0065): console-class construction contract.
#     Exactly four sites: main's gated block + the two dev_map test
#     harnesses + the sl-0121 quest-marker probe (tests/* is excluded
#     from the tester artifact — the exclusion filter itself is pinned
#     in section 9 below).
mo_all = sorted(
    (p.relative_to(REPO), text.count("MapOverlay.new()"))
    for p, text in repo_gd.items()
    if "MapOverlay.new()" in text
)
if mo_all != [
    (Path("game/main.gd"), 1),
    (Path("tests/dev_map/dev_map_test.gd"), 1),
    (Path("tests/dev_map/map_overlay_probe.gd"), 1),
    (Path("tests/quest_pull/quest_pull_probe.gd"), 1),
]:
    fail(f"MapOverlay construction sites drifted: {mo_all}")
mo_lines = [i for i, l in enumerate(main_lines) if "MapOverlay.new()" in l]
if mo_lines:
    i = mo_lines[0]
    mo_indent = len(main_lines[i]) - len(main_lines[i].lstrip("\t"))
    mo_gated = False
    for j in range(i - 1, max(i - 12, -1), -1):
        line = main_lines[j]
        if not line.strip():
            continue
        indent = len(line) - len(line.lstrip("\t"))
        if indent < mo_indent:
            mo_gated = line.strip().startswith("if dev_tools")
            break
    if not mo_gated:
        fail("MapOverlay.new() is not directly inside an `if dev_tools` block")

# 3. Free speed steps: both fine-step inputs carry the gate on the same line.
#    The sl-0065 map toggle rides the same rule.
for action in ("debug_speed_down", "debug_speed_up", "map_toggle"):
    hits = [l for l in main_lines if action in l and "is_action_just_pressed" in l]
    if len(hits) != 1 or "dev_tools and" not in hits[0]:
        fail(f"{action} input check not dev_tools-gated: {hits}")

# 4. CLI bot mode: the bot branch is gated.
bot_hits = [l for l in main_lines if 'BootArgs.get_arg("bot")' in l]
if len(bot_hits) != 1 or "dev_tools and" not in bot_hits[0]:
    fail(f"--bot CLI branch not dev_tools-gated: {bot_hits}")

# 5. Audit modes: both flags carry their gate in the declaration.
audit_mode_hits = [l for l in main_lines if re.search(r"\bvar audit_mode\b", l)]
if len(audit_mode_hits) != 1 or "dev_tools and" not in audit_mode_hits[0]:
    fail(f"audit_mode not dev_tools-gated at declaration: {audit_mode_hits}")
audit_min_hits = [l for l in main_lines if re.search(r"\bvar audit_min\b", l)]
if len(audit_min_hits) != 1 or "audit_mode and" not in audit_min_hits[0]:
    fail(f"audit_min not audit_mode-gated at declaration: {audit_min_hits}")
verify_hits = [l for l in main_lines if re.search(r"\bvar verify_mode\b", l)]
if len(verify_hits) != 1 or "dev_tools and" not in verify_hits[0]:
    fail(f"verify_mode (--verify CLI) not dev_tools-gated at declaration: {verify_hits}")

# 6. God: SET_GOD is enqueued from exactly two sites (console exec + audit
#    block), both console/audit-gated; nothing else in game/ enqueues it.
god_sites = []
for p, text in repo_gd.items():
    if "sim" in p.parts:
        continue
    for i, l in enumerate(text.splitlines()):
        if "SET_GOD" in l:
            god_sites.append((p.relative_to(REPO), i))
if len(god_sites) != 2 or any(str(f) != str(Path("game/main.gd")) for f, _ in god_sites):
    fail(f"SET_GOD enqueue sites drifted (expect exactly 2 in main.gd): {god_sites}")

# 7. Slow-mo: time_divisor written only at its declaration default and the
#    one console handler line.
td_writes = []
for p, text in repo_gd.items():
    for l in text.splitlines():
        if re.search(r"\btime_divisor\s*=[^=]", l) and "var time_divisor" not in l:
            td_writes.append((p.relative_to(REPO), l.strip()))
if len(td_writes) != 1 or str(td_writes[0][0]) != str(Path("game/main.gd")):
    fail(f"time_divisor write sites drifted (expect 1, console handler): {td_writes}")

# 8. Verdicts: the jsonl is opened only inside main.gd (the console verdict
#    handler — reachable only through the gated console).
v_sites = [
    p.relative_to(REPO) for p, text in repo_gd.items() if "verdicts.jsonl" in text
]
if v_sites != [Path("game/main.gd")]:
    fail(f"verdicts.jsonl touched outside main.gd: {v_sites}")

# 9. Export presets: tester carries the feature tag + exclusions; dev does not.
cfg = (REPO / "export_presets.cfg").read_text(encoding="utf-8")
presets = {}
for block in cfg.split("[preset.")[1:]:
    name_m = re.search(r'name="([^"]+)"', block)
    if name_m:
        presets[name_m.group(1)] = block
tester = presets.get("windows-tester", "")
dev = presets.get("windows-dev", "")
if 'custom_features="tester"' not in tester:
    fail("windows-tester preset lost the tester feature tag")
excl_m = re.search(r'exclude_filter="([^"]*)"', tester)
excl = excl_m.group(1) if excl_m else ""
for want in ("tests/*", "reports/*", "assets/*"):
    if want not in excl:
        fail(f"windows-tester exclude_filter missing {want}: {excl!r}")
if 'custom_features=""' not in dev:
    fail("windows-dev preset grew custom features (must stay empty)")

if findings:
    print(f"LOCKDOWN LINT: FAIL - {len(findings)} finding(s):")
    for f in findings:
        print(" -", f)
    sys.exit(1)
print("LOCKDOWN LINT: PASS - one-flag gate proven at source level")
