extends RefCounted
class_name FindPath

# Grid pathfinding for nightmares on the HALF-CELL grid (documentation/half_cells.md).
# The map's 64 px cells are split into 32 px half cells (46×36 on the 23×18 map); anything that blocks
# (border, obstacles, Wardens) blocks half cells. A nightmare fits through one half cell (half_cells.md 04c10c33:
# a gap one half wide is enough), so each free half cell is a node. Route points are the half's centre in
# FULL-cell units ((h - 0.5) / 2: x.25 or x.75; Grid puts point p at p * 64 + 32 px), so
# Grid.calculate_map_position(point) is the half's centre pixel, the place to walk to.
# A whole cell given as an end (the start, the Heartwood) means its nearest half. Movement is up/down/left/right.

const HALF := 2  # Half cells per full cell, per axis

var _grid: Grid
var _size: Vector2i  # Half cells
var _blocked: PackedByteArray  # 1 per blocked half cell
var _astar := AStarGrid2D.new()  # One node per half cell

# Stepping off the preferred route costs this much extra per node. It's tiny (the total over the longest
# possible route stays under 1 step), so paths are still always shortest; it only breaks ties between
# equally short routes in favour of the one that reuses the most of the old route.
var _off_route_weight: float
var version := 0  # Bumped on every blocking change (PathGenerator.route_tail checks its route is current)
var _preferred_nodes: Array[Vector2i] = []


# Builds the grid. Only `walkable_cells` (full cells) start out open; everything else is blocked.
func _init(grid: Grid, walkable_cells: Array) -> void:
	_grid = grid
	_size = Vector2i(grid.size) * HALF
	_blocked = PackedByteArray()
	_blocked.resize(_size.x * _size.y)
	_blocked.fill(1)
	_astar.region = Rect2i(Vector2i.ZERO, _size)
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
			_astar.set_point_solid(Vector2i(x, y), _blocked[y * _size.x + x] == 1)
	_off_route_weight = 1.0 + 1.0 / (_astar.region.size.x * _astar.region.size.y + 1.0)
	_astar.fill_weight_scale_region(_astar.region, _off_route_weight)

# --- Coordinates -----------------------------------------------------------------------------------

# The 4 half cells of a 64 px footprint whose top-left half cell is `origin`.
static func halves_of(origin: Vector2) -> Array[Vector2]:
	var o := Vector2(roundf(origin.x), roundf(origin.y))
	var halves: Array[Vector2] = [o, o + Vector2(1, 0), o + Vector2(0, 1), o + Vector2(1, 1)]
	return halves

# A whole cell's 4 half cells (a 2×2 footprint at a whole cell).
static func halves_of_cell(cell: Vector2) -> Array[Vector2]:
	return halves_of((cell * HALF).floor())

# Route point (a half's centre, full-cell units: x.25 / x.75) <-> half cell. A whole cell (x.0) maps to its
# top-left half.
static func point_to_node(point: Vector2) -> Vector2i:
	if is_whole_cell(point):
		return Vector2i(point * HALF)
	return Vector2i(roundi(point.x * HALF + 0.5), roundi(point.y * HALF + 0.5))

static func node_to_point(node: Vector2i) -> Vector2:
	return (Vector2(node) - Vector2(0.5, 0.5)) / HALF

# True for a whole-cell coordinate (the start, the Heartwood), not a route point.
static func is_whole_cell(point: Vector2) -> bool:
	return point == point.floor()

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
	version += 1
	_astar.set_point_solid(i, blocked)

# Marks a whole cell blocked or open: its 4 half cells.
func set_blocked(cell: Vector2, blocked: bool) -> void:
	for h in halves_of_cell(cell):
		set_half_blocked(h, blocked)

# --- Paths -----------------------------------------------------------------------------------------------

# Makes future paths stick to `points` (the current route) when there's a tie.
func set_preferred_cells(points: PackedVector2Array) -> void:
	_preferred_version += 1
	for node in _preferred_nodes:
		if _astar.is_in_boundsv(node):
			_astar.set_point_weight_scale(node, _off_route_weight)
	_preferred_nodes.clear()
	for point in points:
		var node := point_to_node(point)
		if _astar.is_in_boundsv(node):
			_astar.set_point_weight_scale(node, 1.0)
			_preferred_nodes.append(node)

# The route between `start` and `end` (route points, full-cell units; start and end included), or empty. A
# whole cell at either end means its half nearest the other end.
func calculate_point_path(start: Vector2, end: Vector2) -> PackedVector2Array:
	var a := point_to_node(start)
	var b := point_to_node(end)
	if is_whole_cell(end):
		b = _nearest_half(end, Vector2(a) if not is_whole_cell(start) else start * HALF + Vector2.ONE * 0.5)
	if is_whole_cell(start):
		a = _nearest_half(start, Vector2(b))
	if not _walkable_node(a) or not _walkable_node(b):
		return PackedVector2Array()
	var nodes := _astar.get_id_path(a, b)
	var points := PackedVector2Array()
	points.resize(nodes.size())
	for i in nodes.size():
		points[i] = node_to_point(nodes[i])
	return points

# A shortest route (as calculate_point_path), balancing two things: it keeps to the preferred route (the one drawn
# now), and it turns as little as it can (a turn costs as much as two halves off the old route). The drawn route
# uses it: corridors are two or more halves wide, and a plain A* route jogs between their lanes one half at a time,
# which draws as a broad smeared band with the walkers on its edge; and a lane rarely changes unless the old one is
# blocked or longer.
func straightest_point_path(start: Vector2, end: Vector2) -> PackedVector2Array:
	# Cached by what it depends on (the blocked halves, the ends, the preferred route): the build ghost's
	# preview already searched the grid the placement makes, so draw() right after reuses it.
	var key := [hash(_blocked), start, end, _preferred_version]
	if key == _straight_key:
		return _straight_route.duplicate()
	var route := _straightest_search(start, end)
	_straight_key = key
	_straight_route = route.duplicate()
	return route

var _straight_key: Array = []
var _straight_route := PackedVector2Array()
var _preferred_version := 0  # Bumped by set_preferred_cells (part of the straightest cache key)

func _straightest_search(start: Vector2, end: Vector2) -> PackedVector2Array:
	var a := point_to_node(start)
	var b := point_to_node(end)
	if is_whole_cell(end):
		b = _nearest_half(end, Vector2(a) if not is_whole_cell(start) else start * HALF + Vector2.ONE * 0.5)
	if is_whole_cell(start):
		a = _nearest_half(start, Vector2(b))
	if not _walkable_node(a) or not _walkable_node(b):
		return PackedVector2Array()
	if a == b:
		return PackedVector2Array([node_to_point(a)])
	var count := _size.x * _size.y
	var ia := a.y * _size.x + a.x
	var ib := b.y * _size.x + b.x
	# Breadth-first distances from `a`, in visiting order (each layer complete before the next)
	var dist := PackedInt32Array()
	dist.resize(count)
	dist.fill(-1)
	dist[ia] = 0
	var order := PackedInt32Array([ia])
	var steps: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	var head := 0
	while head < order.size():
		var i := order[head]
		head += 1
		if dist[ib] != -1 and dist[i] >= dist[ib]:
			break
		var node := Vector2i(i % _size.x, i / _size.x)
		for step in steps:
			var to := node + step
			if not _walkable_node(to):
				continue
			var j := to.y * _size.x + to.x
			if dist[j] == -1:
				dist[j] = dist[i] + 1
				order.append(j)
	if dist[ib] == -1:
		return PackedVector2Array()
	var preferred := PackedByteArray()
	preferred.resize(count)
	for n in _preferred_nodes:
		if _astar.is_in_boundsv(n):
			preferred[n.y * _size.x + n.x] = 1
	# cost[node * 4 + heading] = nodes off the preferred route * OFF + turns * TURN; from[...] = the key before. Staying
	# on the current route weighs heavily (Balancing 2026-10-05: a placement flipped a wide corridor to another lane, away
	# from the Wardens built for it); turns still keep new stretches straight.
	const OFF := 1  # A node off the current route; a turn costs TURN of them
	const TURN := 2  # Measured: higher lets a placement flip the lane, a strict order (turns last) leaves jogs
	var cost := PackedInt32Array()
	cost.resize(count * 4)
	cost.fill(-1)
	var from := PackedInt32Array()
	from.resize(count * 4)
	from.fill(-1)
	for h in 4:
		cost[ia * 4 + h] = 0
	for k in range(1, order.size()):
		var i := order[k]
		if dist[i] > dist[ib]:
			break
		var node := Vector2i(i % _size.x, i / _size.x)
		var off := 0 if preferred[i] == 1 else OFF
		for h in 4:
			var back := node - steps[h]
			if back.x < 0 or back.y < 0 or back.x >= _size.x or back.y >= _size.y:
				continue
			var p := back.y * _size.x + back.x
			if dist[p] != dist[i] - 1:
				continue
			for before in 4:
				var c := cost[p * 4 + before]
				if c < 0:
					continue
				c += off + (TURN if before != h and p != ia else 0)
				if cost[i * 4 + h] < 0 or c < cost[i * 4 + h]:
					cost[i * 4 + h] = c
					from[i * 4 + h] = p * 4 + before
	var key := -1
	for h in 4:
		var c := cost[ib * 4 + h]
		if c >= 0 and (key == -1 or c < cost[key]):
			key = ib * 4 + h
	var nodes: Array[Vector2i] = []
	while key != -1:
		var i := key / 4
		nodes.append(Vector2i(i % _size.x, i / _size.x))
		key = -1 if i == ia else from[key]
	nodes.reverse()
	var points := PackedVector2Array()
	points.resize(nodes.size())
	for i in nodes.size():
		points[i] = node_to_point(nodes[i])
	return points

# True if calculate_point_path(point, end) would find a route: one flood fill from the end per grid version,
# then a lookup per point (the path rule asks this for every walking nightmare, ~150, after every change).
func reaches(point: Vector2, end: Vector2) -> bool:
	var key := [version, end]
	if key != _reach_key:
		_reach_key = key
		_flood_from(end)
	if is_whole_cell(point):  # A whole cell (the start): any free half of it (they're side by side)
		for h in halves_of_cell(point):
			var n := Vector2i(h)
			if _walkable_node(n) and _dist[n.y * _size.x + n.x] >= 0:
				return true
		return false
	var node := point_to_node(point)
	return _walkable_node(node) and _dist[node.y * _size.x + node.x] >= 0

var _reach_key: Array = []
var _dist := PackedInt32Array()  # Steps from each half cell to the end (-1: no way there)

# From route point `point` towards `end`, one shortest step at a time (down the distance field), until it
# stands on a half marked in `stop` (1 per half: a route the caller knows) or at the end: the points walked,
# `point` first. Empty if there's no way. Ties keep going straight. Much cheaper than a search per nightmare.
func descend(point: Vector2, end: Vector2, stop: PackedByteArray) -> PackedVector2Array:
	if is_whole_cell(point) or not reaches(point, end):
		return PackedVector2Array()
	var node := point_to_node(point)
	var i := node.y * _size.x + node.x
	var points := PackedVector2Array([point])
	var w := _size.x
	var offsets := PackedInt32Array([-w, 1, w, -1])  # Up, right, down, left
	var heading := -1
	while _dist[i] > 0:
		if points.size() > 1 and stop[i] == 1:
			return points
		var want := _dist[i] - 1
		var x := i % w
		var next := -1
		for k in 5:
			var dir := heading if k == 0 else k - 1
			if dir < 0 or (k > 0 and dir == heading):
				continue
			if (dir == 1 and x == w - 1) or (dir == 3 and x == 0):
				continue
			var j := i + offsets[dir]
			if j >= 0 and j < _dist.size() and _dist[j] == want:
				next = j
				heading = dir
				break
		i = next
		points.append(node_to_point(Vector2i(i % w, i / w)))
	return points

func _flood_from(end: Vector2) -> void:
	_dist.resize(_size.x * _size.y)
	_dist.fill(-1)
	var queue := PackedInt32Array()
	var seeds: Array[Vector2] = halves_of_cell(end) if is_whole_cell(end) else [Vector2(point_to_node(end))]
	for h in seeds:
		var n := Vector2i(h)
		if _walkable_node(n) and _dist[n.y * _size.x + n.x] < 0:
			_dist[n.y * _size.x + n.x] = 0
			queue.append(n.y * _size.x + n.x)
	var head := 0
	while head < queue.size():
		var i := queue[head]
		head += 1
		var x := i % _size.x
		var next := _dist[i] + 1
		if x > 0 and _dist[i - 1] < 0 and _blocked[i - 1] == 0:
			_dist[i - 1] = next
			queue.append(i - 1)
		if x < _size.x - 1 and _dist[i + 1] < 0 and _blocked[i + 1] == 0:
			_dist[i + 1] = next
			queue.append(i + 1)
		if i >= _size.x and _dist[i - _size.x] < 0 and _blocked[i - _size.x] == 0:
			_dist[i - _size.x] = next
			queue.append(i - _size.x)
		if i + _size.x < _dist.size() and _dist[i + _size.x] < 0 and _blocked[i + _size.x] == 0:
			_dist[i + _size.x] = next
			queue.append(i + _size.x)

# A nightmare fits at `point` (a route point; a whole cell: its top-left half).
func is_walkable(point: Vector2) -> bool:
	return _walkable_node(point_to_node(point))

func _walkable_node(node: Vector2i) -> bool:
	return _astar.is_in_boundsv(node) and not _astar.is_point_solid(node)

# The free half of whole cell `cell` nearest `toward` (half-cell units), else its top-left half.
func _nearest_half(cell: Vector2, toward: Vector2) -> Vector2i:
	var best := point_to_node(cell)
	var best_d := INF
	for h in halves_of_cell(cell):
		var d: float = absf(h.x - toward.x) + absf(h.y - toward.y)
		if d < best_d and _walkable_node(Vector2i(h)):
			best_d = d
			best = Vector2i(h)
	return best
