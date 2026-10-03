extends SceneTree

# The Glade gift (user: "doing this didn't feel right and was unintuitive"): pick up to 5 obstacles one by one on the
# map (click again to unselect), a "3 of 5" counter, the route previewed live, "Clear them" clears exactly those (free,
# each tended). Full game (the gifts), temp profile.

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
	HeartwoodMemory.file_path = "user://test_glade_pick_%d.json" % OS.get_process_id()
	ResultsScreen.demo_override = 0
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 4242
	root.add_child(main)
	for i in 3:
		await process_frame
	var map = main.get_node("%MapGenerator")
	var run_state: RunState = main.get_node("%RunState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	_check(HeartwoodGifts.POOL[&"glade"].place == &"obstacles" and int(HeartwoodGifts.POOL[&"glade"].size) == 5,
		"Glade is picked obstacle by obstacle, up to 5")
	var placer := GiftScreen.GiftPlacer.new(director, &"glade", false)
	main.add_child(placer)
	await process_frame
	var picks: Array = []
	for cell in map.obstacles:
		if picks.size() < 6 and map.get_obstacle_cells(cell).size() == 1:
			picks.append(cell)
	for cell in picks.slice(0, 3):
		placer.click(cell)
	_check(placer.cells.size() == 3 and placer.status().begins_with("3 of 5") and placer.is_complete(), "three picked: \"%s\"" % placer.status())
	placer.click(picks[1])
	_check(placer.cells.size() == 2 and not placer.cells.has(picks[1]), "clicking a picked one unselects it")
	for cell in picks:
		placer.click(cell)
	_check(placer.cells.size() <= 5, "never more than 5 (%d)" % placer.cells.size())
	var chosen: Array = placer.placement().cells.duplicate()
	var tended := run_state.obstacles_tended
	var gifts = main.get_tree().get_first_node_in_group(&"heartwood_gifts")
	var as_cells: Array[Vector2] = []
	as_cells.assign(chosen)
	gifts._apply(&"glade", {"cells": as_cells}, false)
	await process_frame
	_check(chosen.all(func(c: Vector2) -> bool: return map.get_obstacle(c) == null) and run_state.obstacles_tended == tended + chosen.size(),
		"\"Clear them\" clears exactly the picked ones, each tended (%d)" % chosen.size())
	placer.queue_free()
	main.queue_free()
	await process_frame
	ResultsScreen.demo_override = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
