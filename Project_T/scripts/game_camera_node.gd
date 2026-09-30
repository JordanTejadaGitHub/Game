extends Node2D

@onready var camera_2d: Camera2D = $Camera2D
const MAP_GRID = preload("res://resource/map/map_grid.tres")  # The shared grid resource

# Camera movement settings
@export var camera_speed: float = 1000.0  # Camera movement speed
@export var movement_smoothness: float = 12.0  # How quickly the camera catches up to its target (higher = snappier)

# Camera zoom settings
@export var camera_zoom_in_max: float = 2.5  # Maximum zoom-in level (was 1.4; user: "allow zooming in more")
@export var camera_zoom_out_min: float = 0.5  # Minimum zoom-out level
@export var zoom_step: float = 1.1  # Each wheel notch multiplies the zoom by this (even steps at both ends)
@export var zoom_smoothness: float = 10.0  # How quickly the zoom catches up to its target (higher = snappier)
@export var hud_overscroll := Vector2(300, 180)  # Screen pixels the view may go past each map edge (the HUD's size)

# Internal variables
var target_position: Vector2  # Target position for the camera
var target_zoom: Vector2  # Target zoom level (Vector2 for consistency), in view units (see _view_zoom)
# The zoom the player sees: 1 = one map pixel per window pixel, whatever the UI scale. The UI scale
# (HeartwoodMemory "ui_scale" = the root's content_scale_factor) scales everything drawn, so the
# Camera2D zooms by view / factor and the map keeps its size when the UI grows or shrinks.
var _view_zoom: Vector2

var map_size_pixels: Vector2  # Map size in pixels, calculated from MAP_GRID

func _ready() -> void:
	add_to_group(&"game_camera")
	# Calculate map size in pixels from the grid
	map_size_pixels = MAP_GRID.size * MAP_GRID.cell_size

	# Initialize the camera position and zoom
	target_position = camera_2d.position
	target_zoom = camera_2d.zoom
	_view_zoom = camera_2d.zoom
	camera_2d.zoom = _view_zoom / ui_factor()

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

# H / F: centre on the Heartwood / on the forest's edge.
func _unhandled_input(event: InputEvent) -> void:
	var map_generator = get_node_or_null("%MapGenerator")
	if map_generator == null:
		return
	if event.is_action_pressed("center_heartwood"):
		target_position = MAP_GRID.calculate_map_position(map_generator.endPath)
		_glide_points = PackedVector2Array()
	elif event.is_action_pressed("center_start"):
		target_position = MAP_GRID.calculate_map_position(map_generator.startPath)
		_glide_points = PackedVector2Array()
	# Wheel zoom here, not polled: a wheel over a panel (the Codex, Dreams this run, settings …) is
	# used by the UI and never reaches this (screens_ui.md: UI scrolling never moves the map).
	elif event.is_action_pressed("zoom_in") and not modal_open():
		zoom_by_step(1.0)
	elif event.is_action_pressed("zoom_out") and not modal_open():
		zoom_by_step(-1.0)

func zoom_by_step(direction: float) -> void:
	var zoom_min := _get_zoom_out_min()
	target_zoom = (target_zoom * pow(zoom_step, direction)).clamp(Vector2.ONE * zoom_min,
		Vector2.ONE * maxf(camera_zoom_in_max, zoom_min))

# A full-screen screen is up (pause menu with its Codex / settings, Dream, Omen, Remember, family
# pick, results, boss dossier, nightmare card): the map stays put under it.
const MODAL_SCREENS := ["HUD/PauseMenu", "HUD/DreamScreen", "HUD/OmenScreen", "HUD/RememberScreen",
	"HUD/FamilyPickScreen", "HUD/ResultsScreen", "HUD/BossDossier", "HUD/NightmareIntro"]

func modal_open() -> bool:
	var main := owner if owner != null else get_parent()
	for path in MODAL_SCREENS:
		var screen := main.get_node_or_null(path) as CanvasItem
		if screen != null and screen.visible:
			return true
	return false

# Typing in a text field (the Codex search, the dev card search): the keys are letters, not panning.
func _typing() -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	return focus is LineEdit or focus is TextEdit

# Keyboard panning (WASD / arrows). Zoom is the wheel, in _unhandled_input.
func _handle_input(delta: float) -> void:
	if modal_open() or _typing():
		return
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
	var zoom_min := _get_zoom_out_min()
	target_zoom = target_zoom.clamp(Vector2.ONE * zoom_min, Vector2.ONE * maxf(camera_zoom_in_max, zoom_min))

# Touch (TouchBuild: two-finger drag / pinch): move the view by `screen_px` (the fingers' movement,
# so the map follows them) and zoom by `factor` (> 1 = in), within the usual limits.
func pan_screen(screen_px: Vector2) -> void:
	target_position -= screen_px / camera_2d.zoom
	_glide_points = PackedVector2Array()

func zoom_by(factor: float) -> void:
	var zoom_min := _get_zoom_out_min()
	target_zoom = (target_zoom * factor).clamp(Vector2.ONE * zoom_min, Vector2.ONE * maxf(camera_zoom_in_max, zoom_min))

# How far the camera may zoom out: `camera_zoom_out_min`, but never past the whole map (plus a cell
# of forest) filling the view, so a small map can't shrink into the middle of the screen.
func _get_zoom_out_min() -> float:
	var viewport_size := camera_2d.get_viewport_rect().size
	var framed := map_size_pixels + MAP_GRID.cell_size * 2
	# The viewport size is in UI-scaled pixels: × the factor gives the view zoom that frames the map.
	return maxf(camera_zoom_out_min, minf(viewport_size.x / framed.x, viewport_size.y / framed.y) * ui_factor())

# Smoothly move the camera to the target position.
# Using 1 - exp(-k * delta) makes the smoothing feel the same at any frame rate.
func _smooth_camera_movement(delta: float) -> void:
	camera_2d.position = camera_2d.position.lerp(target_position, 1.0 - exp(-movement_smoothness * delta))

# Smoothly adjust the camera's zoom level
func _smooth_zoom(delta: float) -> void:
	_view_zoom = _view_zoom.lerp(target_zoom, 1.0 - exp(-zoom_smoothness * delta))
	camera_2d.zoom = _view_zoom / ui_factor()

# The UI scale factor now (1 when nothing scales the window).
func ui_factor() -> float:
	return UiStyle.ui_factor(get_tree().root if is_inside_tree() else null)

# Clamp the camera's target to the map boundaries
func _clamp_camera_to_map() -> void:
	var EPSILON = 0.001  # Small buffer to prevent jittering

	var viewport_size = camera_2d.get_viewport_rect().size
	var actual_visible_area = viewport_size / camera_2d.zoom  # Adjust for zoom
	var half_visible_area = actual_visible_area / 2  # Half the visible area

	# The view may go past the map edges by the HUD's size, so the start and the Heartwood can be
	# scrolled clear of the panels (screens_ui.md principle 5).
	var overscroll: Vector2 = hud_overscroll / camera_2d.zoom

	# Calculate clamping ranges to keep the visible area within the map bounds (plus the overscroll).
	# When the view is bigger than that along an axis, the map is centred on that axis instead.
	var min_x = half_visible_area.x - overscroll.x + EPSILON
	var max_x = map_size_pixels.x - half_visible_area.x + overscroll.x - EPSILON
	if max_x < min_x:
		min_x = map_size_pixels.x / 2
		max_x = min_x
	var min_y = half_visible_area.y - overscroll.y + EPSILON
	var max_y = map_size_pixels.y - half_visible_area.y + overscroll.y - EPSILON
	if max_y < min_y:
		min_y = map_size_pixels.y / 2
		max_y = min_y

	# When the camera hits the boundaries, we update the target position directly
	if target_position.x < min_x:
		target_position.x = min_x
	elif target_position.x > max_x:
		target_position.x = max_x

	if target_position.y < min_y:
		target_position.y = min_y
	elif target_position.y > max_y:
		target_position.y = max_y
