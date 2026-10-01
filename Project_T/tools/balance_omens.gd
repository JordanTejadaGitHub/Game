extends SceneTree

# Omen mode comparison (run_design.md "Omens with teeth" point 4, balance_simulation.md): reads one
# balance_sim.gd output folder per --omens mode (runs.csv + the per-run drift CSVs) and prints the
# medians and spread per mode, then the three targets.
#   godot --headless --path . --script res://tools/balance_omens.gd -- \
#       --mode=clear=<dir> --mode=always=<dir> --mode=clean=<dir> [--at=25,40]
#
# Omen reward Dew = the fixed reward paid + the pot multipliers' extra or loss (balance_sim omen_pot_dew).
# Leaves lost by drift N = the drift rows' leaves_lost up to N, plus the leaves left at the last row
# when the run ended (dormant) by N (the losing drift writes no row). Dormant = ended before --last.

var modes := {}  # mode -> dir, in argument order
var marks: Array[int] = [25, 40]

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var value := arg.get_slice("=", 1)
		match arg.get_slice("=", 0):
			"--mode": modes[value] = arg.substr(arg.find("=", arg.find("=") + 1) + 1)
			"--at":
				marks.clear()
				for part in value.split(","):
					marks.append(int(part))
	if modes.is_empty():
		printerr("usage: --mode=clear=<dir> --mode=always=<dir> --mode=clean=<dir>")
		quit(1)
		return
	var stats := {}
	for mode in modes:
		stats[mode] = _mode_stats(modes[mode])
		if stats[mode].is_empty():
			printerr("no runs in %s" % modes[mode])
			quit(1)
			return
	_print_table(stats)
	_print_acts(stats)
	_print_blocks(stats)
	_print_targets(stats)
	quit(0)

func _mode_stats(dir: String) -> Dictionary:
	var runs := _read_csv(dir.path_join("runs.csv"))
	if runs.is_empty():
		return {}
	var out := {"runs": runs.size(), "reached": [], "dormant": 0, "per10": [], "paid": [], "share": [],
		"omen_lost": [], "omen_dew": [], "omen_pot_dew": [], "omen_dreamlight": [], "lost_total": [], "acts": {}, "blocks": {}}
	var sums := {"share": 0.0, "omen_lost": 0.0, "lost": 0.0}
	var last: int = marks.max()
	for mark in marks:
		out["lost_%d" % mark] = []
		out["earned_%d" % mark] = []
		out["banked_%d" % mark] = []
	for run in runs:
		var reached := int(run.survived)
		var won := str(run.won) == "true"
		var rows := _read_csv(dir.path_join("%s_%s_seed%s.csv" % [run.profile, run.style, run.seed]))
		var dormant := not won and reached < last
		out.reached.append(reached)
		if dormant:
			out.dormant += 1
		var lost_total := int(rows[-1].leaves_lost) if not rows.is_empty() else 0  # leaves_lost is the run total so far
		if dormant and not rows.is_empty():
			lost_total += int(rows[-1].leaves_left)
		out.lost_total.append(lost_total)
		out.per10.append(10.0 * lost_total / maxf(reached, 1))
		for mark in marks:
			var lost := 0
			var earned := 0
			var banked := -1
			for row in rows:
				if int(row.drift) <= mark:
					lost = int(row.leaves_lost)
					earned += int(row.dew_rest) + int(row.dew_other)
					banked = int(row.banked)
			if dormant and reached < mark and not rows.is_empty():
				lost += int(rows[-1].leaves_left)
			out["lost_%d" % mark].append(lost)
			out["earned_%d" % mark].append(earned)
			if reached >= mark:  # Banked at N only means something for runs that got there
				out["banked_%d" % mark].append(banked)
		var share := float(run.omen_share)
		var omen_lost := int(run.omen_leaves_lost)
		out.paid.append(int(run.omen_paid))
		out.share.append(share)
		out.omen_lost.append(omen_lost)
		out.omen_dew.append(int(run.omen_dew))
		_add_acts(out, run, rows, dormant, reached)
		for block in str(run.get("omen_blocks", "")).split(";", false):
			var parts := block.split(":")
			out.blocks.get_or_add(parts[0], []).append([int(parts[1]), int(parts[2]), int(parts[3]), int(parts[4])])
		out.omen_pot_dew.append(int(run.get("omen_pot_dew", 0)))
		out.omen_dreamlight.append(int(run.get("omen_dreamlight", -1)))
		sums.share += share
		sums.omen_lost += omen_lost
		sums.lost += lost_total
	out.share_per_omen_leaf_all = sums.share / maxf(sums.omen_lost, 1.0)
	out.share_per_leaf_all = sums.share / maxf(sums.lost, 1.0)
	return out

func _print_table(stats: Dictionary) -> void:
	var header := "  %-26s" % "metric"
	for mode in stats:
		header += " %24s" % ("%s (%d runs)" % [mode, stats[mode].runs])
	print(header)
	var lines := [["drift reached", "reached"]]
	for mark in marks:
		lines.append(["leaves lost by %d" % mark, "lost_%d" % mark])
	lines.append_array([["leaves lost / 10 drifts", "per10"], ["leaves lost, run", "lost_total"],
		["Omens paid", "paid"], ["reward shares", "share"], ["leaves lost in Omen blocks", "omen_lost"],
		["Omen reward Dew (all)", "omen_dew"], ["  of it, pot multipliers", "omen_pot_dew"]])
	for mark in marks:
		lines.append(["Dew earned by %d" % mark, "earned_%d" % mark])
		lines.append(["Dew banked at %d (alive)" % mark, "banked_%d" % mark])
	for line in lines:
		var text := "  %-26s" % line[0]
		for mode in stats:
			text += " %24s" % _cell(stats[mode][line[1]])
		print(text)
	var text := "  %-26s" % ("dormant before %d" % marks.max())
	for mode in stats:
		text += " %24s" % ("%d%% (%d)" % [roundi(100.0 * stats[mode].dormant / stats[mode].runs), stats[mode].dormant])
	print(text)
	for pair in [["shares / Omen-block leaf", "share_per_omen_leaf_all"], ["shares / leaf lost (run)", "share_per_leaf_all"]]:
		text = "  %-26s" % pair[0]
		for mode in stats:
			text += " %24s" % ("%.2f" % stats[mode][pair[1]])
		print(text)
	print("  (cells: median [p10–p90]; share ratios are batch totals)")

func _print_targets(stats: Dictionary) -> void:
	if not (stats.has("clear") and stats.has("always")):
		return
	var c: Dictionary = stats.clear
	var a: Dictionary = stats.always
	var extra := _median(a.lost_total) - _median(c.lost_total)
	var extra_per10 := _median(a.per10) - _median(c.per10)
	print("  always vs clear: +%.1f leaves lost per run (median; target >= 3), +%.2f per 10 drifts" % [extra, extra_per10])
	var dorm: float = 100.0 * (float(a.dormant) / a.runs - float(c.dormant) / c.runs)
	print("  always vs clear: %+.0f points dormancy (target >= +10)" % dorm)
	if stats.has("clean"):
		var k: Dictionary = stats.clean
		print("  clean vs always: %.2f vs %.2f shares per Omen-block leaf, %.2f vs %.2f per run leaf (target: clean higher)"
			% [k.share_per_omen_leaf_all, a.share_per_omen_leaf_all, k.share_per_leaf_all, a.share_per_leaf_all])

func _cell(values: Array) -> String:
	if values.is_empty():
		return "-"
	var sorted := values.duplicate()
	sorted.sort()
	var lo: float = sorted[floori(0.1 * (sorted.size() - 1))]
	var hi: float = sorted[ceili(0.9 * (sorted.size() - 1))]
	return "%s [%s–%s]" % [_num(_median(values)), _num(lo), _num(hi)]

func _num(value: float) -> String:
	return str(roundi(value)) if absf(value) >= 10.0 or is_equal_approx(value, roundf(value)) else "%.1f" % value

func _median(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	var mid := sorted.size() / 2
	return float(sorted[mid]) if sorted.size() % 2 == 1 else (float(sorted[mid - 1]) + float(sorted[mid])) / 2.0

func _read_csv(path: String) -> Array:
	var rows := []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return rows
	var keys := file.get_csv_line()
	while not file.eof_reached():
		var values := file.get_csv_line()
		if values.size() < keys.size():
			continue
		var row := {}
		for i in keys.size():
			row[keys[i]] = values[i]
		rows.append(row)
	return rows

# Per act (balance_sim's omen_*_aN columns; leaves from the drift rows): only runs that started the act.
func _add_acts(out: Dictionary, run: Dictionary, rows: Array, dormant: bool, reached: int) -> void:
	for act in range(1, 5):
		var first := (act - 1) * 25 + 1
		if reached + 1 < first or not run.has("omen_dew_a%d" % act):
			continue
		var bucket: Dictionary = out.acts.get_or_add(act, {"runs": 0, "lost": [], "dew": [], "pot": [], "share": 0.0, "omen_lost": 0, "paid": 0})
		bucket.runs += 1
		bucket.lost.append(_lost_by(rows, act * 25, dormant, reached) - _lost_by(rows, first - 1, dormant, reached))
		bucket.dew.append(int(run["omen_dew_a%d" % act]))
		bucket.pot.append(int(run["omen_pot_a%d" % act]))
		bucket.share += float(run["omen_share_a%d" % act])
		bucket.omen_lost += int(run["omen_lost_a%d" % act])
		bucket.paid += int(run["omen_paid_a%d" % act])

# Leaves lost by the end of drift `mark` (leaves_lost is the run's running total; a run that ended by then
# lost what it had left too).
func _lost_by(rows: Array, mark: int, dormant: bool, reached: int) -> int:
	var lost := 0
	for row in rows:
		if int(row.drift) <= mark:
			lost = int(row.leaves_lost)
	if dormant and reached < mark and not rows.is_empty():
		lost = int(rows[-1].leaves_lost) + int(rows[-1].leaves_left)
	return lost

func _print_acts(stats: Dictionary) -> void:
	var acts := {}
	for mode in stats:
		for act in stats[mode].acts:
			acts[act] = true
	if acts.is_empty():
		return
	var keys := acts.keys()
	keys.sort()
	for act in keys:
		print("  -- act %d --" % act)
		for line in [["runs in the act", "runs"], ["leaves lost in the act", "lost"], ["Omen reward Dew (all)", "dew"],
				["  of it, pot multipliers", "pot"], ["Omens paid", "paid"], ["shares / Omen-block leaf", "per_leaf"]]:
			var text := "  %-26s" % line[0]
			for mode in stats:
				var bucket: Dictionary = stats[mode].acts.get(act, {})
				var cell := "-"
				if not bucket.is_empty():
					match line[1]:
						"runs", "paid": cell = str(bucket[line[1]])
						"per_leaf": cell = "%.2f (%.1f / %d)" % [bucket.share / maxf(bucket.omen_lost, 1.0), bucket.share, bucket.omen_lost]
						_: cell = _cell(bucket[line[1]])
				text += " %24s" % cell
			print(text)

# Per Omen, all modes together: blocks paid, median reward Dew and pot part, and the net as a share of the
# block's plain pot (Dry Spell's check: a clean block ≈ +25%).
func _print_blocks(stats: Dictionary) -> void:
	var all := {}
	for mode in stats:
		for id in stats[mode].blocks:
			all.get_or_add(id, []).append_array(stats[mode].blocks[id])
	if all.is_empty():
		return
	print("  -- per Omen (all modes; median) --")
	print("  %-18s %6s %8s %8s %10s %16s" % ["Omen", "blocks", "reward", "pot", "lost", "net / plain pot"])
	var ids := all.keys()
	ids.sort()
	for id in ids:
		var blocks: Array = all[id]
		var nets := []
		var clean_nets := []
		for b in blocks:
			if b[2] > 0:
				nets.append(100.0 * (b[0] + b[1]) / b[2])
				if b[3] == 0:
					clean_nets.append(100.0 * (b[0] + b[1]) / b[2])
		var net := "-" if nets.is_empty() else "%+.0f%% (clean %s)" % [_median(nets), "-" if clean_nets.is_empty() else "%+.0f%%" % _median(clean_nets)]
		print("  %-18s %6d %8s %8s %10s %16s" % [id, blocks.size(), _num(_median(blocks.map(func(b): return b[0]))),
			_num(_median(blocks.map(func(b): return b[1]))), _num(_median(blocks.map(func(b): return b[3]))), net])
