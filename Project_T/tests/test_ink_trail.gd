extends SceneTree

var failures := 0
var main: Node
var spawner: Node
var container: Node
var placer: TowerPlacer

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	paused = false
	spawner = main.get_node("%EnemyContainer")
	container = main.get_node("%TowerContainer")
	placer = main.get_node("%TowerPlacer")
	for e in spawner.get_children():
		e.queue_free()
	await process_frame
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/inkcap.tres")
	tower.cell = Vector2(6, 10)
	tower.position = Tower.MAP_GRID.calculate_map_position(tower.cell)
	container.add_child(tower)
	tower.set_process(false)
	var leader = _spawn(Vector2(7, 10))
	tower.hit(leader, 1.0, false, Tower.NO_CRIT)
	var ink := BranchKit.InkField.find(tower)
	ink.set_process(false)
	ink._process(0.25)
	_check(ink.ink_at(Vector2(7, 10)), "real Inkcap hit creates ink")
	var walker = _spawn(Vector2(7, 10))
	ink._process(0.25)
	_check(walker.statuses.stacks(EnemyStatuses.SPORED) == 1, "brief contact applies Poisoned before the shared cell timer")
	_check(walker.statuses.source(EnemyStatuses.SPORED) == tower, "trail Poisoned retains Inkcap ownership")
	# Moving across consecutive ink cells must not multiply its one-stack/second cadence.
	leader.global_position = Tower.MAP_GRID.calculate_map_position(Vector2(8, 10))
	walker.global_position = leader.global_position
	ink._process(0.25)
	_check(walker.statuses.stacks(EnemyStatuses.SPORED) == 1, "crossing to new ink does not bypass cadence")
	for i in 3:
		ink._process(0.25)
	_check(walker.statuses.stacks(EnemyStatuses.SPORED) == 2, "remaining on ink adds another stack after one second")
	var flyer = _spawn(Vector2(8, 10), "crow")
	ink._process(0.25)
	_check(not flyer.statuses.has(EnemyStatuses.SPORED), "ground ink excludes flyers")
	ink.marked.clear()
	for i in 10:
		ink._process(0.25)
	var late = _spawn(Vector2(8, 10))
	ink._process(0.25)
	_check(not late.statuses.has(EnemyStatuses.SPORED), "expired ink cannot poison new walkers")
	# Deliquescent pools keep their half-second cadence after immediate contact.
	tower.evolve(load("res://resource/tower/deliquescent.tres"), 0)
	ink.mark(leader, tower)
	ink._on_dispelled(leader)
	var pool_walker = _spawn(leader.get_current_cell())
	ink._process(0.25)
	_check(pool_walker.statuses.stacks(EnemyStatuses.SPORED) == 1, "pool contact applies Poisoned immediately")
	ink._process(0.25)
	_check(pool_walker.statuses.stacks(EnemyStatuses.SPORED) == 1, "pool does not tick before half a second")
	ink._process(0.25)
	_check(pool_walker.statuses.stacks(EnemyStatuses.SPORED) == 2, "pool retains half-second cadence")
	print("ink trail test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _spawn(cell: Vector2, id: String = "leaf_bug"):
	var enemy = spawner.spawn_enemy(load("res://resource/enemy/%s.tres" % id))
	enemy.set_process(false)
	enemy.global_position = Tower.MAP_GRID.calculate_map_position(cell)
	enemy.max_health = 100000
	enemy.health = 100000
	return enemy

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
