extends RefCounted
## Solid-tile bitgrid — the sim-side collision view of the arena (docs/12 §2.3).
## Baked from the same arena definition that places the wall/prop tiles, so
## collision matches visible geometry by construction. Out-of-bounds is solid.

var width: int = 0
var height: int = 0
var _cells: PackedByteArray = PackedByteArray()


func setup(w: int, h: int) -> void:
	width = w
	height = h
	_cells.resize(w * h)
	_cells.fill(0)


func set_solid(x: int, y: int) -> void:
	if x >= 0 and x < width and y >= 0 and y < height:
		_cells[y * width + x] = 1


func is_solid(x: int, y: int) -> bool:
	if x < 0 or x >= width or y < 0 or y >= height:
		return true
	return _cells[y * width + x] == 1


## sl-0078 fit rule: the walk grid is a clone of the conservative grid
## with art-matched prop cells opened (their blocking moves to sub-cell
## discs). Clone + open keep this class the one collision store.
func set_open(x: int, y: int) -> void:
	if x >= 0 and x < width and y >= 0 and y < height:
		_cells[y * width + x] = 0


func clone() -> RefCounted:
	var g: RefCounted = get_script().new()
	g.width = width
	g.height = height
	g._cells = _cells.duplicate()
	return g


func solid_count() -> int:
	var n := 0
	for c in _cells:
		n += c
	return n
