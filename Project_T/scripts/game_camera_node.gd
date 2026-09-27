extends Node2D

@onready var camera_2d: Camera2D = $Camera2D
const MAP_GRID = preload("res://resource/map/map_grid.tres")  # The shared grid resource

# Camera movement settings
@export var camera_speed: float = 1000.0  # Camera movement speed
@export var movement_smoothness: float = 12.0  # How quickly the camera catches up to its target (higher = snappier)

# Camera zoom settings
@export var camera_zoom_in_max: float = 1.4  # Maximum zoom-in level
@export var camera_zoom_out_min: float = 0.5  # Minimum zoom-out level
@export var zoom_speed: float = 0.1  # Speed of zoom adjustment
@export var zoom_smoothness: float = 10.0  # How quickly the zoom catches up to its target (higher = snappier)

# Internal variables
var target_position: Vector2  # Target position for the camera
var target_zoom: Vector2  # Target zoom level (Vector2 for consistency)

var map_size_pixels: Vector2  # Map size in pixels, calculated from MAP_GRID

func _ready() -> void:
	add_to_group(&"game_camera")
	# Calculate map size in pixels from the grid
	map_size_pixels = MAP_GRID.size * MAP_GRID.cell_size

	# Initialize the camera position and zoom
	target_position = camera_2d.position
	target_zoom = camera_2d.zoom

var _glide_points := PackedVector2Array()  # Onboarding glide along the path (pixels)
var _glide_time := 0.0
var _glide_duration := 0.0

# Glides the camera along `points` (pixels) over `duration` seconds, ending on the last one. Any
# camera key cancels it. Used on a first run to show where creatures go (onboarding.md).
func glide(points: PackedVector2Array, duration: float = 5.0) -> void:
	if points.size() < 2:
		return
	_glide_points = points
	_glide_time = 0.0
	_glide_duration = duration

func _process(delta: float) -> void:
	# The camera runs in real time: game speed (2×/3×) shouldn't make panning faster.
	if Engine.time_scale > 0.0:
		delta /= Engine.time_scale
	if not _glide_points.is_empty():
		_advance_glide(delta)
	_handle_input(delta)  # Handle WASD movement and zoom input
	_clamp_camera_to_map()  # Keep the target inside the map bounds
	_smooth_camera_movement(delta)  # Smoothly move the camera
	_smooth_zoom(delta)  # Smoothly adjust the zoom level

func _advance_glide(delta: float) -> void:
	for action in ["move_camera_up", "move_camera_down", "move_camera_left", "move_camera_right"]:
		if Input.is_action_pressed(action):
			_glide_points = PackedVector2Array()  # The player takes over
			return
	_glide_time += delta
	var t := clampf(_glide_time / _glide_duration, 0.0, 1.0)
	var index := t * (_glide_points.size() - 1)
	var i := mini(int(index), _glide_points.size() - 2)
	target_position = _glide_points[i].lerp(_glide_points[i + 1], index - i)
	if t >= 1.0:
		_glide_points = PackedVector2Array()

# Handle keyboard input for movement and zoom
func _handle_input(delta: float) -> void:
	# Handle WASD movement
	var direction = Vector2.ZERO
	if Input.is_action_pressed("move_camera_up"):  # W
		direction.y -= 1
	if Input.is_action_pressed("move_camera_down"):  # S
		direction.y += 1
	if Input.is_action_pressed("move_camera_left"):  # A
		direction.x -= 1
	if Input.is_action_pressed("move_camera_right"):  # D
		direction.x += 1
	if direction != Vector2.ZERO:
		target_position += direction.normalized() * camera_speed * delta

	# Handle zoom input
	if Input.is_action_just_released("zoom_in"):  # Zoom in
		target_zoom.x = clamp(target_zoom.x + zoom_speed, camera_zoom_out_min, camera_zoom_in_max)
		target_zoom.y = clamp(target_zoom.y + zoom_speed, camera_zoom_out_min, camera_zoom_in_max)
	if Input.is_action_just_released("zoom_out"):  # Zoom out
		target_zoom.x = clamp(target_zoom.x - zoom_speed, camera_zoom_out_min, camera_zoom_in_max)
		target_zoom.y = clamp(target_zoom.y - zoom_speed, camera_zoom_out_min, camera_zoom_in_max)

# Smoothly move the camera to the target position.
# Using 1 - exp(-k * delta) makes the smoothing feel the same at any frame rate.
func _smooth_camera_movement(delta: float) -> void:
	camera_2d.position = camera_2d.position.lerp(target_position, 1.0 - exp(-movement_smoothness * delta))

# Smoothly adjust the camera's zoom level
func _smooth_zoom(delta: float) -> void:
	# Interpolate zoom as Vector2
	camera_2d.zoom = camera_2d.zoom.lerp(target_zoom, 1.0 - exp(-zoom_smoothness * delta))

# Clamp the camera's target to the map boundaries
func _clamp_camera_to_map() -> void:
	var EPSILON = 0.001  # Small buffer to prevent jittering

	var viewport_size = camera_2d.get_viewport_rect().size
	var actual_visible_area = viewport_size / camera_2d.zoom  # Adjust for zoom
	var half_visible_area = actual_visible_area / 2  # Half the visible area

	# Calculate clamping ranges to ensure the entire visible area stays within map bounds
	var min_x = half_visible_area.x + EPSILON
	var max_x = max(map_size_pixels.x - half_visible_area.x - EPSILON, min_x)
	var min_y = half_visible_area.y + EPSILON
	var max_y = max(map_size_pixels.y - half_visible_area.y - EPSILON, min_y)

	# When the camera hits the boundaries, we update the target position directly
	if target_position.x < min_x:
		target_position.x = min_x
	elif target_position.x > max_x:
		target_position.x = max_x

	if target_position.y < min_y:
		target_position.y = min_y
	elif target_position.y > max_y:
		target_position.y = max_y
