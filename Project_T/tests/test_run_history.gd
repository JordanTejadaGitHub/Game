extends SceneTree

# Headless test for the run history (balance_simulation.md "Run history"): a run end adds one record
# (run fields, per-drift rows with the bot's column names, a report), newest first, capped; tests
# never write the real user://run_history.json; the Codex lists the runs.
#   godot --headless --path . --script res://tests/test_run_history.gd --fixed-fps 60

var failures := 0
var TEMP_PATH := "user://test_run_history_%d.json" % OS.get_process_id()
var PROFILE_PATH := "user://test_run_history_profile_%d.json" % OS.get_process_id()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = PROFILE_PATH
	var real := ProjectSettings.globalize_path(RunHistory.DEFAULT_PATH)
	var real_before := FileAccess.get_modified_time(RunHistory.DEFAULT_PATH) if FileAccess.file_exists(RunHistory.DEFAULT_PATH) else -1

	# 1. By default a test run writes nothing (not the real file, not anything).
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.get_node("%RunState").end_run(false)
	await process_frame
	_check((FileAccess.get_modified_time(RunHistory.DEFAULT_PATH) if FileAccess.file_exists(RunHistory.DEFAULT_PATH) else -1) == real_before,
		"a test run never writes the real run history (%s)" % real)
	main.queue_free()
	await process_frame

	# 2. Recording into a temp file: a short run, then the end.
	RunHistory.file_path = TEMP_PATH
	RunHistory.record_in_tests = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_PATH))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	director.start_next_drift()
	for i in 60 * 20:
		if director.awaiting_family_pick or director.is_resting():
			break
		await process_frame
	var history := root.get_tree().get_first_node_in_group(RunHistory.GROUP) as RunHistory
	_check(history != null, "the HUD makes the run history")
	# Called early: drift 91 starts while drift 90's nightmare is still out; its damage stays drift 90's.
	var straggler := Node2D.new()
	root.add_child(straggler)
	history._on_drift_started(90)
	history._origin[straggler.get_instance_id()] = 90
	director._called_early = true  # As start_next_drift sets it while 90 is still arriving
	history._on_drift_started(91)
	director._called_early = false
	_check(not history._open[90].called_early and history._open[91].called_early, "a drift row says whether it was called early")
	director.early_calls = 3
	director.call_early_dew = 7
	var hit := DamageLog.Event.new()
	hit.enemy = straggler
	hit.amount = 50.0
	history._on_damage(hit)
	_check(float(history._open[90].damage) == 50.0 and float(history._open[91].damage) == 0.0,
		"damage counts for the drift that spawned the nightmare, even after the next was called early")
	straggler.queue_free()
	# Route profiles (Balancing: where the Dew sits on the route, where nightmares die).
	var map: Node2D = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var container: Node = main.get_node("%TowerContainer")
	run_state.dew = 1000
	placer.select_tower(load("res://resource/tower/sprout.tres"))
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	for cell in route.slice(2, 8):
		for side in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			if container.get_child_count() == 0 and map.is_buildable(cell + side):
				placer._try_build(cell + side)
	placer.set_build_mode(false)
	var invested := history.invested_by_progress()
	var spread: float = invested.off_route
	for dew in invested.invested:
		spread += dew
	_check(container.get_child_count() > 0 and float(invested.total) > 0.0 and is_equal_approx(spread, float(invested.total))
		and float(invested.off_route) == 0.0, "a Warden by the route spreads its Dew over the bins it covers (%s)" % [invested])
	var spawner = main.get_node("%EnemyContainer")
	var walker: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"), 1.0, {}, false)
	await process_frame
	history._on_dispelled(walker)
	history._note_leak(walker)
	_check(int(history._route_block.dispels[0]) == 1 and float(history._route_block.dispel_health[0]) > 0.0
		and int(history._route_block.leaked) == 1, "a dispel counts in its route bin (just spawned: the first), a leak apart")
	run_state.abandoned = true
	run_state.end_run(false)
	await process_frame
	var runs := RunHistory.load_runs()
	_check(runs.size() == 1, "one run saved (%d)" % runs.size())
	if not runs.is_empty():
		var record: Dictionary = runs[0]
		_check(record.result == "abandoned" and int(record.survived) >= 1 and int(record.seed) != 0 and record.has("grove")
			and record.has("perks") and record.has("dew") and record.has("leaves_lost_by_act"), "the run's fields (%s)" % record.result)
		var drifts: Array = record.drifts
		_check(not drifts.is_empty() and drifts[0].has_all(["drift", "act", "seconds", "health_spawned", "damage", "leaks",
			"leaves_lost", "leaves_left", "banked", "closest"]) and int(drifts[0].health_spawned) > 0,
			"per-drift rows use the bot's column names (%s)" % [drifts[0] if not drifts.is_empty() else {}])
		var report := RunHistory.report_text(record)
		_check(report.contains("Result: abandoned") and report.contains("drift,act,seconds,health_spawned"), "the copyable report")
		_check(int(record.get("early_calls", -1)) == 3 and int(record.get("dew_call_early", -1)) == 7
			and report.contains("Called early: 3 drifts · 7 Dew") and report.contains(",closest,called_early"),
			"the record counts drifts called early and their Dew; the CSV has a called_early column")
		var blocks: Array = record.get("route_blocks", [])
		_check(not blocks.is_empty() and blocks[-1].dispels.size() == RunHistory.ROUTE_BINS and blocks[-1].invested.size() == RunHistory.ROUTE_BINS
			and int(blocks[-1].leaked) >= 1 and record.has("heart_share"), "route profiles per block (%s)" % [blocks])
		_check(report.contains("kills by route: ") and report.contains("| leaked ") and report.contains("Dew by route: ")
			and report.contains("Heart share: "), "the report's route lines")
		var heat_map := String(record.get("heat_map", ""))
		_check(heat_map != "" and FileAccess.file_exists(heat_map), "a heat map PNG next to the record (%s)" % heat_map)
		if heat_map != "":
			DirAccess.remove_absolute(ProjectSettings.globalize_path(heat_map))
			DirAccess.remove_absolute(ProjectSettings.globalize_path(heat_map.get_base_dir()))
		# The exact build (balance_simulation.md): content id + label, and the tuning snapshot.
		_check(String(record.get("build", {}).get("id", "")).length() == 6 and report.contains("Build ")
			and int(record.get("balance", {}).get("starting_dew", 0)) > 0 and record.balance.has("health_by_drift"),
			"the record carries its build and balance (%s)" % record.get("build", {}))
	# The Codex lists it.
	var codex: CodexPanel = main.get_node("%PauseMenu").codex
	codex.open()
	await process_frame
	_check(codex.past_run_entries.size() == 1 and codex.past_run_entries[0].find_child("Copy", true, false) != null,
		"the Codex's Past runs page lists it with Copy run report")
	codex.visible = false
	main.queue_free()
	await process_frame

	# 3. Newest first, capped at MAX_RUNS.
	var many: Array = []
	for i in RunHistory.MAX_RUNS + 5:
		many.append({"survived": i})
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(many))
	file.close()
	var probe := RunHistory.new()
	probe.save_run({"survived": 999})
	probe.free()
	runs = RunHistory.load_runs()
	_check(runs.size() == RunHistory.MAX_RUNS and int(runs[0].survived) == 999, "newest first, the last %d kept" % RunHistory.MAX_RUNS)

	# 4. Asked to record while pointed at the real file: still never written.
	RunHistory.file_path = RunHistory.DEFAULT_PATH
	var guard := RunHistory.new()
	guard.save_run({"survived": 1})
	guard.free()
	_check((FileAccess.get_modified_time(RunHistory.DEFAULT_PATH) if FileAccess.file_exists(RunHistory.DEFAULT_PATH) else -1) == real_before,
		"record_in_tests never writes the real file")

	RunHistory.record_in_tests = false
	RunHistory.file_path = RunHistory.DEFAULT_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	print("run history test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
