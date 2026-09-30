extends SceneTree

# Balance simulation summary (documentation/balance_simulation.md "What it records" / "The checks"):
# reads the runs.csv that tools/balance_sim.gd appends to, prints the batch table per profile × style
# and the pass / fail checks, and compares with the saved baseline.
#   godot --headless --path . --script res://tools/balance_summary.gd -- [--dir=user://balance_out]
#       [--save-baseline]   (writes tools/balance_baseline.json from this batch)
#       [--human]   (adds the player's runs from RunHistory, user://run_history.json, as "human/…" rows)

const BASELINE := "res://tools/balance_baseline.json"

var dir := "user://balance_out"  # balance_sim.gd's default (outside res://)
var save_baseline := false
var human := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--dir="):
			dir = arg.get_slice("=", 1)
		elif arg == "--save-baseline":
			save_baseline = true
		elif arg == "--human":
			human = true
	var runs := _read_runs(dir.path_join("runs.csv"))
	if human:
		runs.append_array(_human_runs())
	if runs.is_empty():
		printerr("no runs in %s" % dir.path_join("runs.csv"))
		quit(1)
		return
	var groups := {}  # "profile/style" -> [run, …]
	for run in runs:
		groups.get_or_add("%s/%s%s" % [run.profile, run.style, ("+" + str(run.get("cards_start", ""))) if str(run.get("cards_start", "")) != "" else ""], []).append(run)
	var table := {}
	print("=== balance batch: %d runs ===" % runs.size())
	print("  %-18s %4s %9s %11s %10s %8s %8s %6s  %s" % ["profile/style", "runs", "survival", "(spread)",
		"firstleak", "lost@25", "hoard", "win%", "top Warden (max share)"])
	for key in groups:
		var g: Array = groups[key]
		var row := {
			"runs": g.size(),
			"survival": _median(g.map(func(r) -> float: return r.survived)),
			"survival_min": _min(g.map(func(r) -> float: return r.survived)),
			"survival_max": _max(g.map(func(r) -> float: return r.survived)),
			"first_leak": _median(g.map(func(r) -> float: return r.first_leak)),
			"lost_25": _median(g.filter(func(r) -> bool: return r.lost_25 >= 0).map(func(r) -> float: return r.lost_25)),
			"hoard": _median(g.map(func(r) -> float: return r.hoard_rests)),
			"win_rate": float(g.filter(func(r) -> bool: return r.won).size()) / g.size(),
			"max_top_share": _max(g.map(func(r) -> float: return r.max_top_share)),
			"max_asleep": _max(g.map(func(r) -> float: return r.max_asleep)),
			"top_warden": _mode(g.map(func(r) -> String: return r.top_warden)),
		}
		table[key] = row
		print("  %-18s %4d %9.0f %5.0f-%-5.0f %10.0f %8s %8.2f %5.0f%%  %s (%.0f%%)" % [key, row.runs, row.survival,
			row.survival_min, row.survival_max, row.first_leak, "-" if is_nan(row.lost_25) else "%.0f" % row.lost_25,
			row.hoard, 100.0 * row.win_rate, row.top_warden, 100.0 * row.max_top_share])
	_checks(table, groups)
	_compare(table)
	if save_baseline:
		var file := FileAccess.open(BASELINE, FileAccess.WRITE)
		file.store_string(JSON.stringify(table, "\t"))
		file.close()
		print("  baseline saved to %s" % BASELINE)
	quit(0)

func _checks(table: Dictionary, groups: Dictionary) -> void:
	print("=== checks ===")
	var fresh = table.get("fresh/balanced")
	if fresh:
		_check(fresh.first_leak >= 20, "Fresh, Balanced: first leak at drift 20 or later (revised act 1 target)", "median drift %.0f" % fresh.first_leak)
		_check(not is_nan(fresh.lost_25) and fresh.lost_25 >= 0 and fresh.lost_25 <= 3, "Fresh, Balanced: 0-3 leaves lost by drift 25 (revised)",
			"median %s" % ("run over before 25" if is_nan(fresh.lost_25) else "%.0f" % fresh.lost_25))
		_check(fresh.survival >= 30 and fresh.survival <= 50 and fresh.win_rate < 0.05, "Fresh, Balanced: ends in act 2, wins < 5%",
			"median survival %.0f, wins %.0f%%" % [fresh.survival, 100.0 * fresh.win_rate])
	if table.has("early/balanced"):
		_check(table["early/balanced"].survival >= 51, "Early: usually reaches act 3", "median survival %.0f" % table["early/balanced"].survival)
	if table.has("half/balanced"):
		_check(table["half/balanced"].win_rate > 0.0, "Half: wins sometimes", "wins %.0f%%" % (100.0 * table["half/balanced"].win_rate))
	if table.has("full/balanced"):
		_check(table["full/balanced"].win_rate > 0.5, "Full: wins most runs", "wins %.0f%%" % (100.0 * table["full/balanced"].win_rate))
	for key in table:
		var profile: String = key.get_slice("/", 0)
		var style: String = key.get_slice("/", 1)
		var row: Dictionary = table[key]
		if style != "balanced" and table.has(profile + "/balanced"):
			var ratio: float = row.survival / maxf(table[profile + "/balanced"].survival, 1.0)
			_check(ratio >= 0.6 and ratio <= 1.5, "%s: survival within 0.6-1.5x Balanced" % key, "x%.2f" % ratio)
		_check(row.max_top_share < 0.35, "%s: no Warden above 35%% of a drift's damage (Ascended 45%%)" % key,
			"%s at %.0f%%" % [row.top_warden, 100.0 * row.max_top_share])
		if style != "sleep":
			_check(row.max_asleep < 0.40, "%s: Asleep share < 40%%" % key, "max %.0f%%" % (100.0 * row.max_asleep))
		_check(row.hoard < 2.0, "%s: banked Dew at rests < 2 rest bonuses after act 1" % key, "median x%.2f" % row.hoard)
	print("  (not yet checked: the leak rate's shape within a run; see the per-drift CSVs)")

func _check(ok: bool, label: String, detail: String) -> void:
	print("  %s  %s (%s)" % ["PASS" if ok else "FAIL", label, detail])

func _compare(table: Dictionary) -> void:
	if not FileAccess.file_exists(BASELINE):
		print("  (no baseline yet: run with --save-baseline to keep this batch as one)")
		return
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASELINE))
	print("=== vs baseline ===")
	for key in table:
		if not base.has(key):
			print("  %s: new" % key)
			continue
		var moved: Array[String] = []
		for stat in ["survival", "first_leak", "lost_25", "hoard", "win_rate", "max_top_share", "max_asleep"]:
			var now: float = table[key][stat]
			var then: float = base[key].get(stat, NAN)
			if is_nan(now) or is_nan(then):
				continue
			if absf(now - then) > maxf(absf(then) * 0.1, 0.01):
				moved.append("%s %.2f -> %.2f" % [stat, then, now])
		print("  %s: %s" % [key, "unchanged" if moved.is_empty() else ", ".join(moved)])

# The player's runs (Main's RunHistory) in runs.csv's shape, so they sit beside the bots: profile "human",
# style = the dev tag (or "blight N" / "play"); lost_25 from the drift rows.
func _human_runs() -> Array:
	var result := []
	var history: Script = load("res://scripts/run/run_history.gd") if ResourceLoader.exists("res://scripts/run/run_history.gd") else null
	if history == null:
		return result
	for record in history.call("load_runs"):
		var lost := 0.0
		var lost_25 := -1.0
		for row in record.get("drifts", []):
			lost += float(row.get("leaves_lost", 0))
			if int(row.get("drift", 0)) == 25:
				lost_25 = lost
		var top: Array = record.get("top", [])
		var tag := str(record.get("dev", ""))
		if tag == "":
			tag = "blight %d" % int(record.get("blight", 0)) if int(record.get("blight", 0)) > 0 else "play"
		result.append({"profile": "human", "style": tag, "seed": record.get("seed", 0), "survived": float(record.get("survived", 0)),
			"won": bool(record.get("won", false)), "first_leak": float(record.get("first_leak", -1)), "lost_25": lost_25,
			"hoard_rests": 0.0, "top_warden": str(top[0].get("name", "")) if not top.is_empty() else "",
			"max_top_share": float(top[0].get("share", 0.0)) if not top.is_empty() else 0.0, "max_asleep": 0.0})
	return result

func _read_runs(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var lines := FileAccess.get_file_as_string(path).strip_edges().split("\n")
	var keys := lines[0].split(",")
	var runs: Array = []
	for i in range(1, lines.size()):
		var values := lines[i].split(",")
		var run := {}
		for k in keys.size():
			var v: String = values[k] if k < values.size() else ""
			run[keys[k]] = (v == "true") if v in ["true", "false"] else (float(v) if v.is_valid_float() else v)
		runs.append(run)
	return runs

func _median(values: Array) -> float:
	if values.is_empty():
		return NAN
	var sorted := values.duplicate()
	sorted.sort()
	var mid := sorted.size() / 2
	return sorted[mid] if sorted.size() % 2 == 1 else (sorted[mid - 1] + sorted[mid]) / 2.0

func _min(values: Array) -> float:
	return values.min() if not values.is_empty() else NAN

func _max(values: Array) -> float:
	return values.max() if not values.is_empty() else NAN

func _mode(values: Array) -> String:
	var counts := {}
	for v in values:
		counts[v] = counts.get(v, 0) + 1
	var best := ""
	for v in counts:
		if best == "" or counts[v] > counts[best]:
			best = v
	return best
