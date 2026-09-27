extends Node
class_name DreamState

# Dreams (in-run upgrades, documentation/dream_design.md): which Wardens are unlocked this run,
# which cards were taken (stat cards stack), and the Dream offers after certain drifts.
# Wardens ask this node for their effective stats; the Dream screen shows `offer_ready` offers.

const GROUP := &"dream_state"
const DREAM_DIR := "res://resource/dream/"
# Rarity weights (Common, Uncommon, Rare, Legendary) by act.
const RARITY_WEIGHTS := [[65, 28, 7, 0], [50, 32, 15, 3], [38, 34, 22, 6]]
const COZY_CORNERS_BONUS := 0.15
const HEDGE_PER_WALLS := 5
const HEDGE_BONUS_PER := 0.01
const HEDGE_BONUS_MAX := 0.20
const SPORE_CASCADE_TARGETS := 2

signal unlocks_changed
signal card_taken(card: UpgradeData)
# A Dream is ready to be chosen (`cards` has up to 3). The Dream screen pauses and shows it.
signal offer_ready(cards: Array[UpgradeData], drift_number: int)
signal offer_closed

@export var pool: Array[UpgradeData] = []  # Empty = every card in res://resource/dream/
@export var starting_unlocks: Array[String] = ["sprout", "thornwall"]
@export var unlock_everything: bool = false  # Debug/tests: every Warden and evolution available
@export var dream_after_drifts: Array[int] = [1, 3, 5, 7, 9, 10, 12, 14]
@export var boss_dream_drifts: Array[int] = [5, 10]
# The first Dream always offers these (the base Wardens of the first-playable scope).
@export var first_dream_card_ids: Array[String] = ["dream_sporeling", "dream_firefly_jar", "dream_dewdrop"]
@export var cards_per_offer: int = 3
@export var skip_dew: int = 15  # "Let it pass"
@export var tag_weight: float = 2.0  # Cards tagged with a line you own are this much likelier
@export var pity_after: int = 3  # Dreams in a row without Rare+ before one is guaranteed

var unlocked := {}  # Warden id -> true
var stacks := {}  # Card id -> times taken
var dreams_seen := 0
var current_offer: Array[UpgradeData] = []
var current_offer_drift := 0

var _dreams_without_rare := 0
var _pending_drifts: Array[int] = []
var _bend_cells := {}  # Path cells where the route turns (Cozy Corners)
var _rng := RandomNumberGenerator.new()

@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var map_generator = %MapGenerator
@onready var tower_container: Node2D = %TowerContainer
@onready var spawner = %EnemyContainer

func _ready() -> void:
	add_to_group(GROUP)
	_rng.randomize()
	if pool.is_empty():
		pool = load_pool()
	for id in starting_unlocks:
		unlocked[id] = true
	drift_director.drift_cleared.connect(_on_drift_cleared)
	map_generator.path_changed.connect(_update_bends)
	spawner.enemy_cleansed.connect(_on_enemy_cleansed)
	_update_bends()

static func load_pool() -> Array[UpgradeData]:
	var cards: Array[UpgradeData] = []
	# list_directory also sees resources in exported builds (where files are remapped).
	for file in ResourceLoader.list_directory(DREAM_DIR):
		var path: String = DREAM_DIR + file
		if path.ends_with(".tres") or path.ends_with(".res"):
			var card := load(path) as UpgradeData
			if card != null:
				cards.append(card)
	return cards


# --- Unlocks and costs ------------------------------------------------------------------------------

func is_unlocked(warden_id: String) -> bool:
	return unlock_everything or unlocked.has(warden_id)

func has_card(card_id: String) -> bool:
	return stacks.get(card_id, 0) > 0

func card_stacks(card_id: String) -> int:
	return stacks.get(card_id, 0)

# Warden ids and card ids the player owns (for card prerequisites).
func owns(id: String) -> bool:
	return is_unlocked(id) or has_card(id)

# Wardens that can be planted from the tower bar right now.
func is_buildable(data: TowerData) -> bool:
	return data.buildable_directly and is_unlocked(data.get_id())

func get_build_cost(data: TowerData) -> int:
	var cost := data.cost
	for card in _taken_cards():
		if card.set_cost_warden == data.get_id():
			cost = mini(cost, card.set_cost)
	return cost

func get_evolve_cost(to: TowerData) -> int:
	var discount := 0.0
	for card in _taken_cards():
		discount += card.evolve_discount * stacks[card.id]
	return roundi(to.evolve_cost * maxf(1.0 - discount, 0.0))

# `data`'s evolutions this run: [[TowerData, available: bool], ...].
func get_evolutions(data: TowerData) -> Array:
	var result: Array = []
	for next in data.evolves_to:
		result.append([next, is_unlocked(next.get_id())])
	return result


# --- Stats for Wardens --------------------------------------------------------------------------------

func get_soothe_multiplier(tower: Tower) -> float:
	var bonus := _sum_stat(tower.tower_data, "soothe_bonus")
	if has_rule(&"cozy_corners") and is_beside_bend(tower.cell):
		bonus += COZY_CORNERS_BONUS
	if has_rule(&"hedge_maze"):
		bonus += minf(HEDGE_BONUS_PER * (count_walls() / HEDGE_PER_WALLS), HEDGE_BONUS_MAX)
	return 1.0 + bonus

func get_attack_speed_multiplier(data: TowerData) -> float:
	return 1.0 + _sum_stat(data, "attack_speed_bonus")

func get_range_bonus(data: TowerData) -> float:
	return _sum_stat(data, "range_bonus")

func get_splash_multiplier(data: TowerData) -> float:
	return 1.0 + _sum_stat(data, "splash_bonus")

func get_status_strength_multiplier(status: StringName) -> float:
	var bonus := 0.0
	for card in _taken_cards():
		if card.status_id == status:
			bonus += card.status_strength_bonus * stacks[card.id]
	return 1.0 + bonus

# Duration of `status` when `data` applies it (its own duration or the default, plus Dreams).
func get_status_duration(data: TowerData, status: StringName) -> float:
	var duration: float = data.status_duration if data.status_duration > 0.0 else EnemyStatuses.DEFAULT_DURATION[status]
	var multiplier := 1.0
	for card in _taken_cards():
		if card.status_id != status or not _applies_to(card, data):
			continue
		duration += card.status_duration_add * stacks[card.id]
		multiplier *= pow(card.status_duration_multiplier, stacks[card.id])
	return duration * multiplier

func has_rule(rule: StringName) -> bool:
	for card in _taken_cards():
		if card.rule_id == rule:
			return true
	return false

func get_dew_per_clear() -> int:
	var dew := 0
	for card in _taken_cards():
		dew += card.dew_per_clear * stacks[card.id]
	return dew

func count_walls() -> int:
	var count := 0
	for tower in tower_container.get_children():
		if tower is Tower and tower.tower_data.line == "wall" and not tower.is_queued_for_deletion():
			count += 1
	return count

func is_beside_bend(cell: Vector2) -> bool:
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		if _bend_cells.has(cell + offset):
			return true
	return false

func _sum_stat(data: TowerData, stat: String) -> float:
	var total := 0.0
	for card in _taken_cards():
		if _applies_to(card, data):
			total += float(card.get(stat)) * stacks[card.id]
	return total

func _applies_to(card: UpgradeData, data: TowerData) -> bool:
	return (card.stat_line == "" or card.stat_line == data.line) \
		and (card.stat_warden == "" or card.stat_warden == data.get_id())

func _taken_cards() -> Array[UpgradeData]:
	var taken: Array[UpgradeData] = []
	for card in pool:
		if stacks.get(card.id, 0) > 0:
			taken.append(card)
	return taken

func _update_bends() -> void:
	_bend_cells.clear()
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	for i in range(1, path.size() - 1):
		if path[i] - path[i - 1] != path[i + 1] - path[i]:
			_bend_cells[path[i]] = true


# --- Taking cards -------------------------------------------------------------------------------------

func take(card: UpgradeData) -> void:
	stacks[card.id] = stacks.get(card.id, 0) + 1
	if card.unlocks != null:
		unlocked[card.unlocks.get_id()] = true
		unlocks_changed.emit()
	if card.dew_now > 0:
		run_state.add_dew(card.dew_now)
	if card.max_leaves_add > 0:
		run_state.max_leaves += card.max_leaves_add
	if card.leaves_now > 0 or card.max_leaves_add > 0:
		run_state.regrow_leaves(card.leaves_now)
	if card.set_cost_warden != "":
		unlocks_changed.emit()  # Tower bar prices change
	card_taken.emit(card)


# --- Offers -----------------------------------------------------------------------------------------

func is_offering() -> bool:
	return not current_offer.is_empty()

func _on_drift_cleared(number: int, _bonus: int, _perfect: bool) -> void:
	if not dream_after_drifts.has(number) or not drift_director.has_next_drift() or run_state.is_over:
		return
	_pending_drifts.append(number)
	if not is_offering():
		_show_next_offer()

func _show_next_offer() -> void:
	if _pending_drifts.is_empty():
		return
	current_offer_drift = _pending_drifts.pop_front()
	current_offer = make_offer(current_offer_drift)
	if current_offer.is_empty():
		_show_next_offer()
		return
	offer_ready.emit(current_offer, current_offer_drift)

func choose(card: UpgradeData) -> void:
	if not current_offer.has(card):
		return
	take(card)
	_close_offer()

# "Let it pass": no card, a little Dew instead.
func skip() -> void:
	if not is_offering():
		return
	run_state.add_dew(skip_dew)
	_close_offer()

func _close_offer() -> void:
	current_offer = []
	offer_closed.emit()
	_show_next_offer()

# Builds a Dream offer for after drift `drift_number` (see dream_design.md, "How offers work").
func make_offer(drift_number: int) -> Array[UpgradeData]:
	dreams_seen += 1
	var offer: Array[UpgradeData] = []
	if dreams_seen == 1:
		for card in pool:
			if first_dream_card_ids.has(card.id) and is_eligible(card):
				offer.append(card)
	var act := drift_director.get_act(drift_number)
	var force_rare := boss_dream_drifts.has(drift_number) or _dreams_without_rare >= pity_after
	while offer.size() < cards_per_offer:
		var want_rare := force_rare and not offer.any(func(c: UpgradeData) -> bool: return c.is_rare_or_better())
		var card := _draw_card(act, offer, want_rare)
		if card == null:
			break
		offer.append(card)
	if offer.any(func(c: UpgradeData) -> bool: return c.is_rare_or_better()):
		_dreams_without_rare = 0
	else:
		_dreams_without_rare += 1
	return offer

func is_eligible(card: UpgradeData, act: int = 1) -> bool:
	if not card.in_start_pool or act < card.min_act:
		return false
	if card.max_stacks > 0 and card_stacks(card.id) >= card.max_stacks:
		return false
	if card.unlocks != null and is_unlocked(card.unlocks.get_id()):
		return false
	for requirement in card.requires:
		if not owns(requirement):
			return false
	return true

func _draw_card(act: int, exclude: Array[UpgradeData], want_rare: bool) -> UpgradeData:
	var eligible: Array[UpgradeData] = []
	for card in pool:
		if not exclude.has(card) and is_eligible(card, act):
			eligible.append(card)
	if eligible.is_empty():
		return null
	var rarity := _roll_rarity(act, want_rare)
	var of_rarity := eligible.filter(func(c: UpgradeData) -> bool: return c.rarity == rarity)
	if of_rarity.is_empty() and want_rare:
		of_rarity = eligible.filter(func(c: UpgradeData) -> bool: return c.is_rare_or_better())
	if of_rarity.is_empty():
		of_rarity = eligible
	return _weighted_pick(of_rarity)

func _roll_rarity(act: int, want_rare: bool) -> int:
	var weights: Array = RARITY_WEIGHTS[clampi(act, 1, RARITY_WEIGHTS.size()) - 1].duplicate()
	if want_rare:
		weights[0] = 0
		weights[1] = 0
	var total := 0
	for w in weights:
		total += w
	if total <= 0:
		return UpgradeData.Rarity.RARE
	var roll := _rng.randi_range(1, total)
	for i in weights.size():
		roll -= weights[i]
		if roll <= 0:
			return i
	return 0

func _weighted_pick(cards: Array) -> UpgradeData:
	var owned_lines := {}
	for tower_id in unlocked:
		var line := _line_of(tower_id)
		if line != "":
			owned_lines[line] = true
	var weights: Array[float] = []
	var total := 0.0
	for card in cards:
		var weight := 1.0
		for tag in card.tags:
			if owned_lines.has(tag):
				weight = tag_weight
				break
		weights.append(weight)
		total += weight
	var roll := _rng.randf() * total
	for i in cards.size():
		roll -= weights[i]
		if roll <= 0.0:
			return cards[i]
	return cards[-1]

var _lines_by_id := {}

func _line_of(tower_id: String) -> String:
	if _lines_by_id.is_empty():
		for card in pool:
			if card.unlocks != null:
				_lines_by_id[card.unlocks.get_id()] = card.unlocks.line
		_lines_by_id["sprout"] = "sprout"
		_lines_by_id["thornwall"] = "wall"
	return _lines_by_id.get(tower_id, "")


# --- Rules ------------------------------------------------------------------------------------------

# Spore Cascade: a cleansed creature's Spored stacks spread to the nearest creatures.
func _on_enemy_cleansed(enemy: Node2D) -> void:
	if not has_rule(&"spore_cascade") or not enemy.statuses.has(EnemyStatuses.SPORED):
		return
	var spores: int = enemy.statuses.stacks(EnemyStatuses.SPORED)
	var potency: float = enemy.statuses.potency(EnemyStatuses.SPORED)
	var duration: float = enemy.statuses.time_left(EnemyStatuses.SPORED)
	var others := get_tree().get_nodes_in_group(Tower.ENEMY_GROUP)
	others.erase(enemy)
	others.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_squared_to(enemy.global_position) \
			< b.global_position.distance_squared_to(enemy.global_position))
	for i in mini(SPORE_CASCADE_TARGETS, others.size()):
		others[i].apply_status(EnemyStatuses.SPORED, spores, duration, potency)
