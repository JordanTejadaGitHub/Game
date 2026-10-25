extends Node2D
# Forest Floor (Dream card; owner 2026-10-25, dream_council_review.md 36): "Now: place 2 Mossy Boulders on open ground."
# MapGenerator makes one of these (no class_name: MapGenerator.boulder_placement) and owns the boulders' state
# (placed_obstacles, boulders_placed, can_place_boulder, place_boulder); this node runs their placement, as WaymarkStone
# runs the stone's:
# - Once the Dream (and any other choice) closes at the rest, a placement ghost with the route preview opens; the next
#   drift's Start waits for both boulders (DriftDirector.pending_choice &"boulders"). Esc lets the player look round
#   first; Start reopens it.
# - Each click places one boulder (can_block first, with the walkers' cells); the placement stays open for the second.
# The boulders themselves are ordinary Mossy Boulder tiles (place_obstacle).

var map: Node2D  # MapGenerator (set before add_child)

const POLL_SECONDS := 0.25  # How often it looks whether the placement should open
const PREVIEW_WIDTH := 6.0
const OK := Palette.GLOW
const REFUSED := Palette.EMBER  # The palette has no red: Ember is "no"
const PREVIEW := Color(Palette.HEARTLIGHT, 0.55)

var placing := false
var _declined := false  # The player put the placement off (Esc): Start reopens it
var _hover := Vector2(-1, -1)
var _hover_ok := false
var _poll := 0.0
var _overlay: Node2D
var _preview: Line2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Choice screens pause the tree; placing works while paused
	_overlay = Node2D.new()
	_overlay.name = "BoulderGhost"
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

func _needed() -> int:
	var dreams = _dreams()
	return dreams.boulders_needed() if dreams != null and dreams.has_method("boulders_needed") else 0

func _process(delta: float) -> void:
	if placing:
		if _needed() <= 0:
			_close()
		else:
			_update_hover()
		return
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = POLL_SECONDS
	var director = _director()
	if director == null or _declined or _needed() <= 0:
		return
	if director.pending_choice() == &"boulders" and not RestScreens.any_open(self, director):
		begin_placing()

# Opens the placement. Building and the clear tool step aside.
func begin_placing() -> void:
	if placing:
		return
	placing = true
	_declined = false
	_hover = Vector2(-1, -1)
	var placer = map.get_node_or_null("%TowerPlacer")
	if placer != null and placer.get("build_mode"):
		placer.set_build_mode(false)
	var clearer = map.get_node_or_null("%ObstacleClearer")
	if clearer != null and clearer.has_method("set_tool_active") and clearer.has_method("is_tool_active") and clearer.is_tool_active():
		clearer.set_tool_active(false)
	_toast(_prompt())
	_update_hover()

func _prompt() -> String:
	var left := _needed()
	return "Forest Floor: click open ground to place %s (Esc to look round first)." % (
		"a Mossy Boulder" if left == 1 else "%d Mossy Boulders" % left)

func cancel_placing() -> void:
	if not placing:
		return
	_declined = true  # The player looks round first; Start (DriftPanel.reopen_choice) opens it again
	_close()

func _close() -> void:
	placing = false
	_preview.visible = false
	RouteLine.clear(_preview)
	_overlay.queue_redraw()

# Reopens a put-off placement (the Start button while it waits).
func reopen() -> void:
	_declined = false
	begin_placing()

func is_placing() -> bool:
	return placing

# The route points every walking nightmare stands on or steps to (a rest has none; tests may put some on the field).
func _walker_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	var spawner = map.get_node_or_null("%EnemyContainer")
	if spawner == null or not spawner.has_method("get_maze_walkers"):
		return points
	for enemy in spawner.get_maze_walkers():
		points.append(enemy.get_target_cell())
	return points

func _update_hover() -> void:
	var cell: Vector2 = map.MAP_GRID.calculate_grid_coordinates(map.get_global_mouse_position())
	if cell == _hover:
		return
	_hover = cell
	_hover_ok = map.can_place_boulder(cell, _walker_points())
	var route: PackedVector2Array = map.get_path_if_boulder_at(cell, true) if _hover_ok else PackedVector2Array()
	_preview.visible = not route.is_empty()
	if route.is_empty():
		RouteLine.clear(_preview)
	else:
		RouteLine.draw_route(_preview, route, PREVIEW, PREVIEW_WIDTH, map.get_path_from(map.startPath))
	_overlay.queue_redraw()

# Places one boulder on `cell` (the placement's click; tests call it). False if it can't go there.
func place_at(cell: Vector2) -> bool:
	if _needed() <= 0:
		return false
	if not map.can_place_boulder(cell, _walker_points()):
		_toast(_refusal_text(cell))
		return false
	map.place_boulder(cell)
	var director = _director()
	if director != null and director.get("maze_economy") != null:
		director.maze_economy.observe(map)  # As the Waymark: a longer maze is sampled, never paid twice
	_hover = Vector2(-1, -1)  # The next hover check sees the new board
	if _needed() <= 0:
		_close()
	elif placing:
		_toast(_prompt())
		_update_hover()
	return true

func _refusal_text(cell: Vector2) -> String:
	if map.is_waymark_ground(cell) and map.is_buildable(cell):
		return "A boulder there would close the way to the Heartwood."
	return "A boulder needs open ground: not on a Warden, an obstacle, the start or the Heartwood's glade."

func _input(event: InputEvent) -> void:
	if map == null or not placing:
		return
	if event.is_action_pressed("cancel_build"):
		cancel_placing()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("place_tower"):
		_update_hover()
		place_at(_hover)
		get_viewport().set_input_as_handled()

func _toast(text: String) -> void:
	var hud = map.owner.get_node_or_null("HUD") if map != null and map.owner != null else null
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast(text)

# The placement ghost (on the overlay, map coordinates): the hovered cell, Glow when a boulder can go there, Ember if not,
# with the Mossy Boulder's own tile faintly in it.
func _draw_ghost() -> void:
	if not placing or not map.MAP_GRID.is_within_bounds(_hover):
		return
	var at: Vector2 = map.MAP_GRID.calculate_map_position(_hover)
	var size: Vector2 = map.MAP_GRID.cell_size
	var colour := OK if _hover_ok else REFUSED
	if _hover_ok:
		var tex := _boulder_texture()
		if tex != null:
			_overlay.draw_texture_rect_region(tex.atlas, Rect2(at - size / 2.0, size), tex.region, Color(1, 1, 1, 0.6))  # multiplier
	_overlay.draw_rect(Rect2(at - size / 2.0, size), Color(colour, 0.25), true)
	_overlay.draw_rect(Rect2(at - size / 2.0, size), Color(colour, 0.8), false, 2.0)

var _tex: AtlasTexture = null

# The Mossy Boulder's first tile from the environment TileSet (null when it can't be found: the ghost is the cell only).
func _boulder_texture() -> AtlasTexture:
	if _tex != null:
		return _tex
	var data: ObstacleData = map.BOULDER
	var layer = map.get("environment_object_layer")
	if layer == null or layer.tile_set == null or data.tiles.is_empty() or not layer.tile_set.has_source(data.source_id):
		return null
	var source := layer.tile_set.get_source(data.source_id) as TileSetAtlasSource
	if source == null or source.texture == null:
		return null
	var coords: Vector2i = data.tiles[0]
	if not source.has_tile(coords):
		return null
	_tex = AtlasTexture.new()
	_tex.atlas = source.texture
	_tex.region = source.get_tile_texture_region(coords)
	return _tex
