extends SceneTree
# Route cost on crazy mazes (environment_assets.md "Room to maze", maze_feel.md change 5): a serpentine
# and a spiral of half-offset Thornwalls on an emptied map, 150 nightmares walking them. Times:
# - the straightest-route search (the drawn route; also on a synthetic 800+-half-step serpentine),
# - a ghost hover on a new cell (can_block_halves + the drawn-route preview, uncached),
# - one placement after its hover (block, route, every walker re-routed, dual redraw, the Warden itself),
#   and one with no hover first,
# - a drag line of 10 walls: the drag (a stroke plan per cell) and planting it (TowerPlacer.plant_stroke),
#   counting route updates (one at the end is the goal: MapGenerator.hold_route / release_route),
# at 1× and while paused. Budget: placement 10 ms (one frame), hover 4 ms; fails over 2× budget.
# Run:  Godot --headless --path . --script res://tests/test_maze_perf.gd --fixed-fps 60

const WALKERS := 150
const PLACE_BUDGET_MS := 10.0  # A placement fits in one frame (Environment Discussion, 2026-10-05)
const HOVER_BUDGET_MS := 4.0
const REPEATS := 5

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_maze_perf_%d.json" % OS.get_process_id()
	_synthetic()
	for shape in ["serpentine", "spiral"]:
		await _maze(shape)
	print("maze perf test: %d failure(s)" % failures)
	quit(failures)

# FindPath alone on a bigger grid (32×20 cells): a serpentine 800+ half steps long.
func _synthetic() -> void:
	var grid := Grid.new()
	grid.size = Vector2(32, 20)
	grid.cell_size = Vector2(64, 64)
	var cells: Array = []
	for x in 32:
		for y in 20:
			cells.append(Vector2(x, y))
	var finder := FindPath.new(grid, cells)
	var size := finder.size()
	for row in range(2, size.y - 1, 3):  # Wall rows 2 halves thick, 1-half corridors, gaps at alternating ends
		var gap_right := (row / 3) % 2 == 0
		for x in size.x:
			var in_gap := x >= size.x - 1 if gap_right else x <= 0
			if not in_gap:
				finder.set_half_blocked(Vector2(x, row), true)
				finder.set_half_blocked(Vector2(x, row + 1), true)
	var from := FindPath.node_to_point(Vector2i(0, 0))
	var to := FindPath.node_to_point(Vector2i(0, size.y - 1) if (size.y / 3) % 2 == 0 else Vector2i(size.x - 1, size.y - 1))
	var route := finder.straightest_point_path(from, to)
	var t := Time.get_ticks_usec()
	for i in REPEATS:
		finder._straightest_search(from, to)  # Uncached
	var straight_ms := (Time.get_ticks_usec() - t) / 1000.0 / REPEATS
	t = Time.get_ticks_usec()
	for i in REPEATS:
		finder.calculate_point_path(from, to)
	var astar_ms := (Time.get_ticks_usec() - t) / 1000.0 / REPEATS
	print("synthetic serpentine (64×40 halves): %d half steps; straightest %.2f ms, A* %.2f ms" % [route.size() - 1, straight_ms, astar_ms])
	_check(route.size() - 1 >= 600, "the synthetic serpentine is 600+ half steps (%d)" % (route.size() - 1))

func _maze(shape: String) -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	var map = main.get_node("MapGenerator")
	map.map_seed = 4242
	map.force_layout = MapLayout.Kind.CORNER
	map.force_short = 1  # A top or bottom start
	map.force_feature = MapLayout.Feature.GROVE  # No pond: everything can be cleared
	root.add_child(main)
	await process_frame
	map = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var spawner = main.get_node("%EnemyContainer")
	main.get_node("%RunState").dew = 10000000
	for cell in map.obstacles.keys():  # An open field
		map._remove_obstacle(cell, false)
	var size: Vector2i = map.path_layer.get_finder().size()
	var shape_data: Dictionary = _serpentine(size) if shape == "serpentine" else _spiral(size)
	# The maze's two ends: the start at the top-left rim, the Heartwood at the maze's far end (test only: the
	# goal cell moves, the Heartwood sprite stays).
	map.move_start(Vector2(1, 0))
	map.endPath = shape_data.goal
	map.path_layer.cell_end_path = shape_data.goal
	map.path_layer.draw()
	placer.tower_data = load("res://resource/tower/thornwall.tres")
	var slots: Array[Vector2] = shape_data.slots
	var line := _find_line(slots)
	var hole := Vector2(-1, -1)
	for i in range(slots.size() / 2, slots.size()):
		if not line.has(slots[i]):
			hole = slots[i]
			break
	var built := 0
	for origin in slots:
		if origin != hole and placer._try_build_half(origin):
			built += 1
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	print("%s: %d walls, route %d half steps" % [shape, built, route.size() - 1])
	# 150 walkers spread along the route, clear of the hole and the line
	var keep_clear: Array[Vector2] = FindPath.halves_of(hole)
	for origin in line:
		keep_clear.append_array(FindPath.halves_of(origin))
	var shade: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var spawned := 0
	for i in WALKERS:
		var k := int(float(i) / WALKERS * (route.size() - 2))
		while k < route.size() - 2 and _near_halves(route[k], keep_clear):
			k += 1  # A walker there would refuse the wall
		var e: Node2D = spawner.spawn_enemy(shade)
		if e == null:
			continue
		e.unkillable = true
		e.position = map.MAP_GRID.calculate_map_position(route[k])
		e.set_path(route.slice(k))
		spawned += 1
	_check(spawned == WALKERS, "%s: %d walkers" % [shape, spawned])
	_sell(placer, seller, line)  # The drag line refills it
	await process_frame
	var hole_halves: Array[Vector2] = FindPath.halves_of(hole)
	var finder: FindPath = map.path_layer.get_finder()
	for paused in [false, true]:
		root.get_tree().paused = paused
		var label := "%s %s" % [shape, "paused" if paused else "1x"]
		# The straightest search, uncached
		var t := Time.get_ticks_usec()
		for i in REPEATS:
			finder._straightest_search(map.startPath, map.endPath)
		var straight_ms := (Time.get_ticks_usec() - t) / 1000.0 / REPEATS
		# Hover on a new cell (the hole), uncached: the drawn-route preview and the path rule over every walker
		# (walkers with a way out: MapGenerator.has_route_from, as TowerPlacer._walker_cells asks)
		t = Time.get_ticks_usec()
		for i in REPEATS:
			finder._straight_key = []
			finder._reach_key = []
			map.can_block_halves(hole_halves, _walker_points(map, spawner))
			map.get_path_if_blocked_halves(hole_halves, true)
		var hover_ms := (Time.get_ticks_usec() - t) / 1000.0 / REPEATS
		# A placement after its hover (the real flow), and one cold; sold again between tries
		var place_ms := 0.0
		var cold_ms := 0.0
		var placed := 0
		for i in REPEATS:
			finder._straight_key = []
			var hovered := i % 2 == 0
			if hovered:
				map.get_path_if_blocked_halves(hole_halves, true)
			t = Time.get_ticks_usec()
			var ok := placer._try_build_half(hole)
			var ms := (Time.get_ticks_usec() - t) / 1000.0
			if hovered:
				place_ms += ms
			else:
				cold_ms += ms
			if ok:
				placed += 1
				_sell(placer, seller, [hole])
			await process_frame
		place_ms /= ceilf(REPEATS / 2.0)
		cold_ms /= floorf(REPEATS / 2.0)
		_check(placed == REPEATS, "%s: the hole takes a wall (%d of %d; %s)" % [label, placed, REPEATS, map.block_refusal()])
		# A drag line of 10 walls: the drag (a plan per cell), then planting it
		var updates := [0]
		var count := func() -> void: updates[0] += 1
		t = Time.get_ticks_usec()
		placer.begin_stroke_half(line[0])
		for origin in line.slice(1):
			placer.extend_stroke(origin)
		var drag_ms := (Time.get_ticks_usec() - t) / 1000.0
		map.path_changed.connect(count)
		t = Time.get_ticks_usec()
		var line_built := placer.plant_stroke()
		var plant_ms := (Time.get_ticks_usec() - t) / 1000.0
		map.path_changed.disconnect(count)
		_check(line_built == line.size(), "%s: the drag line plants all %d walls (%d)" % [label, line.size(), line_built])
		_sell(placer, seller, line)  # Out again for the next pass
		await process_frame
		print("  %s: straightest %.2f ms · hover %.2f ms · placement %.2f ms (no hover first %.2f) · drag of 10 %.2f ms, planting it %.2f ms (%d route updates)" % [
			label, straight_ms, hover_ms, place_ms, cold_ms, drag_ms, plant_ms, updates[0]])
		_check(hover_ms <= HOVER_BUDGET_MS * 2.0, "%s: hover %.2f ms (budget %.0f, fail over %.0f)" % [label, hover_ms, HOVER_BUDGET_MS, HOVER_BUDGET_MS * 2])
		_check(place_ms <= PLACE_BUDGET_MS * 2.0, "%s: placement %.2f ms (budget %.0f, fail over %.0f)" % [label, place_ms, PLACE_BUDGET_MS, PLACE_BUDGET_MS * 2])
	root.get_tree().paused = false
	main.free()
	await process_frame

func _walker_points(map: Node, spawner: Node) -> PackedVector2Array:
	var points := PackedVector2Array()
	for enemy in spawner.get_maze_walkers():
		if map.has_route_from(enemy.get_target_cell()):
			points.append(enemy.get_target_cell())
	return points

func _sell(placer: TowerPlacer, seller: TowerSeller, origins: Array) -> void:
	for tw in placer.tower_container.get_children():
		if tw is Tower and not tw.is_queued_for_deletion() and origins.has(tw.half_cell):
			seller.sell(tw.cell)

# Wall rows 2 halves thick with 1-half corridors, the gap at alternating ends; the goal at the far end of
# the last corridor (cell row 16).
func _serpentine(size: Vector2i) -> Dictionary:
	var slots: Array[Vector2] = []
	var row := 0
	for y in range(3, size.y - 5, 3):  # Rows 3..30
		var gap_right := row % 2 == 0
		var x0 := 2 if gap_right else 4
		var x1 := size.x - 6 if gap_right else size.x - 4
		for x in range(x0, x1 + 1, 2):
			slots.append(Vector2(x, y))
		row += 1
	return {slots = slots, goal = Vector2(20, 16)}

# Square rings 4 halves apart (2-half walls, 2-half corridors). Each ring's gap is on its top side, and a
# spoke in the corridor inside it sits just past the gap, so the way in goes all round the corridor to the
# next ring's gap. The goal is in the middle.
func _spiral(size: Vector2i) -> Dictionary:
	var slots: Array[Vector2] = []
	var lo := 4
	var hi := Vector2i(size.x - 6, size.y - 6)  # Top-left halves of the last slot on the right / bottom side
	var rings: Array[int] = []
	while hi.x - lo >= 8 and hi.y - lo >= 8:
		rings.append(lo)
		lo += 4
		hi -= Vector2i(4, 4)
	hi = Vector2i(size.x - 6, size.y - 6)
	for i in rings.size():
		var l := rings[i]
		for x in range(l, hi.x + 1, 2):  # Top side first: one row of slots (the drag line comes from here)
			if x != l + 4:  # The gap
				slots.append(Vector2(x, l))
		for x in range(l, hi.x + 1, 2):
			slots.append(Vector2(x, hi.y))
		for y in range(l + 2, hi.y - 1, 2):
			slots.append(Vector2(l, y))
			slots.append(Vector2(hi.x, y))
		if i < rings.size() - 1:
			slots.append(Vector2(l + 6, l + 2))  # The spoke, in this ring's corridor just past its gap
		hi -= Vector2i(4, 4)
	var last: int = rings.back()
	var middle := (Vector2(last + 2, last + 2) + Vector2(hi + Vector2i(4, 4)) - Vector2.ONE) / 2.0
	return {slots = slots, goal = (middle / 2.0).floor()}

# 10 slots in a row, side by side (a drag line), away from the maze's ends.
func _find_line(slots: Array[Vector2]) -> Array[Vector2]:
	for i in range(1, slots.size() - 10):
		var run: Array[Vector2] = slots.slice(i, i + 10)
		var ok := true
		for j in range(1, run.size()):
			if run[j] != run[j - 1] + Vector2(2, 0):
				ok = false
		if ok:
			return run
	return []

# Within 3 halves (chessboard) of any of `halves`: walkers keep clear, as they will have moved on a little.
func _near_halves(point: Vector2, halves: Array[Vector2]) -> bool:
	var node := Vector2(FindPath.point_to_node(point))
	for h in halves:
		if absf(h.x - node.x) <= 3 and absf(h.y - node.y) <= 3:
			return true
	return false

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
