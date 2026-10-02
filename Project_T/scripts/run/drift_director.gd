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
@export var random_drifts := true  # Roll the drifts from the run's seed (DriftRoller); false = the hand-made ones
# Boss pools (enemy_design.md): draw each act's boss from resource/boss/act_N/ (BossPool). Only when
# the drifts are the game's own (loaded from DEMO_DRIFTS_DIR), never a test's hand-set ones.
@export var boss_pools := true
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
@export var guaranteed_elite_from: int = 31  # run_design.md f2eb4f8: was 26 (the drift 28–29 death cluster)
@export var second_elite_from: int = 76  # Two Deeply Blighted per drift from here
# Block finales (spire_difficulty.md, Slay the Spire's elite fights): the last drift of every block
# (not a boss drift) gets this many guaranteed Deeply Blighted, by the drift they start from
# ({start drift: count}; the highest start at or below the drift wins). Replaces the rule above there.
@export var block_finale_elites := {10: 1, 15: 2, 30: 3, 60: 4}  # Drift 10 eased (it was the run's hardest point at 2)
# Elites alone didn't make a spike (Balancing: +2 elites cost the bot 0.35 leaves), so every non-boss nightmare on a
# block finale from `block_finale_health_from` has this much more health, on top of everything else.
@export var block_finale_health_multiplier: float = 1.4
@export var block_finale_health_from: int = 10

# The guaranteed elites for drift `number` if it's a block finale (0 before the first start), else -1.
func get_block_finale_elites(number: int) -> int:
	if number % drifts_per_block != 0 or number % drifts_per_act == 0:
		return -1  # Not a block's last drift, or a boss drift
	var count := 0
	var best := -1
	for start in block_finale_elites:
		if int(start) <= number and int(start) > best:
			best = int(start)
			count = int(block_finale_elites[start])
	return count
@export var boss_health_multiplier: float = 1.5  # On the bosses' base health
@export var mid_boss_health_multiplier: float = 1.75  # Acts 2-3 bosses instead ("Human runs 7-9": 0 of 3 killed the act 2 boss once act 2 ended at x4.5; was 2.25, from "Human run 3": the Lamplighter died in 29 s); act 1 and the Oak keep theirs
@export var act1_boss_health_multiplier: float = 1.75  # Act 1's boss (drift 25) instead (boss stays and drains: ×1.75 = Dreams 11/15, skip 5/15 vs the Stag)
# Acts 3–4 (run_design.md "Act 3 probe", interim): a flat health multiplier for every nightmare from
# `late_acts_from_act`, bosses included, on top of the growth / boss multiplier.
@export var late_acts_health_multiplier: float = 6.0  # Acts 3–4, bosses included ("Human run 7"; was 4.8, 4.0, 3.5, 1.6)
@export var act4_health_multiplier: float = 1.2  # Spire: act 4 on top of the late multiplier, bosses and the Oak too
@export var final_boss_late_multiplier: float = 3.0  # …except the Hollow Oak at drift 100 ("Human run 2": it died in 17 s at 1.6)
@export var late_acts_from_act: int = 3
# Acts 1–2 (run_design.md 72860af, balance batches): act 1 is x1.0 through `act1_ramp_from`, rising
# evenly to `act1_health_multiplier` at `act1_ramp_to` and holding to the act's end; act 2 holds that
# for its first drifts (a breather while the first finals arrive) until `early_ramp_from`, then rises
# evenly to `early_acts_health_multiplier` at `early_ramp_to`, held until acts 3–4 take over (no stacking).
@export var act1_health_multiplier: float = 1.15  # Spire: main's peak again, paying for the finales' x1.4 (was 1.25, 1.35)
@export var act1_ramp_from: int = 3  # Spire: the ramp starts at drift 3 (was 9)
@export var act1_ramp_to: int = 20
@export var early_acts_health_multiplier: float = 4.5  # Act 2 ends at this ("Human run 7"; was 3.6, 3.0, 2.5, 1.55)
@export var act2_start_health_multiplier: float = 2.0  # …starting from this at act 2's first drift (Spire: one straight line to 4.5 @45; was 1.7, 2.0, 1.6, 1.3)
@export var early_ramp_from: int = 26
@export var early_ramp_to: int = 45
@export var act2_steep_from: int = 37  # "Human run 2": drifts 26-37 keep the old ramp (to act2_steep_value), the rest of the rise comes after
@export var act2_steep_value: float = 3.45  # Drift 37: on the straight line 2.0 @26 → 4.5 @45, so no knee (Spire, Balancing Discussion; was 3.3, 2.9, 2.3, 1.995)
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
# The Dew pot (run_design.md "The Dew pot", 2026-10-01): each drift has a fixed Dew pot, split across the
# nightmares it spawns by weight (EnemyData.dew_reward, Deeply Blighted ×3; a boss drift's boss takes half).
# Added nightmares (Omens, extra_nightmares, splits, followers) share it; a leak loses its share. Per act:
# the first → last non-boss drift (linear), then its boss drift.
@export var dew_pot_acts: Array[Vector2] = [Vector2(30, 115), Vector2(103.5, 121.5), Vector2(121.5, 130.5), Vector2(126, 130.5)]  # Spire: acts 2-4 x0.9
@export var dew_pot_bosses: Array[float] = [220.0, 243.0, 288.0, 0.0]  # Drift 100 pays nothing: it's the win (Spire: acts 2-3 x0.9)
const POT_ELITE_WEIGHT := 3.0
const POT_BOSS_SHARE := 0.5

# Blight Levels (meta_design.md), set by MetaRun at run start. 1.0 / 0 = no change.
var blight_health_multiplier := 1.0  # Nightmares (not bosses)
var blight_boss_health_multiplier := 1.0
var blight_speed_multiplier := 1.0
var blight_rest_bonus_multiplier := 1.0  # The block's rest bonus (before perfect / Dreams)
var rest_bonus_perk_multiplier := 1.0  # Rested Roots (Grove perk), same part of the rest bonus
var blight_elites_per_drift := 0  # Nightmares per drift made Deeply Blighted
var blight_dew_multiplier := 1.0  # A Blight Level's Dew cut: multiplies every drift's pot (none set yet)

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
# The boss drawn for each act (index 0 = act 1; BossPool), set once the run's seed is known.
var bosses: Array[BossData] = []
var preset_bosses: Array = []  # Boss ids a resumed run drew (RunSaver sets them before the draw)
var _own_drifts := false  # The drifts came from DEMO_DRIFTS_DIR (boss pools may replace boss drifts)

func _ready() -> void:
	if drifts.is_empty():
		drifts = load_demo_drifts()
		_own_drifts = true
	if boss_pools and _own_drifts:
		_draw_bosses.call_deferred()  # Before the roll: DriftRoller keeps boss drifts as they are
	if get_tree().current_scene == owner:  # The player's default (tests keep the export's)
		auto_drift = bool(HeartwoodMemory.get_settings().get("auto_drift", auto_drift))
	spawner.enemy_split.connect(_on_enemy_split)
	spawner.enemy_cleansed.connect(_on_enemy_cleansed)
	spawner.enemy_reached_goal.connect(_resolve.bind(true))
	if spawner.has_signal("boss_drained"):  # A boss at the Heartwood drains leaves: its drift and block leaked
		spawner.boss_drained.connect(_on_boss_drained)
	run_state.run_ended.connect(_on_run_ended)
	if random_drifts:
		_roll_drifts.call_deferred()

# Random drifts (run_design.md; Enemy Code's DriftRoller): every block but the first, the bosses and
# the intro drifts is rolled from the run's seed, all at once. Deferred so the seed is final
# (MapGenerator picks it in its _ready; RunSaver restores a saved one before that): the same run, or
# a resumed one, always meets the same drifts.
func _roll_drifts() -> void:
	var map := get_node_or_null("%MapGenerator")
	DriftRoller.roll_run(self, map.map_seed if map else 0)

# Boss pools: one boss per act, from the run's seed (deferred like the roll, so the seed is final).
func _draw_bosses() -> void:
	if not preset_bosses.is_empty():
		bosses = BossPool.from_ids(preset_bosses)
	else:
		var map := get_node_or_null("%MapGenerator")
		var playing := get_tree().current_scene == owner  # Tests meet the defaults unless BossPool.force_draw
		var real_game := playing and not MetaRun.is_dev_run()  # Dev runs draw but never read / write the profile
		var defaults := (not playing and not BossPool.force_draw) or (real_game and HeartwoodMemory.is_first_run())
		bosses = BossPool.draw(map.map_seed if map else 0, defaults, ResultsScreen.is_demo(),
			BossPool.last_from_profile() if real_game else [])
	BossPool.apply(self, bosses)

# The boss drawn for `act` (null without boss pools or past the run's acts).
func get_drawn_boss(act: int) -> BossData:
	return bosses[act - 1] if act >= 1 and act <= bosses.size() else null

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
		# A due arrival waits in the start mist while the field is full (EnemyContainer.max_field); the
		# order holds, the drift stays arriving, and it walks in as soon as there's room.
		while not schedule.is_empty() and schedule[0][0] <= arrival.clock and spawner.has_room():
			var next: Array = schedule.pop_front()
			var shares: Array = arrival.get("shares", [])
			var share: float = shares.pop_front() if not shares.is_empty() else -1.0
			_spawn(next[1], number, next[2] if next.size() > 2 else false, share)
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

# Nightmares due to arrive but held in the start mist because the field is full (EnemyContainer
# max_field; platforms.md "Calling drifts early stacks them"): for the "+N" on the mist.
func get_waiting_count() -> int:
	var waiting := 0
	for number in _arriving:
		var arrival: Dictionary = _arriving[number]
		for entry in arrival.schedule:
			if entry[0] > arrival.clock:
				break  # The schedule is in time order: the rest aren't due yet
			waiting += 1
	return waiting

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
	if pending_choice() != &"":
		return false  # A choice open or minimised (peeking at the map) holds the next drift
	if resting:
		return true
	if is_mist_full():
		return false  # Calling early stacks up to the field cap, not past it for free Dew (platforms.md)
	return _next_is_in_block()

# Nightmares are waiting in the start mist for room on the field (EnemyContainer.max_field): calling
# the next drift early is refused until they're in (the Call early button greys: "The mist is full").
func is_mist_full() -> bool:
	return get_waiting_count() > 0

# The choice that must be made before the next drift (screens_ui.md "Choice screens", user bug: "I can
# hide the Dream choice and start the wave"): &"family" (the family pick), &"dream" (an offer shown or
# queued), &"omen" (an Omen offer shown or waiting behind the Dream), or &"" when none. Minimising a
# choice to peek at the map doesn't resolve it. The boss dossier and Remember never block.
func pending_choice() -> StringName:
	if awaiting_family_pick:
		return &"family"
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) if is_inside_tree() else null
	if dreams != null and (dreams.is_offering() or dreams.has_pending_offer()):
		return &"dream"
	var gifts := get_tree().get_first_node_in_group(&"heartwood_gifts") if is_inside_tree() else null
	if gifts != null and gifts.is_offering():
		return &"gift"  # Heartwood's Gifts (Spire): after the Dream and the family pick, before the Omen
	var omens := get_tree().get_first_node_in_group(&"omens") if is_inside_tree() else null
	if omens != null and (omens.is_offering() or omens.has_pending_offer()):
		return &"omen"
	return &""

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
	_called_early = is_arriving()  # Call of the Wild: a drift called early has its pot +10%
	if _called_early:  # Run history (balancing: "the user calls most drifts early")
		early_calls += 1
		call_early_dew += bonus
	_start_drift()
	_called_early = false
	return true

# Leaves the rest and starts the next drift.
func start_next_block() -> bool:
	if not resting or not can_start_next_drift():
		return false
	resting = false
	if drifts_started == 0 or get_block(drifts_started + 1) != get_block(drifts_started):
		block_pot = 0.0  # A new block's pot (the quick rest after drift 1 stays in block 1)
		run_state.pot_earned_block = 0.0
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
	_arriving[number].shares = pot_shares(_arriving[number].schedule, number, _called_early)
	drift_started.emit(number)
	# Creatures due at t=0 arrive right away, not a frame later.
	_process(0.0)

# The next drift belongs to the current block (no rest in between).
func _next_is_in_block() -> bool:
	return has_next_drift() and drifts_started % drifts_per_block != 0 and drifts_started != 1

# The difficulty's nightmare count multiplier for drift `number` (1.0 for the intro drifts).
func get_extra_nightmares(number: int) -> float:
	return extra_nightmares if number >= extra_nightmares_from else 1.0

# Acts 1–2's health multiplier for drift `number`: ×1.0 to drift 9, rising to ×1.15 at 20 (held to 30),
# then rising to ×1.55 at 45 (held to 50).
func get_early_multiplier(number: int) -> float:
	var act1 := clampf(float(number - act1_ramp_from) / maxf(act1_ramp_to - act1_ramp_from, 1), 0.0, 1.0)
	if get_act(number) >= 2:  # Act 2: from act2_start at its first drift up to early_acts at early_ramp_to, then held
		if number <= act2_steep_from:  # The old, gentle ramp to drift 37
			var early := clampf(float(number - early_ramp_from) / maxf(act2_steep_from - early_ramp_from, 1), 0.0, 1.0)
			return lerpf(act2_start_health_multiplier, act2_steep_value, early)
		var steep := clampf(float(number - act2_steep_from) / maxf(early_ramp_to - act2_steep_from, 1), 0.0, 1.0)
		return lerpf(act2_steep_value, early_acts_health_multiplier, steep)  # Then most of the rise to drift 45
	return lerpf(1.0, act1_health_multiplier, act1)

# Health multiplier for `data` in drift `number`: get_growth (bosses: ×1.5 their base), × the act 2
# ramp, or ×1.6 in acts 3–4. Dreams / Omens multiply on top (hook: see get_health_multiplier).
func get_health_scale(data: EnemyData, number: int) -> float:
	var act := get_act(number)
	var boss := act1_boss_health_multiplier if act == 1 else (mid_boss_health_multiplier if act == 2 or act == 3 else boss_health_multiplier)
	var scale := boss if data.is_boss else get_growth(number)
	if get_act(number) >= late_acts_from_act:
		var final_boss := data.is_boss and number >= drifts_per_act * 4
		scale *= final_boss_late_multiplier if final_boss else late_acts_health_multiplier
		if act >= 4:
			scale *= act4_health_multiplier  # Spire: act 4 harder still, bosses and the Oak included
	elif not (data.is_boss and get_act(number) == 1):  # Act 1's boss keeps its own multiplier (its escort takes the ramp)
		scale *= get_early_multiplier(number)
	if not data.is_boss and number >= block_finale_health_from and get_block_finale_elites(number) >= 0:
		scale *= block_finale_health_multiplier  # A block finale (spire_difficulty.md)
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
	var mods: Dictionary = omens.get_schedule_modifiers(number).duplicate() if omens else {}
	var gifts := get_tree().get_first_node_in_group(&"heartwood_gifts")  # Thick Mist (Heartwood's Gifts): arrivals further apart
	if gifts != null and gifts.get_spacing_multiplier(number) != 1.0:
		mods["spacing"] = float(mods.get("spacing", 1.0)) * gifts.get_spacing_multiplier(number)
	return mods

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
# From drift 31, a drift that lists no elites gets one (two from drift 76): each time a random
# non-boss kind in it (boss drifts: from the escort), and one of that kind becomes Deeply Blighted.
func add_guaranteed_elite(schedule: Array, number: int) -> void:
	var listed := schedule.filter(func(a: Array) -> bool: return a.size() > 2 and a[2]).size()
	var wanted := 0
	var finale := get_block_finale_elites(number)
	if finale >= 0:  # A block's last drift (spire_difficulty.md "block finales"): its own count
		wanted = finale - listed
	elif number >= guaranteed_elite_from and listed == 0:
		wanted = 2 if number >= second_elite_from else 1
	for n in wanted:
		var by_kind := {}  # EnemyData -> [schedule index, …] not elite yet
		for i in schedule.size():
			# Never a kind on its intro drift: that drift teaches it (human run 5: an elite Phantom on drift 31)
			if not schedule[i][1].is_boss and not (schedule[i].size() > 2 and schedule[i][2]) \
					and schedule[i][1].intro_drift != number:
				by_kind.get_or_add(schedule[i][1], []).append(i)
		if by_kind.is_empty():
			return  # Only the new kind (or bosses) here: no guaranteed elite this drift
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

func _spawn(data: EnemyData, number: int, elite: bool = false, share: float = -1.0) -> void:
	var enemy: Node2D = spawner.spawn_enemy(data, get_health_scale(data, number),
		get_spawn_modifiers(data, number), elite)
	if enemy == null:
		return  # No route (shouldn't happen: building never fully blocks the path)
	_drift_of[enemy] = number
	_active[number].remaining += 1
	if share >= 0.0 and enemy.has_method("set_dew_share"):
		enemy.set_dew_share(share)  # Its followers take their part of it (Enemy.FOLLOWER_DEW_SHARE)


# --- The Dew pot --------------------------------------------------------------------------------------

var _called_early := false  # Set while start_next_drift starts a drift early
var early_calls := 0  # Drifts started while the previous one was still arriving, this run
var call_early_dew := 0  # Dew paid by calling early, this run

# Whether the drift being started right now was called early (drift_started's listeners ask).
func is_calling_early() -> bool:
	return _called_early
var block_pot := 0.0  # The pots of this block's drifts (rest report: "Dew this block: 840 of 900")

# Drift `number`'s base pot from the table (before Dreams / Omens).
func get_dew_pot(number: int) -> float:
	var act := get_act(number)
	if is_boss_drift(number):
		return dew_pot_bosses[clampi(act - 1, 0, dew_pot_bosses.size() - 1)]
	var row: Vector2 = dew_pot_acts[clampi(act - 1, 0, dew_pot_acts.size() - 1)]
	var first := (act - 1) * drifts_per_act + 1
	var last := act * drifts_per_act - 1
	return lerpf(row.x, row.y, clampf(float(number - first) / maxf(last - first, 1), 0.0, 1.0))

# What multiplies the pot: Dream cards (Morning Dew; Call of the Wild when called early) and Omens
# (Bountiful Night, Blood Moon, Dry Spell), Rich Dew (Grove dew_gain) and a Blight Dew cut. Catchers, call-early
# Dew and rest bonuses come on top instead.
# `with_omen` false: everything but the active Omen's factor (Dry Spell pays back what the block would have held).
# Sidegrade perks (MetaRun, Spire experiment): Morning Stores' cost, drifts 1–5 pay less of their pot.
var early_pot_multiplier := 1.0
const EARLY_POT_DRIFTS := 5

func get_dew_pot_multiplier(number: int, called_early: bool = false, with_omen: bool = true) -> float:
	var multiplier := 1.0
	if number <= EARLY_POT_DRIFTS:
		multiplier *= maxf(early_pot_multiplier, 0.0)
	if run_state != null:  # Rich Dew (Grove dew_gain, +5% a level): the pot, not each nightmare (run_design.md, fixed)
		multiplier *= 1.0 + run_state.dew_gain_bonus
	multiplier *= blight_dew_multiplier
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) if is_inside_tree() else null
	if dreams != null and dreams.has_method("get_dew_pot_multiplier"):
		multiplier *= dreams.get_dew_pot_multiplier(number, called_early)
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) if is_inside_tree() else null
	if with_omen and omens != null and omens.has_method("get_dew_pot_multiplier"):
		multiplier *= omens.get_dew_pot_multiplier(number)
	return multiplier

# The pot drift `number` would pay if started now (the DriftPanel shows it before it starts).
func get_effective_pot(number: int, called_early: bool = false) -> float:
	return get_dew_pot(number) * get_dew_pot_multiplier(number, called_early)

# Each schedule entry's share of the pot, in schedule order: weight = dew_reward (Deeply Blighted ×3); a
# boss drift's bosses take POT_BOSS_SHARE between them, the escorts the rest. Adds the pot to the block's.
func pot_shares(schedule: Array, number: int, called_early: bool = false) -> Array:
	var pot := get_effective_pot(number, called_early)
	block_pot += pot
	var weights: Array[float] = []
	var boss_weight := 0.0
	var other_weight := 0.0
	for entry in schedule:
		var data: EnemyData = entry[1]
		var weight := maxf(float(data.dew_reward), 1.0) * (POT_ELITE_WEIGHT if entry.size() > 2 and entry[2] else 1.0)
		weights.append(weight)
		if data.is_boss:
			boss_weight += weight
		else:
			other_weight += weight
	var boss_pot := 0.0
	if boss_weight > 0.0:
		boss_pot = pot * (POT_BOSS_SHARE if other_weight > 0.0 else 1.0)
	var other_pot := pot - boss_pot
	var shares := []
	for i in schedule.size():
		var is_boss: bool = schedule[i][1].is_boss
		var total := boss_weight if is_boss else other_weight
		shares.append((boss_pot if is_boss else other_pot) * weights[i] / total if total > 0.0 else 0.0)
	return shares


# --- Bookkeeping ----------------------------------------------------------------------------------

func _on_enemy_split(parent: Node2D, child: Node2D) -> void:
	if not _drift_of.has(parent):
		return
	var number: int = _drift_of[parent]
	_drift_of[child] = number
	_active[number].remaining += 1

# The drift that spawned `enemy` (split children and followers: their parent's), 0 if none.
func drift_of(enemy: Node) -> int:
	return int(_drift_of.get(enemy, 0))

func _on_enemy_cleansed(enemy: Node2D) -> void:
	if enemy.enemy_data.is_boss and _drift_of.has(enemy) and not enemy.is_echo:  # Echoes (Remembering Oak) aren't bosses
		bosses_cleansed += 1
	_resolve(enemy, false)

# A boss that got through stays at the Heartwood, draining leaves (enemy_design.md "A boss that
# reaches the Heartwood stays"): it never reaches the goal, so its drift and block are marked here.
func _on_boss_drained(enemy: Node2D, _leaves: int) -> void:
	var number := int(_drift_of.get(enemy, 0))
	if _active.has(number):
		_active[number].leaked = true
	_block_leaked = true

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
	if not bosses.is_empty() and get_tree().current_scene == owner and not MetaRun.is_dev_run():
		BossPool.remember(bosses)  # The next run weighs against these
	_arriving.clear()
	_auto_timer = -1.0
	set_process(false)
