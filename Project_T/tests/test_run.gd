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
	_check(drifts.size() == 100, "runs have 100 drifts, the demo too (%d)" % drifts.size())
	# Acts 3–4 (acts_3_4.md): the Moth Queen at 75 (after 12 Lurkers), the Hollow Oak ends drift 100.
	var bosses_75: Array = drifts[74].get_schedule().filter(func(a: Array) -> bool: return a[1].is_boss)
	_check(bosses_75.size() == 1 and bosses_75[0][1].display_name == "The Moth Queen"
		and drifts[74].get_schedule()[12][1].is_boss, "drift 75: 12 Lurkers, then the Moth Queen")
	var last: Array = drifts[99].get_schedule()[-1]
	_check(last[1].is_boss and last[1].display_name == "The Hollow Oak", "drift 100 ends with the Hollow Oak")
	_check(drifts[50].get_schedule().all(func(a: Array) -> bool: return not a[1].is_boss)
		and drifts[50].get_creature_count() == 48, "drift 51: 48 nightmares, no boss")
	_check(drifts[97].get_creature_count() == 80, "drift 98: the Swarm of 80 Shades")
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
	# Dispel Dew × 1.0 / 0.68 / 0.65 / 0.5 by act (act 2 tightened), fractions carried over.
	run_state._dispel_dew_carry = 0.0
	_check(run_state._scaled_dispel_dew(20) == 20, "act 1 pays dispel Dew in full")
	run_state._dispel_dew_carry = 0.0
	var started := director.drifts_started
	director.drifts_started = 80  # Act 4
	run_state._dispel_dew_carry = 0.0
	var act_4_paid := run_state._scaled_dispel_dew(3) + run_state._scaled_dispel_dew(3)
	director.drifts_started = started
	run_state._dispel_dew_carry = 0.0
	_check(act_4_paid == 3, "act 4 pays half, the halves adding up (3 + 3 → %d)" % act_4_paid)
	# Mid-game rework: ×1.045 per drift to 25, ×1.055 for 26–50 (≈ ×11 by drift 50), ×1.045 from 51
	# (≈ ×33 at 75, ×100 at 100).
	_check(is_equal_approx(director.get_growth(25), pow(1.045, 24)) and is_equal_approx(director.get_growth(26), pow(1.045, 24) * 1.055)
		and absf(director.get_growth(50) - 11.0) < 0.6, "health growth steepens from drift 26 (×%.1f at 50)" % director.get_growth(50))
	_check(is_equal_approx(director.get_growth(51), director.get_growth(50) * 1.045) and absf(director.get_growth(75) - 33.0) < 1.5
		and absf(director.get_growth(100) - 100.0) < 3.0, "growth eases to ×1.045 from 51 (×%.0f at 75, ×%.0f at 100)" % [
		director.get_growth(75), director.get_growth(100)])
	# Acts 3–4: ×1.6 on top of growth, bosses included (run_design.md "Act 3 probe").
	var shade_data: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var oak_data: EnemyData = load("res://resource/enemy/hollow_oak.tres")
	_check(is_equal_approx(director.get_health_scale(shade_data, 50), director.get_growth(50) * 1.55 * director.get_health_multiplier(shade_data, 50))
		and is_equal_approx(director.get_health_scale(shade_data, 51), director.get_growth(51) * 1.6 * director.get_health_multiplier(shade_data, 51))
		and is_equal_approx(director.get_health_scale(oak_data, 100), director.boss_health_multiplier * 1.6 * director.get_health_multiplier(oak_data, 100)),
		"acts 3–4 nightmares and bosses have ×1.6 health")
	# Acts 1–2 (run_design.md 72860af): ×1.0 to 9, ramping to ×1.15 at 20 (held through 30), ramping to ×1.55 at 45.
	var curve := {1: 1.0, 9: 1.0, 20: 1.15, 25: 1.15, 26: 1.15, 30: 1.15, 45: 1.55, 50: 1.55}
	for number in curve:
		_check(is_equal_approx(director.get_early_multiplier(number), curve[number]),
			"drift %d: health ×%.2f (got %.3f)" % [number, curve[number], director.get_early_multiplier(number)])
	_check(absf(director.get_early_multiplier(37) - (1.15 + 0.4 * 7.0 / 15.0)) < 0.001 and director.get_early_multiplier(14) > 1.0
		and director.get_early_multiplier(14) < 1.15, "both ramps are straight lines")
	# One Deeply Blighted from drift 31 when the drift lists none (boss drifts: from the escort); two from 76.
	for number in [25, 26, 30, 31, 35, 45, 50, 51, 75, 76, 100]:
		var schedule: Array = director.drifts[number - 1].get_schedule()
		var listed: int = schedule.filter(func(a: Array) -> bool: return a[2]).size()
		director.add_guaranteed_elite(schedule, number)
		var elites: Array = schedule.filter(func(a: Array) -> bool: return a[2])
		var expected := listed if number < 31 or listed > 0 else (2 if number >= 76 else 1)
		_check(elites.size() == expected and elites.all(func(a: Array) -> bool: return not a[1].is_boss),
			"drift %d: %d elite(s) (%d listed)" % [number, elites.size(), listed])
	var stag: EnemyData = load("res://resource/enemy/old_stag.tres")
	_check(is_equal_approx(director.get_health_scale(stag, 25), director.act1_boss_health_multiplier * director.get_health_multiplier(stag, 25))
		and is_equal_approx(director.get_health_scale(shade_data, 25), director.get_growth(25) * 1.15 * director.get_health_multiplier(shade_data, 25)),
		"act 1's boss is ×1.75 (no ramp); its escort takes ×1.15")
	_check(is_equal_approx(director.get_health_scale(stag, 50), 1.5 * 1.55 * director.get_health_multiplier(stag, 50)),
		"later bosses keep their act's multiplier (act 2's ×1.55)")

	# Selling in a rest what was planted this rest: a full refund (75% once it stood through a drift)
	var sprout: TowerData = placer.towers[0]
	placer.tower_data = sprout
	var cell := _free_cell(map_generator)
	_check(placer._try_build(cell), "built a Sprout")
	var refund := seller.get_refund(seller.get_tower_at(cell))
	_check(refund == sprout.cost, "placed this rest: a full refund (%d)" % refund)
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
	placer.clear_settling()  # Sold during the drift above: the ground would still be settling
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
	_check(rests[0] == [1, false, 44, true], "rest bonus 30 + 4×1 + perfect 10 = 44 (%s)" % [rests[0]])

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
	_check(rests[1] == [2, false, 38, false], "leaky block: 30 + 4×2, no perfect bonus (%s)" % [rests[1]])
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
	# A waiting choice holds the drift (user bug: "I can hide the Dream choice and start the wave").
	var rest_dreams: DreamState = main.get_node("%DreamState")
	_check(director.pending_choice() == &"dream" and not director.can_start_next_drift(), "the Dream waiting behind the boss rest's Remember screen holds the drift too")
	rest_dreams.remember_closed()  # The player closes Remember: the Dream shows
	for i in 30:
		if rest_dreams.is_offering():
			break
		await process_frame
	if rest_dreams.is_offering():
		var dream_screen = main.get_node("HUD/DreamScreen")
		dream_screen.peek.set_peeking(true)  # Minimised to peek at the map
		var started_before := director.drifts_started
		_check(not director.start_next_drift() and director.drifts_started == started_before and director.pending_choice() == &"dream",
			"a minimised Dream offer holds the next drift")
		var panel = main.get_node("HUD/DriftPanel")
		panel._process(0.0)
		_check(panel._start_button.text == "Choose a Dream" and not panel._start_button.disabled, "Start reads Choose a Dream")
		panel._on_start_pressed()
		_check(not dream_screen.peek.peeking and director.drifts_started == started_before, "pressing it reopens the Dream screen")
	else:
		_check(false, "the boss rest offers a Dream")
	await _settle(main)
	_check(acts == [[2, 1]] and run_state.leaves == 11, "act break regrows 1 leaf (%s)" % [acts])
	await _resolve_choices(main)
	director.start_next_drift()
	await _play_until(main, func() -> bool: return not ended.is_empty(), 0, 3000)
	_check(ended == [true] and not director.has_next_drift(), "clearing the last drift wins")
	main.queue_free()
	await process_frame

	# The run is won by dispelling the Hollow Oak (drift 100), in the demo too.
	main = await _new_run()
	director = main.get_node("%DriftDirector")
	run_state = main.get_node("%RunState")
	family = main.get_node("%FamilyPickScreen")
	director.drifts = [all[0], all[99]]
	director.drifts_per_act = 2
	ended.clear()
	run_state.run_ended.connect(func(won: bool) -> void: ended.append(won))
	director.start_next_drift()
	await _play_until(main, func() -> bool: return director.awaiting_family_pick)
	family.choose(family.offer[0])
	director.start_next_drift()
	await _play_until(main, func() -> bool: return not ended.is_empty(), 0, 6000)
	_check(ended == [true] and director.bosses_cleansed == 1, "dispelling the Hollow Oak wins the run")
	var titles := main.get_node("%ResultsScreen").find_children("*", "Label", true, false) \
		.map(func(label: Label) -> String: return label.text)
	_check(titles.has("The Hollow Oak is dispelled"), "the results say the Hollow Oak is dispelled")
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
		var remember := main.get_node_or_null("%RememberScreen") as RememberScreen
		if remember != null and remember.visible:
			remember.close()  # The boss-rest Remember screen: the Dream waits behind it
		var enemies: Array = main.get_node("%EnemyContainer").get_enemies()
		for j in range(leave, enemies.size()):
			enemies[j].take_damage(1000000)
		await process_frame
	_check(false, "timed out waiting (%d frames)" % max_frames)

# Runs rames frames dismissing any Dream / Omen offers, without cleansing anything.
# Makes every waiting choice (a Dream, an Omen shown or queued) so the next drift may start: a
# waiting choice holds it (screens_ui.md "Choice screens").
func _resolve_choices(main: Node) -> void:
	var director: DriftDirector = main.get_node("%DriftDirector")
	var dreams: DreamState = main.get_node("%DreamState")
	for i in 300:
		if director.pending_choice() == &"":
			return
		dreams.remember_closed()  # The boss rest opens Remember first; the Dream waits behind it
		if dreams.is_offering():
			dreams.skip() if dreams.can_skip() else dreams.choose(dreams.current_offer[0])
		var omens = get_first_node_in_group(&"omens")
		if omens != null and (omens.is_offering() or omens.has_pending_offer()) and not dreams.is_offering():
			omens.choose(null)
		await process_frame

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
