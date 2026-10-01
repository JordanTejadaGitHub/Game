extends SceneTree

# Headless test for "Slow and sleep have limits" (tower_design.md, 2026-10-01): all slows together
# never take a nightmare below 50% of its speed (elites 60%, bosses 70%); after waking it can't fall
# Asleep again for 4 s (bosses 8 s); after a Hold ends it can't be Held again for 1.5 s (bosses 3 s),
# except Snare's release-pull Hold in the very frame the Hold ended. Run from the project folder:
#   godot --headless --path . --script res://tests/test_status_limits.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	# EnemyStatuses is a RefCounted: no scene needed.
	var s := EnemyStatuses.new()
	s.apply(EnemyStatuses.DROWSY, 5)
	s.slow_time = 5.0
	s.slow_amount = 0.6
	_check(is_equal_approx(s.get_speed_multiplier(), EnemyStatuses.SLOW_FLOOR) and s.slow_capped,
		"slows stack to the 50%% floor, flagged as capped (%.2f)" % s.get_speed_multiplier())
	s.is_elite = true
	_check(is_equal_approx(s.get_speed_multiplier(), EnemyStatuses.SLOW_FLOOR_ELITE), "elites: 60%")
	s.is_elite = false
	s.is_boss = true
	_check(is_equal_approx(s.get_speed_multiplier(), EnemyStatuses.SLOW_FLOOR_BOSS), "bosses: 70%")
	s.is_boss = false
	var light := EnemyStatuses.new()
	light.apply(EnemyStatuses.DROWSY, 1)
	_check(light.get_speed_multiplier() > EnemyStatuses.SLOW_FLOOR and not light.slow_capped, "a light slow isn't touched")

	# Sleep cooldown
	var sleeper := EnemyStatuses.new()
	_check(sleeper.sleep(2.0) and sleeper.is_asleep(), "it falls asleep")
	for i in 3:
		sleeper.tick(1.0)
	_check(not sleeper.is_asleep() and sleeper.sleep_cooldown > 0.0, "it wakes, with a breather")
	_check(not sleeper.sleep(2.0) and not sleeper.is_asleep(), "it can't fall asleep again right away")
	sleeper.apply(EnemyStatuses.DROWSY, 3)
	_check(sleeper.stacks(EnemyStatuses.DROWSY) == 3, "Drowsy still stacks meanwhile")
	for i in 5:
		sleeper.tick(1.0)
	_check(sleeper.sleep(1.0), "after 4 s it can sleep again")

	# Hold cooldown
	var held := EnemyStatuses.new()
	held.apply(EnemyStatuses.HELD, 1, 1.0)
	_check(held.is_held(), "it's Held")
	held.tick(1.1)
	_check(not held.is_held() and held.hold_cooldown > 0.0, "the Hold ends, with a breather")
	held.apply(EnemyStatuses.HELD, 1, 1.0)
	_check(held.is_held(), "a Hold in the very frame the last one ended still lands (Snare's release pull)")
	held.tick(1.1)
	held.tick(0.1)
	held.apply(EnemyStatuses.HELD, 1, 1.0)
	_check(not held.is_held(), "a later Hold within 1.5 s doesn't")
	for i in 2:
		held.tick(1.0)
	held.apply(EnemyStatuses.HELD, 1, 1.0)
	_check(held.is_held(), "after the breather it can be Held again")
	held.apply(EnemyStatuses.HELD, 1, 3.0)
	_check(held.time_left(EnemyStatuses.HELD) > 2.5, "an ongoing Hold can still be stretched")

	print("status limits test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
