extends SceneTree

# Headless test for the acts 3–4 nightmares and bosses (acts_3_4.md, enemy_design.md): Lurkers hidden
# until revealed, Will-o'-Wisps, the Gravecrawler burrowing, the Sleepwalker wandering into dead ends,
# the Drowned One, Barrow Wight, Watcher, Ash Crawler, Shellbound, Whisper Swarm, Dream Thief, Weeper,
# the Moth Queen (weaving flight, brood, Eclipse) and the Hollow Oak (saplings, Grief, rising again).
#   godot --headless --path . --script res://tests/test_acts_3_4.gd --fixed-fps 60

var failures := 0
var spawner: Node
var map_generator: Node
var tower_container: Node
var placer: TowerPlacer
var route: PackedVector2Array

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 777
	root.add_child(main)
	await process_frame
	spawner = main.get_node("%EnemyContainer")
	map_generator = main.get_node("%MapGenerator")
	tower_container = main.get_node("%TowerContainer")
	placer = main.get_node("%TowerPlacer")
	var run_state = main.get_node("%RunState")
	for tower in tower_container.get_children():
		tower.free()
	route = map_generator.get_path_from(map_generator.startPath)

	# --- Lurker: hidden until a Warden is close, a Marking Warden has it in range, or a Wisp is near ---
	var lurker := _still("dusk_moth", route[10])
	lurker._update_presence(0.2)
	_check(lurker.is_hidden() and not lurker.is_in_group("enemies"), "a Lurker is hidden and untargetable")
	var near := _plant("sprout", _free_neighbour(route[10]))
	lurker._update_presence(0.2)
	_check(not lurker.is_hidden() and lurker.is_in_group("enemies"), "a Warden right beside it sees it")
	near.free()
	lurker._update_presence(0.2)
	_check(lurker.is_hidden(), "hidden again once the Warden is gone")
	var lantern := _plant_at_distance("lanternmoth", route[10], 3.0)
	_check(lantern != null, "found a spot 3 cells from the Lurker for a Lanternmoth")
	if lantern:
		lurker._update_presence(0.2)
		_check(not lurker.is_hidden(), "a Lanternmoth (Marks) reveals it from range")
		lantern.free()
	lurker._update_presence(0.2)
	var wisp := _still("will_o_wisp", route[11])
	lurker._update_presence(0.2)
	_check(not lurker.is_hidden(), "a Will-o'-Wisp one cell away reveals it")
	_clear_enemies()

	# --- Drowned One: always Damp, never slowed, can't be Held or made Drowsy ---
	var drowned := _still("drowned_one", route[5])
	drowned.apply_status(EnemyStatuses.DROWSY, 3)
	drowned.apply_status(EnemyStatuses.HELD)
	_check(drowned.statuses.has(EnemyStatuses.DAMP), "the Drowned One is always Damp")
	drowned.statuses.remove(EnemyStatuses.DAMP)
	drowned._update_presence(0.0)
	_check(drowned.statuses.has(EnemyStatuses.DAMP), "and gets soaked again at once")
	_check(not drowned.statuses.has(EnemyStatuses.DROWSY) and not drowned.statuses.is_held(), "no Drowsy, no Held")
	_check(is_equal_approx(drowned.get_move_speed(), drowned.speed), "Damp doesn't slow it")

	# --- Barrow Wight: can't be Held, Drowsy lasts half as long ---
	var wight := _still("barrow_wight", route[6])
	wight.apply_status(EnemyStatuses.HELD)
	wight.apply_status(EnemyStatuses.DROWSY)
	_check(not wight.statuses.is_held(), "the Barrow Wight can't be Held")
	_check(is_equal_approx(wight.statuses.time_left(EnemyStatuses.DROWSY), 1.5), "Drowsy lasts half as long on it")

	# --- Watcher: immune to Drowsy, wakes Drowsy nightmares within 1.5 cells ---
	var sleeper := _still("leaf_bug", route[12])
	sleeper.apply_status(EnemyStatuses.DROWSY, 2)
	var far_sleeper := _still("leaf_bug", route[18])
	far_sleeper.apply_status(EnemyStatuses.DROWSY, 2)
	var watcher := _still("watcher", route[13])
	watcher.apply_status(EnemyStatuses.DROWSY)
	watcher._update_presence(0.2)
	_check(not watcher.statuses.has(EnemyStatuses.DROWSY), "the Watcher never sleeps")
	_check(not sleeper.statuses.has(EnemyStatuses.DROWSY), "it wakes a Drowsy Shade beside it")
	_check(far_sleeper.statuses.has(EnemyStatuses.DROWSY), "but not one far away")
	_clear_enemies()

	# --- Ash Crawler: its trail clears Spored from nightmares on it ---
	var crawler := _still("ash_crawler", route[8])
	crawler._on_cell_reached()
	var spored := _still("leaf_bug", route[8])
	spored.apply_status(EnemyStatuses.SPORED, 2, 5.0, 3.0)
	crawler._update_presence(0.2)
	_check(not spored.statuses.has(EnemyStatuses.SPORED), "the Ash Crawler's ash clears Spored")
	crawler._update_presence(3.5)
	_check(crawler._ash_cells.is_empty(), "the ash burns out after 3 s")
	_clear_enemies()

	# --- Shellbound's dread shell, the Whisper Swarm's shape ---
	var shell := _still("shellbound", route[5])
	_check(is_equal_approx(shell.coat_max, 100.0), "the Shellbound's shell soaks 100")
	var before: int = shell.health
	shell.take_damage(5.0)
	_check(before - shell.health == 1, "a small hit mostly bounces off the shell (%d)" % (before - shell.health))
	shell.max_health = 100000
	shell.health = 100000
	for i in 20:  # −6 per hit until it has soaked 100
		shell.take_damage(50.0)
	_check(shell.coat == 0.0 and shell.sprite.sprite_frames == shell.enemy_data.cracked_frames, "a broken shell shows the cracked art")
	var swarm := _still("whisper_swarm", route[6])
	before = swarm.health
	swarm.take_damage(100.0)
	_check(before - swarm.health == 50, "single-target hits do half to the Whisper Swarm")
	before = swarm.health
	swarm.take_damage(100.0, "", true)
	_check(before - swarm.health == 100, "area hits do full damage")

	# --- Dream Thief: steals 5 Dew on reaching the Heartwood; double Dew when dispelled ---
	var thief := _still("dream_thief", route[7])
	_check(thief.get_dew_reward() == 6, "the Dream Thief drops double Dew (6)")
	run_state.dew = 20
	run_state.invulnerable = true
	spawner._on_enemy_reached_goal(thief)
	_check(run_state.dew == 15, "it steals 5 Dew on the way in (%d left)" % run_state.dew)
	run_state.dew = 3
	spawner._on_enemy_reached_goal(thief)
	_check(run_state.dew == 0, "never more than there is")

	# --- Weeper: mends nightmares within 1.5 cells for 2% of their max health a second ---
	var hurt := _still("leaf_bug", route[9])
	hurt.health = 50
	var weeper := _still("weeper", route[9])
	weeper.health = 10
	weeper._update_presence(1.0)
	_check(hurt.health == 52, "the Weeper mends the Shade beside it (%d)" % hurt.health)
	_check(weeper.health == 10, "but not itself")
	_clear_enemies()

	# --- Gravecrawler burrows under a wall when that's shorter ---
	var burrow := _burrow_setup()
	_check(not burrow.is_empty(), "found a wall to burrow under")
	if not burrow.is_empty():
		var grave := _still("gravecrawler", burrow.here)
		var long_way := PackedVector2Array([burrow.here])
		for i in 60:
			long_way.append(burrow.here)  # A made-up long way round
		grave.set_path(long_way)
		grave._path_index = 1
		grave.set_process(true)
		grave._try_burrow()
		_check(grave._leaping, "the Gravecrawler sinks under the wall")
		await _wait(1.8)
		_check(grave.get_current_cell() == burrow.beyond and grave._burrows == 1,
			"and surfaces on the other side (%s)" % grave.get_current_cell())
		grave._leaping = false
		grave._path_index = 1
		var path_before: PackedVector2Array = grave._path.duplicate()
		grave._try_burrow()
		_check(not grave._leaping and grave._path == path_before, "only once per trip")
		_clear_enemies()

	# --- Sleepwalker wanders into a dead end and back ---
	var pocket := _dead_end_setup()
	_check(not pocket.is_empty(), "built a one-cell dead end beside the route")
	if not pocket.is_empty():
		var data: EnemyData = load("res://resource/enemy/wandering_hare.tres").duplicate()
		data.wander_chance = 1.0
		spawner.spawn_enemy(data)
		var walker: Node2D = spawner.get_child(spawner.get_child_count() - 1)
		walker.set_process(false)
		var from := route.slice(pocket.index)
		walker.position = walker.grid.calculate_map_position(from[0])
		walker.set_path(from)
		walker._path_index = 1
		walker._try_wander()
		_check(walker._path.size() >= 2 and walker._path[0] == pocket.cell and walker._path[1] == from[0],
			"the Sleepwalker steps into the dead end and back")
		_check(walker._path[walker._path.size() - 1] == map_generator.endPath, "then goes on to the Heartwood")
		_clear_enemies()

	# --- The Moth Queen: weaving flight, brood, Eclipse ---
	spawner.drift_health_scale = 3.0
	var queen: Node2D = spawner.spawn_enemy(load("res://resource/enemy/moth_queen.tres"))
	queen.set_process(false)
	_check(queen.is_flying() and queen._path.size() > 2 and queen._path[queen._path.size() - 1] == map_generator.endPath,
		"the Moth Queen weaves over the maze to the Heartwood")
	_check(spawner.drift_health_scale == 3.0, "bosses don't change the drift's health scale")
	var brood := []
	var on_brood := func(parent: Node2D, child: Node2D) -> void:
		if parent == queen:
			brood.append(child)
	spawner.enemy_split.connect(on_brood)
	queen._update_presence(4.1)
	_check(brood.size() == 1 and brood[0].enemy_data.resource_path.get_file() == "dusk_moth.tres",
		"she drops a Lurker every 4 s")
	if brood.size() == 1:
		_check(brood[0].max_health == 210, "grown like the drift's other nightmares (%d)" % brood[0].max_health)
		_check(brood[0]._path[brood[0]._path.size() - 1] == map_generator.endPath, "it walks the maze from there")
	var bystander := _still("leaf_bug", route[25])
	queen.take_damage(queen.max_health / 2 + 1)
	_check(spawner.eclipse_left > 4.9, "half health: the Eclipse")
	_check(queen.sprite.animation == &"eclipse", "her wings close (eclipse pose)")
	bystander._update_presence(0.2)
	queen._update_presence(0.2)
	_check(bystander.is_hidden() and not queen.is_hidden(), "every nightmare but the Queen is hidden")
	spawner.eclipse_left = 0.0
	bystander._update_presence(0.2)
	_check(not bystander.is_hidden(), "and seen again when it ends")
	spawner.enemy_split.disconnect(on_brood)
	_clear_enemies()

	# --- The Hollow Oak: saplings, Grief, Blight Level 10 rising, saplings wither ---
	var oak: Node2D = spawner.spawn_enemy(load("res://resource/enemy/hollow_oak.tres"))
	oak.set_process(false)
	var sapling: ObstacleData = oak.enemy_data.sapling
	oak._update_presence(8.1)
	var planted: Array = map_generator.obstacles.keys().filter(func(c: Vector2) -> bool:
		return map_generator.obstacles[c] == sapling)
	_check(planted.size() == 1, "the Hollow Oak plants a thorn-sapling")
	var sapling_sprites: Array = spawner._sapling_sprites.values()
	_check(sapling_sprites.size() == 1 and sapling_sprites[0].animation == &"grow", "the sapling grows in")
	_check(not map_generator.get_path_from(map_generator.startPath).is_empty(), "the path stays open")
	var grief := []
	spawner.enemy_split.connect(func(parent: Node2D, child: Node2D) -> void:
		if parent == oak:
			grief.append(child))
	oak.take_damage(oak.max_health * 0.34 + 1)
	_check(grief.size() == 6 and oak.hold_time > 0.0, "two-thirds health: it stops, and 6 Mourners rise")
	_check(oak.sprite.animation == &"grief", "and wails (grief animation)")
	oak.take_damage(oak.max_health * 0.34)
	_check(grief.size() == 12, "and again at one third")
	MetaRun.blight_level = 10
	oak.take_damage(1e9)
	_check(not oak.is_cleansed and oak.health == oak.max_health / 2, "Blight Level 10: it rises again at half health")
	_check(is_equal_approx(oak._sapling_speed, 2.0), "planting twice as fast")
	oak.take_damage(1e9)
	MetaRun.blight_level = 0
	_check(oak.is_cleansed, "the second time it's dispelled")
	_check(planted.all(func(c: Vector2) -> bool: return map_generator.get_obstacle(c) == null), "its saplings wither")
	_check(sapling_sprites.size() == 1 and sapling_sprites[0].animation == &"wither", "crumbling to ash (wither animation)")

	print("acts 3-4 test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# A nightmare of `kind` standing still on `cell`.
func _still(kind: String, cell: Vector2) -> Node2D:
	var enemy: Node2D = spawner.spawn_enemy(load("res://resource/enemy/%s.tres" % kind))
	enemy.set_process(false)
	enemy.position = enemy.grid.calculate_map_position(cell)
	return enemy

func _clear_enemies() -> void:
	for enemy in spawner.get_children():
		enemy.free()

# A Warden of `kind` on `cell`, added straight to the map (it doesn't block the path).
func _plant(kind: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % kind)
	tower.cell = cell
	tower.position = map_generator.MAP_GRID.calculate_map_position(cell)
	tower_container.add_child(tower)
	return tower

# A Warden of `kind` about `cells` cells from `target`, still with `target` in range.
func _plant_at_distance(kind: String, target: Vector2, cells: float) -> Tower:
	for x in range(-4, 5):
		for y in range(-4, 5):
			var cell := target + Vector2(x, y)
			if absf(Vector2(x, y).length() - cells) < 0.5 and map_generator.is_buildable(cell) and not route.has(cell):
				var tower := _plant(kind, cell)
				if tower.global_position.distance_to(map_generator.MAP_GRID.calculate_map_position(target)) <= tower.get_range_pixels():
					return tower
				tower.free()
	return null

func _free_neighbour(cell: Vector2) -> Vector2:
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		if not route.has(cell + offset) and map_generator.is_buildable(cell + offset):
			return cell + offset
	return cell

# A Thornwall beside a route cell, with walkable ground past it that leads to the Heartwood:
# {here, beyond}, or {} if the map has no such spot.
func _burrow_setup() -> Dictionary:
	for i in range(5, route.size() - 5):
		var here := route[i]
		for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var wall: Vector2 = here + direction
			var beyond: Vector2 = here + direction * 2
			if route.has(wall) or not map_generator.can_block(wall) or not map_generator.is_buildable(beyond):
				continue
			map_generator.block_cell(wall)
			if map_generator.get_path_from(beyond).is_empty():
				map_generator.unblock_cell(wall)
				continue
			_plant("thornwall", wall)
			route = map_generator.get_path_from(map_generator.startPath)
			return {"here": here, "beyond": beyond}
	return {}

# Walls in a single open cell beside the route so it's a dead end: {index (route), cell}, or {}.
func _dead_end_setup() -> Dictionary:
	for i in range(5, route.size() - 5):
		for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var side: Vector2 = route[i] + direction
			if route.has(side) or not map_generator.is_buildable(side):
				continue
			var walls: Array[Vector2] = []
			var ok := true
			for step in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				var around: Vector2 = side + step
				if around == route[i] or route.has(around) or not map_generator.is_buildable(around):
					continue
				if not map_generator.can_block(around):
					ok = false
					break
				map_generator.block_cell(around)
				walls.append(around)
			if ok and map_generator.get_path_from(map_generator.startPath) == route:
				return {"index": i, "cell": side}
			for wall in walls:
				map_generator.unblock_cell(wall)
	return {}

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout
