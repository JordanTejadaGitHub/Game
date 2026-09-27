extends Node2D

# Emitted after the enemy path changes (e.g. a tower was built). Enemies re-route when they hear it.
signal path_changed

@onready var ground_layer: GroundGenerator = %GroundTileMapLayer
@onready var path_layer: PathGenerator = %PathTileMapLayer
@onready var environment_object_layer: EnvironmentObjectGenerator = %EnvironmentObjectTileMapLayer
const MAP_GRID = preload("res://resource/map/map_grid.tres")


@export var startPath: Vector2 = Vector2(1,0)
@export var endPath: Vector2 = Vector2(MAP_GRID.size.x - 2, MAP_GRID.size.y - 1)
var unwalkable_cells: PackedVector2Array


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ground_layer.initialize()
	unwalkable_cells = environment_object_layer.initialize(startPath, endPath)
	path_layer.initialize(get_array_board(), startPath, endPath)
	path_layer.draw()
	unwalkable_cells += path_layer.current_path
	# Trees are placed off the initial path, so the map always starts with a valid route.
	var tree_cells := environment_object_layer.generate_details_and_trees(unwalkable_cells)
	for cell in tree_cells:
		path_layer.set_cell_blocked(cell, true)

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

# Path from `cell` to the end, in cell coordinates. Used by enemies to re-route.
func get_path_from(cell: Vector2) -> PackedVector2Array:
	return path_layer.find_path_from(cell)
