extends SceneTree

# Headless test for mobile backgrounding (mobile_plan.md "Shorter sessions"): the app going to the
# background saves at a rest and pauses a live game; Android's Back button acts as Esc during a run.
# Uses a temp save file, never the player's own run.
#   godot --headless --path . --script res://tests/test_app_pause.gd --fixed-fps 60

var RUN_PATH := "user://test_app_pause_%d.json" % OS.get_process_id()  # Per process: parallel sessions share user://
var PROFILE_PATH := "user://test_app_pause_profile_%d.json" % OS.get_process_id()

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	RunSaver.file_path = RUN_PATH
	HeartwoodMemory.file_path = PROFILE_PATH
	RunSaver.delete_save()

	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(3)
	var saver: RunSaver = main.get_node("%RunSaver")
	saver.autosave = true
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	var menu := get_first_node_in_group(&"pause_menu")
	_check(not quit_on_go_back, "Back doesn't quit during a run")

	# --- At a rest: backgrounding saves what changed since the rest's autosave ---
	await _frames(3)
	_check(director.is_resting() and RunSaver.has_save(), "the opening rest is saved")
	run_state.dew = 777
	saver.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var saved = JSON.parse_string(FileAccess.get_file_as_string(RUN_PATH))
	_check(saved is Dictionary and int(saved.get("dew", -1)) == 777, "backgrounding at a rest saves the latest Dew (%s)" % str(saved.get("dew") if saved is Dictionary else "?"))
	if menu.visible:
		menu.close()

	# --- Mid-drift: backgrounding pauses the game, the save stays the rest's ---
	director.start_next_drift()
	await _frames(5)
	_check(not paused, "the drift runs")
	run_state.dew = 4242
	saver.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_check(paused and menu.visible, "backgrounding mid-drift opens the pause menu")
	saved = JSON.parse_string(FileAccess.get_file_as_string(RUN_PATH))
	_check(saved is Dictionary and int(saved.get("dew", -1)) == 777, "mid-drift backgrounding keeps the last rest's save")

	# --- Back closes the menu, Back again opens it ---
	saver.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _frames(2)
	_check(not menu.visible and not paused, "Back closes the pause menu and resumes")
	saver.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _frames(2)
	_check(menu.visible and paused, "Back opens the pause menu")
	saver.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_check(menu.visible and paused, "backgrounding while paused leaves the menu as it is")
	menu.close()

	main.queue_free()
	await _frames(2)
	_check(quit_on_go_back, "leaving the run gives Back its quit again")
	RunSaver.delete_save()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	print("test_app_pause: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(failures)

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   ", label)
	else:
		failures += 1
		print("  FAIL ", label)
