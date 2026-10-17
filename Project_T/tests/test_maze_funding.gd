extends SceneTree
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + text)
func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var director: DriftDirector = main.get_node("%DriftDirector")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var run: RunState = main.get_node("%RunState")
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	var wall: TowerData = load("res://resource/tower/thornwall.tres")
	_check(placer.get_cost(sprout) == 10, "Sprouts start at 10 Dew")
	_check(run.starting_dew - 5 * placer.get_cost(sprout) >= 3 * placer.get_cost(wall), "opening funds five attackers plus three maze walls")
	_check(TowerPlacer.SPROUT_STEP_DEW == 5 and TowerPlacer.SPROUTS_PER_STEP == 5, "Sprout escalation: +5 every 5 (Balancing 2026-10-16; was +4 every 10 in the Health x2, Dew x2 trial; it was every 5)")
	var shade: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var boss: EnemyData = load("res://resource/enemy/old_stag.tres")
	_check(is_equal_approx(director.get_health_scale(shade, 1), director.trial_health_at(1)), "drift-one health remains unchanged")
	_check(is_equal_approx(director.get_health_scale(shade, 24), director.get_growth(24) * director.get_early_multiplier(24) * 1.05 * director.trial_health_multiplier), "ordinary health ramps to five percent extra by drift24")
	_check(is_equal_approx(director.get_health_scale(shade, 26), director.get_growth(26) * director.get_early_multiplier(26) * director.trial_health_multiplier), "Act2 health has no additional increase")
	_check(is_equal_approx(director.get_health_scale(boss, 25), director.act1_boss_health_multiplier * director.trial_health_multiplier), "boss health remains unchanged")
	_check(is_equal_approx(director.get_dew_pot(10), lerpf(30.0,115.0,9.0/23.0) * director.trial_dew_multiplier), "opening drift income remains unchanged")
	_check(is_equal_approx(director.get_dew_pot(11), lerpf(30.0,115.0,10.0/23.0)*1.15 * director.trial_dew_multiplier), "Act1 kill pot increases fifteen percent from drift11")
	_check(is_equal_approx(director.get_dew_pot(26),103.5*1.2 * director.trial_dew_multiplier), "Act2 kill pot increases twenty percent")
	_check(is_equal_approx(director.get_dew_pot(51),121.5 * director.trial_dew_multiplier), "later-act kill income remains unchanged")
	_check(is_equal_approx(director.get_dew_pot(25),220.0 * director.trial_dew_multiplier), "boss pot remains unchanged")
	_check(Tower.rank_costs == [30,48,60,90,135], "Nurture prices do not consume the extra maze budget")
	main.queue_free()
	await process_frame
	print("maze funding test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)
