extends SceneTree

# Headless test for the Waymark (Legendary Dream; owner 2026-10-21, legendaries_final.md 1.1): placement legality, the
# held Start and save, the two-leg route (per-leg indices on a corridor walked both ways), a walker visiting the stone
# before the Heartwood and shedding every status there, flyers ignoring it, a build that would cut a leg refused, Restless,
# unique-cell maze counting and the stone in the run save.
#   godot --headless --path . --script res://tests/test_waymark.gd --fixed-fps 60

var RUN_PATH := "user://test_waymark_run_%d.json" % OS.get_process_id()  # Per process: parallel sessions share user://
var PROFILE_PATH := "user://test_waymark_profile_%d.json" % OS.get_process_id()
const MAP_SEED := 4242
const FAST := 6.0  # Walkers sped up so the test stays short
const WALK_FRAMES := 6000

var failures := 0
var main: Node
var map
var dreams: DreamState
var director: DriftDirector
var saver: RunSaver
var spawner
var placer: TowerPlacer
var run_state: RunState

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func _run() -> void:
	RunSaver.file_path = RUN_PATH
	HeartwoodMemory.file_path = PROFILE_PATH
	RunSaver.delete_save()
	main = await _new_run()
	_bind()
	run_state.dew = 100000
	_test_card()
	_test_ground()
	var cell := _pick_cell()
	_check(cell.x >= 0, "an open cell for the stone exists on seed %d" % MAP_SEED)
	if cell.x < 0:
		_finish()
		return
	_test_take_and_place(cell)
	_test_legs(cell)
	var walls := _close_three_sides(cell)
	_test_cut_refused(cell, walls)
	_test_overlap(cell)
	await _test_walker(cell)
	await _test_flyer()
	_test_laps()
	map.unblock_halves(walls)
	_test_maze(cell)
	await _test_save(cell)
	_finish()

func _finish() -> void:
	if main != null and is_instance_valid(main):
		main.queue_free()
	await process_frame
	RunSaver.delete_save()
	if FileAccess.file_exists(PROFILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	print("waymark test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _new_run() -> Node:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	scene.get_node("MapGenerator").map_seed = MAP_SEED
	root.add_child(scene)
	await process_frame
	await process_frame
	return scene

func _bind() -> void:
	map = main.get_node("%MapGenerator")
	dreams = main.get_node("%DreamState")
	director = main.get_node("%DriftDirector")
	saver = main.get_node("%RunSaver")
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	run_state = main.get_node("%RunState")

func _card(id: String) -> UpgradeData:
	for card in dreams.pool:
		if card.id == id:
			return card
	_check(false, "card %s exists" % id)
	return null

func _test_card() -> void:
	var card := _card("waymark")
	if card == null:
		return
	_check(card.rarity == UpgradeData.Rarity.LEGENDARY and card.kind == UpgradeData.Kind.RULE and card.min_act == 2
		and card.in_start_pool and card.max_stacks == 1 and card.rule_id == &"waymark", "Waymark is a start-pool Legendary rule from act 2")
	_check(DreamState.CARD_CUES.needs_no_cue(&"waymark"), "the stone is the card's look (NATURAL)")

# Where the stone can't stand.
func _test_ground() -> void:
	_check(not map.can_place_waymark(map.startPath), "not on the start")
	_check(not map.can_place_waymark(map.endPath), "not on the Heartwood")
	_check(not map.can_place_waymark(map.get_glade_cells()[0]), "not in the Heartwood's glade")
	if not map.obstacles.is_empty():
		_check(not map.can_place_waymark(map.obstacles.keys()[0]), "not on an obstacle")
	var near_start: Vector2 = map.startPath + (Vector2(1, 0) if map.startPath.x < 1 else Vector2(-1, 0))
	_check(not map.is_waymark_ground(near_start), "not in the start's mist")
	_check(not map.can_place_waymark(Vector2(-3, -3)), "not off the map")

# An open cell with four buildable neighbours, as far from the Heartwood as can be, whose four sides can close without
# cutting the plain start -> Heartwood route (so a dead end round it is a Waymark test, not a closed map).
func _pick_cell() -> Vector2:
	var best := Vector2(-1, -1)
	var best_d := -1.0
	var finder: FindPath = map.path_layer.get_finder()
	for x in map.MAP_GRID.size.x:
		for y in map.MAP_GRID.size.y:
			var cell := Vector2(x, y)
			var d: float = cell.distance_to(map.endPath)
			if d <= best_d or not map.can_place_waymark(cell):
				continue
			var sides := _sides(cell)
			if not sides.all(func(c: Vector2) -> bool: return map.is_buildable(c)):
				continue
			var version: int = map.probe_begin()
			var closed: Array = []
			for c in sides + [cell]:
				for h in FindPath.halves_of_cell(c):
					if not finder.is_half_blocked(h):
						finder.set_half_blocked(h, true)
						closed.append(h)
			var plain := finder.calculate_point_path(map.startPath, map.endPath)
			for h in closed:
				finder.set_half_blocked(h, false)
			closed.clear()
			for c in sides.slice(0, 3):  # Three sides shut (the stub): both legs must still reach the stone's open side
				for h in FindPath.halves_of_cell(c):
					if not finder.is_half_blocked(h):
						finder.set_half_blocked(h, true)
						closed.append(h)
			var stub_ok := not finder.calculate_point_path(map.startPath, cell).is_empty() \
				and not finder.calculate_point_path(cell, map.endPath).is_empty()
			for h in closed:
				finder.set_half_blocked(h, false)
			map.probe_end(version)
			if not plain.is_empty() and stub_ok:
				best = cell
				best_d = d
	return best

static func _sides(cell: Vector2) -> Array:
	return [cell + Vector2.UP, cell + Vector2.RIGHT, cell + Vector2.DOWN, cell + Vector2.LEFT]

func _test_take_and_place(cell: Vector2) -> void:
	_check(saver.can_save_now(), "a rest with nothing open can save")
	dreams.take(_card("waymark"))
	_check(dreams.has_rule(&"waymark") and dreams.waymark_needed(), "taken: the stone waits to be placed")
	_check(director.pending_choice() == &"waymark" and not director.can_start_next_drift(), "Start is held until the stone is placed")
	_check(not saver.can_save_now(), "no save before the stone is placed")
	var stone = map.waymark_stone
	_check(stone != null and not stone.place_at(map.endPath), "the stone refuses the Heartwood")
	_check(stone != null and stone.place_at(cell) and map.waymark_cell == cell, "the stone stands on open ground")
	_check(not dreams.waymark_needed() and director.pending_choice() == &"" and saver.can_save_now(),
		"placed: Start and the save are free again")
	_check(stone.visible and stone.position == map.MAP_GRID.calculate_map_position(cell), "the stone shows on its cell")
	_check(not map.is_buildable(cell) and not map.can_block_halves(FindPath.halves_of_cell(cell)), "its cell can never be built on")

func _test_legs(cell: Vector2) -> void:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var split: int = map.waymark_split(route)
	_check(split > 0 and split < route.size() - 1, "the route runs out to the stone, then on (split %d of %d)" % [split, route.size()])
	_check(route == map.path_layer.current_path, "the drawn route is the two legs")
	var plain: PackedVector2Array = map.path_layer.get_finder().calculate_point_path(map.startPath, map.endPath)
	_check(map.route_length(route) >= map.route_length(plain), "the two legs are never shorter than the plain route")
	var on_halves: Dictionary = map.path_layer.path_halves()
	var touches := false
	for h in FindPath.halves_of_cell(cell):
		touches = touches or on_halves.has(Vector2i(h))
	_check(touches, "the drawn path tiles reach the stone")
	var past := split + 1  # The first point off the stone (the route may cross two of its halves in a row)
	while past < route.size() - 1 and map.is_waymark_point(route[past]):
		past += 1
	_check(not map.get_path_from(route[split], true).is_empty() and map.waymark_split(map.get_path_from(route[past], true)) < 0,
		"a walker past the stone heads straight for the Heartwood")
	var mid: Vector2 = route[maxi(split / 2, 1)]
	_check(map.waymark_split(map.get_path_from(mid)) >= 0, "a walker on leg 1 still goes to the stone")

# Walls on three sides of the stone (forced, no Wardens): it sits at the end of a one-cell stub, so the legs share it.
func _close_three_sides(cell: Vector2) -> Array:
	var halves: Array = []
	for c in _sides(cell).slice(0, 3):
		halves.append_array(FindPath.halves_of_cell(c))
	_check(map.can_block_halves(halves), "closing three sides keeps both legs")
	map.block_halves(halves)
	return halves

func _test_cut_refused(cell: Vector2, _walls: Array) -> void:
	var last: Vector2 = _sides(cell)[3]
	var halves := FindPath.halves_of_cell(last)
	var plain_ok: bool = not map.get_path_if_blocked_halves(halves).is_empty()
	_check(not plain_ok, "with the stone, closing its last side leaves no two-leg route")
	_check(not map.can_block_halves(halves) and map.block_refusal() == &"closes", "a build that would cut a leg is refused")
	var version: int = map.probe_begin()
	var finder: FindPath = map.path_layer.get_finder()
	for h in halves:
		finder.set_half_blocked(h, true)
	var start_end := finder.calculate_point_path(map.startPath, map.endPath)
	for h in halves:
		finder.set_half_blocked(h, false)
	map.probe_end(version)
	_check(not start_end.is_empty(), "the same build would be legal without the stone (start -> Heartwood stays open)")

# The stub is walked both ways: its points are on both legs, and each leg keeps its own index.
func _test_overlap(cell: Vector2) -> void:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var split: int = map.waymark_split(route)
	var shared := Vector2(-1, -1)
	for i in split:
		if route.slice(split + 1).has(route[i]):
			shared = route[i]
	_check(shared.x >= 0, "a corridor to a dead-end stone is on both legs")
	if shared.x < 0:
		return
	var tail1: PackedVector2Array = map.get_path_from(shared)
	var tail2: PackedVector2Array = map.get_path_from(shared, true)
	_check(map.waymark_split(tail1) >= 0, "leg 1 on the shared corridor still walks to the stone (never the leg 2 tail)")
	_check(map.waymark_split(tail2) < 0 and tail2.size() < tail1.size(), "leg 2 on it walks on to the Heartwood")
	var off := FindPath.node_to_point(Vector2i(cell * 2) + Vector2i(0, 0))
	_check(map.is_waymark_point(off) and not map.is_waymark_point(cell), "the stone's halves are its points; its whole cell is not")

func _test_walker(cell: Vector2) -> void:
	var data: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var enemy = spawner.spawn_enemy(data, 1.0)
	_check(enemy != null, "a walker spawns")
	if enemy == null:
		return
	enemy.speed *= FAST
	enemy.apply_status(EnemyStatuses.DAMP, 2, 60.0)
	enemy.apply_status(EnemyStatuses.MARKED, 3, 60.0)
	enemy.statuses.marked_forever = true
	enemy.statuses.static_forever = true
	var log := {"touched": -1, "goal": -1, "statuses": -1, "forever": true, "restless": -1}
	var frame := [0]
	enemy.waymark_reached.connect(func(e: Node2D, _shed: int) -> void:
		log.touched = frame[0]
		log.statuses = e.statuses.count()
		log.forever = e.statuses.marked_forever or e.statuses.static_forever)
	spawner.enemy_reached_goal.connect(func(_e: Node2D) -> void: log.goal = frame[0])
	_check(enemy.statuses.count() >= 1, "it carries statuses on its way in")
	_check(enemy._waymark_index >= 0 and not enemy.passed_waymark, "its route has the stone ahead")
	var restless_checked := false
	for i in WALK_FRAMES:
		frame[0] = i
		if int(log.goal) >= 0:
			break
		if int(log.touched) >= 0 and not restless_checked and is_instance_valid(enemy):
			restless_checked = true
			spawner._on_path_changed()  # A placement right as it turns at the stone
			log.restless = enemy.get_restless()
		await process_frame
	print("  walker: stone at frame %d, Heartwood at %d, statuses after the stone %d, Restless %d" % [log.touched, log.goal, log.statuses, log.restless])
	_check(int(log.touched) >= 0, "the walker reached the stone")
	_check(int(log.goal) >= 0 and int(log.touched) < int(log.goal), "it reached the stone before the Heartwood (stone %d, goal %d)" % [log.touched, log.goal])
	_check(int(log.statuses) == 0 and not bool(log.forever), "at the stone it lost every status, never-fade ones too")
	_check(int(log.restless) == 0, "turning back at the stone is never Restless")

func _test_flyer() -> void:
	var data: EnemyData = load("res://resource/enemy/dandelion_seed.tres")
	var flyer = spawner.spawn_enemy(data, 1.0)
	_check(flyer != null, "a flyer spawns")
	if flyer == null:
		return
	_check(flyer._waymark_index < 0, "a flyer's straight line has no stone on it")
	for i in 30:
		await process_frame
	_check(is_instance_valid(flyer) and not flyer.passed_waymark, "a flyer flies straight past")
	if is_instance_valid(flyer):
		flyer.queue_free()

func _test_laps() -> void:
	var enemy = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"), 1.0)
	if enemy == null:
		return
	enemy.passed_waymark = true
	enemy._restart_route()
	_check(not enemy.passed_waymark and enemy._waymark_index >= 0, "a new lap walks both legs again")
	enemy.pull_back_to(0)
	enemy.passed_waymark = true
	enemy.pull_back_to(0)
	_check(enemy.passed_waymark, "a pull back never clears it")
	enemy.queue_free()

func _test_maze(cell: Vector2) -> void:
	var dup := PackedVector2Array([Vector2(1.25, 1.25), Vector2(1.75, 1.25), Vector2(2.25, 1.25), Vector2(1.75, 1.25), Vector2(1.25, 1.25)])
	_check(map.route_length(dup) == 3 and map.unique_route_length(dup) == 2, "unique counting: out and back counts once")
	var economy = director.maze_economy
	_check(economy.added_cells(map) == 0, "the stone itself earns no maze Dew (%d)" % economy.added_cells(map))
	# Real Thornwalls on three sides of the stone: a dead-end stub, walked out and back.
	placer.select_tower(load("res://resource/tower/thornwall.tres"))
	var planted := 0
	for side in _sides(cell).slice(0, 3):
		if placer._try_build(side):
			planted += 1
	_check(planted == 3, "three Thornwalls round the stone are legal (the fourth side stays open)")
	_check(not placer._try_build(_sides(cell)[3]), "the fourth would cut a leg: refused")
	var now: PackedVector2Array = map.get_path_from(map.startPath)
	var base: PackedVector2Array = map.waymark_baseline_route()
	var added: int = economy.added_cells(map)
	print("  maze: route %d cells (%d unique), baseline %d (%d unique), added %d" % [map.route_length(now), map.unique_route_length(now),
		map.route_length(base), map.unique_route_length(base), added])
	_check(added == maxi(0, map.unique_route_length(now) - map.unique_route_length(base)), "added cells are unique(now) - unique(baseline)")
	# The raw growth over the baseline depends on the map (the baseline may already turn at the stone), so check the stub
	# itself: walked out and back, its cells are on the route twice but counted once.
	_check(map.route_length(now) > map.unique_route_length(now), "the stub walked out and back is not counted twice (%d raw vs %d unique)" % [map.route_length(now), map.unique_route_length(now)])
	var moved := Vector2(-1, -1)
	economy.sample(1, 1, map)
	var sampled: int = int(economy.to_save().blocks["1"].samples["1"])
	for x in map.MAP_GRID.size.x:
		for y in map.MAP_GRID.size.y:
			if moved.x < 0 and Vector2(x, y) != cell and map.can_place_waymark(Vector2(x, y)):
				moved = Vector2(x, y)
	if moved.x >= 0:
		map.waymark_stone.place_at(moved)
		_check(int(economy.to_save().blocks["1"].samples["1"]) <= sampled, "moving the stone never raises an unpaid sample")
		map.waymark_stone.place_at(cell)

func _test_save(cell: Vector2) -> void:
	_check(map.waymark_cell == cell, "the stone is back on its cell before saving")
	_check(saver.save_now(), "the run saves at a rest with the stone placed")
	var data := RunSaver.read_saved_run()
	var saved: Array = data.get("waymark", [])
	_check(saved.size() == 2 and Vector2(saved[0], saved[1]) == cell, "the stone's cell is in the run save")
	main.queue_free()
	await process_frame
	RunSaver.resume_next = true
	main = await _new_run()
	_bind()
	await process_frame
	await process_frame
	_check(map.waymark_cell == cell, "Continue puts the stone back on its cell")
	_check(dreams.has_rule(&"waymark") and not dreams.waymark_needed() and director.pending_choice() == &"",
		"a Continue doesn't ask to place it again")
	_check(map.waymark_split(map.get_path_from(map.startPath)) >= 0, "the restored route runs out to the stone")
