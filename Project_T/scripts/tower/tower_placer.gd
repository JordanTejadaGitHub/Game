extends Node2D
class_name TowerPlacer

# Build mode: shows a ghost tower snapped to the hovered cell (green = can build, red = can't or
# can't afford) with its Dew cost, and a preview of the route enemies would take.
# Left-click builds, right-click / Esc exits, B toggles.

signal build_mode_changed(active: bool)
signal tower_built(tower: Tower)
# A placement was refused because of the cell (a nightmare on it, or it would close the path).
# Not affording it emits RunState.dew_short instead.
signal build_rejected(cell: Vector2)

@export var tower_scene: PackedScene = preload("res://scenes/tower/tower.tscn")
# Wardens that can be planted directly. Only the ones DreamState has unlocked show in the tower bar.
@export var towers: Array[TowerData] = [
	preload("res://resource/tower/sprout.tres"),
	preload("res://resource/tower/thornwall.tres"),
	preload("res://resource/tower/sporeling.tres"),
	preload("res://resource/tower/pebbling.tres"),
	preload("res://resource/tower/dewdrop.tres"),
	preload("res://resource/tower/firefly_jar.tres"),
	preload("res://resource/tower/rootling.tres"),
	preload("res://resource/tower/acorn.tres"),
	preload("res://resource/tower/bellflower.tres"),
	preload("res://resource/tower/nestling.tres"),
	preload("res://resource/tower/whirligig.tres"),
	# Memory Wardens (one of each per run)
	preload("res://resource/tower/white_stag.tres"),
	preload("res://resource/tower/pond_keeper.tres"),
	preload("res://resource/tower/moon_moth.tres"),
]
# The tower that will be built (the last one selected; the first in `towers` to begin with).
var tower_data: TowerData

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const VALID_TINT := Color(0.4, 1.0, 0.5, 0.65)
const INVALID_TINT := Color(1.0, 0.35, 0.35, 0.65)
const NO_CELL := Vector2(-1, -1)

@onready var map_generator = %MapGenerator
@onready var tower_container: Node2D = %TowerContainer
@onready var enemy_spawner = %EnemyContainer
@onready var run_state: RunState = %RunState
@onready var dream_state: DreamState = %DreamState

var build_mode := false
var _hover_cell := NO_CELL
# Route enemies would take if a tower were built on the hovered cell (empty = it would block them).
var _hover_path := PackedVector2Array()
var _hover_valid := false  # The cell itself allows building (ignores cost)
var _hover_affordable := false
var _path_preview := Line2D.new()
const PREVIEW_COLOR := Color(0.4, 0.9, 1.0, 0.6)  # The route preview (RouteLine: high-contrast setting)

func _ready() -> void:
	tower_data = towers[0]
	_path_preview.width = 6.0
	_path_preview.default_color = PREVIEW_COLOR
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

# Picks the tower to build and enters build mode.
func select_tower(data: TowerData) -> void:
	tower_data = data
	set_build_mode(true)
	queue_redraw()

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
	var valid := not _hover_path.is_empty() and not _is_occupied_by_enemy(_hover_cell) \
		and not is_unique_placed(tower_data)
	# Dew changes while hovering (creatures get cleansed), so re-check affordability too.
	var affordable := run_state.can_afford(get_cost(null, _hover_cell))
	if valid != _hover_valid or affordable != _hover_affordable:
		_hover_valid = valid
		_hover_affordable = affordable
		queue_redraw()

func _draw() -> void:
	if _hover_cell == NO_CELL or not MAP_GRID.is_within_bounds(_hover_cell):
		return
	draw_set_transform(MAP_GRID.calculate_map_position(_hover_cell))
	var tint := VALID_TINT if _hover_valid and _hover_affordable else INVALID_TINT
	if tower_data.can_attack:
		var range_pixels := Tower.range_to_pixels(Tower.get_range_for(tower_data, dream_state))
		draw_circle(Vector2.ZERO, range_pixels, Color(tint, 0.12))
		draw_arc(Vector2.ZERO, range_pixels, 0.0, TAU, 64, Color(tint, 0.5), 2.0)
	if tower_data.texture == null:
		Tower.draw_placeholder(self, tint)
	else:
		var frame := tower_data.get_frame_rect(0)
		draw_texture_rect_region(tower_data.texture, Rect2(-frame.size / 2.0, frame.size), frame, tint)
	var tag := "%s · %d Dew" % [tower_data.display_name, get_cost(null, _hover_cell)]
	if run_state.fertile_cells.has(_hover_cell):
		tag += " (fertile)"
	var growth := get_hover_path_growth()
	if is_unique_placed(tower_data):
		tag += "  ·  already planted (one per run)"
	elif hover_breaks_path():
		tag += "  ·  would close the dream"  # The forest's rule: it may bend, never close
	elif _is_occupied_by_enemy(_hover_cell):
		tag += "  ·  nightmare here"
	elif growth != 0:
		tag += "  ·  %+d path" % growth  # "Wardens are walls": how much longer the walk gets
	WorldLabel.draw_tag(self, 0.0, MAP_GRID.cell_size.y / 2.0 + 18.0, tag,
		WorldLabel.cost_color(_hover_affordable))

# How many tiles longer creatures would walk if the ghost were built (0 if it can't be).
func get_hover_path_growth() -> int:
	if _hover_path.is_empty():
		return 0
	return _hover_path.size() - map_generator.get_path_from(map_generator.startPath).size()

# The hovered cell is free but building there would cut creatures off (the forest's rule).
func hover_breaks_path() -> bool:
	return build_mode and _hover_cell != NO_CELL and map_generator.is_buildable(_hover_cell) \
		and _hover_path.is_empty()

# Recomputes the route preview for the hovered cell (only needed when the cell or the maze changes).
func _refresh_hover() -> void:
	_hover_path = PackedVector2Array()
	if map_generator.is_buildable(_hover_cell):
		_hover_path = map_generator.get_path_if_blocked(_hover_cell)
	_path_preview.clear_points()
	RouteLine.apply(_path_preview, PREVIEW_COLOR)
	for point in _hover_path:
		_path_preview.add_point(MAP_GRID.calculate_map_position(point))
	_hover_valid = not _hover_path.is_empty() and not _is_occupied_by_enemy(_hover_cell) \
		and not is_unique_placed(tower_data)
	_hover_affordable = run_state.can_afford(get_cost(null, _hover_cell))
	queue_redraw()

# Memory Wardens are one per run: true if `data` is one and it's already on the map.
func is_unique_placed(data: TowerData) -> bool:
	if not data.is_unique:
		return false
	for tower in tower_container.get_children():
		if tower is Tower and tower.tower_data == data and not tower.is_queued_for_deletion():
			return true
	return false

# Builds a tower on `cell` and charges its Dew cost. Returns false (and charges nothing) if the cell
# can't be built on or the player can't afford it.
func _try_build(cell: Vector2) -> bool:
	if is_unique_placed(tower_data):
		build_rejected.emit(cell)
		return false
	if _is_occupied_by_enemy(cell):
		build_rejected.emit(cell)
		return false
	# Every enemy on the field must still be able to reach the end, not just new spawns.
	var enemy_cells := PackedVector2Array()
	for enemy in enemy_spawner.get_maze_walkers():
		enemy_cells.append(enemy.get_target_cell())
	if not map_generator.can_block(cell, enemy_cells):
		build_rejected.emit(cell)
		return false
	var cost := get_cost(null, cell)
	if not run_state.spend_dew(cost):
		return false
	run_state.fertile_cells.erase(cell)  # Only the first Warden gets the fertile price

	var tower: Tower = tower_scene.instantiate()
	tower.tower_data = tower_data
	tower.cell = cell
	tower.invested_dew = cost
	tower.position = MAP_GRID.calculate_map_position(cell)
	tower_container.add_child(tower)
	map_generator.block_cell(cell)  # Emits path_changed -> enemies re-route, preview refreshes
	tower_built.emit(tower)
	return true

# Dew to plant the selected Warden (Dreams can change it, e.g. Cheap Hedges). With `cell`, the price
# on that cell (Reclaimed Earth: fertile cells halve the first Warden).
func get_cost(data: TowerData = null, cell: Vector2 = NO_CELL) -> int:
	var warden := data if data != null else tower_data
	if cell == NO_CELL:
		return dream_state.get_build_cost(warden)
	return dream_state.get_build_cost_at(warden, cell)

# Wardens that can be planted right now (unlocked this run), in roster order.
func get_buildable_towers() -> Array[TowerData]:
	var result: Array[TowerData] = []
	for data in towers:
		if dream_state.is_buildable(data):
			result.append(data)
	return result

# Grows `tower` into `into` in place, if that evolution is unlocked and affordable. The path never
# changes, so evolving is always allowed, including mid-drift and while paused.
func evolve(tower: Tower, into: TowerData) -> bool:
	if not tower.tower_data.evolves_to.has(into) or not dream_state.is_unlocked(into.get_id()):
		return false
	var cost := dream_state.get_evolve_cost(into)
	if not run_state.spend_dew(cost):
		return false
	tower.evolve(into, cost)
	return true

# Nurtures `tower` one rank (warden_stats.md "Nurture v2"), if it can go higher and the player can
# afford it. The rank that asks for a Focus (III) needs `focus`; without one it refuses. Ranks never
# change the path, so this is always allowed, like evolving.
func nurture(tower: Tower, focus: Tower.Focus = Tower.Focus.NONE) -> bool:
	if not is_instance_valid(tower) or not tower.can_nurture():
		return false
	if tower.needs_focus() and focus == Tower.Focus.NONE:
		return false
	var cost := tower.get_nurture_cost()
	if not run_state.spend_dew(cost):
		return false
	if "rank_dew_spent" in run_state:
		run_state.rank_dew_spent += cost  # Nurture Dream openers look at this
	tower.nurture(cost, focus)
	return true

# True if an enemy is standing in, or walking into, `cell`.
func _is_occupied_by_enemy(cell: Vector2) -> bool:
	for enemy in enemy_spawner.get_maze_walkers():
		if enemy.get_current_cell() == cell or enemy.get_target_cell() == cell:
			return true
	return false
