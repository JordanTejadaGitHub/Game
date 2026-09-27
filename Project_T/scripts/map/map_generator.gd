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
var tile_set: TileSet  # Shared by the ground, path and object layers (EnvironmentTiles)
var heartwood: Heartwood  # The goal tree on the end cell
var dream_void: DreamVoid  # The starry void around the island
var lighting: EnvironmentLighting  # Cold edges, warm Warden lights
var ambience: EnvironmentAmbience  # Edge fog and the act's particles


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# A random map gets a concrete seed too, so a saved run can rebuild exactly this map.
	if map_seed == 0:
		map_seed = randi_range(1, 2147483646)
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed

	tile_set = EnvironmentTiles.create_tile_set()
	for layer: TileMapLayer in [ground_layer, path_layer, environment_object_layer]:
		layer.tile_set = tile_set
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

	heartwood = Heartwood.new()
	heartwood.position = MAP_GRID.calculate_map_position(endPath)
	heartwood.run_state = get_node_or_null("%RunState")
	add_child(heartwood)

	dream_void = DreamVoid.new()
	dream_void.bridge_end = environment_object_layer.bridge_end
	dream_void.map_seed = map_seed
	add_child(dream_void)
	move_child(dream_void, 0)  # Behind the tile layers

	lighting = EnvironmentLighting.new()
	lighting.tower_container = get_node_or_null("%TowerContainer")
	add_child(lighting)
	ambience = EnvironmentAmbience.new()
	ambience.heartwood_position = heartwood.position
	add_child(ambience)

# Swaps the environment art to act `act`'s season (every sheet, and the Heartwood's).
func set_act(act: int) -> void:
	EnvironmentTiles.set_act(tile_set, act)
	heartwood.set_act(act)
	ambience.act = act

# If obstacles cut the start off from the end, clears the fewest-obstacle route between them.
# Ridges are left intact (they create the zig-zag) unless there's no other way through.
func _carve_route_if_blocked() -> void:
	if not path_layer.find_path_from(startPath).is_empty():
		return
	var route := _find_carve_route(false)
	if route.is_empty():
		route = _find_carve_route(true)
	for cell in route:
		if obstacles.has(cell):
			_remove_obstacle(cell, false)  # Generation: no clearing mark

# Cheapest start-to-end route where obstacles are passable but costly. Ridge cells are solid unless
# `break_ridges`.
func _find_carve_route(break_ridges: bool) -> PackedVector2Array:
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(Vector2i.ZERO, Vector2i(MAP_GRID.size))
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()
	for cell in unwalkable_cells:
		if astar.is_in_boundsv(Vector2i(cell)):
			astar.set_point_solid(Vector2i(cell), true)
	for cell in obstacles:
		if environment_object_layer.ridge_cells.has(cell):
			if break_ridges:
				astar.set_point_weight_scale(Vector2i(cell), CARVE_RIDGE_WEIGHT)
			else:
				astar.set_point_solid(Vector2i(cell), true)
		else:
			astar.set_point_weight_scale(Vector2i(cell), CARVE_OBSTACLE_WEIGHT)
	return astar.get_point_path(Vector2i(startPath), Vector2i(endPath))

# Removes the obstacle on `cell`; `mark` leaves its clearing mark (tended stump, moved hollow).
func _remove_obstacle(cell: Vector2, mark: bool = true) -> void:
	var data: ObstacleData = obstacles.get(cell)
	obstacles.erase(cell)
	if mark and data != null:
		environment_object_layer.mark_cleared(cell, data)
	else:
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

# Opens a cell a Warden stood on (it was sold), redraws the path and notifies enemies.
# Opening a cell never cuts a route, so this is always allowed.
func unblock_cell(cell: Vector2) -> void:
	path_layer.set_cell_blocked(cell, false)
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

# Puts obstacle `data` on `cell` mid-run (the Hollow Oak's thorn-saplings): blocks and draws it, and
# re-routes nightmares. Call can_block() first; it can then be cleared like any obstacle.
func place_obstacle(cell: Vector2, data: ObstacleData) -> void:
	if not data.tiles.is_empty():  # No tiles: something else draws it (the saplings' animation)
		environment_object_layer.set_cell(Vector2i(cell), data.source_id, data.tiles.pick_random())
	else:
		environment_object_layer.erase_cell(Vector2i(cell))  # No grass detail showing through
	obstacles[cell] = data
	path_layer.set_cell_blocked(cell, true)
	path_layer.draw()
	path_changed.emit()

# Removes an obstacle without the player clearing it (a sapling withering): no clearing mark, no
# obstacle_cleared. Re-routes nightmares.
func remove_obstacle(cell: Vector2) -> void:
	if not obstacles.has(cell):
		return
	_remove_obstacle(cell, false)
	path_layer.draw()
	path_changed.emit()

# Path from `cell` to the end, in cell coordinates. Used by enemies to re-route.
func get_path_from(cell: Vector2) -> PackedVector2Array:
	return path_layer.find_path_from(cell)
