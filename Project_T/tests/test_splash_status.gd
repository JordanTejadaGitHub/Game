extends SceneTree

# Splash rework (owner 2026-10-25, dream_council_review.md 37; splash_td.md 5): a splash gives its Warden's status only to
# the nightmare it hit; the others take its damage. Past the AreaHitQueue's budget (a dense crowd: the hits land next
# frame) the same holds. A pulse keeps its status. A splash hit never spends Pinned. Hailfall gives a Warden without a
# splash one (40% onto the 3 nearest within 1 cell, never splashing again); Spattered gives the splash's status back
# (a form's own splash: splash_status_stacks; once a second per Warden per nightmare).
# Run from the project folder:
#   godot --headless --path . --script res://tests/test_splash_status.gd --fixed-fps 60

const CELL := 64.0

var failures := 0
var spawner
var dreams: DreamState

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	spawner = main.get_node("%EnemyContainer")
	var container: Node = main.get_node("%TowerContainer")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	dreams = main.get_node("%DreamState")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	var puff_data: TowerData = load("res://resource/tower/puffball.tres").duplicate()
	puff_data.crit_chance = 0.0
	puff_data.id = "puffball"
	var puff := _plant(placer, container, puff_data, Vector2(5, 5))

	# 1. The nightmare hit takes the status; the others take damage only.
	var at := puff.global_position + Vector2(CELL, 0)
	var target := _spawn(at)
	var near := _spawn(at + Vector2(0.6, 0) * CELL)
	await process_frame
	puff.projectile_landed(target, target.global_position)
	await process_frame
	_check(target.statuses.stacks(EnemyStatuses.SPORED) == puff_data.status_stacks, "the nightmare hit takes %d Poisoned (%d)" % [
		puff_data.status_stacks, target.statuses.stacks(EnemyStatuses.SPORED)])
	_check(near.health < near.max_health and not near.statuses.has(EnemyStatuses.SPORED), "a nightmare in the splash: damage only")

	# 2. A dense crowd past the AreaHitQueue budget: the late hits are still damage only.
	_clear()
	await process_frame
	target = _spawn(at)
	var crowd: Array = []
	for i in AreaHitQueue.BUDGET + 6:
		crowd.append(_spawn(at + Vector2.from_angle(TAU * i / 30.0) * 0.5 * CELL))
	await process_frame
	puff.projectile_landed(target, target.global_position)
	for f in 4:
		await process_frame
	var hurt := 0
	var statused := 0
	for e in crowd:
		if e.health < e.max_health:
			hurt += 1
		if e.statuses.has(EnemyStatuses.SPORED):
			statused += 1
	_check(hurt == crowd.size() and statused == 0, "past the area budget: %d of %d hurt, %d with Poisoned (0)" % [hurt, crowd.size(), statused])

	# 3. A pulse (or any area hit that isn't a splash's other) keeps its status.
	_clear()
	await process_frame
	var pulsed := _spawn(at)
	await process_frame
	puff.hit(pulsed, 1.0, true)
	_check(pulsed.statuses.has(EnemyStatuses.SPORED), "an area hit by default still carries the status")

	# 4. A splash hit never spends Pinned.
	_clear()
	await process_frame
	target = _spawn(at)
	var pinned := _spawn(at + Vector2(0.6, 0) * CELL)
	await process_frame
	pinned.statuses.pinned = true
	puff.projectile_landed(target, target.global_position)
	await process_frame
	_check(pinned.statuses.pinned and pinned.health < pinned.max_health, "a splash hit leaves Pinned for a direct hit")

	# 5. Hailfall: a Warden without a splash splashes 40% onto the 3 nearest within 1 cell; the splash never splashes again.
	_clear()
	await process_frame
	_take("hailfall")
	_check(dreams.has_rule(Tower.HAILFALL), "Hailfall held")
	var spore_data: TowerData = load("res://resource/tower/sporeling.tres").duplicate()
	spore_data.crit_chance = 0.0
	spore_data.id = "sporeling"
	var shooter := _plant(placer, container, spore_data, Vector2(5, 8))
	shooter.clear_dream_cache()
	var hit_at := shooter.global_position + Vector2(CELL, 0)
	target = _spawn(hit_at)
	var ring: Array = [_spawn(hit_at + Vector2(0.4, 0) * CELL), _spawn(hit_at + Vector2(0, 0.5) * CELL),
		_spawn(hit_at + Vector2(-0.6, 0) * CELL)]
	var fourth := _spawn(hit_at + Vector2(0, -0.9) * CELL)  # Within 1 cell, but the 4th nearest
	var beyond := _spawn(hit_at + Vector2(1.3, 0) * CELL)  # Within 1 cell of a splashed one (0.9), not of the target
	await process_frame
	shooter.note_primary_target(target)
	shooter.hit(target, 1.0)
	await process_frame
	var ring_hurt := ring.filter(func(e) -> bool: return e.health < e.max_health).size()
	_check(target.statuses.has(EnemyStatuses.SPORED), "Hailfall: the nightmare hit keeps its status")
	_check(ring_hurt == 3 and ring.all(func(e) -> bool: return not e.statuses.has(EnemyStatuses.SPORED)),
		"Hailfall: the 3 nearest take damage only (%d hurt)" % ring_hurt)
	_check(fourth.health == fourth.max_health, "Hailfall: the 4th nearest is untouched")
	_check(beyond.health == beyond.max_health, "Hailfall: a granted splash never splashes again")
	var lost: float = ring[0].max_health - ring[0].health
	_check(lost > 0.0 and lost <= spore_data.damage * Tower.HAILFALL_SHARE * 3.0, "Hailfall's share is about 40%% of a hit (%.1f)" % lost)

	# 6. Spattered: a form's own splash gives splash_status_stacks, once a second per Warden per nightmare.
	_clear()
	await process_frame
	_take("spattered")
	_check(dreams.has_rule(Tower.SPATTERED), "Spattered held")
	puff.clear_dream_cache()
	target = _spawn(at)
	near = _spawn(at + Vector2(0.6, 0) * CELL)
	await process_frame
	puff.projectile_landed(target, target.global_position)
	await process_frame
	_check(near.statuses.stacks(EnemyStatuses.SPORED) == puff_data.splash_status_stacks, "Spattered: the splash gives %d Poisoned (%d)" % [
		puff_data.splash_status_stacks, near.statuses.stacks(EnemyStatuses.SPORED)])
	puff.projectile_landed(target, target.global_position)
	await process_frame
	_check(near.statuses.stacks(EnemyStatuses.SPORED) == puff_data.splash_status_stacks, "Spattered: at most once a second per Warden")

	print("splash status test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _take(id: String) -> void:
	var card := load("res://resource/dream/%s.tres" % id) as UpgradeData
	_check(card != null, "%s's card exists" % id)
	if card != null and not dreams.has_card(id):
		dreams.take(card)

func _plant(placer: TowerPlacer, container: Node, data: TowerData, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = data
	tower.cell = cell
	tower.position = cell * CELL + Vector2(CELL, CELL) / 2
	container.add_child(tower)
	tower.set_process(false)
	return tower

func _clear() -> void:
	for child in spawner.get_children():
		child.queue_free()

# A sturdy nightmare standing still at `position`.
func _spawn(position: Vector2) -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = position
	enemy.max_health = 100000
	enemy.health = 100000
	return enemy

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
