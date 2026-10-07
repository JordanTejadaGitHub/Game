extends SceneTree

# Headless test for drag to build (screens_ui.md "Planting several Wardens: drag to build"): a stroke
# across the whole map skips the cell that would close the path (and plants the rest in order), the
# stroke locks to a row/column after 2 cells (Alt: free), diagonal jumps fill the corner, Dew runs out
# mid-stroke, cancel drops it, and a click is a stroke of one. Run:
#   godot --headless --path . --script res://tests/test_drag_build.gd --fixed-fps 60

const MAP_SEED := 42

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = MAP_SEED
	root.add_child(main)
	await process_frame
	var map = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var run_state: RunState = main.get_node("%RunState")
	var container: Node = main.get_node("%TowerContainer")
	var wall: TowerData = load("res://resource/tower/thornwall.tres")
	placer.set_build_mode(true)
	placer.select_tower(wall)
	# Half cells (b8305630): a stroke holds half origins (a whole cell's = cell × 2), a Warden's width apart.
	var h := 2.0 if placer.half_placement() else 1.0

	# --- Axis lock and corner fill ---
	placer.begin_stroke(Vector2(3, 3))
	placer.extend_stroke(Vector2(4, 3) * h)
	placer.extend_stroke(Vector2(6, 5) * h)  # Locked to row 3 after 2 cells
	_check(placer.get_stroke_cells() == [Vector2(3, 3) * h, Vector2(4, 3) * h, Vector2(5, 3) * h, Vector2(6, 3) * h], "a stroke locks to its row")
	placer.cancel_stroke()
	_check(not placer.stroking and placer.get_stroke_cells().is_empty(), "cancel drops the stroke")
	placer.begin_stroke(Vector2(3, 3))
	placer.extend_stroke(Vector2(4, 4) * h, true)  # Alt: free; a diagonal jump
	_check(placer.get_stroke_cells() == [Vector2(3, 3) * h, Vector2(4, 3) * h, Vector2(4, 4) * h], "a diagonal jump fills the corner cell")
	placer.cancel_stroke()

	# --- A stroke across the map: the cell that would close the path is skipped ---
	# Every route from start to end crosses the column between them, so walling all of it would close
	# the dream; the plan must leave (at least) one gap.
	var column := int((map.startPath.x + map.endPath.x) / 2.0)
	run_state.dew = 100000
	var before := container.get_child_count()
	placer.begin_stroke(Vector2(column, 0))
	placer.extend_stroke(Vector2(column, Tower.MAP_GRID.size.y - 1) * h)
	var plan := placer.get_stroke_plan()
	var closing := plan.keys().filter(func(c) -> bool: return plan[c] == "would close the dream")
	var green := plan.keys().filter(func(c) -> bool: return plan[c] == "")
	_check(not closing.is_empty(), "a path-closing cell is marked red (%d)" % closing.size())
	_check(not green.is_empty(), "the others are green (%d)" % green.size())
	_check(placer.get_stroke_tag().begins_with("%d Thornwalls · %d Dew" % [green.size(), green.size() * placer.get_cost(wall)]),
		"the tag counts them: %s" % placer.get_stroke_tag())
	var planted := placer.plant_stroke()
	_check(planted == green.size() and container.get_child_count() == before + planted, "release plants all the green cells (%d)" % planted)
	_check(not map.get_path_from(map.startPath).is_empty(), "and the dream stays open")
	for c in closing:
		_check(map.is_buildable((c / h).floor()), "the skipped cell is still open ground")

	# --- Out of Dew mid-stroke ---
	var row := 1
	var cells: Array = []
	for x in range(1, Tower.MAP_GRID.size.x - 1):
		if map.is_buildable(Vector2(x, row)):
			cells.append(Vector2(x, row))
	run_state.dew = placer.get_cost(wall) * 2
	placer.begin_stroke(Vector2(1, row))
	placer.extend_stroke(Vector2(Tower.MAP_GRID.size.x - 2, row) * h)
	plan = placer.get_stroke_plan()
	_check(plan.values().count("") <= 2 and plan.values().has("out of Dew"), "Dew runs out: the rest are skipped")
	placer.cancel_stroke()

	# --- A click is a stroke of one ---
	run_state.dew = 1000
	var one := container.get_child_count()
	var cell := Vector2.ZERO
	for c in cells:
		if map.is_buildable(c) and map.can_block(c):
			cell = c
			break
	placer.begin_stroke(cell)
	_check(placer.plant_stroke() == 1 and container.get_child_count() == one + 1, "a click plants one")

	# --- Build mode stays on until you leave it (user, maze_feel.md ec8fab5b; replaced "Shift to keep going") ---
	placer.set_build_mode(true)
	placer.after_player_placement(true)
	_check(placer.build_mode and placer.tower_data == wall, "a placement keeps it armed, the Warden still selected")
	placer.after_player_placement(false)
	_check(placer.build_mode, "a refused placement keeps it armed")
	var cancel := InputEventAction.new()
	cancel.action = "cancel_build"
	cancel.pressed = true
	placer._unhandled_input(cancel)
	await process_frame
	_check(not placer.build_mode, "right-click / Esc (cancel_build) leaves build mode")

	print("drag build test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
