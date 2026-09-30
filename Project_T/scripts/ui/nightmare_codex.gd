extends Node
class_name NightmareCodex

# The Codex's Nightmares (screens_ui.md "Nightmares"): every nightmare and boss, "???" until first met
# (profile nightmares_seen, which NightmareInfo writes on first sight, dev runs included; account
# knowledge lives on the real profile, see HeartwoodMemory.ACCOUNT_KEYS). This node counts lifetime
# dispels per kind (profile nightmare_dispels, flushed at rests and the run's end, never in tests)
# and grows the "Know every nightmare" milestone (all_nightmares; normal runs). The Codex reads the
# static helpers. Made by the HUD.

const DIR := "res://resource/enemy/"
const DISPELS_KEY := "nightmare_dispels"  # {kind: n}
const VIEWED_KEY := "nightmares_viewed"  # The Codex's gold "New" until the page has been opened
const MILESTONE := "all_nightmares"  # "Know every nightmare"

static var _all: Array[EnemyData] = []
static var _acts := {}  # Kind -> act (1–4)

var drift_director: DriftDirector
var _pending := {}  # Kind -> dispels not yet written

# Every nightmare and boss, by act, then name; bosses last within their act.
static func all_kinds() -> Array[EnemyData]:
	if _all.is_empty():
		for file in ResourceLoader.list_directory(DIR):
			if file.ends_with(".tres") or file.ends_with(".res"):
				var data := load(DIR + file) as EnemyData
				if data != null:
					_all.append(data)
		_all.sort_custom(func(a: EnemyData, b: EnemyData) -> bool:
			var act_a := act_of(a)
			var act_b := act_of(b)
			if act_a != act_b:
				return act_a < act_b
			if a.is_boss != b.is_boss:
				return not a.is_boss
			return a.display_name < b.display_name)
	return _all

static func kind_of(data: EnemyData) -> String:
	return data.resource_path.get_file().get_basename()

# The act a kind belongs to: a boss's act from its pool; otherwise the act of its first drift in the
# hand-made run, its introduction drift, or the act of the nightmare that brings it (split / followers
# / summons); act 1 if none of these say.
static func act_of(data: EnemyData) -> int:
	var kind := kind_of(data)
	if _acts.is_empty():
		_build_acts()
	return int(_acts.get(kind, 1))

static func _build_acts() -> void:
	_acts["_"] = 0  # Built
	for act in range(1, BossPool.ACTS + 1):
		for boss in BossPool.get_pool(act):
			if boss.boss != null:
				_acts[kind_of(boss.boss)] = act
	var drifts := DriftDirector.load_demo_drifts()
	for i in drifts.size():
		for group in drifts[i].groups:
			for entry in group.entries:
				if entry.enemy != null and not _acts.has(kind_of(entry.enemy)):
					_acts[kind_of(entry.enemy)] = ceili((i + 1) / 25.0)
	for file in ResourceLoader.list_directory(DIR):
		var data := load(DIR + file) as EnemyData if file.ends_with(".tres") else null
		if data == null:
			continue
		if not _acts.has(kind_of(data)) and data.intro_drift > 0:
			_acts[kind_of(data)] = ceili(data.intro_drift / 25.0)
	# Brought by another nightmare: its parent's act.
	for file in ResourceLoader.list_directory(DIR):
		var parent := load(DIR + file) as EnemyData if file.ends_with(".tres") else null
		if parent == null or not _acts.has(kind_of(parent)):
			continue
		for summon in parent.get_summons():  # Followers, splits, broods, grief spawns
			var child = summon.get("data")
			if child is EnemyData and not _acts.has(kind_of(child)):
				_acts[kind_of(child)] = _acts[kind_of(parent)]

static func seen() -> Array:
	return HeartwoodMemory.load_data().get("nightmares_seen", [])

# The Codex marks the met kinds viewed (their gold "New" goes); never from tests.
static func mark_viewed(kinds: Array) -> void:
	if OS.get_cmdline_args().has("--script") or kinds.is_empty():
		return
	var profile := HeartwoodMemory.load_data()
	var viewed: Array = profile.get(VIEWED_KEY, [])
	var added := false
	for kind in kinds:
		if not viewed.has(kind):
			viewed.append(kind)
			added = true
	if added:
		profile[VIEWED_KEY] = viewed
		HeartwoodMemory.save_data(profile)

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	if drift_director == null:
		return
	var spawner := drift_director.get_node_or_null("%EnemyContainer")
	if spawner != null:
		spawner.enemy_cleansed.connect(_on_dispelled)
	drift_director.rest_started.connect(func(_b: int, _boss: bool, _bonus: int, _perfect: bool) -> void: flush())
	var run_state := drift_director.get_node_or_null("%RunState")
	if run_state != null:
		run_state.run_ended.connect(func(_won: bool) -> void: flush())

func _on_dispelled(enemy: Node2D) -> void:
	var data = enemy.get("enemy_data")
	if data is EnemyData and not enemy.get("is_echo"):
		var kind := kind_of(data)
		_pending[kind] = int(_pending.get(kind, 0)) + 1

# The real game only (tests never write): the dispels so far, and the milestone once every kind is met.
func _may_write() -> bool:
	return drift_director != null and get_tree().current_scene == drift_director.owner

func flush() -> void:
	if not _may_write():
		_pending.clear()
		return
	var profile := HeartwoodMemory.load_data()
	var changed := false
	if not _pending.is_empty():
		var dispels: Dictionary = profile.get(DISPELS_KEY, {})
		for kind in _pending:
			dispels[kind] = int(dispels.get(kind, 0)) + int(_pending[kind])
		profile[DISPELS_KEY] = dispels
		_pending.clear()
		changed = true
	var met: Array = profile.get("nightmares_seen", [])
	if not MetaRun.is_dev_run() and not profile.milestones.has(MILESTONE) \
			and all_kinds().all(func(d: EnemyData) -> bool: return met.has(kind_of(d))):
		profile.milestones[MILESTONE] = true
		changed = true
	if changed:
		HeartwoodMemory.save_data(profile)
