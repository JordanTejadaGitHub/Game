extends Node

@onready var enemy_spawner = $EnemyContainer
@onready var leaf_bug = preload("res://resource/enemy/leaf_bug.tres")

func _ready() -> void:
	# Keep LeafBugs coming so there's something to maze (until waves exist)
	enemy_spawner.start_spawning(leaf_bug)
