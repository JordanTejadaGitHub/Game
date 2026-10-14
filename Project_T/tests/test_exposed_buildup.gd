extends SceneTree

var failures := 0
func _initialize() -> void:
	var status := EnemyStatuses.new()
	_check(status.get_max_stacks(EnemyStatuses.MARKED) == 10, "Exposed has ten buildup stacks")
	status.apply(EnemyStatuses.MARKED, 9)
	_check(is_equal_approx(status.get_damage_taken_multiplier(), 1.0), "nine Exposed stacks give no damage bonus")
	status.apply(EnemyStatuses.MARKED, 1)
	_check(is_equal_approx(status.get_damage_taken_multiplier(), 1.25), "the tenth stack activates the existing 25% bonus")
	status.tick(5.1)
	_check(is_equal_approx(status.get_damage_taken_multiplier(), 1.0), "the damage bonus ends when Exposed drains below ten")
	var bright := EnemyStatuses.new()
	bright.marked_bonus = 0.05
	bright.apply(EnemyStatuses.MARKED, 1)
	_check(is_equal_approx(bright.get_damage_taken_multiplier(), 1.0), "Bright Marks cannot bypass the buildup requirement")
	bright.apply(EnemyStatuses.MARKED, 9)
	_check(is_equal_approx(bright.get_damage_taken_multiplier(), 1.30), "Bright Marks retains its stronger completed bonus")
	print("Exposed buildup test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)