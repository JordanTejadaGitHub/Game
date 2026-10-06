extends SceneTree

# Headless test for settling ground (run_design.md "No maze juggling"): during a drift, the cells a
# Warden was sold from can't be planted on for TowerPlacer.SETTLE_SECONDS; the ghost says so; every
# footprint cell counts (2×2 too); rests are exempt and settle everything. Run:
#   godot --headless --path . --script res://tests/test_settling.gd --fixed-fps 60

const MAP_SEED := 42

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = MAP_SEED
	root.add_child(main)
	await process_frame
	var map_generator = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var sprout: TowerData = load("res://resource/tower/sprout.tres")

	# --- A rest: selling doesn't settle anything ---
	var first := _build(placer, map_generator, sprout)
	var cell := first.cell
	_check(seller.sell(cell), "sold during a rest")
	_check(placer.settling.is_empty(), "rests are exempt: nothing settles")
	placer.tower_data = sprout
	_check(placer._try_build(cell), "and the cell takes a Warden again at once")

	# --- A drift: the sold cell settles for 8 s ---
	director.start_next_block()
	await process_frame
	for enemy in main.get_node("%EnemyContainer").get_children():
		enemy.queue_free()  # Keep nightmares off the cell under test
	await process_frame
	_check(not director.is_build_phase(), "a drift is on")
	_check(seller.sell(cell), "sold during the drift")
	_check(is_equal_approx(placer.settling_left([cell]), TowerPlacer.SETTLE_SECONDS), "the ground settles for 8 s")
	placer.tower_data = sprout
	_check(not placer._try_build(cell), "it can't be planted on while settling")
	placer.set_build_mode(true)
	placer._hover_cell = cell
	placer._refresh_hover()
	_check(not placer._hover_valid, "the ghost shows it as invalid")
	placer._tick_settling(3.0)
	_check(is_equal_approx(placer.settling_left([cell]), TowerPlacer.SETTLE_SECONDS - 3.0), "it counts down in game time")
	paused = true
	placer._tick_settling(3.0)
	_check(is_equal_approx(placer.settling_left([cell]), TowerPlacer.SETTLE_SECONDS - 3.0), "not while paused")
	paused = false
	var marks: Node2D = placer.get_parent().get_node_or_null("SettlingMarks")
	_check(marks != null and marks.is_visible_in_tree(), "the settling ring is drawn in the world, outside build mode too")
	placer._tick_settling(5.5)
	_check(placer.settling.is_empty() and placer._try_build(cell), "after 8 s it can be planted again")
	placer.set_build_mode(false)

	# --- 2×2: every footprint cell settles, and a 2×2 ghost overlapping one is refused ---
	var second := _build(placer, map_generator, sprout)
	_check(seller.sell(second.cell), "another sale")
	var covered := false
	for origin in [second.cell, second.cell - Vector2(1, 0), second.cell - Vector2(0, 1), second.cell - Vector2.ONE]:
		covered = covered or placer.settling_left(Tower.footprint_cells(origin, 2)) > 0.0
	_check(covered, "a 2×2 footprint over the settling cell sees it")
	placer.settle(Tower.footprint_cells(Vector2(2, 2), 2))
	_check(placer.settling_left([Vector2(3, 3)]) > 0.0 and placer.settling_left([Vector2(2, 3)]) > 0.0, "a 2×2 Warden sold settles all 4 cells")

	# --- A Warden between cells (user: "selling between cells locks cells double the size"): only its own halves ---
	var origin := Vector2(-1, -1)
	for y in range(4, 30):
		for x in range(5, 40, 2):  # Odd half origins: between whole cells
			var o := Vector2(x, y)
			if origin.x < 0 and map_generator.halves_of(o).all(func(h: Vector2) -> bool: return map_generator.is_buildable_half(h)) \
					and placer.settling_left_halves(map_generator.halves_of(o)) <= 0.0 \
					and map_generator.halves_of(o + Vector2(2, 0)).all(func(h: Vector2) -> bool: return map_generator.is_buildable_half(h)) \
					and map_generator.can_block_halves(map_generator.halves_of(o)):
				origin = o
	main.get_node("%RunState").dew = 1000
	placer.tower_data = sprout
	_check(origin.x >= 0 and placer._try_build_half(origin), "a Sprout plants between cells")
	var between: Tower = null
	for t in placer.tower_container.get_children():
		if t is Tower and t.half_cell == origin:
			between = t
	var own: Array = between.get_halves() if between else []
	_check(between != null and seller.sell(between.cell), "and sells during the drift")
	_check(own.all(func(h: Vector2) -> bool: return placer.settling_left_halves([h]) > 0.0), "its 4 halves settle")
	var neighbour := origin + Vector2(2, 0)  # The 2×2 beside it, sharing the same whole cells
	_check(placer.settling_left_halves(map_generator.halves_of(neighbour)) <= 0.0,
		"the halves beside it, in the same whole cells, stay open (not double the size)")

	# --- The next rest settles everything at once ---
	director.build_phase_changed.emit(true)
	_check(placer.settling.is_empty(), "a rest settles the ground at once")

	print("settling test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

# Builds `data` on a free cell beside the path (keeping it open).
func _build(placer: TowerPlacer, map_generator, data: TowerData) -> Tower:
	var path: PackedVector2Array = Tower.route_cells(map_generator.get_path_from(map_generator.startPath))  # Whole cells (half-cell routes)
	var container: Node = placer.tower_container
	placer.run_state.dew = 10000
	for i in range(6, path.size() - 3):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if path.has(cell) or not map_generator.can_block(cell):
				continue
			placer.tower_data = data
			var count := container.get_child_count()
			if placer._try_build(cell):
				var built: Tower = container.get_child(count)
				built.set_process(false)
				return built
	return null
