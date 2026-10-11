extends SceneTree
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _run() -> void:
	root.size = Vector2i(1280, 720)
	var main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 4242
	root.add_child(main)
	for i in 3:
		await process_frame
	var hud = main.get_node("HUD")
	var meter = hud.get_node("DriftMeter")
	main.get_node("%DriftDirector").drifts_started = 1
	meter.refresh()
	if not hud.has_method("set_bar_hidden") or not meter.has_method("set_hidden"):
		_check(false, "meter and tower bar expose hide/reopen controls")
	else:
		var selected = main.get_node("%TowerPlacer").tower_data
		var bar_arrow = hud.get_node("TowerBarToggle") as Button
		bar_arrow.pressed.emit()
		_check(not main.get_node("%TowerBar").visible and not hud.clear_tool.visible and bar_arrow.visible and bar_arrow.get_meta(&"arrow") == Vector2.UP, "bar hides but its up arrow remains")
		hud._build_tower_bar()
		_check(not main.get_node("%TowerBar").visible and main.get_node("%TowerPlacer").tower_data == selected, "bar refresh stays hidden and preserves selection")
		bar_arrow.pressed.emit()
		_check(main.get_node("%TowerBar").visible and hud.clear_tool.visible and bar_arrow.get_meta(&"arrow") == Vector2.DOWN, "down arrow hides and up arrow restores the bar")
		var meter_arrow = hud.get_node("MeterToggle") as Button
		meter_arrow.pressed.emit()
		_check(not meter.visible and meter_arrow.visible and meter_arrow.get_meta(&"arrow") == Vector2.LEFT, "meter hides but its reopen arrow remains")
		meter_arrow.pressed.emit()
		_check(meter.visible and meter_arrow.get_meta(&"arrow") == Vector2.RIGHT, "meter arrow restores the panel")
		for view in [Vector2i(1280, 720), Vector2i(1200, 540)]:
			root.size = view
			for i in 3:
				await process_frame
			for button in [bar_arrow, meter_arrow]:
				var rect: Rect2 = button.get_global_rect()
				_check(root.get_visible_rect().encloses(rect) and rect.size.y >= 48, "hide control is on screen and touch-sized at %s" % view)
	main.queue_free()
	await process_frame
	print("hide controls: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)