extends SceneTree
# Map landmarks and the frame (environment_assets.md "Landmarks" / "Frame balance and the bend spur"; map_landmark.gd,
# enivornment_object_generator.gd):
# - every map has an Old Waystone (a buildable one-cell site, MapGenerator.landmark_kind / landmark_cell for Tower Code);
#   about 1 map in 3 also a Dew Pool (2 walkable cells nobody can build on, MapGenerator.dew_pool_cells for Enemy Code);
#   both in the bowl, MIN_GAP from the start and the Heartwood, off the glade, apart; neither moves the route.
# - every frame region (4 corners, 4 side middles) keeps its minimum of woods;
# - the bend spur sits 40–55% of the way from the start's row to the Heartwood's (within the RIDGE_END_GAP clamp).
# Run:  Godot --headless --path . --script res://tests/test_landmarks.gd --fixed-fps 60

const LANDMARK := preload("res://scripts/map/map_landmark.gd")
const SEEDS := [1207, 1, 2, 3, 4, 6, 7, 8, 9, 10]

var failures := 0

func _init() -> void:
	for map_seed in SEEDS:
		var plain := await _route_with(map_seed, 0)
		for pool in [0, 1]:
			var main := await _make(map_seed, pool)
			var map = main.get_node("%MapGenerator")
			var stone: Vector2 = map.landmark_cell
			_check(stone.x >= 0 and map.landmark_kind == &"waystone" and map.is_waystone(stone),
				"seed %d: an Old Waystone (%s)" % [map_seed, stone])
			_check(map.dew_pool_cells.size() == (2 if pool == 1 else 0), "seed %d: %d pool cells" % [map_seed, map.dew_pool_cells.size()])
			for cell in map.landmark_cells():
				_check(map.environment_object_layer.in_bowl(cell), "seed %d: %s in the bowl" % [map_seed, cell])
				_check(not map.get_glade_cells().has(cell) and not map.obstacles.has(cell), "seed %d: open ground" % map_seed)
				for at: Vector2 in [map.startPath, map.endPath]:
					_check(maxf(absf(cell.x - at.x), absf(cell.y - at.y)) >= LANDMARK.MIN_GAP,
						"seed %d: %s keeps %d cells from %s" % [map_seed, cell, LANDMARK.MIN_GAP, at])
				var on_pool: bool = map.dew_pool_cells.has(cell)
				_check(map.is_buildable(cell) == not on_pool and map.is_dew_pool(cell) == on_pool,
					"seed %d: the Waystone is built on, the Dew Pool never" % map_seed)
			for cell in map.dew_pool_cells:
				_check(maxf(absf(cell.x - stone.x), absf(cell.y - stone.y)) >= LANDMARK.APART, "seed %d: the pool keeps apart from the stone" % map_seed)
			_check(map.get_path_from(map.startPath) == plain, "seed %d: landmarks never move the route" % map_seed)
			if pool == 0:
				_check_frame(map, map_seed)
			main.free()
	# The pool's roll: about 1 map in 3 over 60 seeds, and the same seed always rolls the same.
	var pools := 0
	for map_seed in range(100, 160):
		var main := await _make(map_seed, -1)
		var has_pool: bool = not main.get_node("%MapGenerator").dew_pool_cells.is_empty()
		pools += 1 if has_pool else 0
		_check(main.get_node("%MapGenerator").landmark_kind == &"waystone", "seed %d has a Waystone" % map_seed)
		main.free()
		if map_seed < 104:
			var again := await _make(map_seed, -1)
			_check((not again.get_node("%MapGenerator").dew_pool_cells.is_empty()) == has_pool, "seed %d rolls the same pool again" % map_seed)
			again.free()
	print("Dew Pools on %d of 60 maps" % pools)
	_check(pools >= 10 and pools <= 32, "about 1 map in 3 has a Dew Pool (%d of 60)" % pools)
	print("test_landmarks: %d failure(s)" % failures)
	quit(failures)

# Every frame region keeps its minimum; the bend spur's row is 40–55% of the way to the Heartwood (or clamped).
func _check_frame(map, map_seed: int) -> void:
	var objects = map.environment_object_layer
	var counts := []
	for r in objects.REGION_COUNT:
		var n: int = objects.region_count(r, map.obstacles)
		counts.append(n)
		_check(n >= objects.region_minimum(r), "seed %d: frame region %d keeps its woods (%d of at least %d)" % [map_seed, r, n, objects.region_minimum(r)])
	var axis_v: int = objects._axis_u ^ 1  # The spurs' rows run across v
	var a: float = map.startPath[axis_v]
	var b: float = map.endPath[axis_v]
	var first: float = minf(a, b) + objects.RIDGE_END_GAP
	var last: float = maxf(a, b) - objects.RIDGE_END_GAP
	var bend_rows := {}
	for cell: Vector2 in objects.ridge_cells:
		bend_rows[int(cell[axis_v])] = true
	var lo := clampf(a + (b - a) * objects.BEND_SHARE.x, first, last)
	var hi := clampf(a + (b - a) * objects.BEND_SHARE.y, first, last)
	var near := false  # Some spur cell sits in the bend's band (its line wanders ±1 row)
	for v: int in bend_rows:
		near = near or (v >= minf(lo, hi) - 1.5 and v <= maxf(lo, hi) + 1.5)
	_check(last < first or near, "seed %d: the bend spur sits 40-55%% of the way from the start (rows %s, band %.1f-%.1f)" % [map_seed, bend_rows.keys(), minf(lo, hi), maxf(lo, hi)])
	print("  seed %d frame: %s" % [map_seed, counts])

func _make(map_seed: int, pool: int) -> Node:
	LANDMARK.force_pool = pool
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = map_seed
	root.add_child(main)
	await process_frame
	LANDMARK.force_pool = -1
	return main

func _route_with(map_seed: int, pool: int) -> PackedVector2Array:
	var main := await _make(map_seed, pool)
	var map = main.get_node("%MapGenerator")
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	main.free()
	return route

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
