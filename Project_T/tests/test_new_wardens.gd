extends SceneTree

# Headless test for the Wardens from tower_design.md's hidden branches, the Nestling and Whirligig
# families, Honeysuckle and the Memory Wardens: data, evolution links, Dream cards and each mechanic.
# Run from the project folder:
#   godot --headless --path . --script res://tests/test_new_wardens.gd --fixed-fps 60

const NEW_WARDENS := ["fairy_ring", "elf_circle", "standing_stone", "moonstone", "frostfern", "hoarfrost",
	"sunpetal", "midsummer", "rootlight", "starcave", "graftling", "grafted_elder", "nestling",
	"wrens_nest", "starling_murmuration", "magpie_perch", "magpies_hoard", "whirligig", "gust", "zephyr",
	"pinwheel", "windmill", "honeysuckle", "white_stag", "pond_keeper", "moon_moth"]
const CELL := 64.0

var failures := 0
var main: Node
var map_generator
var spawner
var tower_container: Node
var placer: TowerPlacer
var shade: EnemyData
var route: PackedVector2Array

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	map_generator = main.get_node("%MapGenerator")
	spawner = main.get_node("%EnemyContainer")
	tower_container = main.get_node("%TowerContainer")
	placer = main.get_node("%TowerPlacer")
	var dream_state: DreamState = main.get_node("%DreamState")
	dream_state.unlock_everything = true
	shade = load("res://resource/enemy/leaf_bug.tres")
	route = map_generator.get_path_from(map_generator.startPath)
	await _clear_enemies()

	_test_data(dream_state)
	await _test_crits()
	await _test_snipers()
	await _test_frost()
	await _test_traps()
	await _test_beam()
	await _test_copy()
	await _test_birds()
	await _test_wind()
	await _test_pull_and_light()
	await _test_memory()

	print("new wardens test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)


# --- Data -----------------------------------------------------------------------------------------------

func _test_data(dream_state: DreamState) -> void:
	var reachable := {}
	var stack: Array = placer.towers.duplicate()
	while not stack.is_empty():
		var data: TowerData = stack.pop_back()
		if reachable.has(data.get_id()):
			continue
		reachable[data.get_id()] = true
		stack.append_array(data.evolves_to)
	for id in NEW_WARDENS:
		var data := load("res://resource/tower/%s.tres" % id) as TowerData
		_check(data != null, "%s loads" % id)
		if data == null:
			continue
		_check(data.texture != null and data.get_frame_rect(0).size == Vector2(64, 64), "%s has a 64x64 idle sheet" % id)
		_check(data.attack_kind == TowerData.AttackKind.AURA or data.attack_texture != null, "%s has an attack sheet" % id)
		_check(reachable.has(id), "%s can be reached (planted or grown into)" % id)
		if not data.is_unique:
			var card := load("res://resource/dream/dream_%s.tres" % id) as UpgradeData
			_check(card != null and card.unlocks == data, "%s has a Dream card" % id)
	var pool_ids := dream_state.pool.map(func(c: UpgradeData) -> String: return c.id)
	_check("dream_honeysuckle" in pool_ids, "Honeysuckle's card is in the Dream pool")


# --- Crits and snipers ----------------------------------------------------------------------------------

func _test_crits() -> void:
	var data: TowerData = load("res://resource/tower/nestling.tres").duplicate()
	data.crit_chance = 1.0
	data.bonus_vs_multiplier = 1.0
	var tower := _plant(data, Vector2(3, 3))
	var enemy := _spawn_at(tower.global_position + Vector2(CELL, 0))
	var crits := [0]
	tower.crit_landed.connect(func(_t: Tower, _e: Node2D) -> void: crits[0] += 1)
	await process_frame
	tower.hit(enemy)
	_check(enemy.health == enemy.max_health - roundi(data.damage * data.crit_multiplier), "a crit deals damage × multiplier")
	_check(enemy._crit_flash > 0.0 and crits[0] == 1, "a crit flashes and emits crit_landed")
	data.crit_chance = 0.0
	var before: int = enemy.health
	tower.hit(enemy)
	_check(enemy.health == before - data.damage, "without a crit, plain damage")
	await _clean()

func _test_snipers() -> void:
	var stone: TowerData = load("res://resource/tower/standing_stone.tres").duplicate()
	stone.crit_chance = 0.0
	var tower := _plant(stone, Vector2(3, 3))
	var close := _spawn_at(tower.global_position + Vector2(CELL, 0))
	var far := _spawn_at(tower.global_position + Vector2(5 * CELL, 0))
	far.max_health = 1000
	far.health = 1000
	await process_frame
	var in_range := tower.get_enemies_in_range()
	_check(not in_range.has(close) and in_range.has(far), "Standing Stone can't hit nightmares within 2 cells")
	tower.hit(far)
	_check(far.health == far.max_health - roundi(stone.damage * 1.2), "5 cells away: +20% damage (distance bonus)")
	var strong := _spawn_at(tower.global_position + Vector2(0, 6 * CELL))
	strong.max_health = 5000
	strong.health = 5000
	tower.target_mode = TowerData.TargetMode.STRONGEST
	_check(tower.find_target() == strong, "target priority: Strongest")

	var moon: TowerData = load("res://resource/tower/moonstone.tres").duplicate()
	moon.crit_chance = 0.0
	var moonstone := _plant(moon, Vector2(3, 12))
	var prey := _spawn_at(moonstone.global_position + Vector2(3 * CELL, 0))
	await process_frame
	_check(moonstone.hit(prey) and not moonstone.hit(prey), "Moonstone's first hit on a nightmare always crits, later ones don't")
	await _clean()


# --- Frost ----------------------------------------------------------------------------------------------

func _test_frost() -> void:
	var frost: TowerData = load("res://resource/tower/frostfern.tres").duplicate()
	frost.crit_chance = 0.0
	var tower := _plant(frost, Vector2(3, 3))
	var dry := _spawn_at(tower.global_position + Vector2(CELL, 0))
	var damp := _spawn_at(tower.global_position + Vector2(0, CELL))
	damp.apply_status(EnemyStatuses.DAMP)
	await process_frame
	tower.hit(dry)
	tower.hit(damp)
	_check(not dry.statuses.is_held(), "Frostfern doesn't freeze dry nightmares")
	_check(damp.statuses.is_held(), "Frostfern freezes Damp nightmares (Held)")
	damp.set_process(true)
	var at: Vector2 = damp.position
	await _wait(0.3)
	_check(damp.position == at, "a Held nightmare doesn't move")
	await _wait(0.7)
	_check(not damp.statuses.is_held(), "the freeze wears off")
	tower.hit(damp)
	_check(not damp.statuses.is_held(), "the same nightmare can't be frozen again right away")
	await _clean()


# --- Traps ----------------------------------------------------------------------------------------------

func _test_traps() -> void:
	var ring_data: TowerData = load("res://resource/tower/fairy_ring.tres").duplicate()
	ring_data.crit_chance = 0.0
	var spot := _route_cell(12)
	var tower := _plant(ring_data, _free_cell_near(spot))
	await process_frame
	tower._plant_ring()
	_check(tower._rings.size() == 1, "Fairy Ring plants a ring")
	var ring: FairyRing = tower._rings[0]
	_check(route.has(ring.cell) and tower._is_cell_in_range(ring.cell), "the ring is on a path tile in range")
	var walker := _spawn_at(map_generator.MAP_GRID.calculate_map_position(ring.cell))
	await process_frame
	await process_frame
	_check(walker.health == walker.max_health - ring_data.damage, "stepping on the ring sets off a burst")
	_check(walker.statuses.stacks(EnemyStatuses.SPORED) == 2, "the burst applies Spored ×2")
	await _wait(0.5)
	_check(not is_instance_valid(ring), "a ring is used up once it goes off")
	await _clean()


# --- Beam -----------------------------------------------------------------------------------------------

func _test_beam() -> void:
	var sun: TowerData = load("res://resource/tower/sunpetal.tres").duplicate()
	sun.crit_chance = 0.0
	var tower := _plant(sun, Vector2(3, 3))
	var target := _spawn_at(tower.global_position + Vector2(2 * CELL, 0))
	target.max_health = 100000
	target.health = 100000
	await _wait(2.0)
	var dealt: int = target.max_health - target.health
	_check(tower._beam_target == target, "Sunpetal holds its beam on the target")
	_check(tower._beam_ramp > 1.4, "the beam ramps up over time (×%.2f after 2 s)" % tower._beam_ramp)
	_check(dealt > sun.damage * 2.0, "the ramped beam deals more than its base damage per second (%d)" % dealt)
	target.apply_status(EnemyStatuses.DROWSY)
	var ramp: float = tower._beam_ramp
	await _wait(1.0)
	_check(tower._beam_ramp - ramp > sun.beam_ramp_per_second * 1.5, "the beam ramps twice as fast on Drowsy")
	await _clean()


# --- Copy -----------------------------------------------------------------------------------------------

func _test_copy() -> void:
	var graft := _plant(load("res://resource/tower/graftling.tres"), Vector2(3, 3))
	await process_frame
	graft._refresh_neighbours()
	_check(graft.get_copied() == null and graft.find_target() == null, "a lone Graftling has nothing to copy")
	var pebbling_data: TowerData = load("res://resource/tower/pebbling.tres")
	var neighbour := _plant(pebbling_data, Vector2(4, 3))
	_plant(load("res://resource/tower/sprout.tres"), Vector2(2, 3))
	_plant(load("res://resource/tower/white_stag.tres"), Vector2(3, 4))
	await process_frame
	graft._refresh_neighbours()
	_check(graft.get_copied() == pebbling_data, "Graftling copies its strongest neighbour (not the Memory Warden)")
	_check(is_equal_approx(graft.get_damage(), neighbour.get_damage() * 0.6), "at 60% damage")
	_check(graft.get_range_cells() == neighbour.get_range_cells(), "with the copied range")
	await _clean()


# --- Birds ----------------------------------------------------------------------------------------------

func _test_birds() -> void:
	var nest: TowerData = load("res://resource/tower/nestling.tres").duplicate()
	nest.crit_chance = 0.0
	var tower := _plant(nest, Vector2(3, 3))
	var phantom_data: EnemyData = load("res://resource/enemy/dandelion_seed.tres")
	var phantom := _spawn_at(tower.global_position + Vector2(2 * CELL, 0), phantom_data)
	tower.set_process(false)  # Only the test's own swoop
	await process_frame
	tower.fire_at(phantom)
	var bird: Projectile = null
	for child in tower.get_children():
		if child is Projectile:
			bird = child
	await _wait(0.5)
	_check(phantom.max_health - phantom.health == int(nest.damage * 1.25),
		"Nestling deals ×1.25 to Phantoms (%d)" % (phantom.max_health - phantom.health))
	_check(is_instance_valid(bird) and bird.is_returning(), "the bird flies back after its swoop")
	await _wait(1.0)
	_check(not is_instance_valid(bird), "and vanishes once home")

	var wrens := _plant(load("res://resource/tower/wrens_nest.tres"), Vector2(3, 10))
	var slow := _spawn_at(wrens.global_position + Vector2(CELL, 0))
	var fast := _spawn_at(wrens.global_position + Vector2(-CELL, 0))
	fast.speed = slow.speed * 3.0
	_check(wrens.find_target() == fast, "Wren's Nest hunts the fastest nightmare")

	var magpie: TowerData = load("res://resource/tower/magpie_perch.tres").duplicate()
	magpie.crit_chance = 0.0
	var perch := _plant(magpie, Vector2(10, 3))
	var mark := _spawn_at(perch.global_position + Vector2(CELL, 0))
	var reward: int = mark.get_dew_reward()
	perch.hit(mark)
	_check(mark.get_dew_reward() == reward + 1, "Magpie Perch: hit nightmares drop +1 Dew")

	var hoard: TowerData = load("res://resource/tower/magpies_hoard.tres").duplicate()
	hoard.crit_chance = 1.0
	hoard.crit_dew_per_drift = 2
	var hoarder := _plant(hoard, Vector2(10, 10))
	var mark2 := _spawn_at(hoarder.global_position + Vector2(CELL, 0))
	mark2.max_health = 100000
	mark2.health = 100000
	var run_state = main.get_node("%RunState")
	var dew: int = run_state.dew
	for i in 4:
		hoarder.hit(mark2)
	_check(run_state.dew == dew + 2, "Magpie's Hoard: +1 Dew per crit, capped per drift")

	# Starling Murmuration sweeps a stretch of path. The birds above are still attacking whatever
	# comes into range, so clear them first (on some maps the swept tile is within their reach).
	await _clean()
	var starling: TowerData = load("res://resource/tower/starling_murmuration.tres").duplicate()
	starling.crit_chance = 0.0
	var spot := _route_cell(12)
	var flock := _plant(starling, _free_cell_near(spot))
	var on_path := _spawn_at(map_generator.MAP_GRID.calculate_map_position(spot))
	var off_path := _spawn_at(flock.global_position + Vector2(0, 0.4 * CELL))
	await process_frame
	flock._sweep()
	_check(on_path.health == on_path.max_health - starling.damage, "the flock hits nightmares on the swept stretch")
	_check(off_path.health == off_path.max_health, "and nothing off the path")
	await _clean()


# --- Wind -----------------------------------------------------------------------------------------------

func _test_wind() -> void:
	# Whirligig: nudges back along the route, at most once per 3 s.
	var whirl: TowerData = load("res://resource/tower/whirligig.tres").duplicate()
	whirl.crit_chance = 0.0
	var walker := _spawn_walker()
	await _wait(3.0)
	walker.set_process(false)
	var tower := _plant(whirl, walker.get_current_cell() + Vector2(0, 0))
	var before: float = walker.get_remaining_distance()
	tower._release()
	var pushed: float = walker.get_remaining_distance() - before
	_check(absf(pushed - 0.25 * CELL) < 1.0, "Whirligig pushes a nightmare back 0.25 tiles (%.1f px)" % pushed)
	before = walker.get_remaining_distance()
	tower._release()
	_check(walker.get_remaining_distance() == before, "not again within 3 s")
	await _clean()

	# Gust: copies the most-afflicted nightmare's statuses (half stacks) onto 2 nearby ones.
	var gust: TowerData = load("res://resource/tower/gust.tres").duplicate()
	gust.crit_chance = 0.0
	var gust_tower := _plant(gust, Vector2(5, 5))
	var source := _spawn_at(gust_tower.global_position + Vector2(CELL, 0))
	source.apply_status(EnemyStatuses.SPORED, 4, 5.0, 1.0)
	source.apply_status(EnemyStatuses.DAMP)
	var others: Array = []
	for offset in [Vector2(0.5, 0.5), Vector2(0.5, -0.5), Vector2(1.0, 0.8)]:
		others.append(_spawn_at(source.global_position + offset * CELL))
	await process_frame
	gust_tower._release()
	var spread := others.filter(func(e: Node2D) -> bool: return e.statuses.has(EnemyStatuses.SPORED))
	_check(spread.size() == 2, "Gust spreads to 2 nightmares (%d)" % spread.size())
	_check(spread.all(func(e: Node2D) -> bool:
		return e.statuses.stacks(EnemyStatuses.SPORED) == 2 and e.statuses.has(EnemyStatuses.DAMP)),
		"with half the stacks, and every status")
	await _clean()

	# Pinwheel: hits the 8 tiles around it.
	var pin: TowerData = load("res://resource/tower/pinwheel.tres").duplicate()
	pin.crit_chance = 0.0
	pin.spin_bonus = 0.0
	var spinner := _plant(pin, Vector2(5, 5))
	var beside := _spawn_at(spinner.global_position + Vector2(CELL, CELL))
	var two_away := _spawn_at(spinner.global_position + Vector2(2 * CELL, 0))
	await process_frame
	spinner._release()
	_check(beside.health == beside.max_health - pin.damage, "Pinwheel's blades hit the tiles around it")
	_check(two_away.health == two_away.max_health, "and nothing further away")
	await _clean()


# --- Pull, light, Honeysuckle ------------------------------------------------------------------------------

func _test_pull_and_light() -> void:
	var keeper_data: TowerData = load("res://resource/tower/pond_keeper.tres").duplicate()
	keeper_data.crit_chance = 0.0
	var walker := _spawn_walker()
	await _wait(4.0)
	walker.set_process(false)
	var index: int = walker.get_route_index()
	var behind: PackedVector2Array = walker.get_cells_behind()
	var keeper := _plant(keeper_data, _free_cell_near(behind[1]))
	await process_frame
	keeper._grab(walker)
	_check(walker.get_route_index() < index, "Pond Keeper drags the nightmare back (%d -> %d)" % [index, walker.get_route_index()])
	_check(walker.statuses.has(EnemyStatuses.DAMP), "and makes it Damp")
	await _clean()

	var light: TowerData = load("res://resource/tower/rootlight.tres").duplicate()
	light.crit_chance = 0.0
	var spot := _route_cell(10)
	var root_tower := _plant(light, _free_cell_near(spot))
	var lit := _spawn_at(map_generator.MAP_GRID.calculate_map_position(spot))
	await process_frame
	root_tower._release()
	_check(not root_tower._lit_cells.is_empty(), "Rootlight lights path tiles in range")
	_check(lit.statuses.has(EnemyStatuses.MARKED), "nightmares in the light are Marked")
	await _clean()

	var honey := _plant(load("res://resource/tower/honeysuckle.tres"), Vector2(5, 5))
	var sniff := _spawn_at(honey.global_position + Vector2(CELL, 0))
	await process_frame
	honey._release()
	_check(sniff.statuses.stacks(EnemyStatuses.DROWSY) == 1 and sniff.health == sniff.max_health,
		"Honeysuckle makes nightmares Drowsy without hurting them")
	await _clean()


# --- Memory Wardens -------------------------------------------------------------------------------------

func _test_memory() -> void:
	var stag_data: TowerData = load("res://resource/tower/white_stag.tres")
	var stag := _plant(stag_data, Vector2(5, 5))
	var inside := _spawn_at(stag.global_position + Vector2(3 * CELL, 0))
	var outside := _spawn_at(stag.global_position + Vector2(8 * CELL, 0))
	var sprout := _plant(load("res://resource/tower/sprout.tres"), Vector2(6, 5))
	await _wait(0.3)
	_check(inside.statuses.is_in_stag_aura() and not outside.statuses.is_in_stag_aura(), "the White Stag's aura covers radius 4")
	_check(is_equal_approx(inside.statuses.get_speed_multiplier(), 0.85), "nightmares in it are 15% slower")
	_check(is_equal_approx(inside.statuses.get_damage_taken_multiplier(), 1.15), "and take 15% more damage")
	sprout._refresh_neighbours()
	_check(is_equal_approx(sprout.get_crit_chance(), 0.05), "Wardens in it gain 5% crit chance")

	var moth := _plant(load("res://resource/tower/moon_moth.tres"), Vector2(12, 5))
	var near_moth := _plant(load("res://resource/tower/sprout.tres"), Vector2(14, 5))
	await process_frame
	near_moth._refresh_neighbours()
	_check(is_equal_approx(near_moth.get_range_cells(), 2.5 + 1.0), "the Moon Moth gives Wardens within 3 cells +1 range")
	_check(moth.tower_data.applies_status == EnemyStatuses.MARKED, "its shots Mark")

	placer.tower_data = stag_data
	_check(placer.is_unique_placed(stag_data), "a Memory Warden already on the map counts as placed")
	var count := tower_container.get_child_count()
	main.get_node("%RunState").dew = 1000
	placer._try_build(_free_cell_near(_route_cell(6)))
	_check(tower_container.get_child_count() == count, "Memory Wardens are one per run")
	await _clean()


# --- Helpers --------------------------------------------------------------------------------------------

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout

# A Warden on `cell`, added straight to the map (no path blocking: the tests keep nightmares still).
func _plant(data: TowerData, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = data
	tower.cell = cell
	tower.position = map_generator.MAP_GRID.calculate_map_position(cell)
	tower_container.add_child(tower)
	return tower

# A nightmare standing still at `position`.
func _spawn_at(position: Vector2, data: EnemyData = null) -> Node2D:
	spawner.spawn_enemy(data if data != null else shade)
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = position
	return enemy

# A nightmare walking the route from the start.
func _spawn_walker() -> Node2D:
	spawner.spawn_enemy(shade)
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.max_health = 100000
	enemy.health = 100000
	return enemy

func _route_cell(index: int) -> Vector2:
	return route[mini(index, route.size() - 1)]

# A cell beside `at` that isn't on the route.
func _free_cell_near(at: Vector2) -> Vector2:
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(1, 1), Vector2(-1, -1)]:
		if not route.has(at + offset):
			return at + offset
	return at + Vector2(2, 0)

func _clear_enemies() -> void:
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

# Removes the test's Wardens and nightmares.
func _clean() -> void:
	for tower in tower_container.get_children():
		tower.queue_free()
	await _clear_enemies()
