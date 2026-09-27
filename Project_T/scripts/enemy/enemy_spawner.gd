extends Node2D

# Spawns creatures and re-emits their signals, so listeners (RunState, DriftDirector) don't track
# individual enemies. When a creature that splits is cleansed, `enemy_split` fires for each child
# BEFORE `enemy_cleansed` fires for the parent, so drift bookkeeping never sees an empty drift early.
# Followers (a Mother Duck's Ducklings) are announced through `enemy_split` too: any creature that
# comes from another belongs to the same drift.
signal enemy_cleansed(enemy: Node2D)
signal enemy_reached_goal(enemy: Node2D)
signal enemy_split(parent: Node2D, child: Node2D)
# The Old Stag knocked a Thornwall down (it's gone for good; the path re-routes).
signal wall_trampled(cell: Vector2, by: Node2D)

const SPLIT_SPACING := 14.0  # Pixels between creatures that pop out of a split

@export var enemy_scene: PackedScene = preload("res://scenes/enemy/enemy.tscn")  # The enemy scene to spawn

# Node references
@onready var map_generator = %MapGenerator
@onready var tower_container: Node2D = %TowerContainer

func _ready() -> void:
	map_generator.path_changed.connect(_on_path_changed)

# Spawns a creature at the start of the maze. Returns it, or null if there's no route.
# `modifiers`: Omen multipliers for the creature (see Enemy.modifiers). `elite`: Deeply Blighted.
# Flyers float straight at the Heartwood; a Mother Duck brings her Ducklings in single file.
func spawn_enemy(enemy_data: EnemyData, health_scale: float = 1.0, modifiers: Dictionary = {},
		elite: bool = false) -> Node2D:
	var path_points: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	if path_points.is_empty():
		return null
	if enemy_data.trait_kind == EnemyData.Trait.FLYING:
		path_points = PackedVector2Array([map_generator.startPath, map_generator.endPath])
	var enemy := _create(enemy_data, health_scale, modifiers, elite)
	enemy.position = enemy.grid.calculate_map_position(path_points[0])  # Start at the first waypoint (pixels)
	enemy.set_path(path_points)
	_spawn_followers(enemy, path_points)
	return enemy

func _create(enemy_data: EnemyData, health_scale: float, modifiers: Dictionary = {},
		elite: bool = false) -> Node2D:
	var enemy = enemy_scene.instantiate()
	enemy.enemy_data = enemy_data
	enemy.health_scale = health_scale
	enemy.modifiers = modifiers
	enemy.elite = elite
	enemy.cleansed.connect(_on_enemy_cleansed)
	enemy.reached_goal.connect(enemy_reached_goal.emit)
	enemy.trample_requested.connect(_on_trample_requested)
	add_child(enemy)
	return enemy

# A Mother Duck's Ducklings set off one after another right behind her. If she's cleansed while
# they're still walking, they get lost and slow down.
func _spawn_followers(leader: Node2D, path: PackedVector2Array) -> void:
	var data: EnemyData = leader.enemy_data
	if data.followers == null or data.follower_count <= 0:
		return
	var followers: Array[Node2D] = []
	for i in data.follower_count:
		var follower := _create(data.followers, leader.health_scale, leader.modifiers)
		follower.position = leader.position
		follower.set_path(path)
		follower.hold_time = data.follower_spacing * (i + 1)
		followers.append(follower)
		enemy_split.emit(leader, follower)
	leader.cleansed.connect(func(_leader: Node2D) -> void:
		for follower in followers:
			if is_instance_valid(follower):
				follower.set_lost())

# Enemies still walking the maze. Cleansing enemies are excluded: they don't block building or re-route.
func get_enemies() -> Array[Node]:
	var enemies: Array[Node] = []
	for enemy in get_children():
		if not enemy.is_cleansed:
			enemies.append(enemy)
	return enemies

# Walking creatures that follow the maze (flyers float over it): these are the ones building must
# never cut off, and the ones that re-route.
func get_maze_walkers() -> Array[Node]:
	return get_enemies().filter(func(enemy: Node) -> bool: return not enemy.is_flying())

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
		var child := _create(data.split_into, parent.health_scale, parent.modifiers)
		child.position = parent.position + back * SPLIT_SPACING * i
		child.set_path(path)
		enemy_split.emit(parent, child)

# Old Stag: knocks down a Thornwall (or Bramble) next to it. The wall is gone for good, with no
# refund; opening a cell never breaks the path rule, and everyone re-routes.
func _on_trample_requested(enemy: Node2D) -> void:
	var here: Vector2 = enemy.get_current_cell()
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var cell: Vector2 = here + offset
		for tower in tower_container.get_children():
			if tower is Tower and tower.cell == cell and tower.tower_data.line == "wall" \
					and not tower.is_queued_for_deletion():
				tower_container.remove_child(tower)
				tower.queue_free()
				map_generator.unblock_cell(cell)
				enemy.trampled()
				wall_trampled.emit(cell, enemy)
				return

# The maze changed: every enemy re-routes from the cell it's currently walking toward.
func _on_path_changed() -> void:
	for enemy in get_maze_walkers():
		var new_path: PackedVector2Array = map_generator.get_path_from(enemy.get_target_cell())
		if not new_path.is_empty():
			enemy.set_path(new_path)
