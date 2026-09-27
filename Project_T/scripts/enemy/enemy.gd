extends Node2D

@export var enemy_data: EnemyData
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var path_2d: Path2D = $Path2D
@onready var path_follower: PathFollow2D = $Path2D/PathFollow2D

@export var grid: Grid = preload("res://resource/map/map_grid.tres") # Reference to the shared Grid resource

var health: int
var speed: float

func _ready() -> void:
	# Initialize attributes
	health = enemy_data.health
	speed = enemy_data.speed

	# Set up animations
	sprite.frames = enemy_data.sprite_frames
	sprite.play("walk_side")

	# Ensure PathFollow2D starts at the beginning of the path
	path_follower.progress = 0.0

func _process(delta: float) -> void:
	var previous_position := position

	# Move the PathFollow2D along the path
	path_follower.progress += speed * delta

	# Update the enemy's position to match the PathFollow2D's position
	position = path_follower.position

	# Update animation based on movement direction
	update_animation(position - previous_position)

func update_animation(velocity: Vector2) -> void:
	# Keep the current animation when not moving (e.g. end of path)
	if velocity.is_zero_approx():
		return
	if abs(velocity.x) >= abs(velocity.y):  # Moving horizontally
		sprite.play("walk_side")
		sprite.flip_h = velocity.x < 0  # Flip horizontally if moving left
	elif velocity.y > 0:  # Moving down
		sprite.play("walk_down")
		sprite.flip_h = false
	else:  # Moving up
		sprite.play("walk_up")
		sprite.flip_h = false


func set_path(points: PackedVector2Array) -> void:
	# Ensure the Path2D has a valid Curve2D
	if not path_2d.curve:
		path_2d.curve = Curve2D.new()

	# Add points to the curve, converting grid positions to map positions
	var curve = path_2d.curve
	curve.clear_points()

	for point in points:
		var map_position = grid.calculate_map_position(point)
		curve.add_point(map_position)
