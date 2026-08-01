"""The balance calculator (sl-0095, docs/22 block 9 - designer-approved spec).

Paper-first, deterministic, zero sim contact: reads the game-owned data file
data/balance_frame.json (or argv[1]) and proves the ruled stat frame's gates:
  1. TTK/TTD per zone x class x expected gear inside the declared bands
     at the sl-0087 brackets;
  2. armor liveness - obtainable armor in the 0.4-0.6x band, flagged loudly
     at >= 0.8x common hits (the block-2 floor-plateau onset);
  3. the pattern x scenario realized-DPS matrix - every pattern best in >= 1
     scenario, none best in all (block 3, CORE-41);
  4. ordinary enemies die in 3-5 reference hits at every band; frequent
     combat numbers <= 3 digits (block 9 / A.4);
  5. the ITEM VALIDATOR - refuses over-budget items (block 4), un-paired
     stat uplifts (block 7's six-pair grammar), and uniques with zero/two
     rule-breaks or a chassis outside 70-90% of tier budget (block 8).
The ruled constants are HARD-CODED here as the design contract: a data file
drifting from docs/22's frame FAILS - mismatches flag loudly, and docs/22 is
never amended game-side. All damage math uses THE formula:
    taken = max(attack - armor, ceil(attack * 0.2))    (one rounding step)

    python tools/balance_calc.py [data/balance_frame.json]
"""

import json
import math
import sys

# ---- the ruled frame (docs/22, designer 2026-08-01) - the design contract ----
FLOOR = 0.2
BRACKETS = {"green": (1, 7, 1), "dry": (8, 15, 2), "wet": (16, 22, 3), "snow": (23, 30, 4)}
BUDGET_STEP = 1.4
FRAME_BAND = 0.1
ARMOR_BAND = (0.4, 0.6)
PLATEAU = 0.8
HITS_BAND = (3, 5)
MAX_NUMBER = 999
HP_STEP_BAND = (1.25, 1.30)
SPEED_BASES = [100, 105, 110]
SPEED_CAP = 115
PAIRS = {("damage", "defense"), ("speed", "hp"), ("range", "attack_speed"),
         ("hp", "speed"), ("defense", "damage"), ("mana", "hp")}
UNIQUE_WHITELIST = {"pattern_replacement", "exception_behaviour", "over_budget_paired_cost", "utility"}
CHASSIS_BAND = (0.7, 0.9)

findings: list[str] = []


def fail(msg: str) -> None:
    findings.append(msg)


def taken(attack: int, armor: int) -> int:
    return max(attack - armor, math.ceil(attack * FLOOR))


d = json.load(open(sys.argv[1] if len(sys.argv) > 1 else "data/balance_frame.json", encoding="utf-8"))

# ---- ruled-frame mismatch checks (the file is the game's, the design is planning's) ----
if d["formula"]["floor_fraction"] != FLOOR:
    fail(f"formula floor {d['formula']['floor_fraction']} != ruled 0.2")
file_brackets = {b["zone"]: (b["levels"][0], b["levels"][1], b["tier"]) for b in d["brackets"]}
if file_brackets != BRACKETS:
    fail(f"brackets drifted from sl-0087: {file_brackets}")
wt = d["weapon_tiers"]
if wt["budget_step"] != BUDGET_STEP or wt["frame_band"] != FRAME_BAND:
    fail("weapon tier step/band drifted from the block-3/4 ruling")
if d["armor_rules"]["obtainable_band"] != list(ARMOR_BAND) or d["armor_rules"]["plateau_flag"] != PLATEAU:
    fail("armor rules drifted from the block-2 rider")
if d["hits_to_kill"]["band"] != list(HITS_BAND):
    fail("hits-to-kill band drifted from the block-9 ruling")
file_pairs = {(p["up"], p["down"]) for p in d["pairs"]}
if file_pairs != PAIRS:
    fail(f"pair grammar drifted from the block-7 six (delta {file_pairs ^ PAIRS})")
ur = d["unique_rules"]
if ur["breaks_required"] != 1 or set(ur["whitelist"]) != UNIQUE_WHITELIST or ur["chassis_fraction_band"] != list(CHASSIS_BAND):
    fail("unique rules drifted from the block-8 ruling")
if sorted(c["base_speed"] for c in d["classes"].values()) != SPEED_BASES or d["speed_rules"]["hard_cap"] != SPEED_CAP:
    fail("speed bases/cap drifted from the block-6 ruling")

budgets = [wt["t1_dps_budget"] * BUDGET_STEP ** t for t in range(5)]
frames = wt["frames"]
tiers_of_zone = {z: BRACKETS[z][2] for z in BRACKETS}
mid_level = {z: (BRACKETS[z][0] + BRACKETS[z][1] + 1) // 2 for z in BRACKETS}

# frame DPS within +/-10% of budget at every tier
for fname, f in frames.items():
    for t in range(5):
        dps = f["damage"][t] * f["shots_per_sec"]
        r = dps / budgets[t]
        if not (1 - FRAME_BAND - 1e-9 <= r <= 1 + FRAME_BAND + 1e-9):
            fail(f"{fname} T{t + 1} DPS {dps:.1f} is {r:.3f}x budget (band +/-10%)")

# armor HP steps chunky per block 4
ahp = d["armor_slot"]["hp"]
for t in range(1, 5):
    step = ahp[t] / ahp[t - 1]
    if not (HP_STEP_BAND[0] - 1e-9 <= step <= HP_STEP_BAND[1] + 1e-9):
        fail(f"armor HP step T{t}->T{t + 1} = {step:.3f} outside {HP_STEP_BAND}")

# ---- gate 1: TTK / TTD per zone x class x expected gear ----
ttk_lo, ttk_hi = d["ttk_band_seconds"]
ttd_lo, ttd_hi = d["ttd_band_seconds"]
report_rows = []
for zone, band in d["enemy_bands"].items():
    t = tiers_of_zone[zone] - 1
    for cname, c in d["classes"].items():
        f = frames[c["weapon_frame"]]
        hits = math.ceil(band["trash_hp"] / f["damage"][t])
        ttk = hits / f["shots_per_sec"]
        if not (ttk_lo <= ttk <= ttk_hi):
            fail(f"TTK {zone}/{cname}: {ttk:.2f}s outside [{ttk_lo}, {ttk_hi}]")
        hp = c["base_hp"] + (mid_level[zone] - 1) * c["hp_per_level"] + ahp[t]
        per_hit = taken(band["typical_hit"], d["armor_slot"]["defense"][t])
        ttd = hp / (per_hit * band["landed_hits_per_sec"])
        if not (ttd_lo <= ttd <= ttd_hi):
            fail(f"TTD {zone}/{cname}: {ttd:.1f}s outside [{ttd_lo}, {ttd_hi}]")
        report_rows.append(f"  {zone:5s} {cname:5s} L{mid_level[zone]:2d} T{t + 1}: TTK {ttk:.2f}s ({hits} hits), TTD {ttd:.1f}s (taken {per_hit}/hit)")

# ---- gate 2: armor liveness (block-2 rider) ----
for zone, band in d["enemy_bands"].items():
    t = tiers_of_zone[zone] - 1
    ratio = d["armor_slot"]["defense"][t] / band["typical_hit"]
    if not (ARMOR_BAND[0] - 1e-9 <= ratio <= ARMOR_BAND[1] + 1e-9):
        fail(f"armor band {zone}: obtainable {d['armor_slot']['defense'][t]} = {ratio:.2f}x typical hit (band 0.4-0.6)")
    if ratio >= PLATEAU:
        fail(f"ARMOR PLATEAU {zone}: {ratio:.2f}x >= 0.8x common hits (floor-plateau onset)")
snow_hit = d["enemy_bands"]["snow"]["typical_hit"]
if d["armor_slot"]["defense"][4] / snow_hit >= PLATEAU:
    fail(f"ARMOR PLATEAU T5 capstone: {d['armor_slot']['defense'][4]}/{snow_hit} >= 0.8x")

# ---- gate 3: pattern x scenario fairness (block 3 / CORE-41) ----
scenarios = d["pattern_matrix"]["scenarios"]
mult = d["pattern_matrix"]["realized_multipliers"]
for t in range(5):
    best_count = {p: 0 for p in mult}
    for s in scenarios:
        realized = {p: frames[p]["damage"][t] * frames[p]["shots_per_sec"] * mult[p][s] for p in mult}
        top = max(realized.values())
        winners = [p for p, v in realized.items() if abs(v - top) < 1e-9]
        for w in winners:
            best_count[w] += 1
    for p, n in best_count.items():
        if n == 0:
            fail(f"pattern fairness T{t + 1}: {p} is best in NO scenario")
        if n == len(scenarios):
            fail(f"pattern fairness T{t + 1}: {p} is best in ALL scenarios")

# ---- gate 4: chunky hits + digit rule ----
ref = d["hits_to_kill"]["reference_frame"]
for zone, band in d["enemy_bands"].items():
    t = tiers_of_zone[zone] - 1
    hits = math.ceil(band["trash_hp"] / frames[ref]["damage"][t])
    if not (HITS_BAND[0] <= hits <= HITS_BAND[1]):
        fail(f"hits-to-kill {zone}: {hits} reference hits outside 3-5")
numbers = []
for f in frames.values():
    numbers += f["damage"]
for band in d["enemy_bands"].values():
    numbers += [band["typical_hit"], band["trash_hp"]]
numbers += d["armor_slot"]["defense"] + d["armor_slot"]["hp"]
for cname, c in d["classes"].items():
    numbers.append(c["base_hp"] + 29 * c["hp_per_level"] + ahp[3])
for n in numbers:
    if n > MAX_NUMBER:
        fail(f"combat number {n} exceeds 3 digits")

# ---- gate 5: the item validator (blocks 4/7/8 - TECH-16 discharged) ----
for item in d["items"]:
    iid = item["id"]
    unique = item.get("unique")
    if unique is not None:
        breaks = unique.get("breaks", [])
        if len(breaks) != 1:
            fail(f"item {iid}: unique breaks {len(breaks)} rules (exactly one - zero is not a unique, two is never)")
        elif breaks[0] not in UNIQUE_WHITELIST:
            fail(f"item {iid}: break '{breaks[0]}' not on the block-8 whitelist")
        cf = unique.get("chassis_fraction")
        if cf is None or not (CHASSIS_BAND[0] <= cf <= CHASSIS_BAND[1]):
            fail(f"item {iid}: unique chassis {cf} outside 70-90% of tier budget")
        continue
    t = item["tier"] - 1
    trade = item.get("trade")
    raw = item.get("stats", {})
    if raw:
        fail(f"item {iid}: raw un-paired stat uplift {sorted(raw)} - the block-7 grammar refuses something-for-nothing")
    if trade is not None:
        combo = (trade.get("up"), trade.get("down"))
        if combo not in PAIRS:
            fail(f"item {iid}: trade {combo[0]}/{combo[1]} is not one of the six sanctioned pairs")
        elif trade.get("up_amount", 0) <= 0 or trade.get("down_amount", 0) <= 0:
            fail(f"item {iid}: trade amounts must both be real (up {trade.get('up_amount')}, down {trade.get('down_amount')})")
    if item["slot"] == "weapon":
        f = frames.get(item.get("frame", ""))
        if f is None:
            fail(f"item {iid}: unknown weapon frame '{item.get('frame')}'")
        else:
            r = f["damage"][t] * f["shots_per_sec"] / budgets[t]
            if not (1 - FRAME_BAND - 1e-9 <= r <= 1 + FRAME_BAND + 1e-9):
                fail(f"item {iid}: weapon at {r:.3f}x tier budget (over/under the +/-10% frame band)")
    elif item["slot"] == "ring":
        if trade is None:
            fail(f"item {iid}: a ring is exactly ONE sanctioned pair - no trade declared")

# ---- info report (never gated) ----
xp = d["xp"]
zone_levels = {z: BRACKETS[z][1] - BRACKETS[z][0] + (0 if z == "green" else 1) for z in BRACKETS}
total_xp = sum(zone_levels[z] * xp["per_level"][z] for z in BRACKETS)
print("balance_calc - the docs/22 frame, computed:")
for row in report_rows:
    print(row)
print(f"  XP: total to 30 = {total_xp}; kills/level = " + ", ".join(
    f"{z} {xp['per_level'][z] / xp['per_kill'][z]:.0f}" for z in BRACKETS))
print(f"  weapon budgets: " + ", ".join(f"T{t + 1} {budgets[t]:.1f}" for t in range(5)))

if findings:
    print(f"\nFAIL — {len(findings)} findings:")
    for f in findings:
        print(" -", f)
    sys.exit(1)
print("PASS — all five gates hold: the numbers exist before the code does")
