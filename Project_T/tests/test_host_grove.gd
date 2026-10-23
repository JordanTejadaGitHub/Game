extends SceneTree

# Headless test for Host Grove's Potency read (evo_shared_spec.md 7, dream_council_review.md 33): Reactions.effect_multiplier
# takes DreamState.calling_potency on effect damage (a Poisoned tick x1.3, Deathcap and Thick Haze are effect tags), never
# on a Reaction's tag, and with Undiluted the larger of the two, not their product. Reactions.force_host_potency stands in
# for the Sporeling row (Roguelite Code fills calling_potency later).
#   godot --headless --path . --script res://tests/test_host_grove.gd --fixed-fps 60

const CELL := 64.0
const HOST := 1.3

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

	var spore := _plant(load("res://resource/tower/sporeling.tres"), Vector2(5, 5))
	var enemy := _spawn(spore.global_position + Vector2(CELL, 0))
	_check(Reactions.is_effect(&"deathcap") and Reactions.is_effect(&"haze"), "Deathcap and Thick Haze are effect damage")

	var undiluted_before := DreamState.undiluted_on
	DreamState.undiluted_on = false
	Reactions.force_host_potency = 0.0
	var plain := Reactions.effect_multiplier(enemy, spore, &"spored")
	Reactions.force_host_potency = HOST
	var hosted := Reactions.effect_multiplier(enemy, spore, &"spored")
	_check(is_equal_approx(hosted, plain * HOST), "Host Grove: a Poisoned tick x1.3 (%.3f vs %.3f)" % [hosted, plain])
	_check(is_equal_approx(Reactions.effect_multiplier(enemy, spore, &"deathcap"), Reactions.effect_multiplier(enemy, spore, &"haze")),
		"Deathcap and Thick Haze take the same Potency")

	# Never on a Reaction's damage.
	Reactions.force_host_potency = 0.0
	var clap_plain := Reactions.effect_multiplier(enemy, spore, &"thunderclap")
	var ignite_plain := Reactions.effect_multiplier(enemy, spore, &"ignite")
	Reactions.force_host_potency = HOST
	_check(is_equal_approx(Reactions.effect_multiplier(enemy, spore, &"thunderclap"), clap_plain), "never on a Thunderclap")
	_check(is_equal_approx(Reactions.effect_multiplier(enemy, spore, &"ignite"), ignite_plain), "never on an Ignite")

	# With Undiluted (x2.0 on Poisoned, applied where the tick is made): the larger of the two, so x1.0 here, never x2.6.
	DreamState.undiluted_on = true
	Reactions.force_host_potency = 0.0
	var und_plain := Reactions.effect_multiplier(enemy, spore, &"spored")
	Reactions.force_host_potency = HOST
	_check(is_equal_approx(Reactions.effect_multiplier(enemy, spore, &"spored"), und_plain * maxf(HOST, DreamState.UNDILUTED_POISONED) / DreamState.UNDILUTED_POISONED),
		"with Undiluted: max(host, Undiluted), not the product")

	DreamState.undiluted_on = undiluted_before
	Reactions.force_host_potency = 0.0
	await _clean()
	print("host grove test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

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
