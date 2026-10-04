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
	current_path = _pathGenerator.calculate_point_path(cell_start_path, cell_end_path)
	# Later re-routes (towers, cleared obstacles, enemies mid-walk) stick to this route when they can.
	_pathGenerator.set_preferred_cells(current_path)
	# Half cells (experiment/half-cells): route points step by half a cell, so the path is a soft fill drawn
	# under every body position (HalfPathFill), not tiles. The start still runs off the rim onto the bridge.
	for cell in current_path:
		if board != null:
			for x in [floorf(cell.x), ceilf(cell.x)]:  # The full cells this body overlaps
				for y in [floorf(cell.y), ceilf(cell.y)]:
					board.environment_object_layer.wear_away(Vector2i(x, y))  # The path wore the debris away
		current_path_curve.add_point(grid.calculate_map_position(cell))
	if not current_path.is_empty():
		set_cell(cell_start_path, EnvironmentTiles.PATH_RIM, EnvironmentTiles.path_tile(_edge_mask(cell_start_path)))
	_fill().queue_redraw()

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
	
func is_cell_blocked(cell: Vector2) -> bool:
	return not _pathGenerator.is_walkable(cell)

func set_cell_blocked(cell: Vector2, blocked: bool) -> void:
	_pathGenerator.set_blocked(cell, blocked)

# Path from `cell` to the end of the map, in cell coordinates. Empty if the end can't be reached.
func find_path_from(cell: Vector2) -> PackedVector2Array:
	return _pathGenerator.calculate_point_path(cell, cell_end_path)

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

# --- Half cells (experiment/half-cells) -------------------------------------------------------------

# The soft path fill: a 64 px rounded square under every body position on the route (they overlap by
# half), an edge in a darker shade first. A look good enough to judge play, not final art.
var _path_fill: Node2D

func _fill() -> Node2D:
	if _path_fill == null:
		_path_fill = Node2D.new()
		_path_fill.name = "HalfPathFill"
		_path_fill.draw.connect(_draw_fill)
		add_child(_path_fill)
	return _path_fill

func _draw_fill() -> void:
	var size := Vector2(grid.cell_size)
	for pass_index in 2:
		var grow := 3.0 if pass_index == 0 else -1.0
		var colour := Color(Palette.LOAM, 0.9) if pass_index == 0 else Palette.PATH
		for cell in current_path:
			var rect := Rect2(grid.calculate_map_position(cell) - size / 2.0, size).grow(grow)
			_path_fill.draw_rect(rect, colour)

func get_finder() -> FindPath:
	return _pathGenerator

func is_half_blocked(h: Vector2) -> bool:
	return _pathGenerator.is_half_blocked(h)

func set_half_blocked(h: Vector2, blocked: bool) -> void:
	_pathGenerator.set_half_blocked(h, blocked)
