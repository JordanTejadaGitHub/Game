extends SceneTree

# Headless run-flow test (run_design.md "Blocks and rests"): rests, the family pick after drift 1,
# drifts flowing on their own, call early, rest bonuses, selling refunds, speed controls, boss rest
# with its family pick and act break, winning and losing. Dreams / Omens that pop up at rests are
# dismissed (first card / Clear Skies) so the flow keeps going.
#   godot --headless --path . --script res://tests/test_run.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_demo_data()
	await _test_blocks_and_rests()
	await _test_boss_rest_and_win()
	await _test_lose()
	print("run test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _test_demo_data() -> void:
	var drifts := DriftDirector.load_demo_drifts()
	_check(drifts.size() == 50, "the demo has 50 drifts (%d)" % drifts.size())
	_check(drifts[0].get_creature_count() == 6, "drift 1 is 6 Shades")
	var boss_25: Array = drifts[24].get_schedule().map(func(a: Array) -> String: return _kind(a[1]))
	_check(boss_25.count("old_stag") == 1 and boss_25.find("old_stag") == 12, "drift 25: 12 Leaf Bugs, then the boss")
	var boss_50: Array = drifts[49].get_schedule().map(func(a: Array) -> String: return _kind(a[1]))
	_check(boss_50.has("great_toad"), "drift 50 brings its boss")
	var elites: int = drifts[44].get_schedule().filter(func(a: Array) -> bool: return a[2]).size()
	_check(elites == 4, "drift 45 has 4 Deeply Blighted (%d)" % elites)
	# Difficulty pass v1: +25% nightmares (rounded up per kind) from drift 10; bosses stay alone.
	var entry := DriftEntry.new()
	entry.enemy = load("res://resource/enemy/leaf_bug.tres")
	entry.count = 6
	_check(entry.get_count(1.0, 1.0, 1.25) == 8 and entry.get_count() == 6, "6 nightmares × 1.25 rounds up to 8")
	entry.count = 3
	_check(entry.get_count(1.0, 1.0, 1.25) == 4, "3 nightmares × 1.25 rounds up to 4")
	entry.count = 2
	_check(entry.get_count(1.0, 1.0, 1.25) == 2, "kinds of 1–2 (lone specials) stay as listed")
	entry.count = 6
	entry.elite = true
	_check(entry.get_count(1.0, 1.0, 1.25) == 6, "elites stay as listed")
	var boss_count: int = drifts[24].get_schedule(1.0, 1.0, 1.0, 1.25).map(func(a: Array) -> String: return _kind(a[1])).count("old_stag")
	_check(boss_count == 1, "the boss still comes alone")
	_check(drifts[9].get_schedule(1.0, 1.0, 1.0, 1.25).size() > drifts[9].get_schedule().size(), "drift 10 gets more nightmares")

func _test_blocks_and_rests() -> void:
	var main := await _new_run()
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	var spawner = main.get_node("%EnemyContainer")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var speed: GameSpeed = main.get_node("%GameSpeed")
	var family: Control = main.get_node("%FamilyPickScreen")
	var dreams: DreamState = main.get_node("%DreamState")
	var map_generator = main.get_node("%MapGenerator")

	_check(director.is_resting() and director.drifts_started == 0, "the run starts resting")
	_check(run_state.leaves == 15 and run_state.max_leaves == 15 and run_state.dew == 60, "15 leaves, 60 Dew")
	_check(spawner.get_enemies().is_empty(), "no creatures before Start")
	_check(director.get_extra_nightmares(9) == 1.0 and director.get_extra_nightmares(10) == 1.25, "extra nightmares from drift 10")
	# Mid-game rework: ×1.045 per drift to 25, ×1.055 from 26 (≈ ×11 by drift 50).
	_check(is_equal_approx(director.get_growth(25), pow(1.045, 24)) and is_equal_approx(director.get_growth(26), pow(1.045, 24) * 1.055)
		and absf(director.get_growth(50) - 11.0) < 0.6, "health growth steepens from drift 26 (×%.1f at 50)" % director.get_growth(50))
	# One Deeply Blighted from drift 26 when the drift lists none (boss drifts: from the escort).
	for number in [25, 26, 35, 45, 50]:
		var schedule: Array = director.drifts[number - 1].get_schedule()
		var listed: int = schedule.filter(func(a: Array) -> bool: return a[2]).size()
		director.add_guaranteed_elite(schedule, number)
		var elites: Array = schedule.filter(func(a: Array) -> bool: return a[2])
		var expected := listed if number < 26 or listed > 0 else 1
		_check(elites.size() == expected and elites.all(func(a: Array) -> bool: return not a[1].is_boss),
			"drift %d: %d elite(s) (%d listed)" % [number, elites.size(), listed])
	var stag: EnemyData = load("res://resource/enemy/old_stag.tres")
	_check(is_equal_approx(director.get_health_scale(stag, 25), 1.5), "bosses have ×1.5 health")

	# Selling in a rest: the rest refund (build_phase_refund, 75% in difficulty pass v1)
	var sprout: TowerData = placer.towers[0]
	placer.tower_data = sprout
	var cell := _free_cell(map_generator)
	_check(placer._try_build(cell), "built a Sprout")
	var refund := seller.get_refund(seller.get_tower_at(cell))
	_check(absf(refund - sprout.cost * seller.build_phase_refund) <= 1.0, "the rest refund is build_phase_refund (%d)" % refund)
	_check(seller.sell(cell) and run_state.dew == 60 - sprout.cost + refund, "the refund is paid while resting")

	# Drift 1 → the family pick (no rest bonus, no Dream)
	var rests := []
	director.rest_started.connect(func(block: int, boss: bool, bonus: int, perfect: bool) -> void:
		rests.append([block, boss, bonus, perfect]))
	var picks := []
	director.family_pick_requested.connect(func(reason: StringName) -> void: picks.append(reason))
	_check(director.start_next_drift(), "Start drift 1")
	_check(not director.is_resting() and spawner.get_enemies().size() == 1, "drift 1 starts, first Leaf Bug arrives at once")
	_check(not director.can_start_next_drift(), "no drift 2 before the family pick")

	# Selling during a drift: half refund
	placer.tower_data = sprout
	_check(placer._try_build(cell), "can build during a drift")
	var dew := run_state.dew
	seller.sell(cell)
	_check(run_state.dew == dew + sprout.cost / 2, "half refund while creatures walk")

	# Pause stops creatures but not building
	speed.set_paused(true)
	var walker: Node2D = spawner.get_enemies()[0]
	var pos := walker.position
	await _frames(10)
	_check(walker.position == pos, "creatures stop while paused")
	placer.tower_data = sprout
	_check(placer._try_build(cell), "can build while paused")
	seller.sell(cell)
	speed.set_speed(3.0)
	_check(not paused and Engine.time_scale == 3.0, "3× speed unpauses")
	speed.set_speed(1.0)

	await _play_until(main, func() -> bool: return director.awaiting_family_pick)
	_check(picks == [&"first"] and rests.is_empty(), "after drift 1: family pick, no rest")
	_check(family.visible and family.offer.size() == 3, "3 families offered")
	var picked: TowerData = family.offer[0]
	family.choose(picked)
	_check(dreams.is_unlocked(picked.get_id()) and not director.awaiting_family_pick, "picking unlocks the family")
	_check(director.is_resting(), "then a quick rest until Start")

	# Drifts 2–5 flow on their own
	_check(director.start_next_drift(), "Start drift 2")
	await _play_until(main, func() -> bool: return director.drifts_started >= 3, 0, 3000)
	_check(director.drifts_started >= 3, "drift 3 starts by itself (Auto-drift)")
	await _play_until(main, func() -> bool: return not rests.is_empty(), 0, 9000)
	_check(director.drifts_started == 5 and director.is_resting(), "rest after drift 5")
	_check(rests[0] == [1, false, 40, true], "rest bonus 20 + 10×1 + perfect 10 = 40 (%s)" % [rests[0]])

	await _settle(main)  # Let the rest's Dream (built a frame later) show and be dismissed
	# Block 2: call early, a leak, health growth
	var bonus_now := [0]
	_check(director.start_next_drift(), "Start drift 6 (3 Bark Beetles, 2.5 s apart)")
	await _frames(2)
	bonus_now[0] = director.get_call_early_bonus()
	_check(bonus_now[0] == 2, "calling drift 7 early skips ~5 s = 2 Dew (%d)" % bonus_now[0])
	dew = run_state.dew
	director.start_next_drift()
	_check(director.drifts_started == 7 and run_state.dew == dew + bonus_now[0], "call early pays")
	var bug: Node2D = spawner.get_enemies().filter(func(e: Node2D) -> bool:
		return _kind(e.enemy_data) == "leaf_bug")[0]
	_check(bug.max_health == roundi(100 * pow(1.045, 6)), "drift 7 Leaf Bug health ×1.045^6 (%d)" % bug.max_health)
	var leaves_before := run_state.leaves
	_send_to_goal(bug, map_generator)
	await _frames(5)
	_check(run_state.leaves == leaves_before - 1, "a Leaf Bug reaching the Heartwood costs a leaf")
	director.set_auto_drift(false)
	await _play_until(main, func() -> bool: return not director.is_arriving() and spawner.get_enemies().is_empty(), 0, 3000)
	await _frames(300)
	_check(director.drifts_started == 7, "Auto-drift off: the next drift waits for the button")
	director.set_auto_drift(true)
	await _play_until(main, func() -> bool: return rests.size() >= 2, 0, 9000)
	_check(rests[1] == [2, false, 40, false], "leaky block: 20 + 10×2, no perfect bonus (%s)" % [rests[1]])
	main.queue_free()
	await process_frame

func _test_boss_rest_and_win() -> void:
	var main := await _new_run()
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	var family: Control = main.get_node("%FamilyPickScreen")
	var all := DriftDirector.load_demo_drifts()
	# A short run: block 1 = drifts 1–4 + the Old Stag drift (a boss at the end of "act 1"), then one more.
	director.drifts = [all[0], all[1], all[2], all[3], all[24], all[1]]
	director.drifts_per_act = 5
	var picks := []
	director.family_pick_requested.connect(func(reason: StringName) -> void: picks.append(reason))
	var rests := []
	director.rest_started.connect(func(block: int, boss: bool, bonus: int, perfect: bool) -> void:
		rests.append([block, boss]))
	var acts := []
	director.act_started.connect(func(act: int, regrown: int) -> void: acts.append([act, regrown]))
	var ended := []
	run_state.run_ended.connect(func(won: bool) -> void: ended.append(won))
	run_state.leaves = 10

	director.start_next_drift()
	await _play_until(main, func() -> bool: return director.awaiting_family_pick)
	family.choose(family.offer[0])
	director.start_next_drift()
	await _play_until(main, func() -> bool: return picks.size() >= 2, 0, 12000)
	_check(picks == [&"first", &"boss"] and director.bosses_cleansed == 1, "boss drift ends with a family pick")
	_check(rests.is_empty(), "the boss rest waits for the family pick")
	family.choose(family.offer[0])
	_check(rests == [[1, true]], "then the boss rest")
	await _settle(main)
	_check(acts == [[2, 1]] and run_state.leaves == 11, "act break regrows 1 leaf (%s)" % [acts])
	director.start_next_drift()
	await _play_until(main, func() -> bool: return not ended.is_empty(), 0, 3000)
	_check(ended == [true] and not director.has_next_drift(), "clearing the last drift wins")
	main.queue_free()
	await process_frame

func _test_lose() -> void:
	var main := await _new_run()
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	var spawner = main.get_node("%EnemyContainer")
	run_state.leaves = 1
	director.start_next_drift()
	_send_to_goal(spawner.get_enemies()[0], main.get_node("%MapGenerator"))
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

# Each frame: dismisses Dream / Omen offers (first card / Clear Skies) and cleanses every creature
# except the first `leave`, until `done` or `max_frames`.
func _play_until(main: Node, done: Callable, leave: int = 0, max_frames: int = 4000) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	var omens = get_first_node_in_group(&"omens")
	for i in max_frames:
		if done.call():
			return
		if dreams.is_offering():
			if dreams.can_skip():
				dreams.skip()  # Let it pass: no card effects that would change the numbers under test
			else:
				dreams.choose(dreams.current_offer[0])
		if omens != null and omens.is_offering():
			omens.choose(null)
		var enemies: Array = main.get_node("%EnemyContainer").get_enemies()
		for j in range(leave, enemies.size()):
			enemies[j].take_damage(1000000)
		await process_frame
	_check(false, "timed out waiting (%d frames)" % max_frames)

# Runs rames frames dismissing any Dream / Omen offers, without cleansing anything.
func _settle(main: Node, frames: int = 10) -> void:
	for i in frames:
		await _play_until(main, func() -> bool: return true)
		await process_frame
		var dreams: DreamState = main.get_node("%DreamState")
		if dreams.is_offering():
			dreams.skip() if dreams.can_skip() else dreams.choose(dreams.current_offer[0])
		var omens = get_first_node_in_group(&"omens")
		if omens != null and omens.is_offering():
			omens.choose(null)

# Puts `enemy` one step from the Heartwood so it reaches it next frame.
func _send_to_goal(enemy: Node2D, map_generator) -> void:
	var goal: Vector2 = map_generator.endPath
	enemy.position = enemy.grid.calculate_map_position(goal) + Vector2(0, -8)
	enemy.set_path(PackedVector2Array([goal]))

func _free_cell(map_generator) -> Vector2:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	for i in range(4, path.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if not path.has(cell) and map_generator.can_block(cell):
				return cell
	return Vector2(-1, -1)

# A creature's kind by its resource file (display names change with the story; files don't).
func _kind(data: EnemyData) -> String:
	return data.resource_path.get_file().get_basename()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
