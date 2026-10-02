extends Node2D
class_name GrowHints

# Grow onboarding (onboarding.md b024ccda; human run 12 reached drift 30 and never grew or ranked a Warden):
# - At rests only, a small gold ↑ at the base of every Warden that can grow now (an unlocked form it can afford)
#   and a small gold dot when its next rank is affordable. Setting Gameplay → "Growth hints" (SETTING, default on).
# - The first rest any Warden can grow (once per profile): the one nearest the view centre shimmers with a big ↑,
#   with the whisper "That Sporeling could grow. Click it."; selecting it pulses the panel's Grow buttons once.
# - The first time a rank is affordable on a selected Warden (once per profile), the Nurture button pulses once.
# - Drift 15 with nothing grown or ranked this run: "Your Wardens can become much more than this." (a whisper).
# World node made by the HUD; polls only at rests (POLL_EVERY), draws nothing during drifts.

const SETTING := "growth_hints"
const PROFILE_KEY := "grow_hints_seen"  # ["spotlight", "nurture"]: once per profile
const REMIND_DRIFT := 15
const POLL_EVERY := 0.25
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
var _poll := 0.0
var _time := 0.0
var _seen: Array = []

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	name = "GrowHints"
	z_index = 5
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
		queue_redraw())
	drift_director.drift_started.connect(_on_drift_started)
	if tower_seller != null:
		tower_seller.selection_changed.connect(_on_selection_changed)

static func enabled() -> bool:
	return bool(HeartwoodMemory.get_settings().get(SETTING, true))

func _process(delta: float) -> void:
	var resting := drift_director.is_resting() and run_state != null and not run_state.is_over
	if not resting:
		if not marks.is_empty() or spotlight != null:
			marks.clear()
			spotlight = null
			queue_redraw()
		return
	_time += delta
	if spotlight != null:
		queue_redraw()  # The shimmer
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = POLL_EVERY
	refresh()

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
	queue_redraw()

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
		queue_redraw()
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

func _draw() -> void:
	var show_marks := enabled()
	for mark in marks:
		var tower: Tower = mark.tower
		if not is_instance_valid(tower) or (not show_marks and tower != spotlight):
			continue
		var base := to_local(tower.global_position) + BASE
		if mark.grow and tower != spotlight:
			_arrow(base + Vector2(-MARK_OFFSET, 0), 5.0)
		if mark.rank:
			draw_circle(base + Vector2(MARK_OFFSET, 0), 4.0, Palette.DREAD)
			draw_circle(base + Vector2(MARK_OFFSET, 0), 2.5, UiStyle.GOLD)
	if spotlight != null and is_instance_valid(spotlight):
		var base := to_local(spotlight.global_position) + BASE
		var still := bool(Fx.setting("reduced_motion", false))
		var beat := 0.5 if still else 0.5 + 0.5 * sin(_time * 4.0)
		draw_arc(base - Vector2(0, 14), 30.0 + 4.0 * beat, 0.0, TAU, 40, Color(UiStyle.GOLD, 0.35 + 0.4 * beat), 2.0, true)
		_arrow(base + Vector2(0, -2 - 4.0 * beat), 9.0)

# A gold "↑" with a dark rim (readable on grass and path).
func _arrow(at: Vector2, size: float) -> void:
	var head := PackedVector2Array([at + Vector2(0, -size * 1.6), at + Vector2(size, -size * 0.4), at + Vector2(-size, -size * 0.4)])
	var rim := PackedVector2Array([at + Vector2(0, -size * 1.6 - 2), at + Vector2(size + 2, -size * 0.4 + 1), at + Vector2(-size - 2, -size * 0.4 + 1)])
	draw_colored_polygon(rim, Palette.DREAD)
	draw_line(at + Vector2(0, -size * 0.4), at + Vector2(0, size * 0.6), Palette.DREAD, size * 0.7 + 2)
	draw_colored_polygon(head, UiStyle.GOLD)
	draw_line(at + Vector2(0, -size * 0.4), at + Vector2(0, size * 0.6), UiStyle.GOLD, size * 0.7)
