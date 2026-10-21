extends Node
class_name RunSaver

# Mid-run save (run_design.md "Mid-run save"): autosaves at every rest once its choices (family
# pick, Dream, Omen) are settled, and when the player picks Save & Quit during a rest. Quitting
# mid-block resumes from that block's last rest. One run in progress at a time; the save is
# deleted when the run ends. The title screen offers Continue when one exists.
#
# Saved: map seed and tended obstacles, Wardens (cell, kind, invested Dew), Dew, leaves, Seeds
# counters, drift progress, Dreams and Omens (their own to_save()/load_save()).

const PATH := "user://run.json"
const VERSION := 11  # 2: map 23x18; 3: ridges taper; 4: fewer obstacles; 5: one bend; 6: layouts; 7: features near the route; 8: organic ponds; 9: inland Heartwood (same seed, different map); 10: the log is one obstacle; 11: the Spire merge (gifts, branch offers, finales in the save)

# Where the save lives (tests point this elsewhere so they never touch the player's run).
static var file_path := PATH

# Set by the title screen before loading the main scene: restore the saved run.
static var resume_next := false
static var resuming := false  # This run is a Continue (set where resume_next is consumed; MetaRun reads it after)
static var next_map_seed := 0  # The next new run's map seed (SeedPicker, Remembered Seed); 0 = a random map. Used once

@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var dream_state: DreamState = %DreamState
@onready var map_generator = %MapGenerator
@onready var tower_container: Node2D = %TowerContainer
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var family_screen: Control = %FamilyPickScreen

var _resume_failed := false
var _save_retry_after := 0.0
var _dirty := false  # A rest began or a choice closed: save once nothing is open
# Autosave only when this is the game actually being played (tests add the scene by hand).
var autosave := true
var _saved_data := {}  # Loaded save, applied once the scene is ready

const QUIT_FRAMES := 3  # Frames between freeing the run and quitting

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# During a run the close button asks first (the pause menu's Quit… dialog: what's saved, title or desktop); a
		# second close while it's asking, or once the run is over, quits.
		var menu := get_tree().get_first_node_in_group(&"pause_menu")
		if menu != null and not run_state.is_over:
			if menu.is_asking_quit():
				menu._quit_to(true)  # The second close still respects a failed save.
			else:
				menu.ask_quit()
		else:
			safe_quit(get_tree())
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		_on_backgrounded()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_press_menu_key()
	elif what == NOTIFICATION_EXIT_TREE:
		get_tree().auto_accept_quit = true  # Back to the title / Grove: their close is the engine's
		get_tree().quit_on_go_back = true

# Mobile (mobile_plan.md "Shorter sessions"): the OS may kill a backgrounded app without warning. Save what a
# Continue can keep (at a rest: everything built since the rest began), and pause a live game so coming back
# never costs leaves. Mid-drift the save stays the last rest's, as on PC.
func _on_backgrounded() -> void:
	if run_state.is_over:
		return
	if autosave and can_save_now():
		save_now()
	var menu := get_tree().get_first_node_in_group(&"pause_menu")
	if menu != null and not get_tree().paused:
		menu.open()

# Android's Back button is Esc: cancel building, deselect, open / close the pause menu (open_menu handlers).
func _press_menu_key() -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = &"open_menu"
		event.pressed = pressed
		Input.parse_input_event(event)

# Quits without tearing the run scene down during exit: frees the current scene, waits a few frames,
# then quits. Static, so it keeps going after this node is freed with the scene. Tests that quit with
# main.tscn loaded can use it too.
static func safe_quit(tree: SceneTree, exit_code: int = 0) -> void:
	var scene := tree.current_scene
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	for i in QUIT_FRAMES:
		await tree.process_frame
	tree.quit(exit_code)

# Balance snapshots (Balancing Discussion + the story chat, 2026-10-05): opt-in, a copy of each rest's autosave for
# Balancing Code's --from-save (it only reads them). Debug builds only, never an export: the Developer setting
# keep_snapshots, off by default. Files <date>_<seed>_d<drift>_<build>.json, "_dev" added for dev runs (Unlock all
# families; Test Grove never autosaves); the newest SNAPSHOTS_KEPT are kept. run.json itself is untouched.
const SNAPSHOT_DIR := "D:/Projects/logs/balancing/snapshots"
const SNAPSHOTS_KEPT := 40
const SNAPSHOT_SETTING := "keep_snapshots"
const SNAPSHOT_PATTERN := "^\\d{4}-\\d{2}-\\d{2}_-?\\d+_d\\d{3}_.*\\.json$"  # Pruning only ever touches snapshots

static func snapshots_on() -> bool:
	return OS.is_debug_build() and bool(HeartwoodMemory.get_settings().get(SNAPSHOT_SETTING, false))

# The snapshot's file name: date, map seed, drift, build (and "_dev" for dev runs).
static func snapshot_name(map_seed: int, drift: int, dev: bool) -> String:
	var build := String(BuildInfo.current().get("id", "build")).validate_filename().left(12)
	return "%s_%d_d%03d_%s%s.json" % [Time.get_date_string_from_system(), map_seed, drift, build, "_dev" if dev else ""]

# Writes `text` to dir/file_name and drops the oldest snapshots past `kept`. Returns the path written ("" = failed).
static func write_snapshot(text: String, file_name: String, dir: String = SNAPSHOT_DIR, kept: int = SNAPSHOTS_KEPT) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var path := dir.path_join(file_name)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(text)
	file.close()
	var pattern := RegEx.create_from_string(SNAPSHOT_PATTERN)
	var names := Array(DirAccess.get_files_at(dir)).filter(func(n: String) -> bool: return pattern.search(n) != null)
	names.sort_custom(func(x: String, y: String) -> bool:
		return FileAccess.get_modified_time(dir.path_join(x)) > FileAccess.get_modified_time(dir.path_join(y)))
	for i in range(kept, names.size()):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(names[i])))
	return path

# The drift a Continue would start before (the save's drifts_started + 1), or 0 with no save (the quit dialog says it).
static func saved_drift() -> int:
	if not has_save():
		return 0
	var parsed := read_saved_run()
	return int(parsed.get("drifts_started", 0)) + 1 if not parsed.is_empty() else 0

static func has_save() -> bool:
	return FileAccess.file_exists(file_path) or FileAccess.file_exists(file_path + ".bak")

static func delete_save() -> void:
	for path in [file_path, file_path + ".bak"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Choice screens pause the tree
	# Closing the window mid-run: free the run first, quit a few frames later (safe_quit). The engine
	# can crash tearing this scene down at exit (Tower Code, ~5% under load). Only while a run is open;
	# other scenes keep the engine's own close.
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false  # Back = Esc during a run (_press_menu_key); the title's Back still quits
	# Never in tests, and never in Test Grove (a dev playtest would overwrite the real saved run).
	autosave = get_tree().current_scene == owner and not TestGrove.is_active()
	MetaRun.resumed_extra_ridges = -1  # A new run reads Clear Sight from the loadout; a resumed one from its save
	# Runs before MapGenerator (earlier sibling), so the map is rebuilt from the saved seed.
	resuming = resume_next
	if resume_next:
		resume_next = false
		_saved_data = _read()
		_resume_failed = _saved_data.is_empty()
		if not _saved_data.is_empty():
			map_generator.map_seed = int(_saved_data.map_seed)
			MetaRun.blight_level = int(_saved_data.get("blight_level", 0))  # Before MetaRun applies it
			MetaRun.resumed_extra_ridges = int(_saved_data.get("extra_ridges", -1))  # Sidegrade Clear Sight: the same map
			drift_director.preset_bosses = _saved_data.get("bosses", [])  # Before the (deferred) boss draw
	elif next_map_seed != 0:  # Remembered Seed (SeedPicker): a past run's map or a typed seed, played and banked normally
		map_generator.map_seed = next_map_seed
	next_map_seed = 0
	drift_director.rest_started.connect(func(_b: int, _boss: bool, _bonus: int, _perfect: bool) -> void: _dirty = true)
	drift_director.family_pick_requested.connect(func(_reason: StringName) -> void: _dirty = true)
	run_state.run_ended.connect(func(_won: bool) -> void:
		_dirty = false
		if autosave:
			delete_save())
	if not _saved_data.is_empty():
		_restore.call_deferred(_saved_data)
	else:
		_dirty = not _resume_failed  # Save the opening rest too, so Continue exists right away

func _process(delta: float) -> void:
	_save_retry_after = maxf(0.0, _save_retry_after - delta)
	if autosave and _dirty and _save_retry_after <= 0.0 and can_save_now():
		save_now()

# A save is only taken while resting with nothing waiting on the player.
func can_save_now() -> bool:
	if _resume_failed or run_state.is_over or not drift_director.is_resting() or drift_director.awaiting_family_pick:
		return false
	if family_screen.visible or dream_state.is_offering() or dream_state.has_pending_offer():
		return false
	var omens := get_tree().get_first_node_in_group(&"omens")
	var gifts := HeartwoodGifts.find(self)
	if gifts != null and gifts.is_offering():
		return false  # The gift first (Spire)
	if omens != null and (omens.is_offering() or omens.get("_offer_waiting")):
		return false
	return true

func save_now() -> bool:
	if not can_save_now():
		return false
	var towers: Array = []
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion():
			towers.append({"cell": [tower.cell.x, tower.cell.y], "half": [tower.half_cell.x, tower.half_cell.y], "data": tower.tower_data.resource_path,
				"invested": tower.invested_dew, "rest_dew": tower.rest_dew, "rank": tower.rank, "paid_ranks": Array(tower.paid_ranks), "banked_ranks": tower.banked_ranks, "focus": tower.focus, "rank_choices": Array(tower.rank_choices),
				"target_mode": tower.target_mode, "target_chosen": tower.target_chosen, "kin_branch": tower.kin_branch, "size": tower.get_footprint(),
				"legacy": tower.legacy_data.resource_path if tower.legacy_data else "",  # An Ascended form's final
				"drifts_stood": int(tower.get_meta(&"drifts_stood", 0)),  # Old Growth (DreamState counts it)
				"gift_sprout": bool(tower.get_meta(&"gift_sprout", false)),  # Never raises the Sprout price
				"sprout_line": bool(tower.get_meta(&"sprout_line", false)),  # Grown from a paid Sprout: still raises it
				"twig": tower.twig,  # Twig Walls: a one-half Thornwall (walls planted before the card stay 2×2)
				"unique_plant_order": int(tower.get_meta(&"unique_plant_order", 0)),
				"unique_plant_rest": int(tower.get_meta(&"unique_plant_rest", -1)),
				"underdog": bool(tower.get_meta(&"underdog", false))})  # Underdog's mark (set at each rest)
	var data := {
		"version": VERSION,
		"app_version": String(ProjectSettings.get_setting("application/config/version", "")),  # Which build wrote it (route repair log)
		"build": String(BuildInfo.current().get("id", "")),
		"map_seed": map_generator.map_seed,
		"blight_level": MetaRun.blight_level,
		"extra_ridges": MetaRun.run_extra_ridges,  # Sidegrade Clear Sight's ridge, so a resume rebuilds the same map
		"tended": run_state.tended_cells.map(func(c: Vector2) -> Array: return [c.x, c.y]),
		"towers": towers,
		"dew": run_state.dew,
		"leaves": run_state.leaves,
		"max_leaves": run_state.max_leaves,
		"obstacles_tended": run_state.obstacles_tended,
		"omen_seeds": run_state.omen_seeds,
		"free_clears": run_state.free_clears,
		"sprout_charges": run_state.sprout_charges,  # Seedling Gift, Sprout Bed
		"free_nurtures": run_state.free_nurtures,  # First Care
		"foretold": family_screen.foretold if "foretold" in family_screen else [],  # Kin Foretold: the next boss pick's families
		"gifts": HeartwoodGifts.find(self).to_save() if HeartwoodGifts.find(self) != null else {},  # Heartwood's Gifts (Spire)
		"dew_harvested": run_state.dew_harvested,  # The Harvest + interest (Golden Harvest)
		"fertile_cells": run_state.fertile_cells.keys().map(func(c: Vector2) -> Array: return [c.x, c.y]),
		"creatures_cleansed": run_state.creatures_cleansed,
		"cleansed_in_act_1": run_state.cleansed_in_act_1,  # Act 1 dispels pay fewer Seeds
		"cleansed_in_act_2": run_state.cleansed_in_act_2,
		"leaves_lost": run_state.leaves_lost,
		"longest_path": run_state.longest_path,
		"play_time": run_state.play_time,
		"drifts_started": drift_director.drifts_started,
		"drifts_cleared": drift_director.drifts_cleared,
		"blocks_rested": drift_director.blocks_rested,
		"maze_economy": drift_director.maze_economy.to_save(),
		"bosses_cleansed": drift_director.bosses_cleansed,
		"early_calls": drift_director.early_calls, "call_early_dew": drift_director.call_early_dew,
		"auto_drift": drift_director.auto_drift,
		"bosses": BossPool.ids(drift_director.bosses),  # Boss pools: the bosses this run drew
		"dreams": dream_state.to_save(),
	}
	var omens := get_tree().get_first_node_in_group(&"omens")
	if omens != null and omens.has_method("to_save"):
		data["omens"] = omens.to_save()
	var history := get_tree().get_first_node_in_group(RunHistory.GROUP) as RunHistory
	if history != null:
		data["history"] = history.to_save()  # The run history's record so far: a resumed run is recorded whole
	var kin := Kinships.find(tower_container)
	if kin != null:
		data["kinships"] = kin.to_save()  # Bond ages (drifts together), Whole Trees, counts
	# Nurture Dream cards (Tender Care / Warm Hands openers, Remembered Care's memory seeds).
	if "rank_dew_spent" in run_state:
		data["rank_dew_spent"] = run_state.rank_dew_spent
	if "memory_seeds" in run_state:
		data["memory_seeds"] = Array(run_state.memory_seeds)
	var text := JSON.stringify(data)
	if not _write_run(text):
		_dirty = true
		_save_retry_after = 1.0
		return false
	_dirty = false
	_save_retry_after = 0.0
	if autosave and snapshots_on():
		write_snapshot(text, snapshot_name(map_generator.map_seed, drift_director.drifts_started, MetaRun.is_dev_run()))
	return true

# Commit a complete temporary file; retain the last readable run for recovery.
static func _write_run(text: String) -> bool:
	var temp := "%s.%d.tmp" % [file_path, OS.get_process_id()]
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save the run: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(text)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
		return false
	if not _parse_run(file_path).is_empty():
		error = DirAccess.copy_absolute(ProjectSettings.globalize_path(file_path), ProjectSettings.globalize_path(file_path + ".bak"))
		if error != OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
			return false
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(file_path))
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
	return error == OK

static func _parse_run(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return {}
	var data: Dictionary = json.data
	if int(data.get("version", 0)) != VERSION:
		return {}
	for key in ["map_seed", "tended", "towers", "dew", "leaves", "max_leaves", "obstacles_tended", "omen_seeds",
			"creatures_cleansed", "drifts_started", "drifts_cleared", "blocks_rested",
			"bosses_cleansed", "auto_drift", "dreams"]:
		if not data.has(key):
			return {}
	if not data.tended is Array or not data.towers is Array or not data.dreams is Dictionary:
		return {}
	for key in ["map_seed", "dew", "leaves", "max_leaves", "obstacles_tended", "omen_seeds",
			"creatures_cleansed", "drifts_started", "drifts_cleared", "blocks_rested", "bosses_cleansed"]:
		if not _is_number(data[key]):
			return {}
	if not data.auto_drift is bool:
		return {}
	for key in ["tended", "fertile_cells"]:
		var cells = data.get(key, [])
		if not cells is Array:
			return {}
		for cell in cells:
			if not _is_coordinate(cell):
				return {}
	for saved in data.towers:
		if not saved is Dictionary or not _is_coordinate(saved.get("cell")):
			return {}
		if not _is_number(saved.get("invested")) or not saved.get("data") is String:
			return {}
		if not ResourceLoader.exists(saved.data) or not load(saved.data) is TowerData:
			return {}
		if saved.has("half") and not _is_coordinate(saved.half):
			return {}
		for key in ["paid_ranks", "rank_choices"]:
			var ranks = saved.get(key, [])
			if not ranks is Array or not ranks.all(_is_number):
				return {}
		var legacy = saved.get("legacy", "")
		if not legacy is String or (legacy != "" and (not ResourceLoader.exists(legacy) or not load(legacy) is TowerData)):
			return {}
	return data

static func _is_number(value: Variant) -> bool:
	return value is int or (value is float and is_finite(value))

static func _is_coordinate(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _is_number(value[0]) and _is_number(value[1])

static func read_saved_run() -> Dictionary:
	var data := _parse_run(file_path)
	return data if not data.is_empty() else _parse_run(file_path + ".bak")

func _read() -> Dictionary:
	var data := read_saved_run()
	if data.is_empty():
		push_warning("Run save unreadable or from another version; keeping it for recovery")
	return data

# A restored map must have a route (Android, v0.1.15: a continued run after an update had none: no path tiles,
# nightmares stuck at the start; not reproduced headless). If it hasn't: every restored Warden comes off the grid
# (and if that isn't enough, obstacles and gift terrain on the way are cleared as generation does), then they go back
# one at a time, most Dew first; any whose return would cut the route again is taken back with a full Dew refund.
# Returns what happened for the run history ({} = the route was fine).
func _repair_route(data: Dictionary) -> Dictionary:
	if not map_generator.get_path_from(map_generator.startPath).is_empty():
		return {}
	var layer = map_generator.path_layer
	var towers: Array = []
	for node in tower_container.get_children():
		if node is Tower and not node.is_queued_for_deletion() and not node.tower_data.rooted:
			towers.append(node)
	for tower in towers:
		for h in tower.get_halves():
			layer.set_half_blocked(h, false)
	var cleared: Array = []
	if layer.find_path_from(map_generator.startPath).is_empty():  # Not the Wardens: the ground itself
		var before: Array = map_generator.obstacles.keys()
		map_generator._carve_route_if_blocked()
		cleared = before.filter(func(c: Vector2) -> bool: return not map_generator.obstacles.has(c))
		var map_gifts = map_generator.get("gifts")
		for cell in cleared:  # Kept cleared through the next save: tended (no Seed), out of the gift terrain
			if not run_state.tended_cells.has(cell):
				run_state.tended_cells.append(cell)
			if map_gifts != null and map_gifts.gift_obstacles.has(cell):
				map_gifts.gift_obstacles.erase(cell)
		if map_gifts != null and not cleared.is_empty():
			map_gifts._rebuild_props()
	towers.sort_custom(func(a: Tower, b: Tower) -> bool: return a.invested_dew > b.invested_dew)
	var removed: Array[Tower] = []
	for tower in towers:
		for h in tower.get_halves():
			layer.set_half_blocked(h, true)
		if layer.find_path_from(map_generator.startPath).is_empty():
			for h in tower.get_halves():
				layer.set_half_blocked(h, false)
			removed.append(tower)
	var refund := 0
	for tower in removed:
		refund += tower.invested_dew
		tower_container.remove_child(tower)
		tower.queue_free()
	if refund > 0:
		run_state.add_dew(refund)  # In full: the player never chose this
	layer.draw()
	map_generator.path_changed.emit()
	var repaired: bool = not map_generator.get_path_from(map_generator.startPath).is_empty()
	var words: Array[String] = []
	if not removed.is_empty():
		words.append("%d Warden%s returned, %s refunded" % [removed.size(), "" if removed.size() == 1 else "s", UiStyle.dew_amount(refund)])
	if not cleared.is_empty():
		words.append("%d obstacle%s cleared" % [cleared.size(), "" if cleared.size() == 1 else "s"])
	var toast := ("The path was blocked after the update: " + ", ".join(words) + ".") if repaired and not words.is_empty() \
		else "The path was blocked after the update and couldn't be repaired."
	_toast.call_deferred(toast)
	push_warning("RunSaver: restored map had no route (save %s, app %s): %s" % [data.get("version", "?"), data.get("app_version", "?"), toast])
	return {"drift": int(data.get("drifts_started", 0)), "save_version": int(data.get("version", 0)),
		"app_version": String(data.get("app_version", "")), "build": String(data.get("build", "")),
		"wardens_returned": removed.map(_tower_note),
		"obstacles_cleared": cleared.map(func(c: Vector2) -> Array: return [c.x, c.y]),
		"refund": refund, "repaired": repaired}

static func _tower_note(tower: Tower) -> Dictionary:
	return {"id": tower.tower_data.get_id(), "cell": [tower.cell.x, tower.cell.y], "half": [tower.half_cell.x, tower.half_cell.y],
		"dew": tower.invested_dew}

func _toast(text: String) -> void:
	var hud := get_parent().get_node_or_null("HUD") if get_parent() != null else null
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast(text)

# Rebuilds the saved run on the freshly generated (same-seed) map. The run resumes resting.
func _restore(data: Dictionary) -> void:
	# The forest as it was: tended obstacles gone, Wardens back in place.
	for cell in data.tended:
		map_generator._remove_obstacle(Vector2(cell[0], cell[1]))
	var gifts := HeartwoodGifts.find(self)  # Heartwood's Gifts (Spire): their terrain back before the Wardens
	if gifts != null and data.has("gifts"):
		# The tended cells first: restoring terrain gifts skip what the player tended after them (Environment Code;
		# set again below, after anything a restoring effect appended).
		run_state.tended_cells.assign(data.tended.map(func(c: Array) -> Vector2: return Vector2(c[0], c[1])))
		gifts.load_save(data.gifts)
	for saved in data.towers:
		var tower: Tower = tower_placer.tower_scene.instantiate()
		tower.tower_data = load(saved.data)
		tower.cell = Vector2(saved.cell[0], saved.cell[1])
		tower.invested_dew = int(saved.invested)
		tower.rest_dew = int(saved.get("rest_dew", 0))  # Placed this rest (saves happen at rests)
		tower.rank = int(saved.get("rank", 0))  # Saves from before Nurture have none
		tower.paid_ranks.clear()  # Bought ranks (free ones stay free through growth); older saves: every rank paid
		for r in saved.get("paid_ranks", range(1, tower.rank + 1)):
			tower.paid_ranks.append(int(r))
		tower.banked_ranks = int(saved.get("banked_ranks", 0))  # Granted ranks still to spend
		tower.focus = int(saved.get("focus", 0)) as Tower.Focus
		tower.rank_choices.clear()  # Nurture v3: one choice per rank (older saves: Tower._migrate_choices fills them)
		for choice in saved.get("rank_choices", []):
			tower.rank_choices.append(int(choice))
		tower._migrate_choices()
		tower.target_mode = int(saved.get("target_mode", 0)) as TowerData.TargetMode  # Targeting
		tower.target_chosen = bool(saved.get("target_chosen", saved.has("target_mode") and tower.tower_data.has_target_priority))
		tower.kin_branch = String(saved.get("kin_branch", ""))  # An Ascended form's branch (Kinships)
		if String(saved.get("legacy", "")) != "":
			tower.legacy_data = load(saved.legacy)  # The final form it grew from (its legacy attack)
		if int(saved.get("drifts_stood", 0)) > 0:  # Old Growth: drifts this Warden has stood
			tower.set_meta(&"drifts_stood", int(saved.drifts_stood))
		if bool(saved.get("gift_sprout", false)):
			tower.set_meta(&"gift_sprout", true)
		if bool(saved.get("sprout_line", false)):
			tower.set_meta(&"sprout_line", true)
		tower.set_meta(&"unique_plant_order", int(saved.get("unique_plant_order", 0)))
		tower.set_meta(&"unique_plant_rest", int(saved.get("unique_plant_rest", -1)))
		if bool(saved.get("underdog", false)):
			tower.set_meta(&"underdog", true)
		# Ascended forms grew to 2×2: one saved before that (no "size") stays on its one cell.
		var size := int(saved.get("size", 1 if tower.tower_data.tier >= DreamState.ASCENDED_TIER else 0))
		if size > 0 and size != tower.tower_data.footprint:
			tower.footprint_size = size
		var half: Array = saved.get("half", [-1, -1])  # Its half-cell origin, if it has one
		tower.half_cell = Vector2(half[0], half[1])
		tower.twig = bool(saved.get("twig", false)) and tower.half_cell.x >= 0
		if tower.twig:
			tower.position = Tower.twig_centre(tower.half_cell)
		else:
			tower.position = Tower.half_centre(tower.half_cell) if tower.half_cell.x >= 0 else Tower.footprint_centre(tower.cell, tower.get_footprint())
		tower_container.add_child(tower)
		if map_generator.path_layer.has_method("set_half_blocked"):
			for h in tower.get_halves():  # Its 2×2 halves (the Sapling: its cells' halves)
				map_generator.path_layer.set_half_blocked(h, true)
		else:
			for c in tower.get_cells():  # The Sapling covers 2×2
				map_generator.path_layer.set_cell_blocked(c, true)
		if tower.tower_data.get_id() == TowerPlacer.SAPLING_ID:
			tower_placer.sapling_taken = true
	map_generator.path_layer.draw()
	map_generator.path_changed.emit()

	run_state.dew = int(data.dew)
	run_state.max_leaves = int(data.max_leaves)
	run_state.leaves = int(data.leaves)
	run_state.obstacles_tended = int(data.obstacles_tended)
	run_state.tended_cells.assign(data.tended.map(func(c: Array) -> Vector2: return Vector2(c[0], c[1])))
	run_state.omen_seeds = int(data.omen_seeds)
	run_state.creatures_cleansed = int(data.creatures_cleansed)
	run_state.cleansed_in_act_1 = int(data.get("cleansed_in_act_1", 0))
	run_state.cleansed_in_act_2 = int(data.get("cleansed_in_act_2", 0))
	run_state.leaves_lost = int(data.get("leaves_lost", 0))
	run_state.longest_path = maxi(run_state.longest_path, int(data.get("longest_path", 0)))
	run_state.play_time = float(data.get("play_time", 0.0))
	# Clearing Dream cards. Burn Back's clears are in `tended` without counting as tended, so both
	# are restored as saved, never recomputed from each other.
	run_state.fertile_cells.clear()
	for cell in data.get("fertile_cells", []):
		run_state.fertile_cells[Vector2(cell[0], cell[1])] = true
	run_state.add_free_clears(int(data.get("free_clears", 0)) - run_state.free_clears)
	run_state.add_sprout_charges(int(data.get("sprout_charges", 0)) - run_state.sprout_charges)
	run_state.free_nurtures = int(data.get("free_nurtures", 0))
	if "foretold" in family_screen:
		family_screen.foretold = Array(data.get("foretold", []))  # Kin Foretold: the same families, as promised
	run_state.dew_harvested = int(data.get("dew_harvested", 0))
	if "rank_dew_spent" in run_state:
		run_state.rank_dew_spent = int(data.get("rank_dew_spent", 0))
	if "memory_seeds" in run_state:
		run_state.memory_seeds.assign(data.get("memory_seeds", []).map(func(r) -> int: return int(r)))
	run_state.dew_changed.emit(run_state.dew)
	run_state.leaves_changed.emit(run_state.leaves, run_state.max_leaves)
	var repair := _repair_route(data)  # A restored map with no route (Android v0.1.15): fixed here, logged below

	drift_director.drifts_started = int(data.drifts_started)
	drift_director.drifts_cleared = int(data.drifts_cleared)
	drift_director.blocks_rested = int(data.blocks_rested)
	drift_director.maze_economy.load_save(data.get("maze_economy", {}))
	drift_director._maze_changed()
	drift_director.bosses_cleansed = int(data.bosses_cleansed)
	drift_director.early_calls = int(data.get("early_calls", 0))
	drift_director.call_early_dew = int(data.get("call_early_dew", 0))
	drift_director.set_auto_drift(bool(data.auto_drift))
	drift_director.resting = true
	drift_director.build_phase_changed.emit(true)

	dream_state.load_save(data.dreams)
	var omens := get_tree().get_first_node_in_group(&"omens")
	if omens != null and data.has("omens") and omens.has_method("load_save"):
		omens.load_save(data.omens)
	var history := get_tree().get_first_node_in_group(RunHistory.GROUP) as RunHistory
	if history != null and data.has("history"):
		history.load_save(data.history)
	if history != null and not repair.is_empty():  # In the run report, so we learn the cause
		history.run["route_repairs"] = Array(history.run.get("route_repairs", [])) + [repair]
	var kin := Kinships.find(tower_container)
	if kin != null and data.has("kinships"):
		kin.load_save(data.kinships)  # After the Wardens are back, so the saved bonds keep their age
	dream_state.unlocks_changed.emit()
