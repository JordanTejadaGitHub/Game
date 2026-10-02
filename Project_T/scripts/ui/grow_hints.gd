extends Node2D
class_name GrowHints

# Grow onboarding (onboarding.md b024ccda; human run 12 reached drift 30 and never grew or ranked a Warden):
# - At rests only, a small gold ↑ at the base of every Warden that can grow now (an unlocked form it can afford)
#   and a small gold dot when its next rank is affordable. Setting Gameplay → "Growth hints" (SETTING, default on).
# - The first rest any Warden can grow (once per profile): the one nearest the view centre shimmers with a big ↑,
#   with the whisper "That Sporeling could grow. Click it."; selecting it pulses the panel's Grow buttons once.
# - The first time a rank is affordable on a selected Warden (once per profile), the Nurture button pulses once.
# - Drift 15 with nothing grown or ranked this run: "Your Wardens can become much more than this." (a whisper).
# World node made by the HUD; recounts only at rests and only when something changed (Dew: plant, sell, grow, rank;
# a rest; unlocks; cards), draws nothing during drifts (test_perf_stress: polling every Warden 4×/s cost frames).

const SETTING := "growth_hints"
# The marks retire themselves (onboarding.md "Can grow" marks, user-approved): once the profile has grown RETIRE_GROWN
# Wardens or finished RETIRE_RUNS runs, the setting turns Off once, silently; RETIRED_KEY keeps it from flipping again
# if the player turns it back on. Real game only (dev runs don't count).
const GROWN_KEY := "wardens_grown"  # Profile: Wardens grown, all runs
const RETIRED_KEY := "growth_hints_retired"
const RETIRE_GROWN := 10
const RETIRE_RUNS := 3
const MARK_ALPHA := 0.6  # The marks are quiet (no glow, no pulse); the first-time spotlight stays loud
const PROFILE_KEY := "grow_hints_seen"  # ["spotlight", "nurture"]: once per profile
const REMIND_DRIFT := 15
const BASE := Vector2(0, 22)  # A Warden's base from its cell centre
const MARK_OFFSET := 18.0

var drift_director: DriftDirector
var run_state: RunState
var dream_state: DreamState
var tower_container: Node
var tower_seller: TowerSeller
var whispers: Node
var panel: Node
var marks: Array = []  # [{tower, grow: bool, rank: bool}] at this rest
var spotlight: Tower = null  # The Warden the first grow hint points at
var _dirty := true  # Something changed since the last count
var _time := 0.0
var _seen: Array = []
var _marks_layer := Node2D.new()  # The quiet marks (redrawn on refresh only)

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	name = "GrowHints"
	z_index = 5
	_marks_layer.name = "Marks"
	_marks_layer.draw.connect(_draw_marks)
	add_child(_marks_layer)
	process_mode = Node.PROCESS_MODE_ALWAYS  # A paused rest still shows them
	run_state = drift_director.get_node_or_null("%RunState")
	dream_state = drift_director.get_node_or_null("%DreamState")
	tower_container = drift_director.get_node_or_null("%TowerContainer")
	tower_seller = drift_director.get_node_or_null("%TowerSeller")
	whispers = drift_director.get_node_or_null("%Whispers")
	var hud := drift_director.owner.get_node_or_null("HUD") if drift_director.owner else null
	panel = hud.get_node_or_null("WardenPanel") if hud else null
	_seen = HeartwoodMemory.load_data().get(PROFILE_KEY, [])
	drift_director.rest_ended.connect(func(_block: int) -> void:
		spotlight = null
		marks.clear()
		_redraw())
	drift_director.drift_started.connect(_on_drift_started)
	drift_director.rest_started.connect(func(_b: int, _boss: bool, _bonus: int, _perfect: bool) -> void: _mark_dirty())
	run_state.dew_changed.connect(_mark_dirty.unbind(1))  # Plant, sell, grow and rank all move Dew
	dream_state.unlocks_changed.connect(_mark_dirty)
	dream_state.card_taken.connect(_mark_dirty.unbind(1))
	if tower_container != null:
		tower_container.child_exiting_tree.connect(_mark_dirty.unbind(1))
		tower_container.child_entered_tree.connect(func(node: Node) -> void:
			if node is Tower and not node.evolved.is_connected(_on_evolved):
				node.evolved.connect(_on_evolved))
	if tower_seller != null:
		tower_seller.selection_changed.connect(_on_selection_changed)
	if _counts():
		var memory := HeartwoodMemory.load_data()
		if retire_check(memory):
			HeartwoodMemory.save_data(memory)

# The real game, not a dev run (Test Grove, all families, Dev Grove): only these count and flip the setting.
func _counts() -> bool:
	return get_tree().current_scene == drift_director.owner and not MetaRun.is_dev_run()

func _on_evolved(_tower: Tower) -> void:
	if not _counts():
		return
	var memory := HeartwoodMemory.load_data()
	memory[GROWN_KEY] = int(memory.get(GROWN_KEY, 0)) + 1
	retire_check(memory)
	HeartwoodMemory.save_data(memory)

# Turns the marks Off in `memory` once enough has been grown or played; true if it flipped now.
static func retire_check(memory: Dictionary) -> bool:
	if bool(memory.get(RETIRED_KEY, false)):
		return false
	if int(memory.get(GROWN_KEY, 0)) < RETIRE_GROWN and int(memory.get("runs_played", 0)) < RETIRE_RUNS:
		return false
	memory[RETIRED_KEY] = true
	memory.settings[SETTING] = false
	return true

static func enabled() -> bool:
	return bool(HeartwoodMemory.get_settings().get(SETTING, true))

func _process(delta: float) -> void:
	var resting := drift_director.is_resting() and run_state != null and not run_state.is_over
	if not resting:
		_dirty = true  # Recount when the next rest comes
		if not marks.is_empty() or spotlight != null:
			marks.clear()
			spotlight = null
			_redraw()
		return
	_time += delta
	if spotlight != null:
		queue_redraw()  # The shimmer
	if _dirty:
		_dirty = false
		refresh()

# The marks layer and the spotlight (the marks changed).
func _redraw() -> void:
	queue_redraw()
	_marks_layer.queue_redraw()

func _mark_dirty() -> void:
	_dirty = true

# What every Warden can do with the Dew there is now; starts the spotlight the first time one can grow.
func refresh() -> void:
	marks.clear()
	if tower_container == null or dream_state == null:
		return
	var growable: Array[Tower] = []
	for tower in tower_container.get_children():
		if not tower is Tower or tower.is_queued_for_deletion():
			continue
		var grow := can_grow_now(tower)
		var rank: bool = tower.can_nurture() and run_state.can_afford(tower.get_nurture_cost())
		if grow:
			growable.append(tower)
		if grow or rank:
			marks.append({"tower": tower, "grow": grow, "rank": rank})
	if spotlight != null and (not is_instance_valid(spotlight) or not growable.has(spotlight)):
		spotlight = null  # Grown, sold, or no longer affordable
	if spotlight == null and not growable.is_empty() and not _seen.has("spotlight"):
		spotlight = _nearest_to_view(growable)
		_note("spotlight")
		if whispers != null and whispers.has_method("whisper"):
			whispers.whisper(&"grow", [spotlight.tower_data.display_name])
	_redraw()

# An unlocked form it can afford now (ranked Wardens pay the rank difference: Tower.get_grow_cost).
func can_grow_now(tower: Tower) -> bool:
	for option in Tower.grow_options(dream_state, tower.tower_data):
		if option[1] and run_state.can_afford(tower.get_grow_cost(option[0]).total):
			return true
	return false

func _nearest_to_view(towers: Array[Tower]) -> Tower:
	var centre := get_viewport().get_camera_2d().get_screen_center_position() if get_viewport().get_camera_2d() else Vector2.ZERO
	var best: Tower = towers[0]
	for tower in towers:
		if tower.global_position.distance_to(centre) < best.global_position.distance_to(centre):
			best = tower
	return best

func _on_selection_changed(towers: Array[Tower]) -> void:
	if towers.size() != 1 or not drift_director.is_resting():
		return
	var tower: Tower = towers[0]
	if tower == spotlight:
		spotlight = null  # Found it: the Grow buttons take over
		_redraw()
		_pulse.call_deferred(&"grow")  # After the panel's refresh built them
	elif not _seen.has("nurture") and tower.can_nurture() and run_state.can_afford(tower.get_nurture_cost()):
		_note("nurture")
		_pulse.call_deferred(&"nurture")

func _pulse(kind: StringName) -> void:
	if panel != null and panel.has_method("pulse"):
		panel.pulse(kind)  # Tower Code's WardenPanel hook

func _on_drift_started(number: int) -> void:
	if number == REMIND_DRIFT and not grown_this_run() and whispers != null and whispers.has_method("whisper"):
		whispers.whisper(&"grow_more")  # Whispers are once per profile

# Any Dew spent on growing or ranks this run (RunHistory's spend record), else any grown or ranked Warden.
func grown_this_run() -> bool:
	var history := get_tree().get_first_node_in_group(RunHistory.GROUP)
	if history != null:
		var dew: Dictionary = history.run.get("dew", {})
		if int(dew.get("grow", 0)) > 0 or int(dew.get("rank", 0)) > 0:
			return true
	for tower in tower_container.get_children():
		if tower is Tower and (tower.rank > 0 or tower.tower_data.tier > 1):
			return true
	return false

# Once per profile (the real game only; tests keep it in memory).
func _note(id: String) -> void:
	if _seen.has(id):
		return
	_seen.append(id)
	if get_tree().current_scene != drift_director.owner or MetaRun.is_dev_run():
		return
	var memory := HeartwoodMemory.load_data()
	memory[PROFILE_KEY] = _seen
	HeartwoodMemory.save_data(memory)

# The quiet marks, on their own layer: redrawn only when the count changes (refresh), never per frame (the shimmer
# redrew every mark each frame: test_perf_stress p50 +2.7 ms with a board of Wardens).
func _draw_marks() -> void:
	var show_marks := enabled()
	for mark in marks:
		var tower: Tower = mark.tower
		if not is_instance_valid(tower) or not show_marks:
			continue
		var base := _marks_layer.to_local(tower.global_position) + BASE
		if mark.grow and tower != spotlight:
			_bud(_marks_layer, base + Vector2(-MARK_OFFSET, 0), 5.0, MARK_ALPHA)
		if mark.rank:
			_dewdrop(_marks_layer, base + Vector2(MARK_OFFSET, 0), 4.0, MARK_ALPHA)

# Only the first-time spotlight, which shimmers (redrawn each frame while it's up).
func _draw() -> void:
	if spotlight != null and is_instance_valid(spotlight):
		var base := to_local(spotlight.global_position) + BASE
		var still := bool(Fx.setting("reduced_motion", false))
		var beat := 0.5 if still else 0.5 + 0.5 * sin(_time * 4.0)
		draw_arc(base - Vector2(0, 14), 30.0 + 4.0 * beat, 0.0, TAU, 40, Color(UiStyle.GOLD, 0.35 + 0.4 * beat), 2.0, true)
		_bud(self, base + Vector2(0, -2 - 4.0 * beat), 9.0)

# Until UI Asset's art (can_grow bud, can_rank dewdrop, first_time bud with motes; user: the ↑ didn't fit the theme):
# a small bud drawn in code: a stem, two leaves and a gold bud, dark-rimmed so it reads on grass and path.
func _bud(canvas: CanvasItem, at: Vector2, size: float, alpha: float = 1.0) -> void:
	var top := at + Vector2(0, -size * 1.4)
	var rim := Color(Palette.DREAD, alpha)
	canvas.draw_line(at, top, rim, size * 0.45 + 2.0)
	canvas.draw_line(at, top, Color(Palette.LEAF, alpha), size * 0.45)
	for side in [-1.0, 1.0]:
		var base := at + Vector2(0, -size * 0.55)
		var leaf := PackedVector2Array([base, base + Vector2(side * size * 0.9, -size * 0.35), base + Vector2(side * size * 0.5, size * 0.15)])
		canvas.draw_colored_polygon(leaf, Color(Palette.SPRIG, alpha))
	canvas.draw_circle(top, size * 0.6 + 1.5, rim)
	canvas.draw_circle(top, size * 0.6, Color(UiStyle.GOLD, alpha))
	canvas.draw_circle(top + Vector2(-size * 0.18, -size * 0.18), size * 0.2, Color(Palette.HEARTLIGHT, alpha * 0.8))

# The next rank is affordable: a small dewdrop.
func _dewdrop(canvas: CanvasItem, at: Vector2, size: float, alpha: float = 1.0) -> void:
	var drop := PackedVector2Array([at + Vector2(0, -size * 1.6)])
	for i in 9:
		var angle := PI * (i / 8.0)
		drop.append(at + Vector2(cos(angle) * size, sin(angle) * size * 0.9 - size * 0.1))
	var rim := PackedVector2Array()
	for point in drop:
		rim.append(at + (point - at) * 1.3)
	canvas.draw_colored_polygon(rim, Color(Palette.DREAD, alpha))
	canvas.draw_colored_polygon(drop, Color(Palette.DEWLIGHT, alpha))
	canvas.draw_circle(at + Vector2(-size * 0.3, -size * 0.2), size * 0.22, Color(Palette.HEARTLIGHT, alpha))
