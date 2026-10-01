extends SceneTree

# Headless test for the start arrows (user 2026-10-01: "arrows at the beginning of the wave, so we know the
# direction"): a drift starting shows chevrons on the route's first cells from the start, pointing along it; they
# follow a re-route and are gone after SHOW_TIME.
#   godot --headless --path . --script res://tests/test_start_arrows.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var arrows := main.get_node_or_null("StartArrows") as StartArrows
	_check(arrows != null, "the HUD makes StartArrows")
	if arrows == null:
		_finish(main)
		return
	var map_generator = main.get_node("%MapGenerator")
	var director: DriftDirector = main.get_node("%DriftDirector")
	_check(not arrows.is_showing(), "hidden before a drift")
	director.drift_started.emit(1)
	var route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	_check(arrows.is_showing() and arrows._cells.size() == StartArrows.ARROW_CELLS + 1, "a drift starting shows them (%d cells)" % arrows._cells.size())
	_check(arrows._cells[0] == map_generator.MAP_GRID.calculate_map_position(route[0])
		and arrows._cells[1] == map_generator.MAP_GRID.calculate_map_position(route[1]), "…on the route's first cells from the start, in walking order")
	# A re-route while they show: they follow it
	var blocked := Vector2(-1, -1)
	for i in range(1, mini(route.size() - 1, 4)):
		if map_generator.is_buildable(route[i]) and map_generator.can_block(route[i]):
			blocked = route[i]
			break
	if blocked.x >= 0:
		map_generator.block_cell(blocked)
		var new_route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
		_check(arrows._cells[1] == map_generator.MAP_GRID.calculate_map_position(new_route[1]), "…and follow a re-route while they show")
		map_generator.unblock_cell(blocked)
	for i in int((StartArrows.SHOW_TIME + 0.5) * 60):
		await process_frame
	_check(not arrows.is_showing(), "…gone after %.1f s" % StartArrows.SHOW_TIME)
	_finish(main)

func _finish(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("start arrows test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
