extends SceneTree

# Headless test for the wall Drowsy cap (warden_stats.md, the Honeysuckle row): Drowsy from walls stops at
# 3 stacks on a nightmare (walls slow but can't put it to sleep alone); a Warden's Drowsy still goes past.
# Honeysuckle grows for 30 Dew. Run from the project folder:
#   godot --headless --path . --script res://tests/test_wall_drowsy.gd --fixed-fps 60

const CELL := 64.0

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var spawner = main.get_node("%EnemyContainer")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var container: Node = main.get_node("%TowerContainer")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame
	_check(load("res://resource/tower/honeysuckle.tres").evolve_cost == 30, "Honeysuckle grows for 30 Dew")

	var honey := _plant(placer, container, "honeysuckle", Vector2(5, 5))
	var bell := _plant(placer, container, "bellflower", Vector2(7, 5))
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy: Node2D = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	for i in 10:
		honey._apply_one_status(enemy, EnemyStatuses.DROWSY, 1, 0.0)
	_check(enemy.statuses.stacks(EnemyStatuses.DROWSY) == Tower.WALL_DROWSY_CAP,
		"a Honeysuckle alone stops at %d Drowsy (%d)" % [Tower.WALL_DROWSY_CAP, enemy.statuses.stacks(EnemyStatuses.DROWSY)])
	_check(not enemy.statuses.is_asleep(), "so it can't put a nightmare to sleep alone")
	for i in 3:
		bell._apply_one_status(enemy, EnemyStatuses.DROWSY, 1, bell.get_damage())
	_check(enemy.statuses.stacks(EnemyStatuses.DROWSY) > Tower.WALL_DROWSY_CAP, "a Warden's Drowsy goes past it (%d)" % enemy.statuses.stacks(EnemyStatuses.DROWSY))
	var stacks: int = enemy.statuses.stacks(EnemyStatuses.DROWSY)
	honey._apply_one_status(enemy, EnemyStatuses.DROWSY, 1, 0.0)
	_check(enemy.statuses.stacks(EnemyStatuses.DROWSY) == stacks, "and the wall doesn't lower it (%d)" % enemy.statuses.stacks(EnemyStatuses.DROWSY))

	print("wall drowsy test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _plant(placer: TowerPlacer, container: Node, id: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = cell * CELL + Vector2(CELL, CELL) / 2
	container.add_child(tower)
	tower.set_process(false)
	return tower

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
