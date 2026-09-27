extends Node2D

# Emitted after the enemy path changes (e.g. a tower was built). Enemies re-route when they hear it.
signal path_changed
# Emitted when the player clears an obstacle (before path_changed).
signal obstacle_cleared(cell: Vector2, data: ObstacleData)

@onready var ground_layer: GroundGenerator = %GroundTileMapLayer
@onready var path_layer: PathGenerator = %PathTileMapLayer
@onready var environment_object_layer: EnvironmentObjectGenerator = %EnvironmentObjectTileMapLayer
const MAP_GRID = preload("res://resource/map/map_grid.tres")
# How much more a route through an obstacle costs than open ground when carving a guaranteed route.
# High, so carving takes long detours before clearing anything, and prefers stray obstacles over
# breaking a ridge (which would undo the zig-zag the ridges create).
const CARVE_OBSTACLE_WEIGHT := 100.0
const CARVE_RIDGE_WEIGHT := 1000.0


@export var startPath: Vector2 = Vector2(1,0)
@export var endPath: Vector2 = Vector2(MAP_GRID.size.x - 2, MAP_GRID.size.y - 1)
@export var map_seed: int = 0  # 0 = new random map every run; anything else reproduces a map
var unwalkable_cells: PackedVector2Array
# Clearable trees/rocks still on the map: {cell (Vector2): ObstacleData}.
var obstacles: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	if map_seed != 0:
		rng.seed = map_seed
	else:
		rng.randomize()

	ground_layer.initialize()
	unwalkable_cells = environment_object_layer.initialize(startPath, endPath)
	path_layer.initialize(get_array_board(), startPath, endPath)

	# Obstacles can sit on any open cell, so the route winds around them. Keep start/end clear.
	var skip := unwalkable_cells.duplicate()
	skip.append(startPath)
	skip.append(endPath)
	obstacles = environment_object_layer.generate_obstacles(rng, skip)
	for cell in obstacles:
		path_layer.set_cell_blocked(cell, true)
	_carve_route_if_blocked()

	path_layer.draw()
	var no_details := unwalkable_cells + path_layer.current_path + PackedVector2Array(obstacles.keys())
	environment_object_layer.generate_details(rng, no_details)

# If obstacles cut the start off from the end, clears the fewest-obstacle route between them.
func _carve_route_if_blocked() -> void:
	if not path_layer.find_path_from(startPath).is_empty():
		return
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(Vector2i.ZERO, Vector2i(MAP_GRID.size))
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for cell in unwalkable_cells:
		if astar.is_in_boundsv(Vector2i(cell)):
			astar.set_point_solid(Vector2i(cell), true)
	for cell in obstacles:
		var is_ridge: bool = environment_object_layer.ridge_cells.has(cell)
		astar.set_point_weight_scale(Vector2i(cell), CARVE_RIDGE_WEIGHT if is_ridge else CARVE_OBSTACLE_WEIGHT)
	for cell in astar.get_point_path(Vector2i(startPath), Vector2i(endPath)):
		if obstacles.has(cell):
			_remove_obstacle(cell)

func _remove_obstacle(cell: Vector2) -> void:
	obstacles.erase(cell)
	environment_object_layer.erase_cell(Vector2i(cell))
	path_layer.set_cell_blocked(cell, false)

func get_array_board() -> PackedVector2Array:
	var _map_array: PackedVector2Array
	for x in range(MAP_GRID.size.x):
		for y in range(MAP_GRID.size.y):
			if !unwalkable_cells.has(Vector2(x,y)):
				_map_array.append(Vector2(x,y))
	return _map_array


# --- Building -------------------------------------------------------------------------------------

# True if nothing occupies `cell` (inside the map, not border/tree/tower, not the start or end).
# Does not check whether blocking it would cut off the path — see get_path_if_blocked().
func is_buildable(cell: Vector2) -> bool:
	return MAP_GRID.is_within_bounds(cell) \
		and cell != startPath and cell != endPath \
		and not path_layer.is_cell_blocked(cell)

# Returns the start-to-end path that would exist if `cell` were blocked, without changing anything.
# Empty means blocking `cell` would leave enemies with no way through.
func get_path_if_blocked(cell: Vector2) -> PackedVector2Array:
	path_layer.set_cell_blocked(cell, true)
	var path := path_layer.find_path_from(startPath)
	path_layer.set_cell_blocked(cell, false)
	return path

# True if blocking `cell` keeps the end reachable from the start and from every cell in `also_from`
# (e.g. cells enemies are currently walking toward).
func can_block(cell: Vector2, also_from: PackedVector2Array = PackedVector2Array()) -> bool:
	if not is_buildable(cell):
		return false
	path_layer.set_cell_blocked(cell, true)
	var ok := not path_layer.find_path_from(startPath).is_empty()
	for from_cell in also_from:
		if not ok:
			break
		ok = not path_layer.find_path_from(from_cell).is_empty()
	path_layer.set_cell_blocked(cell, false)
	return ok

# Permanently blocks `cell` (call can_block() first), redraws the path and notifies enemies.
func block_cell(cell: Vector2) -> void:
	path_layer.set_cell_blocked(cell, true)
	environment_object_layer.erase_cell(Vector2i(cell))  # Clear grass detail under the tower
	path_layer.draw()
	path_changed.emit()


# --- Obstacles ------------------------------------------------------------------------------------

# The tree/rock on `cell`, or null.
func get_obstacle(cell: Vector2) -> ObstacleData:
	return obstacles.get(cell)

# The start-to-end path that would exist if the obstacle on `cell` were cleared, without changing
# anything. Clearing only ever opens routes, so this is never empty when a path exists now.
func get_path_if_cleared(cell: Vector2) -> PackedVector2Array:
	path_layer.set_cell_blocked(cell, false)
	var path := path_layer.find_path_from(startPath)
	path_layer.set_cell_blocked(cell, true)
	return path

# Removes the obstacle on `cell` (no-op if there isn't one), redraws the path and notifies enemies.
func clear_obstacle(cell: Vector2) -> bool:
	var data := get_obstacle(cell)
	if data == null:
		return false
	_remove_obstacle(cell)
	path_layer.draw()
	obstacle_cleared.emit(cell, data)
	path_changed.emit()
	return true

# Path from `cell` to the end, in cell coordinates. Used by enemies to re-route.
func get_path_from(cell: Vector2) -> PackedVector2Array:
	return path_layer.find_path_from(cell)
