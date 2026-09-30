extends Node2D
class_name TowerSeller

# Outside build mode: hovering a Warden highlights it; Delete sells it straight away (right-click never
# sells: it only cancels or deselects).
# Selecting (screens_ui.md, "Selecting several Wardens"):
#   click                  one Warden (empty ground clears the selection)
#   click and drag         every Warden in the box (Thornwalls only if the box has nothing else);
#                          the drag starts after DRAG_THRESHOLD px so clicks stay clicks
#   double-click           every Warden of the same kind and Nurture rank on screen (Ctrl: the whole map;
#                          Alt: any rank)
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

const SELL_CONFIRM_TIME := 2.0  # Seconds for the second press of the sell key during a drift
var _sell_armed: Array = []  # The Wardens the first press armed
var _sell_armed_until := 0  # Ticks (ms) until the second press must come

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

# Q / E / Z (screens_ui.md hotkeys): grow the selection into the Warden panel's 1st / 2nd / 3rd option.
# Registered here with these defaults when project.godot doesn't list them yet (rebindable once it does).
const GROW_OPTION_ACTIONS: Array[StringName] = [&"grow_option_1", &"grow_option_2", &"grow_option_3"]
const GROW_OPTION_KEYS: Array[Key] = [KEY_Q, KEY_E, KEY_Z]

# A grow key went down / up: the panel previews that option while it's held.
signal grow_option_held(index: int, held: bool)

func _ready() -> void:
	# Build mode owns the mouse; selling is available the rest of the time.
	_ensure_grow_actions()
	tower_placer.build_mode_changed.connect(func(building: bool) -> void: set_active(not building))
	# The refund changes when a drift starts or ends.
	drift_director.build_phase_changed.connect(queue_redraw.unbind(1))
	drift_director.build_phase_changed.connect(_on_build_phase_changed)
	Tower.resting = drift_director.is_build_phase()
	# A Warden leaving any other way (trampled by an Unbound nightmare) leaves the selection too.
	tower_container.child_exiting_tree.connect(_on_tower_leaving)
	_ensure_target_action()

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
	var resting := drift_director.is_build_phase()
	var share := build_phase_refund if resting else drift_refund
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if dreams:
		share = dreams.get_refund_share(share, resting)  # Fair Trade
	# Placed this rest (run_design.md "Selling"): Dew spent on it during this rest comes back in full.
	var fresh := mini(tower.rest_dew, tower.invested_dew) if resting else 0
	return fresh + int((tower.invested_dew - fresh) * share)

# Whether all of `tower` was bought this rest (the Sell button says "full refund").
func is_placed_this_rest(tower: Tower) -> bool:
	return drift_director.is_build_phase() and tower.rest_dew > 0 and tower.rest_dew >= tower.invested_dew

# A drift starting ends "placed this rest" for every Warden; a rest starting opens it again.
func _on_build_phase_changed(resting: bool) -> void:
	Tower.resting = resting
	if not resting:
		for tower in tower_container.get_children():
			if tower is Tower:
				tower.rest_dew = 0

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
	tower_placer.settle(tower.get_cells())  # Settling ground: not plantable again for a moment (drifts only)
	run_state.earn_dew_at(refund, tower.position)
	tower_sold.emit(tower, refund)
	if selection.has(tower):
		selection.erase(tower)
		_selection_updated()
	_hover_tower = null
	queue_redraw()
	return true


# --- Selection ------------------------------------------------------------------------------------------

func _on_tower_leaving(node: Node) -> void:
	if node is Tower and selection.has(node):
		selection.erase(node)
		_selection_updated.call_deferred()  # The panel refreshes once the Warden has gone
	if _hover_tower == node:
		_hover_tower = null

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
	selection.assign(selection.filter(func(t) -> bool: return is_instance_valid(t) and not t.is_queued_for_deletion()))  # Untyped: t may be freed
	selected = selection[0] if not selection.is_empty() else null
	for tower in tower_container.get_children():
		if tower is Tower and tower.is_selected != selection.has(tower):
			tower.is_selected = selection.has(tower)  # The targeting pip
			tower.queue_redraw()
	Tower.set_badges_visible(&"selection", not selection.is_empty())  # Card badges show while Wardens are selected
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
# Wardens of `data` on screen (whole_map: anywhere); with `rank` >= 0, only those at that Nurture rank.
func get_same_kind(data: TowerData, whole_map: bool, rank: int = -1) -> Array[Tower]:
	var view := _visible_world_rect()
	var result: Array[Tower] = []
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() and tower.tower_data == data \
				and (rank < 0 or tower.rank == rank) and (whole_map or view.has_point(tower.position)):
			result.append(tower)
	return result

# Double-click / touch long-press (screens_ui.md "Selecting several Wardens"): the same kind AND the
# same Nurture rank as `tower`; `any_rank` (Alt) = the same kind at any rank; `whole_map` (Ctrl) = not
# just on screen; `add` (Shift) = add to the selection.
func select_same_as(tower: Tower, whole_map: bool, any_rank: bool, add: bool = false) -> void:
	var same := get_same_kind(tower.tower_data, whole_map, -1 if any_rank else tower.rank)
	set_selection(selection + same if add else same)

func _visible_world_rect() -> Rect2:
	var viewport := get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()

# Shift: adds `towers`, or removes them if they're all selected already.
func _add_or_remove(towers: Array) -> void:
	if not towers.is_empty() and towers.all(func(t) -> bool: return selection.has(t)):
		set_selection(selection.filter(func(t) -> bool: return is_instance_valid(t) and not towers.has(t)))
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
	var sorted := towers.filter(func(t) -> bool: return is_instance_valid(t) and t is Tower)  # Skip gone ones
	sorted.sort_custom(func(a: Tower, b: Tower) -> bool:
		return a.cell.distance_squared_to(heart) < b.cell.distance_squared_to(heart))
	return sorted

# How many of `towers` the player can afford to grow into `into` right now.
func count_affordable(towers: Array, into: TowerData) -> int:
	return plan_grow(towers, into)[0]

# Which of `towers` group grow would grow into `into` with the Dew there is, nearest the Heartwood
# first (each pays Tower.get_grow_cost: ranked Wardens pay their rank difference too), skipping ones
# that don't fit so a cheaper one further out still can: [count, total Dew].
func plan_grow(towers: Array, into: TowerData) -> Array:
	var count := 0
	var total := 0
	if tower_placer.ascended_blocker(into) != "":
		return [0, 0]  # One Ascended form per family is already on the map
	var limit := 1 if into.tier >= DreamState.ASCENDED_TIER else towers.size()  # …and only one can wake
	for tower in sort_by_heartwood(towers):
		if not is_instance_valid(tower) or count >= limit:
			continue
		if into.footprint > tower.get_footprint() and tower_placer.get_grow_squares(tower, into).is_empty():
			continue  # No room for the 2×2 form: skipped (grow_group picks the best square for the rest)
		var cost: int = tower.get_grow_cost(into).total
		if total + cost > run_state.dew:
			continue
		count += 1
		total += cost
	return [count, total]

# What growing all of `towers` into `into` would cost.
func full_grow_cost(towers: Array, into: TowerData) -> int:
	var total := 0
	for tower in towers:
		if is_instance_valid(tower):
			total += tower.get_grow_cost(into).total
	return total

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
# The sell key (X or Delete; screens_ui.md hotkeys): sells the selected Wardens, or the hovered one
# with nothing selected. During a drift with the confirm_sell setting on, the first press shows the
# (half) refund and a second press within SELL_CONFIRM_TIME sells; at rests one press sells.
# Returns whether the key did something.
func sell_key() -> bool:
	var targets: Array = selection.duplicate() if not selection.is_empty() else ([_hover_tower] if _hover_tower else [])
	targets = targets.filter(func(t) -> bool: return is_instance_valid(t) and not t.tower_data.rooted)
	if targets.is_empty() or not can_sell():
		return false
	var ask: bool = not drift_director.is_build_phase() and Fx.setting("confirm_sell", true)  # Cached (get_settings reads the profile)
	var now := Time.get_ticks_msec()
	if ask and not (now < _sell_armed_until and _sell_armed == targets):
		_sell_armed = targets
		_sell_armed_until = now + int(SELL_CONFIRM_TIME * 1000)
		get_tree().create_timer(SELL_CONFIRM_TIME, true, false, true).timeout.connect(queue_redraw)
		queue_redraw()
		return true
	_sell_armed = []
	_sell_armed_until = 0
	if targets == selection:
		sell_selection()
	else:
		sell(targets[0].cell)
	return true

# Waiting for the second press: the Wardens and their total refund (0 when not armed).
func get_armed_sell() -> Array:
	if Time.get_ticks_msec() >= _sell_armed_until:
		return []
	return _sell_armed.filter(func(t) -> bool: return is_instance_valid(t))

# The key the Sell button shows ("X", or the rebound one).
func sell_key_name() -> String:
	return _sell_key_name()

# The key bound to `action` ("Q"), for button badges; "" when none.
static func key_name(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	return ""

static func _ensure_grow_actions() -> void:
	for i in GROW_OPTION_ACTIONS.size():
		if InputMap.has_action(GROW_OPTION_ACTIONS[i]):
			continue
		InputMap.add_action(GROW_OPTION_ACTIONS[i])
		var key := InputEventKey.new()
		key.physical_keycode = GROW_OPTION_KEYS[i]
		InputMap.action_add_event(GROW_OPTION_ACTIONS[i], key)

# The first key bound to sell_tower, for the prompt ("X").
func _sell_key_name() -> String:
	for event in InputMap.action_get_events("sell_tower"):
		if event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	return "the sell key"

# True while a text field has focus (the sell key must not fire while typing).
func _typing() -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	return focus is LineEdit or focus is TextEdit

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

# Q / E / Z: grows the selection into its `index`th option (the Warden panel's order; each kind in a
# group its own). A locked option opens the Remember tree on that form instead; a 2×2 form asks for its
# square like the panel's button. Returns true if anything grew or opened.
func grow_option(index: int) -> bool:
	var dreams := _dreams()
	if dreams == null or selection.is_empty():
		return false
	var acted := false
	for group in get_selection_groups():
		var options := Tower.grow_options(dreams, group[0])
		if index >= options.size():
			continue
		var next: TowerData = options[index][0]
		if not options[index][1]:
			dreams.open_remember(next)
			return true
		if group[1].size() == 1 and next.footprint > group[1][0].get_footprint():
			acted = tower_placer.begin_grow_choice(group[1][0], next) or acted
		elif group[1].size() == 1:
			acted = tower_placer.evolve(group[1][0], next) or acted
		else:
			acted = grow_group(group[1], next) > 0 or acted
	return acted

# G: grows the selection. One Warden: into its first form that's unlocked and affordable. Several: each
# group into its first unlocked form, as many as the Dew allows.
func grow_selected() -> bool:
	var dreams := _dreams()
	if dreams == null or selection.is_empty():
		return false
	var grown := false
	for group in get_selection_groups():
		for option in Tower.grow_options(dreams, group[0]):
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
	if event.is_action_pressed("sell_tower") and not (event is InputEventMouseButton) and not _typing():
		if sell_key():
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
	elif _grow_option_event(event):
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cycle_target") and not selection.is_empty():
		cycle_target_group(selection)
		get_viewport().set_input_as_handled()

# Q / E / Z: a press previews the option (held), the release grows it; the preview ends either way.
func _grow_option_event(event: InputEvent) -> bool:
	if not (event is InputEventKey) or selection.is_empty() or _typing():
		return false
	for i in GROW_OPTION_ACTIONS.size():
		if not InputMap.has_action(GROW_OPTION_ACTIONS[i]) or not event.is_action(GROW_OPTION_ACTIONS[i]):
			continue
		if event.is_echo():
			return true
		if event.is_pressed():
			grow_option_held.emit(i, true)
		else:
			grow_option_held.emit(i, false)
			grow_option(i)
		return true
	return false

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
		select_same_as(_hover_tower, mouse.ctrl_pressed or mouse.meta_pressed, mouse.alt_pressed, shift)
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
	var armed := get_armed_sell()
	if not armed.is_empty():
		# First press during a drift: show the (half) refund; a second press sells.
		var refund := 0
		for tower in armed:
			refund += get_refund(tower)
		var at: Vector2 = armed[0].position
		WorldLabel.draw_tag(self, at.x, at.y - MAP_GRID.cell_size.y / 2.0 - 8.0,
			"Press %s again to sell for +%d Dew (half during a drift)" % [_sell_key_name(), refund],
			Color(1.0, 0.8, 0.45))
	if _dragging:
		var box := Rect2(_press_world, Vector2.ZERO).expand(get_global_mouse_position())
		draw_rect(box, Color(SELECTED_COLOR, 0.08))
		draw_rect(box, Color(SELECTED_COLOR, 0.8), false, 1.5)
	if _hover_tower == null or _dragging:
		return
	var center: Vector2 = MAP_GRID.calculate_map_position(_hover_cell)
	var rect := Rect2(center - MAP_GRID.cell_size / 2, MAP_GRID.cell_size).grow(-2)
	draw_rect(rect, HIGHLIGHT_COLOR, false, 2.0)
	var label := "%s · click: details · %s: sell +%d Dew" % [_hover_tower.tower_data.display_name,
		_sell_key_name(), get_refund(_hover_tower)]
	if not can_sell():
		label = "%s · click: details · Overgrown: no selling until the rest" % _hover_tower.tower_data.display_name
	WorldLabel.draw_tag(self, center.x, rect.position.y - 8, label)

# --- Targeting (screens_ui.md "Targeting") -------------------------------------------------------------

# Sets every Warden in `towers` that has the switch to `mode`.
func set_target_group(towers: Array, mode: TowerData.TargetMode) -> void:
	for tower in towers:
		if is_instance_valid(tower) and tower.can_choose_target():
			tower.set_target_mode(mode)
	selection_changed.emit(selection)  # The panel's switch follows

# T: the next mode after the first targeting Warden's, for all of them together.
func cycle_target_group(towers: Array) -> void:
	var aimed := towers.filter(func(t) -> bool: return is_instance_valid(t) and t.can_choose_target())
	if aimed.is_empty():
		return
	var modes := Tower.PLAYER_TARGET_MODES
	var index := modes.find(aimed[0].get_target_mode())
	set_target_group(aimed, modes[(index + 1) % modes.size()])

# The T key's action. It belongs in project.godot's input map (and the settings' keybind list); until
# it's there, it's made here so the key works.
static func _ensure_target_action() -> void:
	if InputMap.has_action("cycle_target"):
		return
	InputMap.add_action("cycle_target")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_T
	InputMap.action_add_event("cycle_target", key)
