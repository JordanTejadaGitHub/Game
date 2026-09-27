extends Node2D

# Spawns creatures and re-emits their signals, so listeners (RunState, DriftDirector) don't track
# individual enemies. When a creature that splits is cleansed, `enemy_split` fires for each child
# BEFORE `enemy_cleansed` fires for the parent, so drift bookkeeping never sees an empty drift early.
signal enemy_cleansed(enemy: Node2D)
signal enemy_reached_goal(enemy: Node2D)
signal enemy_split(parent: Node2D, child: Node2D)

const SPLIT_SPACING := 14.0  # Pixels between creatures that pop out of a split

@export var enemy_scene: PackedScene = preload("res://scenes/enemy/enemy.tscn")  # The enemy scene to spawn

# Node references
@onready var map_generator = %MapGenerator

func _ready() -> void:
	map_generator.path_changed.connect(_on_path_changed)

# Spawns a creature at the start of the maze. Returns it, or null if there's no route.
func spawn_enemy(enemy_data: EnemyData, health_scale: float = 1.0) -> Node2D:
	var path_points: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	if path_points.is_empty():
		return null
	var enemy := _create(enemy_data, health_scale)
	enemy.position = enemy.grid.calculate_map_position(path_points[0])  # Start at the first waypoint (pixels)
	enemy.set_path(path_points)
	return enemy

func _create(enemy_data: EnemyData, health_scale: float) -> Node2D:
	var enemy = enemy_scene.instantiate()
	enemy.enemy_data = enemy_data
	enemy.health_scale = health_scale
	enemy.cleansed.connect(_on_enemy_cleansed)
	enemy.reached_goal.connect(enemy_reached_goal.emit)
	add_child(enemy)
	return enemy

# Enemies still walking the maze. Cleansing enemies are excluded: they don't block building or re-route.
func get_enemies() -> Array[Node]:
	var enemies: Array[Node] = []
	for enemy in get_children():
		if not enemy.is_cleansed:
			enemies.append(enemy)
	return enemies

func _on_enemy_cleansed(enemy: Node2D) -> void:
	_split(enemy)
	enemy_cleansed.emit(enemy)

# Pops `split_count` `split_into` creatures out where `parent` was, lined up behind it on its route.
func _split(parent: Node2D) -> void:
	var data: EnemyData = parent.enemy_data
	if data.split_into == null or data.split_count <= 0:
		return
	var path: PackedVector2Array = map_generator.get_path_from(parent.get_target_cell())
	if path.is_empty():
		return
	var ahead: Vector2 = parent.grid.calculate_map_position(path[0]) - parent.position
	var back := -ahead.normalized() if not ahead.is_zero_approx() else Vector2.ZERO
	for i in data.split_count:
		var child := _create(data.split_into, parent.health_scale)
		child.position = parent.position + back * SPLIT_SPACING * i
		child.set_path(path)
		enemy_split.emit(parent, child)

# The maze changed: every enemy re-routes from the cell it's currently walking toward.
func _on_path_changed() -> void:
	for enemy in get_enemies():
		var new_path: PackedVector2Array = map_generator.get_path_from(enemy.get_target_cell())
		if not new_path.is_empty():
			enemy.set_path(new_path)
