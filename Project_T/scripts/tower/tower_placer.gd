extends Node2D
class_name TowerPlacer

# Build mode: shows a ghost tower snapped to the hovered cell (green = can build, red = can't) and a
# preview of the route enemies would take. Left-click builds, right-click / Esc exits, B toggles.

signal build_mode_changed(active: bool)
signal tower_built(tower: Tower)

@export var tower_scene: PackedScene = preload("res://scenes/tower/tower.tscn")
@export var tower_data: TowerData = preload("res://resource/tower/stone_tower.tres")

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const VALID_TINT := Color(0.4, 1.0, 0.5, 0.65)
const INVALID_TINT := Color(1.0, 0.35, 0.35, 0.65)
const NO_CELL := Vector2(-1, -1)

@onready var map_generator = %MapGenerator
@onready var tower_container: Node2D = %TowerContainer
@onready var enemy_spawner = %EnemyContainer

var build_mode := false
var _hover_cell := NO_CELL
# Route enemies would take if a tower were built on the hovered cell (empty = it would block them).
var _hover_path := PackedVector2Array()
var _hover_valid := false
var _path_preview := Line2D.new()

func _ready() -> void:
	_path_preview.width = 6.0
	_path_preview.default_color = Color(0.4, 0.9, 1.0, 0.6)
	_path_preview.joint_mode = Line2D.LINE_JOINT_ROUND
	_path_preview.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_path_preview.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_path_preview)
	# Another tower changing the maze invalidates the preview for the hovered cell.
	map_generator.path_changed.connect(_refresh_hover)
	set_build_mode(false)

func set_build_mode(active: bool) -> void:
	build_mode = active
	visible = active
	_hover_cell = NO_CELL
	build_mode_changed.emit(active)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_build_mode"):
		set_build_mode(not build_mode)
		get_viewport().set_input_as_handled()
	elif not build_mode:
		return
	elif event.is_action_pressed("cancel_build"):
		set_build_mode(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("place_tower"):
		_try_build(_hover_cell)
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not build_mode:
		return
	var cell: Vector2 = MAP_GRID.calculate_grid_coordinates(get_global_mouse_position())
	if cell != _hover_cell:
		_hover_cell = cell
		_refresh_hover()
	# Enemies move every frame, so re-check whether one is standing on the hovered cell.
	var valid := not _hover_path.is_empty() and not _is_occupied_by_enemy(_hover_cell)
	if valid != _hover_valid:
		_hover_valid = valid
		queue_redraw()

func _draw() -> void:
	if _hover_cell == NO_CELL or not MAP_GRID.is_within_bounds(_hover_cell):
		return
	draw_set_transform(MAP_GRID.calculate_map_position(_hover_cell))
	var tint := VALID_TINT if _hover_valid else INVALID_TINT
	var range_pixels := Tower.range_to_pixels(tower_data.attack_range)
	draw_circle(Vector2.ZERO, range_pixels, Color(tint, 0.12))
	draw_arc(Vector2.ZERO, range_pixels, 0.0, TAU, 64, Color(tint, 0.5), 2.0)
	Tower.draw_placeholder(self, tint)

# Recomputes the route preview for the hovered cell (only needed when the cell or the maze changes).
func _refresh_hover() -> void:
	_hover_path = PackedVector2Array()
	if map_generator.is_buildable(_hover_cell):
		_hover_path = map_generator.get_path_if_blocked(_hover_cell)
	_path_preview.clear_points()
	for point in _hover_path:
		_path_preview.add_point(MAP_GRID.calculate_map_position(point))
	_hover_valid = not _hover_path.is_empty() and not _is_occupied_by_enemy(_hover_cell)
	queue_redraw()

func _try_build(cell: Vector2) -> void:
	if _is_occupied_by_enemy(cell):
		return
	# Every enemy on the field must still be able to reach the end, not just new spawns.
	var enemy_cells := PackedVector2Array()
	for enemy in enemy_spawner.get_enemies():
		enemy_cells.append(enemy.get_target_cell())
	if not map_generator.can_block(cell, enemy_cells):
		return

	var tower: Tower = tower_scene.instantiate()
	tower.tower_data = tower_data
	tower.cell = cell
	tower.position = MAP_GRID.calculate_map_position(cell)
	tower_container.add_child(tower)
	map_generator.block_cell(cell)  # Emits path_changed -> enemies re-route, preview refreshes
	tower_built.emit(tower)

# True if an enemy is standing in, or walking into, `cell`.
func _is_occupied_by_enemy(cell: Vector2) -> bool:
	for enemy in enemy_spawner.get_enemies():
		if enemy.get_current_cell() == cell or enemy.get_target_cell() == cell:
			return true
	return false
