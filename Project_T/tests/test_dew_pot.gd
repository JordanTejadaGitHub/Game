extends SceneTree

# The Dew pot (run_design.md "The Dew pot", 2026-10-01): each drift's Dew is a fixed pot split across its
# nightmares by weight. Checks: the shares sum to the pot; an elite gets 3× a normal share; a boss drift's
# boss takes half; added nightmares (Crowded Paths) don't change the total; a drift's dispels pay its pot
# and a leak loses exactly its share; followers share their leader's share.

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	run_state.invulnerable = true
	var shade: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var husk: EnemyData = load("res://resource/enemy/bark_beetle.tres")
	var boss: EnemyData = load("res://resource/enemy/old_stag.tres")

	# Weights: dew_reward, Deeply Blighted ×3; the shares always sum to the pot.
	var schedule := [[0.0, shade, false], [1.0, shade, true], [2.0, husk, false]]
	var pot := director.get_effective_pot(12)
	var shares: Array = director.pot_shares(schedule, 12)
	var total := 0.0
	for s in shares:
		total += s
	_check(is_equal_approx(total, pot), "the shares sum to the pot (%.2f of %.2f)" % [total, pot])
	_check(is_equal_approx(shares[1], shares[0] * 3.0), "a Deeply Blighted nightmare gets 3× a normal share")
	_check(is_equal_approx(shares[2] / shares[0], float(husk.dew_reward) / shade.dew_reward), "bigger nightmares a bigger share (by dew_reward)")
	# Added nightmares (Crowded Paths, extra_nightmares) share the same pot: more nightmares, same total.
	var crowded := schedule.duplicate()
	for i in 6:
		crowded.append([3.0 + i, shade, false])
	var crowded_total := 0.0
	for s in director.pot_shares(crowded, 12):
		crowded_total += s
	_check(is_equal_approx(crowded_total, pot), "added nightmares share the pot: the total stays %.0f" % pot)
	# A boss drift: the boss takes half, the escorts share the rest.
	var boss_shares: Array = director.pot_shares([[0.0, boss, false], [1.0, shade, false], [2.0, shade, false]], 25)
	_check(is_equal_approx(boss_shares[0], director.get_effective_pot(25) * 0.5) and is_equal_approx(boss_shares[1], boss_shares[2]),
		"a boss drift's boss takes half its pot (%.0f of %.0f)" % [boss_shares[0], director.get_effective_pot(25)])
	# Bountiful Night (Roguelite's Omen hook): pot ×2, once the hook exists.
	# Rich Dew (Grove dew_gain, +5% a level) multiplies the pot: level 1 = a drift's dispels 5% more in total.
	run_state.dew_gain_bonus = 0.05
	var rich_total := 0.0
	for s in director.pot_shares(schedule, 12):
		rich_total += s
	run_state.dew_gain_bonus = 0.0
	_check(is_equal_approx(rich_total, total * 1.05), "Rich Dew level 1: the drift's shares total 5%% more (%.2f vs %.2f)" % [rich_total, total])
	var omens := main.get_node("%OmenDirector")
	if omens.has_method("get_dew_pot_multiplier"):
		for omen in omens.all_omens() if omens.has_method("all_omens") else []:
			if omen.id == "bountiful_night":
				omens.active = omen
				omens.active_block = director.get_block(12)
				_check(is_equal_approx(director.get_effective_pot(12), director.get_dew_pot(12) * 2.0), "Bountiful Night doubles the pot")
				omens.active = null

	# A real drift: every dispel pays its share; a leak loses exactly its own.
	director.block_pot = 0.0
	run_state.pot_earned_block = 0.0
	run_state._dispel_dew_carry = 0.0
	director.drifts_started = 11
	director.resting = false
	director._start_drift()  # Drift 12
	var drift_pot := director.block_pot
	var spawner = main.get_node("%EnemyContainer")
	var leaked_share := -1.0
	for i in 2400:  # Until it has all arrived (40 s at 60 fps)
		await process_frame
		for enemy in spawner.get_enemies().duplicate():
			if enemy.is_cleansed:
				continue
			if leaked_share < 0.0:
				leaked_share = enemy.get_dew_share()  # The first one leaks
				spawner.enemy_reached_goal.emit(enemy)
				enemy.queue_free()
			else:
				enemy.take_damage(enemy.max_health * 1000.0)
		if not director.is_arriving() and spawner.get_enemies().is_empty():
			break
	_check(drift_pot > 0.0 and is_equal_approx(run_state.pot_earned_block + leaked_share, drift_pot),
		"a drift's dispels pay its pot, less exactly the leaked share (%.2f + %.2f of %.2f)" % [run_state.pot_earned_block, leaked_share, drift_pot])

	# Followers: a leader with followers keeps half, its followers share the other half (Enemy.set_dew_share).
	var bearer: EnemyData = load("res://resource/enemy/mother_duck.tres")
	if bearer.followers != null and bearer.follower_count > 0:
		director._active[13] = {"remaining": 0, "arriving": false, "leaked": false}
		director._spawn(bearer, 13, false, 40.0)
		await process_frame
		var leader = spawner.get_enemies().filter(func(e) -> bool: return e.enemy_data == bearer).front()
		var sum: float = leader.dew_share
		for f in leader.dew_followers:
			sum += f.dew_share
		_check(is_equal_approx(sum, 40.0), "a leader and its followers share its 40 Dew (%.2f)" % sum)

	print("dew pot test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("ok  " + label)
	else:
		failures += 1
		printerr("FAIL: " + label)
