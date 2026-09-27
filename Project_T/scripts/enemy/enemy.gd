extends Node2D

# Emitted when the enemy walks off the end of its path (reaches the goal), right before it's freed.
signal reached_goal(enemy: Node2D)
# Emitted when health hits 0. The enemy stops being a target and plays its cleanse effect.
signal cleansed(enemy: Node2D)

# Group of enemies that are still blighted (walking, targetable). Cleansed enemies leave it.
const GROUP := "enemies"
const BLIGHT_SHADER := preload("res://shaders/blight.gdshader")
const HEALTH_BAR_SIZE := Vector2(40, 5)
const HEALTH_BAR_OFFSET := Vector2(0, -38)  # Bar centre, relative to the enemy's origin
const CLEANSE_TIME := 0.8

@export var enemy_data: EnemyData
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var grid: Grid = preload("res://resource/map/map_grid.tres") # Reference to the shared Grid resource

var health: int
var max_health: int
var speed: float
var is_cleansed := false
# Multiplies `enemy_data.health` (set before adding to the tree; drifts grow creatures this way).
var health_scale := 1.0

# Cells to walk through, in grid coordinates. `_path_index` is the cell we're currently walking toward.
var _path: PackedVector2Array
var _path_index: int = 0

func _ready() -> void:
	add_to_group(GROUP)

	# Initialize attributes
	max_health = maxi(roundi(enemy_data.health * health_scale), 1)
	health = max_health
	speed = enemy_data.speed

	# Set up animations
	sprite.sprite_frames = enemy_data.sprite_frames
	sprite.scale = Vector2.ONE * enemy_data.sprite_scale
	sprite.play("walk_side")

	# Blighted look: per-enemy material so each one can be cleansed on its own
	var blight_material := ShaderMaterial.new()
	blight_material.shader = BLIGHT_SHADER
	sprite.material = blight_material

func _process(delta: float) -> void:
	if is_cleansed or _path_index >= _path.size():
		return

	var previous_position := position
	# Walk toward the next cell centre; carry leftover distance into the following cell so speed
	# stays constant through corners.
	var remaining := speed * delta
	while remaining > 0.0 and _path_index < _path.size():
		var target := grid.calculate_map_position(_path[_path_index])
		var to_target := target - position
		var distance := to_target.length()
		if distance <= remaining:
			position = target
			remaining -= distance
			_path_index += 1
		else:
			position += to_target / distance * remaining
			remaining = 0.0

	# Update animation based on movement direction
	update_animation(position - previous_position)

	if _path_index >= _path.size():
		reached_goal.emit(self)
		queue_free()

func _draw() -> void:
	# Health bar, only once the enemy has been hit
	if is_cleansed or health >= max_health:
		return
	var bar := Rect2(HEALTH_BAR_OFFSET - HEALTH_BAR_SIZE / 2, HEALTH_BAR_SIZE)
	draw_rect(bar.grow(1), Color(0.1, 0.1, 0.12, 0.8))
	var fill := bar
	fill.size.x *= float(health) / max_health
	draw_rect(fill, Color(0.55, 0.9, 0.5))

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

# Soothes the blight away. At 0 health the enemy is cleansed.
func take_damage(amount: int) -> void:
	if is_cleansed:
		return
	health = maxi(health - amount, 0)
	queue_redraw()
	if health == 0:
		_cleanse()

# Colour returns, the creature hops happily and fades out. It no longer blocks building or re-routes.
func _cleanse() -> void:
	is_cleansed = true
	remove_from_group(GROUP)
	cleansed.emit(self)
	queue_redraw()

	var tween := create_tween()
	tween.tween_method(_set_blight, 1.0, 0.0, CLEANSE_TIME * 0.4)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.25, 1.25), CLEANSE_TIME * 0.2)
	tween.tween_property(sprite, "scale", Vector2.ONE, CLEANSE_TIME * 0.2)
	tween.tween_property(sprite, "position:y", -24.0, CLEANSE_TIME * 0.6)
	tween.parallel().tween_property(self, "modulate:a", 0.0, CLEANSE_TIME * 0.6)
	tween.tween_callback(queue_free)

# 1 = fully blighted (grey), 0 = cleansed (full colour).
func _set_blight(amount: float) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("blight", amount)


# Sets the cells to walk through (grid coordinates). The enemy heads to points[0] first.
func set_path(points: PackedVector2Array) -> void:
	_path = points
	_path_index = 0

# The cell the enemy is currently walking toward. New paths should start from here so the enemy
# never cuts diagonally through a cell mid-step.
func get_target_cell() -> Vector2:
	if _path_index < _path.size():
		return _path[_path_index]
	return grid.calculate_grid_coordinates(position)

# The cell the enemy is standing in right now.
func get_current_cell() -> Vector2:
	return grid.calculate_grid_coordinates(position)

# Pixels left to walk before reaching the goal. Lower = further ahead (used for "first" targeting).
func get_remaining_distance() -> float:
	if _path_index >= _path.size():
		return 0.0
	var to_next := position.distance_to(grid.calculate_map_position(_path[_path_index]))
	# Paths step one cell at a time, so every remaining step is one cell long.
	return to_next + (_path.size() - 1 - _path_index) * grid.cell_size.x
