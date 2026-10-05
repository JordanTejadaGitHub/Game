extends SceneTree

# tools/balance_sim.gd --save-at / --from-save (balance_simulation.md "Acts 3–4 coverage", part 2): a run writes a
# RunSaver snapshot of its board at the rest after drift 5, and a second run resumes that snapshot and plays on.
# Both run as their own processes; the snapshot is the test's own (no player save is read).

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var out := ProjectSettings.globalize_path("user://test_from_save_%d" % OS.get_process_id())
	var base := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tools/balance_sim.gd",
		"--fixed-fps", "60", "--", "--profile=fresh", "--style=balanced", "--speed=8"]
	var first := []
	OS.execute(OS.get_executable_path(), base + ["--seed=3", "--last=5", "--save-at=5", "--out=" + out.path_join("a")], first, true)
	var snapshot := out.path_join("a").path_join("snapshot_fresh_balanced_seed3_d5.json")
	_check(FileAccess.file_exists(snapshot), "--save-at=5 wrote the snapshot")
	if FileAccess.file_exists(snapshot):
		var data = JSON.parse_string(FileAccess.get_file_as_string(snapshot))
		_check(typeof(data) == TYPE_DICTIONARY and int(data.get("version", 0)) == RunSaver.VERSION, "it's a RunSaver save of this version")
		_check(typeof(data) == TYPE_DICTIONARY and not (data.get("towers", []) as Array).is_empty(), "with the bot's Wardens on it")
		OS.execute(OS.get_executable_path(), base + ["--seed=99", "--last=6", "--from-save=" + snapshot,
			"--out=" + out.path_join("b")], [], true)
		var row := _summary(out.path_join("b").path_join("runs.csv"))
		_check(int(row.get("resumed_at", -1)) == 5, "--from-save resumed at the rest after drift 5 (%s)" % row.get("resumed_at"))
		_check(int(row.get("survived", 0)) >= 6, "and played on (survived %s)" % row.get("survived"))
		_check(FileAccess.file_exists(snapshot), "the snapshot itself is left as it was")
	_clean(out)
	print("balance from-save test: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(failures)

func _summary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var lines := FileAccess.get_file_as_string(path).strip_edges().split("\n")
	if lines.size() < 2:
		return {}
	var keys := lines[0].split(",")
	var values := lines[1].split(",")
	var row := {}
	for i in mini(keys.size(), values.size()):
		row[keys[i]] = values[i]
	return row

func _clean(dir: String) -> void:
	for sub in DirAccess.get_directories_at(dir):
		_clean(dir.path_join(sub))
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
