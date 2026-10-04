extends SceneTree
# Half-cell pathing (documentation/half_cells.md): 32 px half cells, nightmares as
# fitting through one half cell (half_cells.md 04c10c33), footprints at half offsets,
# the full-cell API still working, a nightmare walking a half-step route, and the pathfinding cost.
# Run:  Godot --headless --path . --script res://tests/test_half_cells.gd --fixed-fps 60

var failures := 0

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_half_cells_%d.json" % OS.get_process_id()
	_corridor_rule()
	_dual_masks()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 1207
	root.add_child(main)
	await process_frame
	var map = main.get_node("%MapGenerator")

	# The route: from the start to the Heartwood in half steps, within the usual length band.
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	_check(not route.is_empty() and map.halves_of(map.startPath * 2).has(Vector2(FindPath.point_to_node(route[0])))
		and map.halves_of(map.endPath * 2).has(Vector2(FindPath.point_to_node(route[-1]))), "a route from a start half to a Heartwood half")
	_check(Array(route).all(func(p: Vector2) -> bool: return not FindPath.is_whole_cell(p) and fposmod(p.x * 4.0, 2.0) == 1.0),
		"route points are half centres (x.25 / x.75)")
	var steps_ok := true
	for i in range(1, route.size()):
		if absf(route[i].x - route[i - 1].x) + absf(route[i].y - route[i - 1].y) != 0.5:
			steps_ok = false
	_check(steps_ok, "the route steps half a cell at a time")
	var length: int = map.route_length(route)
	_check(length >= map.min_route_length and length <= map.max_route_length,
		"route length %d (full cells) in %d..%d" % [length, map.min_route_length, map.max_route_length])

	# A footprint at a half offset beside the route: blocking it moves the route off those halves.
	var placed := false
	for p in route:
		for offset in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1), Vector2(3, 1), Vector2(1, 3)]:
			var origin: Vector2 = p * 2.0 + offset
			if int(origin.x) % 2 == 0 and int(origin.y) % 2 == 0:
				continue  # Want a real half offset
			var halves: Array[Vector2] = map.halves_of(origin)
			if not map.can_block_halves(halves):
				continue
			var before: PackedVector2Array = map.get_path_from(map.startPath)
			var preview: PackedVector2Array = map.get_path_if_blocked_halves(halves)
			map.block_halves(halves)
			var after: PackedVector2Array = map.get_path_from(map.startPath)
			_check(after == preview, "the preview is the route after blocking")
			_check(halves.all(func(h: Vector2) -> bool: return not map.is_buildable((h / 2.0).floor())),
				"whole-cell gift terrain can't go on any cell a Warden half touches (GiftPlacer uses is_buildable)")
			var crosses := false
			for q in after:
				for h in map.body_halves(q):
					if halves.has(h):
						crosses = true
			_check(not crosses, "no nightmare body crosses the footprint at %s" % origin)
			var dual: TileMapLayer = map.path_layer.dual_layer
			var path_halves: Dictionary = map.path_layer.path_halves()
			var masks_ok := dual.get_used_cells().size() > 0
			for at in dual.get_used_cells():
				var want := PathGenerator.dual_mask(path_halves, at)
				var got := dual.get_cell_atlas_coords(at).x
				if got != want and not (want == 15 and got >= 15):
					masks_ok = false
			_check(masks_ok and halves.all(func(h: Vector2) -> bool: return not path_halves.has(Vector2i(h))),
				"the dual path: every tile by its corners, none on the Warden's halves")
			_check(not map.can_block_halves(halves) and map.block_refusal() == &"occupied", "the same halves can't be taken twice")
			map.unblock_halves(halves)
			_check(map.get_path_from(map.startPath) == before, "unblocked: the old route back")
			placed = true
			break
		if placed:
			break
	_check(placed, "a half-offset footprint beside the route")

	# The full-cell API: an obstacle cell is 4 blocked halves; a full cell blocks as before.
	var obstacle: Vector2 = map.obstacles.keys()[0]
	_check(map.halves_of(obstacle * 2).all(func(h: Vector2) -> bool: return not map.is_buildable_half(h)), "an obstacle's 4 halves are taken")
	_check(not map.is_buildable_half(map.startPath * 2) and not map.is_buildable_half(map.endPath * 2 + Vector2(1, 1)), "not on the start or the Heartwood")
	var glade_half: Vector2 = map.get_glade_cells()[0] * 2
	_check(map.is_buildable_half(glade_half) or map.path_layer.is_half_blocked(glade_half), "the glade stays buildable")

	# A nightmare walks the half-step route.
	var shade: Node2D = main.get_node("%EnemyContainer").spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var start_px: Vector2 = shade.position
	for i in 240:
		await process_frame
	_check(is_instance_valid(shade) and shade.position.distance_to(start_px) > 64.0, "a nightmare walks the route")
	if is_instance_valid(shade):
		var target: Vector2 = shade.get_target_cell()
		_check(not map.get_path_from(target).is_empty(), "re-routing from its target point works (%s)" % target)

	# Cost: a full route search, as every nightmare re-routes on each placement.
	var t0 := Time.get_ticks_usec()
	for i in 200:
		map.get_path_from(map.startPath)
	var per_path := (Time.get_ticks_usec() - t0) / 200.0
	print("  half-cell route search: %.0f us each; 150 nightmares re-routing on a placement ~ %.1f ms" % [per_path, per_path * 150 / 1000.0])
	_check(per_path < 2000.0, "a route search stays under 2 ms (%.0f us)" % per_path)

	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("test_half_cells: %d failure(s)" % failures)
	quit(failures)

# On a bare 6×4 grid: a wall of half cells with a 1-half gap lets a nightmare through; a full wall doesn't.
func _corridor_rule() -> void:
	var grid := Grid.new()
	grid.size = Vector2(6, 4)
	grid.cell_size = Vector2(64, 64)
	var cells: Array = []
	for x in 6:
		for y in 4:
			cells.append(Vector2(x, y))
	var finder := FindPath.new(grid, cells)
	var start := Vector2(0, 1)
	var end := Vector2(5, 1)
	_check(not finder.calculate_point_path(start, end).is_empty(), "open grid: a route")
	for y in 8:  # A wall down half column 5, a gap at half row 3 only
		if y != 3:
			finder.set_half_blocked(Vector2(5, y), true)
	var path := finder.calculate_point_path(start, end)
	_check(not path.is_empty(), "a 1-half gap: nightmares fit through")
	_check(path.has(FindPath.node_to_point(Vector2i(5, 3))), "through the gap at half (5, 3) (%s)" % [path])
	finder.set_half_blocked(Vector2(5, 3), true)  # Close it
	_check(finder.calculate_point_path(start, end).is_empty(), "a full wall: no way through")
	_check(is_equal_approx(Tower.MAP_GRID.calculate_map_position(FindPath.node_to_point(Vector2i(7, 0))).x, 7 * 32 + 16),
		"a route point's pixel is its half's centre")

# The dual grid's corner masks (TL 1, TR 2, BR 4, BL 8) on a few sets of path halves (2 wide here).
func _dual_masks() -> void:
	var halves_of := func(points: Array) -> Dictionary:
		var halves := {}
		for p in points:
			for h in FindPath.halves_of_cell(p):
				halves[Vector2i(h)] = true
		return halves
	# A straight run east: bodies at x 0..3 (half steps), row 0.
	var straight: Dictionary = halves_of.call([Vector2(0, 0), Vector2(0.5, 0), Vector2(1, 0), Vector2(1.5, 0)])
	_check(PathGenerator.dual_mask(straight, Vector2i(2, 1)) == 15, "straight: inside is a full tile")
	_check(PathGenerator.dual_mask(straight, Vector2i(2, 0)) == 4 | 8, "straight: the top bank (BR + BL)")
	_check(PathGenerator.dual_mask(straight, Vector2i(2, 2)) == 1 | 2, "straight: the bottom bank (TL + TR)")
	_check(PathGenerator.dual_mask(straight, Vector2i(0, 0)) == 4, "straight: the west end's outer corner")
	# A corner: east along row 0, then south down column 1.5.
	var corner: Dictionary = halves_of.call([Vector2(0, 0), Vector2(0.5, 0), Vector2(1, 0), Vector2(1.5, 0), Vector2(1.5, 0.5), Vector2(1.5, 1)])
	_check(PathGenerator.dual_mask(corner, Vector2i(5, 1)) == 1 | 8, "corner: the outer bank turns (TL + BL)")
	_check(PathGenerator.dual_mask(corner, Vector2i(3, 2)) == 15 - 8, "corner: the inner corner (all but BL)")
	# A half-step jog: east, then shifted half a cell south, then east again.
	var jog: Dictionary = halves_of.call([Vector2(0, 0), Vector2(0.5, 0), Vector2(0.5, 0.5), Vector2(1, 0.5), Vector2(1.5, 0.5)])
	# Path halves: row 0 x 0-2, row 1 x 0-4, row 2 x 1-4.
	_check(PathGenerator.dual_mask(jog, Vector2i(3, 1)) == 1 | 4 | 8, "jog: the top bank steps down (all but TR)")
	_check(PathGenerator.dual_mask(jog, Vector2i(1, 2)) == 1 | 2 | 4, "jog: the bottom bank steps in (all but BL)")
