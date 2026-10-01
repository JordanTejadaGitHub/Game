extends Node
class_name RunHistory

# Run history (balance_simulation.md "Run history", user: "keep a run history to check balancing"):
# every run end (win, loss, abandon), real game and dev runs (tagged), never tests, adds one record to
# user://run_history.json (the last MAX_RUNS; separate from the profile so it can travel with a bug
# report). Per drift, compact rows use the bot's drift-log column names (tools/balance_sim.gd COLUMNS:
# drift, act, seconds, health_spawned, damage, leaks, leaves_lost, leaves_left, banked) plus
# `closest` (the furthest share of its route any nightmare walked). Made by the HUD; reads RunState,
# DreamState, OmenDirector, DamageLog, MetaRun and the Wardens (read-only).

const DEFAULT_PATH := "user://run_history.json"
const MAX_RUNS := 50
const GROUP := &"run_history"
const SAMPLE_EVERY := 0.25  # Seconds between closest-approach samples

static var file_path := DEFAULT_PATH
static var record_in_tests := false  # Tests may record, and only into a temp file_path

var drift_director: DriftDirector
var run_state: RunState
var dream_state: DreamState
var run := {}  # The record being built
var _drift := {}  # The latest drift's row (leaves lost, leaves left and banked go here)
# Rows of this block, by drift number, until the rest: a nightmare's health, damage, leak and closest
# approach count for the drift that spawned it, even when the next drift was called early
# (balance_simulation.md "Human run 1" item 4). "seconds" is the drift's own arrival span.
var _open := {}
var _started := {}  # Drift number -> clock when it started
var _arrived := {}  # Drift numbers whose arrival ended
var _origin := {}  # Nightmare instance id -> the drift that spawned it
var _clock := 0.0
var _sample := 0.0
var _longest := {}  # Enemy id -> the most route it had left (px)
var _boss_seen := {}  # Enemy id -> [kind, time met]
var _pending_spends: Array = []  # Costs spent this frame, sorted at its end by what happened
var _frame_events: Array[String] = []  # "plant" / "grow" / "rank" / "clear" seen this frame
var _offer_ids: Array = []  # The Dream offer on screen
var _taken_in_offer := false
var _last_leaves := 0
var _last_dew := 0
var _last_dreamlight := 0
var _omen_offers := 0
var _saved := false

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	add_to_group(GROUP)
	if drift_director == null:
		return
	run_state = drift_director.get_node_or_null("%RunState")
	dream_state = drift_director.get_node_or_null("%DreamState")
	_start_record()
	drift_director.drift_started.connect(_on_drift_started)
	drift_director.rest_started.connect(_on_rest_started)
	var spawner := drift_director.get_node_or_null("%EnemyContainer")
	if spawner != null:
		spawner.child_entered_tree.connect(_on_spawned)
		spawner.enemy_cleansed.connect(_on_dispelled)
		spawner.enemy_reached_goal.connect(func(enemy: Node2D) -> void:
			var row := _row_for(enemy)
			if not row.is_empty():
				row["leaks"] = int(row.get("leaks", 0)) + 1)
	drift_director.drift_arrived.connect(func(number: int) -> void:
		if _open.has(number) and not _arrived.has(number):
			_arrived[number] = true
			_open[number]["seconds"] = snappedf(_clock - float(_started.get(number, _clock)), 0.1))
	if run_state != null:
		_last_leaves = run_state.leaves
		_last_dew = run_state.dew
		run_state.leaves_changed.connect(_on_leaves_changed)
		run_state.dew_changed.connect(_on_dew_changed)
		run_state.dew_spent.connect(func(cost: int) -> void:
			_pending_spends.append(cost)
			if _pending_spends.size() == 1:
				_sort_spends.call_deferred())
		run_state.run_ended.connect(_on_run_ended)
	if dream_state != null:
		_last_dreamlight = dream_state.dreamlight
		dream_state.dreamlight_changed.connect(_on_dreamlight_changed)
		dream_state.offer_ready.connect(func(cards: Array[UpgradeData], drift: int) -> void:
			_offer_ids = cards.map(func(c: UpgradeData) -> String: return c.id)
			_offer_drift = drift
			_taken_in_offer = false)
		dream_state.card_taken.connect(func(card: UpgradeData) -> void:
			run.dreams_taken.append([card.id, drift_director.drifts_started])
			_taken_in_offer = true)
		dream_state.offer_closed.connect(func() -> void:
			if not _taken_in_offer and not _offer_ids.is_empty():
				run.dreams_skipped.append([_offer_ids.duplicate(), _offer_drift])
			_offer_ids = [])
	var omens := get_tree().get_first_node_in_group(&"omens")
	if omens != null:
		omens.offer_ready.connect(func(_o: Array, _b: int) -> void: _omen_offers += 1)
		omens.omen_started.connect(func(omen: OmenData, first: int, last: int) -> void:
			run.omens.append({"id": String(omen.resource_path.get_file().get_basename()), "name": omen.display_name,
				"drifts": [first, last], "reward": ""}))
		omens.omen_rewarded.connect(func(omen: OmenData, summary: String) -> void:
			for entry in run.omens:
				if entry.name == omen.display_name and entry.reward == "":
					entry.reward = summary
					break)
	var placer := drift_director.get_node_or_null("%TowerPlacer")
	if placer != null:
		placer.tower_built.connect(func(_t: Tower) -> void: _frame_events.append("plant"))
	var container := drift_director.get_node_or_null("%TowerContainer")
	if container != null:
		container.child_entered_tree.connect(func(node: Node) -> void:
			if node is Tower:
				node.evolved.connect(func(_t: Tower) -> void: _frame_events.append("grow"))
				node.nurtured.connect(func(_t: Tower) -> void: _frame_events.append("rank")))
	var map := drift_director.get_node_or_null("%MapGenerator")
	if map != null:
		map.obstacle_cleared.connect(func(_c: Vector2, _d: ObstacleData) -> void: _frame_events.append("clear"))
	var family := drift_director.get_node_or_null("%FamilyPickScreen")
	if family != null and family.has_signal("family_chosen"):
		family.family_chosen.connect(func(offered: Array, chosen: Resource) -> void:
			run.family_picks.append({"drift": drift_director.drifts_started,
				"offered": offered.map(func(r: Resource) -> String: return r.get_id() if r is TowerData else String(r.get("id"))),
				"chosen": chosen.get_id() if chosen is TowerData else String(chosen.get("id"))}))

var _offer_drift := 0

func _start_record() -> void:
	var profile := HeartwoodMemory.load_data()
	var map := drift_director.get_node_or_null("%MapGenerator")
	run = {
		"date": Time.get_datetime_string_from_system(), "version": String(ProjectSettings.get_setting("application/config/version", "dev")),
		"seed": 0, "demo": ResultsScreen.is_demo(), "dev": dev_tag(), "blight": MetaRun.blight_level,
		"grove": profile.get("unlocks", {}).duplicate(), "perks": HeartwoodMemory.get_loadout(profile),
		"result": "", "survived": 0, "won": false, "first_leak": 0, "seconds": 0.0, "leaves_lost_by_act": {},
		"close_calls": 0, "family_picks": [], "dreams_taken": [], "dreams_skipped": [], "omens": [], "clear_skies": 0,
		"bosses": [], "dew": {"earned": 0, "plant": 0, "grow": 0, "rank": 0, "clear": 0, "other": 0, "banked_at_rest": []},
		"wardens": {}, "ranks": {}, "attackers": 0, "top": [], "combos": {}, "reactions": {},
		"dreamlight": {"earned": 0, "spent": 0}, "drifts": [],
	}
	if map != null:
		run.seed = int(map.map_seed)
	BuildInfo.start()  # Hashes on a thread; noted at rests and the end (_note_build)
	run.balance = BuildInfo.balance_snapshot(drift_director, run_state)

# The build this run was played on (balance_simulation.md "The exact build it was played on"); a
# run continued after a relaunch on a changed build lists the later ones in `later_builds`.
func _note_build() -> void:
	var info := BuildInfo.current()
	if info.is_empty():
		return
	var entry := {"id": info.get("id", ""), "label": info.get("label", ""), "commit": info.get("commit", ""),
		"dirty": info.get("dirty", {}), "time": info.get("time", "")}
	if not run.has("build"):
		run.build = entry
	elif run.build.get("id", "") != entry.id and not run.get("later_builds", []).any(func(b: Dictionary) -> bool: return b.id == entry.id):
		run.later_builds = run.get("later_builds", []) + [entry]

# "" for a normal run, else which developer setting made it one ("all families", "Test Grove", "Dev Grove: …").
static func dev_tag() -> String:
	var tags: Array[String] = []
	if MetaRun.all_families_active():
		tags.append("all families")
	if TestGrove.is_active():
		tags.append("Test Grove")
	if DevGrove.is_active():
		tags.append(DevGrove.tag())  # "Dev Grove: Full"
	return ", ".join(tags)

func _process(delta: float) -> void:
	_clock += delta
	_sample -= delta
	if _sample > 0.0 or _open.is_empty():
		return
	_sample = SAMPLE_EVERY
	var spawner := drift_director.get_node_or_null("%EnemyContainer")
	if spawner == null:
		return
	for enemy in spawner.get_enemies():
		if not enemy.has_method("get_remaining_distance") or enemy.get("is_cleansed"):
			continue
		var id: int = enemy.get_instance_id()
		var left: float = enemy.get_remaining_distance()
		var longest: float = maxf(_longest.get(id, 0.0), left)
		_longest[id] = longest
		var row := _row_for(enemy)
		if longest > 0.0 and not row.is_empty():
			row["closest"] = maxf(float(row.get("closest", 0.0)), snappedf(1.0 - left / longest, 0.01))

# The row of the drift that spawned `enemy` (the latest drift's if unknown).
func _row_for(enemy: Node) -> Dictionary:
	if enemy == null or not is_instance_valid(enemy):
		return _drift
	return _open.get(_origin.get(enemy.get_instance_id(), 0), _drift)

func _on_drift_started(number: int) -> void:
	_close_drift()
	if run.seed == 0:
		var map := drift_director.get_node_or_null("%MapGenerator")
		run.seed = int(map.map_seed) if map != null else 0
	_drift = {"drift": number, "act": drift_director.get_act(number), "seconds": 0.0, "health_spawned": 0,
		"damage": 0, "leaks": 0, "leaves_lost": 0, "leaves_left": run_state.leaves if run_state else 0, "banked": 0, "closest": 0.0,
		"called_early": drift_director.is_calling_early()}  # Started while the previous one was still arriving
	_open[number] = _drift
	_started[number] = _clock
	if DamageLog.instance != null and not DamageLog.instance.damage_dealt.is_connected(_on_damage):
		DamageLog.instance.damage_dealt.connect(_on_damage)

# The latest drift stops being "the latest" (the next one started, or the rest): its leaves left and
# Dew banked are taken now; its row stays open for its nightmares until the rest (_flush_rows).
func _close_drift() -> void:
	if _drift.is_empty():
		return
	var number := int(_drift.drift)
	if not _arrived.has(number):  # Still arriving: its span so far
		_drift["seconds"] = snappedf(_clock - float(_started.get(number, _clock)), 0.1)
	_drift["leaves_left"] = run_state.leaves if run_state else 0
	_drift["banked"] = run_state.dew if run_state else 0
	_drift = {}

# The block is over (a rest, or the run's end): its rows go into the record, in drift order.
func _flush_rows() -> void:
	_close_drift()
	var numbers := _open.keys()
	numbers.sort()
	for number in numbers:
		var row: Dictionary = _open[number]
		row["damage"] = roundi(float(row.get("damage", 0.0)))
		run.drifts.append(row)
	_open.clear()
	_started.clear()
	_arrived.clear()
	_origin.clear()

func _on_rest_started(block: int, _boss: bool, _bonus: int, _perfect: bool) -> void:
	_flush_rows()
	run.dew.banked_at_rest.append([block, run_state.dew if run_state else 0])

func _on_spawned(node: Node) -> void:
	var data = node.get("enemy_data")
	if not data is EnemyData or _open.is_empty():
		return
	(func() -> void:  # Its health and drift are set once it's in (the director tags it after spawning)
		if not is_instance_valid(node) or _open.is_empty():  # The rows may have closed before this ran (Tower Code found it)
			return
		var number := drift_director.drift_of(node)
		if number <= 0 or not _open.has(number):
			number = int(_drift.get("drift", 0)) if not _drift.is_empty() else int(_open.keys().max())
		_origin[node.get_instance_id()] = number
		var row: Dictionary = _open[number]
		row["health_spawned"] = int(row.get("health_spawned", 0)) + int(node.get("max_health") if node.get("max_health") != null else 0)
	).call_deferred()
	if data.is_boss:
		_boss_seen[node.get_instance_id()] = [NightmareCodex.kind_of(data), _clock, drift_director.drifts_started]

func _on_dispelled(enemy: Node2D) -> void:
	var id := enemy.get_instance_id()
	if _boss_seen.has(id):
		var seen: Array = _boss_seen[id]
		run.bosses.append({"kind": seen[0], "drift": seen[2], "dispelled": true, "seconds": snappedf(_clock - seen[1], 0.1)})
		_boss_seen.erase(id)

func _on_damage(event: DamageLog.Event) -> void:
	var row := _row_for(event.enemy)
	if not row.is_empty():
		row["damage"] = float(row.get("damage", 0.0)) + event.amount

func _on_leaves_changed(leaves: int, _max: int) -> void:
	var lost := _last_leaves - leaves
	_last_leaves = leaves
	if lost <= 0:
		return
	if run.first_leak == 0:
		run.first_leak = drift_director.drifts_started
	var act := str(drift_director.get_act(maxi(drift_director.drifts_started, 1)))
	run.leaves_lost_by_act[act] = int(run.leaves_lost_by_act.get(act, 0)) + lost
	if not _drift.is_empty():
		_drift["leaves_lost"] = int(_drift.get("leaves_lost", 0)) + lost

func _on_dew_changed(dew: int) -> void:
	if dew > _last_dew:
		run.dew.earned += dew - _last_dew
	_last_dew = dew

func _on_dreamlight_changed(dreamlight: int) -> void:
	var change := dreamlight - _last_dreamlight
	_last_dreamlight = dreamlight
	if change > 0:
		run.dreamlight.earned += change
	else:
		run.dreamlight.spent -= change

# The frame's spends go to what happened in it (planting, growth, ranks, clears), else "other".
func _sort_spends() -> void:
	for cost in _pending_spends:
		var kind: String = _frame_events.pop_front() if not _frame_events.is_empty() else "other"
		run.dew[kind] = int(run.dew.get(kind, 0)) + int(cost)
	_pending_spends.clear()
	_frame_events.clear()

func _on_run_ended(won: bool) -> void:
	_flush_rows()
	_note_build()
	run.won = won
	run.result = "won" if won else ("abandoned" if run_state.abandoned else "lost")
	run.survived = drift_director.drifts_started
	run["early_calls"] = drift_director.early_calls  # Drifts called early (balancing)
	run["dew_call_early"] = drift_director.call_early_dew
	run.seconds = snappedf(run_state.play_time, 1.0)
	var calls := CloseCalls.find(self)
	run.close_calls = calls.run_count if calls != null else 0
	run.clear_skies = maxi(_omen_offers - run.omens.size(), 0)
	for id in _boss_seen:  # Met but not dispelled
		run.bosses.append({"kind": _boss_seen[id][0], "drift": _boss_seen[id][2], "dispelled": false, "seconds": 0.0})
	var container := drift_director.get_node_or_null("%TowerContainer")
	if container != null:
		for tower in container.get_children():
			if tower is Tower:
				var form: String = tower.tower_data.get_id()
				run.wardens[form] = int(run.wardens.get(form, 0)) + 1
				var rank := str(tower.rank)
				run.ranks[rank] = int(run.ranks.get(rank, 0)) + 1
				if tower.tower_data.can_attack:
					run.attackers += 1
	var log := DamageLog.instance
	if log != null:
		var total := 0.0
		for row in log.get_top_towers("run", 1000):
			total += float(row.amount)
		for row in log.get_top_towers("run", 5):
			run.top.append({"name": row.name, "damage": roundi(row.amount), "share": snappedf(row.amount / maxf(total, 1.0), 0.001)})
		run.combos = log.combo_counts_run.duplicate()
	var tracker := get_tree().get_first_node_in_group(&"reaction_tracker")
	if tracker != null:
		run.reactions = tracker.counts.duplicate()
	save_run(run)

# The record so far, for the run save (RunSaver, at each rest): a Save & quit run is recorded whole.
func to_save() -> Dictionary:
	_note_build()
	return {"run": run.duplicate(true), "omen_offers": _omen_offers}

# Continue: the saved record goes on (the counters restored before this don't count twice).
func load_save(data: Dictionary) -> void:
	var saved = data.get("run")
	if not saved is Dictionary or saved.is_empty():
		return
	run = saved.duplicate(true)
	run["resumed"] = int(run.get("resumed", 0)) + 1
	_omen_offers = int(data.get("omen_offers", 0))
	_drift = {}
	_open.clear()
	_started.clear()
	_arrived.clear()
	_origin.clear()
	if run_state != null:
		_last_leaves = run_state.leaves
		_last_dew = run_state.dew
	if dream_state != null:
		_last_dreamlight = dream_state.dreamlight

# The real game (the run's scene is the current scene), or a test that asked to record into a temp file.
func _may_write() -> bool:
	if record_in_tests:
		return file_path != DEFAULT_PATH
	return drift_director != null and get_tree().current_scene == drift_director.owner

func save_run(record: Dictionary) -> void:
	if _saved or not _may_write():
		return
	_saved = true
	var runs := load_runs()
	runs.push_front(record)
	runs = runs.slice(0, MAX_RUNS)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s" % file_path)
		return
	file.store_string(JSON.stringify(runs, "\t"))

# The saved runs, newest first.
static func load_runs() -> Array:
	if not FileAccess.file_exists(file_path):
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(file_path))
	return parsed if parsed is Array else []

# A plain-text report of one run, for sharing ("Copy run report").
static func report_text(record: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Heartwood TD run · %s · %s%s" % [record.get("date", ""), record.get("version", ""),
		" · dev (%s)" % record.dev if String(record.get("dev", "")) != "" else ""])
	var build: Dictionary = record.get("build", {})
	if not build.is_empty():
		var dirty: Dictionary = build.get("dirty", {})
		lines.append("Build %s · commit %s%s%s" % [build.get("label", build.get("id", "")), build.get("commit", "?"),
			" + %d uncommitted: %s" % [dirty.size(), ", ".join(dirty.keys().map(func(p: String) -> String: return "%s (%s)" % [p.get_file(), dirty[p]]))] if not dirty.is_empty() else "",
			" · later on %s" % ", ".join(record.get("later_builds", []).map(func(b: Dictionary) -> String: return b.id)) if record.has("later_builds") else ""])
	if record.has("balance"):
		lines.append("Balance: " + JSON.stringify(record.balance))
	lines.append("Result: %s · drift %d · %s · seed %d · Blight %d%s" % [record.get("result", ""), int(record.get("survived", 0)),
		_time_text(float(record.get("seconds", 0.0))), int(record.get("seed", 0)), int(record.get("blight", 0)), " · demo" if record.get("demo", false) else ""])
	lines.append("Leaves lost by act: %s · first leak: drift %d · close calls: %d" % [JSON.stringify(record.get("leaves_lost_by_act", {})),
		int(record.get("first_leak", 0)), int(record.get("close_calls", 0))])
	lines.append("Families: %s" % ", ".join(record.get("family_picks", []).map(func(p: Dictionary) -> String:
		return "%s (of %s, drift %d)" % [p.chosen, "/".join(p.offered), int(p.drift)])))
	lines.append("Dreams: %s" % ", ".join(record.get("dreams_taken", []).map(func(d: Array) -> String: return "%s@%d" % [d[0], int(d[1])])))
	lines.append("Dreams passed: %d · Omens: %s · Clear Skies: %d" % [record.get("dreams_skipped", []).size(),
		", ".join(record.get("omens", []).map(func(o: Dictionary) -> String: return o.name)), int(record.get("clear_skies", 0))])
	lines.append("Bosses: %s" % ", ".join(record.get("bosses", []).map(func(b: Dictionary) -> String:
		return "%s d%d %s" % [b.kind, int(b.drift), ("%d s" % roundi(b.seconds)) if b.dispelled else "not dispelled"])))
	var dew: Dictionary = record.get("dew", {})
	lines.append("Dew: earned %d · plant %d · grow %d · ranks %d · clears %d · other %d" % [int(dew.get("earned", 0)),
		int(dew.get("plant", 0)), int(dew.get("grow", 0)), int(dew.get("rank", 0)), int(dew.get("clear", 0)), int(dew.get("other", 0))])
	lines.append("Wardens: %d attackers · %s" % [int(record.get("attackers", 0)), JSON.stringify(record.get("wardens", {}))])
	lines.append("Top: %s" % ", ".join(record.get("top", []).map(func(t: Dictionary) -> String:
		return "%s %d%%" % [t.name, roundi(float(t.share) * 100.0)])))
	lines.append("Grove: %d nodes · perks %s · Dreamlight +%d / −%d" % [record.get("grove", {}).size(),
		", ".join(record.get("perks", [])), int(record.get("dreamlight", {}).get("earned", 0)), int(record.get("dreamlight", {}).get("spent", 0))])
	lines.append("Called early: %d drifts · %d Dew" % [int(record.get("early_calls", 0)), int(record.get("dew_call_early", 0))])
	lines.append("drift,act,seconds,health_spawned,damage,leaks,leaves_lost,leaves_left,banked,closest,called_early")
	for row in record.get("drifts", []):
		lines.append("%d,%d,%.1f,%d,%d,%d,%d,%d,%d,%.2f,%d" % [int(row.drift), int(row.act), float(row.seconds), int(row.health_spawned),
			int(row.damage), int(row.leaks), int(row.leaves_lost), int(row.leaves_left), int(row.banked), float(row.closest),
			1 if row.get("called_early", false) else 0])
	return "\n".join(lines)

static func _time_text(seconds: float) -> String:
	var minutes := roundi(seconds / 60.0)
	return "%dh %02dm" % [minutes / 60, minutes % 60] if minutes >= 60 else "%d min" % minutes
