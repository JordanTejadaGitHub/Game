extends SceneTree

# Headless test for chain falloff (tower_design.md "Chain falloff"): from the 6th link of a chain each
# Reaction deals 15% less than the one before, never below 25%; only Reaction damage, never Dawnbreak;
# the chain itself still counts every link. Run from the project folder:
#   godot --headless --path . --script res://tests/test_chain_falloff.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	# The curve
	for chain in range(1, 6):
		_check(is_equal_approx(Reactions.chain_falloff_at(chain), 1.0), "link %d: full damage" % chain)
	_check(is_equal_approx(Reactions.chain_falloff_at(6), 0.85), "6th link ×0.85")
	_check(is_equal_approx(Reactions.chain_falloff_at(7), 0.70), "7th link ×0.70")
	_check(is_equal_approx(Reactions.chain_falloff_at(10), 0.25), "10th link: the floor, ×0.25")
	_check(is_equal_approx(Reactions.chain_falloff_at(120), 0.25), "never below 25%% (chain 120)")

	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var spawner = main.get_node("%EnemyContainer")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy: Node2D = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)

	# Off the nightmare's chain mark, Reaction tags only
	_check(is_equal_approx(Reactions.chain_falloff(enemy, &"thunderclap"), 1.0), "no chain: full damage")
	enemy.statuses.mark_chain(7, [], 1.0)
	_check(is_equal_approx(Reactions.chain_falloff(enemy, &"thunderclap"), 0.70), "on a 7-link chain a Thunderclap deals ×0.70")
	_check(is_equal_approx(Reactions.chain_falloff(enemy, &"shatter"), 0.70), "Shatter too")
	_check(is_equal_approx(Reactions.chain_falloff(enemy, &"dawnbreak"), 1.0), "Dawnbreak isn't reduced")
	_check(is_equal_approx(Reactions.chain_falloff(enemy, &""), 1.0) and is_equal_approx(Reactions.chain_falloff(enemy, &"spored"), 1.0),
		"plain hits and status ticks aren't reduced")
	enemy.statuses.chain_time = 0.0
	_check(is_equal_approx(Reactions.chain_falloff(enemy, &"thunderclap"), 1.0), "an expired chain mark: full damage again")

	print("chain falloff test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
