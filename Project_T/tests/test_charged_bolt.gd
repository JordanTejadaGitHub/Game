extends SceneTree

# Headless test for the Charged bolt's look (screens_ui.md "In the world", row "Charged bolt"; user: "should
# there be a visual when the charged pops"): a strike shows a ChargedBolt in the world (not under
# %EnemyContainer), emits ReactionTracker.bolt_struck for Sound, and its damage number is the bolt kind
# (larger, warm, with a glyph); past the budget (6 per 0.25 s) only the flash plays; Static Field adds its ring.
#   godot --headless --path . --script res://tests/test_charged_bolt.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var spawner = main.get_node("%EnemyContainer")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame
	var damage_log: DamageLog = main.get_node("%DamageLog")
	damage_log.numbers_mode = DamageLog.NumbersMode.ALL
	var enemy: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	enemy.set_process(false)
	enemy.max_health = 100000
	enemy.health = 100000
	enemy.coat = 0.0
	var struck := []
	var tracker := ReactionTracker.find(enemy)
	tracker.bolt_struck.connect(func(at: Vector2, damage: float) -> void: struck.append([at, damage]))
	await create_timer(0.3).timeout  # A fresh budget window
	Reactions.strike_bolt(enemy, 30.0, null)
	var world := tracker.get_parent()
	var bolts: Array = world.get_children().filter(func(n: Node) -> bool: return n is ChargedBolt)
	_check(bolts.size() == 1 and bolts[0]._bolt, "a strike shows a bolt in the world (%d)" % bolts.size())
	_check(not spawner.get_children().any(func(n: Node) -> bool: return n is ChargedBolt), "never under the EnemyContainer")
	_check(struck.size() == 1 and struck[0][0].is_equal_approx(enemy.global_position), "bolt_struck fires for Sound (%s)" % [struck])
	var numbers: Array = damage_log.get_children().filter(func(n: Node) -> bool: return n is DamageLog.FloatingNumber)
	_check(numbers.any(func(n) -> bool: return n.bolt and n._size >= 16), "its damage number is the larger bolt kind")
	for i in 9:
		Reactions.strike_bolt(enemy, 30.0, null)
	bolts = world.get_children().filter(func(n: Node) -> bool: return n is ChargedBolt)
	var drawn: int = bolts.filter(func(b) -> bool: return b._bolt).size()
	_check(drawn == ChargedBolt.BUDGET and bolts.size() == 10, "past %d bolts in 0.25 s only the flash plays (%d bolts of %d)" % [ChargedBolt.BUDGET, drawn, bolts.size()])
	for i in 20:
		await process_frame
	_check(world.get_children().filter(func(n: Node) -> bool: return n is ChargedBolt).is_empty(), "they fade out")
	var ring := ChargedBolt.strike(Vector2(100, 100), world, 96.0)
	_check(ring != null and ring._field == 96.0, "Static Field: a ring to its reach")

	print("charged bolt test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
