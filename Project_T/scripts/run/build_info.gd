extends RefCounted
class_name BuildInfo

# The exact build a run was played on (balance_simulation.md "Run history" → "The exact build it was
# played on"; user: "versions are not commits but every change"). The player plays whatever is on
# disk, other chats' uncommitted edits included, so the id is a hash of the files' contents:
#   id      short hash of every .gd / .tres / .tscn / .gdshader / data .json under ROOTS (+ project.godot)
#   commit  git HEAD, and `dirty`: the uncommitted files at launch, each with its content hash
#   time    the newest file's modified time (when this build came to be); `label` "Sep 30 21:14 · 3f9a2c"
# Computed once per launch, on first use (~0.2 s with git, debug builds; no thread: a thread still
# hashing when a short run or test quits crashed Godot at exit); an exported build reads
# res://build_info.json (write_baked() makes it before export). Each new id is added to
# user://builds.json the first time it launches (never from tests).

const ROOTS := ["res://scripts", "res://resource", "res://scenes", "res://animation", "res://shaders", "res://assets"]
const EXTENSIONS := ["gd", "tres", "tscn", "gdshader", "json"]
const EXTRA_FILES := ["res://project.godot"]
const BAKED_PATH := "res://build_info.json"
const BUILDS_PATH := "user://builds.json"
const GIT_PATHS := ["git", "D:/Program Files/Git/cmd/git.exe", "C:/Program Files/Git/cmd/git.exe"]
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

static var builds_path := BUILDS_PATH  # Tests point it at a temp file
static var _info := {}

# Kept for callers: the build is computed on first use (current()).
static func start() -> void:
	pass

# This launch's build: {id, commit, dirty, time, label}, computed once.
static func current() -> Dictionary:
	if _info.is_empty():
		if not OS.is_debug_build():
			_info = _baked()
		else:
			_info = _compute_launch()
			_remember(_info)
	return _info

# The label (the title calls it a frame after it shows, so the hitch isn't on the first frame).
static func label_if_ready() -> String:
	return String(current().get("label", ""))

static func _compute_launch() -> Dictionary:
	var info := compute(list_files())
	info.merge(git_state(), true)
	return info

# Every hashed file under ROOTS, sorted (the order is part of the id).
static func list_files() -> Array[String]:
	var files: Array[String] = []
	for root in ROOTS:
		_walk(root, files)
	for path in EXTRA_FILES:
		if FileAccess.file_exists(path):
			files.append(path)
	files.sort()
	return files

static func _walk(dir_path: String, into: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.include_hidden = false
	for file in dir.get_files():
		if EXTENSIONS.has(file.get_extension()):
			into.append(dir_path.path_join(file))
	for sub in dir.get_directories():
		if not sub.begins_with(".") and not sub.begins_with("_"):  # _preview and friends are scratch
			_walk(dir_path.path_join(sub), into)

# {id, time, label, files} for `paths`: the same contents give the same id; any change a new one.
static func compute(paths: Array) -> Dictionary:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	var newest := 0
	for path in paths:
		var md5 := FileAccess.get_md5(path)
		if md5 == "":
			continue
		ctx.update(("%s:%s\n" % [String(path).trim_prefix("res://"), md5]).to_utf8_buffer())
		newest = maxi(newest, FileAccess.get_modified_time(path))
	var id := ctx.finish().hex_encode().left(6)
	return {"id": id, "time": Time.get_datetime_string_from_unix_time(newest), "label": make_label(id, newest),
		"files": paths.size()}

# "Sep 30 21:14 · 3f9a2c" (local time).
static func make_label(id: String, unix: int) -> String:
	if unix <= 0:
		return id
	var local := unix + int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var t := Time.get_datetime_dict_from_unix_time(local)
	return "%s %d %02d:%02d · %s" % [MONTHS[int(t.month) - 1], int(t.day), int(t.hour), int(t.minute), id]

# {commit, dirty: {path: md5}} from git, or {} when git isn't there (skipped quietly).
static func git_state() -> Dictionary:
	var project := ProjectSettings.globalize_path("res://")
	for git in GIT_PATHS:
		if git != "git" and not FileAccess.file_exists(git):
			continue
		var out: Array = []
		if OS.execute(git, ["-C", project, "rev-parse", "--short=8", "HEAD"], out, false, false) != 0 or out.is_empty():
			continue
		var state := {"commit": String(out[0]).strip_edges(), "dirty": {}}
		out.clear()
		if OS.execute(git, ["-C", project, "status", "--porcelain", "--untracked-files=no", "--", "."], out, false, false) == 0 and not out.is_empty():
			var top := String(out[0])
			for line in top.split("\n", false):
				var rel := line.substr(3).strip_edges().trim_prefix("Project_T/")
				var md5 := FileAccess.get_md5("res://" + rel)
				state.dirty[rel] = md5.left(8) if md5 != "" else "deleted"
		return state
	return {}

# Exported builds: the info written by write_baked() before export, else just the version.
static func _baked() -> Dictionary:
	if FileAccess.file_exists(BAKED_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(BAKED_PATH))
		if parsed is Dictionary:
			return parsed
	var version := String(ProjectSettings.get_setting("application/config/version", "release"))
	return {"id": version, "label": version}

# Writes res://build_info.json for an export (debug builds / tools only).
static func write_baked() -> void:
	var info := current().duplicate()
	var file := FileAccess.open(BAKED_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(info, "\t"))

# Adds a new build id to user://builds.json the first time it launches (never from test scripts
# unless they point builds_path at a temp file).
static func _remember(info: Dictionary) -> void:
	if info.is_empty() or (builds_path == BUILDS_PATH and OS.get_cmdline_args().has("--script")):
		return
	var builds: Array = []
	if FileAccess.file_exists(builds_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(builds_path))
		if parsed is Array:
			builds = parsed
	if builds.any(func(b) -> bool: return b is Dictionary and b.get("id", "") == info.id):
		return
	builds.push_front({"id": info.id, "label": info.get("label", ""), "commit": info.get("commit", ""),
		"dirty": info.get("dirty", {}), "time": info.get("time", ""), "first_launch": Time.get_datetime_string_from_system()})
	var file := FileAccess.open(builds_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(builds.slice(0, 200), "\t"))

# The key tuning numbers of this run (the live nodes' exported numbers, plus health per act edge).
static func balance_snapshot(director: DriftDirector, state: RunState) -> Dictionary:
	var snapshot := {}
	for node in [director, state]:
		if node == null:
			continue
		for prop in node.get_property_list():
			if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) or not (prop.usage & PROPERTY_USAGE_STORAGE):
				continue
			var value = node.get(prop.name)
			if value is int or value is float or (value is Array and value.all(func(v) -> bool: return v is float or v is int)):
				snapshot[prop.name] = value if not value is Array else Array(value)
	if director != null:
		var growth := {}
		for n in [1, 10, 20, 24, 26, 45, 49, 51, 74, 76, 99]:  # A plain nightmare's base scale (no Dreams, Omens, Blight)
			var act_scale: float = director.late_acts_health_multiplier if director.get_act(n) >= director.late_acts_from_act \
				else director.get_early_multiplier(n)
			growth[str(n)] = snappedf(director.get_growth(n) * act_scale, 0.001)
		snapshot["health_by_drift"] = growth
	return snapshot
