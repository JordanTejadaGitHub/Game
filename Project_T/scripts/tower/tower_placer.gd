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
# The Heartwood Sapling was planted (it's rooted: never sold or moved).
signal sapling_planted(tower: Tower)

const SAPLING_ID := "heartwood_sapling"
var sapling: TowerData = preload("res://resource/tower/heartwood_sapling.tres")
var sapling_taken := false
# The Sapling is switched off in runs for now (design chat): never offered. A save that already has one
# planted keeps it. Static so screens outside a run (the Codex) can read it too.
static var sapling_enabled := false

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
const BONUS_ON := Color(0.55, 1.0, 0.6)  # A position card that would be on here
const BONUS_OFF := Color(0.7, 0.72, 0.76)  # …off (grey, with the reason)
const BONUS_LOST := Color(1.0, 0.45, 0.4)  # A planted Warden this placement would switch a card off for
const CHIP_STEP := 20.0

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
var _ghost_rows: Array = []  # The ghost's position cards here (DreamState.get_card_effects rows)
var _neighbour_changes: Array = []  # [[tower, card name, now on], …]
var _range_gain := 0.0  # Cells of range position cards would add here
var _kin_spots := {}  # Cells where the selected Warden would find a kin (Kinships.kin_spots)
var _kin_here := ""  # The Kinship it would form on the hovered cell
const KIN_SPOT_COLOR := Color(0.78, 0.86, 0.42, 0.4)  # Faint green-gold leaf outline
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
	Tower.set_badges_visible(&"build", active)  # Card badges show in build mode
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
	var valid := not _hover_path.is_empty() and not _cells_occupied(_footprint(_hover_cell)) \
		and not is_unique_placed(tower_data)
	# Dew changes while hovering (creatures get cleansed), so re-check affordability too.
	var affordable := run_state.can_afford(get_cost(null, _hover_cell))
	if valid != _hover_valid or affordable != _hover_affordable:
		_hover_valid = valid
		_hover_affordable = affordable
		queue_redraw()

func _draw() -> void:
	_draw_kin_spots()
	if _hover_cell == NO_CELL or not MAP_GRID.is_within_bounds(_hover_cell):
		return
	draw_set_transform(Tower.footprint_centre(_hover_cell, tower_data.footprint))
	var tint := VALID_TINT if _hover_valid and _hover_affordable else INVALID_TINT
	if tower_data.can_attack:
		# The range this Warden would really have on this cell (position cards included). A gain shows
		# as the base range faint and the boosted range bright.
		var base_pixels := Tower.range_to_pixels(Tower.get_range_for(tower_data, dream_state))
		var range_pixels := Tower.range_to_pixels(Tower.get_range_for(tower_data, dream_state) + _range_gain)
		draw_circle(Vector2.ZERO, range_pixels, Color(tint, 0.12))
		if _range_gain > 0.0:
			draw_arc(Vector2.ZERO, base_pixels, 0.0, TAU, 64, Color(tint, 0.22), 1.5)
			draw_arc(Vector2.ZERO, range_pixels, 0.0, TAU, 64, Color(BONUS_ON, 0.85), 2.5)
		else:
			draw_arc(Vector2.ZERO, range_pixels, 0.0, TAU, 64, Color(tint, 0.5), 2.0)
	_draw_card_areas()
	if tower_data.texture == null:
		Tower.draw_placeholder(self, tint)
	else:
		var frame := tower_data.get_frame_rect(0)
		draw_texture_rect_region(tower_data.texture, Rect2(-frame.size / 2.0 + tower_data.sprite_offset, frame.size), frame, tint)
	var tag := "%s · %d Dew" % [tower_data.display_name, get_cost(null, _hover_cell)]
	if run_state.fertile_cells.has(_hover_cell):
		tag += " (fertile)"
	var growth := get_hover_path_growth()
	if is_unique_placed(tower_data):
		tag += "  ·  already planted (one per run)"
	elif hover_breaks_path():
		tag += "  ·  would close the dream"  # The forest's rule: it may bend, never close
	elif _cells_occupied(_footprint(_hover_cell)):
		tag += "  ·  nightmare here"
	elif growth != 0:
		tag += "  ·  %+d path" % growth  # "Wardens are walls": how much longer the walk gets
	if _kin_here != "":
		tag += "  ·  Kin spot: forms %s" % _kin_here
	var broken := get_neighbour_changes().filter(func(change: Array) -> bool: return not change[2])
	if not broken.is_empty():
		# Placing a Warden should never silently weaken others.
		var names := {}
		for change in broken:
			names[change[1]] = names.get(change[1], 0) + 1
		for name in names:
			tag += "  ·  breaks %s on %d Warden%s" % [name, names[name], "" if names[name] == 1 else "s"]
	WorldLabel.draw_tag(self, 0.0, MAP_GRID.cell_size.y / 2.0 + 18.0, tag,
		WorldLabel.cost_color(_hover_affordable))
	# Bonus chips above the ghost: each position card, on (green, what it gives) or off (grey, why).
	var y := -MAP_GRID.cell_size.y / 2.0 - 10.0 + minf(tower_data.sprite_offset.y, 0.0)
	for chip in get_ghost_chips():
		WorldLabel.draw_tag(self, 0.0, y, chip[0], BONUS_ON if chip[1] else BONUS_OFF)
		y -= CHIP_STEP
	# Planted Wardens this placement would switch a card off (red) or on (green) for.
	for change in get_neighbour_changes():
		var tower: Tower = change[0]
		if not is_instance_valid(tower):
			continue
		draw_set_transform(to_local(tower.global_position))
		WorldLabel.draw_tag(self, 0.0, -MAP_GRID.cell_size.y / 2.0 - 6.0,
			("gains %s" if change[2] else "loses %s") % change[1], BONUS_ON if change[2] else BONUS_LOST)
	draw_set_transform(Vector2.ZERO)

# --- Dream bonuses on the ghost (screens_ui.md "Dream bonuses on Wardens") ---

# Chips for the ghost's position cards: [[text, on], …] ("Solitude ✓ +30% damage, +0.5 range" /
# "Solitude ✗ Rain Lily is 1 cell away").
func get_ghost_chips() -> Array:
	var chips := []
	for row in _ghost_rows:
		if row.active:
			chips.append(["%s ✓ %s" % [row.name, row.get("effect", "")], true])
		else:
			chips.append(["%s ✗ %s" % [row.name, row.get("reason", "")], false])
	return chips

# Planted Wardens whose position cards this placement would turn off or on: [[tower, card name, on]].
func get_neighbour_changes() -> Array:
	return _neighbour_changes

# Recomputes the ghost's card rows, its range gain and the neighbour check for the hovered cell (only
# when the cell or the maze changes; the query walks the whole card list).
func _update_dream_preview() -> void:
	_ghost_rows.clear()
	_neighbour_changes.clear()
	_range_gain = 0.0
	if _hover_cell == NO_CELL or not MAP_GRID.is_within_bounds(_hover_cell) \
			or not dream_state.has_method("get_card_effects"):
		return
	for row in dream_state.get_card_effects(tower_data, _hover_cell):
		if row.get("positional", false):
			_ghost_rows.append(row)
	_range_gain = maxf(dream_state.get_range_bonus_at(tower_data, _hover_cell) - dream_state.get_range_bonus(tower_data), 0.0)
	# Kinships: the cells where this Warden would find a kin, and the one it would form here.
	var kin := Kinships.find(self)
	_kin_spots = kin.kin_spots(tower_data) if kin else {}
	_kin_here = kin.preview(tower_data, _hover_cell).get("name", "") if kin else ""
	var reach: float = dream_state.max_card_radius()
	if reach <= 0.0:
		return
	var ghost := {"cell": _hover_cell, "data": tower_data}
	for tower in tower_container.get_children():
		if not tower is Tower or tower.is_queued_for_deletion() \
				or maxf(absf(tower.cell.x - _hover_cell.x), absf(tower.cell.y - _hover_cell.y)) > reach:
			continue
		var before := _active_positional(dream_state.get_card_effects(tower.tower_data, tower.cell, tower))
		var after := _active_positional(dream_state.get_card_effects(tower.tower_data, tower.cell, tower, ghost))
		for name in before:
			if not after.has(name):
				_neighbour_changes.append([tower, name, false])
		for name in after:
			if not before.has(name):
				_neighbour_changes.append([tower, name, true])

static func _active_positional(rows: Array) -> Array:
	var names := []
	for row in rows:
		if row.get("positional", false) and row.active:
			names.append(row.name)
	return names

# Kin spots: a faint leaf-coloured outline on each free cell within reach of an unbonded Warden of the
# selected Warden's other family branch ("plant here to form Night Chimes"). Drawn in world space.
func _draw_kin_spots() -> void:
	if _kin_spots.is_empty() or not build_mode:
		return
	draw_set_transform(Vector2.ZERO)
	var half := MAP_GRID.cell_size / 2.0 - Vector2(5, 5)
	for cell in _kin_spots:
		if not MAP_GRID.is_within_bounds(cell) or not map_generator.is_buildable(cell):
			continue
		var centre := MAP_GRID.calculate_map_position(cell)
		draw_rect(Rect2(centre - half, half * 2.0), KIN_SPOT_COLOR, false, 2.0)
		# A small leaf in the corner.
		var leaf := centre + Vector2(half.x - 7.0, -half.y + 7.0)
		draw_colored_polygon(PackedVector2Array([leaf + Vector2(-4, 3), leaf + Vector2(0, -4), leaf + Vector2(4, 3),
			leaf + Vector2(0, 1)]), Color(KIN_SPOT_COLOR, 0.7))

# A dashed outline of each owned position card's area around the ghost (Solitude's 2 cells), so
# "within 2 cells" is something the player can see. Cells count as a square (Chebyshev).
func _draw_card_areas() -> void:
	var done := {}
	for row in _ghost_rows:
		var radius: float = row.get("radius", 0.0)
		if radius <= 0.0 or done.has(radius):
			continue
		done[radius] = true
		var half := (radius + 0.5) * MAP_GRID.cell_size.x
		var corners := [Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]
		var colour := Color(BONUS_ON if row.active else BONUS_OFF, 0.7)
		for i in 4:
			draw_dashed_line(corners[i], corners[(i + 1) % 4], colour, 2.0, 8.0)

# How many tiles longer creatures would walk if the ghost were built (0 if it can't be).
func get_hover_path_growth() -> int:
	if _hover_path.is_empty():
		return 0
	return _hover_path.size() - map_generator.get_path_from(map_generator.startPath).size()

# The hovered cell is free but building there would cut creatures off (the forest's rule).
func hover_breaks_path() -> bool:
	return build_mode and _hover_cell != NO_CELL \
		and _footprint(_hover_cell).all(func(c: Vector2) -> bool: return map_generator.is_buildable(c)) \
		and _hover_path.is_empty()

# Recomputes the route preview for the hovered cell (only needed when the cell or the maze changes).
func _refresh_hover() -> void:
	_hover_path = PackedVector2Array()
	if _footprint(_hover_cell).all(func(c: Vector2) -> bool: return map_generator.is_buildable(c)):
		_hover_path = map_generator.get_path_if_blocked_cells(_footprint(_hover_cell))
	_path_preview.clear_points()
	RouteLine.apply(_path_preview, PREVIEW_COLOR)
	for point in _hover_path:
		_path_preview.add_point(MAP_GRID.calculate_map_position(point))
	_hover_valid = not _hover_path.is_empty() and not _cells_occupied(_footprint(_hover_cell)) \
		and not is_unique_placed(tower_data)
	_hover_affordable = run_state.can_afford(get_cost(null, _hover_cell))
	_update_dream_preview()
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
	if _cells_occupied(_footprint(cell)):
		build_rejected.emit(cell)
		return false
	# Every enemy on the field must still be able to reach the end, not just new spawns.
	var enemy_cells := PackedVector2Array()
	for enemy in enemy_spawner.get_maze_walkers():
		enemy_cells.append(enemy.get_target_cell())
	if not map_generator.can_block_cells(_footprint(cell), enemy_cells):
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
	tower.position = Tower.footprint_centre(cell, tower_data.footprint)
	tower_container.add_child(tower)
	map_generator.block_cells(_footprint(cell))  # Emits path_changed -> enemies re-route, preview refreshes
	tower_built.emit(tower)
	if tower_data == sapling:
		sapling_planted.emit(tower)
		set_build_mode(false)
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
	if ascended_blocker(into) != "":
		return false  # One Ascended form per family on the map
	var cost: int = tower.get_grow_cost(into).total  # Evolve cost + the rank difference; all invested
	if not run_state.spend_dew(cost):
		return false
	tower.evolve(into, cost)
	return true

# Ascended forms are one per family (tower_design.md): while one is on the map, nothing else can grow
# into it (selling it frees the slot). The reason to show on the Grow button, or "".
func ascended_blocker(into: TowerData) -> String:
	if into.tier < DreamState.ASCENDED_TIER:
		return ""
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() and tower.tower_data.get_id() == into.get_id():
			return "%s is already awake" % into.display_name
	return ""

# Nurtures `tower` one rank (warden_stats.md "Nurture v2"), if it can go higher and the player can
# afford it. The rank that asks for a Focus (III) needs `focus`; without one it refuses. Ranks never
# change the path, so this is always allowed, like evolving.
func nurture(tower: Tower, focus: Tower.Focus = Tower.Focus.NONE) -> bool:
	if not is_instance_valid(tower) or not tower.can_nurture():
		return false
	if tower.needs_focus() and focus == Tower.Focus.NONE:
		return false
	# Rank VI would make it the Eldest (only one Warden grows past V): the panel asks first and calls
	# DreamState.make_eldest; group Nurture and the hotkey never crown one by accident.
	if dream_state.has_method("needs_eldest_confirm") and dream_state.needs_eldest_confirm(tower):
		return false
	var cost := tower.get_nurture_cost()
	if cost == 0 and tower.free_nurtures_left() > 0:
		run_state.free_nurtures -= 1  # First Care: a free rank (nothing invested, nothing refunded)
	elif not run_state.spend_dew(cost):
		return false
	if "rank_dew_spent" in run_state:
		run_state.rank_dew_spent += cost  # Nurture Dream openers look at this
	tower.nurture(cost, focus)
	return true

# The cells the selected Warden would cover with its top-left on `cell` (just `cell` for 1×1).
func _footprint(cell: Vector2) -> Array[Vector2]:
	return Tower.footprint_cells(cell, tower_data.footprint)

func _cells_occupied(cells: Array[Vector2]) -> bool:
	for c in cells:
		if _is_occupied_by_enemy(c):
			return true
	return false

# --- The Heartwood Sapling (offered once after the drift-50 family pick) ---

# The Sapling can be taken (free) once drift 50 has begun, once per run.
func can_take_sapling() -> bool:
	var director := get_node_or_null("%DriftDirector")
	if not sapling_enabled or sapling_taken or director == null:
		return false
	return director.drifts_started >= 50

# Takes the Sapling: it joins the roster for this run and is selected for planting.
func take_sapling() -> void:
	sapling_taken = true
	if not towers.has(sapling):
		towers.append(sapling)
	dream_state.unlocked[SAPLING_ID] = true
	select_tower(sapling)

# Taken but not planted yet (the HUD keeps reminding the player).
func has_unplanted_sapling() -> bool:
	return sapling_enabled and sapling_taken and not is_unique_placed(sapling)

# True if an enemy is standing in, or walking into, `cell`.
func _is_occupied_by_enemy(cell: Vector2) -> bool:
	for enemy in enemy_spawner.get_maze_walkers():
		if enemy.get_current_cell() == cell or enemy.get_target_cell() == cell:
			return true
	return false
