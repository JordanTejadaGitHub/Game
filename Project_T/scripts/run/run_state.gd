extends Node
class_name RunState

# Per-run resources. Lives in the main scene; restarting a run reloads the scene, so there's no reset
# logic. Starting values are exports here (one place) so meta perks can modify them later.

signal dew_changed(dew: int)
# Emitted when something tried to spend Dew the player doesn't have (for UI feedback).
signal dew_short(cost: int)
# Emitted when Dew is earned somewhere in the world (e.g. a creature was cleansed), for popups.
signal dew_earned(amount: int, world_position: Vector2)
signal leaves_changed(leaves: int, max_leaves: int)
signal free_clears_changed(free_clears: int)
# Emitted once, when the run is won (last drift cleansed) or lost (no leaves left).
signal run_ended(won: bool)

@export var starting_dew: int = 60
@export var starting_leaves: int = 20
@export var max_leaves: int = 20

var dew: int
var leaves: int
var obstacles_tended := 0  # Obstacles cleared this run; each is +1 Seed at run end
var tended_cells: Array[Vector2] = []  # Which obstacles were cleared (for the mid-run save)
var omen_seeds := 0  # Seeds earned from Omen rewards (Swift Stream), paid at run end
# Clearing Dreams (dream_design.md, "Clearing cards"): free clears to spend (Heartwood's Reach),
# cells whose first Warden costs half (Reclaimed Earth: {cell: true}), and a flag set while a
# Dream clears obstacles without Seeds (Burn Back the Dead Wood). Every clear still lands in
# `tended_cells`, so tended_cells.size() is the run's total clears (Tended Forest).
var free_clears := 0
var fertile_cells := {}
var clearing_without_seeds := false
var invulnerable := false  # Test Grove: leaves can't fall
var creatures_cleansed := 0
var is_over := false
var won := false

# Seeds formula (meta_design.md): 1 per 2 drifts survived (max 50), 1 per 25 creatures cleansed,
# 10 per boss, 1 per obstacle tended, +50 for winning, +20 on the very first run.
const SEEDS_PER_DRIFTS := 2
const SEEDS_DRIFT_MAX := 50
const CLEANSES_PER_SEED := 25
const SEEDS_PER_BOSS := 10
const SEEDS_FOR_WIN := 50
const SEEDS_FIRST_RUN := 20

@onready var enemy_spawner = %EnemyContainer
@onready var map_generator = %MapGenerator

func _ready() -> void:
	dew = starting_dew
	leaves = starting_leaves
	enemy_spawner.enemy_cleansed.connect(_on_enemy_cleansed)
	enemy_spawner.enemy_reached_goal.connect(_on_enemy_reached_goal)
	map_generator.obstacle_cleared.connect(func(cell: Vector2, _data: ObstacleData) -> void:
		if not clearing_without_seeds:
			obstacles_tended += 1
		tended_cells.append(cell))

# The run's Seeds: [[label, seeds], …] ending with ["Total", n]. `drifts_cleared` and `bosses`
# come from the DriftDirector; `first_run` adds the first-run bonus.
func get_seed_breakdown(drifts_cleared: int, bosses: int, first_run: bool) -> Array:
	var lines: Array = [
		["Drifts survived: %d" % drifts_cleared, mini(drifts_cleared / SEEDS_PER_DRIFTS, SEEDS_DRIFT_MAX)],
		["Nightmares dispelled: %d" % creatures_cleansed, creatures_cleansed / CLEANSES_PER_SEED],
		["Bosses dispelled: %d" % bosses, bosses * SEEDS_PER_BOSS],
		["Tended: %d" % obstacles_tended, obstacles_tended],
	]
	if omen_seeds > 0:
		lines.append(["Omens", omen_seeds])
	if won:
		lines.append(["The Hollow Oak is dispelled", SEEDS_FOR_WIN])
	if first_run:
		lines.append(["The first seed", SEEDS_FIRST_RUN])
	var total := 0
	for line in lines:
		total += line[1]
	lines.append(["Total", total])
	return lines

func can_afford(cost: int) -> bool:
	return dew >= cost

# Spends `cost` Dew if the player has it. Returns false (and spends nothing) otherwise.
func spend_dew(cost: int) -> bool:
	if not can_afford(cost):
		dew_short.emit(cost)
		return false
	dew -= cost
	dew_changed.emit(dew)
	return true

func add_free_clears(amount: int) -> void:
	free_clears = maxi(free_clears + amount, 0)
	free_clears_changed.emit(free_clears)

# Uses one free clear if there is one.
func use_free_clear() -> bool:
	if free_clears <= 0:
		return false
	add_free_clears(-1)
	return true

func add_dew(amount: int) -> void:
	if amount <= 0:
		return
	dew += amount
	dew_changed.emit(dew)

# Adds Dew and shows a "+N Dew" popup at `world_position`.
func earn_dew_at(amount: int, world_position: Vector2) -> void:
	if amount <= 0:
		return
	add_dew(amount)
	dew_earned.emit(amount, world_position)
	# Popup lives in the world (the main scene), not on whatever earned it, which may be freed.
	get_parent().add_child(DewPopup.new(amount, world_position))

func lose_leaves(amount: int) -> void:
	if is_over or amount <= 0 or invulnerable:
		return
	leaves = maxi(leaves - amount, 0)
	leaves_changed.emit(leaves, max_leaves)
	if leaves == 0:
		end_run(false)

# The Heartwood regrows up to its maximum (between acts).
func regrow_leaves(amount: int) -> void:
	if is_over:
		return
	leaves = mini(leaves + amount, max_leaves)
	leaves_changed.emit(leaves, max_leaves)

func end_run(did_win: bool) -> void:
	if is_over:
		return
	is_over = true
	won = did_win
	run_ended.emit(did_win)

func _on_enemy_cleansed(enemy: Node2D) -> void:
	creatures_cleansed += 1
	earn_dew_at(enemy.get_dew_reward(), enemy.global_position)

func _on_enemy_reached_goal(enemy: Node2D) -> void:
	lose_leaves(enemy.get_leaf_cost())
