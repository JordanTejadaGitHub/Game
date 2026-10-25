extends SceneTree

# Headless test for the Puffball (tower_design.md "Spores don't pop"): its puff bursts on landing over 1
# tile; since the splash rework (dream_council_review.md 37) only the nightmare hit takes its Poisoned (3), the others
# nearby take its damage. Nightmares it hits hold up to its cap, and nothing pops.
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
	data.id = "puffball"  # A duplicate has no path to take its id from
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
	_check(data.status_stacks == 3 and data.splash_status_stacks == 1, "Puffball's hit gives 3 Poisoned; its splash 1 with Spattered")
	_check(not close.statuses.has(EnemyStatuses.SPORED) and close.health < close.max_health,
		"the burst soothes a nightmare within 1 tile, damage only (section 37)")
	_check(b.health == b.max_health and c.health == c.max_health and d.health == d.max_health and far.health == far.max_health,
		"and nothing further away")
	target.health = 1000000
	target.max_health = 1000000
	for i in data.status_max_stacks:
		tower.projectile_landed(target, target.global_position)
		await process_frame  # Let the area-hit budget drain between applications.
	_check(target.statuses.stacks(EnemyStatuses.SPORED) == data.status_max_stacks, "nightmares it hits hold up to %d Poisoned (%d)" % [
		data.status_max_stacks, target.statuses.stacks(EnemyStatuses.SPORED)])
	_check(not "pop_at_stacks" in data, "the pop is gone from the data")

	# Chain Bloom (section 35, Tower Code): a splash landing on a nightmare carrying 2+ statuses reaches half again as far
	# (CHAIN_BLOOM_RADIUS 1.5); no fog needed any more (it was Puffball in Mistveil's fog).
	# (Section 37: the outer nightmare takes damage only, so the reach is read from its health.)
	var outer := _spawn(spawner, target.global_position + Vector2(0, 1.3) * CELL)
	tower.projectile_landed(target, target.global_position)
	await process_frame
	_check(outer.health == outer.max_health, "without Chain Bloom, 1.3 tiles away is outside the puff")
	for bloom in dreams.pool:
		if bloom.id == "chain_bloom":
			dreams.take(bloom)
	_check(dreams.has_rule(&"chain_bloom"), "Chain Bloom taken")
	tower.clear_dream_cache()
	target.statuses.remove(EnemyStatuses.DAMP)
	tower.projectile_landed(target, target.global_position)
	await process_frame
	_check(target.statuses.count() < 2 and outer.health == outer.max_health, "Chain Bloom on a nightmare with 1 status: still 1 tile")
	target.apply_status(EnemyStatuses.DAMP, 2)
	tower.projectile_landed(target, target.global_position)
	await process_frame
	_check(outer.health < outer.max_health and not outer.statuses.has(EnemyStatuses.SPORED),
		"…on one with 2+ statuses: half again as far (1.5 tiles), still damage only")

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
