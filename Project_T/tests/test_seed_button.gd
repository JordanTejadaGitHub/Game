extends SceneTree

# A Seedbearer's ripe seed in the Warden panel (Tower Code, Phase 2): "Plant Sprout (N)" at a rest starts the cell
# choice (TowerPlacer.begin_seed_choice, the touch way in); outside a rest it waits, greyed. Temp profile.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_seed_button_%d.json" % OS.get_process_id()
	ResultsScreen.demo_override = 0
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 777
	root.add_child(main)
	for i in 3:
		await process_frame
	var map = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var panel = main.find_child("WardenPanel", true, false)
	main.get_node("%RunState").dew = 2000
	main.get_node("%DreamState").unlock_everything = true
	var cell := Vector2(-1, -1)
	for y in range(3, 15):
		for x in range(3, 20):
			if cell.x < 0 and map.is_buildable(Vector2(x, y)) and not map.get_path_if_blocked(Vector2(x, y)).is_empty():
				cell = Vector2(x, y)
	placer.select_tower(load("res://resource/tower/seedbearer.tres"))
	placer._try_build(cell)
	placer.set_build_mode(false)
	var tower := seller.get_tower_at(cell)
	_check(tower != null, "a Seedbearer is planted")
	tower.set_meta(&"seeds_ready", 1)

	Tower.resting = false
	seller.select(tower)
	for i in 3:
		await process_frame
	var button: Button = _live_button(panel)
	_check(button != null and button.disabled and button.text.contains("next rest"), "during a drift the button waits, greyed (%s)" % (button.text if button else "none"))

	Tower.resting = true
	panel._refresh()
	for i in 2:
		await process_frame
	button = _live_button(panel)
	_check(button != null and not button.disabled and button.text == "Plant Sprout (1)", "at a rest: \"Plant Sprout (1)\"")
	if button != null:
		button.pressed.emit()
	_check(placer.is_choosing_seed(), "pressing it lights the cells beside it (the seed choice)")
	placer.cancel_seed_choice()
	main.queue_free()
	await process_frame
	ResultsScreen.demo_override = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)

func _live_button(panel: Node) -> Button:
	for child in panel._all_buttons():
		if child is Button and child.name.begins_with("PlantSprout") and not child.is_queued_for_deletion():
			return child
	return null
