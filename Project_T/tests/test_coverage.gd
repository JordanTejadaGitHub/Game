extends SceneTree

# Headless test for coverage (maze_feel.md 8b50fce6: "only upgrade at the right spots where it covers everything"):
# a Warden beside the route covers path tiles, one far from it covers none; every pass counts; the ghost's chip compares
# a spot with the board's best open cell. Run from the project folder:
#   godot --headless --path . --script res://tests/test_coverage.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_coverage_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var map = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var spore: TowerData = load("res://resource/tower/sporeling.tres")
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var cells := Tower.route_cells(route)

	# Counting: every route point (half a tile apart) in range counts, so a stretch passed twice counts twice.
	var centre := Tower.MAP_GRID.calculate_map_position(cells[cells.size() / 2])
	var once := TowerPlacer.coverage_on(route, centre, 2.5 * 64.0)
	var twice := route + route
	_check(once > 0 and TowerPlacer.coverage_on(twice, centre, 2.5 * 64.0) == once * 2, "a route passed twice counts twice (%d)" % once)
	_check(TowerPlacer.coverage_on(route, Vector2(-5000, -5000), 2.5 * 64.0) == 0, "nothing in range: 0")
	# Rule 1 (warden_stats.md b6f44fac): Nurture-widened areas count cells by distance, so ranks add ground smoothly.
	_check(BranchKit.cells_within(1.5) == 8 and BranchKit.cells_within(1.0) == 4 and BranchKit.cells_within(2.0) == 12,
		"cells by distance: 4 within 1, 8 within 1.5, 12 within 2 (%d, %d, %d)" % [BranchKit.cells_within(1.0), BranchKit.cells_within(1.5), BranchKit.cells_within(2.0)])
	_check(BranchKit.cells_gained(1.5, 0.6) == 4, "+0.6 from 1.5 reaches the 4 cells at distance 2 (%d)" % BranchKit.cells_gained(1.5, 0.6))

	# A planted Warden beside the route reports it in its panel lines.
	var beside := Vector2(-1, -1)
	for c in cells:
		for side in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			if beside.x < 0 and not cells.has(c + side) and map.can_block(c + side):
				beside = c + side
	placer.tower_data = spore
	main.get_node("%RunState").add_dew(500)
	_check(placer._try_build(beside), "a Sporeling plants beside the route")
	var tower: Tower = null
	for t in placer.tower_container.get_children():
		if t is Tower and t.cell == beside:
			tower = t
	await process_frame
	_check(tower != null and tower.get_coverage() > 0, "it covers path tiles (%d)" % (tower.get_coverage() if tower else -1))
	_check(tower != null and BranchKit.stat_lines(tower).any(func(l: String) -> bool: return l.begins_with("Covers ")),
		"its panel says how much it covers")

	# The ghost: its chip, and the board's best is at least as good as any spot.
	placer.set_build_mode(true)
	placer.select_tower(spore)
	placer._hover_cell = beside + Vector2(0, 2)
	placer._hover_half = placer.origin_at(Tower.MAP_GRID.calculate_map_position(placer._hover_cell))
	var chip := placer.coverage_chip()
	_check(not chip.is_empty() and String(chip[0]).begins_with("covers "), "the ghost shows a coverage chip (%s)" % [chip])
	_check(placer.best_coverage() >= placer.ghost_coverage(), "the best open spot covers at least as much (%d ≥ %d)" % [placer.best_coverage(), placer.ghost_coverage()])
	placer.select_tower(load("res://resource/tower/thornwall.tres"))
	_check(placer.coverage_chip().is_empty(), "walls show no coverage chip")
	placer.set_build_mode(false)

	print("coverage test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
