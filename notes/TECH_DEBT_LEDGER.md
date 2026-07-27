# Tech Debt Ledger (TECH-20)

Opened at M0 per planning `docs/12-PHASE_A_LAB_BUILD_PLAN.md` §4. Every
deliberate shortcut gets a named entry here in the same commit that introduces
or confirms it. The formal TECH-20 read-out happens after the combat
prototype. The scope tripwire (CLAUDE.md) also ledgers refused out-of-scope
work here.

| # | Entry | Where (lands at) | Exit condition |
|---|---|---|---|
| 1 | Hard-coded ability effects — the three test abilities are bespoke code, no item/skill composition system (TECH-06 deferred) | `sim/` (M4) | Phase C item-system design |
| 2 | Quickdraw is a hard-coded cadence multiplier — no stat pipeline exists (TECH-08 deferred) | `sim/` (M4) | TECH-08 stat-pipeline decision |
| 3 | Fixed class-shell stats — flat values in data, no growth curves | `data/` (M2) | Phase C build grammar |
| 4 | Arena-only spawning — scenario spawner assumes the one greybox arena | `sim/` (M2+) | Phase B+ encounter authoring |
| 5 | Placeholder EffectLibrary entries until the effects pack lands (M-FX; pack-or-placeholder call pre-registered for end of M5) | `game/` (M3+) | Effects-pack acceptance — 9-row checklist (M6) |
| 6 | Brute-force actor collision and projectile-vs-actor circle tests — spatial hash deferred, upgrade path documented | `sim/collision/` (M2) | M2 600-projectile stress-scene verdict |
| 7 | PNG-sequence GIF path (F9 ring buffer → PNG → ffmpeg) — no in-engine encoder | `tools/gif.ps1` (M3) | Only if the weekly GIF cadence makes it painful |
