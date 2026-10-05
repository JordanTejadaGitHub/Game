extends SceneTree

# Headless test for the save-folder move (scripts/run/user_dir_migration.gd): the old folder's files and subfolders are
# copied into the new one once when the new one has no profile; a second launch copies nothing; a new folder that
# already has a profile is never touched; the old folder stays. Temp folders only.
#   godot --headless --path . --script res://tests/test_user_dir_migration.gd

var failures := 0

func _initialize() -> void:
	var base := OS.get_user_data_dir().path_join("test_user_dir_migration_%d" % OS.get_process_id())
	var from := base.path_join("old")
	var to := base.path_join("new")
	DirAccess.make_dir_recursive_absolute(from.path_join("logs"))
	_write(from.path_join("heartwood.json"), "{\"seeds\": 302}")
	_write(from.path_join("run_history.json"), "[]")
	_write(from.path_join("logs/godot.log"), "log")
	var script := load("res://scripts/run/user_dir_migration.gd")
	var copied: int = script.move_once(from, to)
	_check(copied == 3 and FileAccess.get_file_as_string(to.path_join("heartwood.json")) == "{\"seeds\": 302}"
		and FileAccess.file_exists(to.path_join("logs/godot.log")) and FileAccess.file_exists(to.path_join(script.MARKER)),
		"the old folder is copied across once, subfolders too (%d files)" % copied)
	_check(FileAccess.file_exists(from.path_join("heartwood.json")), "the old folder stays")
	_write(from.path_join("heartwood.json"), "{\"seeds\": 999}")
	_check(script.move_once(from, to) == 0 and FileAccess.get_file_as_string(to.path_join("heartwood.json")) == "{\"seeds\": 302}",
		"a second launch copies nothing: the new profile is never overwritten")
	var fresh := base.path_join("empty_old")
	DirAccess.make_dir_recursive_absolute(fresh)
	_check(script.move_once(fresh, base.path_join("new2")) == 0, "no old profile: nothing to move")
	_remove_tree(base)
	print("user dir migration test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _remove_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for name in dir.get_files():
		DirAccess.remove_absolute(path.path_join(name))
	for sub in dir.get_directories():
		_remove_tree(path.path_join(sub))
	DirAccess.remove_absolute(path)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
