extends SceneTree

# tools/balance_sim.gd --start-at (balance_simulation.md "Acts 3–4 coverage"): a run started at drift 51 gets a
# typical holding (families picked, Dreams taken, Dew and Dreamlight given, leaves set), builds its board in that one
# rest and plays on. Runs the runner as its own process for one drift and checks its summary row.

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var out := "user://test_start_at_%d" % OS.get_process_id()
	var out_abs := ProjectSettings.globalize_path(out)
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tools/balance_sim.gd",
		"--fixed-fps", "60", "--", "--seed=3", "--profile=fresh", "--style=balanced", "--start-at=51", "--last=51",
		"--speed=8", "--out=" + out_abs]
	var output := []
	var code := OS.execute(OS.get_executable_path(), args, output, true)
	var row := _summary(out_abs.path_join("runs.csv"))
	_check(not row.is_empty(), "the runner wrote its summary row (exit %d)" % code)
	if not row.is_empty():
		_check(int(row.get("start_at", 0)) == 51, "start_at is 51 (%s)" % row.get("start_at"))
		_check(int(row.get("start_dew", 0)) > 2000, "the start Dew covers 50 drifts of pot and rest bonuses (%s)" % row.get("start_dew"))
		_check(int(row.get("start_leaves", 0)) == 10, "10 leaves at 51 (%s)" % row.get("start_leaves"))
		_check(int(row.get("start_dreamlight", 0)) >= 9, "Dreamlight topped up to the human mean (%s)" % row.get("start_dreamlight"))
		_check(int(row.get("survived", 0)) >= 50, "the run starts past drift 50 (survived %s)" % row.get("survived"))
		var choices := "\n".join(output)
		_check(choices.contains("family pick (first)") and choices.count("family pick (boss)") == 2,
			"the first pick and the boss picks at 25 / 50 were made")
		_check(choices.count(": Dream ") + choices.count("Dream passed") >= 9, "a Dream offer at each skipped rest")
	_clean(out_abs)
	print("balance start-at test: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
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
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
