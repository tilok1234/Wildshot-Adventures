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
