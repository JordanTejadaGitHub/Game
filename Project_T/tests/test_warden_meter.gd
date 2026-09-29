extends SceneTree

# Headless test for WardenMeter ("Damage that means something", screens_ui.md): plays drift 1 with a
# Warden beside the path and one far from it, then checks the maze DPS, the needed DPS (and the rest's
# forecast), per-Warden DPS / share / Dew / rating, the far one's "few nightmares in range", and the
# block summary.
#   godot --headless --path . --script res://tests/test_warden_meter.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var map = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	run_state.dew = 1000
	run_state.invulnerable = true
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var near := _build(placer, map, route, 4)
	var far := _build_far(placer, map, route)
	_check(near != null and far != null, "planted a Warden by the path and one far from it")
	var meter := WardenMeter.find(near)
	_check(meter != null, "the run has a WardenMeter")
	var forecast := meter.get_benchmark()
	_check(forecast.forecast and forecast.drift == 1 and forecast.needed_dps > 0.0,
		"at the opening rest: a forecast for drift 1 (needs ~%.1f)" % forecast.needed_dps)
	director.start_next_drift()
	var during := {}
	for i in 60 * 90:
		if director.awaiting_family_pick or director.is_resting():
			break
		if i == 60 * 15:
			during = meter.get_benchmark()
		await process_frame
	_check(not during.is_empty() and not during.forecast and during.maze_dps > 0.0,
		"during the drift: the maze's DPS (%.1f) vs needed (%.1f)" % [during.get("maze_dps", 0.0), during.get("needed_dps", 0.0)])
	var rows := meter.get_meter_rows("drift")
	var near_row := {}
	var far_row := {}
	for r in rows:
		if r.tower == near:
			near_row = r
		elif r.tower == far:
			far_row = r
	_check(not near_row.is_empty() and near_row.dps > 0.0 and near_row.share > 0.9, "the near Warden: DPS %.1f, share %.2f" % [near_row.get("dps", 0.0), near_row.get("share", 0.0)])
	_check(near_row.get("dew_invested", 0) == near.invested_dew and near_row.rating_label == &"carrying", "rated carrying (%.2f)" % near_row.get("rating", -1.0))
	_check(not far_row.is_empty() and far_row.rating_label == &"underused" and far_row.reason == "few nightmares in range",
		"the far one: underused, few nightmares in range (%s, '%s')" % [far_row.get("rating_label", ""), far_row.get("reason", "")])
	var summary := meter.get_block_summary()
	_check(summary.maze_dps > 0.0 and summary.carrying.size() == 1 and summary.underused.size() == 1,
		"block summary: 1 carrying, 1 underused (%d, %d)" % [summary.carrying.size(), summary.underused.size()])
	_check(summary.needed_dps > 0.0, "and the next drift's needed DPS")

	print("warden meter test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _build(placer: TowerPlacer, map, route: PackedVector2Array, index: int) -> Tower:
	placer.tower_data = load("res://resource/tower/sporeling.tres")
	for i in range(index, route.size() - 3):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = route[i] + offset
			if route.has(cell) or not map.can_block(cell):
				continue
			var count := placer.tower_container.get_child_count()
			if placer._try_build(cell):
				return placer.tower_container.get_child(count)
	return null

# A Warden at least 5 cells from every path tile.
func _build_far(placer: TowerPlacer, map, route: PackedVector2Array) -> Tower:
	placer.tower_data = load("res://resource/tower/sporeling.tres")
	for y in Tower.MAP_GRID.size.y:
		for x in Tower.MAP_GRID.size.x:
			var cell := Vector2(x, y)
			if not map.can_block(cell) or route.has(cell):
				continue
			var far_enough := true
			for at in route:
				if at.distance_to(cell) < 5.0:
					far_enough = false
					break
			if far_enough:
				var count := placer.tower_container.get_child_count()
				if placer._try_build(cell):
					return placer.tower_container.get_child(count)
	return null
