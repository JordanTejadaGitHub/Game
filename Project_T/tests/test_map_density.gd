extends SceneTree
# Map generation over many seeds (game_design.md "The forest (map)", environment_assets.md "Map
# layouts" and "Room to maze"): an open build bowl the player's Wardens maze, the obstacles in the frame.
# - Random layouts at Blight 0 and 9: obstacles in OBSTACLES_BLIGHT_0 / _9 (at least MIN_OBSTACLES: the
#   clearing Dream cards need 8+), at most MAX_RIDGES spurs (+1 at Blight 9), BOWL_LOOSE lone obstacles in the
#   bowl, an opening route in ROUTE_RANGE that bends round the bend spur (>= Manhattan + MapLayout.BEND_EXTRA) on every map.
# - Each layout forced over LAYOUT_SEEDS seeds: route in ROUTE_RANGE and bent, the bowl open (buildable cells
#   at least BUILDABLE_MIN), the layout's median obstacle count in OBSTACLES_BLIGHT_0.
# - Each feature forced: it's placed, keeps its distance from the start and end, sits in the frame band or
#   straddles its inner edge, ponds block without being obstacles, ruins are stone obstacles.
# Run:  Godot --headless --path . --script res://tests/test_map_density.gd --fixed-fps 60

const SEEDS := 50
const LAYOUT_SEEDS := 20
const MIN_OBSTACLES := 12
const MAX_RIDGES := 2  # The bend spur + one short spur; +1 at Blight 9 (as many as fit)
const ROUTE_RANGE := Vector2i(24, 42)  # Opening route, full cells (Room to maze with the +10 bend, 2026-10-05; was ~46)
const ROUTE_MAX_BLIGHT_9 := 46  # Its extra spur can stretch the opening a little
const OBSTACLES_BLIGHT_0 := Vector2i(38, 48)  # User 2026-10-06: "a bit more obstacles" (was 30-42)
const OBSTACLES_BLIGHT_9 := Vector2i(38, 56)  # The extra spur is a deliberate step: less open floor
const BOWL_LOOSE := Vector2i(3, 6)  # Lone decision obstacles in the bowl (not spur or feature cells)
const BUILDABLE_MIN := 275  # ~291 median with 38-48 obstacles (was ~275 before the bowl opened)

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
		var band: Vector2i = OBSTACLES_BLIGHT_9 if blight >= 9 else OBSTACLES_BLIGHT_0
		_check(map.obstacles.size() >= maxi(MIN_OBSTACLES, band.x) and map.obstacles.size() <= band.y,
			"blight %d seed %d: %d obstacles (%d-%d)" % [blight, seed_value, map.obstacles.size(), band.x, band.y])
		var loose := _bowl_loose(map, env)
		_check(loose >= BOWL_LOOSE.x and loose <= BOWL_LOOSE.y, "blight %d seed %d: %d lone obstacles in the bowl (%d-%d)" % [
			blight, seed_value, loose, BOWL_LOOSE.x, BOWL_LOOSE.y])
		var length: int = map.route_length(map.get_path_from(map.startPath))
		var most := ROUTE_MAX_BLIGHT_9 if blight >= 9 else ROUTE_RANGE.y
		_check(length >= ROUTE_RANGE.x and length <= most, "blight %d seed %d: opening route %d cells (%d-%d)" % [
			blight, seed_value, length, ROUTE_RANGE.x, most])
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
		var length: int = map.route_length(map.get_path_from(map.startPath))  # Half cells: full-cell length
		var cells := 0
		for x in int(map.MAP_GRID.size.x):
			for y in int(map.MAP_GRID.size.y):
				if map.is_buildable(Vector2(x, y)):
					cells += 1
		lengths.append(length)
		buildable.append(cells)
		counts.append(map.obstacles.size())
		_check(length >= ROUTE_RANGE.x and length <= ROUTE_RANGE.y, "%s seed %d: route %d cells (%d-%d)" % [name,
			seed_value, length, ROUTE_RANGE.x, ROUTE_RANGE.y])
		_check(cells >= BUILDABLE_MIN, "%s seed %d: %d buildable cells (at least %d)" % [name, seed_value, cells, BUILDABLE_MIN])
		_check(_bends(map), "%s seed %d: the route bends" % [name, seed_value])
		_check(map.obstacles.size() >= MIN_OBSTACLES, "%s seed %d: at least %d obstacles" % [name, seed_value, MIN_OBSTACLES])
		main.free()
	lengths.sort()
	buildable.sort()
	counts.sort()
	var median: int = counts[counts.size() / 2]
	_check(median >= OBSTACLES_BLIGHT_0.x and median <= OBSTACLES_BLIGHT_0.y, "%s: median %d obstacles (%d-%d)" % [
		name, median, OBSTACLES_BLIGHT_0.x, OBSTACLES_BLIGHT_0.y])
	print("  %s: route %d-%d (median %d), buildable %d-%d (median %d), obstacles %d-%d (median %d)" % [name,
		lengths[0], lengths[-1], lengths[lengths.size() / 2], buildable[0], buildable[-1], buildable[buildable.size() / 2],
		counts[0], counts[-1], median])

# One feature over a few seeds: placed, clear of the start and end, and of the right kind.
func _feature_case(feature: int) -> void:
	var placed := 0
	var near_route := 0
	var band_routes := 0  # Seeds whose opening route runs through the frame band
	var placed_near := 0  # Placed by a near-the-route try (the generator's rule; the drawn route may take another tie)
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
		_check(cells.is_empty() or (cells.any(env.in_band) and cells.all(func(c: Vector2) -> bool: return not env._deep_in_bowl(c))),
			"%s seed %d: in the frame band or straddling its inner edge" % [MapLayout.FEATURE_NAMES[feature], seed_value])
		if feature != MapLayout.Feature.GROVE:  # Pond, ruin and log shape the opening where the route runs through the band
			var route: PackedVector2Array = map.get_path_from(map.startPath)
			var close := false
			var in_band := false
			for cell in cells:
				for r in route:
					var rc := Vector2(FindPath.point_to_node(r) / 2)  # The route point's whole cell
					if not env.in_band(rc):
						continue
					in_band = true
					if maxf(absf(cell.x - rc.x), absf(cell.y - rc.y)) <= 2:
						close = true
			if env.feature_near_route:
				placed_near += 1
			if in_band:
				band_routes += 1
			if close:
				near_route += 1
		main.free()
	_check(placed >= 6, "%s placed on %d of 8 seeds" % [MapLayout.FEATURE_NAMES[feature], placed])
	if feature == MapLayout.Feature.POND:
		print("  feature pond: %d inside corners over 8 seeds (non-rectangular ponds)" % corners)
	if feature != MapLayout.Feature.GROVE:
		_check(placed_near >= 6, "%s placed near the route's band stretch on %d of 8 seeds" % [MapLayout.FEATURE_NAMES[feature], placed_near])
		print("  feature %s: placed near the band route on %d of 8; the drawn route passes within 2 on %d (in an open bowl it may take another of the equal routes)" % [MapLayout.FEATURE_NAMES[feature], placed_near, near_route])
	if feature == MapLayout.Feature.LOG:
		_check(shortcuts >= 4, "Tending the log shortens the route on %d of 8 seeds" % shortcuts)  # Open bowl: the drawn route can skirt a log it was laid across
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

# The opening route bends round the bend spur: at least the start→Heartwood Manhattan distance + MapLayout.BEND_EXTRA.
func _bends(map: Node) -> bool:
	return map.route_length(map.get_path_from(map.startPath)) >= map.min_route_length

# Obstacles in the open bowl that aren't a spur or the feature: the lone decision obstacles.
func _bowl_loose(map: Node, env: Node) -> int:
	var n := 0
	for cell: Vector2 in map.obstacles:
		if env.in_bowl(cell) and not env.ridge_cells.has(cell) and not env.feature_cells.has(cell) \
				and not env.stray_cells.has(cell) and cell != env.ruin_tree:  # Not the spur's strays or the Ruin's tree
			n += 1
	return n

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
