# Draws the unit's movement path using an autotile.
class_name PathGenerator
extends TileMapLayer

@onready var board = %MapGenerator
@onready var tileMap: TileMapLayer = %PathTileMapLayer
@onready var tile_map_location: TileMapLocation = preload("res://resource/map/tile_map_location_data.tres")

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
	# And we draw a tile for every cell in the path.
		
	for cell in current_path:
		var tile_score:int = _get_tile_score(cell)
		var tile: Vector2i = tile_map_location.tile_straight_side
		if tile_score == 2 or tile_score == 8 or tile_score == 10:
			pass
		elif tile_score == 1 or tile_score == 4 or tile_score == 5:
			tile = tile_map_location.tile_straight_up
		elif tile_score == 9:
			tile = tile_map_location.tile_corner_left_up
		elif tile_score == 12:
			tile = tile_map_location.tile_corner_left_down
		elif tile_score == 6:
			tile = tile_map_location.tile_corner_right_down
		elif tile_score == 3:
			tile = tile_map_location.tile_corner_right_up
		set_cell(cell, 1, tile)
		current_path_curve.add_point(grid.calculate_map_position(cell))
	
	# The function below updates the auto-tiling. Without it, you wouldn't get the nice path with curves
	# and the arrows on either end.

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

# `path_drawn` is only parented once draw_unit_path() runs; free it ourselves otherwise so it doesn't leak.
func _exit_tree() -> void:
	if path_drawn.get_parent() == null:
		path_drawn.free()

# Stops drawing, clearing the drawn path and the `_pathGenerator`.
func stop() -> void:
	_pathGenerator = null
	clear()
