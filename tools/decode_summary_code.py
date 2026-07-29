"""Decode a tester summary code (M8 feedback fallback).

Mirrors game/drivers/feedback_bundle.gd encode_code():
    WS1-MMM-SSDD-KKKC   (Crockford base32, no I/L/O/U)
    MMM minutes | SS sessions | DD deaths | KKK kills | C checksum

Usage: python tools/decode_summary_code.py WS1-XXX-XXXX-XXXX
Exits 1 on malformed input or checksum mismatch (a typo'd code must
never silently become wrong evidence).
"""

import sys

B32 = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"


def b32_int(s: str) -> int:
    v = 0
    for ch in s:
        v = v * 32 + B32.index(ch)
    return v


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__.strip())
        return 1
    code = sys.argv[1].strip().upper().replace("O", "0").replace("I", "1").replace("L", "1")
    parts = code.split("-")
    if len(parts) != 4 or parts[0] != "WS1" or [len(p) for p in parts[1:]] != [3, 4, 4]:
        print(f"malformed code: {code!r} (expect WS1-MMM-SSDD-KKKC)")
        return 1
    body = parts[1] + parts[2] + parts[3][:3]
    chk = parts[3][3]
    if any(ch not in B32 for ch in body + chk):
        print(f"malformed code: {code!r} (illegal character)")
        return 1
    if B32[sum(B32.index(ch) for ch in body) % 32] != chk:
        print(f"CHECKSUM MISMATCH: {code!r} — re-ask the tester, do not log this")
        return 1
    print(f"code:     {code}")
    print(f"minutes:  {b32_int(body[0:3])}")
    print(f"sessions: {b32_int(body[3:5])}")
    print(f"deaths:   {b32_int(body[5:7])}")
    print(f"kills:    {b32_int(body[7:10])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
