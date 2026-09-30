extends SceneTree

# Headless test for close calls (run_design.md "spend or save"): a nightmare past 85% of its route
# counts once, emits close_call, trembles the Heartwood and lights the last stretch; the rest report
# shows the block's count, which a new block clears.
#   godot --headless --path . --script res://tests/test_close_calls.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var calls := CloseCalls.find(main)
	_check(calls != null, "the HUD makes CloseCalls")
	var spawner = main.get_node("%EnemyContainer")
	var map_generator = main.get_node("%MapGenerator")
	var heard: Array = []
	calls.close_call.connect(func(enemy: Node2D) -> void: heard.append(enemy))

	var shade: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var enemy = spawner.spawn_enemy(shade)
	await process_frame
	calls._check(enemy)  # Its route's length, seen at the start
	_check(calls.block_count == 0, "not a close call at the start")
	# Walk it to just before the goal: 90% of the route.
	var route: PackedVector2Array = enemy._path
	var index := int(route.size() * 0.9)
	enemy._path_index = index
	enemy.position = map_generator.MAP_GRID.calculate_map_position(route[index])
	calls._check(enemy)
	_check(calls.block_count == 1 and heard == [enemy], "past 85%%: one close call, signalled (%d)" % calls.block_count)
	_check(calls._glow_age >= 0.0 and not calls._glow_cells.is_empty(), "the last stretch glows")
	calls._check(enemy)
	_check(calls.block_count == 1, "the same nightmare counts once")

	var report: RestReport = main.get_node("%RestReport")
	report.show_report(1)
	_check(report._label.get_parsed_text().contains("Close calls: 1"), "the rest report counts them")
	# No automatic rest report (screens_ui.md): the card stays hidden unless "Rest summary" is on; the
	# damage meter's "Last block" tab shows the same summary on demand.
	_check(not report.visible or RestReport.auto_show(), "the rest card doesn't pop up by default")
	var meter: DriftMeter = main.get_node("HUD/DriftMeter")
	meter.show_block_summary(true)
	_check(meter.block_summary and meter._summary.visible and meter._summary.get_parsed_text().contains("Close calls: 1")
		and not meter._rows.visible, "the meter's Last block tab shows the summary (%s)" % meter._summary.get_parsed_text().left(60))
	meter.show_block_summary(false)
	_check(not meter._summary.visible and meter._rows.visible, "and the Wardens tab goes back to the rows")
	calls._on_rest_ended(1)
	_check(calls.block_count == 0 and calls.run_count == 1, "a new block starts from 0; the run keeps its total")

	main.queue_free()
	await process_frame
	print("close calls test: " + ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
