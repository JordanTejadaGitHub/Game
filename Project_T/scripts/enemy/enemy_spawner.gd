extends Node2D

@export var enemy_scene: PackedScene = preload("res://scenes/enemy/enemy.tscn")  # The enemy scene to spawn
@export var spawn_rate: float = 2.0  # Time between spawns
var timer: float = 0.0

# Enemy spawned every `spawn_rate` seconds. Temporary stand-in until there's a wave manager.
var _auto_spawn_data: EnemyData

# Node references
@onready var map_generator = %MapGenerator

func _ready() -> void:
	map_generator.path_changed.connect(_on_path_changed)

func _process(delta: float) -> void:
	if _auto_spawn_data == null:
		return
	timer += delta
	if timer >= spawn_rate:
		timer -= spawn_rate
		spawn_enemy(_auto_spawn_data)

# Spawns `enemy_data` now and then again every `spawn_rate` seconds.
func start_spawning(enemy_data: EnemyData) -> void:
	_auto_spawn_data = enemy_data
	timer = 0.0
	spawn_enemy(enemy_data)

func spawn_enemy(enemy_data: EnemyData) -> void:
	var path_points: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	if path_points.is_empty():
		return

	var enemy = enemy_scene.instantiate()
	enemy.enemy_data = enemy_data
	add_child(enemy)
	enemy.position = enemy.grid.calculate_map_position(path_points[0])  # Start at the first waypoint (pixels)
	enemy.set_path(path_points)

# Enemies still walking the maze. Cleansing enemies are excluded: they don't block building or re-route.
func get_enemies() -> Array[Node]:
	var enemies: Array[Node] = []
	for enemy in get_children():
		if not enemy.is_cleansed:
			enemies.append(enemy)
	return enemies

# The maze changed: every enemy re-routes from the cell it's currently walking toward.
func _on_path_changed() -> void:
	for enemy in get_enemies():
		var new_path: PackedVector2Array = map_generator.get_path_from(enemy.get_target_cell())
		if not new_path.is_empty():
			enemy.set_path(new_path)
