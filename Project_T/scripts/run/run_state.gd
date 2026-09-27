extends Node
class_name RunState

# Per-run resources. Lives in the main scene; restarting a run reloads the scene, so there's no reset
# logic. Starting values are exports here (one place) so meta perks can modify them later.

signal dew_changed(dew: int)
# Emitted when something tried to spend Dew the player doesn't have (for UI feedback).
signal dew_short(cost: int)
# Emitted when Dew is earned somewhere in the world (e.g. a creature was cleansed), for popups.
signal dew_earned(amount: int, world_position: Vector2)

@export var starting_dew: int = 60

var dew: int

@onready var enemy_spawner = %EnemyContainer

func _ready() -> void:
	dew = starting_dew
	enemy_spawner.enemy_cleansed.connect(_on_enemy_cleansed)

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

func _on_enemy_cleansed(enemy: Node2D) -> void:
	var reward: int = enemy.enemy_data.dew_reward
	add_dew(reward)
	if reward > 0:
		dew_earned.emit(reward, enemy.global_position)
		# Popup lives in the world (the main scene), not on the creature, which fades out and frees.
		get_parent().add_child(DewPopup.new(reward, enemy.global_position))
