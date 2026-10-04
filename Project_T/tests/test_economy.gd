extends SceneTree

# Headless Dew economy test. Run from the project folder:
#   godot --headless --path . --script res://tests/test_economy.gd --fixed-fps 60

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
	var clearer: ObstacleClearer = main.get_node("%ObstacleClearer")
	main.get_node("%DreamState").clearing_open = true  # Normally a clearing Dream unlocks clearing
	var run_state: RunState = main.get_node("%RunState")
	var towers: Node = main.get_node("%TowerContainer")
	var leaf_bug: EnemyData = load("res://resource/enemy/leaf_bug.tres")

	# Keep the field empty so enemies don't block cells or earn Dew on their own.
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	_check(run_state.dew == run_state.starting_dew, "run starts with starting_dew (%d)" % run_state.dew)
	var short_count := [0]
	run_state.dew_short.connect(func(_cost: int) -> void: short_count[0] += 1)

	# --- Building costs Dew ---
	var cost: int = placer.tower_data.cost
	run_state.dew = cost + 2
	var cell := _cell_next_to_path(map_generator, map_generator.get_path_from(map_generator.startPath), 4)
	_check(placer._try_build(cell), "affordable tower builds")
	_check(run_state.dew == 2, "building charges the tower's cost (%d left)" % run_state.dew)

	# --- Can't build without enough Dew ---
	var tower_count := towers.get_child_count()
	var cell2 := _cell_next_to_path(map_generator, map_generator.get_path_from(map_generator.startPath), 8)
	_check(not placer._try_build(cell2), "unaffordable tower is refused")
	_check(towers.get_child_count() == tower_count, "no tower placed when short on Dew")
	_check(run_state.dew == 2, "refused build charges nothing")
	_check(map_generator.is_buildable(cell2), "refused cell stays open")
	_check(short_count[0] == 1, "dew_short emitted for the UI")

	# --- Invalid cell charges nothing ---
	run_state.dew = 100
	_check(not placer._try_build(Vector2(0, 5)), "border cell refused")
	_check(run_state.dew == 100, "invalid placement charges nothing")

	# --- Clearing obstacles costs Dew ---
	var obstacle_cell: Vector2 = map_generator.obstacles.keys()[0]
	var clear_cost: int = map_generator.get_obstacle(obstacle_cell).clear_cost
	run_state.dew = clear_cost - 1
	_check(not clearer.try_clear(obstacle_cell), "unaffordable clear is refused")
	_check(map_generator.get_obstacle(obstacle_cell) != null, "obstacle stays when short on Dew")
	run_state.dew = clear_cost
	_check(clearer.try_clear(obstacle_cell), "affordable clear works")
	_check(run_state.dew == 0 and map_generator.get_obstacle(obstacle_cell) == null, "clearing charges its cost")

	# --- Cleansing earns Dew ---
	run_state.dew = 0
	spawner.spawn_enemy(leaf_bug)
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.take_damage(enemy.max_health)
	var act_1_pay: int = leaf_bug.dew_reward  # Outside a drift (no pot share): its plain dew_reward
	_check(run_state.dew == act_1_pay, "cleansing a Leaf Bug earns %d Dew (got %d)" % [act_1_pay, run_state.dew])
	var popups := main.get_children().filter(func(n: Node) -> bool: return n is DewPopup)
	_check(popups.size() == 1, "a +Dew popup appears")
	enemy.take_damage(enemy.max_health)
	_check(run_state.dew == act_1_pay, "an already-cleansed creature doesn't pay twice")
	await create_timer(1.5, true, true).timeout
	_check(main.get_children().filter(func(n: Node) -> bool: return n is DewPopup).is_empty(), "popup frees itself")

	print("economy test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

# A buildable cell next to the path near index `from_index` that keeps the path open.
func _cell_next_to_path(map_generator, path: PackedVector2Array, from_index: int) -> Vector2:
	for i in range(from_index, path.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if not path.has(cell) and map_generator.can_block(cell):
				return cell
	return Vector2(-1, -1)
