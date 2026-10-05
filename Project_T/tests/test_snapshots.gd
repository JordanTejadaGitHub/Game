extends SceneTree

# Balance snapshots (RunSaver): the file name, pruning to the newest N, and that pruning never touches other files.
# Writes only to a per-process temp folder under user://, never the real snapshot folder.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	var name := RunSaver.snapshot_name(12345, 7, false)
	_check(RegEx.create_from_string(RunSaver.SNAPSHOT_PATTERN).search(name) != null, "name matches the pattern: " + name)
	_check(name.begins_with(Time.get_date_string_from_system() + "_12345_d007_"), "date, seed, drift lead the name: " + name)
	_check(not name.contains("_dev"), "a real run has no dev tag")
	_check(RunSaver.snapshot_name(-3, 12, true).ends_with("_dev.json"), "a dev run is tagged")
	_check(RegEx.create_from_string(RunSaver.SNAPSHOT_PATTERN).search(RunSaver.snapshot_name(-3, 12, true)) != null, "a negative seed matches")

	var dir := "user://test_snapshots_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var other := FileAccess.open(dir.path_join("notes.json"), FileAccess.WRITE)  # Not a snapshot: never pruned
	other.store_string("{}")
	other.close()
	for drift in range(1, 7):
		var path := RunSaver.write_snapshot("{\"drift\": %d}" % drift, RunSaver.snapshot_name(1, drift, false), dir, 3)
		_check(path != "" and FileAccess.file_exists(path), "snapshot %d written" % drift)
		OS.delay_msec(1100)  # Modified times are in seconds
	var files := Array(DirAccess.get_files_at(dir))
	_check(files.size() == 4, "3 snapshots + the other file kept: %s" % [files])
	_check(files.has("notes.json"), "other files are never pruned")
	for drift in [4, 5, 6]:
		_check(files.has(RunSaver.snapshot_name(1, drift, false)), "the newest kept: d%d" % drift)
	_check(FileAccess.get_file_as_string(dir.path_join(RunSaver.snapshot_name(1, 6, false))) == "{\"drift\": 6}", "content is the save text")
	for f in files:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(f)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))

	_check(not RunSaver.snapshots_on() or OS.is_debug_build(), "never on outside debug builds")
	print("test_snapshots: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(failures)
