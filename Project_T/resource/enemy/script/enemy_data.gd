extends Resource
class_name EnemyData

@export var display_name: String = "Creature"
@export var health: int  # The health of the enemy (at drift 1; grows each drift unless `is_boss`)
@export var speed: float  # The movement speed of the enemy, in pixels per second (64 px = 1 cell)
@export var sprite_frames: SpriteFrames  # The animation to play for the enemy's movement
@export var dew_reward: int = 3  # Dew dropped when this creature is cleansed
@export var leaf_cost: int = 1  # Leaves lost when it reaches the Heartwood (big 2, bosses 5)
@export var is_boss: bool = false  # Bosses have fixed health: no per-drift growth
@export var sprite_scale: float = 1.0  # Drawn bigger/smaller (e.g. bosses, Puffcaplets)

@export_group("Split")
# When cleansed, this many `split_into` creatures pop out and keep walking (e.g. Puffcap).
@export var split_into: EnemyData
@export var split_count: int = 0
