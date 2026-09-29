extends SceneTree

# Headless test for Warden ranks (warden_stats.md "Nurture v2"): base costs 25/40/60/90/135 × the tier
# multiplier at purchase (Sprout ×0.5, base ×1, branch ×2, final ×3, Memory Warden ×2), +10% damage,
# +4% attack speed, +0.1 range per rank, a Focus chosen at rank III (Power / Swift / Reach / Deep),
# ranks and Focus kept through evolution, walls and auras can't be nurtured, status potency uses the
# ranked damage, refunds include rank Dew, group Nurture (partial, nearest the Heartwood first, one
# Focus for the group), the R hotkey and the mid-run save. Run from the project folder:
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
	var driftspore_data: TowerData = load("res://resource/tower/driftspore.tres")
	run_state.dew = 10000
	var tower := _build(placer, map_generator, sprout_data)
	var base_damage := tower.get_damage()
	var base_speed := tower.get_attacks_per_second()
	var base_range := tower.get_range_cells()
	var invested := tower.invested_dew

	# A Sprout ranks at half price: I 13, II 20 (25 and 40 × 0.5, rounded).
	var dew := run_state.dew
	_check(tower.get_nurture_cost() == 13, "Sprout rank I costs 25 × 0.5 = 13 (%d)" % tower.get_nurture_cost())
	placer.nurture(tower)
	_check(tower.get_nurture_cost() == 20, "Sprout rank II costs 40 × 0.5 = 20")
	placer.nurture(tower)
	_check(tower.rank == 2 and run_state.dew == dew - 33, "ranks I-II on a Sprout cost 33")
	_check(is_equal_approx(tower.get_damage(), base_damage * 1.2), "rank II: +20% damage")
	_check(is_equal_approx(tower.get_attacks_per_second(), base_speed * 1.08), "rank II: +8% attack speed")
	_check(is_equal_approx(tower.get_range_cells(), base_range + 0.2), "rank II: +0.2 range")

	# Ranks III-V need a Nurture Dream (warden_stats.md, b061d29): stuck at II without one.
	_check(not tower.can_nurture() and not placer.nurture(tower, Tower.Focus.POWER) and tower.rank == 2,
		"without a Nurture Dream a Warden stops at rank II")
	_check(tower.nurture_blocker() == "Rank III needs a Nurture Dream", "and the button says why (%s)" % tower.nurture_blocker())
	_check(seller.plan_nurture([tower])[0].is_empty(), "group Nurture / R plan nothing for it")
	for card in dreams.pool:
		if card.id == "chosen_few":  # Any Nurture-tagged card opens III-V
			dreams.take(card)
	_check(tower.can_nurture() and tower.nurture_blocker() == "", "a Nurture Dream opens rank III")

	# Rank III asks for a Focus.
	_check(tower.needs_focus() and not placer.nurture(tower), "rank III needs a Focus first")
	_check(placer.nurture(tower, Tower.Focus.POWER) and tower.rank == 3 and tower.focus == Tower.Focus.POWER,
		"rank III with the Power Focus")
	_check(is_equal_approx(tower.get_damage(), base_damage * (1.0 + 0.3 + 0.08)), "rank III Power: +30% +8% damage")
	_check(tower.invested_dew == invested + 13 + 20 + 30, "rank Dew counts as invested")
	_check(seller.get_refund(tower) == tower.invested_dew,
		"rank Dew bought this rest comes back in full, like the rest of it (placed this rest)")
	if "rank_dew_spent" in run_state:
		_check(run_state.rank_dew_spent == 63, "RunState counts Dew spent on ranks")

	# Growing a ranked Warden pays the rank difference (warden_stats.md): for each rank held, its price
	# at the new tier minus its price at the old one. Sprout ×0.5 → Sporeling ×1: (25-13)+(40-20)+(60-30).
	var grow := tower.get_grow_cost(sporeling_data)
	var evolve_base: int = dreams.get_evolve_cost(sporeling_data)
	_check(grow.base == evolve_base and grow.ranks == 12 + 20 + 30 and grow.total == evolve_base + 62,
		"a rank III Sprout growing into a Sporeling pays %d + 62 (%s)" % [evolve_base, grow])
	var invested_before := tower.invested_dew
	var dew_before: int = run_state.dew
	# Ranks and Focus carry through evolution.
	placer.evolve(tower, sporeling_data)
	_check(run_state.dew == dew_before - grow.total and tower.invested_dew == invested_before + grow.total,
		"the whole grow cost is charged and counts as invested (selling refunds it)")
	_check(tower.tower_data == sporeling_data and tower.rank == 3 and tower.focus == Tower.Focus.POWER,
		"a rank III Power Sprout grows into a rank III Power Sporeling")
	_check(is_equal_approx(tower.get_damage(), sporeling_data.damage * 1.38), "with the rank's damage")
	_check(tower.get_nurture_cost() == 90, "a base Warden's rank IV costs 90 × 1")
	placer.nurture(tower)
	_check(is_equal_approx(tower.get_damage(), sporeling_data.damage * (1.0 + 0.4 + 0.16)), "rank IV Power: +40% +16%")
	placer.evolve(tower, driftspore_data)
	_check(tower.get_nurture_cost() == 270, "a branch's rank V costs 135 × 2")
	var shade := _spawn(main, tower.global_position + Vector2(64, 0))
	tower.hit(shade, 1.0, false, Tower.NO_CRIT)
	_check(is_equal_approx(shade.statuses.potency(EnemyStatuses.SPORED), tower.get_damage() * Tower.SPORE_POTENCY),
		"Spored potency uses the ranked damage")
	placer.nurture(tower)
	_check(tower.rank == 5 and not tower.can_nurture() and not placer.nurture(tower), "rank V is the most")

	# Deep: +10% Potency (effect damage) and status duration per rank from III.
	var deep := _build(placer, map_generator, sporeling_data)
	deep.rank = 2
	placer.nurture(deep, Tower.Focus.DEEP)
	var soaked := _spawn(main, deep.global_position + Vector2(64, 0))
	deep.hit(soaked, 1.0, false, Tower.NO_CRIT)
	_check(is_equal_approx(soaked.statuses.potency(EnemyStatuses.SPORED), deep.get_damage() * Tower.SPORE_POTENCY)
		and is_equal_approx(deep.get_potency(), 1.1), "Deep: +10% Potency at rank III (the status keeps the plain strength)")
	_check(is_equal_approx(soaked.statuses.time_left(EnemyStatuses.SPORED), EnemyStatuses.DEFAULT_DURATION[EnemyStatuses.SPORED] * 1.1),
		"Deep: +10% status duration at rank III")

	# Reach and Swift.
	var reach := _build(placer, map_generator, sporeling_data)
	var reach_base := reach.get_range_cells()
	reach.rank = 2
	placer.nurture(reach, Tower.Focus.REACH)
	_check(is_equal_approx(reach.get_range_cells(), reach_base + 0.3 + 0.2), "Reach: +0.2 range at rank III")
	var swift := _build(placer, map_generator, sporeling_data)
	var swift_base := swift.get_attacks_per_second()
	swift.rank = 2
	placer.nurture(swift, Tower.Focus.SWIFT)
	_check(is_equal_approx(swift.get_attacks_per_second(), swift_base * (1.0 + 0.12 + 0.06)), "Swift: +6% attack speed at rank III")

	# Walls, wall growths and the White Stag's aura can't be nurtured; Memory Wardens rank at ×2.
	var wall := _build(placer, map_generator, load("res://resource/tower/thornwall.tres"))
	_check(not wall.can_nurture() and not placer.nurture(wall), "Thornwalls can't be nurtured")
	placer.evolve(wall, load("res://resource/tower/bramble.tres"))
	_check(not wall.can_nurture(), "nor Brambles (a wall growth)")
	var container: Node = main.get_node("%TowerContainer")
	var stag: Tower = placer.tower_scene.instantiate()
	stag.tower_data = load("res://resource/tower/white_stag.tres")
	container.add_child(stag)
	_check(not stag.can_nurture(), "the White Stag (an aura) can't be nurtured")
	var keeper: Tower = placer.tower_scene.instantiate()
	keeper.tower_data = load("res://resource/tower/pond_keeper.tres")
	container.add_child(keeper)
	_check(keeper.get_nurture_cost() == 50, "a Memory Warden's rank I costs 25 × 2")
	stag.queue_free()
	keeper.queue_free()

	# Group Nurture: one rank each while the Dew lasts, nearest the Heartwood first.
	var group: Array[Tower] = []
	for i in 3:
		group.append(_build(placer, map_generator, sprout_data))
	seller.set_selection(group)
	run_state.dew = 28  # Two of the three (13 each)
	var plan: Array = seller.plan_nurture(group)
	var nearest: Array = seller.sort_by_heartwood(group).slice(0, 2)
	_check(plan[0].size() == 2 and plan[1] == 26, "can nurture 2 of 3 for 26 Dew")
	_check(seller.full_nurture_cost(group) == [3, 39], "all three would cost 39")
	_check(seller.nurture_group(group) == 2 and run_state.dew == 2, "group Nurture raises 2 of 3")
	_check(nearest.all(func(t: Tower) -> bool: return t.rank == 1), "the 2 nearest the Heartwood")

	# R nurtures the selection.
	var r_events := InputMap.action_get_events("nurture_warden")
	_check(r_events.any(func(e: InputEvent) -> bool: return e is InputEventKey and e.physical_keycode == KEY_R),
		"R is the Nurture hotkey")
	run_state.dew = 1000
	var press := InputEventAction.new()
	press.action = "nurture_warden"
	press.pressed = true
	seller._unhandled_input(press)
	_check(group.all(func(t: Tower) -> bool: return t.rank == 2 or t.rank == 1) and group.any(func(t: Tower) -> bool: return t.rank == 2),
		"R nurtures every selected Warden one rank")

	# One Focus for the whole group at rank III; without one, those Wardens are left out.
	for t in group:
		t.rank = 2
	_check(seller.count_needing_focus(group) == 3 and seller.nurture_group(group) == 0,
		"group Nurture skips Wardens waiting for a Focus")
	_check(seller.nurture_group(group, Tower.Focus.SWIFT) == 3 \
		and group.all(func(t: Tower) -> bool: return t.rank == 3 and t.focus == Tower.Focus.SWIFT),
		"one Focus for the whole group")

	# First Care (Grove perk): the run's first free_nurtures ranks cost nothing.
	if "free_nurtures" in run_state:
		var freebie := _build(placer, map_generator, sprout_data)
		var paid := freebie.invested_dew
		run_state.free_nurtures = 2
		run_state.dew = 100
		var normal := roundi(Tower.RANK_COSTS[0] * freebie.get_tier_cost_multiplier())  # 25 × 0.5 = 13 on a Sprout
		_check(freebie.get_nurture_cost() == 0 and freebie.get_nurture_price() == normal, "a free rank shows as free (normally %d)" % normal)
		var group_free := [freebie]
		_check(seller.full_nurture_cost(group_free) == [1, 0], "group Nurture counts free ranks as free")
		placer.nurture(freebie)
		placer.nurture(freebie)
		_check(freebie.rank == 2 and run_state.dew == 100 and run_state.free_nurtures == 0,
			"First Care: 2 free ranks, no Dew spent")
		_check(freebie.invested_dew == paid, "free ranks add nothing to invested Dew (nothing to refund)")
		_check(freebie.get_nurture_cost() == freebie.get_nurture_price(), "then ranks cost Dew again")
	else:
		print("(RunState.free_nurtures not in this tree yet: First Care checks skipped)")

	# Mid-run save keeps ranks and Focus.
	var saver: RunSaver = main.get_node("%RunSaver")
	saver.save_now()
	var saved: Dictionary = saver._read()
	var entry := {}
	for row in saved.get("towers", []):
		if Vector2(row.cell[0], row.cell[1]) == tower.cell:
			entry = row
	_check(int(entry.get("rank", -1)) == 5 and int(entry.get("focus", -1)) == Tower.Focus.POWER,
		"the save keeps a Warden's rank and Focus")
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
				var built: Tower = container.get_child(count)
				built.set_process(false)
				return built
	return null
