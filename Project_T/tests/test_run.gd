extends SceneTree

# Headless run-structure test: drifts, build phase, call early, bonuses, leaves, act breaks,
# selling, speed controls, win and lose. Run from the project folder:
#   godot --headless --path . --script res://tests/test_run.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_schedules()
	await _test_full_run()
	await _test_lose()
	print("run test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _test_schedules() -> void:
	var drift3: DriftData = load("res://resource/drift/act1/drift_3.tres")
	var schedule := drift3.get_schedule()
	_check(schedule.size() == 15 and drift3.get_creature_count() == 15, "drift 3 has 15 creatures")
	_check(schedule[0][1].display_name == "Bark Beetle" and schedule[2][1].display_name == "Bark Beetle",
		"drift 3 sends the beetles first")
	_check(is_equal_approx(schedule[3][0], 8.0), "leaf bugs start after the beetles + delay (t=%s)" % schedule[3][0])
	var drift4: DriftData = load("res://resource/drift/act1/drift_4.tres")
	var mixed := drift4.groups[1].get_arrival_order()
	var beetles := mixed.filter(func(e: EnemyData) -> bool: return e.display_name == "Bark Beetle").size()
	_check(mixed.size() == 25 and beetles == 5, "drift 4 mixes 20 Leaf Bugs + 5 Bark Beetles")
	_check(mixed[0].display_name == "Leaf Bug" and mixed[2].display_name == "Bark Beetle",
		"mixed group spreads the beetles out")

func _test_full_run() -> void:
	var main := await _new_run()
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	var spawner = main.get_node("%EnemyContainer")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var speed: GameSpeed = main.get_node("%GameSpeed")
	var map_generator = main.get_node("%MapGenerator")
	director.drifts_per_act = 2  # Act breaks after drifts 2 and 4, so this run sees them
	main.get_node("%DreamState").dream_after_drifts.clear()  # Dreams have their own test

	_check(director.is_build_phase() and director.drifts_started == 0, "run starts in the build phase")
	_check(run_state.leaves == 20 and run_state.dew == 60, "20 leaves, 60 Dew")
	_check(spawner.get_enemies().is_empty(), "no creatures before Start Drift")
	_check(director.get_call_early_bonus() == 0, "no call-early bonus in the build phase")

	# --- Selling: full refund in the build phase ---
	var sprout: TowerData = placer.towers[0]
	placer.tower_data = sprout
	var cell := _free_cell_beside_path(map_generator)
	_check(placer._try_build(cell), "built a Sprout")
	_check(run_state.dew == 60 - sprout.cost, "Sprout cost %d" % sprout.cost)
	_check(seller.sell(cell), "sold it")
	_check(run_state.dew == 60, "full refund in the build phase")
	_check(map_generator.is_buildable(cell), "sold cell is open again")

	# --- Drift 1 ---
	_check(director.start_next_drift(), "Start Drift 1")
	_check(not director.is_build_phase() and director.is_arriving(), "drift 1 is arriving")
	_check(spawner.get_enemies().size() == 1, "first creature arrives immediately")
	_check(not director.start_next_drift(), "can't call early while a drift is still arriving")

	# --- Selling: half refund during a drift ---
	placer.tower_data = sprout
	_check(placer._try_build(cell), "can build during a drift")
	var dew_before := run_state.dew
	seller.sell(cell)
	_check(run_state.dew == dew_before + sprout.cost / 2, "half refund during a drift")

	# --- Pause and speed ---
	speed.set_paused(true)
	var enemy: Node2D = spawner.get_enemies()[0]
	var pos := enemy.position
	for i in 10:
		await process_frame
	_check(enemy.position == pos, "creatures stop while paused")
	placer.tower_data = sprout
	_check(placer._try_build(cell), "can build while paused")
	seller.sell(cell)
	speed.set_speed(3.0)
	_check(not paused and Engine.time_scale == 3.0, "3× speed unpauses")
	speed.set_speed(1.0)

	# Cleanse everything drift 1 sends -> perfect clear
	var cleared := []
	director.drift_cleared.connect(func(n: int, bonus: int, perfect: bool) -> void: cleared.append([n, bonus, perfect]))
	var acts := []
	director.act_started.connect(func(act: int, regrown: int) -> void: acts.append([act, regrown]))
	dew_before = run_state.dew
	await _cleanse_until(spawner, func() -> bool: return director.drifts_cleared >= 1)
	_check(cleared.size() == 1 and cleared[0] == [1, 25, true], "drift 1 clear bonus 20 + perfect 5 (%s)" % [cleared])
	_check(run_state.dew == dew_before + 10 * 3 + 25, "10 Leaf Bugs + bonus = %d Dew (got %d)" % [dew_before + 55, run_state.dew])
	_check(director.is_build_phase(), "back to the build phase after drift 1")

	# --- Drift 2: leak one creature, then call drift 3 early ---
	director.start_next_drift()
	var leaker: Node2D = spawner.get_enemies()[0]
	_send_to_goal(leaker, map_generator)
	await _frames(5)
	_check(run_state.leaves == 19, "a Leaf Bug reaching the Heartwood costs 1 leaf")
	await _cleanse_until(spawner, func() -> bool: return not director.is_arriving(), 2)
	# Let the last creatures walk a little so there's time to skip
	var early_bonus := director.get_call_early_bonus()
	_check(early_bonus > 0 and early_bonus <= director.get_clear_bonus(2), "call-early bonus %d is within the cap" % early_bonus)
	dew_before = run_state.dew
	_check(director.start_next_drift(), "call drift 3 early")
	_check(run_state.dew == dew_before + early_bonus, "call-early bonus paid")
	_check(director.drifts_started == 3 and not director.is_build_phase(), "drifts 2 and 3 overlap")

	# Drift 3 creatures are 1.12² tougher
	var beetle: Node2D = spawner.get_enemies().filter(func(e: Node2D) -> bool:
		return e.enemy_data.display_name == "Bark Beetle")[0]
	_check(beetle.max_health == roundi(300 * 1.12 * 1.12), "drift 3 Bark Beetle health %d" % beetle.max_health)

	await _cleanse_until(spawner, func() -> bool: return director.drifts_cleared >= 3)
	var drift2: Array = cleared.filter(func(c: Array) -> bool: return c[0] == 2)[0]
	_check(drift2[1] == 25 and not drift2[2], "leaky drift 2 gets no perfect bonus (%s)" % [drift2])
	_check(acts.size() == 1 and acts[0] == [2, 1], "act 2 after drift 2 regrows leaves up to max (%s)" % [acts])
	_check(run_state.leaves == 20, "leaves back to 20")

	# --- Drift 4: Puffcaps split, and the drift waits for the Puffcaplets ---
	director.start_next_drift()
	var puffcap: Node2D = spawner.get_enemies()[0]
	_check(puffcap.enemy_data.display_name == "Puffcap", "drift 4 starts with Puffcaps")
	var count_before: int = spawner.get_enemies().size()
	puffcap.take_damage(100000)
	var lets: Array = spawner.get_enemies().filter(func(e: Node2D) -> bool:
		return e.enemy_data.display_name == "Puffcaplet")
	_check(lets.size() == 3 and spawner.get_enemies().size() == count_before - 1 + 3, "a Puffcap splits into 3 Puffcaplets")
	await _cleanse_until(spawner, func() -> bool: return director.drifts_cleared >= 4)
	_check(acts.size() == 2, "act break after drift 4")

	# --- Drift 5 (boss) and the win ---
	var ended := []
	run_state.run_ended.connect(func(won: bool) -> void: ended.append(won))
	director.start_next_drift()
	await _cleanse_until(spawner, func() -> bool: return not ended.is_empty(), 0, 3000)
	_check(ended == [true] and run_state.won, "cleansing the last drift wins the run")
	_check(director.drifts_cleared == 5 and not director.has_next_drift(), "all 5 drifts cleared")
	_check(not director.start_next_drift(), "nothing to start after the win")
	main.queue_free()
	await process_frame

func _test_lose() -> void:
	var main := await _new_run()
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	var spawner = main.get_node("%EnemyContainer")
	var map_generator = main.get_node("%MapGenerator")
	main.get_node("%DreamState").dream_after_drifts.clear()
	run_state.leaves = 1
	director.start_next_drift()
	_send_to_goal(spawner.get_enemies()[0], map_generator)
	await _frames(5)
	_check(run_state.is_over and not run_state.won and run_state.leaves == 0, "losing the last leaf ends the run")
	await _frames(200)
	_check(spawner.get_enemies().size() <= 1, "no more creatures arrive after losing")
	main.queue_free()
	await process_frame


# --- Helpers --------------------------------------------------------------------------------------

func _new_run() -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	return main

func _frames(n: int) -> void:
	for i in n:
		await process_frame

# Each frame, cleanses every creature on the field (in drift order) until `done` or `max_frames`.
# `leave` creatures are left walking.
func _cleanse_until(spawner, done: Callable, leave: int = 0, max_frames: int = 2000) -> void:
	for i in max_frames:
		if done.call():
			return
		var enemies: Array = spawner.get_enemies()
		for j in range(leave, enemies.size()):
			enemies[j].take_damage(100000)
		await process_frame
	_check(false, "timed out waiting (%d frames)" % max_frames)

# Puts `enemy` one step from the Heartwood so it reaches it next frame.
func _send_to_goal(enemy: Node2D, map_generator) -> void:
	var goal: Vector2 = map_generator.endPath
	enemy.position = enemy.grid.calculate_map_position(goal) + Vector2(0, -8)
	enemy.set_path(PackedVector2Array([goal]))

func _free_cell_beside_path(map_generator) -> Vector2:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	for i in range(4, path.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if not path.has(cell) and map_generator.can_block(cell):
				return cell
	return Vector2(-1, -1)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
