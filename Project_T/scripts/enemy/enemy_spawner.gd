extends Node2D

@export var enemy_scene: PackedScene = preload("res://scenes/enemy/enemy.tscn")  # The enemy scene to spawn
@export var spawn_rate: float = 2.0  # Time between spawns
var timer: float = 0.0

# Node references
@onready var path_layer = %MapGenerator/PathTileMapLayer  # Reference to PathTileMapLayer

func spawn_enemy(enemy_data: EnemyData) -> void:
	var enemy = enemy_scene.instantiate()
	enemy.enemy_data = enemy_data
	
	add_child(enemy)

	# Pass the path points from path_layer to the enemy
	var path_points = path_layer.current_path
	if path_points.size() > 0:
		enemy.set_path(path_points)
		enemy.position = enemy.grid.calculate_map_position(path_points[0])  # Start at the first waypoint (pixels)
