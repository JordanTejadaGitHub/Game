# Draws the unit's movement path using an autotile.
class_name PathGenerator
extends TileMapLayer

@onready var board = %MapGenerator
@onready var tileMap: TileMapLayer = %PathTileMapLayer

const grid = preload("res://resource/map/map_grid.tres")

# This variable holds a reference to a PathFinder object. We'll create a new one every time the 
# player select a unit.
var _pathGenerator: FindPath
# This property caches a path found by the _pathGenerator above.
# We cache the path so we can reuse it from the game board. If the player decides to confirm unit
# movement with the cursor, we can pass the path to the unit's walk_along() function.
var current_path := PackedVector2Array()
var temp_current_path := PackedVector2Array()
var current_path_curve: Curve2D = Curve2D.new()
var cell_start_path : Vector2
var cell_end_path : Vector2
var path: Path2D
var path_drawn: Line2D = Line2D.new()
@export var mouse: Node2D


# Creates a new PathFinder that uses the AStar algorithm we use to find a path between two cells 
# among the `walkable_cells`.
# We'll call this function every time the player selects a unit.
func initialize(walkable_cells: Array, cell_start: Vector2, cell_end: Vector2) -> void:
	_pathGenerator = FindPath.new(grid, walkable_cells)
	current_path = _pathGenerator.calculate_point_path(cell_start, cell_end)
	cell_start_path = cell_start
	cell_end_path = cell_end
# Finds and draws the path between `cell_start` and `cell_end`.

func initialize_new_path(walkable_cells: Array) -> void:
	_pathGenerator = FindPath.new(grid, walkable_cells)

func draw():
	# We first clear any tiles on the tilemap, then let the Astar2D (PathFinder) find the
	# path for us.
	clear()
	current_path.clear()
	current_path_curve.clear_points()
	current_path = _pathGenerator.straightest_point_path(cell_start_path, cell_end_path)  # No lane-to-lane jogs
	# Later re-routes (towers, cleared obstacles, enemies mid-walk) stick to this route when they can.
	_pathGenerator.set_preferred_cells(current_path)
	_route_version = _pathGenerator.version
	if current_path.is_empty() and board != null:  # Never expected (every block keeps a way through): leave a trace
		push_error("PathGenerator.draw: no route from %s to %s" % [cell_start_path, cell_end_path])
	_route_index.clear()
	for i in current_path.size():
		_route_index[current_path[i]] = i
	# Half cells (documentation/half_cells.md): route points step by half a cell, so the path is drawn on the
	# dual grid (path_dual.png, _draw_dual), not one tile per cell. The start still runs off the rim onto the bridge.
	for cell in current_path:
		if board != null:  # The path wore the debris away on the whole cell of this point's half
			board.environment_object_layer.wear_away(FindPath.point_to_node(cell) / 2)
		current_path_curve.add_point(grid.calculate_map_position(cell))
	if not current_path.is_empty():
		set_cell(cell_start_path, EnvironmentTiles.PATH_RIM, EnvironmentTiles.path_tile(_edge_mask(cell_start_path)))
	_draw_dual()

# The neighbour bit pointing off the map from an edge cell (N=1, E=2, S=4, W=8), else 0.
func _edge_mask(cell: Vector2) -> int:
	if cell.y <= 0:
		return 1
	if cell.x >= grid.size.x - 1:
		return 2
	if cell.y >= grid.size.y - 1:
		return 4
	if cell.x <= 0:
		return 8
	return 0

func draw_unit_path(node: Node2D) -> bool:
	temp_current_path = _pathGenerator.calculate_point_path(cell_start_path, cell_end_path)
	
	path_drawn.clear_points()
	path_drawn.visible = true
	path_drawn.default_color = Color("aqua",0.6)
	path_drawn.width = 7.5
	path_drawn.joint_mode = Line2D.LINE_JOINT_ROUND
	path_drawn.end_cap_mode = Line2D.LINE_CAP_ROUND
	path_drawn.begin_cap_mode = Line2D.LINE_CAP_ROUND
	if temp_current_path.size() < 1:
		return true
	for point in temp_current_path:
		path_drawn.add_point(grid.calculate_map_position(point))
	
	if !node.has_node(path_drawn.get_path()):
		node.add_child(path_drawn)
	
	return false
	
func hide_path():
	path_drawn.visible = false
	
# A whole cell is blocked if any of its 4 half cells is; a route point (x.25 / x.75) if its half is.
func is_cell_blocked(cell: Vector2) -> bool:
	if FindPath.is_whole_cell(cell):
		return FindPath.halves_of_cell(cell).any(func(h: Vector2) -> bool: return _pathGenerator.is_half_blocked(h))
	return not _pathGenerator.is_walkable(cell)

func set_cell_blocked(cell: Vector2, blocked: bool) -> void:
	_pathGenerator.set_blocked(cell, blocked)

# Path from `cell` to the end of the map, in cell coordinates. Empty if the end can't be reached.
func find_path_from(cell: Vector2) -> PackedVector2Array:
	return _pathGenerator.calculate_point_path(cell, cell_end_path)

# The route draw() would draw from the start now (as long as A*'s, fewer turns; ~2 ms): for route previews,
# so a preview matches the route that gets drawn. Checks that only need "a way through" or a length use
# find_path_from().
func find_drawn_route() -> PackedVector2Array:
	return _pathGenerator.straightest_point_path(cell_start_path, cell_end_path)

func get_curr_path() -> PackedVector2Array:
	return current_path

func get_curr_path_curve() -> Curve2D:
	return current_path_curve

func _get_tile_score(tile:Vector2i) -> int:
	var score:int = 0
	var x = tile.x
	var y = tile.y
	
	score += 1 if current_path.has(Vector2i(x,y-1)) else 0
	score += 2 if current_path.has(Vector2i(x+1,y)) else 0
	score += 4 if current_path.has(Vector2i(x,y+1)) else 0
	score += 8 if current_path.has(Vector2i(x-1,y)) else 0
	
	return score

# Makes the next draw() (and the sticky re-routes after it) take `cells` when it's among the shortest
# routes: MapGenerator hands it the straightest one so the opening route isn't a staircase.
func prefer_route(cells: PackedVector2Array) -> void:
	_pathGenerator.set_preferred_cells(cells)

# `path_drawn` is only parented once draw_unit_path() runs; free it ourselves otherwise so it doesn't leak.
func _exit_tree() -> void:
	if path_drawn.get_parent() == null:
		path_drawn.free()

# Stops drawing, clearing the drawn path and the `_pathGenerator`.
func stop() -> void:
	_pathGenerator = null
	clear()

# --- Half cells (documentation/half_cells.md) ---------------------------------------------------------

# The path on the dual grid (environment_assets.md "Half-cell grid: environment plan"): the path mask is the
# half cells the route runs through (a ribbon one half wide). A second layer of 32 px tiles sits 16 px up and left,
# so each display tile's corners are 4 half cells' centres; it picks path_dual.png's column by which corners
# are path (TL 1, TR 2, BR 4, BL 8), and a full tile (15) one of 4 variants by position. Drawn behind this
# layer, so the start's path.png rim tile (the rope-bridge join) stays on top.
const DUAL_SHEET := "path_dual"
const DUAL_SIZE := Vector2i(32, 32)
const DUAL_FULL_VARIANTS: Array[int] = [15, 16, 17, 18]
var dual_layer: TileMapLayer
var _dual_tiles := {}  # What the dual layer shows: tile -> column
var _act := 1

func _dual() -> TileMapLayer:
	if dual_layer == null:
		dual_layer = TileMapLayer.new()
		dual_layer.name = "PathDual"
		dual_layer.show_behind_parent = true
		dual_layer.position = -Vector2(DUAL_SIZE) / 2.0
		dual_layer.tile_set = _dual_tile_set()
		add_child(dual_layer)
	return dual_layer

func _dual_tile_set() -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_size = DUAL_SIZE
	var source := TileSetAtlasSource.new()
	source.texture = load(EnvironmentTiles.sheet_path(DUAL_SHEET, _act))
	source.texture_region_size = DUAL_SIZE
	for column in source.get_atlas_grid_size().x:
		source.create_tile(Vector2i(column, 0))
	tiles.add_source(source, 0)
	return tiles

# The act's path_dual.png (MapGenerator.set_act).
func set_act(act: int) -> void:
	_act = act
	if dual_layer != null:
		(dual_layer.tile_set.get_source(0) as TileSetAtlasSource).texture = load(EnvironmentTiles.sheet_path(DUAL_SHEET, act))

# Every half cell the route runs through (one per point): {Vector2i: true}.
func path_halves() -> Dictionary:
	var halves := {}
	for point in current_path:
		halves[FindPath.point_to_node(point)] = true
	return halves

# path_dual.png's column for the display tile `at`: its corners are half cells at-1 .. at.
static func dual_mask(halves: Dictionary, at: Vector2i) -> int:
	return ((1 if halves.has(at + Vector2i(-1, -1)) else 0) | (2 if halves.has(at + Vector2i(0, -1)) else 0)
		| (4 if halves.has(at) else 0) | (8 if halves.has(at + Vector2i(-1, 0)) else 0))

func _draw_dual() -> void:
	var layer := _dual()
	var halves := path_halves()
	var tiles := {}  # Display tile -> column
	for h: Vector2i in halves:  # Each path half cell is a corner of 4 display tiles
		for dy in 2:
			for dx in 2:
				var at := h + Vector2i(dx, dy)
				if tiles.has(at):
					continue
				var mask := dual_mask(halves, at)
				if mask == 15:
					mask = DUAL_FULL_VARIANTS[EnvironmentTiles.cell_variant(at, DUAL_FULL_VARIANTS.size(), 7)]
				tiles[at] = mask
	# Only the tiles that changed (a placement moves a short stretch of the route).
	for at: Vector2i in _dual_tiles:
		if not tiles.has(at):
			layer.erase_cell(at)
	for at: Vector2i in tiles:
		if _dual_tiles.get(at, -1) != tiles[at]:
			layer.set_cell(at, 0, Vector2i(tiles[at], 0))
	_dual_tiles = tiles

func get_finder() -> FindPath:
	return _pathGenerator

func is_half_blocked(h: Vector2) -> bool:
	return _pathGenerator.is_half_blocked(h)

func set_half_blocked(h: Vector2, blocked: bool) -> void:
	_pathGenerator.set_half_blocked(h, blocked)

# --- Fast re-routes (half_cells.md "Placement feel") --------------------------------------------------

var _route_version := -1
var _route_index := {}  # Route point -> its index in current_path (built by draw())

# The route from `point` to the Heartwood when `point` is on the current route and nothing has been
# blocked or opened since it was drawn: the route's own tail (a shortest route's tail is a shortest
# route, and the one sticky re-routes keep). Empty otherwise (search instead).
func route_tail(point: Vector2) -> PackedVector2Array:
	if _pathGenerator == null or _route_version != _pathGenerator.version:
		return PackedVector2Array()
	if point == cell_start_path:  # The start as a whole cell: the whole route
		return current_path.duplicate()
	if not _route_index.has(point):
		return PackedVector2Array()
	return current_path.slice(_route_index[point])
