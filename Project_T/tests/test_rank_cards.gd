extends SceneTree

# Headless test for Tower Code's hooks of the rank cards (dream_design.md cdfbe349; Balancing 43496006):
# Specialist (every rank the same choice: each chosen rank's bonus x2) and Brimming (status caps x2 for caps
# above 1, bosses too; Heavy Eyelids after). Many Talents is Roguelite Code's DreamEffects row. Cards are made
# here with the rule ids.
#   godot --headless --path . --script res://tests/test_rank_cards.gd --fixed-fps 60

var failures := 0
var main: Node
var dreams: DreamState
var placer: TowerPlacer
var spawner: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_rank_cards_%d.json" % OS.get_process_id()
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	placer = main.get_node("%TowerPlacer")
	spawner = main.get_node("%EnemyContainer")
	dreams.unlock_everything = true
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	# Specialist: three Power ranks give x2 their Power; a mixed Warden gets nothing.
	var single := _plant("sporeling", Vector2(4, 2))
	single.rank = 3
	single.rank_choices = [Tower.Focus.POWER, Tower.Focus.POWER, Tower.Focus.POWER]
	var mixed := _plant("sporeling", Vector2(6, 2))
	mixed.rank = 3
	mixed.rank_choices = [Tower.Focus.POWER, Tower.Focus.SWIFT, Tower.Focus.POWER]
	var plain := single.get_rank_damage_multiplier()
	var mixed_plain := mixed.get_rank_damage_multiplier()
	_take(&"specialist")
	_check(is_equal_approx(single.focus_power(), 2.0) and is_equal_approx(mixed.focus_power(), 1.0), "Specialist: x2 only when every rank chose alike")
	_check(is_equal_approx(single.get_rank_damage_multiplier() - 1.0, (plain - 1.0) * 2.0),
		"Specialist: Power ranks give double (%.2f -> %.2f)" % [plain, single.get_rank_damage_multiplier()])
	_check(is_equal_approx(mixed.get_rank_damage_multiplier(), mixed_plain), "Specialist: a mixed Warden is unchanged")
	_clear_cards()

	# Brimming: caps above 1 double (Poisoned 8 -> 16, a boss's Drowsy 3 -> 6); single-stack ones stay.
	var walker := _walker()
	var boss := _walker()
	boss.statuses.is_boss = true
	var spored: int = walker.statuses.get_max_stacks(EnemyStatuses.SPORED)
	var marked: int = walker.statuses.get_max_stacks(EnemyStatuses.MARKED)
	var boss_drowsy: int = boss.statuses.get_max_stacks(EnemyStatuses.DROWSY)
	_take(&"brimming")
	await process_frame  # The rule is looked up once a frame
	_check(walker.statuses.get_max_stacks(EnemyStatuses.SPORED) == spored * 2, "Brimming: Poisoned cap x2 (%d -> %d)" % [spored, walker.statuses.get_max_stacks(EnemyStatuses.SPORED)])
	_check(walker.statuses.get_max_stacks(EnemyStatuses.MARKED) == marked, "Brimming: a 1-stack status stays 1")
	_check(boss.statuses.get_max_stacks(EnemyStatuses.DROWSY) == boss_drowsy * 2, "Brimming: bosses too (Drowsy %d -> %d)" % [boss_drowsy, boss.statuses.get_max_stacks(EnemyStatuses.DROWSY)])
	walker.statuses.drowsy_cap_bonus = 1
	_check(walker.statuses.get_max_stacks(EnemyStatuses.DROWSY) == EnemyStatuses.DEFAULT_MAX_STACKS[EnemyStatuses.DROWSY] * 2 + 1,
		"Brimming: Heavy Eyelids adds after the doubling")
	_clear_cards()
	await process_frame
	_check(walker.statuses.get_max_stacks(EnemyStatuses.SPORED) == spored, "without the card, caps return")

	print("rank cards test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _take(rule: StringName) -> void:
	var card := UpgradeData.new()
	card.id = String(rule) + "_test"
	card.rule_id = rule
	card.display_name = String(rule)
	dreams.pool.append(card)
	dreams.take(card)

func _clear_cards() -> void:
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

func _walker() -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"), 50.0)
	var e = spawner.get_child(spawner.get_child_count() - 1)
	e.set_process(false)
	return e

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
