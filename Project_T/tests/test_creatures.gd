extends SceneTree

# Headless test for the acts 1–2 creature traits and bosses (acts_1_2.md): Deeply Blighted elites,
# Dandelion Seeds flying over the maze, Hedgehogs rolling on straights, Mother Duck + Ducklings,
# the Old Stag trampling Thornwalls and charging, the Great Toad leaping.
#   godot --headless --path . --script res://tests/test_creatures.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 777
	root.add_child(main)
	await process_frame
	var spawner = main.get_node("%EnemyContainer")
	var map_generator = main.get_node("%MapGenerator")

	# --- Deeply Blighted ---
	var bug_data: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var elite: Node2D = spawner.spawn_enemy(bug_data, 1.0, {}, true)
	_check(elite.max_health == 300 and elite.get_dew_reward() == 6 and elite.get_leaf_cost() == 2,
		"elite: ×3 health (%d), ×2 Dew (%d), 2 leaves" % [elite.max_health, elite.get_dew_reward()])
	_check(is_equal_approx(elite.sprite.scale.x, 1.2), "elite is drawn 20% bigger")
	elite.free()

	# --- Dandelion Seed floats straight over the maze ---
	var seed: Node2D = spawner.spawn_enemy(load("res://resource/enemy/dandelion_seed.tres"))
	_check(seed.is_flying() and seed._path.size() == 2 and seed._path[1] == map_generator.endPath,
		"Dandelion Seed flies straight at the Heartwood")
	_check(not spawner.get_maze_walkers().has(seed), "flyers don't count for the path rule")
	seed.free()

	# --- Hedgehog rolls on a straight, stops at the turn ---
	var hedgehog: Node2D = spawner.spawn_enemy(load("res://resource/enemy/hedgehog.tres"))
	var line := PackedVector2Array()
	var start: Vector2 = hedgehog.get_current_cell()
	for i in 6:
		line.append(start + Vector2(i, 0))
	line.append(start + Vector2(5, 1))  # a turn at the end
	hedgehog.set_path(line)
	var rolled := false
	var stopped_at_turn := false
	for i in 600:
		await process_frame
		if hedgehog.rolling:
			rolled = true
			_check(is_equal_approx(hedgehog.get_move_speed(), hedgehog.enemy_data.roll_speed), "rolling speed is 3 cells/s")
		if rolled and not hedgehog.rolling:
			stopped_at_turn = true
			break
	_check(rolled, "Hedgehog curls up after 3 straight tiles")
	_check(stopped_at_turn, "and uncurls at the turn")
	hedgehog.free()

	# --- Mother Duck and her Ducklings ---
	var duck: Node2D = spawner.spawn_enemy(load("res://resource/enemy/mother_duck.tres"))
	var ducklings: Array = spawner.get_enemies().filter(func(e: Node2D) -> bool:
		return e.enemy_data.resource_path.get_file() == "duckling.tres")
	_check(ducklings.size() == 4, "Mother Duck brings 4 Ducklings")
	_check(ducklings.all(func(d: Node2D) -> bool: return d.hold_time > 0.0), "Ducklings set off one after another")
	duck.take_damage(1000000)
	_check(ducklings.all(func(d: Node2D) -> bool: return d.lost), "cleansing Mother first leaves the Ducklings lost")
	_check(ducklings[0].get_move_speed() <= ducklings[0].enemy_data.lost_speed + 0.01, "lost Ducklings slow down")
	for child in spawner.get_children():
		child.free()

	# --- Old Stag tramples an adjacent Thornwall, and charges at half health ---
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	main.get_node("%RunState").dew = 1000
	var stag: Node2D = spawner.spawn_enemy(load("res://resource/enemy/old_stag.tres"))
	stag.set_process(false)
	# Stand it mid-route (the entrance's only free neighbour is the one tile creatures must pass).
	var route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var wall_cell := Vector2(-1, -1)
	for i in range(8, route.size()):
		wall_cell = _free_neighbour(map_generator, route[i], route)
		if wall_cell != Vector2(-1, -1):
			stag.position = stag.grid.calculate_map_position(route[i])
			stag.set_path(route.slice(i))
			break
	placer.tower_data = load("res://resource/tower/thornwall.tres")
	_check(placer._try_build(wall_cell), "a Thornwall next to the Stag")
	var trampled := []
	spawner.wall_trampled.connect(func(cell: Vector2, _by: Node2D) -> void: trampled.append(cell))
	stag._update_trait(stag.enemy_data.trample_interval)
	_check(trampled == [wall_cell], "the Old Stag tramples it")
	_check(map_generator.is_buildable(wall_cell), "the cell is open again (the wall is gone for good)")
	stag.take_damage(stag.max_health / 2 + 1)
	_check(stag._bellowed and spawner.get_children().filter(func(e) -> bool: return e.enemy_data == stag.enemy_data.bellow_spawn).size() == 6, "half health: the Stag bellows (6 Husks)")
	stag.free()

	# --- Great Toad leaps 3 tiles and makes creatures near the landing Damp ---
	var toad: Node2D = spawner.spawn_enemy(load("res://resource/enemy/great_toad.tres"))
	var index_before: int = toad._path_index
	var leap_steps: int = 3 * maxi(roundi(1.0 / toad._step_cells(index_before + 1)), 1)  # 3 cells (2 steps a cell on half cells)
	var landing: Vector2 = toad._path[index_before + leap_steps - 1]
	var neighbour: Node2D = spawner.spawn_enemy(bug_data)
	neighbour.set_process(false)
	neighbour.position = toad.grid.calculate_map_position(landing)
	toad._leap()
	await create_timer(toad.LEAP_TIME + 0.2, true, false, true).timeout  # The leap (sped-up burrow row included: 2e8f542b) and a little more, not a step past it
	_check(toad._path_index == index_before + leap_steps,"Toad leaps 3 tiles ahead (%d → %d)" % [index_before, toad._path_index])
	_check(neighbour.statuses.has(EnemyStatuses.DAMP), "creatures by the landing get Damp")

	# --- Hit feedback (screens_ui.md "Hit feedback on nightmares", layer 1): a hit makes it flinch, a tick doesn't ---
	var husk: Node2D = spawner.spawn_enemy(load("res://resource/enemy/bark_beetle.tres"))
	husk.set_process(false)
	husk.coat = 0.0  # Its dread shell (Nightmare Kinds) would soak part of the hit; the flinch is measured on what lands
	var stood: Vector2 = husk.position
	var rest_offset: Vector2 = husk.sprite.offset
	var hitter := Node2D.new()
	main.add_child(hitter)
	hitter.global_position = husk.global_position + Vector2(-100, 0)  # The hit comes from its left
	husk.take_damage(husk.max_health * 0.1, "", false, false, hitter)
	_check(is_equal_approx(husk._flinch_left, husk.FLINCH_TIME) and is_equal_approx(husk._recoil.length(), husk.RECOIL_MAX)
		and husk._recoil.x > 0.0, "a heavy hit: the sprite recoils %.1f px away from the hit" % husk._recoil.length())
	_check(is_equal_approx(husk._flash_shown, husk.FLASH_MAX) and husk.sprite.offset != rest_offset,
		"and it flashes pale (hit_flash %.2f)" % husk._flash_shown)
	_check(husk.position == stood, "the body never moves: only the sprite")
	husk._update_flinch(husk.FLINCH_TIME)
	_check(husk._recoil == Vector2.ZERO and husk._flash_shown == 0.0 and husk.sprite.offset.is_equal_approx(rest_offset),
		"then both return to rest")
	husk.take_damage(1.0)
	_check(husk._recoil.length() >= husk.RECOIL_MIN - 0.001 and husk._recoil.length() < husk.RECOIL_MIN + 0.2
		and husk._flash_shown >= husk.FLASH_MIN - 0.001, "a tap still registers (%.2f px)" % husk._recoil.length())
	husk._update_flinch(husk.FLINCH_TIME)
	husk.take_damage(5.0, "spore", true, false, null, &"spored")
	_check(husk._flinch_left == 0.0 and husk._flash_shown == 0.0 and husk._recoil == Vector2.ZERO,
		"a Poisoned tick doesn't flinch or flash")
	_check(husk.is_sustained(&"spored") and husk.is_sustained(), "it marks the sustained state instead (for the Wardens' overlays)")
	husk._update_sustained(husk.SUSTAIN_HOLD + 0.01)
	_check(not husk.is_sustained(&"spored"), "which ends a moment after the last tick")
	husk.set_sustained(husk.ARC_TAG, true)
	husk._update_sustained(5.0)
	husk._update_flinch(0.016)
	_check(husk.is_sustained(husk.ARC_TAG) and husk._recoil != Vector2.ZERO, "a source can hold it (the Jarlink's arc): it twitches meanwhile")
	husk.set_sustained(husk.ARC_TAG, false)
	husk._update_flinch(0.016)
	_check(not husk.is_sustained() and husk._recoil == Vector2.ZERO, "and is still again once the arc lets go")
	var big: Node2D = spawner.spawn_enemy(load("res://resource/enemy/old_stag.tres"))
	big.set_process(false)
	big.take_damage(big.max_health * 0.2)
	_check(is_equal_approx(big._flinch_recoil.length(), big.RECOIL_MAX * big.BOSS_FLINCH), "a boss flinches half as far (%.1f px; drawn in whole pixels: %.1f)" % [big._flinch_recoil.length(), big._recoil.length()])
	hitter.free()

	print("creatures test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# A buildable neighbour of `cell` that keeps the path open.
# A whole cell beside route point `point` (x.25 / x.75 on half-cell routes) that no route point is in and
# a Warden may block.
func _free_neighbour(map_generator, point: Vector2, route: PackedVector2Array = PackedVector2Array()) -> Vector2:
	var cell := (point + Vector2(0.5, 0.5)).floor()  # The whole cell a route point is in
	var on_route := {}
	for p in route:
		on_route[(p + Vector2(0.5, 0.5)).floor()] = true
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		if not on_route.has(cell + offset) and map_generator.can_block(cell + offset):
			return cell + offset
	return Vector2(-1, -1)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
