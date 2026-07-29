## Build identity stamp (§2.10). The committed value marks editor /
## working-tree runs; tools/export.ps1 rewrites BUILD_ID with
## `git describe --always --dirty` for the duration of an export and
## restores this default afterward, so exported artifacts self-identify
## (tester HUD shows it) and the repo stays clean.
const BUILD_ID := "dev-workingtree"
