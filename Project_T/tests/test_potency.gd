extends SceneTree

# Headless test for Potency (tower_design.md "Potency: effect damage"): effect damage × the source
# Warden's Potency, hits untouched, the Deep Focus as Potency, and Endless Rings' rank caps (speed and
# range stop at VII, Focus at V). Run from the project folder:
#   godot --headless --path . --script res://tests/test_potency.gd --fixed-fps 60

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

	var puffball := _plant("puffball", Vector2(2, 2))
	puffball.tower_data = puffball.tower_data.duplicate()  # The mechanism at Potency 130% (Puffball itself is 100% since "Human run 3")
	puffball.tower_data.potency = 1.3
	puffball._apply_data()
	var sprout := _plant("sprout", Vector2(2, 4))
	_check(is_equal_approx(puffball.get_potency(), 1.3), "Puffball: Potency 130%% (%.2f)" % puffball.get_potency())
	_check(is_equal_approx(sprout.get_potency(), 1.0), "the default is 100%")

	# Effects scale with the source's Potency; hits don't.
	var a := _spawn(Vector2(12.5, 8.5) * CELL)
	a.take_damage(100.0, "", true, false, puffball, &"spored")
	_check(_lost(a) == 130, "a Spored tick from the Puffball deals 130 (%d)" % _lost(a))
	var b := _spawn(Vector2(12.5, 9.5) * CELL)
	b.take_damage(100.0, "", false, false, puffball, &"")
	_check(_lost(b) == 100, "a hit is untouched by Potency (%d)" % _lost(b))
	var c := _spawn(Vector2(12.5, 10.5) * CELL)
	c.take_damage(100.0, "", true, false, puffball, &"thunderclap")
	_check(_lost(c) == 130, "Reactions use the applier's Potency (%d)" % _lost(c))

	# Deep ranks (Nurture v3): +18% Potency each rank chosen.
	sprout.rank = 3
	sprout.rank_choices = [Tower.Focus.DEEP, Tower.Focus.POWER, Tower.Focus.DEEP]
	_check(is_equal_approx(sprout.get_potency(), 1.0 + 2 * Tower.deep_share()), "two Deep ranks: +50%% Potency (%.2f)" % sprout.get_potency())
	sprout.rank = 0
	sprout.rank_choices = []

	# Endless Rings: ranks past VII add only damage.
	sprout.focus = Tower.Focus.NONE
	sprout.rank = 7
	var speed_7 := sprout.get_attacks_per_second()
	var range_7 := sprout.get_range_cells()
	var damage_7 := sprout.get_damage()
	sprout.rank = 10
	_check(is_equal_approx(sprout.get_attacks_per_second(), speed_7), "attack speed stops at rank VII")
	_check(is_equal_approx(sprout.get_range_cells(), range_7), "range stops at rank VII")
	_check(sprout.get_damage() > damage_7 * 1.1, "damage keeps growing past VII")

	print("potency test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _lost(enemy: Node2D) -> int:
	return enemy.max_health - enemy.health

func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
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
	enemy.max_health = 1000000
	enemy.health = 1000000
	enemy.coat = 0.0
	return enemy
