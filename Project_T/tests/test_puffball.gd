extends SceneTree

# Headless test for the Puffball (tower_design.md "Spores don't pop"): its puff bursts on landing over 1
# tile, 2 Poisoned to every nightmare there, nightmares it hits hold up to 16 Poisoned, and nothing pops.
# Sporemother breathes 2 Poisoned a second over everything in range.
# Run from the project folder:
#   godot --headless --path . --script res://tests/test_puffball.gd --fixed-fps 60

const CELL := 64.0

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var spawner = main.get_node("%EnemyContainer")
	var container: Node = main.get_node("%TowerContainer")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var dreams: DreamState = main.get_node("%DreamState")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	# Data: Driftspore grows into Puffball through a Rare Dream.
	var puffball: TowerData = load("res://resource/tower/puffball.tres")
	var driftspore: TowerData = load("res://resource/tower/driftspore.tres")
	_check(driftspore.evolves_to.has(puffball), "Driftspores can grow into Puffballs")
	var card := load("res://resource/dream/dream_puffball.tres") as UpgradeData
	_check(card != null and card.unlocks == puffball and card.requires == ["driftspore"] \
		and card.rarity == UpgradeData.Rarity.RARE and not card.in_start_pool, "Puffball's Rare Dream card (Grove-gated final form)")
	_check(dreams.pool.has(card), "the card is in the Dream pool")

	var data: TowerData = puffball.duplicate()
	data.crit_chance = 0.0
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = data
	tower.cell = Vector2(5, 5)
	tower.position = Vector2(5, 5) * CELL + Vector2(CELL, CELL) / 2
	container.add_child(tower)
	tower.set_process(false)
	var sporeling: Tower = placer.tower_scene.instantiate()  # Applied the spores first
	sporeling.tower_data = load("res://resource/tower/sporeling.tres")
	sporeling.cell = Vector2(1, 1)
	container.add_child(sporeling)
	sporeling.set_process(false)

	var at := tower.global_position + Vector2(CELL, 0)
	var target := _spawn(spawner, at)
	var close := _spawn(spawner, at + Vector2(0.8, 0) * CELL)  # Within the 1-cell burst
	var b := _spawn(spawner, at + Vector2(0, 1.2) * CELL)
	var c := _spawn(spawner, at + Vector2(-1.2, 0) * CELL)
	var d := _spawn(spawner, at + Vector2(1.0, 1.0) * CELL)  # Fourth nearest: no spores
	var far := _spawn(spawner, at + Vector2(6, 0) * CELL)
	await process_frame

	# Spores don't pop (tower_design.md): the puff bursts on landing over 1 tile, Poisoning everything there.
	target.apply_status(EnemyStatuses.SPORED, 9, 5.0, 1.0, 12, "spore", sporeling)
	var health: int = target.health
	tower.projectile_landed(target, target.global_position)
	_check(target.statuses.stacks(EnemyStatuses.SPORED) == 9 + data.status_stacks, "no pop: its stacks keep building (%d)" % target.statuses.stacks(EnemyStatuses.SPORED))
	_check(target.health < health, "the puff soothes its target")
	_check(close.statuses.stacks(EnemyStatuses.SPORED) == data.status_stacks and close.health < close.max_health,
		"the burst Poisons (2) and soothes a nightmare within 1 tile")
	_check(not b.statuses.has(EnemyStatuses.SPORED) and not c.statuses.has(EnemyStatuses.SPORED) and not d.statuses.has(EnemyStatuses.SPORED) \
		and not far.statuses.has(EnemyStatuses.SPORED), "and nothing further away")
	for i in 6:
		tower.projectile_landed(target, target.global_position)
	_check(target.statuses.stacks(EnemyStatuses.SPORED) == data.status_max_stacks, "nightmares it hits hold up to %d Poisoned (%d)" % [
		data.status_max_stacks, target.statuses.stacks(EnemyStatuses.SPORED)])
	_check(not "pop_at_stacks" in data, "the pop is gone from the data")

	# Sporemother: 2 Poisoned a second to everything in range, refreshed every breath so it never wears off there.
	var mother_data: TowerData = load("res://resource/tower/sporemother.tres")
	_check(mother_data.status_stacks == 2 and mother_data.attacks_per_second >= 1.0
		and (mother_data.status_duration <= 0.0 or mother_data.status_duration > 1.0 / mother_data.attacks_per_second),
		"Sporemother: 2 Poisoned a second, and her breath comes before it wears off")

	print("puffball test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

# A sturdy nightmare standing still at `position`.
func _spawn(spawner, position: Vector2) -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = position
	enemy.max_health = 100000
	enemy.health = 100000
	return enemy
