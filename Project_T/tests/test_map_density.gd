extends SceneTree
# Obstacle density over many seeds (game_design.md "The forest (map)": the player's Wardens build most
# of the maze, not the map). Prints the obstacle and ridge count ranges, and checks every map keeps
# at least MIN_OBSTACLES (the clearing Dream cards need 8+), at most 2 ridges (3 at Blight 9) and a
# route from start to end that bends at least once.
# Run:  Godot --headless --path . --script res://tests/test_map_density.gd --fixed-fps 60

const SEEDS := 50
const MIN_OBSTACLES := 10
const MAX_RIDGES := 2

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await _survey(0, MAX_RIDGES)
	MetaRun.blight_level = 9
	await _survey(9, MAX_RIDGES + 1)
	MetaRun.blight_level = 0
	print("map density test: %d failure(s)" % failures)
	quit(failures)

func _survey(blight: int, max_ridges: int) -> void:
	var counts: Array[int] = []
	var ridges: Array[int] = []
	for seed_value in range(1, SEEDS + 1):
		var main: Node = load("res://scenes/main.tscn").instantiate()
		main.get_node("MapGenerator").map_seed = seed_value
		root.add_child(main)
		await process_frame
		var map = main.get_node("%MapGenerator")
		var env = main.get_node("%EnvironmentObjectTileMapLayer")
		counts.append(map.obstacles.size())
		ridges.append(env.ridge_count)
		_check(map.obstacles.size() >= MIN_OBSTACLES, "blight %d seed %d: %d obstacles (min %d)" % [
			blight, seed_value, map.obstacles.size(), MIN_OBSTACLES])
		_check(env.ridge_count <= max_ridges, "blight %d seed %d: %d ridges (max %d)" % [
			blight, seed_value, env.ridge_count, max_ridges])
		_check(not map.get_path_from(map.startPath).is_empty(), "blight %d seed %d: a route exists" % [blight, seed_value])
		var straight := int(absf(map.endPath.x - map.startPath.x) + absf(map.endPath.y - map.startPath.y)) + 1
		_check(map.get_path_from(map.startPath).size() > straight, "blight %d seed %d: the route bends" % [blight, seed_value])
		main.free()
	var total := 0
	for c in counts:
		total += c
	print("Blight %d over %d seeds: obstacles %d-%d (mean %.1f), ridges %d-%d" % [blight, SEEDS,
		counts.min(), counts.max(), float(total) / SEEDS, ridges.min(), ridges.max()])

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
