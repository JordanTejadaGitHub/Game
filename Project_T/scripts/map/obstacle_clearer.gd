extends Node2D
class_name ObstacleClearer

# Outside build mode: hovering a tree/rock highlights it with its clear cost and previews the route
# creatures would take once it's gone. Left-click clears it. Until the run's first clearing Dream
# (DreamState.can_clear), hovering only names it: "Needs a clearing Dream", no outline, no route,
# and clicks do nothing.

# The hovered obstacle changed (null = none); `locked`: clearing isn't unlocked yet (whispers).
signal obstacle_hovered(data: ObstacleData, locked: bool)

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const NO_CELL := Vector2(-1, -1)
const HIGHLIGHT_COLOR := Color(1.0, 0.85, 0.4)
const LOCKED_COLOR := Color(0.78, 0.78, 0.8)

@onready var map_generator = %MapGenerator
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var run_state: RunState = %RunState

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
	run_state.dew_changed.connect(func(_dew: int) -> void: queue_redraw())  # Cost label colour
	run_state.free_clears_changed.connect(func(_n: int) -> void: queue_redraw())
	# Build mode owns left-click; clearing is available the rest of the time.
	tower_placer.build_mode_changed.connect(func(building: bool) -> void: set_active(not building))
	# A clearing Dream unlocks clearing: the hover changes from locked to its price.
	var dreams := get_node_or_null("%DreamState") as DreamState
	if dreams:
		dreams.card_taken.connect(_refresh_hover.unbind(1))

func set_active(value: bool) -> void:
	active = value
	visible = value
	_hover_cell = NO_CELL
	_refresh_hover()

func _unhandled_input(event: InputEvent) -> void:
	if active and event.is_action_pressed("clear_obstacle") and _hover_obstacle != null and not is_locked():
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
	if is_locked():
		WorldLabel.draw_tag(self, center.x, rect.position.y - 8,
			"%s · Needs a clearing Dream" % _hover_obstacle.display_name, LOCKED_COLOR)
		return
	var free := run_state.free_clears > 0
	var cost := get_clear_cost(_hover_obstacle)
	var affordable := free or run_state.can_afford(cost)
	var highlight := HIGHLIGHT_COLOR if affordable else WorldLabel.UNAFFORDABLE_COLOR
	draw_rect(rect, Color(highlight, 0.15))
	draw_rect(rect, highlight, false, 3.0)

	var price := "free (%d left)" % run_state.free_clears if free else "%d Dew" % cost
	var label := "%s %s · %s" % [_hover_obstacle.clear_verb, _hover_obstacle.display_name, price]
	WorldLabel.draw_tag(self, center.x, rect.position.y - 8, label, WorldLabel.cost_color(affordable))

# True until the run's first clearing Dream (then clearing works for the rest of the run).
func is_locked() -> bool:
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	return dreams != null and not dreams.can_clear()

# Dew to clear `data` right now (Dreams can lower it). Every clear-cost check goes through here.
func get_clear_cost(data: ObstacleData) -> int:
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	var cost: int = dreams.get_clear_cost(data) if dreams else data.clear_cost
	return roundi(cost * MetaRun.clear_cost_multiplier())  # Blight Level 9: twice as much

# Clears the obstacle on `cell`, using a free clear (Heartwood's Reach) if there is one, else
# charging its Dew cost. Returns false if there's nothing to clear or the player can't afford it.
func try_clear(cell: Vector2) -> bool:
	var data: ObstacleData = map_generator.get_obstacle(cell)
	if data == null or is_locked():
		return false
	if not run_state.use_free_clear() and not run_state.spend_dew(get_clear_cost(data)):
		return false
	map_generator.clear_obstacle(cell)  # Emits path_changed -> enemies re-route, hover refreshes
	return true

# Recomputes the highlight and route preview (only needed when the cell or the maze changes).
func _refresh_hover() -> void:
	var before := _hover_obstacle
	_hover_obstacle = map_generator.get_obstacle(_hover_cell) if active else null
	if _hover_obstacle != before:
		obstacle_hovered.emit(_hover_obstacle, is_locked())
	_path_preview.clear_points()
	RouteLine.apply(_path_preview, Color(HIGHLIGHT_COLOR, 0.6))
	if _hover_obstacle != null and not is_locked():
		# Only preview when clearing actually changes the route creatures take.
		var new_path: PackedVector2Array = map_generator.get_path_if_cleared(_hover_cell)
		if new_path != map_generator.get_path_from(map_generator.startPath):
			for point in new_path:
				_path_preview.add_point(MAP_GRID.calculate_map_position(point))
	queue_redraw()
