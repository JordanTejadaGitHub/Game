extends Node2D
class_name ObstacleClearer

# Outside build mode: hovering a tree/rock highlights it with its clear cost and previews the route
# creatures would take once it's gone. Left-click clears it.

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const NO_CELL := Vector2(-1, -1)
const HIGHLIGHT_COLOR := Color(1.0, 0.85, 0.4)
const LABEL_FONT_SIZE := 14

@onready var map_generator = %MapGenerator
@onready var tower_placer: TowerPlacer = %TowerPlacer

var active := true
var _hover_cell := NO_CELL
var _hover_obstacle: ObstacleData = null
var _path_preview := Line2D.new()

func _ready() -> void:
	_path_preview.width = 6.0
	_path_preview.default_color = Color(HIGHLIGHT_COLOR, 0.6)
	_path_preview.joint_mode = Line2D.LINE_JOINT_ROUND
	_path_preview.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_path_preview.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_path_preview)
	map_generator.path_changed.connect(_refresh_hover)
	# Build mode owns left-click; clearing is available the rest of the time.
	tower_placer.build_mode_changed.connect(func(building: bool) -> void: set_active(not building))

func set_active(value: bool) -> void:
	active = value
	visible = value
	_hover_cell = NO_CELL
	_refresh_hover()

func _unhandled_input(event: InputEvent) -> void:
	if active and event.is_action_pressed("clear_obstacle") and _hover_obstacle != null:
		try_clear(_hover_cell)
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not active:
		return
	var cell: Vector2 = MAP_GRID.calculate_grid_coordinates(get_global_mouse_position())
	if cell != _hover_cell:
		_hover_cell = cell
		_refresh_hover()

func _draw() -> void:
	if _hover_obstacle == null:
		return
	var center: Vector2 = MAP_GRID.calculate_map_position(_hover_cell)
	var rect := Rect2(center - MAP_GRID.cell_size / 2, MAP_GRID.cell_size).grow(-2)
	draw_rect(rect, Color(HIGHLIGHT_COLOR, 0.15))
	draw_rect(rect, HIGHLIGHT_COLOR, false, 3.0)

	var label := "%s %s · %d Dew" % [_hover_obstacle.clear_verb, _hover_obstacle.display_name,
		_hover_obstacle.clear_cost]
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE)
	var origin := Vector2(center.x - size.x / 2, rect.position.y - 8)
	draw_rect(Rect2(origin + Vector2(-6, -size.y), size + Vector2(12, 6)), Color(0.1, 0.1, 0.12, 0.75))
	draw_string(font, origin, label, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, Color.WHITE)

# Clears the obstacle on `cell`. Returns false if there's nothing to clear.
# TODO: charge `clear_cost` Dew once the economy exists (build order step 2).
func try_clear(cell: Vector2) -> bool:
	var data: ObstacleData = map_generator.get_obstacle(cell)
	if data == null:
		return false
	map_generator.clear_obstacle(cell)  # Emits path_changed -> enemies re-route, hover refreshes
	return true

# Recomputes the highlight and route preview (only needed when the cell or the maze changes).
func _refresh_hover() -> void:
	_hover_obstacle = map_generator.get_obstacle(_hover_cell) if active else null
	_path_preview.clear_points()
	if _hover_obstacle != null:
		# Only preview when clearing actually changes the route creatures take.
		var new_path: PackedVector2Array = map_generator.get_path_if_cleared(_hover_cell)
		if new_path != map_generator.get_path_from(map_generator.startPath):
			for point in new_path:
				_path_preview.add_point(MAP_GRID.calculate_map_position(point))
	queue_redraw()
