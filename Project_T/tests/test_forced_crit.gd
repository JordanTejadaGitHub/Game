extends SceneTree

# Headless test for the Calling evolutions' forced crit (evo_shared_spec.md 5 and X3, dream_council_review.md 33): a forced
# crit deals the Warden's own crit multiplier only (no Keen ranks), is still a crit for the hit's report, and the hook stays
# off with its flag off. Tower.force_calling_crit stands in for a Calling row (Roguelite Code's Firefly rule fills
# DreamState.calling_crit later).
#   godot --headless --path . --script res://tests/test_forced_crit.gd --fixed-fps 60

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

	var jar := _plant(load("res://resource/tower/firefly_jar.tres"), Vector2(5, 5))
	var own_crit: float = jar.attack_data.crit_multiplier if jar.attack_data.crit_multiplier > 1.0 else 2.0

	# Flag off: no forced crit (crit_chance 0, so a rolled hit never crits).
	Tower.force_calling_crit = false
	var plain := _spawn(jar.global_position + Vector2(CELL, 0))
	var crit_off := jar.hit(plain, 1.0, false, Tower.ROLL_CRIT)
	var base := _lost(plain)
	_check(not crit_off and base > 0.0, "flag off: the hook never forces a crit (%d)" % base)

	# Forced: the Warden's own crit multiplier only.
	Tower.force_calling_crit = true
	var forced_target := _spawn(jar.global_position + Vector2(0, CELL))
	var crit_on := jar.hit(forced_target, 1.0, false, Tower.ROLL_CRIT)
	_check(crit_on, "a forced crit is still a crit for the hit (Critical! and crit_landed)")
	_check(absf(_lost(forced_target) - base * own_crit) <= 1.0, "a forced crit deals its own crit multiplier x%.1f (%d vs %d)" % [own_crit, _lost(forced_target), base * own_crit])

	# Keen ranks add crit damage to a real crit, never to a forced one.
	jar.rank = 1
	var keen: Array[int] = [Tower.Focus.KEEN]
	jar.rank_choices = keen
	jar.clear_dream_cache()
	Tower.force_calling_crit = false
	var keen_plain := _spawn(jar.global_position + Vector2(-CELL, 0))
	jar.hit(keen_plain, 1.0, false, Tower.NO_CRIT)
	var keen_base := _lost(keen_plain)
	var real := _spawn(jar.global_position + Vector2(0, -CELL))
	jar.hit(real, 1.0, false, Tower.CRIT)
	Tower.force_calling_crit = true
	var keen_forced := _spawn(jar.global_position + Vector2(CELL, CELL))
	jar.hit(keen_forced, 1.0, false, Tower.ROLL_CRIT)
	_check(_lost(real) > keen_base * own_crit + 1.0, "a real crit gets the Keen rank's crit damage (%d)" % _lost(real))
	_check(absf(_lost(keen_forced) - keen_base * own_crit) <= 1.0, "a forced crit skips Keen (%d vs %d)" % [_lost(keen_forced), keen_base * own_crit])

	# A Pinned / Shatter hit is never forced (the hook only takes plain direct hits): an effect tick neither.
	var tick_target := _spawn(jar.global_position + Vector2(-CELL, CELL))
	jar.hit(tick_target, 1.0, true, Tower.ROLL_CRIT, &"cloud", false)
	_check(_lost(tick_target) > 0.0 and _lost(tick_target) < keen_base * own_crit - 1.0, "an effect tick is never forced (%d)" % _lost(tick_target))

	Tower.force_calling_crit = false
	await _clean()
	print("forced crit test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
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
