extends Node

@onready var enemy_spawner = $EnemyContainer
@onready var leaf_bug = preload("res://resource/enemy/leaf_bug.tres")

func _ready() -> void:
	# Spawn a LeafBug on game start
	enemy_spawner.spawn_enemy(leaf_bug)
