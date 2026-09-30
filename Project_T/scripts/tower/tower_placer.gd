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

# Loaded in _ready, not preloaded: a preload here closed a cycle (TowerPlacer -> tower.tscn -> Tower ->
# Kinships -> TowerPlacer) that broke parsing of scripts reading tower_scene ("Cyclic reference").
@export var tower_scene: PackedScene
const TOWER_SCENE_PATH := "res://scenes/tower/tower.tscn"
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
const CATCH_TINT := Color(1.0, 0.85, 0.44, 0.16)  # Path tiles in a catcher's reach (placement preview)
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
var _heart_here := false  # Heart of the Maze would move to the Warden planted here
const KIN_SPOT_COLOR := Color(0.78, 0.86, 0.42, 0.4)  # Faint green-gold leaf outline
var _path_preview := Line2D.new()
const PREVIEW_COLOR := Color(0.4, 0.9, 1.0, 0.6)  # The route preview (RouteLine: high-contrast setting)

# Settling ground (run_design.md "No maze juggling"): during a drift, the cells a Warden was sold from
# can't be planted on again for SETTLE_SECONDS of game time (every footprint cell). Rests are exempt and
# settle everything at once. The rings with their countdown are drawn by a SettlingMarks node in the
# world (this placer hides outside build mode).
const SETTLE_SECONDS := 8.0
const SETTLE_COLOR := Color(0.85, 0.72, 0.5)
var settling := {}  # cell -> game seconds left
var _settling_marks: Node2D = null

func _ready() -> void:
	if tower_scene == null:
		tower_scene = load(TOWER_SCENE_PATH)
	# Parked Wardens (the Memory Wardens, cut for now) never join the roster: not in the bar, not buildable,
	# not with Test Grove or Unlock all.
	towers.assign(towers.filter(func(t: TowerData) -> bool: return t != null and not t.parked))
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
	var director := get_node_or_null("%DriftDirector")
	if director:
		director.build_phase_changed.connect(func(resting: bool) -> void:
			if resting:
				clear_settling())  # A rest settles the ground at once

# --- Settling ground ---

# Called by TowerSeller when a Warden is sold (all its cells). Nothing settles during a rest.
func settle(cells: Array) -> void:
	var director := get_node_or_null("%DriftDirector")
	if director == null or director.is_build_phase():
		return
	for c in cells:
		settling[c] = SETTLE_SECONDS
	_marks().queue_redraw()

# Seconds until every one of `cells` can be planted on again (0 = now).
func settling_left(cells: Array) -> float:
	var left := 0.0
	for c in cells:
		left = maxf(left, settling.get(c, 0.0))
	return left

func clear_settling() -> void:
	settling.clear()
	if is_instance_valid(_settling_marks):
		_settling_marks.queue_redraw()
	queue_redraw()

func _tick_settling(delta: float) -> void:
	if settling.is_empty() or get_tree().paused:
		return  # This placer runs while paused; the ground settles in game time (delta has time_scale)
	for c in settling.keys():
		settling[c] -= delta
		if settling[c] <= 0.0:
			settling.erase(c)
	_marks().queue_redraw()
	if build_mode and _hover_cell != NO_CELL:
		queue_redraw()  # The ghost's "settling (5 s)" counts down (_process re-checks validity)

func _hover_cell_valid() -> bool:
	return not frozen_ground() and not _hover_path.is_empty() and not _cells_occupied(_footprint(_hover_cell)) \
		and not is_unique_placed(tower_data) and settling_left(_footprint(_hover_cell)) <= 0.0

func _marks() -> Node2D:
	if not is_instance_valid(_settling_marks):
		_settling_marks = Node2D.new()
		_settling_marks.name = "SettlingMarks"
		_settling_marks.z_index = 2  # Over the ground, under the nightmares' health bars
		_settling_marks.draw.connect(_draw_settling)
		get_parent().add_child(_settling_marks)
	return _settling_marks

# A dashed ring of loose earth on each settling cell, with its countdown.
func _draw_settling() -> void:
	for c in settling:
		var centre: Vector2 = _settling_marks.to_local(MAP_GRID.calculate_map_position(c))
		var left: float = settling[c]
		var radius := MAP_GRID.cell_size.x * 0.36
		var share := clampf(left / SETTLE_SECONDS, 0.0, 1.0)
		for i in 12:
			var from := TAU * i / 12.0
			_settling_marks.draw_arc(centre, radius, from, from + TAU / 24.0, 4, Color(SETTLE_COLOR, 0.35), 2.0)
		_settling_marks.draw_arc(centre, radius, -PI / 2.0, -PI / 2.0 + TAU * share, 32, Color(SETTLE_COLOR, 0.9), 2.5)
		WorldLabel.draw_tag(_settling_marks, centre.x, centre.y + 5.0, "%d" % ceili(left), SETTLE_COLOR)

func set_build_mode(active: bool) -> void:
	if not active and stroking:
		cancel_stroke()
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

# While picking a square for a 2×2 growth, clicks go to the choice first (before selection handles them).
func _input(event: InputEvent) -> void:
	if stroking:
		_stroke_input(event)
		return
	if not is_choosing_square():
		return
	if event.is_action_pressed("cancel_build"):
		cancel_grow_choice()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("place_tower"):
		var origin := _choice_at(get_global_mouse_position())
		if origin != NO_CELL:
			evolve(_grow_choice.tower, _grow_choice.into, origin)
			cancel_grow_choice()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_build_mode"):
		set_build_mode(not build_mode)
		get_viewport().set_input_as_handled()
	elif not build_mode:
		return
	elif event.is_action_pressed("cancel_build"):
		if stroking:
			cancel_stroke()  # RMB / Esc drops the stroke, not build mode
		else:
			set_build_mode(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("place_tower"):
		if tower_data.footprint > 1:
			_try_build(_hover_cell)  # Big Wardens: one per click
		else:
			begin_stroke(_hover_cell)  # A click is a stroke of one; dragging adds cells
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_tick_settling(delta)
	if not _grow_preview.is_empty():
		_grow_preview_time += delta
		queue_redraw()  # The new form idles
	if is_choosing_square():
		if not is_instance_valid(_grow_choice.tower):
			cancel_grow_choice()
		else:
			_update_grow_choice()
		return
	if not build_mode:
		return
	var cell: Vector2 = MAP_GRID.calculate_grid_coordinates(get_global_mouse_position())
	if stroking:
		return  # The stroke has its own ghosts and route (_stroke_input)
	if cell != _hover_cell:
		_hover_cell = cell
		_refresh_hover()
	# Enemies move every frame, so re-check whether one is standing on the hovered cell.
	var valid := _hover_cell_valid()
	# Dew changes while hovering (creatures get cleansed), so re-check affordability too.
	var affordable := run_state.can_afford(get_cost(null, _hover_cell))
	if valid != _hover_valid or affordable != _hover_affordable:
		_hover_valid = valid
		_hover_affordable = affordable
		queue_redraw()

func _draw() -> void:
	if is_choosing_square():
		_draw_grow_choice()
		return
	if stroking:
		_draw_stroke()
		return
	_draw_grow_preview()
	_draw_kin_spots()
	if not _catch_preview.is_empty():
		_draw_catch_zone(_catch_preview.at, _catch_preview.radius)
	if _hover_cell == NO_CELL or not MAP_GRID.is_within_bounds(_hover_cell):
		return
	if tower_data.catch_share > 0.0:
		_draw_catch_zone(Tower.footprint_centre(_hover_cell, tower_data.footprint), tower_data.catch_radius \
			+ DewCatch.WIDE_BOWL_STEP * mini(dream_state.rule_stacks(&"wide_bowl"), 3))
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
	if tower_data.can_attack:
		# Its damage type (screens_ui.md "Damage-type icons"): the icon at the ghost's top-left.
		var type_icon := IconInfo.damage_type_icon(tower_data.line)
		if type_icon:
			var corner := -MAP_GRID.cell_size / 2.0 + Vector2(2, 2)
			draw_rect(Rect2(corner - Vector2(1, 1), Vector2(18, 18)), Color(0.1, 0.08, 0.05, 0.8))
			draw_texture_rect(type_icon, Rect2(corner, Vector2(16, 16)), false)
	var tag := "%s · %d Dew" % [tower_data.display_name, get_cost(null, _hover_cell)]
	if tower_data.can_attack:
		tag = "%s · %s · %d Dew" % [tower_data.display_name, IconInfo.damage_type_name(tower_data.line), get_cost(null, _hover_cell)]
	if run_state.fertile_cells.has(_hover_cell):
		tag += " (fertile)"
	var growth := get_hover_path_growth()
	if is_edge_cell(_hover_cell) and _hover_cell != map_generator.startPath and _hover_cell != map_generator.endPath:
		tag += "  ·  the dream's edge"  # The island's rim (screens_ui.md "Invalid placement")
	elif frozen_ground():
		tag += "  ·  Frozen Ground: plant at the rest"
	elif is_unique_placed(tower_data):
		tag += "  ·  already planted (one per run)"
	elif settling_left(_footprint(_hover_cell)) > 0.0:
		tag += "  ·  The ground is settling (%d s)" % ceili(settling_left(_footprint(_hover_cell)))
	elif hover_breaks_path():
		tag += "  ·  would close the dream"  # The forest's rule: it may bend, never close
	elif _cells_occupied(_footprint(_hover_cell)):
		tag += "  ·  nightmare here"
	elif growth != 0:
		tag += "  ·  %+d path" % growth  # "Wardens are walls": how much longer the walk gets
	if _kin_here != "":
		tag += "  ·  Kin spot: forms %s" % _kin_here
	if _heart_here:
		tag += "  ·  Becomes the Heart of the Maze"
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

# --- Growth preview (screens_ui.md "Preview the growth before growing") -------------------------------

const PREVIEW_ALPHA := 0.6
var _grow_preview: Array = []  # [[Tower, TowerData], …] while a Grow button is pointed at or its key held
var _grow_preview_time := 0.0

# Shows each Warden as the form it would grow into: its sprite in place (translucent, idling), the new
# range bright over the current faint one (a sniper's dead zone too), and a 2×2 form's squares.
func show_grow_preview(pairs: Array) -> void:
	_grow_preview = pairs.filter(func(p: Array) -> bool: return is_instance_valid(p[0]) and p[1] != null)
	_grow_preview_time = 0.0
	queue_redraw()

func hide_grow_preview() -> void:
	if not _grow_preview.is_empty():
		_grow_preview = []
		queue_redraw()

func is_previewing_growth() -> bool:
	return not _grow_preview.is_empty()

# The range `tower` would have as `into`: its own extras (ranks, Focus, cards) kept on the new base.
func preview_range(tower: Tower, into: TowerData) -> float:
	return tower.get_range_cells() - Tower.get_range_for(tower.tower_data, dream_state) + Tower.get_range_for(into, dream_state)

# The stat changes for the Grow button's tooltip: "Damage 24 → 38 · Range 2.7 → 3.2 · adds Rooted".
func grow_changes(tower: Tower, into: TowerData) -> String:
	var from := tower.tower_data
	var parts: Array[String] = []
	if into.can_attack and from.can_attack and from.damage > 0:
		var now := tower.get_damage()
		var then := now * float(into.damage) / float(from.damage)
		if roundi(then) != roundi(now):
			parts.append("Damage %d → %d" % [roundi(now), roundi(then)])
		var speed := tower.get_attacks_per_second()
		var faster := speed * into.attacks_per_second / maxf(from.attacks_per_second, 0.01)
		if absf(faster - speed) >= 0.05:
			parts.append("Speed %.1f → %.1f/s" % [speed, faster])
	elif into.can_attack and not from.can_attack:
		parts.append("Damage %d" % into.damage)
	var reach := preview_range(tower, into)
	if into.can_attack and absf(reach - tower.get_range_cells()) >= 0.05:
		parts.append("Range %.1f → %.1f" % [tower.get_range_cells(), reach])
	if into.min_range > 0.0 and into.min_range != from.min_range:
		parts.append("can't hit within %.1f" % into.min_range)
	if into.applies_status != &"" and into.applies_status != from.applies_status:
		parts.append("adds %s" % IconInfo.status_name(into.applies_status))
	return " · ".join(parts)

func _draw_grow_preview() -> void:
	for pair in _grow_preview:
		var tower: Tower = pair[0]
		var into: TowerData = pair[1]
		if not is_instance_valid(tower):
			continue
		if into.footprint > tower.get_footprint():
			draw_set_transform(Vector2.ZERO)
			for origin in get_grow_squares(tower, into):  # Where a 2×2 form could stand
				var rect := Rect2(MAP_GRID.calculate_map_position(origin) - MAP_GRID.cell_size / 2.0, MAP_GRID.cell_size * 2.0)
				draw_rect(rect.grow(-3), Color(VALID_TINT, 0.08))
				draw_rect(rect.grow(-3), Color(VALID_TINT, 0.5), false, 2.0)
			continue
		draw_set_transform(to_local(tower.global_position))
		if into.can_attack:
			var now_px := Tower.range_to_pixels(tower.get_range_cells()) if tower.tower_data.can_attack else 0.0
			var new_px := Tower.range_to_pixels(preview_range(tower, into))
			if now_px > 0.0:
				draw_arc(Vector2.ZERO, now_px, 0.0, TAU, 64, Color(VALID_TINT, 0.25), 1.5)
			draw_circle(Vector2.ZERO, new_px, Color(BONUS_ON, 0.08))
			draw_arc(Vector2.ZERO, new_px, 0.0, TAU, 64, Color(BONUS_ON, 0.85), 2.5)
			if into.min_range > 0.0:  # The sniper's dead zone
				var dead := Tower.range_to_pixels(into.min_range)
				draw_circle(Vector2.ZERO, dead, Color(INVALID_TINT, 0.12))
				draw_arc(Vector2.ZERO, dead, 0.0, TAU, 48, Color(INVALID_TINT, 0.6), 1.5)
		if into.texture == null:
			Tower.draw_placeholder(self, Color(1, 1, 1, PREVIEW_ALPHA))
		else:
			var frame := into.get_frame_rect(int(_grow_preview_time * into.animation_fps) % maxi(into.frame_count, 1))
			draw_texture_rect_region(into.texture, Rect2(-frame.size / 2.0 + into.sprite_offset, frame.size), frame,
				Color(1, 1, 1, PREVIEW_ALPHA))
	draw_set_transform(Vector2.ZERO)

# --- Catcher placement preview (screens_ui.md "Support and economy feedback") ---------------------

var _catch_preview := {}  # {"at": world position, "radius": cells} while the Warden panel asks

# Shades the path tiles a catcher at `at` (world) would catch on, with the share of last block's
# dispels there. The Warden panel shows it for a selected catcher and while "Grow into Dewcatcher" is
# pointed at; the build ghost shows it for a catcher.
func show_catch_preview(at: Vector2, radius: float) -> void:
	_catch_preview = {"at": at, "radius": radius}
	queue_redraw()

func hide_catch_preview() -> void:
	if not _catch_preview.is_empty():
		_catch_preview = {}
		queue_redraw()

func _draw_catch_zone(at: Vector2, radius: float) -> void:
	var reach := radius * MAP_GRID.cell_size.x
	var half := MAP_GRID.cell_size / 2.0
	for cell in map_generator.get_path_from(map_generator.startPath):
		var centre := MAP_GRID.calculate_map_position(cell)
		if centre.distance_to(at) <= reach:
			draw_rect(Rect2(to_local(centre) - half + Vector2(3, 3), MAP_GRID.cell_size - Vector2(6, 6)), CATCH_TINT)
	draw_arc(to_local(at), reach, 0.0, TAU, 64, Color(DewCatch.GOLD, 0.55), 1.5)
	var log := SupportLog.find(self)
	var share := log.dispel_share_near(at, radius) if log else -1.0
	if share >= 0.0:
		var local := to_local(at)
		WorldLabel.draw_tag(self, local.x, local.y - reach - 8.0,
			"~%d%% of dispels last block happened here" % roundi(share * 100.0), DewCatch.GOLD)


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
	if stroking:
		_plan_stroke()  # The maze changed under the stroke
		return
	_hover_path = PackedVector2Array()
	if _footprint(_hover_cell).all(func(c: Vector2) -> bool: return map_generator.is_buildable(c)):
		_hover_path = map_generator.get_path_if_blocked_cells(_footprint(_hover_cell))
	_path_preview.clear_points()
	RouteLine.apply(_path_preview, PREVIEW_COLOR)
	for point in _hover_path:
		_path_preview.add_point(MAP_GRID.calculate_map_position(point))
	_hover_valid = _hover_cell_valid()
	_heart_here = becomes_heart(_hover_cell, _hover_path)
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
	if tower_data == null or tower_data.parked:
		build_rejected.emit(cell)
		return false  # Parked Wardens (cut for now) are never planted
	if frozen_ground():
		_toast_frozen()
		build_rejected.emit(cell)
		return false
	if is_unique_placed(tower_data):
		build_rejected.emit(cell)
		return false
	if settling_left(_footprint(cell)) > 0.0:
		build_rejected.emit(cell)  # Settling ground: sold here moments ago
		return false
	if _cells_occupied(_footprint(cell)):
		build_rejected.emit(cell)
		return false
	# Every enemy on the field must still be able to reach the end, not just new spawns.
	var enemy_cells := PackedVector2Array()
	for enemy_cell in _walker_cells():
		enemy_cells.append(enemy_cell)
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
	if tower_data.get_id() == "sprout" and cost == 0:
		tower.set_meta(&"gift_sprout", true)  # A Seedling Gift charge: never raises the Sprout price
	tower.rest_dew = cost if Tower.resting else 0  # Placed this rest: a full refund until Start
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
func get_cost(data: TowerData = null, cell: Vector2 = NO_CELL, planned_sprouts: int = 0) -> int:
	var warden := data if data != null else tower_data
	var cost: int = dream_state.get_build_cost(warden) if cell == NO_CELL else dream_state.get_build_cost_at(warden, cell)
	# Sprouts get pricier as you plant (warden_stats.md, card 69): every SPROUTS_PER_STEP Sprouts on the map
	# add SPROUT_STEP_DEW to the next one (10, 13, 16, …); Seedling Gift Sprouts don't count and a free one
	# stays free. Seedfall: 6 Dew, and the price never rises (SEEDFALL_SPROUTS_PER_STEP 0). `planned_sprouts`:
	# Sprouts earlier in the same drag stroke.
	if warden.get_id() == "sprout" and cost > 0:
		var per_step := SEEDFALL_SPROUTS_PER_STEP if sprout_price_halved() else SPROUTS_PER_STEP
		if per_step > 0:
			cost += (count_paid_sprouts() + planned_sprouts) / per_step * SPROUT_STEP_DEW
	return cost

func sprout_price_halved() -> bool:
	return dream_state.has_card(SEEDFALL_CARD)

const SEEDFALL_CARD := "seedfall"
const SPROUTS_PER_STEP := 5  # Every 5 Sprouts on the map…
const SPROUT_STEP_DEW := 3  # …add +3 Dew to the next one
const SEEDFALL_SPROUTS_PER_STEP := 0  # Seedfall: 0 = the price never rises

# Sprouts on the map that raise the price (not the free ones from Seedling Gift charges).
func count_paid_sprouts() -> int:
	var count := 0
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() and tower.tower_data.get_id() == "sprout" \
				and not tower.get_meta(&"gift_sprout", false):
			count += 1
	return count

# Wardens that can be planted right now (unlocked this run), in roster order.
func get_buildable_towers() -> Array[TowerData]:
	var result: Array[TowerData] = []
	for data in towers:
		if dream_state.is_buildable(data):
			result.append(data)
	return result

# Grows `tower` into `into` in place, if that evolution is unlocked and affordable. A same-size growth
# never changes the path, so it's always allowed (mid-drift and while paused too). Growing into a
# bigger form (Ascended: 2×2) takes one of the squares from get_grow_squares(): `origin` picks it
# (its top-left cell); with none given, the best one (the longest route) is used.
func evolve(tower: Tower, into: TowerData, origin: Vector2 = NO_CELL) -> bool:
	if not tower.tower_data.evolves_to.has(into) or not dream_state.is_unlocked(into.get_id()):
		return false
	if frozen_ground():
		_toast_frozen()
		return false
	if ascended_blocker(into) != "":
		return false  # One Ascended form per family on the map
	var grows := into.footprint > tower.get_footprint()
	if grows:
		var squares := get_grow_squares(tower, into)
		if squares.is_empty():
			return false  # Needs room
		if origin == NO_CELL:
			origin = best_grow_square(squares)
		elif not squares.has(origin):
			return false
	var cost: int = tower.get_grow_cost(into).total  # Evolve cost + the rank difference; all invested
	if not run_state.spend_dew(cost):
		return false
	if grows:
		_take_square(tower, into, origin)
	tower.evolve(into, cost)
	return true

# The 2×2 squares (top-left cells) `tower` could grow into `into` on (tower_design.md "Ascended forms",
# Size): each of the four squares that include its cell, whose other cells are empty buildable ground
# or the player's own Thornwalls, with no nightmare on them, and where the path rule still holds.
func get_grow_squares(tower: Tower, into: TowerData) -> Array[Vector2]:
	var squares: Array[Vector2] = []
	var size := into.footprint
	if size <= tower.get_footprint():
		return squares
	var enemy_cells := PackedVector2Array()
	for enemy_cell in _walker_cells():
		enemy_cells.append(enemy_cell)
	for dy in range(-(size - 1), 1):
		for dx in range(-(size - 1), 1):
			var origin: Vector2 = tower.cell + Vector2(dx, dy)
			var free = _square_free_cells(tower, origin, size)  # Array[Vector2] or null
			if free == null:
				continue
			var others: Array[Vector2] = []
			others.assign(Tower.footprint_cells(origin, size).filter(func(c) -> bool: return c != tower.cell))
			if _cells_occupied(others):
				continue
			if settling_left(others) > 0.0:
				continue  # Settling ground: a Warden was sold there moments ago
			if not free.is_empty() and not map_generator.can_block_cells(free, enemy_cells):
				continue  # The forest's rule: it may bend, never close
			squares.append(origin)
	return squares

# The cells of the square at `origin` that are open ground now (to be blocked), or null if one is
# another Warden (other than a lone Thornwall), an obstacle, start/end or off the map.
func _square_free_cells(tower: Tower, origin: Vector2, size: int):
	var free: Array[Vector2] = []
	for c in Tower.footprint_cells(origin, size):
		if c == tower.cell:
			continue
		if not MAP_GRID.is_within_bounds(c):
			return null
		if map_generator.is_buildable(c):
			free.append(c)
		elif _thornwall_at(c) == null:
			return null  # Another Warden, an obstacle, start / end, the border
	return free

# The player's own Thornwall on `cell` (absorbed by a growing Ascended form), or null.
func _thornwall_at(cell: Vector2) -> Tower:
	for other in tower_container.get_children():
		if other is Tower and not other.is_queued_for_deletion() and other.cell == cell \
				and other.tower_data.get_id() == "thornwall" and other.get_footprint() == 1:
			return other
	return null

# Of several valid squares, the one that leaves the longest route (group grow and G pick for you).
func best_grow_square(squares: Array[Vector2]) -> Vector2:
	var best := squares[0]
	var best_length := -1
	for origin in squares:
		var cells: Array[Vector2] = Tower.footprint_cells(origin, 2)
		var length: int = map_generator.get_path_if_blocked_cells(cells).size()
		if length > best_length:
			best_length = length
			best = origin
	return best

# Grows `tower` onto the square at `origin`: absorbs Thornwalls there (their Dew back in full), blocks
# the open cells, and moves the Warden to the square's centre.
func _take_square(tower: Tower, into: TowerData, origin: Vector2) -> void:
	var size := into.footprint
	var free: Array[Vector2] = []
	for c in Tower.footprint_cells(origin, size):
		if c == tower.cell:
			continue
		var wall := _thornwall_at(c)
		if wall != null:
			run_state.earn_dew_at(wall.invested_dew, wall.global_position)  # Absorbed: refunded in full
			tower_container.remove_child(wall)
			wall.queue_free()
		else:
			free.append(c)
	var old_cell := tower.cell
	tower.cell = origin
	tower.position = Tower.footprint_centre(origin, size)
	Tower.towers_moved()  # Its neighbour buckets
	tower.footprint_size = size  # It has its room now (Tower.evolve keeps the size it's given)
	var kin := Kinships.find(self)
	if kin:
		kin.note_moved(tower, old_cell)  # The bond keeps its age (evolving keeps it)
	if not free.is_empty():
		map_generator.block_cells(free)  # Emits path_changed: nightmares re-route
	else:
		map_generator.path_changed.emit()


# --- Choosing the square (a Grow into a bigger form with several places to go) ---

signal grow_choice_changed(active: bool)
var _grow_choice := {}  # {tower, into, squares, hover} while the player picks a square

# Starts picking a square for growing `tower` into `into`: the valid squares show as ghosts with their
# route preview; clicking one grows there, Esc / right-click cancels. With one square it grows at once.
func begin_grow_choice(tower: Tower, into: TowerData) -> bool:
	var squares := get_grow_squares(tower, into)
	if squares.is_empty():
		return false
	if squares.size() == 1:
		return evolve(tower, into, squares[0])
	set_build_mode(false)
	_grow_choice = {"tower": tower, "into": into, "squares": squares, "hover": NO_CELL}
	visible = true
	grow_choice_changed.emit(true)
	queue_redraw()
	return true

func is_choosing_square() -> bool:
	return not _grow_choice.is_empty()

func cancel_grow_choice() -> void:
	if _grow_choice.is_empty():
		return
	_grow_choice = {}
	visible = build_mode
	_path_preview.clear_points()
	grow_choice_changed.emit(false)
	queue_redraw()

# The square under `world` (a point on the map), or NO_CELL.
func _choice_at(world: Vector2) -> Vector2:
	var cell := MAP_GRID.calculate_grid_coordinates(world)
	for origin in _grow_choice.squares:
		if Tower.footprint_cells(origin, 2).has(cell):
			return origin
	return NO_CELL

func _update_grow_choice() -> void:
	var hover := _choice_at(get_global_mouse_position())
	if hover == _grow_choice.hover:
		return
	_grow_choice.hover = hover
	_path_preview.clear_points()
	if hover != NO_CELL:
		for point in map_generator.get_path_if_blocked_cells(Tower.footprint_cells(hover, 2)):
			_path_preview.add_point(MAP_GRID.calculate_map_position(point))
	queue_redraw()

func _draw_grow_choice() -> void:
	draw_set_transform(Vector2.ZERO)
	var into: TowerData = _grow_choice.into
	for origin in _grow_choice.squares:
		var rect := Rect2(MAP_GRID.calculate_map_position(origin) - MAP_GRID.cell_size / 2.0, MAP_GRID.cell_size * 2.0)
		var hovered: bool = origin == _grow_choice.hover
		draw_rect(rect.grow(-3), Color(VALID_TINT, 0.18 if hovered else 0.08))
		draw_rect(rect.grow(-3), Color(VALID_TINT, 0.9 if hovered else 0.5), false, 2.0)
		if hovered and into.texture != null:
			var frame := into.get_frame_rect(0)
			var centre := Tower.footprint_centre(origin, 2)
			draw_texture_rect_region(into.texture, Rect2(centre - frame.size / 2.0 + into.sprite_offset, frame.size), frame,
				Color(1, 1, 1, 0.6))
	var tower: Tower = _grow_choice.tower
	if is_instance_valid(tower):
		WorldLabel.draw_tag(self, tower.global_position.x, tower.global_position.y - MAP_GRID.cell_size.y,
			"Grow into %s: pick a square (Esc to cancel)" % into.display_name, WorldLabel.cost_color(true))

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
	if frozen_ground():
		_toast_frozen()
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


# --- Drag to build (screens_ui.md "Planting several Wardens: drag to build") ---
# Press and drag in build mode: every cell passed gets the chosen Warden. The stroke locks to the row or
# column after 2 cells (Alt: free); a diagonal jump fills the corner cell. Each cell is planned in drag
# order: green = it will be planted, red = skipped (can't plant here, the path rule given the earlier
# cells, a nightmare on it, settling ground, out of Dew). Release plants all the green ones in order;
# RMB / Esc cancels. A click is a stroke of one. Touch: confirm_on_release = false and the HUD's Plant
# button calls plant_stroke().

signal stroke_changed(active: bool)
const STROKE_SKIP_TINT := Color(1.0, 0.35, 0.35, 0.45)
var stroking := false
var confirm_on_release := true
var _stroke: Array[Vector2] = []  # Cells in drag order
var _stroke_plan := {}  # cell -> "" (plant) or why it's skipped
var _stroke_axis := -1  # -1 not locked yet, 0 = a row (y fixed), 1 = a column (x fixed)
var _stroke_cost := 0
var _stroke_growth := 0

func begin_stroke(cell: Vector2) -> void:
	if cell == NO_CELL or not MAP_GRID.is_within_bounds(cell):
		return
	stroking = true
	_stroke.assign([cell])
	_stroke_axis = -1
	_plan_stroke()
	stroke_changed.emit(true)

# Adds the cells from the stroke's end to `cell`, one step at a time (a diagonal step goes via the corner
# cell). Once the stroke has 2 cells it locks to their row or column unless `free` (Alt).
func extend_stroke(cell: Vector2, free := false) -> void:
	if not stroking or _stroke.is_empty() or not MAP_GRID.is_within_bounds(cell):
		return
	var target := _locked(cell, free)
	var last: Vector2 = _stroke.back()
	while last != target:
		var step := Vector2(signf(target.x - last.x), signf(target.y - last.y))
		if step.x != 0.0 and step.y != 0.0:
			step.y = 0.0  # The corner first
		last += step
		if not _stroke.has(last):
			_stroke.append(last)
		if not free and _stroke_axis == -1 and _stroke.size() >= 2:
			_stroke_axis = 0 if _stroke[1].y == _stroke[0].y else 1
			target = _locked(cell, free)  # Locked now: carry on along the row / column
	_plan_stroke()

func _locked(cell: Vector2, free: bool) -> Vector2:
	if free or _stroke_axis == -1:
		return cell
	return Vector2(cell.x, _stroke[0].y) if _stroke_axis == 0 else Vector2(_stroke[0].x, cell.y)

func cancel_stroke() -> void:
	stroking = false
	_stroke.clear()
	_stroke_plan.clear()
	stroke_changed.emit(false)
	_hover_cell = NO_CELL  # _process refreshes the single ghost
	queue_redraw()

# Plants every green cell in drag order (each re-checked by _try_build). Returns how many.
func plant_stroke() -> int:
	var cells := _stroke.filter(func(c: Vector2) -> bool: return _stroke_plan.get(c, "x") == "")
	stroking = false  # So the builds below refresh the preview normally
	var planted := 0
	for c in cells:
		if _try_build(c):
			planted += 1
	if planted == 0 and not _stroke.is_empty():
		build_rejected.emit(_stroke[0])  # A click on a cell that can't take it (the sound)
	_stroke.clear()
	_stroke_plan.clear()
	stroke_changed.emit(false)
	_hover_cell = NO_CELL
	queue_redraw()
	return planted

func get_stroke_plan() -> Dictionary:
	return _stroke_plan.duplicate()

func get_stroke_cells() -> Array[Vector2]:
	return _stroke.duplicate()

# "6 Thornwalls · 30 Dew · +14 path"
func get_stroke_tag() -> String:
	var count := _stroke_plan.values().count("")
	var name := tower_data.display_name + ("" if count == 1 else "s")
	var tag := "%d %s · %d Dew" % [count, name, _stroke_cost]
	if _stroke_growth != 0:
		tag += " · %+d path" % _stroke_growth
	var skipped := _stroke.size() - count
	if skipped > 0:
		tag += " · %d skipped" % skipped
	return tag

func _stroke_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel_build"):
		cancel_stroke()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and get_viewport().gui_get_hovered_control() == null:
		# (Over a HUD button, e.g. touch's Plant: an emulated nudge mustn't extend the stroke.)
		extend_stroke(MAP_GRID.calculate_grid_coordinates(get_global_mouse_position()), event.alt_pressed)
	elif event.is_action_released("place_tower") and confirm_on_release:
		plant_stroke()
		get_viewport().set_input_as_handled()

func _plan_stroke() -> void:
	_stroke_plan.clear()
	var blocked: Array[Vector2] = []
	var dew := run_state.dew
	var enemy_cells := PackedVector2Array()
	for enemy_cell in _walker_cells():
		enemy_cells.append(enemy_cell)
	var planned_sprouts := 0
	var unique_used := is_unique_placed(tower_data)
	for c in _stroke:
		var cells: Array[Vector2] = [c]
		var why := ""
		if frozen_ground():
			why = "Frozen Ground: plant at the rest"
		elif blocked.has(c) or not map_generator.is_buildable(c):
			why = "can't plant here"
		elif _cells_occupied(cells):
			why = "nightmare here"
		elif settling_left(cells) > 0.0:
			why = "the ground is settling"
		elif unique_used:
			why = "one per run"
		elif not map_generator.can_block_cells(blocked + cells, enemy_cells):
			why = "would close the dream"
		else:
			var cost := get_cost(null, c, planned_sprouts)
			if cost > dew:
				why = "out of Dew"
			else:
				dew -= cost
				blocked.append(c)
				if tower_data.get_id() == "sprout" and cost > 0:
					planned_sprouts += 1  # Each Sprout in the stroke is priced after the ones before it
				unique_used = tower_data.is_unique
		_stroke_plan[c] = why
	_stroke_cost = run_state.dew - dew
	var route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var new_route: PackedVector2Array = map_generator.get_path_if_blocked_cells(blocked) if not blocked.is_empty() else route
	_stroke_growth = new_route.size() - route.size()
	_path_preview.clear_points()
	RouteLine.apply(_path_preview, PREVIEW_COLOR)
	for point in new_route:
		_path_preview.add_point(MAP_GRID.calculate_map_position(point))
	queue_redraw()

func _draw_stroke() -> void:
	for c in _stroke:
		draw_set_transform(MAP_GRID.calculate_map_position(c))
		var ok: bool = _stroke_plan.get(c, "x") == ""
		var tint := VALID_TINT if ok else STROKE_SKIP_TINT
		if tower_data.texture == null:
			Tower.draw_placeholder(self, tint)
		else:
			var frame := tower_data.get_frame_rect(0)
			draw_texture_rect_region(tower_data.texture, Rect2(-frame.size / 2.0 + tower_data.sprite_offset, frame.size), frame, tint)
	if _stroke.is_empty():
		return
	draw_set_transform(MAP_GRID.calculate_map_position(_stroke.back()))
	var last_why: String = _stroke_plan.get(_stroke.back(), "")
	var tag := get_stroke_tag() + ("  ·  %s" % last_why if last_why != "" else "")
	WorldLabel.draw_tag(self, 0.0, MAP_GRID.cell_size.y / 2.0 + 18.0, tag, WorldLabel.cost_color(true))
	draw_set_transform(Vector2.ZERO)

# Heart of the Maze (card, screens_ui.md "Marks that are always on the map"): whether planting the
# selected Warden on `cell` would make it the heart. Same rule as DreamState.get_heart_of_maze (the
# attacker whose nearest route step is furthest from every other attacker's; ties: further along),
# worked out on `route`, the one this placement would make.
func becomes_heart(cell: Vector2, route: PackedVector2Array) -> bool:
	if cell == NO_CELL or route.is_empty() or not tower_data.can_attack or not dream_state.has_card("heart_of_the_maze"):
		return false
	var cells: Array[Vector2] = [cell]
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() and tower.tower_data.can_attack:
			cells.append(tower.cell)
	if cells.size() < 2:
		return false
	var steps: Array[int] = []
	for c in cells:
		var best_step := 0
		var best_distance := INF
		for i in route.size():
			var distance := c.distance_squared_to(route[i])
			if distance < best_distance:
				best_distance = distance
				best_step = i
		steps.append(best_step)
	var best := -1
	var best_gap := -1
	for i in cells.size():
		var gap := 1 << 30
		for j in cells.size():
			if i != j:
				gap = mini(gap, absi(steps[i] - steps[j]))
		if gap > best_gap or (gap == best_gap and steps[i] > steps[best]):
			best_gap = gap
			best = i
	return best == 0

# Frozen Ground (Omen): no planting, growing or nurturing while one of its block's drifts is on (rests,
# selling and clearing are fine). OmenDirector.blocks_building() knows whether it's active.
func frozen_ground() -> bool:
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	return omens != null and omens.has_method("blocks_building") and omens.blocks_building()

var _frozen_toast_at := -100000

func _toast_frozen() -> void:
	var now := Time.get_ticks_msec()
	if now - _frozen_toast_at < 1500:
		return  # One toast per attempt burst (a stroke plants several)
	_frozen_toast_at = now
	var hud := owner.get_node_or_null("HUD") if owner else null
	if hud and hud.has_method("show_toast"):
		hud.show_toast("Frozen Ground: plant at the rest")

# The cells the path rule protects: every walking nightmare's next cell that still has a way out. One
# with no route already (a test nightmare dropped in a closed pocket) can't be cut off, so it doesn't
# block planting.
func _walker_cells() -> PackedVector2Array:
	var cells := PackedVector2Array()
	for enemy in enemy_spawner.get_maze_walkers():
		var target: Vector2 = enemy.get_target_cell()
		if not map_generator.get_path_from(target).is_empty():
			cells.append(target)
	return cells

# The island's rim: the map's outer ring of cells, never buildable (the start and end are on it).
static func is_edge_cell(cell: Vector2) -> bool:
	var last := MAP_GRID.size - Vector2.ONE
	return MAP_GRID.is_within_bounds(cell) and (cell.x <= 0 or cell.y <= 0 or cell.x >= last.x or cell.y >= last.y)
