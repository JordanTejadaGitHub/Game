extends Node2D
class_name TowerSeller

# Outside build mode: hovering a Warden highlights it; right-click (or Delete) sells it straight away.
# Selecting (screens_ui.md, "Selecting several Wardens"):
#   click                  one Warden (empty ground clears the selection)
#   click and drag         every Warden in the box (Thornwalls only if the box has nothing else);
#                          the drag starts after DRAG_THRESHOLD px so clicks stay clicks
#   double-click           every Warden of the same kind visible on screen (Ctrl: on the whole map)
#   Shift + click / drag   add to / remove from the selection
#   Esc                    clear
# The Warden panel shows the selection and grows, nurtures (R) or sells it as a group.
# Refund = a share of all Dew invested in it (build, growth, ranks): 75% while resting, 50% during a
# drift (run_design.md difficulty pass v1).
# Selling only ever opens paths, so it's always allowed; creatures re-route right away.

signal tower_sold(tower: Tower, refund: int)
# The Warden the player clicked (null = selection cleared). With several selected: the first one.
signal tower_selected(tower: Tower)
# The selection changed (any number of Wardens).
signal selection_changed(towers: Array[Tower])

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const NO_CELL := Vector2(-1, -1)
const HIGHLIGHT_COLOR := Color(0.55, 0.85, 1.0)
const SELECTED_COLOR := Color(1.0, 0.78, 0.42)  # The warm outline on selected Wardens
const DRAG_THRESHOLD := 8.0  # Screen pixels before a press becomes a box drag
const BLOOM_TIME := 0.45
const BLOOM_STAGGER := 0.06  # Seconds between Wardens in a group grow's bloom
const WALL_ID := "thornwall"

@export var build_phase_refund: float = 0.75
@export var drift_refund: float = 0.5

@onready var map_generator = %MapGenerator
@onready var tower_container: Node2D = %TowerContainer
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var drift_director: DriftDirector = %DriftDirector
@onready var run_state: RunState = %RunState

var active := true
# The first selected Warden (null = nothing selected). `selection` has all of them.
var selected: Tower = null
var selection: Array[Tower] = []
var _hover_cell := NO_CELL
var _hover_tower: Tower = null
var _pressing := false
var _dragging := false
var _press_screen := Vector2.ZERO
var _press_world := Vector2.ZERO
var _press_shift := false
var _blooms: Array = []  # [[tower, seconds until it starts]]; negative = seconds since it started

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
	_pressing = false
	_dragging = false

# The Overgrown Dream (bittersweet) roots Wardens in place while creatures are walking.
func can_sell() -> bool:
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	return drift_director.is_build_phase() or dreams == null or not dreams.has_rule(&"overgrown")

# Dew that selling `tower` gives back right now.
func get_refund(tower: Tower) -> int:
	var share := build_phase_refund if drift_director.is_build_phase() else drift_refund
	return int(tower.invested_dew * share)

func get_tower_at(cell: Vector2) -> Tower:
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() \
				and (tower.cell == cell or tower.get_cells().has(cell)):
			return tower
	return null

# Sells the Warden on `cell`. Returns false if there's none.
func sell(cell: Vector2) -> bool:
	var tower := get_tower_at(cell)
	if tower == null or not can_sell() or tower.tower_data.rooted:
		return false  # The Heartwood Sapling is rooted: never sold or moved
	var refund := get_refund(tower)
	tower_container.remove_child(tower)
	tower.queue_free()
	for c in tower.get_cells():
		map_generator.unblock_cell(c)  # Emits path_changed -> creatures re-route
	run_state.earn_dew_at(refund, tower.position)
	tower_sold.emit(tower, refund)
	if selection.has(tower):
		selection.erase(tower)
		_selection_updated()
	_hover_tower = null
	queue_redraw()
	return true


# --- Selection ------------------------------------------------------------------------------------------

# Selects just `tower` (null clears the selection).
func select(tower: Tower) -> void:
	set_selection([tower] if tower != null else [])

func set_selection(towers: Array) -> void:
	selection.clear()
	for tower in towers:
		if tower is Tower and is_instance_valid(tower) and not tower.is_queued_for_deletion() \
				and not selection.has(tower):
			selection.append(tower)
	_selection_updated()

func _selection_updated() -> void:
	selection = selection.filter(func(t: Tower) -> bool: return is_instance_valid(t) and not t.is_queued_for_deletion())
	selected = selection[0] if not selection.is_empty() else null
	tower_selected.emit(selected)
	selection_changed.emit(selection)
	queue_redraw()

# Every Warden whose centre is inside `world_rect`. Thornwalls count only if nothing else is inside.
func get_towers_in_rect(world_rect: Rect2) -> Array[Tower]:
	var wardens: Array[Tower] = []
	var walls: Array[Tower] = []
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() and world_rect.has_point(tower.position):
			if tower.tower_data.get_id() == WALL_ID:
				walls.append(tower)
			else:
				wardens.append(tower)
	return wardens if not wardens.is_empty() else walls

# Every Warden of `data`'s kind, on screen only unless `whole_map`.
func get_same_kind(data: TowerData, whole_map: bool) -> Array[Tower]:
	var view := _visible_world_rect()
	var result: Array[Tower] = []
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() and tower.tower_data == data \
				and (whole_map or view.has_point(tower.position)):
			result.append(tower)
	return result

func _visible_world_rect() -> Rect2:
	var viewport := get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()

# Shift: adds `towers`, or removes them if they're all selected already.
func _add_or_remove(towers: Array) -> void:
	if not towers.is_empty() and towers.all(func(t: Tower) -> bool: return selection.has(t)):
		set_selection(selection.filter(func(t: Tower) -> bool: return not towers.has(t)))
	else:
		set_selection(selection + towers)

# The selection grouped by kind, biggest group first: [[TowerData, Array[Tower]], ...].
func get_selection_groups() -> Array:
	var by_kind := {}
	var order: Array[TowerData] = []
	for tower in selection:
		if not is_instance_valid(tower):
			continue
		var data: TowerData = tower.tower_data
		if not by_kind.has(data):
			by_kind[data] = []
			order.append(data)
		by_kind[data].append(tower)
	var groups: Array = []
	for data in order:
		groups.append([data, by_kind[data]])
	groups.sort_custom(func(a: Array, b: Array) -> bool: return a[1].size() > b[1].size())
	return groups


# --- Group grow and sell --------------------------------------------------------------------------------

# `towers` sorted closest to the Heartwood first (they usually matter most).
func sort_by_heartwood(towers: Array) -> Array:
	var heart: Vector2 = map_generator.endPath
	var sorted := towers.duplicate()
	sorted.sort_custom(func(a: Tower, b: Tower) -> bool:
		return a.cell.distance_squared_to(heart) < b.cell.distance_squared_to(heart))
	return sorted

# How many of `towers` the player can afford to grow into `into` right now.
func count_affordable(towers: Array, into: TowerData) -> int:
	var dreams := _dreams()
	if dreams == null:
		return 0
	var cost := dreams.get_evolve_cost(into)
	if cost <= 0:
		return towers.size()
	return mini(towers.size(), run_state.dew / cost)

# Grows as many of `towers` into `into` as the player can afford, closest to the Heartwood first.
# Returns how many grew. Each grown Warden blooms, staggered.
func grow_group(towers: Array, into: TowerData) -> int:
	var grown := 0
	for tower in sort_by_heartwood(towers):
		if not is_instance_valid(tower) or not tower_placer.evolve(tower, into):
			continue
		_blooms.append([tower, grown * BLOOM_STAGGER])
		grown += 1
	if grown > 0:
		_selection_updated()  # Kinds changed: refresh the panel
	return grown

# Whether group Nurture would raise `tower` (with `focus` for Wardens reaching rank III; without one
# they're left out).
static func _nurturable(tower, focus: Tower.Focus) -> bool:
	return is_instance_valid(tower) and tower.can_nurture() \
		and (focus != Tower.Focus.NONE or not tower.needs_focus())

# The Wardens in `towers` that group Nurture would raise one rank each with the Dew there is,
# nearest the Heartwood first (like group grow), and what that costs: [Array[Tower], cost].
# Wardens whose next rank asks for a Focus only count when `focus` is given (one Focus for the group).
func plan_nurture(towers: Array, focus: Tower.Focus = Tower.Focus.NONE) -> Array:
	var chosen: Array[Tower] = []
	var total := 0
	var free := _free_nurtures()
	for tower in sort_by_heartwood(towers):
		if not _nurturable(tower, focus):
			continue
		var cost: int = 0 if free > 0 else tower.get_nurture_price()
		if total + cost > run_state.dew:
			continue  # A cheaper one further out may still fit
		chosen.append(tower)
		total += cost
		free -= 1
	return [chosen, total]

# First Care: free Nurture ranks left this run (the first ones in a group plan are free).
func _free_nurtures() -> int:
	return run_state.free_nurtures if "free_nurtures" in run_state else 0

# Wardens in `towers` that could still gain a rank (see plan_nurture), and what raising all of them
# one rank costs: [count, Dew].
func full_nurture_cost(towers: Array, focus: Tower.Focus = Tower.Focus.NONE) -> Array:
	var count := 0
	var total := 0
	var free := _free_nurtures()
	for tower in sort_by_heartwood(towers):
		if _nurturable(tower, focus):
			count += 1
			total += 0 if free > 0 else tower.get_nurture_price()
			free -= 1
	return [count, total]

# How many of `towers` are waiting at rank II for a Focus.
func count_needing_focus(towers: Array) -> int:
	return towers.filter(func(t) -> bool: return is_instance_valid(t) and t.needs_focus()).size()

# Nurtures `towers` one rank each as far as the Dew goes, nearest the Heartwood first. Wardens
# reaching rank III take `focus` (none given: they're skipped). Returns how many gained a rank.
func nurture_group(towers: Array, focus: Tower.Focus = Tower.Focus.NONE) -> int:
	var raised := 0
	for tower in plan_nurture(towers, focus)[0]:
		if tower_placer.nurture(tower, focus):
			_blooms.append([tower, raised * BLOOM_STAGGER])
			raised += 1
	if raised > 0:
		_selection_updated()
	return raised

# Dew for selling the whole selection right now.
func get_selection_refund() -> int:
	var total := 0
	for tower in selection:
		if is_instance_valid(tower):
			total += get_refund(tower)
	return total

# Sells every selected Warden. Returns the Dew refunded.
func sell_selection() -> int:
	if not can_sell():
		return 0
	var total := 0
	for tower in selection.duplicate():
		if is_instance_valid(tower):
			var refund := get_refund(tower)
			if sell(tower.cell):
				total += refund
	set_selection([])
	return total

# G: grows the selection. One Warden: into its first form that's unlocked and affordable. Several: each
# group into its first unlocked form, as many as the Dew allows.
func grow_selected() -> bool:
	var dreams := _dreams()
	if dreams == null or selection.is_empty():
		return false
	var grown := false
	for group in get_selection_groups():
		for option in dreams.get_evolutions(group[0]):
			if option[1] and count_affordable(group[1], option[0]) > 0:
				grown = grow_group(group[1], option[0]) > 0 or grown
				break
	return grown

func _dreams() -> DreamState:
	return get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState


# --- Input ----------------------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("sell_tower") and _hover_tower != null:
		sell(_hover_cell)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("clear_obstacle") and _starts_selection(event):
		_on_press(event)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel_build") and not selection.is_empty():
		select(null)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("nurture_warden") and not selection.is_empty():
		nurture_group(selection)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("grow_warden") and not selection.is_empty():
		grow_selected()
		get_viewport().set_input_as_handled()

# A left press starts a click / drag / double-click, unless the Clear tool is on and it's on an obstacle.
func _starts_selection(event: InputEvent) -> bool:
	if _hover_tower != null:
		return true
	# With the Clear tool on, a press on a tree or rock is the clearer's; otherwise it can start a box.
	var clearer := get_node_or_null("%ObstacleClearer")
	var clearing: bool = clearer != null and clearer.has_method("is_tool_active") and clearer.is_tool_active()
	return not clearing or map_generator.get_obstacle(_hover_cell) == null

func _on_press(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	var shift := mouse != null and mouse.shift_pressed
	if mouse != null and mouse.double_click and _hover_tower != null:
		var whole_map := mouse.ctrl_pressed or mouse.meta_pressed
		var same := get_same_kind(_hover_tower.tower_data, whole_map)
		if shift:
			set_selection(selection + same)
		else:
			set_selection(same)
		_pressing = false
		return
	_pressing = true
	_dragging = false
	_press_shift = shift
	_press_screen = get_viewport().get_mouse_position()
	_press_world = get_global_mouse_position()

# Releases arrive here even over the HUD, so a drag always ends.
func _input(event: InputEvent) -> void:
	if not _pressing or not event.is_action_released("clear_obstacle"):
		return
	_pressing = false
	if _dragging:
		_dragging = false
		var box := Rect2(_press_world, Vector2.ZERO).expand(get_global_mouse_position())
		var inside := get_towers_in_rect(box)
		if _press_shift:
			_add_or_remove(inside)
		else:
			set_selection(inside)
		queue_redraw()
		return
	# A plain click: one Warden, or empty ground clears.
	var tower := get_tower_at(MAP_GRID.calculate_grid_coordinates(_press_world))
	if _press_shift:
		if tower != null:
			_add_or_remove([tower])
	else:
		select(tower)

func _process(delta: float) -> void:
	if not _blooms.is_empty():
		for bloom in _blooms:
			bloom[1] -= delta
		_blooms = _blooms.filter(func(b: Array) -> bool: return is_instance_valid(b[0]) and b[1] > -BLOOM_TIME)
		queue_redraw()
	if not active:
		return
	if _pressing and not _dragging \
			and get_viewport().get_mouse_position().distance_to(_press_screen) >= DRAG_THRESHOLD:
		_dragging = true
	if _dragging:
		queue_redraw()
	var cell: Vector2 = MAP_GRID.calculate_grid_coordinates(get_global_mouse_position())
	if cell != _hover_cell:
		_hover_cell = cell
		_hover_tower = get_tower_at(cell)
		queue_redraw()


# --- Drawing --------------------------------------------------------------------------------------------

func _draw() -> void:
	if selection.size() == 1 and is_instance_valid(selected):
		var range_pixels := selected.get_range_pixels()
		draw_circle(selected.position, range_pixels, Color(SELECTED_COLOR, 0.07))
		draw_arc(selected.position, range_pixels, 0.0, TAU, 64, Color(SELECTED_COLOR, 0.45), 2.0)
	for tower in selection:
		if is_instance_valid(tower):
			draw_rect(Rect2(tower.position - MAP_GRID.cell_size / 2, MAP_GRID.cell_size).grow(-2),
				SELECTED_COLOR, false, 3.0)
	for bloom in _blooms:
		var t: float = -bloom[1] / BLOOM_TIME  # 0 -> 1 once started
		if t < 0.0 or not is_instance_valid(bloom[0]):
			continue
		var at: Vector2 = bloom[0].position
		draw_circle(at, 12.0 + 30.0 * t, Color(SELECTED_COLOR, 0.35 * (1.0 - t)))
		for i in 6:
			var dir := Vector2.from_angle(TAU * i / 6.0 + t)
			draw_circle(at + dir * (10.0 + 26.0 * t), 3.0 * (1.0 - t) + 1.0, Color(1.0, 0.95, 0.7, 1.0 - t))
	if _dragging:
		var box := Rect2(_press_world, Vector2.ZERO).expand(get_global_mouse_position())
		draw_rect(box, Color(SELECTED_COLOR, 0.08))
		draw_rect(box, Color(SELECTED_COLOR, 0.8), false, 1.5)
	if _hover_tower == null or _dragging:
		return
	var center: Vector2 = MAP_GRID.calculate_map_position(_hover_cell)
	var rect := Rect2(center - MAP_GRID.cell_size / 2, MAP_GRID.cell_size).grow(-2)
	draw_rect(rect, HIGHLIGHT_COLOR, false, 2.0)
	var label := "%s · click: details · right-click: sell +%d Dew" % [_hover_tower.tower_data.display_name,
		get_refund(_hover_tower)]
	if not can_sell():
		label = "%s · click: details · rooted (Overgrown) until the rest" % _hover_tower.tower_data.display_name
	WorldLabel.draw_tag(self, center.x, rect.position.y - 8, label)
