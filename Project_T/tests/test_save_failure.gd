extends SceneTree

var failures := 0
var path := "user://save_failure_%d.json" % OS.get_process_id()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	RunSaver.file_path = path
	HeartwoodMemory.file_path = "user://save_failure_profile_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var saver: RunSaver = main.get_node("%RunSaver")
	_check(saver.can_save_now(), "opening rest can save")
	_check(saver.save_now(), "initial save succeeds")
	var original := FileAccess.get_file_as_string(path)
	var temp := "%s.%d.tmp" % [path, OS.get_process_id()]
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(temp))
	saver._dirty = true
	main.get_node("%RunState").dew += 10
	_check(not saver.save_now(), "blocked temporary output fails safely")
	_check(saver._dirty, "failed save remains pending")
	_check(FileAccess.get_file_as_string(path) == original, "failed write preserves existing run")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
	_check(saver.save_now(), "retry succeeds")
	_check(not saver._dirty, "successful retry clears pending save")
	_check(FileAccess.get_file_as_string(path + ".bak") == original, "previous valid save retained")
	var broken := FileAccess.open(path, FileAccess.WRITE)
	broken.store_string("{broken")
	broken.close()
	_check(RunSaver.read_saved_run() == JSON.parse_string(original), "unreadable primary recovers previous valid run")
	_check(RunSaver.saved_drift() > 0, "quit summary reads the recovered save")
	var old_version: Dictionary = JSON.parse_string(original)
	old_version.version = RunSaver.VERSION - 1
	broken = FileAccess.open(path, FileAccess.WRITE)
	broken.store_string(JSON.stringify(old_version))
	broken.close()
	_check(not RunSaver.read_saved_run().is_empty(), "incompatible primary can recover compatible backup")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".bak"))
	_check(RunSaver.read_saved_run().is_empty(), "incompatible save is rejected without a compatible backup")
	# Valid JSON must still be restorable before it can displace a good backup.
	var good_data: Dictionary = JSON.parse_string(original)
	var good_backup := FileAccess.open(path + ".bak", FileAccess.WRITE)
	good_backup.store_string(original)
	good_backup.close()
	for defect in ["missing_omen", "bad_tended", "bad_tower"]:
		var malformed := good_data.duplicate(true)
		if defect == "missing_omen":
			malformed.erase("omen_seeds")
		elif defect == "bad_tended":
			malformed.tended = [[]]
		else:
			malformed.towers = [{}]
		broken = FileAccess.open(path, FileAccess.WRITE)
		broken.store_string(JSON.stringify(malformed))
		broken.close()
		_check(RunSaver.read_saved_run() == good_data, "malformed payload recovers backup: " + defect)
	var invalid_path := path + ".missing/run.json"
	RunSaver.file_path = invalid_path
	saver._dirty = true
	_check(not saver.save_now(), "missing output directory fails")
	_check(saver._dirty, "open failure keeps retry pending")
	var menu = main.get_node("%PauseMenu")
	saver.autosave = true
	current_scene = main
	menu._quit_to(false)
	_check(menu.is_asking_quit(), "save failure keeps quit dialog open")
	_check(not main.is_queued_for_deletion() and current_scene == main, "save failure does not leave the run")
	saver.autosave = false
	paused = false
	RunSaver.file_path = path
	main.queue_free()
	await process_frame
	# Invalid Continue must not create a new autosave over the rejected run.
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".bak"))
	RunSaver.resume_next = true
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	saver = main.get_node("%RunSaver")
	_check(not saver._dirty, "invalid resume never schedules an opening overwrite")
	_check(not saver.save_now(), "invalid resume blocks saving until player chooses a new run")
	_check(FileAccess.get_file_as_string(path) == "{broken", "invalid run remains recoverable")
	main.queue_free()
	await process_frame
	for file_path in [path, path + ".bak", HeartwoodMemory.file_path, HeartwoodMemory.file_path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file_path))
	print("save failure test: PASS" if failures == 0 else "save failure test: %d FAILED" % failures)
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)