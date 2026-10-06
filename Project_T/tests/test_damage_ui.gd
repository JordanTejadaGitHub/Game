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
	# The Wardens tab: the top 5, no scroll; each row's change vs its own last drift (playtest 2026-09-30).
	_check(meter._rows.get_child_count() <= DriftMeter.TOP_ROWS and meter._rows.get_parent() == meter._body,
		"the Wardens tab lists at most 5 rows, outside any scroll")
	_check(first.get_node_or_null("Change") != null, "each row has its change label")
	_check(DriftMeter.row_change({"last_dps": 0.0})[0] == "new"
		and DriftMeter.row_change({"last_dps": 10.0, "change": 0.12}) == ["↑12%", DriftMeter.UP_COLOR]
		and DriftMeter.row_change({"last_dps": 10.0, "change": -0.08}) == ["↓8%", DriftMeter.UNDERUSED_COLOR],
		"new / ↑12% gold / ↓8% dim")
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
		# A full-screen screen (the family pick after drift 1) hides every world tag (WorldLabel.cover_while_visible): close
		# them, as the player would, before reading the tags.
		for screen in ["%FamilyPickScreen", "%DreamScreen", "HUD/OmenScreen", "HUD/BossDossier"]:
			var node := main.get_node_or_null(screen) as Control
			if node != null:
				node.visible = false
		_check(WorldLabel.covers.is_empty(), "no full-screen screen covers the map now (%s)" % [WorldLabel.covers.keys()])
		tags._clock = 0.0
		tags._process(0.1)
		if director.is_resting():
			_check(tags.all_shown() and tags._shown_towers().size() >= 1, "at a rest every Warden's tag shows")
		_check(not tags._rows.is_empty() and tags.tag_text(tags._rows.values()[0]).contains(" DPS"), "a tag reads N DPS")
		# Dense clusters (user screenshot): short tags unless focused / the meter is open, never two overlapping.
		var sample := {"dps": 182.0, "change": 0.16, "last_dps": 150.0}
		_check(tags.tag_text(sample, false) == "182 DPS" and tags.tag_text(sample, true).contains("↑16%"),
			"short tags (\"182 DPS\"); the change only when focused or with the meter open")
		tags.queue_redraw()
		await process_frame
		await process_frame
		# Never hidden (user: "sometimes the maze DPS disappear"): every shown tag is drawn; one that still overlaps after
		# its nudges is the number alone.
		var overlap := false
		for i in tags.drawn.size():
			for j in range(i + 1, tags.drawn.size()):
				if (tags.drawn[i][1] as Rect2).intersects(tags.drawn[j][1]) and String(tags.drawn[j][2]).contains(" DPS"):
					overlap = true
		_check(not overlap and tags.drawn.size() == tags._shown_towers().size(),
			"every DPS tag is drawn, a crowded one as its number (%d drawn of %d shown)" % [tags.drawn.size(), tags._shown_towers().size()])
		await _dense_row(main, tags)

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

# A dense row of 6 Wardens side by side (user: "sometimes the maze DPS disappear"): each gets a tag, drawn every frame
# in the same place (no blinking as the order would change).
func _dense_row(main: Node, tags: DpsTags) -> void:
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var map = main.get_node("MapGenerator")
	placer.tower_data = load("res://resource/tower/sporeling.tres")
	var row: Array = []
	for y in range(1, Tower.MAP_GRID.size.y - 1):
		row.clear()
		for x in range(1, Tower.MAP_GRID.size.x - 1):
			var cell := Vector2(x, y)
			var count := placer.tower_container.get_child_count()
			if map.is_buildable(cell) and map.can_block(cell) and placer._try_build(cell):
				row.append(placer.tower_container.get_child(count))
				if row.size() == 6:
					break
			else:
				row.clear()  # Not side by side: start over further on (the walls placed stay; harmless here)
		if row.size() == 6:
			break
	_check(row.size() == 6, "six Wardens side by side (%d)" % row.size())
	if row.size() < 6:
		return
	tags._clock = 1000.0  # Our rows, not the meter's
	var director: DriftDirector = main.get_node("%DriftDirector")
	director.drifts_started = maxi(director.drifts_started, 1)
	placer.build_mode = true  # Every tag shows (as at a rest)
	tags._rows.clear()
	for i in row.size():
		tags._rows[row[i].get_instance_id()] = {"tower": row[i], "dps": 100.0 + 37.0 * i, "tag_color": DriftMeter.FINE_COLOR}
	tags.queue_redraw()
	await process_frame
	await process_frame
	var first: Array = tags.drawn.map(func(d: Array) -> Rect2: return d[1])
	var tagged: Array = tags.drawn.map(func(d: Array) -> Object: return d[0])
	_check(row.all(func(t: Tower) -> bool: return tagged.has(t)), "all six get a tag (%d drawn)" % tags.drawn.size())
	tags._rows[row[0].get_instance_id()].dps = 999.0  # The ranking changes: nothing moves
	tags.queue_redraw()
	await process_frame
	await process_frame
	_check(tags.drawn.map(func(d: Array) -> Rect2: return d[1]) == first, "the tags stay put when the numbers change")

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
