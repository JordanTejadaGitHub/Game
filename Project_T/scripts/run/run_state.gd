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
signal sprout_charges_changed(charges: int)  # For the Warden bar's seed badge (Seedling Gift)
# Emitted once, when the run is won (last drift cleansed) or lost (no leaves left).
signal run_ended(won: bool)
signal dew_spent(cost: int)  # Every spend (RunHistory sorts them into planting, growth, ranks, clears)

@export var starting_dew: int = 60  # run_design.md "Opening rule": enough Sprouts for drift 1
@export var starting_leaves: int = 15  # Difficulty pass v1: was 20
@export var max_leaves: int = 15
# Dispel Dew is each nightmare's share of its drift's Dew pot (DriftDirector, run_design.md "The Dew pot");
# the fraction carries to the next dispel. (The per-act multipliers and Grove dew_gain are folded into the table.)
var _dispel_dew_carry := 0.0
var pot_earned_block := 0.0  # Pot shares dispelled this block (the rest report: "840 of 900")

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
# Nurture Dreams (dream_design.md "Nurture cards"): Dew spent on ranks this run (opener cards need
# 30+), and Remembered Care's memory seeds (ranks the next planted Wardens start at, highest first).
var rank_dew_spent := 0
var memory_seeds: Array[int] = []
# Seedling Gift: free Sprout charges (used before Dew when planting a Sprout).
var sprout_charges := 0

func add_sprout_charges(amount: int) -> void:
	sprout_charges = maxi(sprout_charges + amount, 0)
	sprout_charges_changed.emit(sprout_charges)
var creatures_cleansed := 0
var leaves_lost := 0
var seed_bonus := 0.0  # +share of Seeds at run end (Seed Pouch, Blight Levels); set by MetaRun
var dew_gain_bonus := 0.0  # Rich Dew (Grove dew_gain), set by MetaRun: multiplies every drift's Dew pot (DriftDirector)
var free_nurtures := 0  # Nurture ranks left that cost no Dew (First Care); set by MetaRun
var longest_path := 0  # Longest route the maze reached this run, in tiles
var play_time := 0.0  # Seconds of unpaused play this run
var abandoned := false  # The run ended from the pause menu's Abandon (RunHistory: "abandoned", not "lost")
var dew_harvested := 0  # Dew the catchers poured at rests (the Harvest) plus Wellspring interest (Golden Harvest reads it)
var is_over := false
var won := false

# Seeds formula (meta_design.md, revised for 100 drifts): 1 per 2 drifts survived (max 50), 1 per
# 20 nightmares dispelled, 20 per boss, 1 per obstacle tended, +120 for winning, +20 on the first run.
const SEEDS_PER_DRIFTS := 2
const SEEDS_DRIFT_MAX := 50
const CLEANSES_PER_SEED := 20
const SEEDS_PER_BOSS := 20
const SEEDS_FOR_WIN := 120
const SEEDS_FIRST_RUN := 20

@onready var enemy_spawner = %EnemyContainer
@onready var map_generator = %MapGenerator

func _ready() -> void:
	dew = starting_dew
	leaves = starting_leaves
	enemy_spawner.enemy_cleansed.connect(_on_enemy_cleansed)
	enemy_spawner.enemy_reached_goal.connect(_on_enemy_reached_goal)
	var track_path := func() -> void:
		longest_path = maxi(longest_path, map_generator.route_length(map_generator.get_path_from(map_generator.startPath)))  # Full cells (half-cell route)
	map_generator.path_changed.connect(track_path)
	track_path.call_deferred()  # The map builds its path after RunState is ready
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
	if seed_bonus > 0.0:  # Seed Pouch, Blight Levels (+10% each)
		var extra := roundi(total * seed_bonus)
		lines.append(["Seed bonus +%d%%" % roundi(seed_bonus * 100.0), extra])
		total += extra
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
	dew_spent.emit(cost)
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
func earn_dew_at(amount: int, world_position: Vector2, color: Color = DewPopup.COLOR) -> void:
	if amount <= 0:
		return
	add_dew(amount)
	dew_earned.emit(amount, world_position)
	# Popup lives in the world (the main scene), not on whatever earned it, which may be freed.
	get_parent().add_child(DewPopup.new(amount, world_position, color))

func lose_leaves(amount: int) -> void:
	if is_over or amount <= 0 or invulnerable:
		return
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if dreams and dreams.absorb_leak():
		return  # Thick Bark saved this leak (whole, even a boss's)
	leaves_lost += mini(amount, leaves)
	leaves = maxi(leaves - amount, 0)
	leaves_changed.emit(leaves, max_leaves)
	if leaves == 0:
		end_run(false)

func _process(delta: float) -> void:
	if not is_over:
		play_time += delta / maxf(Engine.time_scale, 0.001)  # Real seconds, not game seconds

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
	# Its share of its drift's pot (already multiplied by the pot's Dreams / Omens); a nightmare from outside
	# a drift (Test Grove spawns) pays its plain dew_reward.
	var share: float = enemy.get_dew_share() if enemy.has_method("get_dew_share") else float(enemy.get_dew_reward())
	var pot_share = enemy.get("dew_share")
	if pot_share != null and float(pot_share) >= 0.0:
		pot_earned_block += share
	# A catcher nearby (Dewcatcher, Wellspring) catches a share more into its bowl, for the Harvest.
	var caught := DewCatch.catch(enemy, share)
	earn_dew_at(_carried_dew(share), enemy.global_position, DewCatch.GOLD if caught else DewPopup.COLOR)

# Pays whole Dew and carries the fraction to the next dispel (small shares aren't rounded away).
func _carried_dew(amount: float) -> int:
	_dispel_dew_carry += amount
	var paid := floori(_dispel_dew_carry + 0.0001)
	_dispel_dew_carry -= paid
	return paid

# The old name (tools/balance_run.gd): plain Dew with the fraction carry.
func _scaled_dispel_dew(dew: float) -> int:
	return _carried_dew(dew)

# Kept for callers (catchers, tests): the pot already holds every Dew multiplier, so dispels add none.
func get_dispel_multiplier() -> float:
	return 1.0

func _on_enemy_reached_goal(enemy: Node2D) -> void:
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	var multiplier := omens.get_leak_multiplier() if omens else 1.0  # Leaf Fall: ×2 (bosses too)
	lose_leaves(roundi(enemy.get_leaf_cost() * multiplier))
