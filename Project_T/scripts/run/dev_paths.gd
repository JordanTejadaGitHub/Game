class_name DevPaths

# Where tests, sims and captures keep their temporary files (user, 2026-10-05: nothing project-related on C:). Since the
# save folder moved (UserDirMigration), user:// is the player's real profile in %APPDATA%; scratch files go to the
# project's logs folder on D: instead, in debug builds on the dev machine. Elsewhere (a release build, another machine)
# they stay under user://.
#   HeartwoodMemory.file_path = DevPaths.scratch("test_x_%d.json" % OS.get_process_id())
# Command-line runs can also redirect user:// as a whole: D:\Projects\logs\scripts\godot_dev.sh / .ps1 set APPDATA.

const ROOT := "D:/Projects/logs/userdata/dev"

static func available() -> bool:
	return OS.is_debug_build() and DirAccess.dir_exists_absolute("D:/Projects/logs")

# An absolute path for a scratch file `name` (its folder made), or "user://<name>" off the dev machine.
static func scratch(name: String) -> String:
	if not available():
		return "user://" + name
	var path := ROOT.path_join(name)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	return path

# Whether this process writes into the player's real profile: a debug --script run (a test, sim or tool) whose user://
# wasn't redirected (godot_dev.sh / the suite set APPDATA). UserDirMigration warns once.
static func script_in_real_profile() -> bool:
	if not OS.is_debug_build():
		return false
	var args := OS.get_cmdline_args()
	return "--script" in args and OS.get_user_data_dir().replace("\\", "/").contains("/AppData/Roaming/")
