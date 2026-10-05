extends Node

# The save folder moved (the user, release builds 2026-10-05): from Godot's default %APPDATA%\Godot\app_userdata\Heartwood TD to
# %APPDATA%\TopBunk Studios\Heartwood TD (project setting application/config/use_custom_user_dir). On the first launch after
# the move, if the new folder has no profile yet, everything in the old folder is copied across once (Seeds, the Grove, run
# history, settings, the mid-run save), so nothing is lost. The old folder is never deleted. The first autoload, so it runs
# before anything reads user://.

const PROFILE := "heartwood.json"
const OLD_FOLDER := "Godot/app_userdata/Heartwood TD"
const MARKER := "moved_from_godot_userdata.txt"  # Written after a copy: where it came from, when

func _init() -> void:
	var to := OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(to)  # A fresh machine: the custom folder doesn't exist yet, and saves need it
	var from := OS.get_data_dir().path_join(OLD_FOLDER)
	if to.simplify_path() == from.simplify_path():
		return  # Not using the custom folder (nothing moved)
	move_once(from, to)

# Copies `from` into `to` when `to` has no profile and `from` has one. Returns the number of files copied (0 = nothing done).
static func move_once(from: String, to: String) -> int:
	if FileAccess.file_exists(to.path_join(PROFILE)) or not FileAccess.file_exists(from.path_join(PROFILE)):
		return 0
	DirAccess.make_dir_recursive_absolute(to)
	var copied := _copy_tree(from, to)
	var marker := FileAccess.open(to.path_join(MARKER), FileAccess.WRITE)
	if marker != null:
		marker.store_line("Copied %d files from %s on %s" % [copied, from, Time.get_datetime_string_from_system()])
		marker.close()
	return copied

static func _copy_tree(from: String, to: String) -> int:
	var dir := DirAccess.open(from)
	if dir == null:
		return 0
	var count := 0
	DirAccess.make_dir_recursive_absolute(to)
	for name in dir.get_files():
		if not FileAccess.file_exists(to.path_join(name)):  # Never overwrite anything already in the new folder
			if DirAccess.copy_absolute(from.path_join(name), to.path_join(name)) == OK:
				count += 1
	for sub in dir.get_directories():
		count += _copy_tree(from.path_join(sub), to.path_join(sub))
	return count
