extends SceneTree

# Headless test for the "Damage that means something" UI (screens_ui.md; numbers from WardenMeter):
# the DriftPanel benchmark (forecast at a rest, the live line in a drift, its colour), the drift meter
# (header, rows, click selects the Warden), the DPS tags' visibility rule, and the rest report's maze /
# Carrying / Underused lines. Plays drift 1 with a Warden by the path and one far away.
#   godot --headless --path . --script res://tests/test_damage_ui.gd --fixed-fps 60

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
	placer.set_build_mode(false)
	_check(near != null and far != null, "planted a Warden by the path and one far away")
	var meter: DriftMeter = main.get_node("HUD/DriftMeter")
	director.start_next_drift()
	var during := ""
	for i in 60 * 90:
		if director.awaiting_family_pick or director.is_resting():
			break
		if i == 60 * 15:
			meter.refresh()
			during = meter._header.text
		await process_frame
	# Playtest fixes 2026-09-30: the needed-DPS estimate is dev-only; no loose line by Start.
	_check(during.contains("Maze ") and not during.contains("needs ~"), "in a drift: the maze's DPS, no estimate outside dev runs (" + during + ")")
	_check(not "benchmark" in main.get_node("HUD/DriftPanel"), "the DriftPanel has no loose benchmark line")

	# The drift meter: header, rows, a click selects and glides.
	meter.set_open(true)
	_check(meter.visible and meter._header.text.contains("Maze ") and meter._rows.get_child_count() >= 2,
		"the drift meter lists the Wardens (%s, %d rows)" % [meter._header.text, meter._rows.get_child_count()])
	var first: Button = meter._rows.get_child(0)
	meter._fit()
	meter.refresh()
	_check(meter._rows.get_child(0) == first, "refreshing keeps the same row buttons (a click isn't lost mid-press)")
	_check(not first.mouse_force_pass_scroll_events and not meter.mouse_force_pass_scroll_events,
		"the wheel over the meter never reaches the map")
	meter._sort.pressed.emit()
	_check(meter._sort.text == "Sort: % of damage", "the sort button reads Sort: % of damage")
	meter._sort.pressed.emit()
	first = meter._rows.get_child(0)
	first.pressed.emit()
	var seller = main.get_node("%TowerSeller")
	_check(not seller.selection.is_empty() and seller.selection[0] == near, "clicking a meter row selects that Warden")
	_check(first.get_theme_color("font_color") == DriftMeter.CARRYING_COLOR, "the top Warden's row is gold (rank on the board)")
	_check(DriftMeter.rank_color(0, 10) == DriftMeter.CARRYING_COLOR and DriftMeter.rank_color(5, 10) == DriftMeter.FINE_COLOR
		and DriftMeter.rank_color(9, 10) == DriftMeter.UNDERUSED_COLOR and DriftMeter.rank_color(0, 1) == DriftMeter.CARRYING_COLOR
		and DriftMeter.rank_color(1, 2) == DriftMeter.FINE_COLOR, "rank colours: top ~20% gold, bottom ~20% dim, the rest white")
	var far_row: Button = meter._rows.get_child(meter._rows.get_child_count() - 1)
	_check(far_row.tooltip_text.contains("Underused: few nightmares in range"), "the underused reason in its tooltip")
	# Crowding: the meter never reaches the DriftPanel (its rows scroll) and sits below the nightmare info.
	meter._fit()
	var drift_panel_top: float = main.get_node("HUD/DriftPanel").get_global_rect().position.y
	_check(meter.get_global_rect().end.y <= drift_panel_top + 1.0 or meter._scroll.custom_minimum_size.y <= 72.0,
		"the open meter stays above the DriftPanel (%.0f vs %.0f)" % [meter.get_global_rect().end.y, drift_panel_top])
	seller.set_selection([])

	# DPS tags: at a rest (or paused / build mode) every attacking Warden, during a drift only the selected.
	var tags: DpsTags = null
	for child in main.get_children():
		if child is DpsTags:
			tags = child
	_check(tags != null, "the DPS tags layer exists")
	if tags != null:
		tags._clock = 0.0
		tags._process(0.1)
		if director.is_resting():
			_check(tags.all_shown() and tags._shown_towers().size() >= 1, "at a rest every Warden's tag shows")
		_check(not tags._rows.is_empty() and tags.tag_text(tags._rows.values()[0]).contains(" DPS"), "a tag reads N DPS")

	# Rest report: the maze line first, then Carrying / Underused.
	var text := RestReport.meter_text(main.get_node("%RestReport"))
	_check(text.contains("Maze ") and text.contains("Carrying: ") and text.contains("Underused: "),
		"the rest report's maze / carrying / underused lines (" + text.replace("\n", " | ") + ")")
	# The last drift's DPS lives in the meter panel.
	meter.refresh()
	_check(not director.is_resting() or (meter._last.visible and meter._last.text.begins_with("Last drift ")),
		"at a rest: the meter shows Last drift N DPS (" + meter._last.text + ")")
	_check(DriftMeter.ratio_color(1.2) == DriftMeter.GOOD and DriftMeter.ratio_color(1.0) == DriftMeter.CLOSE and DriftMeter.ratio_color(0.5) == DriftMeter.SHORT,
		"green ≥110%, amber 90–110%, red below")

	main.queue_free()
	await process_frame
	print("damage ui test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

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

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
