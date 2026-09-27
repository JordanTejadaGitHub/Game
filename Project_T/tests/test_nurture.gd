extends SceneTree

# Headless test for Warden ranks (warden_stats.md "Ranks: Nurture"): costs 15/25/40/60/90, +15% damage,
# +5% attack speed, +0.1 range per rank, kept through evolution, walls and auras can't be nurtured,
# status potency uses the ranked damage, refunds include rank Dew, group Nurture (partial, nearest the
# Heartwood first), the R hotkey, and the mid-run save. Run from the project folder:
#   godot --headless --path . --script res://tests/test_nurture.gd --fixed-fps 60

const RUN_PATH := "user://test_nurture_run.json"

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	RunSaver.file_path = RUN_PATH
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var map_generator = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var run_state: RunState = main.get_node("%RunState")
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.unlock_everything = true
	for child in main.get_node("%EnemyContainer").get_children():
		child.queue_free()
	await process_frame

	var sprout_data: TowerData = load("res://resource/tower/sprout.tres")
	var sporeling_data: TowerData = load("res://resource/tower/sporeling.tres")
	run_state.dew = 10000
	var sprout := _build(placer, map_generator, sprout_data)
	var base_damage := sprout.get_damage()
	var base_speed := sprout.get_attacks_per_second()
	var base_range := sprout.get_range_cells()
	var invested := sprout.invested_dew

	# Ranks I-III: 15 + 25 + 40 Dew.
	var dew := run_state.dew
	for i in 3:
		_check(placer.nurture(sprout), "nurture to rank %d" % (i + 1))
	_check(sprout.rank == 3 and run_state.dew == dew - 80, "ranks I-III cost 15 + 25 + 40 Dew")
	_check(is_equal_approx(sprout.get_damage(), base_damage * 1.45), "rank III: +45% damage")
	_check(is_equal_approx(sprout.get_attacks_per_second(), base_speed * 1.15), "rank III: +15% attack speed")
	_check(is_equal_approx(sprout.get_range_cells(), base_range + 0.3), "rank III: +0.3 range")
	_check(sprout.invested_dew == invested + 80, "rank Dew counts as invested")
	_check(seller.get_refund(sprout) == int(sprout.invested_dew * seller.build_phase_refund),
		"selling refunds rank Dew with the normal rules")

	# Ranks carry through evolution; status potency uses the ranked damage.
	placer.evolve(sprout, sporeling_data)
	_check(sprout.tower_data == sporeling_data and sprout.rank == 3, "a rank III Sprout grows into a rank III Sporeling")
	_check(is_equal_approx(sprout.get_damage(), sporeling_data.damage * 1.45), "with the rank's damage")
	var shade := _spawn(main, sprout.global_position + Vector2(64, 0))
	sprout.hit(shade, 1.0, false, Tower.NO_CRIT)
	_check(is_equal_approx(shade.statuses.potency(EnemyStatuses.SPORED), sprout.get_damage() * Tower.SPORE_POTENCY),
		"Spored potency uses the ranked damage")

	# Ranks IV and V, then no more.
	dew = run_state.dew
	placer.nurture(sprout)
	placer.nurture(sprout)
	_check(sprout.rank == 5 and run_state.dew == dew - 150, "ranks IV-V cost 60 + 90 Dew (230 in all)")
	_check(not sprout.can_nurture() and not placer.nurture(sprout), "rank V is the most")
	_check(is_equal_approx(sprout.get_damage(), sporeling_data.damage * 1.75), "rank V: +75% damage")

	# Walls and the White Stag's aura can't be nurtured.
	var wall := _build(placer, map_generator, load("res://resource/tower/thornwall.tres"))
	_check(not wall.can_nurture() and not placer.nurture(wall), "Thornwalls can't be nurtured")
	var stag: Tower = placer.tower_scene.instantiate()
	stag.tower_data = load("res://resource/tower/white_stag.tres")
	main.get_node("%TowerContainer").add_child(stag)
	_check(not stag.can_nurture(), "the White Stag (an aura) can't be nurtured")
	stag.queue_free()

	# Group Nurture: one rank each while the Dew lasts, nearest the Heartwood first.
	var group: Array[Tower] = []
	for i in 3:
		group.append(_build(placer, map_generator, sprout_data))
	seller.set_selection(group)
	run_state.dew = 35  # Two of the three (15 each)
	var plan: Array = seller.plan_nurture(group)
	var nearest: Array = seller.sort_by_heartwood(group).slice(0, 2)
	_check(plan[0].size() == 2 and plan[1] == 30, "can nurture 2 of 3 for 30 Dew")
	_check(seller.full_nurture_cost(group) == [3, 45], "all three would cost 45")
	_check(seller.nurture_group(group) == 2 and run_state.dew == 5, "group Nurture raises 2 of 3")
	_check(nearest.all(func(t: Tower) -> bool: return t.rank == 1), "the 2 nearest the Heartwood")

	# R: nurtures the selection.
	var r_events := InputMap.action_get_events("nurture_warden")
	_check(r_events.any(func(e: InputEvent) -> bool: return e is InputEventKey and e.physical_keycode == KEY_R),
		"R is the Nurture hotkey")
	run_state.dew = 1000
	var press := InputEventAction.new()
	press.action = "nurture_warden"
	press.pressed = true
	seller._unhandled_input(press)
	_check(group.all(func(t: Tower) -> bool: return t.rank >= 1) and group.any(func(t: Tower) -> bool: return t.rank == 2),
		"R nurtures every selected Warden one rank")

	# Mid-run save keeps ranks.
	var saver: RunSaver = main.get_node("%RunSaver")
	saver.save_now()
	var saved: Dictionary = saver._read()
	var ranks := {}
	for entry in saved.get("towers", []):
		ranks[Vector2(entry.cell[0], entry.cell[1])] = int(entry.get("rank", -1))
	_check(ranks.get(sprout.cell, -1) == 5, "the save keeps a Warden's rank")
	RunSaver.delete_save()

	print("nurture test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _spawn(main: Node, at: Vector2) -> Node2D:
	var spawner = main.get_node("%EnemyContainer")
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = at
	enemy.max_health = 100000
	enemy.health = 100000
	return enemy

# Builds `data` on a free cell beside the path (keeping it open).
func _build(placer: TowerPlacer, map_generator, data: TowerData) -> Tower:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var container: Node = placer.tower_container
	for i in range(3, path.size() - 3):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if path.has(cell) or not map_generator.can_block(cell):
				continue
			placer.tower_data = data
			var count := container.get_child_count()
			if placer._try_build(cell):
				var tower: Tower = container.get_child(count)
				tower.set_process(false)
				return tower
	return null
