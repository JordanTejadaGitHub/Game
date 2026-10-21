extends Node2D
# Waymark (Legendary Dream; owner 2026-10-21, legendaries_final.md 1.1): the standing stone every walker must reach before
# the Heartwood. MapGenerator makes one of these (no class_name: MapGenerator.waymark_stone) and owns the rule's state
# (waymark_cell, set_waymark, can_place_waymark); this node draws the stone and runs its placement:
# - Taken: once the Dream (and any other choice) closes, a placement ghost with the two-leg route preview opens; the next
#   drift's Start waits for it (DriftDirector.pending_choice &"waymark"). Esc lets the player look round first; Start
#   reopens it.
# - Moved: click the stone at a rest (outside build mode), then click its new cell. Free; never during a drift.
# A code-drawn placeholder (palette colours only): a tall grey standing stone with a glowing rune and a soft light.

var map: Node2D  # MapGenerator (set before add_child)

const POLL_SECONDS := 0.25  # How often it looks whether the placement should open
const STONE_WIDTH := 22.0  # px at the base
const STONE_HEIGHT := 64.0  # px from its foot (on the cell) up
const STONE_FOOT := 22.0  # px below the cell centre where it stands
const GLOW_RADIUS := 30.0
const GLOW_PULSE_SECONDS := 2.4
const RUNE_SIZE := 7.0
const GHOST_ALPHA := 0.6
const PREVIEW_WIDTH := 6.0
const BODY := Palette.STONE
const SHADE := Palette.SLATE
const EDGE := Palette.NIGHT
const RUNE := Palette.HEARTLIGHT
const GLOW := Palette.GLOW
const REFUSED := Palette.EMBER  # The palette has no red: Ember is "no"
const PREVIEW := Color(Palette.HEARTLIGHT, 0.55)

var placing := false
var moving := false  # Placing again an existing stone
var _declined := false  # The player put the first placement off (Esc): Start reopens it
var _hover := Vector2(-1, -1)
var _hover_ok := false
var _poll := 0.0
var _clock := 0.0
var _overlay: Node2D
var _preview: Line2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Choice screens pause the tree; placing works while paused
	visible = false
	_overlay = Node2D.new()
	_overlay.name = "WaymarkPlacement"
	_overlay.top_level = true  # In map coordinates (the map is at the origin), over everything on the ground
	_overlay.z_index = 20
	_overlay.draw.connect(_draw_ghost)
	add_child(_overlay)
	_preview = Line2D.new()
	_preview.width = PREVIEW_WIDTH
	_preview.default_color = PREVIEW
	_overlay.add_child(_preview)
	_preview.visible = false

func _dreams():
	return map.get_node_or_null("%DreamState") if map != null else null

func _director():
	return map.get_node_or_null("%DriftDirector") if map != null else null

# MapGenerator.set_waymark: show the stone on its new cell.
func stone_moved() -> void:
	visible = map.has_waymark()
	if visible:
		position = map.MAP_GRID.calculate_map_position(map.waymark_cell)
	queue_redraw()

func _process(delta: float) -> void:
	_clock += delta
	if visible:
		queue_redraw()  # The glow breathes
	if placing:
		_update_hover()
		return
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = POLL_SECONDS
	var dreams = _dreams()
	var director = _director()
	if dreams == null or director == null or _declined or not dreams.has_method("waymark_needed") or not dreams.waymark_needed():
		return
	if director.pending_choice() == &"waymark" and not RestScreens.any_open(self, director):
		begin_placing()

# Opens the placement (the first one, or a move at a rest). Building and the clear tool step aside.
func begin_placing(move := false) -> void:
	if placing:
		return
	placing = true
	moving = move
	_declined = false
	_hover = Vector2(-1, -1)
	var placer = map.get_node_or_null("%TowerPlacer")
	if placer != null and placer.get("build_mode"):
		placer.set_build_mode(false)
	_toast("Moving the Waymark: click open ground (Esc keeps it here)." if move
		else "Place the Waymark: click open ground. Every nightmare walks to it before the Heartwood.")
	_update_hover()

func cancel_placing() -> void:
	if not placing:
		return
	placing = false
	if not moving:
		_declined = true  # The player looks round first; Start (DriftPanel.reopen_choice) opens it again
	moving = false
	_preview.visible = false
	RouteLine.clear(_preview)
	_overlay.queue_redraw()

# Reopens a put-off placement (the Start button while it waits).
func reopen() -> void:
	_declined = false
	begin_placing()

func is_placing() -> bool:
	return placing

func _update_hover() -> void:
	var cell: Vector2 = map.MAP_GRID.calculate_grid_coordinates(map.get_global_mouse_position())
	if cell == _hover:
		return
	_hover = cell
	_hover_ok = cell == map.waymark_cell or map.can_place_waymark(cell)
	var route: PackedVector2Array = map.get_path_if_waymark_at(cell, true) if _hover_ok else PackedVector2Array()
	_preview.visible = not route.is_empty()
	if route.is_empty():
		RouteLine.clear(_preview)
	else:
		RouteLine.draw_route(_preview, route, PREVIEW, PREVIEW_WIDTH, map.get_path_from(map.startPath))
	_overlay.queue_redraw()

# Places the stone on `cell` (the placement's click; tests call it). False if it can't stand there.
func place_at(cell: Vector2) -> bool:
	if cell != map.waymark_cell and not map.can_place_waymark(cell):
		_toast(_refusal_text(map.waymark_refusal()))
		return false
	var was_placing := placing
	placing = false
	moving = false
	_preview.visible = false
	RouteLine.clear(_preview)
	map.set_waymark(cell)
	var director = _director()
	if director != null and director.has_method("_maze_changed"):
		director.maze_economy.observe(map)  # Moving it only ever lowers unpaid maze samples
	if was_placing:
		_overlay.queue_redraw()
	return true

static func _refusal_text(why: StringName) -> String:
	if why == &"closes":
		return "The Waymark needs a way in from the start and a way on to the Heartwood."
	return "The Waymark needs open ground: not on a Warden, an obstacle, the start or the Heartwood's glade."

func _input(event: InputEvent) -> void:
	if map == null:
		return
	if placing:
		if event.is_action_pressed("cancel_build"):
			cancel_placing()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("place_tower"):
			_update_hover()
			place_at(_hover)
			get_viewport().set_input_as_handled()
		return
	# Moving: a click on the stone at a rest, outside build mode.
	if not visible or not event.is_action_pressed("place_tower"):
		return
	var director = _director()
	var placer = map.get_node_or_null("%TowerPlacer")
	if director == null or not director.is_build_phase() or (placer != null and placer.get("build_mode")):
		return
	var cell: Vector2 = map.MAP_GRID.calculate_grid_coordinates(map.get_global_mouse_position())
	if cell == map.waymark_cell:
		begin_placing(true)
		get_viewport().set_input_as_handled()

func _toast(text: String) -> void:
	var hud = map.owner.get_node_or_null("HUD") if map != null and map.owner != null else null
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast(text)

# --- Look ----------------------------------------------------------------------------------------------------------

func _draw() -> void:
	if not map.has_waymark():
		return
	_draw_stone(self, Vector2.ZERO, 1.0, _breath())

func _breath() -> float:
	if bool(Fx.setting("reduced_motion", false)):
		return 0.5
	return 0.5 + 0.5 * sin(_clock * TAU / GLOW_PULSE_SECONDS)

# A tall standing stone at `at` (the cell centre): a soft light round it, the body with a shaded side, a glowing rune.
static func _draw_stone(canvas: CanvasItem, at: Vector2, alpha: float, breath: float) -> void:
	var foot := at + Vector2(0, STONE_FOOT)
	for i in 3:  # The light: three soft discs (no gradient texture needed)
		var r := GLOW_RADIUS * (1.0 - i * 0.25)
		canvas.draw_circle(foot + Vector2(0, -STONE_HEIGHT * 0.45), r, Color(GLOW, (0.06 + 0.05 * breath) * alpha))
	canvas.draw_circle(foot, STONE_WIDTH * 0.7, Color(EDGE, 0.35 * alpha))  # Its shadow on the ground
	var half := STONE_WIDTH / 2.0
	var body := PackedVector2Array([foot + Vector2(-half, 0), foot + Vector2(-half * 0.8, -STONE_HEIGHT * 0.75),
		foot + Vector2(-half * 0.3, -STONE_HEIGHT), foot + Vector2(half * 0.4, -STONE_HEIGHT * 0.95),
		foot + Vector2(half * 0.85, -STONE_HEIGHT * 0.7), foot + Vector2(half, 0)])
	canvas.draw_colored_polygon(body, Color(BODY, alpha))
	var side := PackedVector2Array([foot + Vector2(half * 0.2, 0), foot + Vector2(half * 0.3, -STONE_HEIGHT * 0.9),
		foot + Vector2(half * 0.4, -STONE_HEIGHT * 0.95), foot + Vector2(half * 0.85, -STONE_HEIGHT * 0.7), foot + Vector2(half, 0)])
	canvas.draw_colored_polygon(side, Color(SHADE, alpha))
	var outline := body.duplicate()
	outline.append(body[0])
	canvas.draw_polyline(outline, Color(EDGE, alpha), 2.0)
	var rune := foot + Vector2(-half * 0.2, -STONE_HEIGHT * 0.55)  # A diamond rune with a line through it
	var diamond := PackedVector2Array([rune + Vector2(0, -RUNE_SIZE), rune + Vector2(RUNE_SIZE * 0.6, 0),
		rune + Vector2(0, RUNE_SIZE), rune + Vector2(-RUNE_SIZE * 0.6, 0), rune + Vector2(0, -RUNE_SIZE)])
	canvas.draw_circle(rune, RUNE_SIZE * 1.6, Color(GLOW, (0.15 + 0.2 * breath) * alpha))
	canvas.draw_polyline(diamond, Color(RUNE, (0.7 + 0.3 * breath) * alpha), 2.0)
	canvas.draw_line(rune + Vector2(0, -RUNE_SIZE * 1.6), rune + Vector2(0, RUNE_SIZE * 1.6), Color(RUNE, 0.6 * alpha), 1.0)

# The placement ghost (on the overlay, map coordinates): the stone at the hovered cell, Ember when it can't stand there.
func _draw_ghost() -> void:
	if not placing or not map.MAP_GRID.is_within_bounds(_hover):
		return
	var at: Vector2 = map.MAP_GRID.calculate_map_position(_hover)
	var size: Vector2 = map.MAP_GRID.cell_size
	_overlay.draw_rect(Rect2(at - size / 2.0, size), Color(GLOW if _hover_ok else REFUSED, 0.25), true)
	_overlay.draw_rect(Rect2(at - size / 2.0, size), Color(GLOW if _hover_ok else REFUSED, 0.8), false, 2.0)
	if _hover_ok:
		_draw_stone(_overlay, at, GHOST_ALPHA, 0.5)
