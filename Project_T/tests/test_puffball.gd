extends SceneTree

# Headless test for the Puffball's pop (warden_stats.md): at 10+ Spored stacks a hit pops them for
# 6 × stacks to the nightmare and everything within 1 cell, the stacks are used up, and half of them
# drift on to the 3 nearest nightmares, still credited to their applier. Logged as a "popped" combo.
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

	# Below the threshold nothing pops.
	target.apply_status(EnemyStatuses.SPORED, 7, 5.0, 1.0, 12, "spore", sporeling)
	tower.hit(target)
	_check(target.statuses.stacks(EnemyStatuses.SPORED) == 9, "9 stacks: no pop yet")

	var pops := []
	tower.popped.connect(func(_t: Tower, e: Node2D, stacks: int) -> void: pops.append([e, stacks]))
	var health: int = target.health
	tower.hit(target)  # +2 -> 11 stacks -> pop
	var burst := int(6.0 * 11)
	_check(pops.size() == 1 and pops[0][1] == 11, "11 stacks pop (popped signal)")
	_check(target.health == health - data.damage - burst, "the pop deals 6 × stacks to the nightmare (%d)" % (health - target.health))
	_check(target.statuses.stacks(EnemyStatuses.SPORED) == 0, "its stacks are used up")
	_check(close.max_health - close.health == burst, "and bursts on nightmares within 1 cell")
	_check(b.health == b.max_health and far.health == far.max_health, "but not further away")
	var spread := [close, b, c].filter(func(e: Node2D) -> bool: return e.statuses.stacks(EnemyStatuses.SPORED) == 5)
	_check(spread.size() == 3, "half the stacks (5) drift on to the 3 nearest nightmares")
	_check(not d.statuses.has(EnemyStatuses.SPORED), "and no further than 3")
	# The Puffball's own (stronger) spores took over the stack's credit before the pop.
	_check(close.statuses.source(EnemyStatuses.SPORED) == tower, "still credited to their applier")

	var log := DamageLog.instance
	if log != null:
		var stats: Dictionary = log.get_tower_stats(tower)
		var popped: float = stats.get("combos", {}).get(&"popped", 0.0)
		_check(is_equal_approx(popped, burst * 2.0), "the DamageLog credits the pop to the Puffball as \"popped\" (%.0f)" % popped)
		var events: Array = target.recent_hits.filter(func(e: DamageLog.Event) -> bool: return e.combos.has(&"popped"))
		_check(events.size() == 1 and events[0].kind == &"pop", "logged as a pop event")
	else:
		_check(false, "the main scene has a DamageLog")

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
