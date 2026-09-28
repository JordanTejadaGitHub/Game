extends RefCounted
class_name FindPath

# Grid pathfinding for enemies, backed by Godot's AStarGrid2D. Every cell of the map is a point on
# the grid; cells enemies can't walk through (border, trees, towers) are marked "solid".
# Movement is limited to up, down, left and right.

var _grid: Grid
var _astar := AStarGrid2D.new()

# Stepping off the preferred route costs this much extra per cell. It's tiny (the total over the
# longest possible route stays under 1 step), so paths are still always shortest; it only breaks
# ties between equally short routes in favour of the one that reuses the most of the old route.
# Without it, blocking one cell on open ground can make the route jump to a far-away equal-length one.
var _off_route_weight: float
var _preferred_cells := PackedVector2Array()


# Builds the pathfinding grid. Only `walkable_cells` start out open; everything else is solid.
func _init(grid: Grid, walkable_cells: Array) -> void:
	_grid = grid
	_astar.region = Rect2i(Vector2i.ZERO, Vector2i(grid.size))
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.update()
	_astar.fill_solid_region(_astar.region, true)
	for cell in walkable_cells:
		_astar.set_point_solid(Vector2i(cell), false)
	_off_route_weight = 1.0 + 1.0 / (grid.size.x * grid.size.y + 1.0)
	_astar.fill_weight_scale_region(_astar.region, _off_route_weight)


# Makes future paths stick to `cells` (the current route) when there's a tie.
func set_preferred_cells(cells: PackedVector2Array) -> void:
	for cell in _preferred_cells:
		_astar.set_point_weight_scale(Vector2i(cell), _off_route_weight)
	_preferred_cells = cells.duplicate()
	for cell in _preferred_cells:
		_astar.set_point_weight_scale(Vector2i(cell), 1.0)


# Returns the path found between `start` and `end` as an array of cell coordinates (start and end
# included), or an empty array if there is no path.
func calculate_point_path(start: Vector2, end: Vector2) -> PackedVector2Array:
	if not is_walkable(start) or not is_walkable(end):
		return PackedVector2Array()
	# With the default cell_size of (1, 1), point positions are the cell coordinates themselves.
	return _astar.get_point_path(Vector2i(start), Vector2i(end))


func is_walkable(cell: Vector2) -> bool:
	return _astar.is_in_boundsv(Vector2i(cell)) and not _astar.is_point_solid(Vector2i(cell))


# Marks a cell as blocked (e.g. a tower was built on it) or open again.
func set_blocked(cell: Vector2, blocked: bool) -> void:
	if _astar.is_in_boundsv(Vector2i(cell)):
		_astar.set_point_solid(Vector2i(cell), blocked)
