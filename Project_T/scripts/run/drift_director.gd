extends Node
class_name DriftDirector

# Runs the drifts (waves). Between drifts is the build phase: no timer, the player presses Start
# Drift. Once the current drift has finished arriving, the next one can be called early for a small
# Dew bonus, so several drifts can be on the field at once. A drift is cleared when all of its
# creatures (including ones split off during it) are cleansed or reached the Heartwood.
# See documentation/run_design.md.

signal drift_started(number: int)
# `bonus` includes the perfect bonus when `perfect` (no leaf lost to this drift).
signal drift_cleared(number: int, bonus: int, perfect: bool)
# A new act began: the Heartwood regrew `leaves_regrown` leaves.
signal act_started(act: int, leaves_regrown: int)
# Build phase started (true) or ended (false: a drift is running).
signal build_phase_changed(is_build_phase: bool)
# The latest drift finished arriving: the next one can be called early now.
signal drift_arrived(number: int)

@export var drifts: Array[DriftData] = [
	preload("res://resource/drift/act1/drift_1.tres"),
	preload("res://resource/drift/act1/drift_2.tres"),
	preload("res://resource/drift/act1/drift_3.tres"),
	preload("res://resource/drift/act1/drift_4.tres"),
	preload("res://resource/drift/act1/drift_5.tres"),
]
@export var act_names: Array[String] = ["Forest's Edge", "Deep Wood", "Heartwood Glade"]
@export var drifts_per_act: int = 5
@export var health_growth_per_drift: float = 1.12  # Non-boss health multiplier per drift
@export var clear_bonus_base: int = 15  # Drift-clear bonus = base + per_drift × drift number
@export var clear_bonus_per_drift: int = 5
@export var perfect_bonus: int = 5  # Extra when no leaf was lost to the drift
@export var act_break_leaves: int = 3
@export var call_early_seconds_per_dew: float = 2.0

@onready var run_state: RunState = %RunState
@onready var spawner = %EnemyContainer

# Drifts started so far; also the number of the latest drift (1-based).
var drifts_started := 0
var drifts_cleared := 0
# Drifts on the field: {number: {"remaining": int, "arriving": bool, "leaked": bool}}.
var _active := {}
# Which drift each creature on the field belongs to: {enemy: number}.
var _drift_of := {}
# Creatures of the latest drift still to arrive: [[seconds from its start, EnemyData], ...].
var _schedule: Array = []
var _clock := 0.0

func _ready() -> void:
	spawner.enemy_split.connect(_on_enemy_split)
	spawner.enemy_cleansed.connect(_resolve.bind(false))
	spawner.enemy_reached_goal.connect(_resolve.bind(true))
	run_state.run_ended.connect(_on_run_ended)

func _process(delta: float) -> void:
	if _schedule.is_empty():
		return
	_clock += delta
	while not _schedule.is_empty() and _schedule[0][0] <= _clock:
		var data: EnemyData = _schedule.pop_front()[1]
		_spawn(data, drifts_started)
	if _schedule.is_empty():
		_active[drifts_started].arriving = false
		drift_arrived.emit(drifts_started)
		_check_cleared(drifts_started)


# --- Queries (for the HUD) ------------------------------------------------------------------------

func is_build_phase() -> bool:
	return _active.is_empty() and not run_state.is_over

func is_arriving() -> bool:
	return not _schedule.is_empty()

func has_next_drift() -> bool:
	return drifts_started < drifts.size()

# Start Drift works in the build phase, and as "call early" once the latest drift has fully arrived.
func can_start_next_drift() -> bool:
	return has_next_drift() and not is_arriving() and not run_state.is_over

func get_total_drifts() -> int:
	return drifts.size()

# The act (1-based) that drift `number` belongs to.
func get_act(number: int) -> int:
	return (maxi(number, 1) - 1) / drifts_per_act + 1

func get_act_name(act: int) -> String:
	return act_names[act - 1] if act - 1 < act_names.size() else "Act %d" % act

func get_clear_bonus(number: int) -> int:
	return clear_bonus_base + clear_bonus_per_drift * number

# Dew for calling the next drift now: +1 per `call_early_seconds_per_dew` seconds skipped (the time
# until the slowest creature on the field would reach the Heartwood), capped at the latest drift's
# clear bonus. 0 in the build phase.
func get_call_early_bonus() -> int:
	if is_build_phase() or not can_start_next_drift():
		return 0
	var skipped := 0.0
	for enemy in spawner.get_enemies():
		if enemy.speed > 0.0:
			skipped = maxf(skipped, enemy.get_remaining_distance() / enemy.speed)
	return mini(int(skipped / call_early_seconds_per_dew), get_clear_bonus(drifts_started))


# --- Actions --------------------------------------------------------------------------------------

# Starts the next drift (Start Drift, or call early during a drift). Returns false if it can't.
func start_next_drift() -> bool:
	if not can_start_next_drift():
		return false
	var early_bonus := get_call_early_bonus()
	var was_build_phase := is_build_phase()
	drifts_started += 1
	var number := drifts_started
	_active[number] = {"remaining": 0, "arriving": true, "leaked": false}
	_schedule = drifts[number - 1].get_schedule()
	_clock = 0.0
	if early_bonus > 0:
		run_state.add_dew(early_bonus)
	if was_build_phase:
		build_phase_changed.emit(false)
	drift_started.emit(number)
	# Creatures due at t=0 arrive right away, not a frame later.
	_process(0.0)
	return true

func get_health_scale(data: EnemyData, number: int) -> float:
	if data.is_boss:
		return 1.0
	return pow(health_growth_per_drift, number - 1)

func _spawn(data: EnemyData, number: int) -> void:
	var enemy: Node2D = spawner.spawn_enemy(data, get_health_scale(data, number))
	if enemy == null:
		return  # No route (shouldn't happen: building never fully blocks the path)
	_drift_of[enemy] = number
	_active[number].remaining += 1


# --- Bookkeeping ----------------------------------------------------------------------------------

func _on_enemy_split(parent: Node2D, child: Node2D) -> void:
	if not _drift_of.has(parent):
		return
	var number: int = _drift_of[parent]
	_drift_of[child] = number
	_active[number].remaining += 1

# A creature left the field: cleansed, or reached the Heartwood (`leaked`).
func _resolve(enemy: Node2D, leaked: bool) -> void:
	if not _drift_of.has(enemy):
		return  # Not spawned by a drift (e.g. tests)
	var number: int = _drift_of[enemy]
	_drift_of.erase(enemy)
	var drift: Dictionary = _active[number]
	drift.remaining -= 1
	if leaked:
		drift.leaked = true
	_check_cleared(number)

func _check_cleared(number: int) -> void:
	var drift: Dictionary = _active.get(number, {})
	if drift.is_empty() or drift.arriving or drift.remaining > 0 or run_state.is_over:
		return
	_active.erase(number)
	drifts_cleared += 1
	var perfect: bool = not drift.leaked
	var bonus := get_clear_bonus(number) + (perfect_bonus if perfect else 0)
	run_state.add_dew(bonus)
	drift_cleared.emit(number, bonus, perfect)

	if number % drifts_per_act == 0 and number < drifts.size():
		var before := run_state.leaves
		run_state.regrow_leaves(act_break_leaves)
		act_started.emit(get_act(number + 1), run_state.leaves - before)

	if not has_next_drift() and _active.is_empty():
		run_state.end_run(true)
	elif _active.is_empty():
		build_phase_changed.emit(true)

func _on_run_ended(_won: bool) -> void:
	_schedule.clear()
	set_process(false)
