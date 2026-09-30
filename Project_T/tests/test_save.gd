extends SceneTree

# Headless test for the mid-run save, resume, Seeds and the results screen. Uses temp save files,
# never the player's own run or profile.
#   godot --headless --path . --script res://tests/test_save.gd --fixed-fps 60

var RUN_PATH := "user://test_run_save_%d.json" % OS.get_process_id()  # Per process: parallel sessions share user://
var PROFILE_PATH := "user://test_heartwood_%d.json" % OS.get_process_id()  # Per process: parallel sessions share user://

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	RunSaver.file_path = RUN_PATH
	HeartwoodMemory.file_path = PROFILE_PATH
	RunSaver.delete_save()
	_delete(PROFILE_PATH)

	# --- Play to the first rest, change the forest, let it autosave ---
	var main := await _new_run()
	var saver: RunSaver = main.get_node("%RunSaver")
	saver.autosave = true
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	var map_generator = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var clearer: ObstacleClearer = main.get_node("%ObstacleClearer")
	main.get_node("%DreamState").clearing_open = true  # Normally a clearing Dream unlocks clearing
	var family: Control = main.get_node("%FamilyPickScreen")
	var dreams: DreamState = main.get_node("%DreamState")

	await _frames(3)
	_check(RunSaver.has_save(), "the opening rest is saved right away")
	director.start_next_drift()
	await _play_until(main, func() -> bool: return director.awaiting_family_pick)
	var family_id: String = family.offer[0].get_id()
	family.choose(family.offer[0])
	director.start_next_drift()
	await _play_until(main, func() -> bool: return director.drifts_started == 5 and director.is_resting(), 9000)
	await _settle(main)

	run_state.dew = 500
	placer.tower_data = load("res://resource/tower/sprout.tres")
	var cell := _free_cell(map_generator)
	var sprout_cost := placer.get_cost(placer.tower_data)
	placer._try_build(cell)
	main.get_node("%TowerSeller").get_tower_at(cell).set_meta(&"drifts_stood", 7)  # Old Growth
	main.get_node("%TowerSeller").get_tower_at(cell).set_meta(&"underdog", true)  # Underdog's mark
	var obstacle_cell: Vector2 = map_generator.obstacles.keys()[0]
	clearer.try_clear(obstacle_cell)
	run_state.add_free_clears(2)  # Clearing Dream cards
	var fertile_cell := _free_cell(map_generator)
	run_state.fertile_cells[fertile_cell] = true
	saver._dirty = true
	await _frames(3)
	var saved := {"seed": map_generator.map_seed, "dew": run_state.dew, "leaves": run_state.leaves,
		"cleansed": run_state.creatures_cleansed, "tended": run_state.obstacles_tended}
	var rolled := _drift_prints(director)  # Random drifts: the resumed run must meet the same ones
	_check(RunSaver.has_save(), "a rest autosaves")
	# The run history's record rides in the save (a Save & quit run is recorded whole).
	var saved_file = JSON.parse_string(FileAccess.get_file_as_string(RUN_PATH))
	var history_rows := -1
	if saved_file is Dictionary and saved_file.has("history"):
		history_rows = saved_file.history.run.drifts.size()
	_check(history_rows >= 1, "the save carries the run history's record (%d drift rows)" % history_rows)
	main.queue_free()
	await process_frame

	# --- Continue ---
	RunSaver.resume_next = true
	main = await _new_run()
	await _frames(2)
	director = main.get_node("%DriftDirector")
	run_state = main.get_node("%RunState")
	map_generator = main.get_node("%MapGenerator")
	dreams = main.get_node("%DreamState")
	_check(map_generator.map_seed == saved.seed, "the same map is rebuilt")
	var resumed_history := root.get_tree().get_first_node_in_group(RunHistory.GROUP) as RunHistory
	_check(resumed_history != null and int(resumed_history.run.get("resumed", 0)) == 1
		and resumed_history.run.drifts.size() == history_rows, "Continue carries the run history on (resumed once, its drift rows kept)")
	_check(_drift_prints(director) == rolled and rolled.any(func(p: String) -> bool: return p.begins_with("rolled")),
		"the same random drifts after Continue")
	_check(RestReport.templates_text(director, 2).begins_with("\nThis block: ") and RestReport.templates_text(director, 1) == "",
		"the rest report lists the rolled block's drift shapes (%s)" % RestReport.templates_text(director, 2).strip_edges())
	_check(run_state.dew == saved.dew and run_state.leaves == saved.leaves, "Dew and leaves restored")
	_check(run_state.creatures_cleansed == saved.cleansed and run_state.obstacles_tended == saved.tended,
		"Seed counters restored")
	var tower: Tower = main.get_node("%TowerSeller").get_tower_at(cell)
	_check(tower != null and tower.tower_data.get_id() == "sprout" and tower.invested_dew == sprout_cost, "the Sprout is back")
	_check(tower != null and int(tower.get_meta(&"drifts_stood", 0)) == 7, "Old Growth: its drifts stood are kept")
	_check(tower != null and tower.get_meta(&"underdog", false) == true, "Underdog: its mark is kept")
	_check(not map_generator.is_buildable(cell), "and it blocks its cell again")
	_check(map_generator.get_obstacle(obstacle_cell) == null, "the tended obstacle stays gone")
	_check(dreams.is_unlocked(family_id), "the family pick is remembered")
	_check(run_state.free_clears == 2 and run_state.fertile_cells.has(fertile_cell), "free clears and fertile cells restored")
	_check(director.drifts_started == 5 and director.is_resting(), "resumes at the rest after drift 5")
	_check(director.start_next_drift() and director.drifts_started == 6, "and plays on from drift 6")

	# --- Run end: Seeds banked, save deleted ---
	main.get_node("%RunSaver").autosave = true
	var results: ResultsScreen = main.get_node("%ResultsScreen")
	results.bank_in_tests = true
	run_state.leaves = 1
	var walker: Node2D = main.get_node("%EnemyContainer").get_enemies()[0]
	walker.position = walker.grid.calculate_map_position(map_generator.endPath) + Vector2(0, -8)
	walker.set_path(PackedVector2Array([map_generator.endPath]))
	await _frames(40)  # Drift 6 is slow Bark Beetles
	_check(run_state.is_over and results.visible, "losing shows the results screen")
	if results.breakdown.is_empty():
		print("save test: %d FAILED" % failures)
		quit(failures)
		return
	var total: int = results.breakdown[-1][1]
	var expected: int = mini(5 / 2, 50) + saved.cleansed / RunState.CLEANSES_PER_SEED + saved.tended + 20  # + first-run bonus
	_check(total == expected, "Seeds: drifts, cleansed, tended, first run = %d (got %d, %s)" % [expected, total, results.breakdown])
	_check(HeartwoodMemory.load_data().seeds == total and HeartwoodMemory.load_data().runs_played == 1, "Seeds banked")
	_check(not RunSaver.has_save(), "the run save is deleted when the run ends")
	_check(not HeartwoodMemory.is_first_run(), "no first-run bonus next time")

	main.queue_free()
	await process_frame

	# --- Test Grove runs never bank Seeds or count as runs ---
	TestGrove.force_on = true
	var before := HeartwoodMemory.load_data()
	main = await _new_run()
	var grove_results: ResultsScreen = main.get_node("%ResultsScreen")
	grove_results.bank_in_tests = true
	main.get_node("%RunState").end_run(false)
	await _frames(2)
	var after := HeartwoodMemory.load_data()
	_check(grove_results.not_banked and after.seeds == before.seeds and after.runs_played == before.runs_played,
		"a Test Grove run banks nothing")
	TestGrove.force_on = false
	main.queue_free()
	await process_frame
	RunSaver.delete_save()
	_delete(PROFILE_PATH)
	print("save test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)


func _new_run() -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	return main

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _play_until(main: Node, done: Callable, max_frames: int = 4000) -> void:
	for i in max_frames:
		if done.call():
			return
		_dismiss(main)
		for enemy in main.get_node("%EnemyContainer").get_enemies():
			enemy.take_damage(1000000)
		await process_frame
	_check(false, "timed out waiting (%d frames)" % max_frames)

func _settle(main: Node) -> void:
	for i in 10:
		_dismiss(main)
		await process_frame

func _dismiss(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	if dreams.is_offering():
		if dreams.can_skip():
			dreams.skip()
		else:
			dreams.choose(dreams.current_offer[0])
	var omens = get_first_node_in_group(&"omens")
	if omens != null and omens.is_offering():
		omens.choose(null)

func _free_cell(map_generator) -> Vector2:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	for i in range(4, path.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if not path.has(cell) and map_generator.can_block(cell):
				return cell
	return Vector2(-1, -1)

func _delete(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

# Each drift as text (template + kinds, counts, elites), to compare two runs' rolls.
func _drift_prints(director: DriftDirector) -> Array[String]:
	var prints: Array[String] = []
	for number in range(1, director.get_total_drifts() + 1):
		var template := DriftRoller.template_of(director, number)
		var parts: Array[String] = ["rolled " + String(template) if template != &"" else "hand"]
		for group in director.drifts[number - 1].groups:
			for entry in group.entries:
				parts.append("%s×%d%s" % [entry.enemy.resource_path.get_file() if entry.enemy else "?", entry.count, "!" if entry.elite else ""])
		prints.append(" ".join(parts))
	return prints
