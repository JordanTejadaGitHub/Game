extends Resource
class_name EnemyData

@export var health: int  # The health of the enemy
@export var speed: float  # The movement speed of the enemy
@export var sprite_frames: SpriteFrames  # The animation to play for the enemy's movement
@export var dew_reward: int = 3  # Dew dropped when this creature is cleansed
