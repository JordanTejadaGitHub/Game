extends SceneTree
# The log feature is one obstacle (Environment Discussion, user option c): fallen_log.png pieces along its
# 3-4 cells, cleared as a unit for a tree's cost per cell (through ObstacleClearer, so Dreams and Blight
# apply), counted as one clear, its route preview opening every cell, and the save restoring it whole.
# Run:  Godot --headless --path . --script res://tests/test_fallen_log.gd --fixed-fps 60

const TREE := preload("res://resource/obstacle/tree.tres")

var failures := 0

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_fallen_log_%d.json" % OS.get_process_id()
	var main: Node = null
	var map = null
	var seed_value := 0
	for s in range(1, 40):  # A map whose log survived generation (carving may break one)
		main = await _make_main(s)
		map = main.get_node("%MapGenerator")
		if map.environment_object_layer.log_cells.size() >= 3:
			seed_value = s
			break
		main.free()
	_check(seed_value > 0, "a log map")
	if seed_value == 0:
		quit(failures)
		return
	var env: TileMapLayer = map.environment_object_layer
	var log: Array[Vector2] = env.log_cells.duplicate()
	var data: ObstacleData = map.get_obstacle(log[0])
	_check(log.all(func(c: Vector2) -> bool: return map.get_obstacle(c) == data) and data.display_name == "Fallen Log",
		"one Fallen Log over %d cells" % log.size())
	var pieces: Array = log.map(func(c: Vector2) -> int: return env.get_cell_atlas_coords(Vector2i(c)).x)
	pieces.sort()
	var vertical := log[0].x == log[1].x
	var first := 3 if vertical else 0
	_check(env.get_cell_source_id(Vector2i(log[0])) == EnvironmentTiles.FALLEN_LOG and pieces[0] == first
		and pieces[-1] == first + 2 and pieces.slice(1, -1).all(func(p: int) -> bool: return p == first + 1),
		"end, middle(s), end pieces (%s)" % [pieces])
	_check(map.get_obstacle_cells(log[1]).size() == log.size(), "any cell of it is the whole log")

	# Cost: a tree's per cell, one clear.
	var clearer: ObstacleClearer = main.get_node("%ObstacleClearer")
	var run_state: RunState = main.get_node("%RunState")
	main.get_node("%DreamState").clearing_open = true
	run_state.dew = 10000
	var cost := clearer.get_next_clear_cost_at(log[1])
	_check(cost == TREE.clear_cost * log.size(), "cost = %d per cell × %d = %d" % [TREE.clear_cost, log.size(), cost])
	var preview: PackedVector2Array = map.get_path_if_cleared(log[1])
	var tended := run_state.obstacles_tended
	var clears := run_state.tended_cells.size()
	_check(clearer.try_clear(log[1]) and run_state.dew == 10000 - cost, "one Tend pays for the whole log")
	_check(log.all(func(c: Vector2) -> bool: return map.get_obstacle(c) == null and not map.path_layer.is_cell_blocked(c)),
		"every cell is cleared")
	_check(run_state.obstacles_tended == tended + 1 and run_state.tended_cells.size() == clears + 1, "it counts as one clear (one Seed)")
	var furrow: Array = log.map(func(c: Vector2) -> int: return env.get_cell_atlas_coords(Vector2i(c)).x if env.get_cell_source_id(Vector2i(c)) == EnvironmentTiles.LOG_FURROW else -1)
	furrow.sort()
	_check(furrow == pieces, "a furrow on every cell, piece for piece (%s)" % [furrow])
	_check(map.get_path_from(map.startPath) == preview, "the hover preview was the route it opened")
	var tended_cells: Array[Vector2] = run_state.tended_cells.duplicate()
	main.free()

	# The save restores it whole (RunSaver removes each tended cell).
	main = await _make_main(seed_value)
	map = main.get_node("%MapGenerator")
	for cell in tended_cells:
		map._remove_obstacle(cell)
	_check(log.all(func(c: Vector2) -> bool: return map.get_obstacle(c) == null), "resumed: the whole log stays cleared")
	main.free()

	# Heartwood's Reach: one half-price charge covers the whole log.
	main = await _make_main(seed_value)
	map = main.get_node("%MapGenerator")
	clearer = main.get_node("%ObstacleClearer")
	run_state = main.get_node("%RunState")
	main.get_node("%DreamState").clearing_open = true
	run_state.dew = 10000
	run_state.add_free_clears(1)
	cost = clearer.get_next_clear_cost_at(log[0])
	_check(cost == ceili(TREE.clear_cost * log.size() / 2.0), "half price for the whole log (%d)" % cost)
	_check(clearer.try_clear(log[0]) and run_state.free_clears == 0 and map.get_obstacle(log[2]) == null, "one charge, whole log")
	main.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("test_fallen_log: %d failure(s)" % failures)
	quit(failures)

func _make_main(map_seed: int) -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	var map = main.get_node("MapGenerator")
	map.map_seed = map_seed
	map.force_feature = MapLayout.Feature.LOG
	root.add_child(main)
	await process_frame
	return main
