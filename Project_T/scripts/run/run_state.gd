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
# Emitted once, when the run is won (last drift cleansed) or lost (no leaves left).
signal run_ended(won: bool)

@export var starting_dew: int = 60
@export var starting_leaves: int = 20
@export var max_leaves: int = 20

var dew: int
var leaves: int
var obstacles_tended := 0  # Obstacles cleared this run; each is +1 Seed at run end
var is_over := false
var won := false

@onready var enemy_spawner = %EnemyContainer
@onready var map_generator = %MapGenerator

func _ready() -> void:
	dew = starting_dew
	leaves = starting_leaves
	enemy_spawner.enemy_cleansed.connect(_on_enemy_cleansed)
	enemy_spawner.enemy_reached_goal.connect(_on_enemy_reached_goal)
	map_generator.obstacle_cleared.connect(func(_cell: Vector2, _data: ObstacleData) -> void:
		obstacles_tended += 1)

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
	if is_over or amount <= 0:
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
	earn_dew_at(enemy.enemy_data.dew_reward, enemy.global_position)

func _on_enemy_reached_goal(enemy: Node2D) -> void:
	lose_leaves(enemy.enemy_data.leaf_cost)
