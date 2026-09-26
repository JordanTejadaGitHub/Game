extends Node2D

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
	environment_object_layer.generate_details_and_trees(unwalkable_cells)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_array_board() -> PackedVector2Array:
	var _map_array: PackedVector2Array
	for x in range(MAP_GRID.size.x):
		for y in range(MAP_GRID.size.y):
			if !unwalkable_cells.has(Vector2(x,y)):
				_map_array.append(Vector2(x,y))
	return _map_array
