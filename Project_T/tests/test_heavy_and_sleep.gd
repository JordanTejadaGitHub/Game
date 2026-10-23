extends SceneTree

# Headless test for Mossback, Boulderback (Pebbling branch A) and Dreamshroom (Bloomcap's final form),
# warden_stats.md: ×2 vs completed Exposed, Boulderback's splash and guaranteed crit on Drowsy, Dreamshroom's
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
	var partial := _spawn(moss.global_position + Vector2(-CELL, 0))
	partial.statuses.apply(EnemyStatuses.MARKED, partial.statuses.get_max_stacks(EnemyStatuses.MARKED) - 1)
	moss.hit(partial, 1.0, false, Tower.NO_CRIT)
	marked.statuses.apply(EnemyStatuses.MARKED, marked.statuses.get_max_stacks(EnemyStatuses.MARKED))
	moss.hit(plain, 1.0, false, Tower.NO_CRIT)
	moss.hit(marked, 1.0, false, Tower.NO_CRIT)
	var moss_damage: float = moss.get_damage()
	_check(is_equal_approx(_lost(partial), moss_damage), "partial Exposed does not activate vulnerability or Marked Blow")
	_check(is_equal_approx(_lost(plain), moss_damage), "Mossback: its damage on a plain nightmare (%d)" % _lost(plain))
	_check(is_equal_approx(_lost(marked), moss_damage * 2.0 * (1.0 + EnemyStatuses.MARKED_EXTRA)), "×2 on Marked, on top of Marked's +25%% (%d)" % _lost(marked))
	await _clean()

	# Boulderback: full hit on its target, configured splash share within 1 cell; always crits on Drowsy.
	var boulder := _plant(boulderback, Vector2(5, 5))
	var target := _spawn(Vector2(12.5, 8.5) * CELL)
	var near := _spawn(target.global_position + Vector2(0.8, 0) * CELL)
	var far := _spawn(target.global_position + Vector2(2, 0) * CELL)
	boulder.projectile_landed(target, target.global_position)
	var form: float = boulder._form_hit_multiplier()  # x1.4: Boulderback is a hit final (e57b2a99); its splash is its own direct hit
	_check(is_equal_approx(_lost(target), boulderback.damage * form) and is_equal_approx(_lost(near), boulderback.damage * boulderback.splash_share * form) and _lost(far) == 0,
		"Boulderback: its damage on the target, splash_share within 1 cell (%d / %d / %d)" % [_lost(target), _lost(near), _lost(far)])
	var sleepy := _spawn(boulder.global_position + Vector2(CELL, 0))
	sleepy.statuses.apply(EnemyStatuses.DROWSY)
	_check(boulder.roll_crit(sleepy), "Boulderback always crits on a Drowsy nightmare")
	await _clean()

	# Dreamshroom: native application reaches full Drowsy, sleeps for configured duration, once.
	var shroom := _plant(dreamshroom, Vector2(5, 5))
	var dreamer := _spawn(shroom.global_position + Vector2(CELL, 0))
	var sleep_cap: int = dreamer.statuses.get_max_stacks(EnemyStatuses.DROWSY)
	dreamer.statuses.apply(EnemyStatuses.DROWSY, sleep_cap - dreamshroom.status_stacks)
	_check(not dreamer.statuses.is_asleep(), "below full Drowsy: still awake")
	shroom.apply_status_to(dreamer, shroom.get_damage())
	_check(dreamer.statuses.is_asleep() and is_equal_approx(dreamer.statuses.sleep_time, dreamshroom.sleep_at_max_drowsy), "full Drowsy: asleep for its sleep_at_max_drowsy")
	dreamer.statuses.sleep_time = 0.0
	shroom.apply_status_to(dreamer, shroom.get_damage())
	_check(not dreamer.statuses.is_asleep(), "only once per nightmare")
	var boss := _spawn(shroom.global_position + Vector2(0, CELL))
	boss.statuses.is_boss = true
	for i in ceili(float(boss.statuses.get_max_stacks(EnemyStatuses.DROWSY)) / dreamshroom.status_stacks):
		shroom.apply_status_to(boss, shroom.get_damage())
	_check(boss.statuses.stacks(EnemyStatuses.DROWSY) == boss.statuses.get_max_stacks(EnemyStatuses.DROWSY) and not boss.statuses.is_asleep(), "bosses never fall asleep even at full Drowsy")

	print("heavy and sleep test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _lost(enemy: Node2D) -> float:
	return float(enemy.max_health - enemy.health) + enemy._soothe_carry

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
