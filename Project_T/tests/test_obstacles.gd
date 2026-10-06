extends SceneTree

# Headless obstacle test. Run from the project folder:
#   godot --headless --path . --script res://tests/test_obstacles.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	# --- Generation: random per seed, reproducible, always a route ---
	var main := await _make_main(1234)
	var map = main.get_node("%MapGenerator")
	var obstacles_a: Dictionary = map.obstacles.duplicate()
	var kinds := {}
	for data in obstacles_a.values():
		kinds[data.display_name] = true
	_check(kinds.has("Withered Tree") and kinds.has("Mossy Boulder"), "map has both trees and boulders (%s)" % [kinds.keys()])
	_check_route(map, "seed 1234")
	_check(not map.obstacles.has(map.startPath) and not map.obstacles.has(map.endPath), "start and end stay clear")
	main.free()

	main = await _make_main(1234)
	_check(main.get_node("%MapGenerator").obstacles.keys() == obstacles_a.keys(), "same seed reproduces the map")
	main.free()

	main = await _make_main(98765)
	_check(main.get_node("%MapGenerator").obstacles.keys() != obstacles_a.keys(), "different seeds give different maps")
	main.free()

	for seed_value in range(1, 16):
		main = await _make_main(seed_value)
		map = main.get_node("%MapGenerator")
		_check_route(map, "seed %d" % seed_value)
		# The starting route bends at least once (game_design.md "The forest (map)": one gap-free ridge),
		# so it's longer than a straight corner-to-corner line.
		var straight := int(absf(map.endPath.x - map.startPath.x) + absf(map.endPath.y - map.startPath.y)) + 1
		var length: int = map.get_path_from(map.startPath).size()
		_check(length > straight, "seed %d: route bends (%d cells vs %d straight)" % [seed_value, length, straight])
		var env = main.get_node("%EnvironmentObjectTileMapLayer")
		var broken := 0
		for cell in env.ridge_cells:
			if not map.obstacles.has(cell):
				broken += 1
		_check(broken == 0, "seed %d: generation keeps ridges intact (%d broken)" % [seed_value, broken])
		main.free()

	# Rocks almost everywhere: the generator must carve a route through.
	main = await _make_main(42, 0.7)
	map = main.get_node("%MapGenerator")
	var inner_cells := int((map.MAP_GRID.size.x - 2) * (map.MAP_GRID.size.y - 2))
	_check(map.obstacles.size() > inner_cells / 3, "dense map really is dense (%d of %d cells)" % [map.obstacles.size(), inner_cells])
	_check_route(map, "dense map")
	main.free()

	# --- Clearing opens a shortcut and creatures re-route ---
	var found := false
	for seed_value in range(1, 30):
		main = await _make_main(seed_value)
		map = main.get_node("%MapGenerator")
		var clearer: ObstacleClearer = main.get_node("%ObstacleClearer")
		main.get_node("%DreamState").clearing_open = true  # Normally a clearing Dream unlocks clearing
		var before: PackedVector2Array = map.get_path_from(map.startPath)
		var shortcut := Vector2(-1, -1)
		for cell in map.obstacles:
			if map.get_path_if_cleared(cell).size() < before.size():
				shortcut = cell
				break
		if shortcut == Vector2(-1, -1):
			main.free()
			continue
		found = true
		var events := []
		map.path_changed.connect(func() -> void: events.append("path_changed"))
		map.obstacle_cleared.connect(func(cell: Vector2, _data: ObstacleData) -> void: events.append(cell))
		var preview: PackedVector2Array = map.get_path_if_cleared(shortcut, true)  # The hover preview: as it will be drawn
		_check(clearer.try_clear(shortcut), "clearing an obstacle succeeds")
		_check(not map.obstacles.has(shortcut), "cleared obstacle is gone")
		_check(events == [shortcut, "path_changed"], "clearing emits obstacle_cleared then path_changed")
		var after: PackedVector2Array = map.get_path_from(map.startPath)
		_check(after.size() < before.size() and after == preview, "route takes the shortcut the preview showed")
		_check(map.is_buildable(shortcut), "cleared cell can be built on")
		_check(not clearer.try_clear(shortcut), "can't clear the same cell twice")
		_check(not clearer.try_clear(map.startPath), "can't clear a cell without an obstacle")
		main.free()
		break
	_check(found, "found an obstacle whose removal shortens the route")

	print("obstacle test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _make_main(map_seed: int, rock_chance: float = -1.0) -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = map_seed
	if rock_chance >= 0.0:
		main.get_node("%EnvironmentObjectTileMapLayer").rock_chance = rock_chance
	root.add_child(main)
	await process_frame
	return main

func _check_route(map, label: String) -> void:
	var path: PackedVector2Array = map.get_path_from(map.startPath)
	_check(not path.is_empty(), "%s: start can reach the end" % label)
	for cell in path:
		if map.obstacles.has(cell):
			_check(false, "%s: route never passes through an obstacle" % label)
			return

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
