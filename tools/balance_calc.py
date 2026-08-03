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
     rule-breaks or a chassis outside 70-90% of tier budget (block 8);
  6. THE TACKLE FRAME (sl-0177/0178, the gear seam) - rods are starhooking
     weapons: >= 2 per tier across the four FAMILY norms (each family ONE
     pattern id, the pond's sword/staff/bow parallel; the .tres frames are
     parsed and pinned to their family's norm; the four proto originals
     exact-pinned; family DPS tier-monotone); tier_levels = the sl-0115
     unlock ladder verbatim; prices key EXISTING species, rare species T4
     shelves only, every species priced somewhere; chest hp steps + helm
     defense inside the rift obtainable band vs the parsed star-spray hit.
The ruled constants are HARD-CODED here as the design contract: a data file
drifting from docs/22's frame FAILS - mismatches flag loudly, and docs/22 is
never amended game-side. All damage math uses THE formula:
    taken = max(attack - armor, ceil(attack * 0.2))    (one rounding step)

    python tools/balance_calc.py [data/balance_frame.json]
"""

import json
import math
import os
import re
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

# ---- gate 6: THE TACKLE FRAME (sl-0177/0178 - the gear seam) ----
# Family norms [T]: pattern id + volley shape are THE family (sl-0169's
# law: norms here, deviation stays the uniques' job - unique rods FUTURE).
ROD_FAMILIES = {
    "line":   {"pattern": 7,  "shots": 1, "speed": 14.0, "ttl": 30, "radius": 0.125, "angles": [0.0],               "cadence": (28, 32)},
    "fan":    {"pattern": 8,  "shots": 3, "speed": 12.0, "ttl": 28, "radius": 0.11,  "angles": [-12.0, 0.0, 12.0],  "cadence": (34, 38)},
    "sinker": {"pattern": 9,  "shots": 1, "speed": 9.0,  "ttl": 80, "radius": 0.156, "angles": [0.0],               "cadence": (84, 92)},
    "twin":   {"pattern": 29, "shots": 2, "speed": 15.0, "ttl": 52, "radius": 0.125, "angles": [-3.0, 3.0],         "cadence": (26, 36)},
}
# The designer's proto rods ride verbatim [proto->T] - exact-pinned.
ROD_ORIGINALS = {
    "rod_cane": ([6], 30), "rod_splitwillow": ([4, 4, 4], 36),
    "rod_heavyline": ([16], 88), "rod_twinreed": ([3, 3], 28),
}
TIER_LEVELS = {1: 1, 2: 3, 3: 5, 4: 8}
RIFT_CHEST_STEP_BAND = (1.25, 1.35)
RIFT_HELM_PLATEAU = 0.7

data_dir = os.path.dirname(os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "data/balance_frame.json"))


def parse_rod_tres(rod_id: str):
    """Textual .tres parse: (pattern_id, cadence, [per-shot dicts])."""
    path = os.path.join(data_dir, "weapons", rod_id + ".tres")
    if not os.path.isfile(path):
        return None
    text = open(path, encoding="utf-8").read()
    shots = []
    for block in re.findall(r'\[sub_resource[^\]]*\]([^\[]*)', text):
        m = {k: float(v) for k, v in re.findall(r'(\w+) = (-?[\d.]+)', block)}
        if "damage" in m:
            shots.append(m)
    pat = re.search(r'^pattern_id = (\d+)', text, re.M)
    cad = re.search(r'^cadence_ticks = (\d+)', text, re.M)
    return (int(pat.group(1)) if pat else -1, int(cad.group(1)) if cad else -1, shots)


sh = d.get("starhook", {})
rods = sh.get("rods", [])
tackle = sh.get("tackle", {})
species_ids = set()
rare_ids = set()
for biome in sh.get("biomes", []):
    for fr in biome.get("fish", []):
        species_ids.add(fr["id"])
    rare_ids.add(biome.get("rare", {}).get("id", ""))
species_ids |= rare_ids

if {int(k): v for k, v in tackle.get("tier_levels", {}).items()} != TIER_LEVELS:
    fail(f"tackle tier_levels drifted from the sl-0115 unlock ladder {TIER_LEVELS}")

rod_report = []
per_tier: dict[int, int] = {}
family_dps: dict[str, dict[int, float]] = {}
priced_species: set[str] = set()
slot_price_totals: dict[str, dict[int, int]] = {}


def check_price(row_id: str, row: dict, slot_key: str, tier: int) -> None:
    price = row.get("price")
    if price is None:
        return
    total = 0
    for sp, n in price.items():
        if sp not in species_ids:
            fail(f"tackle {row_id}: price species '{sp}' not in the biome tables")
        if not (1 <= int(n) <= 9):
            fail(f"tackle {row_id}: price count {n} outside 1..9")
        if sp in rare_ids and tier < 4:
            fail(f"tackle {row_id}: rare species '{sp}' priced below the T4 shelf")
        priced_species.add(sp)
        total += int(n)
    slot_price_totals.setdefault(slot_key, {})
    prev = slot_price_totals[slot_key]
    for pt, pv in prev.items():
        if pt < tier and pv > total:
            fail(f"tackle {row_id}: T{tier} price total {total} under T{pt}'s {pv} (tier totals never shrink)")
        if pt > tier and pv < total:
            fail(f"tackle {row_id}: T{tier} price total {total} over T{pt}'s {pv} (tier totals never shrink)")
    prev[tier] = max(prev.get(tier, 0), total)


for rod in rods:
    rid = rod["id"]
    fam = rod.get("family", "")
    tier = int(rod.get("tier", 0))
    if fam not in ROD_FAMILIES:
        fail(f"rod {rid}: unknown family '{fam}'")
        continue
    if tier not in TIER_LEVELS:
        fail(f"rod {rid}: tier {tier} outside the ladder")
        continue
    if int(rod.get("unlock_level", -1)) != TIER_LEVELS[tier]:
        fail(f"rod {rid}: unlock_level {rod.get('unlock_level')} != tier {tier}'s level {TIER_LEVELS[tier]}")
    per_tier[tier] = per_tier.get(tier, 0) + 1
    norm = ROD_FAMILIES[fam]
    parsed = parse_rod_tres(rid)
    if parsed is None:
        fail(f"rod {rid}: data/weapons/{rid}.tres missing")
        continue
    pat, cad, shots = parsed
    if pat != norm["pattern"]:
        fail(f"rod {rid}: pattern {pat} != family '{fam}' norm {norm['pattern']} (families are norms)")
    if len(shots) != norm["shots"]:
        fail(f"rod {rid}: {len(shots)} shots != family norm {norm['shots']}")
    if not (norm["cadence"][0] <= cad <= norm["cadence"][1]):
        fail(f"rod {rid}: cadence {cad} outside family band {norm['cadence']}")
    angles = sorted(s.get("angle_offset_deg", 0.0) for s in shots)
    if angles != sorted(norm["angles"]):
        fail(f"rod {rid}: volley angles {angles} != family norm {sorted(norm['angles'])}")
    for s in shots:
        for key, want in (("speed", norm["speed"]), ("ttl_ticks", norm["ttl"]), ("radius", norm["radius"])):
            if abs(s.get(key, -1) - want) > 1e-6:
                fail(f"rod {rid}: shot {key} {s.get(key)} != family norm {want}")
    dmgs = [int(s["damage"]) for s in shots]
    if rid in ROD_ORIGINALS:
        want_dmg, want_cad = ROD_ORIGINALS[rid]
        if sorted(dmgs) != sorted(want_dmg) or cad != want_cad:
            fail(f"rod {rid}: proto original drifted (dmg {dmgs} cad {cad} vs pinned {want_dmg}/{want_cad})")
    dps = sum(dmgs) * 60.0 / cad if cad > 0 else 0.0
    family_dps.setdefault(fam, {})
    if tier in family_dps[fam]:
        fail(f"rod family {fam}: two rods at T{tier} (one identity per family per tier)")
    family_dps[fam][tier] = dps
    check_price(rid, rod, "rod_" + fam, tier)
    rod_report.append(f"  T{tier} {rid:16s} [{fam:6s}] {'+'.join(str(x) for x in dmgs):8s} dmg @ {60.0 / cad:.2f}/s = {dps:5.1f} dps" + ("  (free spine)" if rod.get("price") is None else ""))

for tier in TIER_LEVELS:
    if per_tier.get(tier, 0) < 2:
        fail(f"rod tier {tier}: only {per_tier.get(tier, 0)} rods (sl-0178: SEVERAL per level tier)")
for fam, by_tier in family_dps.items():
    ts = sorted(by_tier)
    for a, b in zip(ts, ts[1:]):
        if by_tier[b] <= by_tier[a]:
            fail(f"rod family {fam}: DPS not tier-monotone (T{a} {by_tier[a]:.1f} >= T{b} {by_tier[b]:.1f})")

# chest/helm rows: one append-only list, single-stat v1, banded.
titems = tackle.get("items", [])
seen_ids = set()
chest_hp = {}
helm_def = {}
for row in titems:
    tid = row["id"]
    if tid in seen_ids:
        fail(f"tackle items: duplicate id {tid}")
    seen_ids.add(tid)
    slot = row.get("slot", "")
    tier = int(row.get("tier", 0))
    if slot not in ("chest", "helm"):
        fail(f"tackle {tid}: unknown slot '{slot}'")
        continue
    if tier not in TIER_LEVELS:
        fail(f"tackle {tid}: tier {tier} outside the ladder")
        continue
    if slot == "chest":
        chest_hp[tier] = int(row.get("hp", 0))
        if int(row.get("defense", 0)) != 0:
            fail(f"tackle {tid}: chest carries defense (v1 rows are single-stat)")
    else:
        helm_def[tier] = int(row.get("defense", 0))
        if int(row.get("hp", 0)) != 0:
            fail(f"tackle {tid}: helm carries hp (v1 rows are single-stat)")
    if row.get("price") is None:
        fail(f"tackle {tid}: chest/helm rows are vendor rows - a price is required")
    check_price(tid, row, slot, tier)
for tier in TIER_LEVELS:
    if tier not in chest_hp or tier not in helm_def:
        fail(f"tackle: missing chest/helm row at T{tier}")
for a, b in zip(sorted(chest_hp), sorted(chest_hp)[1:]):
    if chest_hp[a] > 0:
        step = chest_hp[b] / chest_hp[a]
        if not (RIFT_CHEST_STEP_BAND[0] - 1e-9 <= step <= RIFT_CHEST_STEP_BAND[1] + 1e-9):
            fail(f"tackle chest hp step T{a}->T{b} = {step:.3f} outside {RIFT_CHEST_STEP_BAND}")
for a, b in zip(sorted(helm_def), sorted(helm_def)[1:]):
    if helm_def[b] <= helm_def[a]:
        fail(f"tackle helm defense not tier-monotone (T{a} {helm_def[a]} >= T{b} {helm_def[b]})")

# The rift reference hit is PARSED from the shipped star-spray pattern -
# retuning the catch's spray moves this gate with it, never silently.
spray = os.path.join(data_dir, "enemies", "patterns", "star_spray.tres")
spray_dmg = 0
if os.path.isfile(spray):
    hits = [int(x) for x in re.findall(r'^damage = (\d+)', open(spray, encoding="utf-8").read(), re.M)]
    spray_dmg = max(hits) if hits else 0
if spray_dmg <= 0:
    fail("tackle: star_spray.tres unreadable - no rift reference hit")
else:
    rare_drop = tackle.get("rare_drop", {})
    lo, hi = int(rare_drop.get("tier_min", 0)), int(rare_drop.get("tier_max", 0))
    if not (1 <= lo <= hi <= 4):
        fail(f"tackle rare_drop tier bounds [{lo},{hi}] outside the ladder")
    if not (1 <= int(rare_drop.get("chance_pct", 0)) <= 100):
        fail(f"tackle rare_drop chance {rare_drop.get('chance_pct')} outside 1..100")
    # Obtainable-at-grade helm defense vs the reference hit (armor_rules
    # band, block-2 rider applied rift-side at the DROP-gated tiers).
    for tier in range(lo, hi + 1):
        ratio = helm_def.get(tier, 0) / spray_dmg
        if not (ARMOR_BAND[0] - 1e-9 <= ratio <= ARMOR_BAND[1] + 1e-9):
            fail(f"tackle helm T{tier}: {helm_def.get(tier, 0)} = {ratio:.2f}x the {spray_dmg} rift hit (band 0.4-0.6)")
    if helm_def and max(helm_def.values()) / spray_dmg > RIFT_HELM_PLATEAU + 1e-9:
        fail(f"tackle helm plateau: max {max(helm_def.values())} > {RIFT_HELM_PLATEAU}x the {spray_dmg} rift hit")

unpriced = species_ids - priced_species - {""}
if unpriced:
    fail(f"tackle: species never priced anywhere: {sorted(unpriced)} (every fish matters)")
for n in [v for r in titems for v in (int(r.get("hp", 0)), int(r.get("defense", 0)))]:
    if n > MAX_NUMBER:
        fail(f"tackle number {n} exceeds 3 digits")

# ---- gate 7: THE RIFT BOSS POOL (sl-0180 - fight length + pool coverage) ----
# Fight length [T]: each boss's hp against the GRADE's free-spine rod
# DPS (the guaranteed-available identity, derived from the parsed rod
# frames above - retuning a rod moves this gate with it) must land in
# the designer's 1-5 minute band. Pools: per-biome common/rare lists,
# catch present everywhere, every id resolving, every boss pooled,
# scenario + proof files on disk. The strain clock is REPORTED per
# fight (info - the designer's lever), never gated.
FIGHT_LEN_BAND = (60.0, 300.0)
spine_dps: dict[int, float] = {}
for rod in rods:
    if rod.get("price") is None and int(rod.get("tier", 0)) in TIER_LEVELS:
        parsed = parse_rod_tres(rod["id"])
        if parsed is not None:
            _, cad, shots = parsed
            if cad > 0:
                spine_dps[int(rod["tier"])] = sum(int(s["damage"]) for s in shots) * 60.0 / cad

bosses = sh.get("bosses", [])
boss_ids = set()
boss_report = []
drain_rate = 0.4
line_path = os.path.join(data_dir, "rift_line.tres")
if os.path.isfile(line_path):
    m = re.search(r"^passive_drain_per_sec = ([\d.]+)", open(line_path, encoding="utf-8").read(), re.M)
    if m:
        drain_rate = float(m.group(1))
for boss in bosses:
    bid = str(boss.get("id", ""))
    grade = int(boss.get("grade", 0))
    boss_ids.add(bid)
    if grade not in TIER_LEVELS:
        fail(f"rift boss {bid}: grade {grade} outside the tier ladder")
        continue
    def_path = os.path.join(data_dir, "enemies", f"rift_boss_{bid}.tres")
    if not os.path.isfile(def_path):
        fail(f"rift boss {bid}: def missing at data/enemies/rift_boss_{bid}.tres")
        continue
    mhp = re.search(r"^hp = (\d+)", open(def_path, encoding="utf-8").read(), re.M)
    if mhp is None:
        fail(f"rift boss {bid}: def carries no hp row")
        continue
    hp_v = int(mhp.group(1))
    dps = spine_dps.get(grade, 0.0)
    if dps <= 0:
        fail(f"rift boss {bid}: no spine rod DPS at grade {grade}")
        continue
    flen = hp_v / dps
    if not (FIGHT_LEN_BAND[0] <= flen <= FIGHT_LEN_BAND[1]):
        fail(f"rift boss {bid}: fight length {flen:.0f}s at grade-{grade} spine DPS {dps:.1f} outside [60, 300]")
    # Scenario/proof presence anchors to the REPO tree (the script's
    # own parent), not the data dir — scratch-copied frames validate
    # against the real scenario files.
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    for fpath, kind in ((os.path.join(repo_root, "data", "scenarios", f"rift_boss_{bid}.tres"), "scenario"),
                       (os.path.join(repo_root, "tests", "bot_scenarios", f"proof_boss_{bid}.tres"), "proof")):
        if not os.path.isfile(fpath):
            fail(f"rift boss {bid}: {kind} file missing")
    boss_report.append(f"  g{grade} rift_boss_{bid:20s} {hp_v:5d} hp / {dps:4.1f} dps = {flen:5.0f}s  (clock eats ~{flen * drain_rate:3.0f} stability)")

pools = sh.get("fight_pool", {})
pooled_ids: set[str] = set()
for bkey in ("nebula", "void", "comet"):
    bp = pools.get(bkey)
    if not isinstance(bp, dict):
        fail(f"fight_pool: biome '{bkey}' missing")
        continue
    for rk in ("common", "rare"):
        pool = bp.get(rk, [])
        if not pool:
            fail(f"fight_pool {bkey}.{rk}: empty")
            continue
        fids = [str(r.get("fight", "")) for r in pool]
        if "catch" not in fids:
            fail(f"fight_pool {bkey}.{rk}: the standard catch is missing")
        for r in pool:
            fid = str(r.get("fight", ""))
            if int(r.get("w", 0)) < 1:
                fail(f"fight_pool {bkey}.{rk}: '{fid}' weight {r.get('w')} < 1")
            if fid != "catch":
                if fid not in boss_ids:
                    fail(f"fight_pool {bkey}.{rk}: unknown fight id '{fid}'")
                pooled_ids.add(fid)
unpooled = boss_ids - pooled_ids
if bosses and unpooled:
    fail(f"rift bosses never pooled: {sorted(unpooled)}")

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
print("  the tackle catalog (gate 6):")
for row in sorted(rod_report):
    print(row)
print("  rift chest hp: " + ", ".join(f"T{t} +{chest_hp[t]}" for t in sorted(chest_hp))
      + "; helm def: " + ", ".join(f"T{t} +{helm_def[t]}" for t in sorted(helm_def))
      + f" (vs the {spray_dmg} rift hit)")
print("  the rift boss pool (gate 7; strain clock %.1f/s reported, never gated):" % drain_rate)
for row in boss_report:
    print(row)

if findings:
    print(f"\nFAIL — {len(findings)} findings:")
    for f in findings:
        print(" -", f)
    sys.exit(1)
print("PASS — all seven gates hold: the numbers exist before the code does")
