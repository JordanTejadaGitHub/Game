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
const VERSION := 3  # 2: the map shrank to 23x18; 3: ridges taper (same seed, different map)

# Where the save lives (tests point this elsewhere so they never touch the player's run).
static var file_path := PATH

# Set by the title screen before loading the main scene: restore the saved run.
static var resume_next := false

@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var dream_state: DreamState = %DreamState
@onready var map_generator = %MapGenerator
@onready var tower_container: Node2D = %TowerContainer
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var family_screen: Control = %FamilyPickScreen

var _dirty := false  # A rest began or a choice closed: save once nothing is open
# Autosave only when this is the game actually being played (tests add the scene by hand).
var autosave := true
var _saved_data := {}  # Loaded save, applied once the scene is ready

static func has_save() -> bool:
	return FileAccess.file_exists(file_path)

static func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file_path))

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Choice screens pause the tree
	# Never in tests, and never in Test Grove (a dev playtest would overwrite the real saved run).
	autosave = get_tree().current_scene == owner and not TestGrove.is_active()
	# Runs before MapGenerator (earlier sibling), so the map is rebuilt from the saved seed.
	if resume_next:
		resume_next = false
		_saved_data = _read()
		if not _saved_data.is_empty():
			map_generator.map_seed = int(_saved_data.map_seed)
			MetaRun.blight_level = int(_saved_data.get("blight_level", 0))  # Before MetaRun applies it
	drift_director.rest_started.connect(func(_b: int, _boss: bool, _bonus: int, _perfect: bool) -> void: _dirty = true)
	drift_director.family_pick_requested.connect(func(_reason: StringName) -> void: _dirty = true)
	run_state.run_ended.connect(func(_won: bool) -> void:
		_dirty = false
		if autosave:
			delete_save())
	if not _saved_data.is_empty():
		_restore.call_deferred(_saved_data)
	else:
		_dirty = true  # Save the opening rest too, so Continue exists right away

func _process(_delta: float) -> void:
	if autosave and _dirty and can_save_now():
		save_now()

# A save is only taken while resting with nothing waiting on the player.
func can_save_now() -> bool:
	if run_state.is_over or not drift_director.is_resting() or drift_director.awaiting_family_pick:
		return false
	if family_screen.visible or dream_state.is_offering() or dream_state.has_pending_offer():
		return false
	var omens := get_tree().get_first_node_in_group(&"omens")
	if omens != null and (omens.is_offering() or omens.get("_offer_waiting")):
		return false
	return true

func save_now() -> bool:
	if not can_save_now():
		return false
	_dirty = false
	var towers: Array = []
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion():
			towers.append({"cell": [tower.cell.x, tower.cell.y], "data": tower.tower_data.resource_path,
				"invested": tower.invested_dew, "rank": tower.rank, "focus": tower.focus,
				"target_mode": tower.target_mode, "kin_branch": tower.kin_branch, "size": tower.get_footprint(),
				"drifts_stood": int(tower.get_meta(&"drifts_stood", 0)),  # Old Growth (DreamState counts it)
				"underdog": bool(tower.get_meta(&"underdog", false))})  # Underdog's mark (set at each rest)
	var data := {
		"version": VERSION,
		"map_seed": map_generator.map_seed,
		"blight_level": MetaRun.blight_level,
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
		"fertile_cells": run_state.fertile_cells.keys().map(func(c: Vector2) -> Array: return [c.x, c.y]),
		"creatures_cleansed": run_state.creatures_cleansed,
		"leaves_lost": run_state.leaves_lost,
		"longest_path": run_state.longest_path,
		"play_time": run_state.play_time,
		"drifts_started": drift_director.drifts_started,
		"drifts_cleared": drift_director.drifts_cleared,
		"blocks_rested": drift_director.blocks_rested,
		"bosses_cleansed": drift_director.bosses_cleansed,
		"auto_drift": drift_director.auto_drift,
		"dreams": dream_state.to_save(),
	}
	var omens := get_tree().get_first_node_in_group(&"omens")
	if omens != null and omens.has_method("to_save"):
		data["omens"] = omens.to_save()
	var kin := Kinships.find(tower_container)
	if kin != null:
		data["kinships"] = kin.to_save()  # Bond ages (drifts together), Whole Trees, counts
	# Nurture Dream cards (Tender Care / Warm Hands openers, Remembered Care's memory seeds).
	if "rank_dew_spent" in run_state:
		data["rank_dew_spent"] = run_state.rank_dew_spent
	if "memory_seeds" in run_state:
		data["memory_seeds"] = Array(run_state.memory_seeds)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s" % file_path)
		return false
	file.store_string(JSON.stringify(data))
	return true

func _read() -> Dictionary:
	if not has_save():
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(file_path))
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != VERSION:
		push_warning("Run save unreadable or from another version; starting a new run")
		return {}
	return parsed

# Rebuilds the saved run on the freshly generated (same-seed) map. The run resumes resting.
func _restore(data: Dictionary) -> void:
	# The forest as it was: tended obstacles gone, Wardens back in place.
	for cell in data.tended:
		map_generator._remove_obstacle(Vector2(cell[0], cell[1]))
	for saved in data.towers:
		var tower: Tower = tower_placer.tower_scene.instantiate()
		tower.tower_data = load(saved.data)
		tower.cell = Vector2(saved.cell[0], saved.cell[1])
		tower.invested_dew = int(saved.invested)
		tower.rank = int(saved.get("rank", 0))  # Saves from before Nurture have none
		tower.focus = int(saved.get("focus", 0)) as Tower.Focus
		tower.target_mode = int(saved.get("target_mode", 0)) as TowerData.TargetMode  # Snipers' aim
		tower.kin_branch = String(saved.get("kin_branch", ""))  # An Ascended form's branch (Kinships)
		if int(saved.get("drifts_stood", 0)) > 0:  # Old Growth: drifts this Warden has stood
			tower.set_meta(&"drifts_stood", int(saved.drifts_stood))
		if bool(saved.get("underdog", false)):
			tower.set_meta(&"underdog", true)
		# Ascended forms grew to 2×2: one saved before that (no "size") stays on its one cell.
		var size := int(saved.get("size", 1 if tower.tower_data.tier >= DreamState.ASCENDED_TIER else 0))
		if size > 0 and size != tower.tower_data.footprint:
			tower.footprint_size = size
		tower.position = Tower.footprint_centre(tower.cell, tower.get_footprint())
		tower_container.add_child(tower)
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
	if "rank_dew_spent" in run_state:
		run_state.rank_dew_spent = int(data.get("rank_dew_spent", 0))
	if "memory_seeds" in run_state:
		run_state.memory_seeds.assign(data.get("memory_seeds", []).map(func(r) -> int: return int(r)))
	run_state.dew_changed.emit(run_state.dew)
	run_state.leaves_changed.emit(run_state.leaves, run_state.max_leaves)

	drift_director.drifts_started = int(data.drifts_started)
	drift_director.drifts_cleared = int(data.drifts_cleared)
	drift_director.blocks_rested = int(data.blocks_rested)
	drift_director.bosses_cleansed = int(data.bosses_cleansed)
	drift_director.set_auto_drift(bool(data.auto_drift))
	drift_director.resting = true
	drift_director.build_phase_changed.emit(true)

	dream_state.load_save(data.dreams)
	var omens := get_tree().get_first_node_in_group(&"omens")
	if omens != null and data.has("omens") and omens.has_method("load_save"):
		omens.load_save(data.omens)
	var kin := Kinships.find(tower_container)
	if kin != null and data.has("kinships"):
		kin.load_save(data.kinships)  # After the Wardens are back, so the saved bonds keep their age
	dream_state.unlocks_changed.emit()
