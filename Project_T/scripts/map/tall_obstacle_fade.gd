class_name TallObstacleFade
extends Node

# Withered Trees overhang the cell above them (96×128). Like tall Wardens (Tower._update_tall_fade) and the
# inland Heartwood's canopy, a tree's overhang fades to EnvironmentTiles.FADE_ALPHA while a Warden, a
# nightmare, the build ghost or the hovered / selected cell is in the cell above it, and comes back once
# clear. The fade is a tile alternative (EnvironmentTiles._add_fade_alternatives), stepped one level every
# STEP_TIME. Made by MapGenerator. Warden cells (every whole cell any of its half cells touches) are cached
# (refreshed when one is planted or sold);
# nightmares, hover and selection are checked CHECK_EVERY seconds, only against the cells below them.

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const CHECK_EVERY := 0.1  # s
const STEP_TIME := 0.05  # s per fade step

var map: Node  # MapGenerator
var tower_container: Node
var enemy_container: Node
var _warden_cells := {}  # {cell: true} under every Warden (refreshed on plant / sell)
var _behind := {}  # {tree cell: target fade step}: something is in the cell above it now
var _levels := {}  # {tree cell: fade step 1..FADE_STEPS}: trees not fully shown
var _check := 0.0
var _step := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Wardens are planted, sold and selected while paused
	if tower_container != null:
		tower_container.child_entered_tree.connect(func(_n: Node) -> void: _refresh_wardens.call_deferred())
		tower_container.child_exiting_tree.connect(func(_n: Node) -> void: _refresh_wardens.call_deferred())
	_refresh_wardens()

func _refresh_wardens() -> void:
	_warden_cells.clear()
	if tower_container == null:
		return
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion():
			for cell in whole_cells_of(tower):
				_warden_cells[cell] = true
	_check = 0.0

func _process(delta: float) -> void:
	_check -= delta
	if _check <= 0.0:
		_check = CHECK_EVERY
		_find_behind()
	_step -= delta
	if _step > 0.0:
		return
	_step = STEP_TIME
	for cell in _behind:  # A step toward its target (deeper for a Warden behind)
		var level: int = _levels.get(cell, 0)
		var target: int = _behind[cell]
		if level != target and _set_level(cell, level + signi(target - level)):
			_levels[cell] = level + signi(target - level)
	for cell in _levels.keys():  # Come back a step
		if _behind.has(cell):
			continue
		var level: int = _levels[cell] - 1
		if not _set_level(cell, level) or level <= 0:
			_levels.erase(cell)
		else:
			_levels[cell] = level

# The trees with something in the cell above them.
func _find_behind() -> void:
	_behind.clear()
	for cell in _warden_cells:
		_mark(cell, EnvironmentTiles.FADE_STEP_WARDEN)
	if enemy_container != null and enemy_container.has_method("get_enemies"):
		for enemy: Node2D in enemy_container.get_enemies():
			_mark(MAP_GRID.calculate_grid_coordinates(enemy.position))
	var seller: TowerSeller = Tower.seller_ref.get_ref() if Tower.seller_ref != null else null
	if seller != null:
		_mark(seller._hover_cell)
		if is_instance_valid(seller.selected):
			for cell in whole_cells_of(seller.selected):
				_mark(cell)
	var placer: TowerPlacer = Tower.placer_ref.get_ref() if Tower.placer_ref != null else null
	if placer != null and placer.build_mode:
		if placer.half_placement() and placer._hover_half != TowerPlacer.NO_CELL:  # The ghost at a half offset
			for h in FindPath.halves_of(placer._hover_half):
				_mark((h / 2.0).floor())
		else:
			_mark(placer._hover_cell)

# The whole cells a Warden touches: every whole cell under any of its half cells (a half-offset Warden
# straddles up to 4).
static func whole_cells_of(tower: Tower) -> Array[Vector2]:
	var cells: Array[Vector2] = []
	for h in tower.get_halves():
		var cell := (h / 2.0).floor()
		if not cells.has(cell):
			cells.append(cell)
	return cells

# `cell` holds something to see: the tree below it (if any) fades to step `level` (or deeper, if already asked).
func _mark(cell: Vector2, level: int = EnvironmentTiles.FADE_STEP_SEEN) -> void:
	var tree := cell + Vector2.DOWN
	if map.environment_object_layer.get_cell_source_id(Vector2i(tree)) == EnvironmentTiles.WITHERED_TREE:
		_behind[tree] = maxi(_behind.get(tree, 0), level)

# Shows the tree on `cell` at fade step `level` (0 = whole). False if there's no tree there any more.
func _set_level(cell: Vector2, level: int) -> bool:
	var layer: TileMapLayer = map.environment_object_layer
	var at := Vector2i(cell)
	if layer.get_cell_source_id(at) != EnvironmentTiles.WITHERED_TREE:
		_levels.erase(cell)
		return false
	layer.set_cell(at, EnvironmentTiles.WITHERED_TREE, layer.get_cell_atlas_coords(at), level)
	return true

func get_level(cell: Vector2) -> int:
	return _levels.get(cell, 0)
