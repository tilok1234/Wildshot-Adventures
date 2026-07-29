"""Tester-bundle evidence report (M8 return path, designer side).

Reads a feedback bundle zip (or a bare session.jsonl) and prints the
Gate-1 evidence FACTS: tester sessions with durations and loadouts,
gaps between sessions, totals, dev-profile exclusions, and a
contamination scan. It computes measurements only — the operational
definition of "re-engagement" is a pending planning-repo lock (docs/12
SS6 item 6) and is deliberately NOT baked in here.

Also cross-checks bundle_info.json's stored summary code by recomputing
it from the log (mirrors game/drivers/feedback_bundle.gd; the encoding
is locked cross-language by the WS1-00F-0202-002N test vector).

Usage:
    python tools/evidence_report.py <bundle.zip | session.jsonl> [--json]
    python tools/evidence_report.py --selftest
"""

import io
import json
import sys
import zipfile
from datetime import datetime, timezone

B32 = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
CONTAMINATION_MARKERS = ("DAMAGE_IMMUNE", "SET_GOD", "slowmo")


def b32enc(v: int, width: int) -> str:
    s = ""
    for _ in range(width):
        s = B32[v % 32] + s
        v //= 32
    return s


def encode_code(minutes: int, sessions: int, deaths: int, kills: int) -> str:
    body = (
        b32enc(min(max(minutes, 0), 32767), 3)
        + b32enc(min(max(sessions, 0), 1023), 2)
        + b32enc(min(max(deaths, 0), 1023), 2)
        + b32enc(min(max(kills, 0), 32767), 3)
    )
    chk = B32[sum(B32.index(c) for c in body) % 32]
    return f"WS1-{body[0:3]}-{body[3:7]}-{body[7:10]}{chk}"


def analyze(lines):
    """One walk over the jsonl: session windows, per-window facts."""
    sessions = []  # tester sessions, in order
    excluded_dev = 0
    cur = None
    cur_dev = False
    contaminated = []

    def close_current():
        nonlocal cur
        if cur is not None and not cur_dev:
            sessions.append(cur)
        cur = None

    for raw in lines:
        raw = raw.strip()
        if not raw:
            continue
        try:
            d = json.loads(raw)
        except json.JSONDecodeError:
            continue
        kind = d.get("kind", "")
        if kind == "session_start":
            close_current()
            cur_dev = bool(d.get("dev_profile", False))
            if cur_dev:
                excluded_dev += 1
            cur = {
                "session": d.get("session", "?"),
                "build": d.get("build", "?"),
                "scenario": str(d.get("scenario", "?")).split("/")[-1].replace(".tres", ""),
                "start_unix": int(d.get("unix", 0)),
                "utc": d.get("utc", "?"),
                "last_unix": int(d.get("unix", 0)),
                "clean_end": False,
                "loadouts": [],
                "deaths": 0,
                "kills": 0,
            }
        elif cur is None:
            continue
        elif kind == "session_heartbeat":
            cur["last_unix"] = int(d.get("unix", cur["last_unix"]))
        elif kind == "session_end":
            cur["last_unix"] = int(d.get("unix", cur["last_unix"]))
            cur["clean_end"] = True
        elif kind == "loadout":
            cur["loadouts"].append(float(d.get("speed", 0)))
        elif not cur_dev:
            if "death_tick" in d:
                cur["deaths"] += 1
            elif kind == "enemy_kill":
                cur["kills"] += 1
            if any(m in raw for m in CONTAMINATION_MARKERS):
                contaminated.append(cur["session"])
    close_current()

    for s in sessions:
        s["secs"] = max(0, s["last_unix"] - s["start_unix"])
    total_secs = sum(s["secs"] for s in sessions)
    gaps = []
    for a, b in zip(sessions, sessions[1:]):
        gaps.append(max(0, b["start_unix"] - a["last_unix"]))
    return {
        "sessions": sessions,
        "excluded_dev_sessions": excluded_dev,
        "gaps_secs": gaps,
        "total_minutes": total_secs // 60,
        "total_deaths": sum(s["deaths"] for s in sessions),
        "total_kills": sum(s["kills"] for s in sessions),
        "lowest_speed_sessions": sum(1 for s in sessions if any(v <= 3.0 for v in s["loadouts"])),
        "contaminated_sessions": sorted(set(contaminated)),
        "builds": sorted({s["build"] for s in sessions}),
    }


def fmt_dur(secs: int) -> str:
    return f"{secs // 60}m{secs % 60:02d}s"


def report(result, stored_code=None) -> str:
    out = []
    n = len(result["sessions"])
    out.append(f"tester sessions: {n}   (dev-profile excluded: {result['excluded_dev_sessions']})")
    out.append(
        f"total: {result['total_minutes']} min, {result['total_deaths']} deaths, "
        f"{result['total_kills']} kills   builds: {', '.join(result['builds']) or '-'}"
    )
    out.append(
        f"lowest-speed sessions (loadout <= 3.0): {result['lowest_speed_sessions']} of {n}"
    )
    recomputed = encode_code(
        result["total_minutes"], n, result["total_deaths"], result["total_kills"]
    )
    if stored_code is not None:
        match = "MATCH" if stored_code == recomputed else "MISMATCH - investigate"
        out.append(f"summary code: stored {stored_code} / recomputed {recomputed} -> {match}")
    else:
        out.append(f"summary code (recomputed): {recomputed}")
    if result["contaminated_sessions"]:
        out.append(
            "!! CONTAMINATION MARKERS inside tester sessions "
            f"{result['contaminated_sessions']} - a tester build cannot produce these; "
            "treat the bundle as suspect"
        )
    out.append("")
    out.append("per session:")
    for s in result["sessions"]:
        loads = "/".join(f"{v:g}" for v in s["loadouts"]) or "-"
        end = "end" if s["clean_end"] else "last-beat"
        out.append(
            f"  {s['utc']}  {fmt_dur(s['secs']):>8} ({end})  scenario={s['scenario']}"
            f"  loadout={loads}  deaths={s['deaths']} kills={s['kills']}  [{s['build']}]"
        )
    if result["gaps_secs"]:
        out.append("gaps between sessions: " + ", ".join(fmt_dur(g) for g in result["gaps_secs"]))
    out.append("")
    out.append("(facts only - the re-engagement operational definition is a planning-repo lock)")
    return "\n".join(out)


def selftest() -> int:
    lines = [
        json.dumps(x)
        for x in [
            {"kind": "session_start", "dev_profile": False, "unix": 1000, "utc": "T1",
             "session": "s1", "build": "b1", "scenario": "first_contact"},
            {"kind": "loadout", "speed": 3.0, "unix": 1001},
            {"kind": "enemy_kill", "tick": 5},
            {"death_tick": 9},
            {"kind": "enemy_kill", "tick": 12},
            {"kind": "session_end", "unix": 1600},
            {"kind": "session_start", "dev_profile": True, "unix": 2000, "utc": "T2",
             "session": "dev", "build": "b1", "scenario": "x"},
            {"death_tick": 1},
            {"kind": "session_end", "unix": 9000},
            {"kind": "session_start", "dev_profile": False, "unix": 6000, "utc": "T3",
             "session": "s2", "build": "b1", "scenario": "first_contact"},
            {"kind": "loadout", "speed": 4.0, "unix": 6001},
            {"kind": "session_heartbeat", "unix": 6300},
            {"death_tick": 7},
        ]
    ]
    r = analyze(lines)
    checks = [
        (len(r["sessions"]) == 2, "2 tester sessions"),
        (r["excluded_dev_sessions"] == 1, "1 dev excluded"),
        (r["total_minutes"] == 15, f"15 min (got {r['total_minutes']})"),
        (r["total_deaths"] == 2, "2 deaths"),
        (r["total_kills"] == 2, "2 kills"),
        (r["lowest_speed_sessions"] == 1, "1 lowest-speed session"),
        (r["gaps_secs"] == [4400], f"gap 4400s (got {r['gaps_secs']})"),
        (not r["contaminated_sessions"], "no contamination"),
        # Cross-language pin: same vector the Godot test asserts.
        (encode_code(15, 2, 2, 2) == "WS1-00F-0202-002N", "code parity with game encoder"),
    ]
    contaminated = analyze(
        lines[:2] + [json.dumps({"kind": "x", "note": "DAMAGE_IMMUNE absorbed"})] + lines[2:]
    )
    checks.append((contaminated["contaminated_sessions"] == ["s1"], "contamination flagged"))
    bad = [msg for ok, msg in checks if not ok]
    if bad:
        print("evidence_report selftest FAIL: " + "; ".join(bad))
        return 1
    print("evidence_report selftest PASS (sessions/exclusion/gaps/loadouts/code-parity/contamination)")
    return 0


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__.strip())
        return 1
    if sys.argv[1] == "--selftest":
        return selftest()
    path = sys.argv[1]
    stored_code = None
    if path.lower().endswith(".zip"):
        with zipfile.ZipFile(path) as z:
            names = z.namelist()
            if "bundle_info.json" in names:
                info = json.loads(z.read("bundle_info.json").decode("utf-8"))
                stored_code = info.get("summary_code")
            if "session.jsonl" not in names:
                print("no session.jsonl in bundle")
                return 1
            lines = io.TextIOWrapper(z.open("session.jsonl"), encoding="utf-8").readlines()
    else:
        with open(path, encoding="utf-8") as f:
            lines = f.readlines()
    result = analyze(lines)
    if "--json" in sys.argv[2:]:
        print(json.dumps(result, indent=1))
    else:
        print(report(result, stored_code))
    return 0


if __name__ == "__main__":
    sys.exit(main())
