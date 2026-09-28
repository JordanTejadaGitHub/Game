extends Node
class_name OmenDirector

# Omens (documentation/run_design.md): at every rest from drift `first_rest_drift` on, after the
# Dream, the wind brings `omens_per_offer` Omens. Pick one to twist the next block (5 drifts) for a
# reward, or keep Clear Skies (nothing changes). The reward is paid at the rest after that block
# (or when the run is won during it), as long as the Heartwood is still standing.
# DriftDirector asks this node for the active Omen's multipliers; bosses ignore them.

const GROUP := &"omens"
const OMEN_DIR := "res://resource/omen/"
const ACT_REWARD_SCALE := [1.0, 1.5, 2.0, 2.5]  # Dew and Seed rewards, by act

# The Omens for block `block` (drifts first..last) are ready; the Omen screen pauses and shows them.
signal offer_ready(omens: Array[OmenData], block: int)
signal offer_closed
signal omen_started(omen: OmenData, first_drift: int, last_drift: int)
# `summary`: what the reward gave, e.g. "+60 Dew, regrow 2 leaves".
signal omen_rewarded(omen: OmenData, summary: String)

@export var pool: Array[OmenData] = []  # Empty = every Omen in res://resource/omen/
@export var first_rest_drift: int = 10
@export var omens_per_offer: int = 2

var active: OmenData = null
var active_block := 0  # The block `active` twists
var current_offer: Array[OmenData] = []
var current_offer_block := 0

var _offer_waiting := false  # An offer is ready but waits for the Dream screen to close
var _rng := RandomNumberGenerator.new()

@onready var drift_director: DriftDirector = %DriftDirector
@onready var run_state: RunState = %RunState
@onready var dream_state: DreamState = %DreamState

func _ready() -> void:
	add_to_group(GROUP)
	_rng.randomize()
	if pool.is_empty():
		pool = load_pool()
	drift_director.rest_started.connect(_on_rest_started)
	dream_state.offer_closed.connect(_try_show.call_deferred)
	run_state.run_ended.connect(_on_run_ended)

static func load_pool() -> Array[OmenData]:
	var omens: Array[OmenData] = []
	for file in ResourceLoader.list_directory(OMEN_DIR):
		if file.ends_with(".tres") or file.ends_with(".res"):
			var omen := load(OMEN_DIR + file) as OmenData
			if omen != null:
				omens.append(omen)
	return omens


# --- Queries (DriftDirector, UI) -------------------------------------------------------------------

func is_offering() -> bool:
	return not current_offer.is_empty()

# First and last drift of block `block`.
func get_block_range(block: int) -> Vector2i:
	var per_block := drift_director.drifts_per_block
	return Vector2i((block - 1) * per_block + 1, mini(block * per_block, drift_director.get_total_drifts()))

func is_active_for(drift_number: int) -> bool:
	return active != null and drift_director.get_block(drift_number) == active_block

# One of OmenData's next-block multipliers (by property name) for drift `drift_number`.
func get_multiplier(drift_number: int, property: String) -> float:
	return float(active.get(property)) if is_active_for(drift_number) else 1.0

func get_schedule_modifiers(drift_number: int) -> Dictionary:
	if not is_active_for(drift_number):
		return {}
	return {"count": active.count_multiplier, "flyers": active.flyer_count_multiplier,
		"spacing": active.arrival_spacing_multiplier}

# Per-creature multipliers (see Enemy.modifiers). Callers leave bosses out.
func get_spawn_modifiers(drift_number: int) -> Dictionary:
	if not is_active_for(drift_number):
		return {}
	return {"speed": active.speed_multiplier, "coat": active.coat_multiplier,
		"dew": active.creature_dew_multiplier, "status_duration": active.status_duration_multiplier}

# The reward line for `omen` when paid in `act`, e.g. "+60 Dew · next Dream offers 4 cards".
# `rest_bonus` >= 0: the rest bonus it multiplies is known, so show the extra Dew instead of "×2".
func describe_reward(omen: OmenData, act: int, rest_bonus: int = -1) -> String:
	var parts: Array[String] = []
	var scale := _act_scale(act)
	if omen.reward_dew > 0:
		parts.append("+%d Dew" % roundi(omen.reward_dew * scale))
	if omen.reward_seeds > 0:
		parts.append("+%d Seeds" % roundi(omen.reward_seeds * scale))
	if omen.reward_leaves > 0:
		parts.append("regrow %d leaves" % omen.reward_leaves)
	if omen.reward_max_leaves > 0:
		parts.append("+%d max leaf" % omen.reward_max_leaves)
	if omen.reward_rare_dreams > 0:
		parts.append("next Dream: one card is Rare+")
	if omen.reward_extra_dream_cards > 0:
		parts.append("next Dream offers %d cards" % (dream_state.cards_per_offer + omen.reward_extra_dream_cards))
	if omen.reward_rest_bonus_multiplier > 1.0:
		if rest_bonus >= 0:
			parts.append("rest bonus +%d Dew" % _extra_rest_bonus(omen, rest_bonus))
		else:
			parts.append("rest bonus ×%s" % str(omen.reward_rest_bonus_multiplier).trim_suffix(".0"))
	return " · ".join(parts)

func _extra_rest_bonus(omen: OmenData, rest_bonus: int) -> int:
	return roundi(rest_bonus * (omen.reward_rest_bonus_multiplier - 1.0))


# --- Offers ----------------------------------------------------------------------------------------

# The Omens offered for block `block`: `omens_per_offer` random ones that make sense there.
func make_offer(block: int) -> Array[OmenData]:
	var drifts := get_block_range(block)
	var eligible: Array[OmenData] = []
	for omen in pool:
		if omen.min_drift > drifts.x:
			continue
		if omen.requires_flyers and not _block_has_flyers(drifts):
			continue
		eligible.append(omen)
	# Shuffle with our own RNG so a resumed run offers the same Omens.
	for i in range(eligible.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap := eligible[i]
		eligible[i] = eligible[j]
		eligible[j] = swap
	return eligible.slice(0, omens_per_offer)

# Picks `omen` for the offered block; null = Clear Skies.
func choose(omen: OmenData) -> void:
	if not is_offering() or (omen != null and not current_offer.has(omen)):
		return
	if omen != null:
		active = omen
		active_block = current_offer_block
		var drifts := get_block_range(active_block)
		omen_started.emit(omen, drifts.x, drifts.y)
	current_offer = []
	offer_closed.emit()

func _on_rest_started(block: int, _is_boss_rest: bool, bonus: int, _perfect: bool) -> void:
	# Pay first, so "next Dream" rewards count for this rest's Dream (its offer is built deferred).
	if active != null and active_block == block:
		_pay_reward(bonus)
	if drift_director.drifts_started < first_rest_drift or not drift_director.has_next_drift() or run_state.is_over:
		return
	var offer := make_offer(block + 1)
	if offer.is_empty():
		return
	current_offer = offer
	current_offer_block = block + 1
	_offer_waiting = true
	_try_show.call_deferred()

# The Omen screen comes after the Dream.
func _try_show() -> void:
	if not _offer_waiting or dream_state.is_offering() or dream_state.has_pending_offer():
		return
	_offer_waiting = false
	offer_ready.emit(current_offer, current_offer_block)

func _pay_reward(rest_bonus: int) -> void:
	var omen := active
	active = null
	if run_state.is_over and not run_state.won:
		return
	var act := drift_director.get_act(drift_director.drifts_started)
	var scale := _act_scale(act)
	var dew := roundi(omen.reward_dew * scale) + _extra_rest_bonus(omen, rest_bonus)
	run_state.add_dew(dew)
	run_state.omen_seeds += roundi(omen.reward_seeds * scale)
	if omen.reward_max_leaves > 0:
		run_state.max_leaves += omen.reward_max_leaves
	if omen.reward_leaves > 0 or omen.reward_max_leaves > 0:
		run_state.regrow_leaves(omen.reward_leaves + omen.reward_max_leaves)
	dream_state.add_rare_dreams(omen.reward_rare_dreams)
	dream_state.add_extra_cards(omen.reward_extra_dream_cards)
	omen_rewarded.emit(omen, describe_reward(omen, act, rest_bonus))

# The run was won during an Omen's block: there's no rest after it, so pay now (Seeds still count).
func _on_run_ended(won: bool) -> void:
	current_offer = []
	_offer_waiting = false
	if won and active != null:
		_pay_reward(0)

func _act_scale(act: int) -> float:
	return ACT_REWARD_SCALE[clampi(act, 1, ACT_REWARD_SCALE.size()) - 1]

func _block_has_flyers(drifts: Vector2i) -> bool:
	for number in range(drifts.x, drifts.y + 1):
		if number - 1 >= drift_director.drifts.size():
			break
		for group in drift_director.drifts[number - 1].groups:
			for entry in group.entries:
				if entry.enemy != null and entry.enemy.trait_kind == EnemyData.Trait.FLYING:
					return true
	return false


# --- Save ------------------------------------------------------------------------------------------

func to_save() -> Dictionary:
	return {"active": active.id if active != null else "", "active_block": active_block,
		"rng_state": str(_rng.state)}

func load_save(data: Dictionary) -> void:
	active = null
	active_block = int(data.get("active_block", 0))
	var id: String = data.get("active", "")
	for omen in pool:
		if omen.id == id:
			active = omen
	if data.has("rng_state"):
		_rng.state = str(data.rng_state).to_int()
