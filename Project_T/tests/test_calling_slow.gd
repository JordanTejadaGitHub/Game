extends SceneTree
# class_kit.calling_slow: the one capped Calling slow (owner 2026-10-23, dream_council_review.md 33; evo_shared_spec.md 7, 9).
# Written 2026-10-23, parse-checked, NOT RUN (the owner runs tests on request).
#   godot --headless --fixed-fps 60 --path . --script res://tests/test_calling_slow.gd

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var spawner: Node = main.get_node("%EnemyContainer")
	var dreams: DreamState = main.get_node("%DreamState")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame
	var kit = dreams.puddles
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)

	# Two rows' requests in one poll: one slow, capped at 0.35
	kit.calling_slow(enemy, 0.20)
	kit.calling_slow(enemy, 0.25)
	kit._apply_calling_slows()
	var slows: Array = enemy.statuses.timed_slows
	_check(slows.size() == 1, "one timed slow per nightmare per poll (%d)" % slows.size())
	_check(not slows.is_empty() and is_equal_approx(float(slows[0][0] if slows[0] is Array else slows[0].amount), 0.35), "0.20 + 0.25 is capped at 0.35")
	_check(kit._slow_requests.is_empty(), "the requests clear after the poll")

	# A boss: half the cap
	enemy.enemy_data = enemy.enemy_data.duplicate()
	enemy.enemy_data.is_boss = true
	enemy.statuses.is_boss = true
	enemy.statuses.timed_slows.clear()
	kit.calling_slow(enemy, 0.5)
	kit._apply_calling_slows()
	slows = enemy.statuses.timed_slows
	_check(not slows.is_empty() and is_equal_approx(float(slows[0][0] if slows[0] is Array else slows[0].amount), 0.175), "a boss: at most 0.175")

	print("test_calling_slow: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)
