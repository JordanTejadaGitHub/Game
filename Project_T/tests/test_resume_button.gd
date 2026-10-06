extends SceneTree

# The DriftPanel's Start button and pause (user: "If it's paused when starting drift, it should resume instead of bringing
# the next drift wave in"; "Start drift should be the same width as the buttons"). Temp profile and run save.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _run() -> void:
	var pid := OS.get_process_id()
	HeartwoodMemory.file_path = "user://test_resume_button_%d.json" % pid
	RunSaver.file_path = "user://test_resume_button_run_%d.json" % pid
	root.size = Vector2i(1280, 800)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 4242
	root.add_child(main)
	await _frames(3)
	var panel = main.get_node("HUD/DriftPanel")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var speed = main.get_node("%GameSpeed")
	var start: Button = panel._start_button
	var auto: Control = panel._auto_toggle
	var row := auto.get_parent() as Control
	await _frames(2)
	_check(absf(start.size.x - row.size.x) < 1.0 and absf(start.get_global_rect().end.x - row.get_global_rect().end.x) < 1.0,
		"Start is as wide as the speed row, on the same right edge (%.0f vs %.0f)" % [start.size.x, row.size.x])
	# At a rest, paused: one press starts the drift and unpauses.
	speed.set_paused(true)
	await _frames(2)
	_check(start.text.begins_with("Start drift"), "paused at a rest: Start drift (%s)" % start.text)
	var started := director.drifts_started
	panel._on_start_pressed()
	await _frames(2)
	_check(director.drifts_started == started + 1 and not speed.paused, "at a rest, paused: the drift starts and the game runs")
	# Mid-drift, paused: Resume only, never a call early.
	speed.set_paused(true)
	await _frames(2)
	_check(start.text == "Resume (Enter)" and not start.disabled, "paused mid-drift: Resume (%s)" % start.text)
	started = director.drifts_started
	panel._on_start_pressed()
	await _frames(2)
	_check(not speed.paused and director.drifts_started == started, "Resume unpauses and calls nothing early")
	print("resume button test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	RunSaver.safe_quit(self, failures)
