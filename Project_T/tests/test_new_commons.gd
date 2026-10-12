extends SceneTree

# Headless test for Tower Code's hooks of the new Commons 270–285 (dream_design.md c15d05ac / b6c1c199; numbers
# balance_simulation.md 605a8ea7): Ripples (area hits on non-main targets +25%), Rhythm (5 hits in a row on one
# nightmare: +20% attack speed for 3 s), Edge of Sight (+25% in the outer half of range), Steady Aim (crits +40% above
# half health). Cards are made here with the rule ids (Roguelite Code owns the data).
#   godot --headless --path . --script res://tests/test_new_commons.gd --fixed-fps 60

var failures := 0
var main: Node
var dreams: DreamState
var placer: TowerPlacer
var spawner: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_new_commons_%d.json" % OS.get_process_id()
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	placer = main.get_node("%TowerPlacer")
	spawner = main.get_node("%EnemyContainer")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame
	var spore := _plant("sporeling", Vector2(10, 2))
	spore.attack_data = spore.attack_data.duplicate()
	spore.attack_data.crit_chance = 0.0
	spore.attack_data.damage = 400  # (Whole-number health: big hits keep the ratios clean)
	spore._stats = {}
	var reach := spore.get_range_pixels()
	var near := _walker(spore.global_position + Vector2(reach * 0.3, 0))
	var far := _walker(spore.global_position + Vector2(reach * 0.8, 0))

	# Edge of Sight: +25% in the outer half of its range.
	_take(&"edge_of_sight")
	var near_hit := _damage(spore, near, false, Tower.NO_CRIT)
	var far_hit := _damage(spore, far, false, Tower.NO_CRIT)
	_check(absf(far_hit / near_hit - (1.0 + Tower.CARD_EDGE)) < 0.05, "Edge of Sight: +25%% in the outer half (%.1f vs %.1f)" % [far_hit, near_hit])
	_clear()

	# Steady Aim: a crit above half health +40%; below half, a plain crit.
	_take(&"steady_aim")
	near.health = near.max_health
	var full_crit := _damage(spore, near, false, Tower.CRIT)
	near.health = int(near.max_health * 0.3)
	var low_crit := _damage(spore, near, false, Tower.CRIT)
	_check(absf(full_crit / low_crit - (1.0 + Tower.CARD_STEADY_AIM)) < 0.05, "Steady Aim: crits +40%% above half health (%.1f vs %.1f)" % [full_crit, low_crit])
	near.health = near.max_health
	_clear()

	# Ripples: an area hit on a nightmare that isn't the attack's target +25%; the target itself not.
	var plain_area := _damage(spore, far, true, Tower.NO_CRIT)
	await process_frame
	_take(&"ripples")
	spore._last_fired = near
	var ripple := _damage(spore, far, true, Tower.NO_CRIT)
	var main_hit := _damage(spore, near, true, Tower.NO_CRIT)
	var main_plain := plain_area * near_hit / far_hit if far_hit > 0.0 else plain_area
	_check(absf(ripple / plain_area - (1.0 + Tower.CARD_RIPPLES)) < 0.05, "Ripples: +25%% on a non-main target (%.1f vs %.1f)" % [ripple, plain_area])
	_check(main_hit > 0.0 and absf(main_hit / plain_area - 1.0) < 0.05, "…the attack's own target unchanged (%.1f)" % main_hit)
	_clear()

	# Fifth Beat preserves ordinary attack cadence; its echo has dedicated integration coverage.
	_take(&"rhythm")
	var speed := spore.get_attacks_per_second()
	spore.note_primary_target(near)
	for i in 5:
		spore.hit(near, 1.0, false, Tower.NO_CRIT)
	_check(is_equal_approx(spore.get_attacks_per_second(), speed), "Fifth Beat has no former passive attack-speed bonus")

	_clear()

	print("new commons test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

# Damage `tower` deals to `enemy` with one hit (area hits land a frame later through the area queue: measured after).
func _damage(tower: Tower, enemy: Node2D, area: bool, crit: int) -> float:
	var before: float = enemy.health
	tower.hit(enemy, 1.0, area, crit)
	if area and enemy.health == before:
		var queue := AreaHitQueue.find(tower)
		if queue != null and queue.has_method("flush"):
			queue.flush()
	return before - enemy.health

func _take(rule: StringName) -> void:
	var card := UpgradeData.new()
	card.id = String(rule) + "_test"
	card.rule_id = rule
	card.display_name = String(rule)
	dreams.pool.append(card)
	dreams.take(card)

func _clear() -> void:
	dreams.stacks.clear()
	dreams.bump_board()

func _plant(id: String, at: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = at
	tower.position = Tower.MAP_GRID.calculate_map_position(at)
	placer.tower_container.add_child(tower)
	tower.set_process(false)
	return tower

func _walker(at: Vector2) -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"), 50.0)
	var e = spawner.get_child(spawner.get_child_count() - 1)
	e.set_process(false)
	e.global_position = at
	e.max_health = 1000000
	e.health = 1000000
	return e

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
