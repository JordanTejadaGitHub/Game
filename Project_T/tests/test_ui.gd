extends SceneTree

# Headless test for the run HUD pieces from screens_ui.md: the drift banner's boss countdown, the
# nightmare info panel, leak feedback, the pause menu summary and Abandon run, the results stats and
# the G (grow) hotkey. Never touches the player's saves (the scene isn't the running game).
#   godot --headless --path . --script res://tests/test_ui.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var director: DriftDirector = main.get_node("%DriftDirector")
	var spawner = main.get_node("%EnemyContainer")
	var run_state: RunState = main.get_node("%RunState")

	# --- Drift banner: next boss countdown ---
	var banner = main.get_node("%DriftBanner")
	var text: String = banner._next_boss_text(0)
	_check(text.ends_with("in 25"), "banner counts down to the drift 25 boss (%s)" % text)

	# --- HUD layout (screens_ui.md "The run HUD", principles 5 and 6) ---
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.unlock_everything = true  # Every Warden in the bar, as in Test Grove
	dreams.unlocks_changed.emit()
	var bar: HBoxContainer = main.get_node("%TowerBar")
	var first_button := bar.get_child(0) as Button
	_check(first_button.text.is_valid_int() and first_button.get_child(0) is Label and first_button.get_child(0).text == "1",
		"Warden buttons show the cost and the hotkey (%s)" % first_button.text)
	for screen in [Vector2i(1920, 1080), Vector2i(1280, 800)]:
		root.size = screen
		await _frames(2)
		var bar_rect := bar.get_global_rect()
		_check(bar_rect.end.y > screen.y - 100 and absf(bar_rect.get_center().x - screen.x / 2.0) < 2.0,
			"the Warden bar sits at the bottom centre at %s (%s)" % [screen, bar_rect])
		for name in ["WardenPanel", "DriftPanel", "DriftBanner"]:
			var other := (main.get_node("HUD/" + name) as Control).get_global_rect()
			_check(not bar_rect.intersects(other), "the Warden bar doesn't overlap %s at %s (%s vs %s)" % [name, screen, bar_rect, other])
	_check(banner.get_drift_text() == "Ready · Drift 1", "before the first drift the banner reads Ready · Drift 1")
	# The camera can scroll past the map's far corner, so the Heartwood can clear the drift controls.
	var camera = main.get_node("GameCameraNode")
	camera.target_position = Vector2(1e6, 1e6)
	camera._clamp_camera_to_map()
	var half_view: Vector2 = camera.camera_2d.get_viewport_rect().size / camera.camera_2d.zoom / 2.0
	_check(camera.target_position.x > camera.map_size_pixels.x - half_view.x + 1.0
		and camera.target_position.y > camera.map_size_pixels.y - half_view.y + 1.0,
		"the camera can go past the map's edges by the HUD's size")
	dreams.unlock_everything = false
	dreams.unlocks_changed.emit()

	# --- Whispers: a locked obstacle says "Dead wood…", Tend waits for the first clearing Dream ---
	var whispers = main.get_node("%Whispers")
	var clearer: ObstacleClearer = main.get_node("%ObstacleClearer")
	whispers.set_process(false)  # Driven by hand below
	whispers.enabled = true
	whispers._seen = []
	clearer.set_process(false)  # Its hover follows the mouse each frame
	clearer._hover_obstacle = load("res://resource/obstacle/tree.tres")
	whispers._process(0.0)
	_check(whispers._queue.has(&"dead_wood") and not whispers._queue.has(&"tend"), "a locked obstacle whispers Dead wood, not Tend")
	dreams.clearing_open = true
	whispers._process(0.0)
	_check(whispers._queue.has(&"tend"), "Tend comes once clearing opens")
	dreams.clearing_open = false
	clearer._hover_obstacle = null
	clearer.set_process(true)
	whispers.set_enabled(false)

	# --- Nightmare info on hover ---
	var info = main.get_node("%NightmareInfo")
	var shade: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	shade.set_process(false)
	info._target = shade
	info._known.clear()  # As if never met before
	await process_frame
	_check(info.visible and info._title.text.begins_with(shade.enemy_data.display_name), "hover panel shows the nightmare")
	_check(info._title.text.contains("New"), "a never-met nightmare gets the New tag")
	_check(info._body.text.contains(shade.enemy_data.trait_text) and info._body.text.contains("Health"),
		"hover panel shows the trait and health")

	# --- Leak feedback ---
	var leak = main.get_node("LeakEffect")
	var map_generator = main.get_node("%MapGenerator")
	shade.set_process(true)
	shade.position = shade.grid.calculate_map_position(map_generator.endPath) + Vector2(0, -8)
	shade.set_path(PackedVector2Array([map_generator.endPath]))
	await _frames(10)
	_check(not leak._pulses.is_empty() and run_state.leaves_lost == 1, "a leak pulses at the Heartwood and counts a lost leaf")

	# --- G grows the selected Warden ---
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	run_state.dew = 500
	placer.tower_data = load("res://resource/tower/sprout.tres")
	var cell := _free_cell(map_generator)
	placer._try_build(cell)
	seller.select(seller.get_tower_at(cell))
	_check(not seller.grow_selected(), "G does nothing without an unlocked form")
	dreams.unlocked["sporeling"] = true
	_check(seller.grow_selected() and seller.get_tower_at(cell).tower_data.get_id() == "sporeling", "G grows the Sprout")

	# --- Pause summary and Abandon run ---
	var pause = main.get_node("%PauseMenu")
	var summary: String = pause.get_run_summary()
	_check(summary.contains("Drift 0") and summary.contains("Families"), "pause shows a run summary")
	pause.open()
	_check(paused, "the pause menu pauses")
	pause._abandon()
	await _frames(2)
	var results: ResultsScreen = main.get_node("%ResultsScreen")
	_check(run_state.is_over and not run_state.won and results.visible, "Abandon run ends the run (results still shown)")
	_check(not results.breakdown.is_empty(), "abandoning still earns Seeds")
	var stats := results.get_stats_text()
	_check(stats.contains("Leaves lost: 1") and stats.contains("Longest path"), "results show the run's stats (%s)" % stats)

	main.queue_free()
	await process_frame
	print("ui test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _free_cell(map_generator) -> Vector2:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	for i in range(3, path.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if not path.has(cell) and map_generator.can_block(cell):
				return cell
	return Vector2(-1, -1)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
