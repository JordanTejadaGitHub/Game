extends SceneTree

# BuildInfo (balance_simulation.md "Run history" → "The exact build it was played on"): the id is a
# hash of the files' contents, so the same files give the same id and any change gives a new one.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)

func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _init() -> void:
	var dir := "user://test_build_info_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(dir)
	var a := dir.path_join("a.gd")
	var b := dir.path_join("b.tres")
	_write(a, "extends Node\nvar x := 1\n")
	_write(b, "[resource]\nvalue = 2\n")
	var first := BuildInfo.compute([a, b])
	_check(String(first.id).length() == 6, "a 6-character id (%s)" % first.id)
	_check(BuildInfo.compute([a, b]).id == first.id, "the same files give the same id")
	_write(a, "extends Node\nvar x := 3\n")  # Same size, other contents
	var changed := BuildInfo.compute([a, b])
	_check(changed.id != first.id, "changing a file changes the id")
	_write(a, "extends Node\nvar x := 1\n")
	_check(BuildInfo.compute([a, b]).id == first.id, "changing it back gives the old id again")
	_check(BuildInfo.compute([a]).id != first.id, "a missing file changes the id")
	_check(BuildInfo.make_label("3f9a2c", 1790000000).ends_with(" · 3f9a2c") and BuildInfo.make_label("3f9a2c", 1790000000).length() > 12,
		"the label reads like \"Sep 30 21:14 · 3f9a2c\" (%s)" % BuildInfo.make_label("3f9a2c", 1790000000))
	# The real file list: game files only (no tests, tools or scratch).
	var files := BuildInfo.list_files()
	_check(files.has("res://scripts/run/build_info.gd") and files.has("res://project.godot")
		and not files.any(func(p: String) -> bool: return p.begins_with("res://tests/") or p.begins_with("res://tools/") or p.contains("/.")),
		"the build hashes the game's files only (%d)" % files.size())
	var start := Time.get_ticks_msec()
	BuildInfo.compute(files)
	var took := Time.get_ticks_msec() - start
	_check(took < 1500, "hashing the game stays cheap (%d ms)" % took)
	# builds.json: each new id once, only into the path it's given.
	BuildInfo.builds_path = dir.path_join("builds.json")
	BuildInfo._remember({"id": "aaaaaa", "label": "x"})
	BuildInfo._remember({"id": "aaaaaa", "label": "x"})
	BuildInfo._remember({"id": "bbbbbb", "label": "y"})
	var builds = JSON.parse_string(FileAccess.get_file_as_string(BuildInfo.builds_path))
	_check(builds is Array and builds.size() == 2 and builds[0].id == "bbbbbb", "builds.json lists each new id once, newest first")
	BuildInfo.builds_path = BuildInfo.BUILDS_PATH
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)
	print("build info test: ", "all passed" if failures == 0 else "%d FAILED" % failures)
	quit(failures)
