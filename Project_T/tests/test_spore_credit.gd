extends SceneTree

# Headless test for fair Spored credit (balance_simulation.md "Human run 2"): all stacks still tick at the
# strongest applier's potency, but DamageLog splits each tick's credit by the appliers' shares of the
# stacks, and the fog-boosted part goes to the fog's Warden. Run from the project folder:
#   godot --headless --path . --script res://tests/test_spore_credit.gd --fixed-fps 60

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
	var log := DamageLog.instance

	var sporeling := _plant(placer, container, "sporeling", Vector2(2, 2))
	var puffball := _plant(placer, container, "puffball", Vector2(4, 2))
	var veil := _plant(placer, container, "mistveil", Vector2(6, 2))
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy: Node2D = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.max_health = 1000000
	enemy.health = 1000000

	# 3 stacks from the Sporeling, then 1 from the stronger Puffball: the Puffball's potency for all.
	enemy.apply_status(EnemyStatuses.SPORED, 3, 10.0, sporeling.get_damage(), 0, "spore", sporeling)
	enemy.apply_status(EnemyStatuses.SPORED, 1, 10.0, puffball.get_damage() * 2.0, 0, "spore", puffball)
	_check(enemy.statuses.source(EnemyStatuses.SPORED) == puffball, "the strongest applier still sets the potency (and is the source)")
	var credit: Array = enemy.statuses.spore_credit()
	var shares := {}
	for part in credit:
		shares[part[0]] = part[1]
	_check(is_equal_approx(shares.get(sporeling, 0.0), 0.75) and is_equal_approx(shares.get(puffball, 0.0), 0.25),
		"the stacks' shares: Sporeling 3/4, Puffball 1/4")

	var before_s: float = log.get_tower_stats(sporeling).get("run", 0.0)
	var before_p: float = log.get_tower_stats(puffball).get("run", 0.0)
	for i in 120:
		enemy._process(1.0 / 60.0)  # Two seconds of ticks
	var got_s: float = log.get_tower_stats(sporeling).get("run", 0.0) - before_s
	var got_p: float = log.get_tower_stats(puffball).get("run", 0.0) - before_p
	_check(got_s > 0.0 and absf(got_s / (got_s + got_p) - 0.75) < 0.02,
		"Spored ticks are credited 75/25 (Sporeling %.0f, Puffball %.0f)" % [got_s, got_p])

	# In Mistveil's fog: the fog-boosted part goes to Mistveil.
	enemy.statuses.set_in_fog(5.0, veil)
	var before_v: float = log.get_tower_stats(veil).get("run", 0.0)
	before_s = log.get_tower_stats(sporeling).get("run", 0.0)
	before_p = log.get_tower_stats(puffball).get("run", 0.0)
	for i in 60:
		enemy._process(1.0 / 60.0)
	var fog_part: float = log.get_tower_stats(veil).get("run", 0.0) - before_v
	var rest: float = log.get_tower_stats(sporeling).get("run", 0.0) - before_s + log.get_tower_stats(puffball).get("run", 0.0) - before_p
	var expected := EnemyStatuses.FOG_SPORE_BONUS / (1.0 + EnemyStatuses.FOG_SPORE_BONUS)
	_check(fog_part > 0.0 and absf(fog_part / (fog_part + rest) - expected) < 0.03,
		"in fog, the boosted part (%.0f%%) goes to Mistveil (got %.0f%%)" % [expected * 100, 100.0 * fog_part / maxf(fog_part + rest, 0.001)])

	print("spore credit test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
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
