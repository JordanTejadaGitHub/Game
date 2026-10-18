extends Node2D

@onready var camera_2d: Camera2D = $Camera2D
const MAP_GRID = preload("res://resource/map/map_grid.tres")  # The shared grid resource

# Camera movement settings
@export var camera_speed: float = 1000.0  # Camera movement speed
@export var movement_smoothness: float = 12.0  # How quickly the camera catches up to its target (higher = snappier)

# Camera zoom settings
@export var camera_zoom_in_max: float = 3.5  # Maximum zoom-in level (was 1.4, then 2.5; user 2026-10-15: "zoom a little more in", desktop and mobile)
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
	get_tree().process_frame.connect(_on_frame_started)
	_frame_scale = Engine.time_scale
	# Calculate map size in pixels from the grid
	map_size_pixels = MAP_GRID.size * MAP_GRID.cell_size

	# Initialize the camera position and zoom
	target_position = camera_2d.position
	target_zoom = camera_2d.zoom
	_view_zoom = camera_2d.zoom
	camera_2d.zoom = _view_zoom / ui_factor()
	# Open framed on the run: halfway between the start and the Heartwood (which now sits inland).
	var map_generator = get_node_or_null("%MapGenerator")
	if map_generator != null and map_generator.get("layout") != null:
		target_position = (MAP_GRID.calculate_map_position(map_generator.startPath)
			+ MAP_GRID.calculate_map_position(map_generator.endPath)) / 2.0
		camera_2d.position = target_position

var _glide_points := PackedVector2Array()  # Onboarding glide along the path (pixels)
var _glide_time := 0.0
var _glide_duration := 0.0

# Glides the camera along `points` (pixels) over `duration` seconds, ending on the last one. Any
# camera key cancels it. Used on a first run to show where creatures go (onboarding.md).
func glide(points: PackedVector2Array, duration: float = 5.0) -> void:
	if points.size() < 2:
		return
	_glide_points = points
	_zoom_anchor_set = false
	_glide_time = 0.0
	_glide_duration = duration
	_glide_lengths = PackedFloat32Array([0.0])  # Distance along the points: a steady pace whatever their spacing
	for i in range(1, points.size()):
		_glide_lengths.append(_glide_lengths[-1] + points[i - 1].distance_to(points[i]))

const ROUTE_GLIDE_SPEED := 260.0  # Pixels a second along the route
const ROUTE_GLIDE_MIN := 4.0
const ROUTE_GLIDE_MAX := 9.0
var _glide_lengths := PackedFloat32Array()

# The first-run glide along the route (onboarding.md): at a steady pace (by distance, eased in and out), 4–9 s by the
# route's length, ending on the Heartwood. When the whole route already fits on screen it doesn't glide (the opening
# framing shows it all; a clamped camera only bobbed up and down, user: "it moves the camera wrong"). True if it glides.
func glide_route(points: PackedVector2Array) -> bool:
	if points.size() < 2:
		return false
	var box := Rect2(points[0], Vector2.ZERO)
	for point in points:
		box = box.expand(point)
	var view := camera_2d.get_viewport_rect().size / camera_2d.zoom
	if box.grow(MAP_GRID.cell_size.x).size.x <= view.x and box.grow(MAP_GRID.cell_size.y).size.y <= view.y:
		return false
	var length := 0.0
	for i in range(1, points.size()):
		length += points[i - 1].distance_to(points[i])
	glide(points, clampf(length / ROUTE_GLIDE_SPEED, ROUTE_GLIDE_MIN, ROUTE_GLIDE_MAX))
	return true

var _frame_scale := 1.0  # Engine.time_scale this frame's delta was scaled by

# Read when the frame starts (after the engine scaled delta): hit-stop and slow motion change time_scale
# mid-frame, and dividing by the new tiny scale flung the camera (user: "I jump around the screen while using
# WASD when a wave is there").
func _on_frame_started() -> void:
	_frame_scale = Engine.time_scale

const MAX_STEP := 0.1  # Seconds: a hitch never moves the camera more than this much panning

func _process(delta: float) -> void:
	# The camera runs in real time: game speed (2×/3×) shouldn't make panning faster.
	if _frame_scale > 0.0:
		delta /= _frame_scale
	delta = minf(delta, MAX_STEP)
	if not _glide_points.is_empty():
		_advance_glide(delta)
	_read_camera_settings(delta)
	_handle_input(delta)  # Handle WASD movement and zoom input
	_edge_scroll_pan(delta)  # The pointer at a window edge
	_clamp_camera_to_map()  # Keep the target inside the map bounds
	_smooth_camera_movement(delta)  # Move the camera (at once when the player pans)
	_smooth_zoom(delta)  # Smoothly adjust the zoom level
	_follow_zoom_anchor()  # A wheel zoom keeps the point under the pointer
	_snap = false

# --- StarCraft 2 / Warcraft 3 style control (screens_ui.md "HUD notes", user 2026-10-11) -----------------------
# Edge scrolling (a setting, on by default, with its speed; the cursor is kept in the window in fullscreen; only
# while the window has focus), middle-mouse drag, the wheel zooming toward the pointer, and panning that is
# immediate: no easing while the player moves the view and no drift after release. H / F and the first-run glide
# still ease. Touch (pan_screen / zoom_by) is unchanged.
const EDGE_SETTING := "edge_scroll"  # On by default
const EDGE_SPEED_SETTING := "edge_scroll_speed"  # A share of the keyboard's speed, 0.25–1 (1 = the same)
const EDGE_MARGIN := 6.0  # Viewport px from a window edge that pan
var _edge_scroll := true
var _edge_speed := 1.0
var _settings_check := 0.0
var _confined := false  # This node confined the cursor (fullscreen edge scrolling)
var _dragging := false  # Middle mouse held on the map
var _snap := false  # The player moved the view this frame: the camera goes there at once
var _zoom_anchor_set := false  # A wheel zoom is easing toward the pointer
var _zoom_anchor_world := Vector2.ZERO  # The map point under the pointer when the wheel turned
var _zoom_anchor_offset := Vector2.ZERO  # The pointer from the view's centre (viewport px)

# The settings, read twice a second (get_settings copies them), and the cursor confined to match.
func _read_camera_settings(delta: float) -> void:
	_settings_check -= delta
	if _settings_check > 0.0:
		return
	_settings_check = 0.5
	var settings := HeartwoodMemory.get_settings()
	_edge_scroll = bool(settings.get(EDGE_SETTING, true))
	_edge_speed = clampf(float(settings.get(EDGE_SPEED_SETTING, 1.0)), 0.25, 1.0)
	_update_confine()

# Edge scrolling is live: the setting is on, a real focused window, and not a touch device.
func _edge_active() -> bool:
	return _edge_scroll and DisplayServer.get_name() != "headless" and get_window().has_focus() and not InputMode.touch()

# Fullscreen with edge scrolling: the cursor can't leave the window (a second monitor). Released when either ends,
# and only ever undone by the node that set it.
func _update_confine() -> void:
	var want := _edge_active() and get_window().mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]
	if want and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
		_confined = true
	elif not want and _confined:
		if Input.mouse_mode == Input.MOUSE_MODE_CONFINED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_confined = false

func _exit_tree() -> void:
	if _confined and Input.mouse_mode == Input.MOUSE_MODE_CONFINED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_confined = false

# The player moves the view by `by` (map px): at once, ending any glide or zoom-to-pointer.
func _pan_now(by: Vector2) -> void:
	target_position += by
	_snap = true
	_glide_points = PackedVector2Array()
	_zoom_anchor_set = false

# The pointer within EDGE_MARGIN of a window edge pans that way, at the keyboard's speed × the setting.
func _edge_scroll_pan(delta: float) -> void:
	if _dragging or not _glide_points.is_empty() or not _edge_active() or modal_open():
		return  # (A glide, the first-run tour or a jump to a Warden, isn't cut short by a pointer resting at an edge)
	var window := get_window()
	if not Rect2i(window.position, window.size).has_point(DisplayServer.mouse_get_position()):
		return  # The pointer left the window (windowed mode): no scrolling from its last position
	var view := get_viewport().get_visible_rect().size
	var mouse := get_viewport().get_mouse_position()
	var direction := Vector2.ZERO
	if mouse.x <= EDGE_MARGIN:
		direction.x -= 1.0
	elif mouse.x >= view.x - 1.0 - EDGE_MARGIN:
		direction.x += 1.0
	if mouse.y <= EDGE_MARGIN:
		direction.y -= 1.0
	elif mouse.y >= view.y - 1.0 - EDGE_MARGIN:
		direction.y += 1.0
	if direction != Vector2.ZERO:
		_pan_now(direction.normalized() * camera_speed * _edge_speed * delta)

# Middle-mouse drag: the map follows the pointer (started on the map in _unhandled_input; motion read here so it
# keeps going over a panel).
func _input(event: InputEvent) -> void:
	if not _dragging or not event is InputEventMouseMotion:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or modal_open():
		_dragging = false
		return
	_pan_now(-(event as InputEventMouseMotion).relative / camera_2d.zoom)

# While a wheel zoom eases, the map point that was under the pointer stays under it.
func _follow_zoom_anchor() -> void:
	if not _zoom_anchor_set:
		return
	target_position = _zoom_anchor_world - _zoom_anchor_offset / camera_2d.zoom
	_clamp_camera_to_map()
	camera_2d.position = target_position
	if _view_zoom.is_equal_approx(target_zoom):
		_zoom_anchor_set = false

func _advance_glide(delta: float) -> void:
	for action in ["move_camera_up", "move_camera_down", "move_camera_left", "move_camera_right"]:
		if Input.is_action_pressed(action):
			_glide_points = PackedVector2Array()  # The player takes over
			return
	_glide_time += delta
	var t := clampf(_glide_time / _glide_duration, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)  # Smoothstep: no snap at the start, no jolt at the end
	var along := eased * _glide_lengths[-1]
	var i := 0
	while i < _glide_points.size() - 2 and _glide_lengths[i + 1] < along:
		i += 1
	var span := _glide_lengths[i + 1] - _glide_lengths[i]
	target_position = _glide_points[i].lerp(_glide_points[i + 1], (along - _glide_lengths[i]) / span if span > 0.0 else 1.0)
	if t >= 1.0:
		_glide_points = PackedVector2Array()

# H / F: centre on the Heartwood / on the forest's edge.
func _unhandled_input(event: InputEvent) -> void:
	# Middle mouse pressed on the map (not over a panel: the UI takes those) starts a drag; its release ends it.
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_MIDDLE:
		_dragging = (event as InputEventMouseButton).pressed and not modal_open()
		return
	var map_generator = get_node_or_null("%MapGenerator")
	if map_generator == null:
		return
	if event.is_action_pressed("center_heartwood"):
		target_position = MAP_GRID.calculate_map_position(map_generator.endPath)
		_glide_points = PackedVector2Array()
		_zoom_anchor_set = false
	elif event.is_action_pressed("center_start"):
		target_position = MAP_GRID.calculate_map_position(map_generator.startPath)
		_glide_points = PackedVector2Array()
		_zoom_anchor_set = false
	# Wheel zoom here, not polled: a wheel over a panel (the Codex, Dreams this run, settings …) is
	# used by the UI and never reaches this (screens_ui.md: UI scrolling never moves the map).
	elif event.is_action_pressed("zoom_in") and not modal_open():
		zoom_by_step(1.0, true)
	elif event.is_action_pressed("zoom_out") and not modal_open():
		zoom_by_step(-1.0, true)

# `toward_pointer` (the wheel): the map point under the pointer stays under it while the zoom eases.
func zoom_by_step(direction: float, toward_pointer := false) -> void:
	var zoom_min := _get_zoom_out_min()
	target_zoom = (target_zoom * pow(zoom_step, direction)).clamp(Vector2.ONE * zoom_min,
		Vector2.ONE * maxf(camera_zoom_in_max, zoom_min))
	if toward_pointer and DisplayServer.get_name() != "headless":  # (Headless has no pointer: tests zoom on the centre)
		_zoom_anchor_offset = get_viewport().get_mouse_position() - get_viewport().get_visible_rect().size / 2.0
		_zoom_anchor_world = camera_2d.position + _zoom_anchor_offset / camera_2d.zoom
		_zoom_anchor_set = true
		_glide_points = PackedVector2Array()

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
	var dreams := main.get_node_or_null("HUD/DreamsRow")  # Phones: "Dreams this run" is a full-screen page (Mobile UI)
	if dreams != null and bool(dreams.get("strip_hidden")):
		var list := dreams.get("_list") as CanvasItem
		if list != null and list.is_visible_in_tree():
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
		_pan_now(direction.normalized() * camera_speed * delta)  # WASD and the arrows: one speed, no easing
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
	if _snap:  # The player is panning (keys, edge, drag): immediate, so nothing drifts on after release
		camera_2d.position = target_position
		return
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
