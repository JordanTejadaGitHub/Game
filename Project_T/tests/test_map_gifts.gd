extends SceneTree
# Heartwood's Gifts, the terrain (heartwood_gifts.md, MapGifts): each terrain gift's effect on the map and on
# nightmares, registration with HeartwoodGifts, and a resumed run rebuilding the same terrain by replaying the
# gifts in order (tended cells first, as RunSaver does), with gift trees the player tended staying gone.
# Run:  Godot --headless --path . --script res://tests/test_map_gifts.gd --fixed-fps 60

const SEED := 1207

var failures := 0
var _log: Array = []  # [id, cells, from, tended_before]: what HeartwoodGifts would save

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)

func _init() -> void:
	var pid := OS.get_process_id()
	HeartwoodMemory.file_path = "user://test_gifts_profile_%d.json" % pid
	RunSaver.file_path = "user://test_gifts_run_%d.json" % pid
	var main := await _make_main()
	var map = main.get_node("%MapGenerator")
	var gifts: MapGifts = map.gifts
	var run_state: RunState = main.get_node("%RunState")
	for id in MapGifts.TERRAIN_GIFTS:
		_check(HeartwoodGifts.has_effect(id), "%s has an effect, so it can be drawn" % id)

	# Sow a Ridge: Withered Trees on the chosen cells.
	var ridge := _find(map, func(c: Vector2) -> Array: return [c, c + Vector2(1, 0), c + Vector2(2, 0)], true)
	_give(gifts, run_state, MapGifts.SOW_RIDGE, ridge)
	_check(ridge.all(func(c: Vector2) -> bool: return map.get_obstacle(c) == MapGifts.TREE_DATA), "a ridge of Withered Trees")

	# Fallen Giant: blocked, never clearable.
	var log_cells := _find(map, func(c: Vector2) -> Array: return [c, c + Vector2(0, 1), c + Vector2(0, 2)], true)
	_give(gifts, run_state, MapGifts.FALLEN_GIANT, log_cells)
	_check(log_cells.all(func(c: Vector2) -> bool: return not map.is_buildable(c) and map.get_obstacle(c) == null),
		"the log blocks its cells and can't be cleared")

	# Mire: nightmares on the bog are slowed (through the slow floors).
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var route_cells: Array[Vector2] = []  # Half cells: the whole cells the route runs through, in order
	for p in route:
		var c := Vector2(FindPath.point_to_node(p) / 2)
		if not route_cells.has(c):
			route_cells.append(c)
	var bog: Array[Vector2] = [route_cells[2], route_cells[3], route_cells[4]]
	_give(gifts, run_state, MapGifts.MIRE, bog)
	_check(not gifts.has_dual("bog") or gifts._dual_layers["bog"].get_used_cells().size() > 0, "the bog is drawn on the path's dual grid")
	var shade: Node2D = main.get_node("%EnemyContainer").spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	shade.set_physics_process(false)
	shade.set_process(false)
	shade.position = map.MAP_GRID.calculate_map_position(route_cells[3])
	gifts._tick = 0.0
	await process_frame
	_check(is_equal_approx(shade.statuses.get_speed_multiplier(), 1.0 - MapGifts.MIRE_SLOW),
		"bog: 20%% slower (%.2f)" % shade.statuses.get_speed_multiplier())

	# Heartwood Roots: the last 4 route cells before the Heartwood; +15% taken there.
	var roots := gifts.roots_cells()
	_check(roots.size() == 4 and not roots.has(map.endPath) and route_cells.has(roots[0]), "roots: the last 4 path cells")
	_give(gifts, run_state, MapGifts.HEARTWOOD_ROOTS, roots)
	_check(not gifts.has_dual("roots") or gifts._dual_layers["roots"].get_used_cells().size() > 0, "the roots are drawn on the path's dual grid")
	shade.position = map.MAP_GRID.calculate_map_position(roots[0])
	gifts._tick = 0.0
	await process_frame
	_check(is_equal_approx(shade.statuses.get_damage_taken_multiplier(), 1.0 + MapGifts.ROOTS_TAKEN),
		"roots: +15%% taken (%.2f)" % shade.statuses.get_damage_taken_multiplier())
	shade.free()

	# Spring (pond tiles, blocked), Moonwell, Bell Stone (blocked), Lightning Tree (an obstacle).
	var spring := _find(map, func(c: Vector2) -> Array: return [c, c + Vector2(1, 0), c + Vector2(0, 1), c + Vector2(1, 1)], true)
	_give(gifts, run_state, MapGifts.SPRING, spring)
	var env: TileMapLayer = map.environment_object_layer
	_check(spring.all(func(c: Vector2) -> bool: return env.get_cell_source_id(Vector2i(c)) == EnvironmentTiles.POND and not map.is_buildable(c)),
		"a spring: pond tiles, unbuildable")
	for id in [MapGifts.MOONWELL, MapGifts.BELL_STONE]:
		var at := _find(map, func(c: Vector2) -> Array: return [c], true)
		_give(gifts, run_state, id, at)
		_check(not map.is_buildable(at[0]) and map.get_obstacle(at[0]) == null, "%s blocks its cell" % id)
	var lightning := _find(map, func(c: Vector2) -> Array: return [c], true)
	_give(gifts, run_state, MapGifts.LIGHTNING_TREE, lightning)
	_check(map.get_obstacle(lightning[0]) != null and gifts.lightning_trees() == lightning, "a Lightning Tree")
	_check(gifts._props.size() == log_cells.size() + 3, "props stand for the log, Moonwell, Bell Stone and tree")
	var pieces: Array = gifts._props.filter(func(p: Node2D) -> bool: return p.kind == "fallen_log").map(func(p: Node2D) -> int: return p.piece)
	pieces.sort()
	_check(pieces == [3, 4, 5], "a 3-cell N-S log: N end, middle, S end (%s)" % [pieces])

	# Mushroom Ring and Ancient Stumps stay open ground.
	var ring := _find(map, _square3, false)
	_give(gifts, run_state, MapGifts.MUSHROOM_RING, ring)
	_check(gifts.rings == [ring[0]] and map.is_buildable(ring[4]), "a mushroom ring, still open ground")
	var stump_cells := _find(map, func(c: Vector2) -> Array: return [c, c + Vector2(3, 0), c + Vector2(6, 0)], false)
	_give(gifts, run_state, MapGifts.ANCIENT_STUMP, stump_cells)
	_check(gifts.stumps.size() == 3 and map.is_buildable(stump_cells[0]), "3 stumps, still buildable")

	# Glade: up to 5 obstacles the player picks (user: a radius gave "no control"), each cleared free and tended.
	var to_clear: Array = []
	for cell: Vector2 in map.obstacles:
		if to_clear.size() < 5 and not gifts.gift_obstacles.has(cell) and map.get_obstacle_cells(cell).size() == 1:
			to_clear.append(cell)
	var tended := run_state.obstacles_tended
	var glade_cells: Array[Vector2] = []
	glade_cells.assign(to_clear)
	_give(gifts, run_state, MapGifts.GLADE, glade_cells)
	_check(to_clear.all(func(c: Vector2) -> bool: return map.get_obstacle(c) == null)
		and run_state.obstacles_tended == tended + to_clear.size(), "a glade: %d cleared and tended" % to_clear.size())

	# Shift the Stones: a stone moves (not tended).
	var from := Vector2(-1, -1)
	for cell: Vector2 in map.obstacles:
		if not gifts.gift_obstacles.has(cell) and not map.get_obstacle(cell).tiles.is_empty():
			from = cell
			break
	var to := _find(map, func(c: Vector2) -> Array: return [c], true)
	var moved: ObstacleData = map.get_obstacle(from)
	tended = run_state.obstacles_tended
	var froms: Array[Vector2] = [from]
	_give(gifts, run_state, MapGifts.SHIFT_STONES, to, froms)
	_check(map.get_obstacle(from) == null and map.get_obstacle(to[0]) == moved and run_state.obstacles_tended == tended,
		"a stone moves, not tended")

	# Shifting Mist (replaced Deeper Glade): 3 rim spots with a route each; picking one moves the start.
	_check(not MapGifts.TERRAIN_GIFTS.has(&"deeper_glade"), "Deeper Glade is gone")
	var options := gifts.start_options(3)
	_check(options.size() == 3 and options.all(func(c: Vector2) -> bool: return _rim_spot_ok(map, c)), "3 rim spots, each with a route (%s)" % [options])
	_check(options == gifts.start_options(3), "the same spots when asked again")
	var ghost := Node2D.new()  # The gift screen's ghost at each spot (Main's placer calls it)
	var drawn := [0]
	ghost.draw.connect(func() -> void:
		for spot in options:
			gifts.draw_start_ghost(ghost, spot, 0.5)
			drawn[0] += 1)
	map.add_child(ghost)
	ghost.queue_redraw()
	await process_frame
	await process_frame
	_check(drawn[0] == options.size(), "the mist-and-bridge ghost draws at each spot")
	ghost.free()
	var old_start: Vector2 = map.startPath
	var preview := gifts.route_from_start(options[0])
	var shift: Array[Vector2] = [options[0]]
	_give(gifts, run_state, MapGifts.SHIFTING_MIST, shift)
	_check(map.startPath == options[0] and map.get_path_from(map.startPath) == preview, "the start moves; the route is the preview")
	_check(env.get_cell_source_id(Vector2i(options[0])) == EnvironmentTiles.EDGE_MIST
		and env.get_cell_source_id(Vector2i(old_start)) == EnvironmentTiles.ISLAND_EDGE
		and map.path_layer.is_cell_blocked(old_start) and not map.path_layer.is_cell_blocked(options[0]),
		"the mist and the way in move; the old start is rim again")
	var out: Vector2i = env._outward(Vector2i(options[0]))
	_check(env.get_cell_source_id(Vector2i(options[0]) + out) == EnvironmentTiles.ROPE_BRIDGE, "a rope bridge out from the new start")

	# The player tends a gift tree and the moved stone afterwards: they stay gone on resume.
	var tended_before: int = run_state.obstacles_tended
	map.clear_obstacle(ridge[1])
	_check(run_state.obstacles_tended == tended_before + MapGifts.SOWN_TREE_SEEDS,
		"tending a Sow a Ridge tree pays %d Seeds (instead of 1)" % MapGifts.SOWN_TREE_SEEDS)
	map.clear_obstacle(lightning[0])
	_check(gifts.lightning_trees().is_empty() and not gifts.gift_obstacles.has(ridge[1]), "tended gift trees leave the gifts' terrain")
	_check(not map.get_path_from(map.startPath).is_empty(), "the way is still open")

	# Resume: a regenerated map, the tended cells first, then every gift again in order.
	var tended_cells: Array[Vector2] = run_state.tended_cells.duplicate()
	var blocked := _blocked(map)
	var obstacle_cells: Array = map.obstacles.keys()
	obstacle_cells.sort()
	var state := _state(gifts)
	main.queue_free()
	await process_frame
	var again := await _make_main()
	var map2 = again.get_node("%MapGenerator")
	var run_state2: RunState = again.get_node("%RunState")
	run_state2.tended_cells = tended_cells
	for cell in tended_cells:
		map2._remove_obstacle(cell)
	for entry: Array in _log:
		map2.gifts.apply(entry[0], entry[1], entry[2], true, entry[3], tended_cells)
	var obstacle_cells2: Array = map2.obstacles.keys()
	obstacle_cells2.sort()
	_check(obstacle_cells2 == obstacle_cells, "the same obstacles on resume (%d vs %d)" % [obstacle_cells2.size(), obstacle_cells.size()])
	_check(_blocked(map2) == blocked, "the same blocked cells on resume")
	_check(_state(map2.gifts) == state, "the same gift terrain on resume")
	_check(run_state2.obstacles_tended == 0, "replaying counts nothing as tended again")
	again.queue_free()
	await process_frame
	print("test_map_gifts: %d failure(s)" % failures)
	quit(failures)

# As HeartwoodGifts.choose does: apply now, remember what to replay.
func _give(gifts: MapGifts, run_state: RunState, id: StringName, cells: Array, from: Array[Vector2] = []) -> void:
	var typed: Array[Vector2] = []
	typed.assign(cells)
	var before := run_state.tended_cells.size()
	gifts.apply(id, typed, from)
	_log.append([id, typed, from, before])

func _make_main() -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = SEED
	root.add_child(main)
	await process_frame
	return main

# The first anchor (reading order) whose `shape` cells are all open ground away from the start, the
# glade and other gifts; `blocks`: blocking them all keeps the way open.
func _find(map: Node, shape: Callable, blocks: bool) -> Array:
	var gifts: MapGifts = map.gifts
	for y in range(2, int(map.MAP_GRID.size.y) - 4):
		for x in range(2, int(map.MAP_GRID.size.x) - 8):
			var cells: Array = shape.call(Vector2(x, y))
			var ok := cells.all(func(c: Vector2) -> bool: return _open(map, c))
			if ok and (not blocks or not map.get_path_if_blocked_cells(cells).is_empty()):
				return cells
	failures += 1
	print("FAIL: no room for a shape")
	return []

func _in_rings(gifts: MapGifts, cell: Vector2) -> bool:
	return gifts.rings.any(func(t: Vector2) -> bool: return cell.x >= t.x and cell.x < t.x + 3 and cell.y >= t.y and cell.y < t.y + 3)

func _state(gifts: MapGifts) -> String:
	return var_to_str([gifts.gift_obstacles, gifts.logs, gifts.spring_cells, gifts.moonwells, gifts.bell_stones,
		gifts.bog_cells, gifts.root_cells, gifts.rings, gifts.stumps, gifts.map.startPath])

func _blocked(map: Node) -> Array:
	var cells: Array = []
	for y in int(map.MAP_GRID.size.y):
		for x in int(map.MAP_GRID.size.x):
			if map.path_layer.is_cell_blocked(Vector2(x, y)):
				cells.append(Vector2(x, y))
	return cells

func _square3(c: Vector2) -> Array:
	var cells: Array = []
	for dy in 3:
		for dx in 3:
			cells.append(c + Vector2(dx, dy))
	return cells

func _open(map: Node, c: Vector2) -> bool:
	var gifts: MapGifts = map.gifts
	return (map.is_buildable(c) and not map.get_glade_cells().has(c) and not gifts.is_bog(c) and not gifts.is_rooted(c)
		and not gifts.stumps.has(c) and not _in_rings(gifts, c) and not map.path_layer.current_path.has(c))

func _rim_spot_ok(map: Node, c: Vector2) -> bool:
	var size := Vector2i(map.MAP_GRID.size)
	var on_rim := c.x == 0 or c.y == 0 or c.x == size.x - 1 or c.y == size.y - 1
	return on_rim and c != map.startPath and not map.gifts.route_from_start(c).is_empty()
