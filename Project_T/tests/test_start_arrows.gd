extends SceneTree

# Headless test for the route arrows at the start of a run (screens_ui.md "In the world"): chevrons along the whole
# route from run start, following re-routes live; the first drift fades them out and they never return (later drifts,
# rests); a resumed run still before drift 1 shows them again.
#   godot --headless --path . --script res://tests/test_start_arrows.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame
	var arrows := main.get_node_or_null("StartArrows") as StartArrows
	_check(arrows != null, "the HUD makes StartArrows")
	if arrows == null:
		_finish(main)
		return
	var map_generator = main.get_node("%MapGenerator")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	_check(arrows.is_showing() and arrows._cells.size() == route.size(), "shown from run start, along the whole route (%d of %d cells)" % [arrows._cells.size(), route.size()])
	_check(arrows._cells[0] == map_generator.MAP_GRID.calculate_map_position(route[0])
		and arrows._cells[-1] == map_generator.MAP_GRID.calculate_map_position(route[-1]), "…from the start to the Heartwood")
	# Spread out (user: "spread them out more"): about one per 3 cells, evenly along the route's length, one on the start
	# and one on the last cell before the Heartwood
	var count := arrows.mark_count()
	var expected := maxi(1, roundi(arrows._length_to(route.size() - 2) / (StartArrows.SPACING_CELLS * StartArrows.CELL))) + 1
	_check(count == expected and count < route.size() / 2, "chevrons spread out: %d for %d route cells" % [count, route.size()])
	_check(arrows.mark_position(0).is_equal_approx(arrows._cells[0]) and arrows.mark_position(count - 1).is_equal_approx(arrows._cells[-2]),
		"…one on the start, one on the last cell before the Heartwood")
	var gaps: Array[float] = []
	for i in count - 1:
		gaps.append(arrows.mark_position(i).distance_to(arrows.mark_position(i + 1)))
	var even := true
	var spacing: float = arrows._length_to(route.size() - 2) / maxf(count - 1, 1.0)
	for i in count - 1:  # Along the route they're exactly `spacing` apart; straight-line gaps can only be shorter (corners)
		even = even and gaps[i] <= spacing + 0.5
	_check(even and spacing >= 2.0 * StartArrows.CELL and spacing <= 4.0 * StartArrows.CELL, "…evenly spaced along the route (%.0f px)" % spacing)
	_check(StartArrows.SIZE * 2.0 <= 0.45 * StartArrows.CELL and StartArrows.BASE_ALPHA <= 0.45 and StartArrows.LIT_ALPHA <= 0.75, "…small and subtle")
	_check(arrows.z_index < 0, "…drawn under the build ghost's route preview")
	# Planting changes the route: they follow it live
	var blocked := Vector2(-1, -1)
	for i in range(2, route.size() - 2):
		if map_generator.is_buildable(route[i]) and map_generator.can_block(route[i]):
			blocked = route[i]
			break
	if blocked.x >= 0:
		map_generator.block_cell(blocked)
		var new_route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
		_check(arrows._cells.size() == new_route.size() and not arrows._cells.has(map_generator.MAP_GRID.calculate_map_position(blocked)),
			"…and follow a re-route as a Warden is planted")
		map_generator.unblock_cell(blocked)
	# The first drift: they fade and never come back
	director.drifts_started = 1
	director.drift_started.emit(1)
	for i in int((StartArrows.FADE_TIME + 0.3) * 60):
		await process_frame
	_check(not arrows.is_showing(), "the first drift fades them out")
	director.drift_started.emit(2)
	map_generator.path_changed.emit()
	await process_frame
	_check(not arrows.is_showing(), "…and they never return (later drifts, re-routes)")
	_finish(main)
	# A resumed run still before drift 1: a fresh scene shows them again
	var resumed: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(resumed)
	for i in 3:
		await process_frame
	var again := resumed.get_node_or_null("StartArrows") as StartArrows
	_check(again != null and again.is_showing(), "a (resumed) run before drift 1 shows them")
	var resumed_late: Node = load("res://scenes/main.tscn").instantiate()
	resumed_late.get_node("%DriftDirector").drifts_started = 12  # As RunSaver restores it
	root.add_child(resumed_late)
	for i in 3:
		await process_frame
	var late := resumed_late.get_node_or_null("StartArrows") as StartArrows
	_check(late != null and not late.is_showing(), "…but not one resumed past drift 1")
	resumed.queue_free()
	resumed_late.queue_free()
	await process_frame
	print("start arrows test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _finish(main: Node) -> void:
	main.queue_free()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
