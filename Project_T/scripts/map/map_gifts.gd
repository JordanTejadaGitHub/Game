class_name MapGifts
extends Node2D

# Heartwood's Gifts, the terrain (heartwood_gifts.md; numbers spire_difficulty.md Phase 3). Made by MapGenerator
# (`map_generator.gifts`). Main's HeartwoodGifts runs the offer, the placement (GiftPlacer checks the cells and
# the route) and the save; the effects registered here (register_effects, from _ready) change the map. On a resumed run the
# map is regenerated from its seed and HeartwoodGifts calls each effect again in order (placement["restoring"]):
# the tended cells are restored before that call, the Wardens after it. Tower Code's GiftGround keeps the
# Warden-side marks and bonuses for the living-ground gifts; this draws their terrain and blocks their cells.
#
# Drawn here (ground overlays: bog, roots, the mushroom ring, stumps; z -1 over the path) and by `GiftProp`
# children of MapGenerator (logs, the Moonwell, the Bell Stone, the Lightning Tree: y-sorted with the trees).
# Art from assets/environment/<act>/ (Environment Assets); a placeholder in palette colours while a sheet is missing.

signal gifts_changed  # Terrain or ground changed

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const TREE_DATA := preload("res://resource/obstacle/tree.tres")
const ROCK_DATA := preload("res://resource/obstacle/rock.tres")

const SOW_RIDGE := &"sow_ridge"
const FALLEN_GIANT := &"fallen_giant"
const GLADE := &"glade"
const SHIFT_STONES := &"shift_stones"
const MIRE := &"mire"
const SPRING := &"spring"
const MUSHROOM_RING := &"mushroom_ring"
const LIGHTNING_TREE := &"lightning_tree"
const MOONWELL := &"moonwell"
const BELL_STONE := &"bell_stone"
const ANCIENT_STUMP := &"ancient_stump"
const HEARTWOOD_ROOTS := &"heartwood_roots"
const SHIFTING_MIST := &"shifting_mist"  # Replaced Deeper Glade (heartwood_gifts.md 0c552b28)
const TERRAIN_GIFTS: Array[StringName] = [SOW_RIDGE, FALLEN_GIANT, GLADE, SHIFT_STONES, MIRE, SPRING, MUSHROOM_RING,
	LIGHTNING_TREE, MOONWELL, BELL_STONE, ANCIENT_STUMP, HEARTWOOD_ROOTS, SHIFTING_MIST]

# Numbers (spire_difficulty.md Phase 3 starting points; Balancing tunes).
const MIRE_SLOW := 0.2  # Through EnemyStatuses' extra slow: the slow floors still hold
const ROOTS_CELLS := 4
const ROOTS_TAKEN := 0.15
const TICK := 0.2  # s between ground checks on the nightmares

# Art (Environment Assets 46525c97): sheet name → [frame size, frames].
const ART := {
	"lightning_tree": [Vector2i(96, 128), 4], "moonwell": [Vector2i(64, 64), 4], "bell_stone": [Vector2i(64, 64), 4],
	"mushroom_ring": [Vector2i(192, 192), 4], "heartwood_roots": [Vector2i(64, 64), 16],
	"bog_path": [Vector2i(64, 64), 16], "ancient_stump": [Vector2i(64, 64), 3],
	"fallen_log": [Vector2i(64, 64), 6],  # Static pieces: 0 W end, 1 E-W middle, 2 E end, 3 N end, 4 N-S middle, 5 S end
}
const ANIMATED: Array[String] = ["lightning_tree", "moonwell", "bell_stone", "mushroom_ring"]

var map: Node  # MapGenerator
var act := 1
var gift_obstacles := {}  # {cell: [kind ("tree" / "rock" / "lightning"), tile (Vector2i)]}: obstacles a gift put down
var logs: Array = []  # [[cells…], …]: Fallen Giants (blocked, never clearable)
var spring_cells: Array[Vector2] = []
var moonwells: Array[Vector2] = []
var bell_stones: Array[Vector2] = []
var bog_cells: Array[Vector2] = []
var root_cells: Array[Vector2] = []
var rings: Array[Vector2] = []  # Top-left cells of 3×3 Mushroom Rings
var stumps: Array[Vector2] = []
var _props: Array[Node2D] = []
var _sheets := {}
var _tick := 0.0
var _frame_time := 0.0

# Registered at run time (from _ready, not _static_init: a Callable stored from a static init can crash the
# engine at exit, Tower Code 3af4bb5b). A test's stand-in may already hold the id.
static func register_effects() -> void:
	for id in TERRAIN_GIFTS:
		if not HeartwoodGifts.has_effect(id):
			HeartwoodGifts.register(id, _effect.bind(id))

# HeartwoodGifts' call: placement.cells (Shift the Stones: placement.from, pairwise), placement.restoring.
static func _effect(main: Node, placement: Dictionary, id: StringName) -> void:
	var map_generator := main.get_node_or_null("%MapGenerator")
	if map_generator == null or map_generator.gifts == null:
		return
	var run_state := main.get_node_or_null("%RunState")
	var tended: Array = run_state.tended_cells if run_state != null else []
	map_generator.gifts.apply(id, HeartwoodGifts.cells_of(placement), HeartwoodGifts.cells_of(placement, "from"),
		bool(placement.get("restoring", false)), int(placement.get("tended_before", -1)), tended)

func _ready() -> void:
	z_index = -1  # Ground overlays: over the path (added after it), under everything standing
	register_effects()
	map.obstacle_cleared.connect(_on_obstacle_cleared)
	map.path_changed.connect(queue_redraw)
	map.path_changed.connect(_draw_duals)
	_load_sheets()

# The cells Heartwood Roots grows over now: the last ROOTS_CELLS of the route before the Heartwood (for the
# gift screen's preview; HeartwoodGifts saves them as the placement, since the route moves).
func roots_cells() -> Array[Vector2]:
	var cells: Array[Vector2] = []
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	for i in range(route.size() - 1, 0, -1):  # Back from the Heartwood: the whole cells the route runs through
		var cell := Vector2(FindPath.point_to_node(route[i]) / 2)
		if cell == map.endPath or cell == map.startPath or cells.has(cell):
			continue
		cells.append(cell)
		if cells.size() >= ROOTS_CELLS:
			break
	return cells

# Shifting Mist: up to `count` rim cells the start could move to (MapLayout's rules: on the rim, not by a
# corner, far enough from the Heartwood, a route from it with today's Wardens: they never rule a spot out on their own), spread
# apart and away from today's start. The same for the same map and start (seeded).
func start_options(count: int) -> Array[Vector2]:
	var size := Vector2i(MAP_GRID.size)
	var last := size - Vector2i.ONE
	var reach := Vector2(size).length() * MapLayout.MIN_DISTANCE_SHARE
	var candidates: Array[Vector2] = []
	var far_enough: Array[Vector2] = []
	for x in size.x:
		for y in size.y:
			var cell := Vector2i(x, y)
			var on_rim := x == 0 or y == 0 or x == last.x or y == last.y
			var by_corner := (x <= 1 or x >= last.x - 1) and (y <= 1 or y >= last.y - 1)
			if not on_rim or by_corner or Vector2(cell) == map.startPath:
				continue
			candidates.append(Vector2(cell))
			if Vector2(cell).distance_to(map.endPath) >= reach:
				far_enough.append(Vector2(cell))
	var pool := far_enough if far_enough.size() >= count else candidates
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([map.map_seed, map.startPath])
	for i in range(pool.size() - 1, 0, -1):  # Seeded shuffle
		var j := rng.randi_range(0, i)
		var swap := pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	var picked: Array[Vector2] = []
	for spread in [6.0, 3.0, 0.0]:  # Apart from each other and the start; relax if the rim is short of room
		for cell in pool:
			if picked.size() >= count:
				return picked
			if picked.has(cell) or cell.distance_to(map.startPath) < spread:
				continue
			if picked.any(func(p: Vector2) -> bool: return p.distance_to(cell) < spread):
				continue
			if route_from_start(cell).is_empty():
				continue
			picked.append(cell)
	return picked

# The route nightmares would take from rim cell `spot` (the gift screen's preview). Changes nothing.
func route_from_start(spot: Vector2) -> PackedVector2Array:
	if spot == map.startPath:
		return map.get_path_from(map.startPath)
	var opened: Array[Vector2] = []
	for h in FindPath.halves_of_cell(spot):
		if map.path_layer.is_half_blocked(h):
			opened.append(h)
			map.path_layer.set_half_blocked(h, false)
	var route: PackedVector2Array = map.path_layer.find_path_from(spot)
	for h in opened:
		map.path_layer.set_half_blocked(h, true)
	return route

# Puts `gift` on `cells` (the caller checked them; Shift the Stones moves `from[i]` to `cells[i]`).
# `restoring`: rebuilding a resumed run on the regenerated map. Obstacles a gift put down and the player
# tended later stay gone: `tended` (RunState.tended_cells) from index `tended_before` (the count when the
# gift was taken; -1 = unknown, any tending of the cell counts).
func apply(gift: StringName, cells: Array[Vector2], from: Array[Vector2] = [], restoring := false,
		tended_before := -1, tended: Array = []) -> void:
	var tended_later := func(cell: Vector2) -> bool:
		return restoring and tended.slice(maxi(tended_before, 0)).has(cell)
	match gift:
		SOW_RIDGE:
			for cell in cells:
				if not tended_later.call(cell):
					_put_obstacle(cell, "tree", TREE_DATA.tiles[EnvironmentTiles.cell_variant(Vector2i(cell), TREE_DATA.tiles.size())])
		FALLEN_GIANT:
			logs.append(cells.duplicate())
			_block(cells)
		GLADE:  # The obstacles the player picked (up to 5; user: "no control" with a radius)
			for cell in cells:
				_clear(cell, restoring)
		SHIFT_STONES:
			for i in mini(from.size(), cells.size()):
				_move_obstacle(from[i], cells[i], tended_later.call(cells[i]))
		MIRE:
			bog_cells.append_array(cells)
		SPRING:
			spring_cells.append_array(cells)
			_block(cells)
			_draw_spring()  # After _block, which clears the object layer
		MUSHROOM_RING:
			if not cells.is_empty():
				rings.append(Vector2(_min_x(cells), _min_y(cells)))  # Top-left
		LIGHTNING_TREE:
			if not cells.is_empty() and not tended_later.call(cells[0]):
				_put_obstacle(cells[0], "lightning", Vector2i.ZERO)
		MOONWELL:
			moonwells.append_array(cells)
			_block(cells)
		BELL_STONE:
			bell_stones.append_array(cells)
			_block(cells)
		ANCIENT_STUMP:
			stumps.append_array(cells)
		HEARTWOOD_ROOTS:
			root_cells.append_array(cells if not cells.is_empty() else roots_cells())
		SHIFTING_MIST:  # Replayed on a resume: the regenerated map starts at the old start again
			if not cells.is_empty():
				map.move_start(cells[0])
	_rebuild_props()
	map.path_layer.draw()
	map.path_changed.emit()
	queue_redraw()
	gifts_changed.emit()

func is_bog(cell: Vector2) -> bool:
	return bog_cells.has(cell)

func is_rooted(cell: Vector2) -> bool:
	return root_cells.has(cell)

func lightning_trees() -> Array[Vector2]:
	var cells: Array[Vector2] = []
	for cell in gift_obstacles:
		if gift_obstacles[cell][0] == "lightning":
			cells.append(cell)
	return cells

# --- Effects on nightmares ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	var frame := int(_frame_time)
	_frame_time = fmod(_frame_time + delta * EnvironmentTiles.FPS, EnvironmentTiles.FRAMES)
	if int(_frame_time) != frame:
		if not rings.is_empty() and _sheets.has("mushroom_ring"):
			queue_redraw()
		for prop in _props:
			if _sheets.has(prop.kind) and ANIMATED.has(prop.kind):
				prop.queue_redraw()
	if bog_cells.is_empty() and root_cells.is_empty():
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK
	var spawner: Node = map.get_node_or_null("%EnemyContainer")  # Made in code: no owner of its own for %
	if spawner == null:
		return
	for enemy in spawner.get_enemies():
		var cell: Vector2 = enemy.get_current_cell()
		var s: EnemyStatuses = enemy.statuses
		if bog_cells.has(cell) and not enemy.is_flying():  # Flyers pass over the bog
			s.slow_time = maxf(s.slow_time, TICK * 1.6)
			s.slow_amount = maxf(s.slow_amount if s.slow_time > 0.0 else 0.0, MIRE_SLOW)
		if root_cells.has(cell):
			s.ground_taken = ROOTS_TAKEN
			s.ground_taken_time = maxf(s.ground_taken_time, TICK * 1.6)

# --- Terrain changes ---------------------------------------------------------------------------------

func _put_obstacle(cell: Vector2, kind: String, tile: Vector2i) -> void:
	if map.get_obstacle(cell) != null:  # Restoring over a regenerated obstacle a gift had replaced
		map._remove_obstacle(cell, false)
	var data := _data_for(kind)
	map.place_obstacle(cell, data)
	if kind != "lightning":  # place_obstacle picked a random tile: use ours (moves keep their look)
		map.environment_object_layer.set_cell(Vector2i(cell), data.source_id, tile)
	gift_obstacles[cell] = [kind, tile]

# Moves the tree / stone on `from` to `to` (not a clear: nothing tended). `gone`: restoring, and the
# player tended it on `to` since.
func _move_obstacle(from: Vector2, to: Vector2, gone: bool) -> void:
	var data: ObstacleData = map.get_obstacle(from)
	if data == null:
		return  # Restoring: already tended away before the move? (the move needs it: nothing to do)
	var kind := "rock" if data.source_id == ROCK_DATA.source_id else "tree"
	var tile: Vector2i = map.environment_object_layer.get_cell_atlas_coords(Vector2i(from))
	gift_obstacles.erase(from)
	map._remove_obstacle(from, false)
	if not gone:
		_put_obstacle(to, kind, tile)

# Clears `cell` free. Fresh: through MapGenerator.clear_obstacle, so it counts as tended (RunState listens).
# Restoring: the save's tended cells already did that; anything left goes quietly.
func _clear(cell: Vector2, restoring: bool) -> void:
	gift_obstacles.erase(cell)
	if restoring:
		map._remove_obstacle(cell)
	else:
		map.clear_obstacle(cell)

func _block(cells: Array[Vector2]) -> void:
	for cell in cells:
		map.path_layer.set_cell_blocked(cell, true)
		map.environment_object_layer.erase_cell(Vector2i(cell))

func _draw_spring() -> void:
	for cell in spring_cells:  # Pond tiles by neighbour mask, banks facing the land
		map.environment_object_layer.set_cell(Vector2i(cell), EnvironmentTiles.POND,
			Vector2i(_mask(cell, func(c: Vector2) -> bool: return spring_cells.has(c)), 0))

func _data_for(kind: String) -> ObstacleData:
	match kind:
		"rock":
			return ROCK_DATA
		"lightning":
			var data: ObstacleData = TREE_DATA.duplicate()
			data.display_name = "Lightning Tree"
			data.tiles = []  # A GiftProp draws it
			return data
	return TREE_DATA

func _on_obstacle_cleared(cell: Vector2, _data: ObstacleData) -> void:
	if gift_obstacles.has(cell):
		gift_obstacles.erase(cell)
		_rebuild_props()
		gifts_changed.emit()

func _obstacles_within(centre: Vector2, radius: int) -> Array:
	var cells: Array = []
	for cell: Vector2 in map.obstacles:
		if absf(cell.x - centre.x) <= radius and absf(cell.y - centre.y) <= radius:
			cells.append(cell)
	return cells

static func _min_x(cells: Array) -> float:
	return cells.reduce(func(m: float, c: Vector2) -> float: return minf(m, c.x), INF)

static func _min_y(cells: Array) -> float:
	return cells.reduce(func(m: float, c: Vector2) -> float: return minf(m, c.y), INF)

static func _mask(cell: Vector2, on: Callable) -> int:
	return ((1 if on.call(cell + Vector2.UP) else 0) | (2 if on.call(cell + Vector2.RIGHT) else 0)
		| (4 if on.call(cell + Vector2.DOWN) else 0) | (8 if on.call(cell + Vector2.LEFT) else 0))

# --- Drawing ----------------------------------------------------------------------------------------

func set_act(new_act: int) -> void:
	act = new_act
	_load_sheets()
	queue_redraw()
	for prop in _props:
		prop.queue_redraw()

func _load_sheets() -> void:
	_sheets.clear()
	for sheet: String in ART:
		var path := EnvironmentTiles.sheet_path(sheet, act)
		if ResourceLoader.exists(path):
			_sheets[sheet] = load(path)
	_load_dual_sheets()

func frame_region(sheet: String, column: int) -> Rect2:
	var size: Vector2i = ART[sheet][0]
	return Rect2(Vector2(column * size.x, 0), Vector2(size))

func _draw() -> void:
	var cell_size := Vector2(MAP_GRID.cell_size)
	var path_cells: PackedVector2Array = map.path_layer.current_path
	for cell in bog_cells if not has_dual("bog") else []:
		var at := MAP_GRID.calculate_map_position(cell) - cell_size / 2.0
		if _sheets.has("bog_path"):
			var mask := _mask(cell, func(c: Vector2) -> bool: return path_cells.has(c) or bog_cells.has(c))
			draw_texture_rect_region(_sheets.bog_path, Rect2(at, cell_size), frame_region("bog_path", mask))
		else:  # Placeholder: dark peat with two puddles
			draw_rect(Rect2(at + Vector2(6, 6), cell_size - Vector2(12, 12)), Color(Palette.ROOT, 0.7))
			draw_circle(at + Vector2(22, 26), 7.0, Palette.POOL)
			draw_circle(at + Vector2(42, 40), 5.0, Palette.POOL)
	for cell in root_cells if not has_dual("roots") else []:
		var at := MAP_GRID.calculate_map_position(cell) - cell_size / 2.0
		if _sheets.has("heartwood_roots"):
			var mask := _mask(cell, func(c: Vector2) -> bool: return path_cells.has(c) or root_cells.has(c) or c == map.endPath)
			draw_texture_rect_region(_sheets.heartwood_roots, Rect2(at, cell_size), frame_region("heartwood_roots", mask))
		else:  # Placeholder: warm root lines across the cell
			var c := at + cell_size / 2.0
			draw_line(c + Vector2(-26, -10), c + Vector2(24, 12), Palette.OAK, 4.0)
			draw_line(c + Vector2(-20, 16), c + Vector2(26, -14), Palette.BARK, 3.0)
	for top in rings:
		var at := MAP_GRID.calculate_map_position(top) - cell_size / 2.0
		if _sheets.has("mushroom_ring"):
			draw_texture_rect_region(_sheets.mushroom_ring, Rect2(at, cell_size * 3), frame_region("mushroom_ring", int(_frame_time)))
		else:  # Placeholder: a ring of toadstools
			var centre := at + cell_size * 1.5
			for i in 12:
				var p := centre + Vector2.from_angle(TAU * i / 12.0) * cell_size.x * 1.25
				draw_circle(p, 6.0, Palette.EMBER)
				draw_circle(p + Vector2(-2, -2), 2.0, Palette.GLOW)
	for cell in stumps:
		var at := MAP_GRID.calculate_map_position(cell) - cell_size / 2.0
		if _sheets.has("ancient_stump"):
			draw_texture_rect_region(_sheets.ancient_stump, Rect2(at, cell_size),
				frame_region("ancient_stump", EnvironmentTiles.cell_variant(Vector2i(cell), 3)))
		else:  # Placeholder: a wide cut stump with rings
			var c := at + cell_size / 2.0
			draw_circle(c, 20.0, Palette.BARK)
			draw_arc(c, 14.0, 0, TAU, 20, Palette.OAK, 2.0)
			draw_arc(c, 7.0, 0, TAU, 14, Palette.OAK, 2.0)

# Standing props, y-sorted with the trees under MapGenerator.
func _rebuild_props() -> void:
	for prop in _props:
		prop.queue_free()
	_props.clear()
	for l: Array in logs:
		for cell in l:
			_add_prop("fallen_log", cell, l)
	for cell in moonwells:
		_add_prop("moonwell", cell)
	for cell in bell_stones:
		_add_prop("bell_stone", cell)
	for cell in lightning_trees():
		_add_prop("lightning_tree", cell)

func _add_prop(kind: String, cell: Vector2, line: Array = []) -> void:
	var prop := GiftProp.new()
	prop.gifts = self
	prop.kind = kind
	prop.line = line
	prop.piece = _log_piece(cell, line)
	prop.position = MAP_GRID.calculate_map_position(cell)
	map.add_child(prop)
	_props.append(prop)

# Which fallen_log.png piece a Fallen Giant cell takes: its ends and middles along the line.
static func _log_piece(cell: Vector2, line: Array) -> int:
	if line.size() < 2:
		return -1
	var vertical: bool = line[0].x == line[1].x
	var along: Array = line.map(func(c: Vector2) -> float: return c.y if vertical else c.x)
	var at := cell.y if vertical else cell.x
	var first := 0 if at == along.min() else (2 if at == along.max() else 1)
	return first + (3 if vertical else 0)

class GiftProp extends Node2D:
	var gifts: MapGifts
	var kind: String
	var line: Array = []
	var piece := -1  # A Fallen Giant cell's piece of fallen_log.png; -1 = the animation frame

	func _draw() -> void:
		var sheet: Texture2D = gifts._sheets.get(kind)
		if sheet != null:
			var size := Vector2(MapGifts.ART[kind][0])
			var at := Vector2(-size.x / 2.0, 32.0 - size.y)  # Tall sprites put their bottom 64 px on the cell
			draw_texture_rect_region(sheet, Rect2(at, size), gifts.frame_region(kind, piece if piece >= 0 else int(gifts._frame_time)))
			return
		match kind:  # Placeholders in palette colours
			"fallen_log":
				var along := Vector2.DOWN if line.size() > 1 and line[0].x == line[1].x else Vector2.RIGHT
				var half := along * 32.0
				draw_line(-half, half, Palette.ROOT, 30.0)
				draw_line(-half, half, Palette.BARK, 24.0)
				draw_line(-half + along.orthogonal() * 6, half + along.orthogonal() * 6, Palette.OAK, 4.0)
			"moonwell":
				draw_circle(Vector2.ZERO, 24.0, Palette.STONE)
				draw_circle(Vector2.ZERO, 16.0, Palette.POOL)
				draw_circle(Vector2(-4, -4), 7.0, Palette.MOONLIGHT)
			"bell_stone":
				draw_rect(Rect2(-12, -40, 24, 64), Palette.SLATE)
				draw_circle(Vector2(0, -18), 6.0, Palette.GOLD)
			"lightning_tree":
				draw_line(Vector2(0, 24), Vector2(0, -60), Palette.DEADWOOD, 10.0)
				draw_line(Vector2(0, -30), Vector2(-20, -56), Palette.DEADWOOD, 5.0)
				draw_line(Vector2(0, -40), Vector2(18, -66), Palette.DEADWOOD, 5.0)
				draw_line(Vector2(-6, -64), Vector2(6, -48), Palette.WRAITHLIGHT, 2.0)

# --- Mire and Roots on the half-cell path (dual grid) -------------------------------------------------
# The path is drawn on PathGenerator's dual grid (32 px tiles, 16 px off the half grid). Where the route runs
# through a Mire cell, bog_path_dual.png replaces path_dual.png's tile; over a rooted cell,
# heartwood_roots_dual.png is laid on top. Same corner masks as the path (PathGenerator.dual_mask), on layers
# drawn over the path's own, so the bog and the roots follow the ribbon. Without those sheets: the old
# whole-cell drawing in _draw().
const DUAL_SHEETS := {"bog": "bog_path_dual", "roots": "heartwood_roots_dual"}
var _dual_layers := {}  # "bog" / "roots" -> TileMapLayer

func _load_dual_sheets() -> void:
	for kind: String in DUAL_SHEETS:
		var path := EnvironmentTiles.sheet_path(DUAL_SHEETS[kind], act)
		if not ResourceLoader.exists(path):
			continue
		var layer: TileMapLayer = _dual_layers.get(kind)
		if layer == null:
			layer = TileMapLayer.new()
			layer.name = "Gift" + kind.capitalize() + "Dual"
			layer.position = -Vector2(PathGenerator.DUAL_SIZE) / 2.0
			var tiles := TileSet.new()
			tiles.tile_size = PathGenerator.DUAL_SIZE
			var source := TileSetAtlasSource.new()
			source.texture_region_size = PathGenerator.DUAL_SIZE
			source.texture = load(path)
			for column in source.get_atlas_grid_size().x:
				source.create_tile(Vector2i(column, 0))
			tiles.add_source(source, 0)
			layer.tile_set = tiles
			map.path_layer.add_child(layer)  # Over the path's dual layer and the start's tile
			_dual_layers[kind] = layer
		else:
			(layer.tile_set.get_source(0) as TileSetAtlasSource).texture = load(path)
	_draw_duals()

func has_dual(kind: String) -> bool:
	return _dual_layers.has(kind)

# Bog and roots tiles: every path display tile with a corner on a Mire / rooted cell's halves.
func _draw_duals() -> void:
	if _dual_layers.is_empty() or map == null or map.path_layer == null:
		return
	var halves: Dictionary = map.path_layer.path_halves()
	for kind: String in _dual_layers:
		var layer: TileMapLayer = _dual_layers[kind]
		layer.clear()
		var cells: Array[Vector2] = bog_cells if kind == "bog" else root_cells
		if cells.is_empty():
			continue
		var marked := {}
		for cell in cells:
			for h in FindPath.halves_of_cell(cell):
				if halves.has(Vector2i(h)):
					marked[Vector2i(h)] = true
		var done := {}
		for h: Vector2i in marked:  # Each marked path half is a corner of 4 display tiles
			for dy in 2:
				for dx in 2:
					var at := h + Vector2i(dx, dy)
					if done.has(at):
						continue
					done[at] = true
					var mask := PathGenerator.dual_mask(halves, at)
					if mask == 15:
						mask = PathGenerator.DUAL_FULL_VARIANTS[EnvironmentTiles.cell_variant(at, PathGenerator.DUAL_FULL_VARIANTS.size(), 7)]
					layer.set_cell(at, 0, Vector2i(mask, 0))
