extends Node
class_name DriftDirector

# Runs the drifts (waves) in blocks of 5 (documentation/run_design.md, "Blocks and rests").
#
#   [rest] → Start → drift 1 → (family pick) → Start → drifts 2–5 flow → [rest] → drifts 6–10 → …
#
# - Within a block, drifts FLOW: the next one starts by itself `auto_drift_delay` seconds after the
#   previous one has finished arriving (not after it's cleansed), so drifts overlap. With Auto-drift
#   off, the player starts each drift by hand.
# - Calling the next drift while the current one is still arriving pays +1 Dew per
#   `call_early_seconds_per_dew` seconds of arrival skipped (capped per drift).
# - A REST comes once a block's last drift has arrived and the field is clear: the rest bonus is
#   paid (+ perfect block), `rest_started` fires (Dreams, Omens, boss rewards hook onto it), and
#   the run waits for `start_next_block()`. Boss rests are also act breaks (leaves regrow).
# - A FAMILY PICK (1 of 3 base Wardens) comes after drift 1 and at every boss rest, before the
#   rest itself. The family-pick screen calls `family_picked()` when done.
# - A drift is cleared when all its creatures (including split-off ones and followers) are
#   cleansed or reached the Heartwood.

signal drift_started(number: int)
# `bonus` is 0 now that bonuses are paid at rests; `perfect` = no leaf lost to this drift.
signal drift_cleared(number: int, bonus: int, perfect: bool)
# A new act began: the Heartwood regrew `leaves_regrown` leaves.
signal act_started(act: int, leaves_regrown: int)
# Resting (true: full refunds, waiting for Start) or not (creatures walking / drifts flowing).
# Kept under its old name so earlier listeners keep working.
signal build_phase_changed(is_build_phase: bool)
# The latest drift finished arriving.
signal drift_arrived(number: int)
# A block ended and the field is clear. `bonus` = rest bonus paid (incl. perfect block).
signal rest_started(block_number: int, is_boss_rest: bool, bonus: int, perfect: bool)
# The player pressed Start after a rest.
signal rest_ended(block_number: int)
# A family pick is due: the family-pick screen should show and then call family_picked().
signal family_pick_requested(reason: StringName)  # &"first" (after drift 1) or &"boss"

const DEMO_DRIFTS_DIR := "res://resource/drift/demo/"

@export var drifts: Array[DriftData] = []  # Empty = load resource/drift/demo/drift_NN.tres in order
@export var act_names: Array[String] = ["Forest's Edge", "Deep Wood", "Misty Hollow", "Heartwood Glade"]
@export var drifts_per_block: int = 5
@export var drifts_per_act: int = 25  # The act's last drift is its boss
# Difficulty pass v1 (run_design.md): health growth, boss health, extra nightmares, act-break leaves.
@export var health_growth_per_drift: float = 1.045  # Non-boss health multiplier per drift
# Mid-game rework (run_design.md): steeper growth from drift 26 (compounding from drift 25's
# value), and from then on every drift without listed elites gets one Deeply Blighted nightmare.
@export var late_health_growth_per_drift: float = 1.055
@export var late_growth_from: int = 26
# Acts 3–4 (acts_3_4.md): growth eases back so the late game doesn't run away (≈ ×100 at drift 100).
@export var endgame_health_growth_per_drift: float = 1.045
@export var endgame_growth_from: int = 51
@export var guaranteed_elite_from: int = 26
@export var second_elite_from: int = 76  # Two Deeply Blighted per drift from here
@export var boss_health_multiplier: float = 1.5  # On the bosses' base health
# Acts 3–4 (run_design.md "Act 3 probe", interim): a flat health multiplier for every nightmare from
# `late_acts_from_act`, bosses included, on top of the growth / boss multiplier.
@export var late_acts_health_multiplier: float = 1.4
@export var late_acts_from_act: int = 3
# Act 2 (run_design.md "Difficulty curve targets", interim): x1.0 through act 1 (a fresh profile
# should reach drift 25), then a straight ramp from `early_ramp_from` to `early_acts_health_multiplier`
# at `early_ramp_to`, held until acts 3-4 take over (no stacking).
@export var early_acts_health_multiplier: float = 1.35
@export var early_ramp_from: int = 26
@export var early_ramp_to: int = 40
@export var extra_nightmares: float = 1.25  # Nightmares per drift (rounded up) from `extra_nightmares_from`
@export var extra_nightmares_from: int = 10  # The intro drifts before it are unchanged
# Rest bonus = base + per_block × block number (economy pass v2, run_design.md: was 20 + 10 × block,
# which made the late game "infinite money")
@export var rest_bonus_base: int = 30
@export var rest_bonus_per_block: int = 4
@export var perfect_block_bonus: int = 10  # No leaf lost in the whole block
@export var act_break_leaves: int = 1
@export var auto_drift: bool = true  # Drifts in a block start by themselves
@export var auto_drift_delay: float = 3.0  # Seconds after the previous drift finished arriving
@export var call_early_seconds_per_dew: float = 2.0
@export var call_early_cap: int = 10  # Max Dew for calling one drift early

# Blight Levels (meta_design.md), set by MetaRun at run start. 1.0 / 0 = no change.
var blight_health_multiplier := 1.0  # Nightmares (not bosses)
var blight_boss_health_multiplier := 1.0
var blight_speed_multiplier := 1.0
var blight_rest_bonus_multiplier := 1.0  # The block's rest bonus (before perfect / Dreams)
var rest_bonus_perk_multiplier := 1.0  # Rested Roots (Grove perk), same part of the rest bonus
var blight_elites_per_drift := 0  # Nightmares per drift made Deeply Blighted

@onready var run_state: RunState = %RunState
@onready var spawner = %EnemyContainer

# Drifts started so far; also the number of the latest drift (1-based).
var drifts_started := 0
var drifts_cleared := 0
var blocks_rested := 0  # Rests reached (= blocks finished)
var bosses_cleansed := 0
var resting := true  # The run starts in a rest (build before drift 1)
var awaiting_family_pick := false
# Drifts on the field: {number: {"remaining": int, "arriving": bool, "leaked": bool}}.
var _active := {}
# Which drift each creature on the field belongs to: {enemy: number}.
var _drift_of := {}
# Arrivals still to come, per drift: {number: {"schedule": [[time, EnemyData, elite], ...], "clock": float}}.
var _arriving := {}
var _auto_timer := -1.0  # Counts down to the next auto drift; < 0 = not waiting
var _block_leaked := false

func _ready() -> void:
	if drifts.is_empty():
		drifts = load_demo_drifts()
	if get_tree().current_scene == owner:  # The player's default (tests keep the export's)
		auto_drift = bool(HeartwoodMemory.get_settings().get("auto_drift", auto_drift))
	spawner.enemy_split.connect(_on_enemy_split)
	spawner.enemy_cleansed.connect(_on_enemy_cleansed)
	spawner.enemy_reached_goal.connect(_resolve.bind(true))
	run_state.run_ended.connect(_on_run_ended)

static func load_demo_drifts() -> Array[DriftData]:
	var files: Array[String] = []
	for file in ResourceLoader.list_directory(DEMO_DRIFTS_DIR):
		if file.ends_with(".tres") or file.ends_with(".res"):
			files.append(file)
	# drift_01 … drift_100 in number order (a plain sort would put drift_100 after drift_10)
	files.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	var result: Array[DriftData] = []
	for file in files:
		result.append(load(DEMO_DRIFTS_DIR + file))
	return result

func _process(delta: float) -> void:
	for number in _arriving.keys():
		var arrival: Dictionary = _arriving[number]
		arrival.clock += delta
		var schedule: Array = arrival.schedule
		while not schedule.is_empty() and schedule[0][0] <= arrival.clock:
			var next: Array = schedule.pop_front()
			_spawn(next[1], number, next[2] if next.size() > 2 else false)
		if schedule.is_empty():
			_arriving.erase(number)
			_active[number].arriving = false
			drift_arrived.emit(number)
			if number == drifts_started and auto_drift and _next_is_in_block():
				_auto_timer = auto_drift_delay
			_check_cleared(number)
	if _auto_timer >= 0.0:
		_auto_timer -= delta
		if _auto_timer < 0.0 and auto_drift and _next_is_in_block():
			_start_drift()


# --- Queries (for the HUD) ------------------------------------------------------------------------

# Resting = full refunds and time stands still until Start. Old name kept for existing callers.
func is_build_phase() -> bool:
	return resting and not run_state.is_over

func is_resting() -> bool:
	return is_build_phase()

func is_arriving() -> bool:
	return not _arriving.is_empty()

func has_next_drift() -> bool:
	return drifts_started < drifts.size()

func get_total_drifts() -> int:
	return drifts.size()

func get_block(number: int) -> int:
	return (maxi(number, 1) - 1) / drifts_per_block + 1

# The act (1-based) that drift `number` belongs to.
func get_act(number: int) -> int:
	return (maxi(number, 1) - 1) / drifts_per_act + 1

func get_act_name(act: int) -> String:
	return act_names[act - 1] if act - 1 < act_names.size() else "Act %d" % act

func is_boss_drift(number: int) -> bool:
	return number % drifts_per_act == 0

# Rest bonus after block `block` (20 + 10 × block), before the perfect bonus and Dreams.
func get_rest_bonus(block: int) -> int:
	return rest_bonus_base + rest_bonus_per_block * block

# Seconds until the next drift starts by itself (-1 = it won't: rest ahead, Auto-drift off, …).
func get_auto_countdown() -> float:
	return _auto_timer if _auto_timer >= 0.0 else -1.0

# Whether the Start / Next button does anything right now.
func can_start_next_drift() -> bool:
	if run_state.is_over or awaiting_family_pick or not has_next_drift():
		return false
	if resting:
		return true
	return _next_is_in_block()

# Dew for starting the next drift right now: +1 per `call_early_seconds_per_dew` seconds of the
# current drift's arrival that are skipped, capped. 0 when resting or when it has finished arriving.
func get_call_early_bonus() -> int:
	if resting or not can_start_next_drift() or not _arriving.has(drifts_started):
		return 0
	var arrival: Dictionary = _arriving[drifts_started]
	var schedule: Array = arrival.schedule
	if schedule.is_empty():
		return 0
	var skipped: float = schedule[-1][0] - arrival.clock
	var bonus := mini(int(skipped / call_early_seconds_per_dew), call_early_cap)
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	return dreams.get_call_early_bonus(int(skipped / call_early_seconds_per_dew), call_early_cap) if dreams else bonus  # Call of the Wild


# --- Actions --------------------------------------------------------------------------------------

# The Start / Next button: ends a rest, or starts the next drift of the block early.
func start_next_drift() -> bool:
	if not can_start_next_drift():
		return false
	if resting:
		return start_next_block()
	var bonus := get_call_early_bonus()
	if bonus > 0:
		run_state.add_dew(bonus)
	_start_drift()
	return true

# Leaves the rest and starts the next drift.
func start_next_block() -> bool:
	if not resting or not can_start_next_drift():
		return false
	resting = false
	build_phase_changed.emit(false)
	rest_ended.emit(get_block(drifts_started + 1))
	_start_drift()
	return true

# The family-pick screen is done (a family was chosen).
func family_picked() -> void:
	if not awaiting_family_pick:
		return
	awaiting_family_pick = false
	if drifts_started == 1:
		return  # The quick rest after drift 1: the player presses Start when ready
	_begin_rest()

func set_auto_drift(value: bool) -> void:
	auto_drift = value
	if not value:
		_auto_timer = -1.0
	elif not resting and not is_arriving() and _next_is_in_block() and drifts_started > 0:
		_auto_timer = auto_drift_delay

func _start_drift() -> void:
	_auto_timer = -1.0
	drifts_started += 1
	var number := drifts_started
	_active[number] = {"remaining": 0, "arriving": true, "leaked": false}
	var mods := get_schedule_modifiers(number)
	_arriving[number] = {
		"schedule": drifts[number - 1].get_schedule(mods.get("count", 1.0), mods.get("flyers", 1.0),
			mods.get("spacing", 1.0), get_extra_nightmares(number)),
		"clock": 0.0,
	}
	add_guaranteed_elite(_arriving[number].schedule, number)
	_add_blight_elites(_arriving[number].schedule)
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	if omens:
		omens.shape_schedule(_arriving[number].schedule, number)  # Elder Night, Hollow Wind
	drift_started.emit(number)
	# Creatures due at t=0 arrive right away, not a frame later.
	_process(0.0)

# The next drift belongs to the current block (no rest in between).
func _next_is_in_block() -> bool:
	return has_next_drift() and drifts_started % drifts_per_block != 0 and drifts_started != 1

# The difficulty's nightmare count multiplier for drift `number` (1.0 for the intro drifts).
func get_extra_nightmares(number: int) -> float:
	return extra_nightmares if number >= extra_nightmares_from else 1.0

# Health multiplier for `data` in drift `number` (get_growth; bosses fixed at ×1.5 their; ×1.4 in acts 3–4;
# base). Dreams / Omens multiply on top (hook: see get_health_multiplier).
# Act 2's health multiplier for drift `number`: 1.0 through drift 26, rising evenly to ×1.35 at drift 40.
func get_early_multiplier(number: int) -> float:
	var t := clampf(float(number - early_ramp_from) / maxf(early_ramp_to - early_ramp_from, 1), 0.0, 1.0)
	return lerpf(1.0, early_acts_health_multiplier, t)

func get_health_scale(data: EnemyData, number: int) -> float:
	var scale := boss_health_multiplier if data.is_boss else get_growth(number)
	if get_act(number) >= late_acts_from_act:
		scale *= late_acts_health_multiplier
	else:
		scale *= get_early_multiplier(number)
	return scale * get_health_multiplier(data, number)

# The per-drift health growth for drift `number`, compounding: ×1.045 per drift to 25, ×1.055 for
# 26–50, ×1.045 from 51.
func get_growth(number: int) -> float:
	var early := mini(number, late_growth_from - 1) - 1
	var late := clampi(number, late_growth_from - 1, endgame_growth_from - 1) - (late_growth_from - 1)
	var endgame := maxi(number - (endgame_growth_from - 1), 0)
	return pow(health_growth_per_drift, early) * pow(late_health_growth_per_drift, late) \
		* pow(endgame_health_growth_per_drift, endgame)

# Dreams / Omens: extra health multiplier for creatures of drift `number` (Wild Growth: all
# creatures; Omens: not bosses).
func get_health_multiplier(data: EnemyData, number: int) -> float:
	var multiplier := blight_boss_health_multiplier if data.is_boss else blight_health_multiplier
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if dreams:
		multiplier *= dreams.get_creature_health_multiplier()
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	if omens and not data.is_boss:
		multiplier *= omens.get_multiplier(number, "health_multiplier")
	return multiplier

# Omens: {"count", "flyers", "spacing"} multipliers for drift `number`'s schedule.
func get_schedule_modifiers(number: int) -> Dictionary:
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	return omens.get_schedule_modifiers(number) if omens else {}

# Per-creature modifiers (see Enemy.modifiers) for drift `number`: the Omen's (bosses ignore
# Omens), times Dreams that change every nightmare (Burn Back the Dead Wood: speed).
func get_spawn_modifiers(data: EnemyData, number: int) -> Dictionary:
	var modifiers := {}
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	if omens and not data.is_boss:
		modifiers = omens.get_spawn_modifiers(number)
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if dreams and dreams.get_creature_speed_multiplier() != 1.0:
		modifiers["speed"] = modifiers.get("speed", 1.0) * dreams.get_creature_speed_multiplier()
	if blight_speed_multiplier != 1.0:
		modifiers["speed"] = modifiers.get("speed", 1.0) * blight_speed_multiplier
	return modifiers

# Blight Level 5: `blight_elites_per_drift` random non-boss arrivals become Deeply Blighted.
# From drift 26, a drift that lists no elites gets one (two from drift 76): each time a random
# non-boss kind in it (boss drifts: from the escort), and one of that kind becomes Deeply Blighted.
func add_guaranteed_elite(schedule: Array, number: int) -> void:
	if number < guaranteed_elite_from or schedule.any(func(a: Array) -> bool: return a.size() > 2 and a[2]):
		return
	for n in (2 if number >= second_elite_from else 1):
		var by_kind := {}  # EnemyData -> [schedule index, …] not elite yet
		for i in schedule.size():
			if not schedule[i][1].is_boss and not (schedule[i].size() > 2 and schedule[i][2]):
				by_kind.get_or_add(schedule[i][1], []).append(i)
		if by_kind.is_empty():
			return
		var arrivals: Array = by_kind[by_kind.keys().pick_random()]
		var index: int = arrivals.pick_random()
		if schedule[index].size() > 2:
			schedule[index][2] = true
		else:
			schedule[index].append(true)

func _add_blight_elites(schedule: Array) -> void:
	if blight_elites_per_drift <= 0:
		return
	var candidates: Array[int] = []
	for i in schedule.size():
		if not schedule[i][1].is_boss and not (schedule[i].size() > 2 and schedule[i][2]):
			candidates.append(i)
	candidates.shuffle()
	for i in candidates.slice(0, blight_elites_per_drift):
		if schedule[i].size() > 2:
			schedule[i][2] = true
		else:
			schedule[i].append(true)

func _spawn(data: EnemyData, number: int, elite: bool = false) -> void:
	var enemy: Node2D = spawner.spawn_enemy(data, get_health_scale(data, number),
		get_spawn_modifiers(data, number), elite)
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

func _on_enemy_cleansed(enemy: Node2D) -> void:
	if enemy.enemy_data.is_boss and _drift_of.has(enemy):
		bosses_cleansed += 1
	_resolve(enemy, false)

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
		_block_leaked = true
	_check_cleared(number)

func _check_cleared(number: int) -> void:
	var drift: Dictionary = _active.get(number, {})
	if drift.is_empty() or drift.arriving or drift.remaining > 0 or run_state.is_over:
		return
	_active.erase(number)
	drifts_cleared += 1
	drift_cleared.emit(number, 0, not drift.leaked)
	if not _active.is_empty() or is_arriving():
		return
	# Field clear. Is a rest (or the end) due?
	if not has_next_drift() and drifts_started == drifts.size():
		_pay_rest_bonus()
		run_state.end_run(true)
	elif drifts_started == 1 and drifts_started == number:
		_request_family_pick(&"first")
	elif drifts_started % drifts_per_block == 0:
		if is_boss_drift(drifts_started):
			_request_family_pick(&"boss")
		else:
			_begin_rest()

func _request_family_pick(reason: StringName) -> void:
	resting = true
	awaiting_family_pick = true
	build_phase_changed.emit(true)
	family_pick_requested.emit(reason)

func _begin_rest() -> void:
	resting = true
	blocks_rested += 1
	var block := get_block(drifts_started)
	var boss := is_boss_drift(drifts_started)
	var paid := _pay_rest_bonus()
	if boss:
		var before := run_state.leaves
		run_state.regrow_leaves(act_break_leaves)
		act_started.emit(get_act(drifts_started + 1), run_state.leaves - before)
	build_phase_changed.emit(true)
	rest_started.emit(block, boss, paid[0], paid[1])

# Pays the rest bonus for the block that just ended. Returns [dew paid, perfect].
func _pay_rest_bonus() -> Array:
	var block := get_block(drifts_started)
	var perfect := not _block_leaked
	var bonus := roundi(get_rest_bonus(block) * blight_rest_bonus_multiplier * rest_bonus_perk_multiplier) \
		+ (perfect_block_bonus if perfect else 0)
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if dreams:
		bonus += dreams.get_dew_per_clear()  # Morning Dew
		bonus += dreams.get_rest_bonus_add()  # Borrowed Dew (negative)
	bonus = maxi(bonus, 0)
	run_state.add_dew(bonus)
	_block_leaked = false
	return [bonus, perfect]

func _on_run_ended(_won: bool) -> void:
	_arriving.clear()
	_auto_timer = -1.0
	set_process(false)
