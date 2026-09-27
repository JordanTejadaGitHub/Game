extends Node2D
class_name TowerSeller

# Outside build mode: hovering a Warden shows what selling it would refund; right-click (or Delete)
# sells it. Refund = all Dew invested in it: 100% in the build phase, 50% during a drift.
# Selling only ever opens paths, so it's always allowed; creatures re-route right away.

signal tower_sold(tower: Tower, refund: int)

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const NO_CELL := Vector2(-1, -1)
const HIGHLIGHT_COLOR := Color(0.55, 0.85, 1.0)

@export var build_phase_refund: float = 1.0
@export var drift_refund: float = 0.5

@onready var map_generator = %MapGenerator
@onready var tower_container: Node2D = %TowerContainer
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var drift_director: DriftDirector = %DriftDirector
@onready var run_state: RunState = %RunState

var active := true
var _hover_cell := NO_CELL
var _hover_tower: Tower = null

func _ready() -> void:
	# Build mode owns the mouse; selling is available the rest of the time.
	tower_placer.build_mode_changed.connect(func(building: bool) -> void: set_active(not building))
	# The refund changes when a drift starts or ends.
	drift_director.build_phase_changed.connect(queue_redraw.unbind(1))

func set_active(value: bool) -> void:
	active = value
	visible = value
	_hover_cell = NO_CELL
	_hover_tower = null

# Dew that selling `tower` gives back right now.
func get_refund(tower: Tower) -> int:
	var share := build_phase_refund if drift_director.is_build_phase() else drift_refund
	return int(tower.invested_dew * share)

func get_tower_at(cell: Vector2) -> Tower:
	for tower in tower_container.get_children():
		if tower is Tower and tower.cell == cell and not tower.is_queued_for_deletion():
			return tower
	return null

# Sells the Warden on `cell`. Returns false if there's none.
func sell(cell: Vector2) -> bool:
	var tower := get_tower_at(cell)
	if tower == null:
		return false
	var refund := get_refund(tower)
	tower_container.remove_child(tower)
	tower.queue_free()
	map_generator.unblock_cell(cell)  # Emits path_changed -> creatures re-route
	run_state.earn_dew_at(refund, MAP_GRID.calculate_map_position(cell))
	tower_sold.emit(tower, refund)
	_hover_tower = null
	queue_redraw()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if active and event.is_action_pressed("sell_tower") and _hover_tower != null:
		sell(_hover_cell)
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not active:
		return
	var cell: Vector2 = MAP_GRID.calculate_grid_coordinates(get_global_mouse_position())
	if cell != _hover_cell:
		_hover_cell = cell
		_hover_tower = get_tower_at(cell)
		queue_redraw()

func _draw() -> void:
	if _hover_tower == null:
		return
	var center: Vector2 = MAP_GRID.calculate_map_position(_hover_cell)
	var rect := Rect2(center - MAP_GRID.cell_size / 2, MAP_GRID.cell_size).grow(-2)
	draw_rect(rect, HIGHLIGHT_COLOR, false, 2.0)
	var label := "Right-click: sell %s · +%d Dew" % [_hover_tower.tower_data.display_name,
		get_refund(_hover_tower)]
	WorldLabel.draw_tag(self, center.x, rect.position.y - 8, label)
