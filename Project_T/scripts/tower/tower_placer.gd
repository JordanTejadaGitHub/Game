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
const VALID_TINT := Color(Palette.SPRIG, 0.65)
const CATCH_TINT := Color(Palette.GLOW, 0.16)  # Path tiles in a catcher's reach (placement preview)
const INVALID_TINT := Color(Palette.EMBER, 0.65)  # The palette has no red: Ember is "no"
const NO_CELL := Vector2(-1, -1)
const BONUS_ON := Palette.NEWLEAF  # A position card that would be on here
const BONUS_OFF := Palette.STONE  # …off (grey, with the reason)
const BONUS_LOST := Palette.EMBER  # A planted Warden this placement would switch a card off for
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
const KIN_SPOT_COLOR := Color(Palette.NEWLEAF, 0.4)  # Faint green-gold leaf outline
var _path_preview := Line2D.new()
const PREVIEW_COLOR := Color(Palette.DEWLIGHT, 0.6)  # The route preview (RouteLine: high-contrast setting)

# Settling ground (run_design.md "No maze juggling"): during a drift, the cells a Warden was sold from
# can't be planted on again for SETTLE_SECONDS of game time (every footprint cell). Rests are exempt and
# settle everything at once. The rings with their countdown are drawn by a SettlingMarks node in the
# world (this placer hides outside build mode).
const SETTLE_SECONDS := 8.0
const SETTLE_COLOR := Palette.GOLD
var settling := {}  # cell -> game seconds left
var _settling_marks: Node2D = null

func _ready() -> void:
	GiftGround.register_effects()  # Heartwood's Gifts: the Warden-side effects (Spire)
	Tower.placer_ref = weakref(self)  # Tall Wardens fade when the build ghost is behind them
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

# Settling is kept per half cell (user: "selling Wardens between cells locks cells double the size": a half-offset
# Warden's 2×2 halves straddle up to 4 whole cells, and all 4 used to settle). `settling` maps half -> seconds left;
# `_spots` holds each sale's halves for its one ring and countdown.
var _spots: Array = []  # [halves, seconds left]

# The halves a whole cell covers.
static func cell_halves(cells: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for c in cells:
		for dy in 2:
			for dx in 2:
				out.append(c * 2.0 + Vector2(dx, dy))
	return out

# Called by TowerSeller when a Warden is sold: exactly its halves settle. Nothing settles during a rest.
func settle_halves(halves: Array) -> void:
	var director := get_node_or_null("%DriftDirector")
	if director == null or director.is_build_phase() or halves.is_empty():
		return
	for h in halves:
		settling[h] = SETTLE_SECONDS
	_spots.append([halves.duplicate(), SETTLE_SECONDS])
	_marks().queue_redraw()

# Whole cells (a 2×2 form on whole cells): their halves.
func settle(cells: Array) -> void:
	settle_halves(cell_halves(cells))

# Seconds until every one of `halves` can be planted on again (0 = now).
func settling_left_halves(halves: Array) -> float:
	var left := 0.0
	for h in halves:
		left = maxf(left, settling.get(h, 0.0))
	return left

# Seconds until every one of whole `cells` can be planted on again (0 = now): any settling half inside them.
func settling_left(cells: Array) -> float:
	return settling_left_halves(cell_halves(cells))

func clear_settling() -> void:
	settling.clear()
	_spots.clear()
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
	for spot in _spots:
		spot[1] -= delta
	_spots = _spots.filter(func(s: Array) -> bool: return s[1] > 0.0)
	_marks().queue_redraw()
	if build_mode and _hover_cell != NO_CELL:
		queue_redraw()  # The ghost's "settling (5 s)" counts down (_process re-checks validity)

func _hover_cell_valid() -> bool:
	return not frozen_ground() and not _hover_path.is_empty() and not _halves_occupied(_ghost_halves()) \
		and not is_unique_placed(tower_data) and settling_left_halves(_ghost_halves()) <= 0.0 \
		and not omen_locked(_ghost_cells())

func _marks() -> Node2D:
	if not is_instance_valid(_settling_marks):
		_settling_marks = Node2D.new()
		_settling_marks.name = "SettlingMarks"
		_settling_marks.z_index = 2  # Over the ground, under the nightmares' health bars
		_settling_marks.draw.connect(_draw_settling)
		get_parent().add_child(_settling_marks)
	return _settling_marks

# A dashed ring of loose earth over each sold Warden's own footprint, with its countdown.
func _draw_settling() -> void:
	for spot in _spots:
		var halves: Array = spot[0]
		var centre := Vector2.ZERO
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for h in halves:
			lo = Vector2(minf(lo.x, h.x), minf(lo.y, h.y))
			hi = Vector2(maxf(hi.x, h.x), maxf(hi.y, h.y))
		centre = _settling_marks.to_local((lo + hi + Vector2.ONE) * MAP_GRID.cell_size / 4.0)
		var left: float = spot[1]
		var radius := (hi.x - lo.x + 1.0) * MAP_GRID.cell_size.x / 2.0 * 0.72  # 0.36 of a cell for a 1-cell Warden
		var share := clampf(left / SETTLE_SECONDS, 0.0, 1.0)
		for i in 12:
			var from := TAU * i / 12.0
			_settling_marks.draw_arc(centre, radius, from, from + TAU / 24.0, 4, Color(SETTLE_COLOR, 0.35), 2.0)
		_settling_marks.draw_arc(centre, radius, -PI / 2.0, -PI / 2.0 + TAU * share, 32, Color(SETTLE_COLOR, 0.9), 2.5)
		WorldLabel.draw_tag(_settling_marks, centre.x, centre.y + 5.0, "%d" % ceili(left), SETTLE_COLOR)

func set_build_mode(active: bool) -> void:
	if not active and stroking:
		cancel_stroke()
	if not active:
		_shift_chain = false
	build_mode = active
	Tower.set_badges_visible(&"build", active)  # Card badges show in build mode
	_update_visible()
	_hover_cell = NO_CELL
	_hover_half = NO_CELL  # Else a still mouse keeps its old half offset and the ghost waits for a move (user: hotkey, no outline)
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
	if is_choosing_seed():
		if event.is_action_pressed("cancel_build"):
			cancel_seed_choice()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("place_tower"):
			var seedbearer: Tower = _seed_choice.tower
			var cell := MAP_GRID.calculate_grid_coordinates(get_global_mouse_position())
			if _seed_choice.cells.has(cell) and plant_seed(seedbearer, cell) != null:
				cancel_seed_choice()
				if is_instance_valid(seedbearer) and BranchKit.seeds_ready(seedbearer) > 0:
					begin_seed_choice(seedbearer)  # Another seed waiting: pick again
			get_viewport().set_input_as_handled()
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
	if _shift_chain and event is InputEventKey and event.keycode == KEY_SHIFT and not event.pressed:
		_shift_chain = false  # Shift let go after a placement: disarm (unless a line is being dragged)
		if build_mode and not stroking and not keep_building:
			set_build_mode(false)
		return
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
		_update_hover()  # Placement feel: the click places where the cursor is this frame
		if tower_data.footprint > 1:
			after_player_placement(_try_build(_hover_cell))  # Big Wardens: one per click
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
	if is_choosing_seed():
		if not is_instance_valid(_seed_choice.tower) or not Tower.resting:
			cancel_seed_choice()  # Sold, or the drift started
		else:
			_update_seed_choice()
		return
	if not build_mode:
		return
	if stroking:
		return  # The stroke has its own ghosts and route (_stroke_input)
	if not _update_hover():
		_flush_slow()  # The cursor rested a frame: the card preview and heart check catch up
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
	if is_choosing_seed():
		_draw_seed_choice()
		return
	if stroking:
		_draw_stroke()
		return
	_draw_grow_preview()
	_draw_rank_preview()
	_draw_kin_spots()
	if not _catch_preview.is_empty():
		_draw_catch_zone(_catch_preview.at, _catch_preview.radius)
	if _hover_cell == NO_CELL or not MAP_GRID.is_within_bounds(_hover_cell):
		return
	if build_mode:
		_draw_placement_grid()
		_draw_ghost_footprint()
	if tower_data.catch_share > 0.0:
		_draw_catch_zone(_ghost_centre(), tower_data.catch_radius \
			+ (DewCatch.WIDE_BOWL_STEP if dream_state.has_rule(&"dew_trail") else 0.0))  # Dew Trail widens the catch
	# What it would receive here (BuffSources): threads in from each aura, "+30% attack speed from 2 Elder
	# Stumps" above the ghost.
	var received := ""
	if tower_data.can_attack and not AuraView.is_aura(tower_data):
		draw_set_transform(Vector2.ZERO)
		var ghost_at := _ghost_centre()
		var entries := BuffSources.would_receive(tower_data, ghost_at, tower_container.get_children())
		for entry in entries:
			var colour := BuffSources.color(entry.kind, entry.source)
			draw_line(to_local(entry.source.global_position), to_local(ghost_at), Color(colour, 0.18), 4.5)
			draw_line(to_local(entry.source.global_position), to_local(ghost_at), Color(colour, 0.8), 1.5)
		received = BuffSources.summary(entries)
	if AuraView.is_aura(tower_data):  # Exactly who it would boost (AuraView)
		draw_set_transform(Vector2.ZERO)
		AuraView.draw_ghost(self, tower_data, _ghost_centre(),
			tower_container.get_children())
	draw_set_transform(_ghost_centre())
	var tint := VALID_TINT if _hover_valid and _hover_affordable else INVALID_TINT
	if tower_data.can_attack:
		# The range this Warden would really have on this cell (position cards included). A gain shows
		# as the base range faint and the boosted range bright.
		var base_pixels := Tower.range_to_pixels(Tower.get_range_for(tower_data, dream_state))
		var range_pixels := Tower.range_to_pixels(Tower.get_range_for(tower_data, dream_state) + _range_gain)
		if not AuraView.is_aura(tower_data):  # An aura Warden's range stays a thin line beside its aura shape
			draw_circle(Vector2.ZERO, range_pixels, Color(tint, 0.12))
		if _range_gain > 0.0:
			draw_arc(Vector2.ZERO, base_pixels, 0.0, TAU, 64, Color(tint, 0.22), 1.5)
			draw_arc(Vector2.ZERO, range_pixels, 0.0, TAU, 64, Color(BONUS_ON, 0.85), 2.5)
		else:
			draw_arc(Vector2.ZERO, range_pixels, 0.0, TAU, 64, Color(tint, 0.5), 2.0)
	_draw_card_areas()
	if tower_data.special == BranchKit.JARLINK:
		_draw_fence_preview()  # The arc this jar would make (Balancing: players couldn't tell which jar links to which)
	if tower_data.special == BranchKit.BROOD:
		# Brood Cap: the stretch its sprites would walk from here, and where they'd give up.
		var walk := BranchKit.brood_walk(_hover_path if not _hover_path.is_empty() else map_generator.get_path_from(map_generator.startPath),
			_ghost_centre(), float(tower_data.special_params.get("sprite_speed", 3.0)))
		for i in walk.size():
			walk[i] = to_local(walk[i])
		draw_set_transform(Vector2.ZERO)
		BranchKit.draw_brood_walk(self, walk, true)
		draw_set_transform(_ghost_centre())
	if tower_data.texture == null:
		Tower.draw_placeholder(self, tint)
	else:
		var frame := tower_data.get_frame_rect(0)
		draw_texture_rect_region(tower_data.texture, Rect2(-frame.size / 2.0 + tower_data.get_sprite_offset(), frame.size), frame, tint)
	var tag := "%s · %d Dew" % [tower_data.display_name, get_cost(null, _hover_cell)]
	if tower_data.can_attack:
		tag = "%s · %s · %d Dew" % [tower_data.display_name, IconInfo.damage_type_name(tower_data.line), get_cost(null, _hover_cell)]
	if run_state.fertile_cells.has(_hover_cell):
		tag += " (fertile)"
	var growth := get_hover_path_growth()
	if is_edge_cell(_hover_cell) and _hover_cell != map_generator.startPath and _hover_cell != map_generator.endPath:
		tag += " · the dream's edge"  # The island's rim (screens_ui.md "Invalid placement")
	elif frozen_ground():
		tag += " · Frozen Ground: plant at the rest"
	elif is_unique_placed(tower_data):
		tag += " · already planted (one per run)"
	elif settling_left_halves(_ghost_halves()) > 0.0:
		tag += " · The ground is settling (%d s)" % ceili(settling_left_halves(_ghost_halves()))
	elif omen_locked(_ghost_cells()):
		tag += " · the old way is open until the rest"  # Second Path (Omen)
	elif hover_breaks_path():
		tag += " · would close the dream"  # The forest's rule: it may bend, never close
	elif _halves_occupied(_ghost_halves()):
		tag += " · nightmare here"
	elif growth != 0:
		tag += " · %+d path" % growth  # "Wardens are walls": how much longer the walk gets
	if _kin_here != "":
		tag += " · Kin spot: forms %s" % _kin_here
	if _heart_here:
		tag += " · Becomes the Heart of the Maze"
	var broken := get_neighbour_changes().filter(func(change: Array) -> bool: return not change[2])
	if not broken.is_empty():
		# Placing a Warden should never silently weaken others.
		var names := {}
		for change in broken:
			names[change[1]] = names.get(change[1], 0) + 1
		for name in names:
			tag += " · breaks %s on %d Warden%s" % [name, names[name], "" if names[name] == 1 else "s"]
	# Tags at the ghost's real position: WorldLabel.draw_tag sets its own transform (screen-sized text), so a
	# draw_set_transform here would be dropped (user: the tags sat at the map's top left).
	draw_set_transform(Vector2.ZERO)
	var ghost := ghost_tag_origin()
	WorldLabel.draw_tag(self, ghost.x, ghost.y + MAP_GRID.cell_size.y / 2.0 + 18.0, tag,
		WorldLabel.cost_color(_hover_affordable))
	# Bonus chips above the ghost: each position card, on (green, what it gives) or off (grey, why).
	var y := ghost.y - MAP_GRID.cell_size.y / 2.0 - 10.0 + minf(tower_data.get_sprite_offset().y, 0.0)
	if received != "":
		WorldLabel.draw_tag(self, ghost.x, y, received, BuffSources.COLORS.acorn)
		y -= CHIP_STEP
	var cover := coverage_chip()  # maze_feel.md: how much route this spot covers vs the board's best
	if not cover.is_empty():
		WorldLabel.draw_tag(self, ghost.x, y, cover[0], cover[1])
		y -= CHIP_STEP
	for chip in get_ghost_chips():
		WorldLabel.draw_tag(self, ghost.x, y, chip[0], BONUS_ON if chip[1] else BONUS_OFF)
		y -= CHIP_STEP
	# Planted Wardens this placement would switch a card off (red) or on (green) for.
	for change in get_neighbour_changes():
		var tower: Tower = change[0]
		if not is_instance_valid(tower):
			continue
		var at := to_local(tower.global_position)
		WorldLabel.draw_tag(self, at.x, at.y - MAP_GRID.cell_size.y / 2.0 - 6.0,
			("gains %s" if change[2] else "loses %s") % change[1], BONUS_ON if change[2] else BONUS_LOST)
	draw_set_transform(Vector2.ZERO)

# --- Growth preview (screens_ui.md "Preview the growth before growing") -------------------------------

const PREVIEW_ALPHA := 0.6
var _grow_preview: Array = []  # [[Tower, TowerData], …] while a Grow button is pointed at or its key held
var _grow_preview_time := 0.0

# Shows each Warden as the form it would grow into: its sprite in place (translucent, idling), the new
# range bright over the current faint one (a sniper's dead zone too), and a 2×2 form's squares.
func show_grow_preview(pairs: Array) -> void:
	_grow_preview = pairs.filter(func(p: Array) -> bool: return is_instance_valid(p[0]) and is_form_open(p[1]))
	_grow_preview_time = 0.0
	_fade_previewed()
	_update_visible()

func hide_grow_preview() -> void:
	if not _grow_preview.is_empty():
		_grow_preview = []
		_fade_previewed()
		_update_visible()

# While previewed, the Warden itself fades back so the new form's ghost over it reads (windowed check: at
# full strength the two sprites blended into one).
const PREVIEW_FADE := 0.3
var _faded: Array = []

func _fade_previewed() -> void:
	for tower in _faded:
		if is_instance_valid(tower) and tower.sprite:
			tower.sprite.modulate.a = 1.0
	_faded = []
	for pair in _grow_preview:
		var tower: Tower = pair[0]
		if tower.sprite and pair[1].footprint <= tower.get_footprint():  # A 2×2 form shows squares, no ghost
			tower.sprite.modulate.a = PREVIEW_FADE
			_faded.append(tower)

func is_previewing_growth() -> bool:
	return not _grow_preview.is_empty()

# Shown in build mode, while choosing a 2×2 form's square, and while a Warden panel preview is up (grow,
# rank, catch: those come outside build mode; user "hovering Grow into doesn't preview"). The route line
# is build mode's and the square choice's only.
func _update_visible() -> void:
	visible = build_mode or is_choosing_square() or is_choosing_seed() or not _grow_preview.is_empty() \
		or not _rank_preview.is_empty() or not _catch_preview.is_empty()
	_path_preview.visible = build_mode or is_choosing_square() or is_choosing_seed()
	queue_redraw()

# Nurture range preview (user: "hovering Nurture range should show the range it would go into"): while the
# Nurture button or a rank choice is pointed at, each Warden that would rank shows its current range faint
# and, if the rank widens it (Reach), the new range bright. [[Tower, range now, range after], …]
var _rank_preview: Array = []

func show_rank_preview(towers: Array, focus: Tower.Focus = Tower.Focus.NONE) -> void:
	_rank_preview = []
	for tower in towers:
		if is_instance_valid(tower) and tower.can_nurture() and tower.tower_data.can_attack:
			_rank_preview.append([tower, tower.get_range_cells(), range_after_rank(tower, focus)])
	_update_visible()

func hide_rank_preview() -> void:
	if not _rank_preview.is_empty():
		_rank_preview = []
		_update_visible()

func rank_preview() -> Array:
	return _rank_preview

# The real range `tower` would have after one more rank of `focus` (the same getters as combat: Dreams,
# Kinships, rank and Focus bonuses): the rank is tried on the Warden and put back.
func range_after_rank(tower: Tower, focus: Tower.Focus = Tower.Focus.NONE) -> float:
	var rank_before: int = tower.rank
	var choices_before: Array = tower.rank_choices.duplicate()
	tower.rank += 1
	if focus != Tower.Focus.NONE:
		tower.rank_choices.append(focus)
	tower.clear_dream_cache()
	var after := tower.get_range_cells()
	tower.rank = rank_before
	tower.rank_choices.assign(choices_before)
	tower.clear_dream_cache()
	return after

func _draw_rank_preview() -> void:
	for entry in _rank_preview:
		var tower: Tower = entry[0]
		if not is_instance_valid(tower):
			continue
		draw_set_transform(to_local(tower.global_position))
		var now_px := Tower.range_to_pixels(entry[1])
		var after_px := Tower.range_to_pixels(entry[2])
		if after_px - now_px >= 2.0:
			draw_arc(Vector2.ZERO, now_px, 0.0, TAU, 64, Color(VALID_TINT, 0.25), 1.5)
			draw_circle(Vector2.ZERO, after_px, Color(BONUS_ON, 0.08))
			draw_arc(Vector2.ZERO, after_px, 0.0, TAU, 64, Color(BONUS_ON, 0.85), 2.5)
		else:
			draw_arc(Vector2.ZERO, now_px, 0.0, TAU, 64, Color(VALID_TINT, 0.5), 2.0)  # Same reach: the current ring
	draw_set_transform(Vector2.ZERO)

# The range `tower` would have as `into`: its own extras (ranks, Focus, cards) kept on the new base.
func preview_range(tower: Tower, into: TowerData) -> float:
	return range_as(tower, into, dream_state)

static func range_as(tower: Tower, into: TowerData, dreams: DreamState) -> float:
	return tower.get_range_cells() - Tower.get_range_for(tower.tower_data, dreams) + Tower.get_range_for(into, dreams)

# Only a form unlocked this run is previewed on the map (user: "only if you have it unlocked"); a locked one
# (Dreamlight on Remember, or the Memory Grove) shows no ring and no ghost.
func is_form_open(into: TowerData) -> bool:
	return into != null and (dream_state == null or dream_state.is_unlocked(into.get_id()))

# The Grow tooltip's headline (story chat 2026-10-01): "Thunderhead: damage 30 → 48, chains 3 → 5, range 3.0 → 3.5".
func grow_changes(tower: Tower, into: TowerData) -> String:
	return describe_growth(tower, into, dream_state)

static func describe_growth(tower: Tower, into: TowerData, dreams: DreamState) -> String:
	var from := tower.tower_data
	var parts: Array[String] = []
	if into.can_attack and from.can_attack and from.damage > 0:
		var now := tower.get_damage()
		var then := now * float(into.damage) / float(from.damage)
		if roundi(then) != roundi(now):
			parts.append("damage %d → %d" % [roundi(now), roundi(then)])
		var speed := tower.get_attacks_per_second()
		var faster := speed * into.attacks_per_second / maxf(from.attacks_per_second, 0.01)
		if absf(faster - speed) >= 0.05:
			parts.append("speed %.1f → %.1f/s" % [speed, faster])
			# Damage and speed both move: their product (warden_stats.md "Branches: pricier and worth it").
			var ratio := (then * faster) / maxf(now * speed, 0.001)
			if absf(ratio - 1.0) >= 0.05:
				parts.append("%.1f× damage per second" % ratio)
	elif into.can_attack and not from.can_attack:
		parts.append("damage %d" % into.damage)
	if into.chain_targets > 0 and into.chain_targets != from.chain_targets:
		parts.append("chains %d → %d" % [from.chain_targets, into.chain_targets] if from.chain_targets > 0 else "chains to %d" % into.chain_targets)
	var reach := range_as(tower, into, dreams)
	if into.can_attack and absf(reach - tower.get_range_cells()) >= 0.05:
		parts.append("range %.1f → %.1f" % [tower.get_range_cells(), reach])
	if into.min_range > 0.0 and into.min_range != from.min_range:
		parts.append("can't hit within %.1f" % into.min_range)
	if into.applies_status != &"" and into.applies_status != from.applies_status:
		parts.append("adds %s" % IconInfo.status_name(into.applies_status))
	return into.display_name + (": " + ", ".join(parts) if not parts.is_empty() else "")

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
		if into.aura_radius > 0.0:  # A form with an aura: the cells it would cover (open "grow aura previews" item)
			var reach := Tower.range_to_pixels(into.aura_radius)
			draw_arc(Vector2.ZERO, reach, 0.0, TAU, 48, Color(BuffSources.color(into.get_id()), 0.7), 2.0)
		if into.texture == null:
			Tower.draw_placeholder(self, Color(1, 1, 1, PREVIEW_ALPHA))
		else:
			var frame := into.get_frame_rect(int(_grow_preview_time * into.animation_fps) % maxi(into.frame_count, 1))
			draw_texture_rect_region(into.texture, Rect2(-frame.size / 2.0 + into.get_sprite_offset(), frame.size), frame,
				Color(1, 1, 1, PREVIEW_ALPHA))
	draw_set_transform(Vector2.ZERO)

# --- Catcher placement preview (screens_ui.md "Support and economy feedback") ---------------------

var _catch_preview := {}  # {"at": world position, "radius": cells} while the Warden panel asks

# Shades the path tiles a catcher at `at` (world) would catch on, with the share of last block's
# dispels there. The Warden panel shows it for a selected catcher and while "Grow into Dewcatcher" is
# pointed at; the build ghost shows it for a catcher.
func show_catch_preview(at: Vector2, radius: float) -> void:
	_catch_preview = {"at": at, "radius": radius}
	_update_visible()

func hide_catch_preview() -> void:
	if not _catch_preview.is_empty():
		_catch_preview = {}
		_update_visible()

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
	_flush_slow()
	var chips := []
	for row in _ghost_rows:
		if row.active:
			chips.append(["%s ✓ %s" % [row.name, row.get("effect", "")], true])
		else:
			chips.append(["%s ✗ %s" % [row.name, row.get("reason", "")], false])
	return chips

# --- Coverage (maze_feel.md 8b50fce6: "only upgrade at the right spots where it covers everything") ---
# The ghost's chip: path tiles inside its range on the route it would leave (every pass counts), tinted by how the
# spot compares with the board's best open cell for this Warden's range (cached per board version).
const COVER_GOOD := 0.85  # At least this share of the best: a top spot (BONUS_ON)
const COVER_OK := 0.5  # At least this: fair (GLOW); below: a poor spot (BONUS_OFF)
var _best_cover := {}  # "board:range" -> path tiles at the best open cell

static func coverage_on(route: PackedVector2Array, centre: Vector2, range_px: float, min_px: float = 0.0) -> int:
	var points := 0
	for p in route:
		var d := centre.distance_squared_to(MAP_GRID.calculate_map_position(p))
		if d <= range_px * range_px and d >= min_px * min_px:
			points += 1
	return roundi(points / 2.0)

func ghost_coverage() -> int:
	if tower_data == null or not tower_data.can_attack or _hover_cell == NO_CELL:
		return 0
	var route: PackedVector2Array = _hover_path if not _hover_path.is_empty() else map_generator.get_path_from(map_generator.startPath)
	var range_px := Tower.range_to_pixels(Tower.get_range_for(tower_data, dream_state) + _range_gain)
	return coverage_on(route, _ghost_centre(), range_px, tower_data.min_range * MAP_GRID.cell_size.x)

# The most path tiles any open cell's centre covers with this range (each route point adds to the cells around it).
func best_coverage() -> int:
	var range_px := Tower.range_to_pixels(Tower.get_range_for(tower_data, dream_state) + _range_gain)
	var key := "%d:%d" % [dream_state.board_version, roundi(range_px)]
	if _best_cover.has(key):
		return _best_cover[key]
	var reach := int(ceil(range_px / MAP_GRID.cell_size.x))
	var counts := {}
	for p in map_generator.get_path_from(map_generator.startPath):
		var at := MAP_GRID.calculate_map_position(p)
		var home := MAP_GRID.calculate_grid_coordinates(at)
		for dy in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				var c := home + Vector2(dx, dy)
				if MAP_GRID.calculate_map_position(c).distance_squared_to(at) <= range_px * range_px:
					counts[c] = counts.get(c, 0) + 1
	var best := 0
	for c in counts:
		if counts[c] > best and map_generator.is_buildable(c):
			best = counts[c]
	_best_cover = {key: roundi(best / 2.0)}  # Only the current board's answer is kept
	return _best_cover[key]

# [text, colour] for the ghost's coverage chip, or [] for Wardens that don't attack.
func coverage_chip() -> Array:
	if tower_data == null or not tower_data.can_attack or _hover_cell == NO_CELL:
		return []
	var covers := ghost_coverage()
	var best := maxi(best_coverage(), 1)
	var share := float(covers) / best
	var colour: Color = BONUS_ON if share >= COVER_GOOD else (Palette.GLOW if share >= COVER_OK else BONUS_OFF)
	return ["covers %d path tiles%s" % [covers, " · a top spot" if covers >= best else ""], colour]

# Planted Wardens whose position cards this placement would turn off or on: [[tower, card name, on]].
func get_neighbour_changes() -> Array:
	_flush_slow()
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
	if _before_board != dream_state.board_version:
		_before_board = dream_state.board_version  # The board changed: every "without the ghost" answer is stale
		_before_cache.clear()
	for tower in tower_container.get_children():
		if not tower is Tower or tower.is_queued_for_deletion() \
				or maxf(absf(tower.cell.x - _hover_cell.x), absf(tower.cell.y - _hover_cell.y)) > reach:
			continue
		var id: int = tower.get_instance_id()
		if not _before_cache.has(id):  # Without the ghost it only changes with the board (half the card checks)
			_before_cache[id] = _active_positional(dream_state.get_card_effects(tower.tower_data, tower.cell, tower))
		var before: Array = _before_cache[id]
		var after := _active_positional(dream_state.get_card_effects(tower.tower_data, tower.cell, tower, ghost))
		for name in before:
			if not after.has(name):
				_neighbour_changes.append([tower, name, false])
		for name in after:
			if not before.has(name):
				_neighbour_changes.append([tower, name, true])

var _before_cache := {}  # Tower instance id -> its active position cards without the ghost (this board version)
var _before_board := -1

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
# Jarlink's build ghost: the arc to the jar it would link with (BranchKit.fence_partner_at) and the cells it covers.
func _draw_fence_preview() -> void:
	var reach := float(tower_data.special_params.get("link_range", 4.5))
	var partner := BranchKit.fence_partner_at(self, _hover_cell, reach)
	draw_set_transform(Vector2.ZERO)
	var here := to_local(MAP_GRID.calculate_map_position(_hover_cell))
	# Its link range (user 2026-10-05: "have Jarlink have its range connection"), and every jar inside it.
	BranchKit.draw_link_area(self, here, reach)
	for other in get_tree().get_nodes_in_group(Tower.GROUP):
		if other is Tower and other.attack_data != null and other.attack_data.special == BranchKit.JARLINK \
				and BranchKit.area_distance_at(MAP_GRID.calculate_map_position(_hover_cell), other) <= reach:
			BranchKit.draw_link_mark(self, to_local(other.global_position), other == partner)
	if partner != null:
		var to := to_local(partner.global_position)
		for cell in BranchKit._arc_cells(_hover_cell, partner.cell):
			var rect := Rect2(to_local(MAP_GRID.calculate_map_position(cell)) - MAP_GRID.cell_size / 2.0, MAP_GRID.cell_size)
			draw_rect(rect.grow(-4), Color(BranchKit.LINK_COLOR, 0.12))
		draw_dashed_line(here, to, Color(BranchKit.LINK_COLOR, 0.8), 2.0, 6.0)  # The arc it would make
	else:
		WorldLabel.draw_tag(self, here.x, here.y - MAP_GRID.cell_size.y - 10.0,
			"no Jarlink within %s cells" % IconInfo._number(reach), Color(BranchKit.LINK_COLOR, 0.9))
	draw_set_transform(_ghost_centre())

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

# Where the ghost's tags hang from (this node's space): the hovered footprint's centre. Tested: never the map origin.
func ghost_tag_origin() -> Vector2:
	return to_local(_ghost_centre())

# --- Half-cell placement (documentation/half_cells.md) ---
# A 1-cell Warden snaps to the half grid: its 2×2 half-cell footprint's top-left half is _hover_half, and
# _hover_cell is the full cell under its centre (ranges, cards, Kinship spots keep full cells). Bigger Wardens
# (the Sapling) stay on whole cells.

var _hover_half := NO_CELL
# Marketing captures (CaptureDirector's "ghost" actions) aim the build ghost here instead of at the mouse; INF = the mouse.
var cursor_override := Vector2(INF, INF)

func half_placement() -> bool:
	return tower_data != null and tower_data.footprint <= 1 and map_generator.has_method("halves_of")

# The top-left half of a 2×2 footprint centred nearest `world` (pixels).
static func half_origin_at(world: Vector2) -> Vector2:
	return (world / (MAP_GRID.cell_size / 2.0)).round() - Vector2.ONE

# Twig Walls (Dream card, dream_design.md c6fefe1b): while held, a Thornwall planted takes the one half cell under the
# cursor and costs half (rounded up, at least 1). DreamState.twig_walls() (Roguelite Code); force_twig for tests.
var force_twig := false

func twig_mode(data: TowerData = null) -> bool:
	var warden := data if data != null else tower_data
	if warden == null or warden.get_id() != "thornwall":
		return false
	return force_twig or (dream_state != null and dream_state.has_method("twig_walls") and dream_state.twig_walls())

# A placement origin (the half the ghost snaps to) and what it means: a 2×2's top-left half, or a twig wall's own half.
func origin_at(world: Vector2) -> Vector2:
	return (world / (MAP_GRID.cell_size / 2.0)).floor() if twig_mode() else half_origin_at(world)

func origin_centre(origin: Vector2) -> Vector2:
	return Tower.twig_centre(origin) if twig_mode() else Tower.half_centre(origin)

func origin_home(origin: Vector2) -> Vector2:
	return Tower.twig_home_cell(origin) if twig_mode() else Tower.half_home_cell(origin)

func origin_halves(origin: Vector2) -> Array[Vector2]:
	if twig_mode():
		var one: Array[Vector2] = [origin]
		return one
	return map_generator.halves_of(origin)

# The ghost's centre (pixels), its half cells, and the full cells they touch.
func _ghost_centre() -> Vector2:
	return origin_centre(_hover_half) if half_placement() and _hover_half != NO_CELL \
		else Tower.footprint_centre(_hover_cell, tower_data.footprint)

func _ghost_halves() -> Array[Vector2]:
	if half_placement() and _hover_half != NO_CELL:
		return origin_halves(_hover_half)
	var out: Array[Vector2] = []
	for c in _footprint(_hover_cell):
		for dy in 2:
			for dx in 2:
				out.append(c * 2.0 + Vector2(dx, dy))
	return out

func _ghost_cells() -> Array[Vector2]:
	return Tower.cells_of_halves(_ghost_halves()) if half_placement() else _footprint(_hover_cell)

# A nightmare's body is on (or stepping into) any of `halves`.
func _halves_occupied(halves: Array) -> bool:
	var bodies := _walker_bodies()
	for h in halves:
		if bodies.has(h):
			return true
	return false

# The half cells under every walking nightmare's body (where it is and where it's stepping), built once a frame:
# the hover asks every frame and strokes per cell (150 walkers × 2 points × 4 halves was ~0.9 ms a check).
var _bodies := {}
var _bodies_frame := -1

func _walker_bodies() -> Dictionary:
	var frame := Engine.get_process_frames()
	if frame == _bodies_frame:
		return _bodies
	_bodies_frame = frame
	_bodies = {}
	for enemy in enemy_spawner.get_maze_walkers():
		for point in [enemy.get_target_cell(), enemy.get_last_cell() if enemy.has_method("get_last_cell") else enemy.get_current_cell()]:
			for h in map_generator.body_halves(point):
				_bodies[h] = true
	return _bodies

func _ghost_buildable() -> bool:
	if half_placement():
		return _ghost_halves().all(func(h: Vector2) -> bool: return map_generator.is_buildable_half(h))
	return _footprint(_hover_cell).all(func(c: Vector2) -> bool: return map_generator.is_buildable(c))

# How many tiles longer creatures would walk if the ghost were built (0 if it can't be).
func get_hover_path_growth() -> int:
	if _hover_path.is_empty():
		return 0
	return map_generator.route_length(_hover_path) - map_generator.route_length(map_generator.get_path_from(map_generator.startPath))

# The hovered cell is free but building there would cut creatures off (the forest's rule).
func hover_breaks_path() -> bool:
	return build_mode and _hover_cell != NO_CELL and _ghost_buildable() and _hover_path.is_empty()

# Recomputes the route preview for the hovered cell (only needed when the cell or the maze changes).
const HOVER_DEAD_ZONE := 4.0  # Pixels past a half line before the ghost changes offset (no flicker on the line)

# --- Placement grid (half_cells.md "Placement feel"): in build mode, faint whole-cell lines over buildable ground,
# half lines near the cursor, the ghost's 2×2 outlined in gold and its refused halves in the "can't" colour. Setting
# `placement_grid`: 0 On (default), 1 Near cursor, 2 Off.
const GRID_LINE := Color(Palette.MOONLIGHT, 0.08)
const GRID_HALF_LINE := Color(Palette.MOONLIGHT, 0.05)
const GRID_NEAR := 3.0  # Cells around the cursor that show half lines (and, in Near cursor mode, all lines)
const GRID_FOOTPRINT := Color(Palette.GOLD, 0.9)
const GRID_REFUSED := Color(Palette.EMBER, 0.35)  # The palette has no red: Ember is "no" (INVALID_TINT's colour)

func _draw_placement_grid() -> void:
	var mode := int(Fx.setting("placement_grid", 0))
	if mode >= 2 or not half_placement():
		return
	draw_set_transform(Vector2.ZERO)
	var size := MAP_GRID.cell_size
	var cursor := _ghost_centre()
	var near := GRID_NEAR * size.x
	var lines := PackedVector2Array()
	var halves := PackedVector2Array()
	for y in MAP_GRID.size.y:
		for x in MAP_GRID.size.x:
			var cell := Vector2(x, y)
			if not map_generator.is_buildable(cell):
				continue
			var centre := MAP_GRID.calculate_map_position(cell)
			var close := centre.distance_to(cursor) <= near
			if mode == 1 and not close:
				continue
			var tl := to_local(centre - size / 2.0)
			lines.append_array([tl, tl + Vector2(size.x, 0), tl, tl + Vector2(0, size.y)])  # Top and left edges
			if not map_generator.is_buildable(cell + Vector2.RIGHT):
				lines.append_array([tl + Vector2(size.x, 0), tl + size])
			if not map_generator.is_buildable(cell + Vector2.DOWN):
				lines.append_array([tl + Vector2(0, size.y), tl + size])
			if close:  # Half lines through the cell
				halves.append_array([tl + Vector2(size.x / 2.0, 0), tl + Vector2(size.x / 2.0, size.y),
					tl + Vector2(0, size.y / 2.0), tl + Vector2(size.x, size.y / 2.0)])
	if not lines.is_empty():
		draw_multiline(lines, GRID_LINE, 1.0)
	if not halves.is_empty():
		draw_multiline(halves, GRID_HALF_LINE, 1.0)

# The ghost's 2×2 halves: refused ones (taken, unbuildable, a nightmare on it, or the whole footprint when it would
# close the route) filled in the "can't" colour, then the footprint outlined in gold.
func _draw_ghost_footprint() -> void:
	if not half_placement() or _hover_half == NO_CELL:
		return
	draw_set_transform(Vector2.ZERO)
	var half := MAP_GRID.cell_size / 2.0
	var bodies := _walker_bodies()
	var closes := _ghost_buildable() and _hover_path.is_empty()
	for h in _ghost_halves():
		if closes or not map_generator.is_buildable_half(h) or bodies.has(h):
			draw_rect(Rect2(to_local(h * half), half), GRID_REFUSED)
	draw_rect(Rect2(to_local(_hover_half * half), half * (1.0 if twig_mode() else 2.0)), GRID_FOOTPRINT, false, 1.5)

# Moves the ghost to the cursor (the same frame it crosses a half line, past a 4 px dead zone). Returns whether it
# moved; the route, validity and price refresh at once, the card preview a frame later.
func _update_hover() -> bool:
	var mouse := get_global_mouse_position() if cursor_override.x == INF else cursor_override
	if half_placement():
		var origin := origin_at(mouse)
		if origin != _hover_half and _hover_half != NO_CELL:
			var off := (mouse - origin_centre(_hover_half)).abs()
			# Half a half cell (a twig wall: half of its own half), + the dead zone
			var hold := MAP_GRID.cell_size.x / (8.0 if twig_mode() else 4.0) + HOVER_DEAD_ZONE
			if off.x < hold and off.y < hold:
				origin = _hover_half  # Still inside the dead zone around the current offset
		if origin == _hover_half:
			return false
		_hover_half = origin
		_hover_cell = origin_home(origin)
	else:
		var cell: Vector2 = MAP_GRID.calculate_grid_coordinates(mouse)
		if cell == _hover_cell:
			return false
		_hover_cell = cell
		_hover_half = NO_CELL
	_refresh_hover(true)
	return true

# `defer`: the per-frame hover passes true, so the card preview and the heart check follow a frame later (placement
# feel: they were ~6 ms of a full board's refresh) and the ghost itself never waits.
func _refresh_hover(defer := false) -> void:
	if stroking:
		_plan_stroke()  # The maze changed under the stroke
		return
	_hover_path = PackedVector2Array()
	if _ghost_buildable():
		_hover_path = map_generator.get_path_if_blocked_halves(_ghost_halves(), true) if half_placement() \
			else map_generator.get_path_if_blocked_cells(_footprint(_hover_cell), true)  # As it will be drawn
	# Route mist (screens_ui.md): the new route, the old one faint where it differs, a glint when it gets longer.
	RouteLine.draw_route(_path_preview, _hover_path, PREVIEW_COLOR, 6.0, map_generator.get_path_from(map_generator.startPath))
	_hover_valid = _hover_cell_valid()
	_hover_affordable = run_state.can_afford(get_cost(null, _hover_cell))
	_slow_due = true
	if not defer:
		_flush_slow()  # Callers that read the rows right away (tests, a path change)
	queue_redraw()

# The slower parts of the hover (card rows, neighbour changes, Kinship spots, Heart of the Maze): a frame after the
# ghost moved, so the ghost itself never waits on them. Getters flush them first, so callers always see current rows.
var _slow_due := false

func _flush_slow() -> void:
	if not _slow_due:
		return
	_slow_due = false
	_heart_here = becomes_heart(_hover_cell, _hover_path)
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
	if half_placement():
		return _try_build_half(cell * 2.0)  # A whole cell = the half origin on its corner (callers, tests)
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
	if omen_locked(_footprint(cell)):
		build_rejected.emit(cell)  # Second Path: the crumbled wall's cells stay open until the rest
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
	tower.plant_dew = cost  # What it was planted for (a Sprout growing into a base: the copy floor)
	if tower_data.get_id() == "sprout" and cost == 0:
		tower.set_meta(&"gift_sprout", true)  # A Seedling Gift charge: never raises the Sprout price
	tower.rest_dew = cost if Tower.resting else 0  # Placed this rest: a full refund until Start
	tower.position = Tower.footprint_centre(cell, tower_data.footprint)
	tower_container.add_child(tower)
	map_generator.block_cells(_footprint(cell))  # Emits path_changed -> enemies re-route, preview refreshes
	BranchKit.on_planted(tower)  # Mother Log: a remembered rank for this cell
	tower_built.emit(tower)
	if tower_data == sapling:
		sapling_planted.emit(tower)
		set_build_mode(false)
	return true

# Half-cell placement: plants the selected 1-cell Warden with its 2×2 half footprint's top-left half at `origin`.
func _try_build_half(origin: Vector2) -> bool:
	var home := origin_home(origin)
	if tower_data == null or tower_data.parked or is_unique_placed(tower_data):
		build_rejected.emit(home)
		return false
	if frozen_ground():
		_toast_frozen()
		build_rejected.emit(home)
		return false
	var halves: Array[Vector2] = origin_halves(origin)  # A twig wall: its one half
	var touched := Tower.cells_of_halves(halves)
	if settling_left_halves(halves) > 0.0 or omen_locked(touched) or _halves_occupied(halves):
		build_rejected.emit(home)
		return false
	if not map_generator.can_block_halves(halves, _walker_points()):
		build_rejected.emit(home)
		return false
	var cost := get_cost(null, home)
	if not run_state.spend_dew(cost):
		return false
	run_state.fertile_cells.erase(home)
	var tower: Tower = tower_scene.instantiate()
	tower.tower_data = tower_data
	tower.half_cell = origin
	tower.cell = home
	tower.invested_dew = cost
	tower.plant_dew = cost  # What it was planted for (a Sprout growing into a base: the copy floor)
	if tower_data.get_id() == "sprout" and cost == 0:
		tower.set_meta(&"gift_sprout", true)
	tower.rest_dew = cost if Tower.resting else 0
	tower.twig = twig_mode()
	tower.position = origin_centre(origin)
	tower_container.add_child(tower)
	map_generator.block_halves(halves)  # Emits path_changed -> enemies re-route, preview refreshes
	BranchKit.on_planted(tower)
	tower_built.emit(tower)
	return true

# The route points the path rule protects (walkers' targets with a way out), for can_block_halves.
func _walker_points() -> PackedVector2Array:
	return _walker_cells()

# Dew to plant the selected Warden (Dreams can change it, e.g. Cheap Hedges). With `cell`, the price
# on that cell (Reclaimed Earth: fertile cells halve the first Warden).
func get_cost(data: TowerData = null, cell: Vector2 = NO_CELL, planned_sprouts: int = 0) -> int:
	var warden := data if data != null else tower_data
	var cost: int = dream_state.get_build_cost(warden) if cell == NO_CELL else dream_state.get_build_cost_at(warden, cell)
	var gifts := GiftGround.active_for(self)
	if gifts:
		cost = roundi(cost * gifts.cost_multiplier(warden))  # Heartwood's Gifts: planting prices (none change them now; Bramble Verge makes growing Bramble free instead)
	# Sprouts get pricier as you plant (warden_stats.md "Sprouts cost more, walls do the maze"): every
	# sprout_per_step() Sprouts on the map add sprout_step_dew() to the next one (12, 16, 20, …); Seedling
	# Gift Sprouts don't count and a free one stays free. Seedfall (the card sets the start): +2 per 5 instead
	# of +4. `planned_sprouts`: Sprouts earlier in the same drag stroke.
	if warden.get_id() == "sprout" and cost > 0:
		var per_step := sprout_per_step()
		if per_step > 0:
			cost += (count_paid_sprouts() + planned_sprouts) / per_step * sprout_step_dew()
	# Copies (user via Balancing 2026-10-04, demo too: mass-planting one base beat act 1 at any grow price): each
	# planted Warden of a kind costs +copy_cost_step per copy of that kind already on the map (selling lowers it);
	# walls are exempt (they're the maze), grown forms count under their own id. `planned_sprouts` = copies earlier in
	# the same drag stroke (a stroke plants one kind).
	# Sprouts are exempt too (Balancing 2026-10-04): they have their own step above, and 5 must still fit the 60 Dew opening.
	if copy_cost_step > 0.0 and cost > 0 and warden.buildable_directly and warden.line != "wall" and warden.get_id() != "sprout":
		cost = roundi(cost * (1.0 + copy_cost_step * (count_copies(warden) + planned_sprouts)))
	if cost > 0 and twig_mode(warden):
		cost = maxi(ceili(cost / 2.0), 1)  # Twig Walls: half a wall's price, rounded up, at least 1
	return cost

@export var copy_cost_step := 0.08  # +8% per copy on the map (be7b5a94; was 0.05. 0 = off, the sims' A/B)
var _copy_counts := {}  # id -> planted copies, rebuilt when the board changes
var _copy_board := -1

# Planted Wardens of `data`'s kind on the map (Seedling Gift Sprouts don't count, as for the Sprout price).
func count_copies(data: TowerData) -> int:
	# DreamState.board_version moves on every plant, sale (path_changed, exiting the tree) and grow (evolved).
	var board: int = dream_state.board_version if dream_state else -2
	if board != _copy_board or board == -2:
		_copy_board = board
		_copy_counts = {}
		for tower in tower_container.get_children():
			if tower is Tower and not tower.is_queued_for_deletion() and not tower.get_meta(&"gift_sprout", false):
				var id: String = tower.tower_data.get_id()
				_copy_counts[id] = _copy_counts.get(id, 0) + 1
	return _copy_counts.get(data.get_id(), 0)

func sprout_price_halved() -> bool:
	return dream_state.has_card(SEEDFALL_CARD)

const SEEDFALL_CARD := "seedfall"
const SPROUTS_PER_STEP := 5  # Every 5 Sprouts on the map…
const SPROUT_STEP_DEW := 4  # …add +4 Dew to the next one
const SEEDFALL_SPROUTS_PER_STEP := 5  # Seedfall: the price rises half as fast…
const SEEDFALL_STEP_DEW := 2  # …+2 per 5

# The Sprout price rule now (Seedfall or not), for the HUD's tooltip, ↑ tag and toast.
func sprout_per_step() -> int:
	return SEEDFALL_SPROUTS_PER_STEP if sprout_price_halved() else SPROUTS_PER_STEP

func sprout_step_dew() -> int:
	return SEEDFALL_STEP_DEW if sprout_price_halved() else SPROUT_STEP_DEW

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
	if tower.twig:
		return false  # Twig Walls: a twig wall stays a wall (a Bramble needs a full footprint; sell and replant)
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
	if into.tier == DreamState.ASCENDED_TIER - 1 and not _finals_grown.has(into.get_id()):
		_finals_grown[into.get_id()] = true  # The first of each final form this run gets its bloom
		Fx.final_bloom(tower, into.display_name)
		tower.final_bloomed.emit(tower)
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
			if map_generator.has_method("halves_of"):  # Half cells: checked by halves (Environment 731000c5)
				if _square_ok_halves(tower, origin, size):
					squares.append(origin)
				continue
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

# Half cells: the square at `origin` takes only open halves, the Warden's own and Thornwalls it absorbs; no nightmare
# or settling ground on it; blocking its open halves never closes the route.
func _square_ok_halves(tower: Tower, origin: Vector2, size: int) -> bool:
	var cells := Tower.footprint_cells(origin, size)
	if cells.any(func(c: Vector2) -> bool: return not MAP_GRID.is_within_bounds(c)):
		return false
	var halves := _square_halves(origin, size)
	if not _square_takeable(tower, halves) or _halves_occupied(halves) or settling_left(cells) > 0.0:
		return false
	var open: Array[Vector2] = []
	for h in halves:
		if map_generator.is_buildable_half(h):
			open.append(h)
	return open.is_empty() or map_generator.can_block_halves(open, _walker_points())

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

# Half cells (Environment 731000c5: whole-cell grid calls are wrong for half-offset Wardens): the halves of a square, the
# Thornwalls a grow there absorbs (any wall with a half in it: half-offset and twig walls too, several per cell), and
# whether every taken half of the square is the growing Warden's own or such a wall's.
func _square_halves(origin: Vector2, size: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for c in Tower.footprint_cells(origin, size):
		for dy in 2:
			for dx in 2:
				out.append(c * 2.0 + Vector2(dx, dy))
	return out

func _walls_in_halves(halves: Array[Vector2], skip: Tower) -> Array[Tower]:
	var walls: Array[Tower] = []
	for other in tower_container.get_children():
		if other is Tower and other != skip and not other.is_queued_for_deletion() \
				and other.tower_data.get_id() == "thornwall" and other.get_footprint() == 1 \
				and other.get_halves().any(func(h: Vector2) -> bool: return halves.has(h)):
			walls.append(other)
	return walls

func _square_takeable(tower: Tower, halves: Array[Vector2]) -> bool:
	var owned := {}
	for h in tower.get_halves():
		owned[h] = true
	for wall in _walls_in_halves(halves, tower):
		for h in wall.get_halves():
			owned[h] = true
	for h in halves:
		if not map_generator.is_buildable_half(h) and not owned.has(h):
			return false  # Another Warden, an obstacle, start / end, the border
	return true

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
	if map_generator.has_method("halves_of"):
		_take_square_halves(tower, origin, size)
		return
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
	if tower.half_cell.x >= 0 and map_generator.has_method("unblock_halves"):
		# Half cells: a Warden at a half offset grows onto whole cells; its old halves open first, and its
		# own cell in the square is blocked whole with the rest.
		map_generator.unblock_halves(tower.get_halves())
		tower.half_cell = Vector2(-1, -1)
		if not free.has(tower.cell):
			free.append(tower.cell)
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

# Half cells: absorbs every Thornwall with a half in the square (half-offset and twig walls too; their Dew back in
# full, their halves opened), opens the Warden's old halves, moves it, then blocks the square's halves exactly.
func _take_square_halves(tower: Tower, origin: Vector2, size: int) -> void:
	var halves := _square_halves(origin, size)
	for wall in _walls_in_halves(halves, tower):
		run_state.earn_dew_at(wall.invested_dew, wall.global_position)  # Absorbed: refunded in full
		map_generator.unblock_halves(wall.get_halves())
		tower_container.remove_child(wall)
		wall.queue_free()
	map_generator.unblock_halves(tower.get_halves())
	tower.half_cell = Vector2(-1, -1)
	var old_cell := tower.cell
	tower.cell = origin
	tower.position = Tower.footprint_centre(origin, size)
	Tower.towers_moved()  # Its neighbour buckets
	tower.footprint_size = size  # It has its room now (Tower.evolve keeps the size it's given)
	var kin := Kinships.find(self)
	if kin:
		kin.note_moved(tower, old_cell)  # The bond keeps its age (evolving keeps it)
	map_generator.block_halves(halves)  # Emits path_changed: nightmares re-route


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
	_update_visible()
	grow_choice_changed.emit(true)
	queue_redraw()
	return true

func is_choosing_square() -> bool:
	return not _grow_choice.is_empty()

func cancel_grow_choice() -> void:
	if _grow_choice.is_empty():
		return
	_grow_choice = {}
	_update_visible()
	RouteLine.clear(_path_preview)
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
	if hover != NO_CELL:
		RouteLine.draw_route(_path_preview, map_generator.get_path_if_blocked_cells(Tower.footprint_cells(hover, 2)),
			PREVIEW_COLOR, 6.0, map_generator.get_path_from(map_generator.startPath))
	else:
		RouteLine.clear(_path_preview)
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
			draw_texture_rect_region(into.texture, Rect2(centre - frame.size / 2.0 + into.get_sprite_offset(), frame.size), frame,
				Color(1, 1, 1, 0.6))  # A texture modulate (fade), not a colour
	var tower: Tower = _grow_choice.tower
	if is_instance_valid(tower):
		WorldLabel.draw_tag(self, tower.global_position.x, tower.global_position.y - MAP_GRID.cell_size.y,
			"Grow into %s: pick a square (Esc to cancel)" % into.display_name, WorldLabel.cost_color(true))

# --- Seedbearer's Sprout (branch expansion Phase 2): the player picks a cell beside it, at a rest ---

signal seed_choice_changed(active: bool)
var _seed_choice := {}  # {tower, cells, hover} while the player picks the cell
var _sprout_data: TowerData = preload("res://resource/tower/sprout.tres")

# Starts picking where a Seedbearer's ready Sprout grows: the open cells beside it (the path rule holds) show;
# clicking one plants a free Sprout, Esc / right-click cancels. Only at a rest, with a seed ready.
func begin_seed_choice(seedbearer: Tower) -> bool:
	if not Tower.resting or BranchKit.seeds_ready(seedbearer) <= 0:
		return false
	var cells := seed_cells_open(seedbearer)
	if cells.is_empty():
		return false
	cancel_grow_choice()
	set_build_mode(false)
	_seed_choice = {"tower": seedbearer, "cells": cells, "hover": NO_CELL}
	_update_visible()
	seed_choice_changed.emit(true)
	queue_redraw()
	return true

func is_choosing_seed() -> bool:
	return not _seed_choice.is_empty()

func cancel_seed_choice() -> void:
	if _seed_choice.is_empty():
		return
	_seed_choice = {}
	_update_visible()
	RouteLine.clear(_path_preview)
	seed_choice_changed.emit(false)
	queue_redraw()

# The cells beside `seedbearer` a Sprout can take now: free, buildable, not settling or Omen-locked, no nightmare
# on it, and the path rule holds.
func seed_cells_open(seedbearer: Tower) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if frozen_ground():
		return out
	var enemy_cells := PackedVector2Array()
	for enemy_cell in _walker_cells():
		enemy_cells.append(enemy_cell)
	for cell in BranchKit.seed_cells(seedbearer):
		var cells: Array[Vector2] = [cell]
		if not MAP_GRID.is_within_bounds(cell) or _cells_occupied(cells) or settling_left(cells) > 0.0 or omen_locked(cells):
			continue
		if map_generator.can_block_cells(cells, enemy_cells):
			out.append(cell)
	return out

# Plants `seedbearer`'s Sprout on `cell` (free; never raises the Sprout price). Returns the Sprout, or null.
func plant_seed(seedbearer: Tower, cell: Vector2) -> Tower:
	if BranchKit.seeds_ready(seedbearer) <= 0 or not seed_cells_open(seedbearer).has(cell):
		build_rejected.emit(cell)
		return null
	var tower: Tower = tower_scene.instantiate()
	tower.tower_data = _sprout_data
	tower.cell = cell
	tower.invested_dew = 0
	tower.set_meta(&"gift_sprout", true)
	tower.position = Tower.footprint_centre(cell, 1)
	tower_container.add_child(tower)
	map_generator.block_cells([cell])
	BranchKit.seed_planted(seedbearer, tower)
	tower_built.emit(tower)
	return tower

func _update_seed_choice() -> void:
	var cell := MAP_GRID.calculate_grid_coordinates(get_global_mouse_position())
	var hover: Vector2 = cell if _seed_choice.cells.has(cell) else NO_CELL
	if hover == _seed_choice.hover:
		return
	_seed_choice.hover = hover
	if hover != NO_CELL:
		RouteLine.draw_route(_path_preview, map_generator.get_path_if_blocked_cells([hover]),
			PREVIEW_COLOR, 6.0, map_generator.get_path_from(map_generator.startPath))
	else:
		RouteLine.clear(_path_preview)
	queue_redraw()

func _draw_seed_choice() -> void:
	draw_set_transform(Vector2.ZERO)
	for cell in _seed_choice.cells:
		var rect := Rect2(MAP_GRID.calculate_map_position(cell) - MAP_GRID.cell_size / 2.0, MAP_GRID.cell_size)
		var hovered: bool = cell == _seed_choice.hover
		draw_rect(rect.grow(-3), Color(VALID_TINT, 0.18 if hovered else 0.08))
		draw_rect(rect.grow(-3), Color(VALID_TINT, 0.9 if hovered else 0.5), false, 2.0)
	var tower: Tower = _seed_choice.tower
	if is_instance_valid(tower):
		WorldLabel.draw_tag(self, tower.global_position.x, tower.global_position.y - MAP_GRID.cell_size.y,
			"Plant a Sprout: pick a cell beside it (Esc to cancel)", WorldLabel.cost_color(true))

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
	if focus != Tower.Focus.NONE and not tower.choice_available(focus):
		return false  # A choice this Warden can't take (support Wardens: Wide / Strong / Kindred); none = its default
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
const STROKE_SKIP_TINT := Color(Palette.EMBER, 0.45)
var stroking := false
var confirm_on_release := true
var _stroke: Array[Vector2] = []  # Cells in drag order
var _stroke_plan := {}  # cell -> "" (plant) or why it's skipped
var _stroke_axis := -1  # -1 not locked yet, 0 = a row (y fixed), 1 = a column (x fixed)
var _stroke_cost := 0
var _stroke_growth := 0

# Starts a stroke on whole cell `cell` (clicks, touch, tests). With half cells, the hovered cell starts at the
# ghost's half offset; any other whole cell at its own corner's half origin (cell × 2).
func begin_stroke(cell: Vector2) -> void:
	if cell == NO_CELL or not MAP_GRID.is_within_bounds(cell):
		return
	if half_placement():
		begin_stroke_half(_hover_half if cell == _hover_cell and _hover_half != NO_CELL else cell * 2.0)
		return
	_start_stroke(cell)

# Starts a stroke at half origin `origin` (half cells: the stroke holds half origins).
func begin_stroke_half(origin: Vector2) -> void:
	if origin == NO_CELL:
		return
	_start_stroke(origin)

func _start_stroke(cell: Vector2) -> void:
	_plan_cache = {}  # A new stroke plans from its first cell
	stroking = true
	_stroke.assign([cell])
	_stroke_axis = -1
	_plan_stroke()
	stroke_changed.emit(true)

# Adds the cells from the stroke's end to `cell`, one step at a time (a diagonal step goes via the corner
# cell). Once the stroke has 2 cells it locks to their row or column unless `free` (Alt).
func extend_stroke(cell: Vector2, free := false) -> void:
	if not stroking or _stroke.is_empty() or not (half_placement() or MAP_GRID.is_within_bounds(cell)):
		return
	var unit := 1.0
	if half_placement():
		unit = 1.0 if twig_mode() else 2.0  # A Warden's width in halves (a twig wall: one): snap the target to the stroke's own offset
		cell = _stroke[0] + ((cell - _stroke[0]) / unit).round() * unit
	var target := _locked(cell, free)
	var last: Vector2 = _stroke.back()
	while last != target:
		var step := Vector2(signf(target.x - last.x), signf(target.y - last.y)) * unit
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
	_hover_half = NO_CELL  # (Half cells: also with a still mouse, as in set_build_mode, Main 7ec7adcf)
	queue_redraw()

# Plants every green cell in drag order (each re-checked by _try_build). Returns how many.
func plant_stroke() -> int:
	var cells := _stroke.filter(func(c: Vector2) -> bool: return _stroke_plan.get(c, "x") == "")
	stroking = false  # So the builds below refresh the preview normally
	var planted := 0
	# One route update for the whole stroke (Environment, maze perf budget): each wall is still checked on the live
	# grid; the route is redrawn and walkers re-routed once, at release.
	var hold := map_generator.has_method("hold_route")
	if hold:
		map_generator.hold_route()
	for c in cells:
		if (_try_build_half(c) if half_placement() else _try_build(c)):
			planted += 1
	if hold:
		map_generator.release_route()
	if planted == 0 and not _stroke.is_empty():
		build_rejected.emit(_stroke[0])  # A click on a cell that can't take it (the sound)
	_stroke.clear()
	_stroke_plan.clear()
	stroke_changed.emit(false)
	_hover_cell = NO_CELL
	_hover_half = NO_CELL  # The ghost refreshes over what was just planted, mouse still or not
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

# Build flow (user 2026-10-05, maze_feel.md: "Shift to keep going", Tropical Tower Wars): a player's placement (a click,
# a dragged line, a big Warden) disarms build mode afterwards; the Warden stays selected in the bar, so its hotkey or a
# click re-arms it. Holding Shift keeps it armed, and letting go of Shift after a placement disarms. Touch has no
# Shift: the HUD's "keep building" pin sets keep_building (platforms.md: nothing keyboard-only).
signal keep_building_changed(on: bool)
var keep_building := false
var _shift_chain := false  # Armed by Shift after a placement: letting go of Shift disarms

func set_keep_building(on: bool) -> void:
	if keep_building != on:
		keep_building = on
		keep_building_changed.emit(on)

# Called after a player's placement (input paths and the touch Plant button; tests calling _try_build / plant_stroke
# directly stay armed).
func after_player_placement(placed: bool) -> void:
	if not placed or not build_mode:
		return
	if Input.is_key_pressed(KEY_SHIFT):
		_shift_chain = true
		return
	if keep_building:
		return
	set_build_mode(false)

func _stroke_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel_build"):
		cancel_stroke()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and get_viewport().gui_get_hovered_control() == null:
		# (Over a HUD button, e.g. touch's Plant: an emulated nudge mustn't extend the stroke.)
		extend_stroke(origin_at(get_global_mouse_position()) if half_placement() else MAP_GRID.calculate_grid_coordinates(get_global_mouse_position()), event.alt_pressed)
	elif event.is_action_released("place_tower") and confirm_on_release:
		after_player_placement(plant_stroke() > 0)  # A click or a dragged line is one placement
		get_viewport().set_input_as_handled()

# Half-cell strokes: the stroke holds half origins, a Warden's width (2 halves) apart.
# Dragging (Environment's maze perf profile: ~5.5 ms a cell, the whole stroke re-planned each step): the plan resumes
# after the cells already planned while the board, the Dew and the Warden are the same; any board change (a placement,
# a sale, path_changed) plans it all again. plant_stroke re-checks every wall on the live grid anyway.
var _plan_cache := {}

func _plan_stroke_half() -> void:
	var blocked: Array[Vector2] = []  # Halves
	var dew := run_state.dew
	var points := _walker_points()
	var planned_sprouts := 0
	var unique_used := is_unique_placed(tower_data)
	var start := 0
	var cache := _plan_cache
	if not cache.is_empty() and cache.board == dream_state.board_version and cache.dew0 == run_state.dew \
			and cache.data == tower_data and cache.stroke.size() <= _stroke.size() \
			and _stroke.slice(0, cache.stroke.size()) == cache.stroke:
		start = cache.stroke.size()
		blocked = cache.blocked.duplicate()
		dew = cache.dew
		planned_sprouts = cache.sprouts
		unique_used = cache.unique
	else:
		_stroke_plan.clear()
	for i in range(start, _stroke.size()):
		var o: Vector2 = _stroke[i]
		var halves: Array[Vector2] = origin_halves(o)
		var home := origin_home(o)
		var why := ""
		if frozen_ground():
			why = "Frozen Ground: plant at the rest"
		elif halves.any(func(h: Vector2) -> bool: return blocked.has(h) or not map_generator.is_buildable_half(h)):
			why = "can't plant here"
		elif _halves_occupied(halves):
			why = "nightmare here"
		elif settling_left_halves(halves) > 0.0:
			why = "the ground is settling"
		elif unique_used:
			why = "one per run"
		elif not map_generator.can_block_halves(blocked + halves, points):
			why = "would close the dream"
		else:
			var cost := get_cost(null, home, planned_sprouts)
			if cost > dew:
				why = "out of Dew"
			else:
				dew -= cost
				blocked.append_array(halves)
				if cost > 0:  # Priced after the earlier ones: the Sprout step and copies
					planned_sprouts += 1
				unique_used = tower_data.is_unique
		_stroke_plan[o] = why
	_plan_cache = {"board": dream_state.board_version, "dew0": run_state.dew, "data": tower_data, "stroke": _stroke.duplicate(),
		"blocked": blocked.duplicate(), "dew": dew, "sprouts": planned_sprouts, "unique": unique_used}
	_stroke_cost = run_state.dew - dew
	var route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var new_route: PackedVector2Array = map_generator.get_path_if_blocked_halves(blocked, true) if not blocked.is_empty() else route
	_stroke_growth = map_generator.route_length(new_route) - map_generator.route_length(route)
	RouteLine.draw_route(_path_preview, new_route, PREVIEW_COLOR, 6.0, route)
	queue_redraw()

func _plan_stroke() -> void:
	if half_placement():
		_plan_stroke_half()
		return
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
				if cost > 0:  # Priced after the earlier ones: the Sprout step and copies
					planned_sprouts += 1  # Each Sprout in the stroke is priced after the ones before it
				unique_used = tower_data.is_unique
		_stroke_plan[c] = why
	_stroke_cost = run_state.dew - dew
	var route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var new_route: PackedVector2Array = map_generator.get_path_if_blocked_cells(blocked) if not blocked.is_empty() else route
	_stroke_growth = new_route.size() - route.size()
	RouteLine.draw_route(_path_preview, new_route, PREVIEW_COLOR, 6.0, route)
	queue_redraw()

func _draw_stroke() -> void:
	for c in _stroke:
		draw_set_transform(origin_centre(c) if half_placement() else MAP_GRID.calculate_map_position(c))
		var ok: bool = _stroke_plan.get(c, "x") == ""
		var tint := VALID_TINT if ok else STROKE_SKIP_TINT
		if tower_data.texture == null:
			Tower.draw_placeholder(self, tint)
		else:
			var frame := tower_data.get_frame_rect(0)
			draw_texture_rect_region(tower_data.texture, Rect2(-frame.size / 2.0 + tower_data.get_sprite_offset(), frame.size), frame, tint)
	if _stroke.is_empty():
		return
	draw_set_transform(Vector2.ZERO)
	var last := to_local(origin_centre(_stroke.back()) if half_placement() else MAP_GRID.calculate_map_position(_stroke.back()))  # draw_tag sets its own transform
	var last_why: String = _stroke_plan.get(_stroke.back(), "")
	var tag := get_stroke_tag() + (" · %s" % last_why if last_why != "" else "")
	WorldLabel.draw_tag(self, last.x, last.y + MAP_GRID.cell_size.y / 2.0 + 18.0, tag, WorldLabel.cost_color(true))

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
# Second Path (an Omen): cells it opened can't be planted on until the next rest (OmenDirector.locked_cells).
func omen_locked(cells: Array) -> bool:
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	if omens == null or not omens.has_method("is_cell_locked"):
		return false
	for c in cells:
		if omens.is_cell_locked(c):
			return true
	return false

func frozen_ground() -> bool:
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	return omens != null and omens.has_method("blocks_building") and omens.blocks_building()

var _frozen_toast_at := -100000
var _finals_grown := {}  # final form id -> true once one grew this run (Fx.final_bloom)

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
		# One flood fill per grid change (Environment, maze perf budget); the old A* until their MapGenerator lands
		if (map_generator.has_route_from(target) if map_generator.has_method("has_route_from") else not map_generator.get_path_from(target).is_empty()):
			cells.append(target)
	return cells

# The island's rim: the map's outer ring of cells, never buildable (the start and end are on it).
static func is_edge_cell(cell: Vector2) -> bool:
	var last := MAP_GRID.size - Vector2.ONE
	return MAP_GRID.is_within_bounds(cell) and (cell.x <= 0 or cell.y <= 0 or cell.x >= last.x or cell.y >= last.y)
