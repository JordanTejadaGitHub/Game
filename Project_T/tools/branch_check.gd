extends SceneTree

# The branch check (Balancing Discussion, owner 2026-10-18: "make sure every branch can pass to drift 25 if they're
# using all the Dew"). On demand, not a suite test: tools/branch_check.sh runs tools/balance_sim.gd once per starting
# family branch and map (--families=<family> --branch=<id> --spend-all --last=25) and this script lists the branches and
# writes the report.
#   --list: "BRANCH <family> <branch>" for each regular branch of the four starting families (DreamState.regular_branches)
#   --report=<dir> --md=<file>: reads <dir>/<family>_<branch>_<seed>.log (each run's RUN line) and writes the table
# Pass = the act 1 boss dispelled with PASS_LEAVES+ leaves on at least PASS_MAPS of the maps.

const FAMILIES := ["sporeling", "firefly_jar", "dewdrop", "bellflower"]
const SEEDS := [1207, 4242, 90210]  # The opening test's maps
const PASS_LEAVES := 5
const PASS_MAPS := 2

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var report := ""
	var md := ""
	var list := false
	for arg in OS.get_cmdline_user_args():
		if arg == "--list":
			list = true
		elif arg.begins_with("--report="):
			report = arg.trim_prefix("--report=")
		elif arg.begins_with("--md="):
			md = arg.trim_prefix("--md=")
	if list:
		await _list()
	elif report != "":
		_report(report, md)
	quit(0)

func _list() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	for id in FAMILIES:
		for form in dreams.regular_branches(load("res://resource/tower/%s.tres" % id)):
			print("BRANCH %s %s" % [id, form.get_id()])
	main.queue_free()
	await process_frame

# One run's RUN line from its log ({} = no line: it crashed or timed out).
func _run_of(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	for line in FileAccess.get_file_as_string(path).split("\n"):
		if line.begins_with("RUN "):
			var data = JSON.parse_string(line.substr(4))
			return data if data is Dictionary else {}
	return {}

# The act 1 boss from the bosses column ("25:kind:health:route_s:hp_arrive:route_dmg:heart_dmg:heart_s:in_range:dispelled…").
func _boss(run: Dictionary) -> Dictionary:
	for fight in String(run.get("bosses", "")).split(";", false):
		var f := fight.split(":")
		if f.size() >= 10 and int(f[0]) == 25 and not f[1].contains("(echo)"):
			return {"kind": f[1], "seconds": float(f[3]) + float(f[7]), "dispelled": f[9] == "1"}
	return {}

func _report(dir: String, md: String) -> void:
	var branches := {}  # "family/branch" -> [runs by seed]
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".log"):
			continue
		var parts := f.trim_suffix(".log").rsplit("_", true, 2)  # <family>_<branch>_<seed>; family ids hold "_" too
		if parts.size() < 3:
			continue
		var family := ""
		for id in FAMILIES:
			if f.begins_with(id + "_"):
				family = id
		if family == "":
			continue
		var branch := f.trim_suffix(".log").trim_prefix(family + "_").trim_suffix("_" + parts[2])
		var key := family + "/" + branch
		if not branches.has(key):
			branches[key] = {}
		branches[key][int(parts[2])] = _run_of(dir.path_join(f))
	var keys := branches.keys()
	keys.sort_custom(func(a: String, b: String) -> bool:
		var fa := FAMILIES.find(a.get_slice("/", 0))
		var fb := FAMILIES.find(b.get_slice("/", 0))
		return fa < fb if fa != fb else a < b)
	var summary: Array[String] = ["| Family | Branch | Result | Maps passed | Worst map |", "|---|---|---|---|---|"]
	var detail: Array[String] = []
	var passed_total := 0
	for key in keys:
		var by_seed: Dictionary = branches[key]
		var passes := 0
		var worst := ""
		var worst_score := INF
		detail.append("### %s" % key)
		detail.append("")
		detail.append("| Map | Reached | Leaves at end | Boss | Closest per block | Dew left after each rest | Wardens at end | Branch |")
		detail.append("|---|---|---|---|---|---|---|---|")
		for map_seed in SEEDS:
			var run: Dictionary = by_seed.get(map_seed, {})
			if run.is_empty():
				detail.append("| %d | no result (crash or timeout: see the log) | | | | | | |" % map_seed)
				if worst_score > -1.0:
					worst_score = -1.0
					worst = "%d (no result)" % map_seed
				continue
			var boss := _boss(run)
			var leaves := int(run.get("leaves_end", 0))
			var dispelled: bool = not boss.is_empty() and boss.dispelled
			var ok := dispelled and leaves >= PASS_LEAVES and int(run.get("survived", 0)) >= 25
			if ok:
				passes += 1
			var boss_text := "not reached" if boss.is_empty() else ("%s %.0f s" % [boss.kind, boss.seconds] if dispelled else "%s not dispelled" % boss.kind)
			detail.append("| %d | drift %d%s | %d | %s | %s | %s | %s | %s |" % [map_seed, int(run.get("started", 0)),
				"" if int(run.get("survived", 0)) >= 25 else " (lost)", leaves, boss_text, run.get("closest_blocks", ""),
				run.get("rest_left", ""), String(run.get("wardens_end", "")).replace("+", ", "), run.get("branch_status", "")])
			var score := float(run.get("survived", 0)) + leaves / 100.0 + (1.0 if dispelled else 0.0)
			if score < worst_score:
				worst_score = score
				worst = "%d: %s" % [map_seed, ("drift %d, %d leaves, boss %s" % [int(run.get("started", 0)), leaves, "dispelled" if dispelled else "not dispelled"])]
		detail.append("")
		var passed := passes >= PASS_MAPS
		if passed:
			passed_total += 1
		summary.append("| %s | %s | %s | %d of %d | %s |" % [key.get_slice("/", 0), key.get_slice("/", 1), "PASS" if passed else "FAIL", passes, SEEDS.size(), worst])
	var lines: Array[String] = []
	lines.append("# Branch check, %s" % Time.get_date_string_from_system())
	lines.append("")
	lines.append("Balancing Discussion (owner 2026-10-18): can every starting-family branch reach drift 25 when the bot spends all its Dew?")
	lines.append("Each run: the family as the first pick (its Calling set), the branch put in its offer and unlocked with the first-pick Dreamlight, grown into nothing else past the base Warden, `--spend-all`, maps %s, to the end of drift 25. Pass = the act 1 boss dispelled with %d+ leaves on %d of %d maps." % [", ".join(SEEDS.map(func(s) -> String: return str(s))), PASS_LEAVES, PASS_MAPS, SEEDS.size()])
	lines.append("The bot is weaker than the owner: a fail is a candidate to look at, not a verdict.")
	lines.append("")
	lines.append("**%d of %d branches pass.**" % [passed_total, keys.size()])
	lines.append("")
	lines.append_array(summary)
	lines.append("")
	lines.append("## Per map")
	lines.append("")
	lines.append("Closest = how far the furthest nightmare got along the route in each block of 5 drifts (1.00 = reached the Heartwood). Dew left = after the bot's spending at each rest (5, 10, 15, 20).")
	lines.append("")
	lines.append_array(detail)
	var text := "\n".join(lines)
	if md != "":
		var file := FileAccess.open(md, FileAccess.WRITE)
		file.store_string(text)
		file.close()
	print(text)
