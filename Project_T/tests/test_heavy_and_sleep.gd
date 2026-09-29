extends SceneTree

# Headless test for Mossback, Boulderback (Pebbling branch A) and Dreamshroom (Bloomcap's final form),
# warden_stats.md: ×2 vs Marked, Boulderback's 50% splash and guaranteed crit on Drowsy, Dreamshroom's
# sleep at full Drowsy (once; bosses never). Also their data and evolution links.
#   godot --headless --path . --script res://tests/test_heavy_and_sleep.gd --fixed-fps 60

const CELL := 64.0

var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	# Data: reachable through their families, with art and unlock cards.
	var pebbling: TowerData = load("res://resource/tower/pebbling.tres")
	var mossback: TowerData = load("res://resource/tower/mossback.tres")
	var boulderback: TowerData = load("res://resource/tower/boulderback.tres")
	var bloomcap: TowerData = load("res://resource/tower/bloomcap.tres")
	var dreamshroom: TowerData = load("res://resource/tower/dreamshroom.tres")
	_check(pebbling.evolves_to[0] == mossback and mossback.evolves_to.has(boulderback), "Pebbling → Mossback → Boulderback")
	_check(bloomcap.evolves_to.has(dreamshroom), "Bloomcap → Dreamshroom")
	for data in [mossback, boulderback, dreamshroom]:
		_check(data.texture != null and data.attack_texture != null, "%s has its art" % data.display_name)
		var card := load("res://resource/dream/dream_%s.tres" % data.get_id()) as UpgradeData
		_check(card != null and card.unlocks == data, "%s has an unlock card" % data.display_name)

	# Mossback: ×2 against Marked.
	var moss := _plant(mossback, Vector2(5, 5))
	var plain := _spawn(moss.global_position + Vector2(CELL, 0))
	var marked := _spawn(moss.global_position + Vector2(0, CELL))
	marked.statuses.apply(EnemyStatuses.MARKED)
	moss.hit(plain, 1.0, false, Tower.NO_CRIT)
	moss.hit(marked, 1.0, false, Tower.NO_CRIT)
	_check(_lost(plain) == 138, "Mossback: 138 on a plain nightmare (%d)" % _lost(plain))
	_check(_lost(marked) == int(138 * 2.0 * (1.0 + EnemyStatuses.MARKED_EXTRA)), "×2 on Marked, on top of Marked's +25%% (%d)" % _lost(marked))
	await _clean()

	# Boulderback: full hit on its target, 50% to the rest within 1 cell; always crits on Drowsy.
	var boulder := _plant(boulderback, Vector2(5, 5))
	var target := _spawn(Vector2(12.5, 8.5) * CELL)
	var near := _spawn(target.global_position + Vector2(0.8, 0) * CELL)
	var far := _spawn(target.global_position + Vector2(2, 0) * CELL)
	boulder.projectile_landed(target, target.global_position)
	_check(_lost(target) == 330 and _lost(near) == 165 and _lost(far) == 0,
		"Boulderback: 330 on the target, 165 splash within 1 cell (%d / %d / %d)" % [_lost(target), _lost(near), _lost(far)])
	var sleepy := _spawn(boulder.global_position + Vector2(CELL, 0))
	sleepy.statuses.apply(EnemyStatuses.DROWSY)
	_check(boulder.roll_crit(sleepy), "Boulderback always crits on a Drowsy nightmare")
	await _clean()

	# Dreamshroom: 2 Drowsy per application; at full Drowsy a nightmare sleeps 3 s (status jobs, 2026-09-29), once.
	var shroom := _plant(dreamshroom, Vector2(5, 5))
	var dreamer := _spawn(shroom.global_position + Vector2(CELL, 0))
	for i in 2:
		shroom.apply_status_to(dreamer, shroom.get_damage())
	_check(dreamer.statuses.stacks(EnemyStatuses.DROWSY) == 4 and not dreamer.statuses.is_asleep(), "4 Drowsy: still awake")
	shroom.apply_status_to(dreamer, shroom.get_damage())
	_check(dreamer.statuses.is_asleep() and is_equal_approx(dreamer.statuses.sleep_time, 3.0), "full Drowsy: asleep for 3 s")
	dreamer.statuses.sleep_time = 0.0
	shroom.apply_status_to(dreamer, shroom.get_damage())
	_check(not dreamer.statuses.is_asleep(), "only once per nightmare")
	var boss := _spawn(shroom.global_position + Vector2(0, CELL))
	boss.statuses.is_boss = true
	for i in 3:
		shroom.apply_status_to(boss, shroom.get_damage())
	_check(not boss.statuses.is_asleep(), "bosses never fall asleep")

	print("heavy and sleep test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _lost(enemy: Node2D) -> int:
	return enemy.max_health - enemy.health

func _plant(data: TowerData, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = data.duplicate()
	tower.tower_data.id = data.get_id()
	tower.tower_data.crit_chance = 0.0
	tower.cell = cell
	tower.position = cell * CELL + Vector2(CELL, CELL) / 2
	container.add_child(tower)
	tower.set_process(false)
	return tower

func _spawn(at: Vector2) -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = at
	enemy.max_health = 100000
	enemy.health = 100000
	return enemy

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	for tower in container.get_children():
		tower.queue_free()
	await process_frame
