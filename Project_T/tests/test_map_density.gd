extends SceneTree
# Map generation over many seeds (game_design.md "The forest (map)", environment_assets.md "Map
# layouts"): the player's Wardens build most of the maze, not the map, and every layout plays alike.
# - Random layouts at Blight 0 and 9: obstacle and ridge ranges, at least MIN_OBSTACLES (the clearing
#   Dream cards need 8+), at most MAX_RIDGES (+1 at Blight 9), a route that bends.
# - Each layout forced over LAYOUT_SEEDS seeds: starting route length and buildable cells stay within
#   ±25% of the medians before layouts existed (LENGTH_MEDIAN, BUILDABLE_MEDIAN), and the route bends.
# - Each feature forced: it's placed, keeps its distance from the start and end, ponds block without
#   being obstacles, ruins are stone obstacles.
# Run:  Godot --headless --path . --script res://tests/test_map_density.gd --fixed-fps 60

const SEEDS := 50
const LAYOUT_SEEDS := 20
const MIN_OBSTACLES := 10
const MAX_RIDGES := 3  # +1 at Blight 9 (as many as fit between the start and the Heartwood)
const LENGTH_MEDIAN := 46  # Corner-to-corner maps before layouts (50 seeds, 2026-10-01)
const BUILDABLE_MEDIAN := 275
const BAND := 0.25
const OBSTACLE_BUDGET := Vector2i(44, 88)  # A layout's median obstacle count stays in here

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await _survey(0, MAX_RIDGES)
	MetaRun.blight_level = 9
	await _survey(9, MAX_RIDGES + 1)
	MetaRun.blight_level = 0
	for kind: Array in [[MapLayout.Kind.CORNER, -1], [MapLayout.Kind.SIDE, -1]]:  # Per start kind
		await _layout_case(kind[0], kind[1])
	for feature in MapLayout.FEATURE_NAMES.size():
		await _feature_case(feature)
	print("map density test: %d failure(s)" % failures)
	quit(failures)

func _make(seed_value: int, kind: int = -1, short: int = -1, feature: int = -1) -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	var map = main.get_node("MapGenerator")
	map.map_seed = seed_value
	map.force_layout = kind
	map.force_short = short
	map.force_feature = feature
	root.add_child(main)
	await process_frame
	return main

func _survey(blight: int, max_ridges: int) -> void:
	var counts: Array[int] = []
	var ridges: Array[int] = []
	var kinds := {}
	for seed_value in range(1, SEEDS + 1):
		var main := await _make(seed_value)
		var map = main.get_node("%MapGenerator")
		var env = main.get_node("%EnvironmentObjectTileMapLayer")
		counts.append(map.obstacles.size())
		ridges.append(env.ridge_count)
		kinds[map.layout.get_kind_name()] = kinds.get(map.layout.get_kind_name(), 0) + 1
		_check(map.obstacles.size() >= MIN_OBSTACLES, "blight %d seed %d: %d obstacles (min %d)" % [
			blight, seed_value, map.obstacles.size(), MIN_OBSTACLES])
		_check(env.ridge_count <= max_ridges, "blight %d seed %d: %d ridges (max %d)" % [
			blight, seed_value, env.ridge_count, max_ridges])
		_check(not map.get_path_from(map.startPath).is_empty(), "blight %d seed %d: a route exists" % [blight, seed_value])
		_check(_bends(map), "blight %d seed %d (%s): the route bends" % [blight, seed_value, map.layout.describe()])
		_check_heartwood(map, env, "blight %d seed %d" % [blight, seed_value])
		main.free()
	var total := 0
	for c in counts:
		total += c
	print("Blight %d over %d seeds: obstacles %d-%d (mean %.1f), ridges %d-%d, layouts %s" % [blight, SEEDS,
		counts.min(), counts.max(), float(total) / SEEDS, ridges.min(), ridges.max(), kinds])

# One layout over LAYOUT_SEEDS seeds: every map's starting route and buildable cells stay in the band.
func _layout_case(kind: int, short: int) -> void:
	var lengths: Array[int] = []
	var buildable: Array[int] = []
	var counts: Array[int] = []
	var name := ""
	for seed_value in range(1, LAYOUT_SEEDS + 1):
		var main := await _make(seed_value, kind, short)
		var map = main.get_node("%MapGenerator")
		name = map.layout.get_kind_name()
		var length: int = map.get_path_from(map.startPath).size()
		var cells := 0
		for x in int(map.MAP_GRID.size.x):
			for y in int(map.MAP_GRID.size.y):
				if map.is_buildable(Vector2(x, y)):
					cells += 1
		lengths.append(length)
		buildable.append(cells)
		counts.append(map.obstacles.size())
		_check(_in_band(length, LENGTH_MEDIAN), "%s seed %d: route %d cells (band %d-%d)" % [name, seed_value, length,
			roundi(LENGTH_MEDIAN * (1 - BAND)), roundi(LENGTH_MEDIAN * (1 + BAND))])
		_check(_in_band(cells, BUILDABLE_MEDIAN), "%s seed %d: %d buildable cells (band %d-%d)" % [name, seed_value,
			cells, roundi(BUILDABLE_MEDIAN * (1 - BAND)), roundi(BUILDABLE_MEDIAN * (1 + BAND))])
		_check(_bends(map), "%s seed %d: the route bends" % [name, seed_value])
		_check(map.obstacles.size() >= MIN_OBSTACLES, "%s seed %d: at least %d obstacles" % [name, seed_value, MIN_OBSTACLES])
		main.free()
	lengths.sort()
	buildable.sort()
	counts.sort()
	var median: int = counts[counts.size() / 2]
	_check(median >= OBSTACLE_BUDGET.x and median <= OBSTACLE_BUDGET.y, "%s: median %d obstacles (budget %d-%d)" % [
		name, median, OBSTACLE_BUDGET.x, OBSTACLE_BUDGET.y])
	print("  %s: route %d-%d (median %d), buildable %d-%d (median %d), obstacles %d-%d (median %d)" % [name,
		lengths[0], lengths[-1], lengths[lengths.size() / 2], buildable[0], buildable[-1], buildable[buildable.size() / 2],
		counts[0], counts[-1], median])

# One feature over a few seeds: placed, clear of the start and end, and of the right kind.
func _feature_case(feature: int) -> void:
	var placed := 0
	var near_route := 0
	var shortcuts := 0  # Log: Tending it shortens the route
	var corners := 0
	for seed_value in range(1, 9):
		var main := await _make(seed_value, -1, -1, feature)
		var map = main.get_node("%MapGenerator")
		var env = main.get_node("%EnvironmentObjectTileMapLayer")
		var cells: Array[Vector2] = env.feature_cells
		if not cells.is_empty():
			placed += 1
		for cell in cells:
			var far: int = env.feature_clearance
			_check(maxf(absf(cell.x - map.startPath.x), absf(cell.y - map.startPath.y)) >= far
				and maxf(absf(cell.x - map.endPath.x), absf(cell.y - map.endPath.y)) >= far,
				"%s seed %d: feature cell %s keeps clear of the start and end" % [MapLayout.FEATURE_NAMES[feature], seed_value, cell])
			if feature == MapLayout.Feature.POND:
				corners += env.pond_corners.filter(func(c: Array) -> bool: return c[0] == cell).size()
			if feature == MapLayout.Feature.POND:
				_check(not map.obstacles.has(cell) and not map.is_buildable(cell)
					and map.path_layer.is_cell_blocked(cell), "pond seed %d: %s blocks but isn't an obstacle" % [seed_value, cell])
			else:
				_check(map.obstacles.has(cell), "%s seed %d: %s is an obstacle" % [MapLayout.FEATURE_NAMES[feature], seed_value, cell])
			if feature == MapLayout.Feature.RUIN:
				_check(map.obstacles.get(cell) == env.rock_obstacle, "ruin seed %d: %s is stone (Move)" % [seed_value, cell])
		_check(not map.get_path_from(map.startPath).is_empty(), "%s seed %d: a route exists" % [MapLayout.FEATURE_NAMES[feature], seed_value])
		if (feature == MapLayout.Feature.LOG and env.log_cells.size() > 0
				and map.get_path_if_cleared(env.log_cells[0]).size() < map.get_path_from(map.startPath).size()):
			shortcuts += 1
		if feature != MapLayout.Feature.GROVE:  # Pond, ruin and log shape the opening
			var route: PackedVector2Array = map.get_path_from(map.startPath)
			var close := false
			for cell in cells:
				for r in route:
					if maxf(absf(cell.x - r.x), absf(cell.y - r.y)) <= 2:
						close = true
			if close:
				near_route += 1
		main.free()
	_check(placed >= 6, "%s placed on %d of 8 seeds" % [MapLayout.FEATURE_NAMES[feature], placed])
	if feature == MapLayout.Feature.POND:
		print("  feature pond: %d inside corners over 8 seeds (non-rectangular ponds)" % corners)
	if feature != MapLayout.Feature.GROVE:
		_check(near_route >= 6, "%s within 2 cells of the opening route on %d of 8 seeds" % [MapLayout.FEATURE_NAMES[feature], near_route])
		print("  feature %s: near the opening route on %d of 8 seeds" % [MapLayout.FEATURE_NAMES[feature], near_route])
	if feature == MapLayout.Feature.LOG:
		_check(shortcuts >= 6, "Tending the log shortens the route on %d of 8 seeds" % shortcuts)
		print("  feature fallen log: Tending it is a shortcut on %d of 8 seeds" % shortcuts)
	print("  feature %s: placed on %d of 8 seeds" % [MapLayout.FEATURE_NAMES[feature], placed])

# The Heartwood (environment_assets.md "Inland Heartwood"): inland, in the half away from the start, at
# least half the diagonal from it (unless no cell is: then among the farthest), and its glade is clear.
func _check_heartwood(map: Node, env: Node, what: String) -> void:
	var h: Vector2 = map.endPath
	var size: Vector2 = map.MAP_GRID.size
	var margin := MapLayout.EDGE_MARGIN
	_check(h.x >= margin and h.y >= margin and h.x <= size.x - 1 - margin and h.y <= size.y - 1 - margin,
		"%s: the Heartwood %s is inland" % [what, h])
	var centre := (size - Vector2.ONE) / 2.0
	_check((h - centre).dot(centre - map.startPath) > 0.0, "%s: the Heartwood is in the far half" % what)
	_check(map.layout.heartwood_fallback or h.distance_to(map.startPath) >= size.length() * MapLayout.MIN_DISTANCE_SHARE,
		"%s: the Heartwood is far enough (%.1f)" % [what, h.distance_to(map.startPath)])
	for cell in map.get_glade_cells():
		_check(not map.obstacles.has(cell) and not env.pond_cells.has(cell) and not env.feature_cells.has(cell)
			and not env.ridge_cells.has(cell), "%s: glade cell %s is clear" % [what, cell])

# Longer than the straightest possible route: the maze makes the route turn back at least once.
func _bends(map: Node) -> bool:
	var straight := int(absf(map.endPath.x - map.startPath.x) + absf(map.endPath.y - map.startPath.y)) + 1
	return map.get_path_from(map.startPath).size() > straight

func _in_band(value: int, median: int) -> bool:
	return value >= median * (1.0 - BAND) and value <= median * (1.0 + BAND)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
