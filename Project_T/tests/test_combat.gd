extends SceneTree

# Headless combat test. Run from the project folder:
#   godot --headless --path . --script res://tests/test_combat.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var map_generator = main.get_node("%MapGenerator")
	var spawner = main.get_node("%EnemyContainer")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var leaf_bug: EnemyData = load("res://resource/enemy/leaf_bug.tres")

	# --- Cleanse on 0 health ---
	spawner.spawn_enemy(leaf_bug)
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	var cleansed := [false]
	enemy.cleansed.connect(func(_e: Node2D) -> void: cleansed[0] = true)
	enemy.take_damage(enemy.max_health - 1)
	_check(not enemy.is_cleansed and enemy.health == 1, "enemy survives non-lethal damage")
	enemy.take_damage(50)
	_check(enemy.is_cleansed and cleansed[0], "enemy is cleansed at 0 health")
	_check(enemy.health == 0, "health doesn't go negative")
	_check(not enemy.is_in_group("enemies"), "cleansed enemy leaves the target group")
	_check(not spawner.get_enemies().has(enemy), "cleansed enemy isn't blocking building")
	await _wait(1.5)
	_check(not is_instance_valid(enemy), "cleansed enemy is freed after its effect")

	# --- "First" targeting ---
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var tower_cell := _cell_next_to_path(map_generator, path, 4)
	_check(tower_cell != Vector2(-1, -1), "found a buildable cell beside the path")
	var strong_tower: TowerData = placer.tower_data.duplicate()
	strong_tower.damage = 1000
	placer.tower_data = strong_tower
	placer._try_build(tower_cell)
	var tower: Tower = main.get_node("%TowerContainer").get_child(0)
	tower.set_process(false)  # Don't let it fire while we check targeting

	for child in spawner.get_children():
		child.queue_free()
	await process_frame
	# Two enemies on the path either side of the tower: the later path cell is closer to the goal.
	path = map_generator.get_path_from(map_generator.startPath)
	var beside := 0
	for i in path.size():
		if path[i].distance_to(tower.cell) == 1.0:
			beside = i
			break
	var behind = _spawn_at(spawner, leaf_bug, map_generator, path[beside - 1])
	var ahead = _spawn_at(spawner, leaf_bug, map_generator, path[beside + 1])
	ahead.set_process(false)
	behind.set_process(false)
	await process_frame
	_check(ahead.get_remaining_distance() < behind.get_remaining_distance(), "remaining distance shrinks along the path")
	_check(tower.find_target() == ahead, "tower targets the enemy closest to the goal")
	ahead.queue_free()
	behind.queue_free()

	# --- Tower shoots and cleanses walking enemies ---
	await process_frame
	var cleanse_count := [0]
	spawner.child_entered_tree.connect(func(node: Node) -> void:
		node.cleansed.connect(func(_e: Node2D) -> void: cleanse_count[0] += 1))
	tower.set_process(true)
	spawner.spawn_enemy(leaf_bug)
	await _wait(12.0)
	_check(cleanse_count[0] >= 1, "tower cleanses a passing enemy (%d cleansed)" % cleanse_count[0])

	print("combat test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout

# A buildable cell next to the path near index `from_index` that keeps the path open.
func _cell_next_to_path(map_generator, path: PackedVector2Array, from_index: int) -> Vector2:
	for i in range(from_index, path.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if not path.has(cell) and map_generator.can_block(cell):
				return cell
	return Vector2(-1, -1)

# Spawns an enemy standing on `cell`, routed from there to the goal.
func _spawn_at(spawner, data: EnemyData, map_generator, cell: Vector2) -> Node2D:
	var enemy = spawner.enemy_scene.instantiate()
	enemy.enemy_data = data
	spawner.add_child(enemy)
	enemy.position = enemy.grid.calculate_map_position(cell)
	enemy.set_path(map_generator.get_path_from(cell))
	return enemy
