extends RefCounted
class_name FindPath

# Grid pathfinding for nightmares on the HALF-CELL grid (experiment/half-cells, documentation/half_cells.md).
# The map's 64 px cells are split into 32 px half cells (46×36 on the 23×18 map); anything that blocks
# (border, obstacles, Wardens) blocks half cells. A nightmare is a 2×2-half-cell body (one full cell wide),
# so the pathing node is the body's top-left half cell: walkable only if all 4 half cells under it are
# free. That is the corridor rule: a gap one half cell wide never fits a body, so routes never use one.
# Route points are the body's centre in FULL-cell units (node / 2: x.0 or x.5), so
# Grid.calculate_map_position(point) is the pixel to walk to, as before. Movement is up/down/left/right.

const HALF := 2  # Half cells per full cell, per axis

var _grid: Grid
var _size: Vector2i  # Half cells
var _blocked: PackedByteArray  # 1 per blocked half cell
var _astar := AStarGrid2D.new()  # Body nodes (top-left half cell), (_size - 1) per axis

# Stepping off the preferred route costs this much extra per node. It's tiny (the total over the longest
# possible route stays under 1 step), so paths are still always shortest; it only breaks ties between
# equally short routes in favour of the one that reuses the most of the old route.
var _off_route_weight: float
var _preferred_nodes: Array[Vector2i] = []


# Builds the grid. Only `walkable_cells` (full cells) start out open; everything else is blocked.
func _init(grid: Grid, walkable_cells: Array) -> void:
	_grid = grid
	_size = Vector2i(grid.size) * HALF
	_blocked = PackedByteArray()
	_blocked.resize(_size.x * _size.y)
	_blocked.fill(1)
	_astar.region = Rect2i(Vector2i.ZERO, _size - Vector2i.ONE)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.update()
	_astar.fill_solid_region(_astar.region, true)
	for cell in walkable_cells:
		for h in halves_of_cell(cell):
			_blocked[int(h.y) * _size.x + int(h.x)] = 0
	for y in _astar.region.size.y:
		for x in _astar.region.size.x:
			_astar.set_point_solid(Vector2i(x, y), not _node_free(Vector2i(x, y)))
	_off_route_weight = 1.0 + 1.0 / (_astar.region.size.x * _astar.region.size.y + 1.0)
	_astar.fill_weight_scale_region(_astar.region, _off_route_weight)

# --- Coordinates -----------------------------------------------------------------------------------

# The 4 half cells of a 64 px footprint whose top-left half cell is `origin`.
static func halves_of(origin: Vector2) -> Array[Vector2]:
	var o := Vector2(roundf(origin.x), roundf(origin.y))
	var halves: Array[Vector2] = [o, o + Vector2(1, 0), o + Vector2(0, 1), o + Vector2(1, 1)]
	return halves

# A full cell's (or a route point's: x.5 allowed) 4 half cells.
static func halves_of_cell(cell: Vector2) -> Array[Vector2]:
	return halves_of(cell * HALF)

# Route point (body centre, full-cell units) <-> body node (top-left half cell).
static func point_to_node(point: Vector2) -> Vector2i:
	return Vector2i(roundi(point.x * HALF), roundi(point.y * HALF))

static func node_to_point(node: Vector2i) -> Vector2:
	return Vector2(node) / HALF

func size() -> Vector2i:
	return _size

# --- Blocking ------------------------------------------------------------------------------------------

func is_half_blocked(h: Vector2) -> bool:
	var i := Vector2i(h)
	return i.x < 0 or i.y < 0 or i.x >= _size.x or i.y >= _size.y or _blocked[i.y * _size.x + i.x] == 1

func set_half_blocked(h: Vector2, blocked: bool) -> void:
	var i := Vector2i(h)
	if i.x < 0 or i.y < 0 or i.x >= _size.x or i.y >= _size.y:
		return
	var value := 1 if blocked else 0
	if _blocked[i.y * _size.x + i.x] == value:
		return
	_blocked[i.y * _size.x + i.x] = value
	for dy in range(-1, 1):  # The 4 body nodes that cover this half cell
		for dx in range(-1, 1):
			var node := i + Vector2i(dx, dy)
			if _astar.is_in_boundsv(node):
				_astar.set_point_solid(node, not _node_free(node))

# Marks a full cell (or a 2×2 footprint at a route point / x.5 cell) blocked or open: its 4 half cells.
func set_blocked(cell: Vector2, blocked: bool) -> void:
	for h in halves_of_cell(cell):
		set_half_blocked(h, blocked)

func _node_free(node: Vector2i) -> bool:
	for dy in 2:
		for dx in 2:
			var h := node + Vector2i(dx, dy)
			if h.x >= _size.x or h.y >= _size.y or _blocked[h.y * _size.x + h.x] == 1:
				return false
	return true

# --- Paths -----------------------------------------------------------------------------------------------

# Makes future paths stick to `points` (the current route) when there's a tie.
func set_preferred_cells(points: PackedVector2Array) -> void:
	for node in _preferred_nodes:
		if _astar.is_in_boundsv(node):
			_astar.set_point_weight_scale(node, _off_route_weight)
	_preferred_nodes.clear()
	for point in points:
		var node := point_to_node(point)
		if _astar.is_in_boundsv(node):
			_astar.set_point_weight_scale(node, 1.0)
			_preferred_nodes.append(node)

# The route between `start` and `end` (route points, full-cell units; start and end included), or empty.
func calculate_point_path(start: Vector2, end: Vector2) -> PackedVector2Array:
	var a := point_to_node(start)
	var b := point_to_node(end)
	if not _walkable_node(a) or not _walkable_node(b):
		return PackedVector2Array()
	var nodes := _astar.get_id_path(a, b)
	var points := PackedVector2Array()
	points.resize(nodes.size())
	for i in nodes.size():
		points[i] = node_to_point(nodes[i])
	return points

# A body fits at `point` (route point / full cell).
func is_walkable(point: Vector2) -> bool:
	return _walkable_node(point_to_node(point))

func _walkable_node(node: Vector2i) -> bool:
	return _astar.is_in_boundsv(node) and not _astar.is_point_solid(node)

# Whether `start` reaches `end` for a single half cell (no body width): tells "too narrow" from "closed".
func connects_thin(start: Vector2, end: Vector2) -> bool:
	var a := point_to_node(start)
	var goals := {}
	for h in halves_of_cell(end):
		goals[Vector2i(h)] = true
	var seen := {a: true}
	var queue: Array[Vector2i] = [a]
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		if goals.has(at):
			return true
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := at + step
			if seen.has(next) or (is_half_blocked(Vector2(next)) and not goals.has(next)):
				continue
			seen[next] = true
			queue.append(next)
	return false
