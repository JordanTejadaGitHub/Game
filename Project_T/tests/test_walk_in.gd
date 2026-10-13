extends SceneTree
# The way in ends on the route (user 2026-10-12: nightmares crossed the bridge, ran to the start cell's centre, then
# ran back a bit before following the path). For a north, south, east and west start: StartGate.walk_in is one straight
# line that ends on the route's first point; a nightmare's entry ends exactly there; and from then on its distance to
# the route's second point only ever shrinks (no step back).
# Run:  Godot --headless --path . --script res://tests/test_walk_in.gd --fixed-fps 60

const SEEDS := 24  # Seeds tried until every side has had a start
const STEP := 1.0 / 60.0

var failures := 0

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_walk_in_profile_%d.json" % OS.get_process_id()
	RunSaver.file_path = "user://test_walk_in_run_%d.json" % OS.get_process_id()
	var seen := {}
	for map_seed in range(1, SEEDS + 1):
		if seen.size() == 4:
			break
		var main: Node = load("res://scenes/main.tscn").instantiate()
		main.get_node("MapGenerator").map_seed = map_seed
		root.add_child(main)
		await process_frame
		var map = main.get_node("%MapGenerator")
		var side := StartGate.outward(Vector2i(map.startPath))
		if not seen.has(side):
			seen[side] = true
			_side_case(main, map, "seed %d, start %s going %s" % [map_seed, map.startPath, side], false)
			_side_case(main, map, "seed %d, start %s going %s, walled" % [map_seed, map.startPath, side], true)
		main.free()
		await process_frame
	_check(seen.size() == 4, "a start on every side within %d seeds (%d)" % [SEEDS, seen.size()])
	print("test_walk_in: %d failure(s)" % failures)
	quit(failures)

func _side_case(main: Node, map: Node, label: String, walled: bool) -> void:
	var spawner = main.get_node("%EnemyContainer")
	var lane_before: float = map.start_gate.lane
	if walled:  # The user's screenshot: Wardens wall the direct way in, the route is forced along the island's edge
		var inward: Vector2 = map.startPath - Vector2(StartGate.outward(Vector2i(map.startPath)))
		var side_step := Vector2(absf(inward.y - map.startPath.y), absf(inward.x - map.startPath.x))
		var blocked := 0
		for cell: Vector2 in [inward, inward + side_step, inward - side_step, map.startPath + side_step]:
			if map.can_block(cell):
				map.block_cell(cell)
				blocked += 1
		_check(blocked >= 2, "%s: Wardens wall the way in (%d)" % [label, blocked])
		map.start_gate._process(0.0)
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	_check(route.size() >= 3, "%s: a route" % label)
	if route.size() < 3:
		return
	# The route begins on the map's fixed start half (the start cell's outer half on the bridge's lane) and never comes
	# back to the start cell, or turns straight back on itself, once it has left
	var half: Vector2i = map.path_layer.start_half
	var out_i := StartGate.outward(Vector2i(map.startPath))
	_check(half == StartGate.start_half_for(Vector2i(map.startPath), map.endPath) and route[0] == FindPath.node_to_point(half)
		and Vector2((Vector2(half) / 2.0).floor()) == map.startPath
		and not map.path_layer.get_finder().is_walkable(FindPath.node_to_point(half + out_i)),
		"%s: the route begins on the start's outer half (%s, route %s)" % [label, half, route[0]])
	_check(is_equal_approx(map.start_gate.lane, lane_before) and absf(map.start_gate.lane) == 16.0,
		"%s: the bridge keeps its lane (%s, was %s)" % [label, map.start_gate.lane, lane_before])
	_check(not map.is_buildable_half(Vector2(half)), "%s: the start half can't be built on" % label)
	var left_start := false
	for i in route.size():
		var cell := (Vector2(FindPath.point_to_node(route[i])) / 2.0).floor()
		if cell != map.startPath:
			left_start = true
		elif left_start:
			_check(false, "%s: the route comes back to the start cell (point %d, %s)" % [label, i, route[i]])
			break
		if i >= 2 and (route[i] - route[i - 1]).is_equal_approx(route[i - 2] - route[i - 1]):
			_check(false, "%s: the route doubles back (point %d, %s)" % [label, i, route[i]])
			break
	_check(map.path_layer.path_halves().has(half), "%s: the drawn path starts on that half" % label)
	var first: Vector2 = map.MAP_GRID.calculate_map_position(route[0])
	var second: Vector2 = map.MAP_GRID.calculate_map_position(route[1])
	var walk: PackedVector2Array = map.start_gate.walk_in()
	var out := Vector2(StartGate.outward(Vector2i(map.startPath)))
	_check(walk.size() == 3 and walk[2] == first, "%s: the way in ends on the route's first point (%s, route %s)" % [label, walk, first])
	if walk.size() != 3:
		return
	_check(is_zero_approx((walk[1] - walk[0]).cross(walk[2] - walk[1])) and (walk[2] - walk[0]).normalized().is_equal_approx(-out),
		"%s: one straight line in from the fog" % label)
	_check(is_equal_approx((walk[1] - map.start_gate.position).dot(out), map.MAP_GRID.cell_size.x / 2.0), "%s: the landing is on the island's edge" % label)
	# Both lanes: a route beginning on either half across the start cell, and on either half along it
	var centre: Vector2 = map.start_gate.position
	for shift: Vector2 in [Vector2(16, 16), Vector2(-16, 16), Vector2(16, -16), Vector2(-16, -16)]:
		var lane := StartGate.walk_in_to(Vector2i(map.startPath), centre + shift)
		_check(lane[2] == centre + shift and is_zero_approx((lane[1] - lane[0]).cross(lane[2] - lane[1]))
			and (lane[2] - lane[0]).dot(-out) > 0.0 and (lane[2] - lane[1]).dot(-out) > 0.0,
			"%s: a route starting %s off the centre: straight in, never back (%s)" % [label, shift, lane])
	# A nightmare: its entry ends on the route's first point, then it only gets nearer the second
	spawner.force_walk_in = true
	var comer: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	spawner.force_walk_in = false
	_check(comer != null and comer.is_entering() and comer.position.is_equal_approx(walk[0]), "%s: it starts in the fog" % label)
	if comer == null:
		return
	comer.set_process(false)
	var along := -INF  # Its progress in toward the island: never backwards on the way in either
	var guard := 0
	while comer.is_entering() and guard < 600:
		comer._process(STEP)
		guard += 1
		var now: float = (comer.position - walk[0]).dot(-out)
		_check(now >= along - 0.001, "%s: no step back on the bridge (%.2f after %.2f)" % [label, now, along])
		along = now
	_check(not comer.is_entering() and comer.position.is_equal_approx(first),
		"%s: the entry ends on the route's first point (%s, route %s)" % [label, comer.position, first])
	_check(absf(guard * STEP - comer.ENTRY_TIME) <= 2.0 * STEP, "%s: the way in still takes ENTRY_TIME (%.2f s)" % [label, guard * STEP])
	var left: float = comer.position.distance_to(second)
	var arrived := false
	for f in 240:
		comer._process(STEP)
		var now: float = comer.position.distance_to(second)
		if now > left + 0.001:
			_check(false, "%s: it backs away from the route's second point (%.2f after %.2f px, frame %d)" % [label, now, left, f])
			break
		left = now
		if now < 4.0:  # (A frame's step at any walking speed)
			arrived = true
			break
	_check(arrived, "%s: it walks on to the route's second point (%.1f px left)" % [label, left])
	comer.free()
