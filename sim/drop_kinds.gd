extends RefCounted
## Ground-drop kind ids (Loop v1, docs/19) — a leaf constant module so
## SimWorld (spawn/serialize), the death-sweep rolls, and LootStep can
## all name kinds without preload cycles (SimWorld preloads LootStep, so
## LootStep cannot preload SimWorld back; match patterns need class
## constants, never instance members).

const GOLD := 0
const WEAPON := 1
const ARMOR := 2
const ABILITY := 3
const UNIQUE := 4
## S1 seam 2 (sl-0104): ring drops — `a` = the balance_frame items[]
## index (block-7 one-pair trade; the pure situational slot).
const RING := 5
## sl-0198 THE FORAGING BUILD: forage materials — `a` = the species
## index (SimWorld.forage_species_ids order), `b` = the kin count.
## Rides loot bags like any kind, but pickup lands in the per-species
## WALLET (PlayerState.forage_mats — the starhook_fish doctrine):
## ZERO bag capacity consumed, one profile truth.
const FORAGE := 6
