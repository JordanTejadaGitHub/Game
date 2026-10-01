extends SceneTree

# Headless test for AreaHitQueue (perf, stacked late drifts): area hits past BUDGET in one frame land at the
# start of the next frame with the same numbers; single-target hits are never deferred.
#   godot --headless --path . --script res://tests/test_area_hit_queue.gd --fixed-fps 60

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
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/rootling.tres").duplicate()
	tower.tower_data.crit_chance = 0.0
	tower.cell = Vector2(3, 3)
	tower.position = Tower.MAP_GRID.calculate_map_position(tower.cell)
	main.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	var enemies: Array = []
	for i in 40:
		var enemy: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
		enemy.set_process(false)
		enemy.max_health = 100000
		enemy.health = 100000
		enemy.coat = 0.0
		enemies.append(enemy)
	await process_frame
	var single := enemies[0] as Node2D
	for enemy in enemies:
		tower.hit(enemy, 1.0, true, Tower.NO_CRIT)
	var hit_now: int = enemies.filter(func(e) -> bool: return e.health < e.max_health).size()
	_check(hit_now == AreaHitQueue.BUDGET, "a 40-target burst lands %d hits this frame (%d)" % [AreaHitQueue.BUDGET, hit_now])
	var queue := AreaHitQueue.find(tower)
	_check(queue.pending() == 40 - AreaHitQueue.BUDGET, "the rest wait (%d)" % queue.pending())
	var before: int = single.health
	tower.hit(single, 1.0, false, Tower.NO_CRIT)
	_check(single.health < before, "a single-target hit is never deferred")
	await process_frame
	await process_frame
	var all_hit: int = enemies.filter(func(e) -> bool: return e.health < e.max_health).size()
	_check(all_hit == 40 and queue.pending() == 0, "next frame every nightmare has been hit (%d)" % all_hit)
	var amounts: Array = enemies.slice(1).map(func(e) -> int: return e.max_health - e.health)
	_check(amounts.all(func(a: int) -> bool: return a == amounts[0]), "every deferred hit dealt the same as the immediate ones (%s)" % [amounts.slice(0, 3)])

	print("area hit queue test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
