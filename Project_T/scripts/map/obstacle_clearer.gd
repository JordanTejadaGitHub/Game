extends Node2D
class_name ObstacleClearer

# The Clear tool (screens_ui.md "The Clear tool"): trees and rocks are cleared through a tool on the
# Warden bar (Main's button, hotkeys 0 / C → set_tool_active). While the tool is active, hovering an
# obstacle shows its outline, cost (or "free") and the route that would open; a click clears it, and
# the tool stays on for more clears until Esc / right-click / picking a Warden. Without the tool,
# hovering only names the obstacle and clicks pass through (box-select can start anywhere).
# Until the run's first clearing Dream (DreamState.can_clear) the tool can't be switched on.
# Touch: the first tap marks the obstacle (pending), a second tap on it or confirm_pending() clears.

# The hovered obstacle changed (null = none); `locked`: clearing isn't unlocked yet (whispers).
signal obstacle_hovered(data: ObstacleData, locked: bool)
signal tool_changed(active: bool)
# The tool was asked for while clearing is still locked (the bar explains why).
signal tool_refused
# Clearing became possible (false) this run, after the first clearing Dream; true = locked again.
signal lock_changed(locked: bool)
# Touch: an obstacle is waiting for its ✓ (`cell` = NO_CELL when the pending clear is dropped).
signal clear_pending(cell: Vector2)

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const NO_CELL := Vector2(-1, -1)
const HIGHLIGHT_COLOR := Color(1.0, 0.85, 0.4)
const LOCKED_COLOR := Color(0.78, 0.78, 0.8)
const NAME_COLOR := Color(0.92, 0.92, 0.88)

@onready var map_generator = %MapGenerator
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var run_state: RunState = %RunState

var active := true  # Not in build mode (build mode owns the mouse)
var tool_active := false
# Touch devices confirm a clear (tap, then ✓ or a second tap); mouse clicks clear at once.
var confirm_clears := DisplayServer.is_touchscreen_available()
var pending_cell := NO_CELL
var _hover_cell := NO_CELL
var _hover_obstacle: ObstacleData = null
var _path_preview := Line2D.new()
var _was_locked := true

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
	# Build mode owns left-click; picking a Warden also puts the Clear tool away.
	tower_placer.build_mode_changed.connect(func(building: bool) -> void:
		if building:
			set_tool_active(false)
		set_active(not building))
	# A clearing Dream unlocks clearing: the hover changes from locked to its price.
	var dreams := get_node_or_null("%DreamState") as DreamState
	if dreams:
		dreams.card_taken.connect(func(_card: UpgradeData) -> void:
			_check_lock()
			_refresh_hover())
		dreams.unlocks_changed.connect(_check_lock)  # Save loads, Test Grove
	_check_lock.call_deferred()

func set_active(value: bool) -> void:
	active = value
	visible = value
	_hover_cell = NO_CELL
	_refresh_hover()

# Switches the Clear tool on or off. Returns whether it's on afterwards (refused while locked).
func set_tool_active(on: bool) -> bool:
	if on and is_locked():
		tool_refused.emit()
		on = false
	if on and tower_placer.build_mode:
		tower_placer.set_build_mode(false)
	_set_pending(NO_CELL)
	if on != tool_active:
		tool_active = on
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if on else Input.CURSOR_ARROW)
		tool_changed.emit(on)
	_refresh_hover()
	return tool_active

func is_tool_active() -> bool:
	return tool_active

func _unhandled_input(event: InputEvent) -> void:
	if not active or not tool_active:
		return  # Without the tool, obstacles only show their name; clicks pass through
	if event.is_action_pressed("cancel_build"):
		set_tool_active(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("clear_obstacle") and _hover_obstacle != null:
		if confirm_clears and pending_cell != _hover_cell:
			_set_pending(_hover_cell)  # Touch: wait for the ✓ (or a second tap)
		else:
			_set_pending(NO_CELL)
			try_clear(_hover_cell)
		get_viewport().set_input_as_handled()

# Touch: the ✓ for the pending obstacle.
func confirm_pending() -> bool:
	var cell := pending_cell
	_set_pending(NO_CELL)
	return cell != NO_CELL and try_clear(cell)

func _set_pending(cell: Vector2) -> void:
	if cell != pending_cell:
		pending_cell = cell
		clear_pending.emit(cell)
		queue_redraw()

func _check_lock() -> void:
	var locked := is_locked()
	if locked != _was_locked:
		_was_locked = locked
		lock_changed.emit(locked)
		if locked and tool_active:
			set_tool_active(false)

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
	if not tool_active:
		WorldLabel.draw_tag(self, center.x, rect.position.y - 8, _hover_obstacle.display_name, NAME_COLOR)
		return
	var free := run_state.free_clears > 0
	var cost := get_clear_cost(_hover_obstacle)
	var affordable := free or run_state.can_afford(cost)
	var highlight := HIGHLIGHT_COLOR if affordable else WorldLabel.UNAFFORDABLE_COLOR
	draw_rect(rect, Color(highlight, 0.15))
	draw_rect(rect, highlight, false, 3.0)

	var price := "free (%d left)" % run_state.free_clears if free else "%d Dew" % cost
	var label := "%s %s · %s" % [_hover_obstacle.clear_verb, _hover_obstacle.display_name, price]
	if pending_cell == _hover_cell:
		label += "  ·  tap ✓ to clear"
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
# (The tool decides when the player may click; Dreams and tests call this directly.)
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
	if pending_cell != NO_CELL and map_generator.get_obstacle(pending_cell) == null:
		_set_pending(NO_CELL)
	_path_preview.clear_points()
	RouteLine.apply(_path_preview, Color(HIGHLIGHT_COLOR, 0.6))
	if _hover_obstacle != null and tool_active:
		# Only preview when clearing actually changes the route creatures take.
		var new_path: PackedVector2Array = map_generator.get_path_if_cleared(_hover_cell)
		if new_path != map_generator.get_path_from(map_generator.startPath):
			for point in new_path:
				_path_preview.add_point(MAP_GRID.calculate_map_position(point))
	queue_redraw()
