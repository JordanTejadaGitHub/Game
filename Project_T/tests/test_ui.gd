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
	# Seedling Gift: a seed badge with the count on the Sprout button, hidden at 0.
	var hud_node = main.get_node("HUD")
	_check(hud_node._seed_badge != null and not hud_node._seed_badge.visible, "no seed badge without free Sprouts")
	run_state.add_sprout_charges(2)
	_check(hud_node._seed_badge.visible, "free Sprouts show a seed badge on the Sprout button")
	run_state.add_sprout_charges(-2)
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

	# --- Dreams row: an icon per Dream, with Few and Mighty's live bonus following the Wardens ---
	var row = main.get_node("%DreamsRow")
	var few: UpgradeData = null
	for card in dreams.pool:
		if card.id == "few_and_mighty":
			few = card
	_check(few != null, "Few and Mighty is in the pool")
	if few != null:
		var before_count: int = row._icons.size()
		dreams.take(few)
		await process_frame
		_check(row._icons.size() == before_count + 1 and row._icons[-1].card == few, "taking a Dream adds its icon")
		var live_before: String = row._icons[-1].live
		_check(live_before == dreams.get_live_bonus_text(few) and live_before.begins_with("+"), "the icon shows the live bonus (%s)" % live_before)
		var row_placer: TowerPlacer = main.get_node("%TowerPlacer")
		main.get_node("%RunState").dew = 500
		row_placer.tower_data = load("res://resource/tower/sprout.tres")
		row_placer._try_build(_free_cell(main.get_node("%MapGenerator")))
		row.refresh()
		_check(row._icons[-1].live != live_before, "planting a Warden updates it (%s → %s)" % [live_before, row._icons[-1].live])
		_check(row.get_list_text().contains("Few and Mighty"), "Dreams this run lists it")

	# --- Dreamlight: the counter beside the Dew, and Remember at rests ---
	var light: Label = main.get_node("HUD/DreamlightLabel")
	dreams.add_dreamlight(2)
	_check(light.text == str(dreams.dreamlight), "the Dreamlight counter follows DreamState (%s)" % light.text)
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	light.gui_input.emit(tap)
	_check((main.get_node("%ToastLabel") as Label).text.begins_with("Dreamlight"), "tapping the counter explains it (no hover-only info)")
	var drift_panel = main.get_node("HUD/DriftPanel")
	var saved_started := director.drifts_started
	director.drifts_started = 0
	drift_panel._process(0.0)
	_check(not drift_panel._remember_button.visible, "no Remember before the first family pick")
	director.drifts_started = 5
	drift_panel._process(0.0)
	_check(drift_panel._remember_button.visible == director.is_resting()
		and drift_panel._remember_button.text == "Remember (%d)" % dreams.dreamlight, "Remember at a rest, with the Dreamlight")
	director.drifts_started = saved_started

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

	# --- Family pick: statuses, branch previews, and Peek (screens_ui.md "Choice screens") ---
	var family = main.get_node("%FamilyPickScreen")
	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	_check(family.get_status_text(sporeling) == "Applies Spored", "the family card names its status (%s)" % family.get_status_text(sporeling))
	_check(family.get_branches(sporeling).size() == 2, "the family card previews two branches")
	family.show_pick(&"first")
	family.peek.set_peeking(true)
	_check(family.visible and family.mouse_filter == Control.MOUSE_FILTER_IGNORE and paused, "Peek shows the map, time still stopped")
	family.peek.set_peeking(false)
	_check(family.mouse_filter == Control.MOUSE_FILTER_STOP, "and Back reopens the pick")
	family.choose(family.offer[0])

	# --- Settings: tabs, and the high-contrast route line ---
	var settings := SettingsPanel.new()
	main.add_child(settings)
	var tab_names: Array = settings.tabs.get_children().map(func(c: Node) -> String: return c.name)
	_check(tab_names.has("Audio") and tab_names.has("Display") and tab_names.has("Accessibility") and tab_names.has("Controls"),
		"settings are in tabs (%s)" % [tab_names])
	settings.queue_free()
	var line := Line2D.new()
	RouteLine._high = 1
	RouteLine.apply(line, Color.WHITE)
	_check(line.width == RouteLine.CONTRAST_WIDTH and line.default_color == RouteLine.CONTRAST_COLOR, "high-contrast route line")
	RouteLine._high = 0
	RouteLine.apply(line, Color.WHITE)
	_check(line.width == 6.0 and line.default_color == Color.WHITE, "normal route line")
	RouteLine._high = -1
	line.free()

	# --- Pause summary and Abandon run ---
	var pause = main.get_node("%PauseMenu")
	(main.get_node("HUD/MenuButton") as Button).pressed.emit()
	_check(pause.visible, "the on-screen Menu button opens the pause menu")
	pause.close()
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
