extends SceneTree

# Headless test for Warden ranks (warden_stats.md "Nurture v3"): base costs 25/40/60/90/135 × the tier
# multiplier at purchase (Sprout ×0.5, base ×1, branch ×2, final ×3, Memory Warden ×2), a choice at every
# rank (Power / Swift / Reach / Deep), no Nurture Dream gate, old saves migrated,
# ranks and their choices kept through evolution, walls and auras can't be nurtured, status potency uses the
# ranked damage, refunds include rank Dew, group Nurture (partial, nearest the Heartwood first, one
# Focus for the group), the R hotkey and the mid-run save. Run from the project folder:
#   godot --headless --path . --script res://tests/test_nurture.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	# Per-process files (CLAUDE.md): a fixed name collided when two chats ran this test at once (a flaky save check).
	RunSaver.file_path = "user://test_nurture_run_%d.json" % OS.get_process_id()
	HeartwoodMemory.file_path = "user://test_nurture_heartwood_%d.json" % OS.get_process_id()  # Not the player's settings
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



	# A Sprout ranks at half price: I 15, II 24 (30 and 48 × 0.5; Balancing 2026-10-04). Nurture v3 (warden_stats.md):
	# every rank is a choice; no choice given = the Warden's default (Power for attackers).
	var dew := run_state.dew
	_check(tower.get_nurture_cost() == 15, "Sprout rank I costs 30 × 0.5 = 15 (%d)" % tower.get_nurture_cost())
	placer.nurture(tower, Tower.Focus.POWER)
	_check(tower.get_nurture_cost() == 24, "Sprout rank II costs 48 × 0.5 = 24")
	placer.nurture(tower)
	_check(tower.rank == 2 and run_state.dew == dew - 39, "ranks I-II on a Sprout cost 39")
	_check(tower.rank_choices == [Tower.Focus.POWER, Tower.Focus.POWER], "each rank records its choice (%s)" % [tower.rank_choices])
	_check(is_equal_approx(tower.get_damage(), base_damage * (1.0 + 2 * Tower.FOCUS_POWER)), "two Power ranks: +36% damage")
	_check(is_equal_approx(tower.get_attacks_per_second(), base_speed) and is_equal_approx(tower.get_range_cells(), base_range),
		"and nothing else (no fixed per-rank gains any more)")

	# No Nurture Dream gate: ranks III–V for Dew.
	_check(tower.can_nurture() and tower.nurture_blocker() == "", "rank III needs no Nurture Dream")
	_check(not placer.nurture(tower, Tower.Focus.WIDE), "a support choice is refused for an attacker")
	_check(placer.nurture(tower, Tower.Focus.REACH) and tower.rank == 3 and tower.focus == Tower.Focus.REACH,
		"rank III with Reach")
	_check(is_equal_approx(tower.get_range_cells(), base_range + Tower.FOCUS_REACH), "Reach: +0.3 range")
	_check(tower.invested_dew == invested + 15 + 24 + 30, "rank Dew counts as invested")
	_check(seller.get_refund(tower) == tower.invested_dew,
		"rank Dew bought this rest comes back in full, like the rest of it (placed this rest)")
	if "rank_dew_spent" in run_state:
		_check(run_state.rank_dew_spent == 69, "RunState counts Dew spent on ranks")

	# Growing a ranked Warden pays the rank difference (warden_stats.md): for each rank held, its price
	# at the new tier minus its price at the old one. Sprout ×0.5 → Sporeling ×1: (30-15)+(48-24)+(60-30).
	var grow := tower.get_grow_cost(sporeling_data)
	var evolve_base: int = dreams.get_evolve_cost(sporeling_data)
	_check(grow.base == evolve_base and grow.ranks == 15 + 24 + 30 and grow.total == evolve_base + 69,
		"a rank III Sprout growing into a Sporeling pays %d + 69 (%s)" % [evolve_base, grow])
	var invested_before := tower.invested_dew
	var dew_before: int = run_state.dew
	# Ranks and their choices carry through evolution.
	placer.evolve(tower, sporeling_data)
	_check(run_state.dew == dew_before - grow.total and tower.invested_dew == invested_before + grow.total,
		"the whole grow cost is charged and counts as invested (selling refunds it)")
	_check(tower.tower_data == sporeling_data and tower.rank == 3 and tower.rank_choices == [Tower.Focus.POWER, Tower.Focus.POWER, Tower.Focus.REACH],
		"the choices grow with it")
	_check(is_equal_approx(tower.get_damage(), sporeling_data.damage * (1.0 + 2 * Tower.FOCUS_POWER)), "with the ranks' damage")
	_check(tower.get_nurture_cost() == 90, "a base Warden's rank IV costs 90 × 1")
	placer.nurture(tower, Tower.Focus.SWIFT)
	_check(is_equal_approx(tower.get_attacks_per_second(), sporeling_data.attacks_per_second * (1.0 + Tower.FOCUS_SWIFT)),
		"Swift: +12% attack speed")
	placer.evolve(tower, driftspore_data)
	_check(tower.get_nurture_cost() == 270, "a branch's rank V costs 135 × 2")
	var shade := _spawn(main, tower.global_position + Vector2(64, 0))
	tower.hit(shade, 1.0, false, Tower.NO_CRIT)
	_check(is_equal_approx(shade.statuses.potency(EnemyStatuses.SPORED), tower.get_damage() * Tower.SPORE_POTENCY),
		"Spored potency uses the ranked damage")
	placer.nurture(tower, Tower.Focus.POWER)
	_check(tower.rank == 5 and not tower.can_nurture() and not placer.nurture(tower), "rank V is the most")
	_check(tower.choices_text() == "Power ×3, Swift, Reach", "the story of its ranks (%s)" % tower.choices_text())

	# Deep: +18% Potency per rank, which strengthens its statuses (tower_design.md "Potency: effect damage and
	# status strength"); no separate duration bonus any more (only with status Potency off, for the A/B).
	var deep := _build(placer, map_generator, sporeling_data)
	placer.nurture(deep, Tower.Focus.DEEP)
	var soaked := _spawn(main, deep.global_position + Vector2(64, 0))
	deep.hit(soaked, 1.0, false, Tower.NO_CRIT)
	_check(is_equal_approx(deep.get_potency(), 1.0 + Tower.deep_share()), "Deep: +25% Potency")
	_check(is_equal_approx(soaked.statuses.time_left(EnemyStatuses.SPORED), EnemyStatuses.DEFAULT_DURATION[EnemyStatuses.SPORED]),
		"Deep: no longer lengthens its statuses")
	Tower.status_potency_on = false
	var old_rule := _spawn(main, deep.global_position + Vector2(64, 0))
	deep.hit(old_rule, 1.0, false, Tower.NO_CRIT)
	_check(is_equal_approx(old_rule.statuses.time_left(EnemyStatuses.SPORED), EnemyStatuses.DEFAULT_DURATION[EnemyStatuses.SPORED] * (1.0 + Tower.FOCUS_DEEP_OLD)),
		"status Potency off: Deep's old +18% duration")
	Tower.status_potency_on = true

	# Old saves: a rank and a Focus chosen at III migrate to Power for I–II and the Focus from III.
	var old := _build(placer, map_generator, sporeling_data)
	old.rank = 4
	old.focus = Tower.Focus.REACH
	_check(old.choice_count(Tower.Focus.POWER) == 2 and old.choice_count(Tower.Focus.REACH) == 2,
		"an old rank IV Reach Warden: Power, Power, Reach, Reach (%s)" % [old.rank_choices])

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
	_check(keeper.get_nurture_cost() == 60, "a Memory Warden's rank I costs 30 × 2")
	stag.queue_free()
	keeper.queue_free()

	# Group Nurture: one rank each while the Dew lasts, nearest the Heartwood first.
	var group: Array[Tower] = []
	for i in 3:
		group.append(_build(placer, map_generator, sprout_data))
	seller.set_selection(group)
	run_state.dew = 32  # Two of the three (15 each)
	var plan: Array = seller.plan_nurture(group)
	var nearest: Array = seller.sort_by_heartwood(group).slice(0, 2)
	_check(plan[0].size() == 2 and plan[1] == 30, "can nurture 2 of 3 for 30 Dew")
	_check(seller.full_nurture_cost(group) == [3, 45], "all three would cost 45")
	_check(seller.nurture_group(group) == 2 and run_state.dew == 2, "group Nurture raises 2 of 3")
	_check(nearest.all(func(t: Tower) -> bool: return t.rank == 1), "the 2 nearest the Heartwood")

	# R arms the Warden panel's rank choices (1–4); it doesn't nurture on its own any more.
	var r_events := InputMap.action_get_events("nurture_warden")
	_check(r_events.any(func(e: InputEvent) -> bool: return e is InputEventKey and e.physical_keycode == KEY_R),
		"R is the Nurture hotkey")
	run_state.dew = 1000
	var asked := [0]
	seller.nurture_asked.connect(func() -> void: asked[0] += 1)
	var ranks_before: Array = group.map(func(t: Tower) -> int: return t.rank)
	var press := InputEventAction.new()
	press.action = "nurture_warden"
	press.pressed = true
	seller._unhandled_input(press)
	_check(asked[0] == 1 and group.map(func(t: Tower) -> int: return t.rank) == ranks_before,
		"R asks for the rank choice instead of nurturing")

	# Group Nurture asks once: one choice for the whole group.
	_check(seller.nurture_group(group, Tower.Focus.SWIFT) == 3 \
		and group.all(func(t: Tower) -> bool: return t.focus == Tower.Focus.SWIFT and t.rank_choices[-1] == Tower.Focus.SWIFT),
		"one choice for the whole group")

	# First Care (Grove perk): the run's first free_nurtures ranks cost nothing.
	if "free_nurtures" in run_state:
		var freebie := _build(placer, map_generator, sprout_data)
		var paid := freebie.invested_dew
		run_state.free_nurtures = 2
		run_state.dew = 100
		var normal := roundi(Tower.RANK_COSTS[0] * freebie.get_tier_cost_multiplier())  # 30 × 0.5 = 15 on a Sprout
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

	# The Nurture button says what a rank adds to the next growth (warden_stats.md; growing pays the ranks).
	var drift := _build(placer, map_generator, driftspore_data)
	var next := drift.next_growth()
	_check(next != null and next.tier == 3, "a branch's next growth is its final (%s)" % (next.get_id() if next else "none"))
	_check(drift.get_next_rank_growth_extra(next) > 0, "and rank I adds to what that growth costs (+%d)" % drift.get_next_rank_growth_extra(next))
	var before_grow: int = drift.get_grow_cost(next).total
	var extra := drift.get_next_rank_growth_extra(next)
	placer.nurture(drift)
	_check(drift.get_grow_cost(next).total == before_grow + extra, "the note matches the new grow cost (%d -> %d)" % [before_grow, drift.get_grow_cost(next).total])
	# Nurture range preview: pointing at Reach shows exactly the range the Warden has after that rank.
	var reacher := _build(placer, map_generator, sporeling_data)
	run_state.dew = 100000
	placer.show_rank_preview([reacher], Tower.Focus.REACH)
	var shown: Array = placer.rank_preview()
	var before_range := reacher.get_range_cells()
	_check(shown.size() == 1 and is_equal_approx(shown[0][1], before_range) and shown[0][2] > before_range,
		"the preview shows the current ring and a bigger one for Reach (%s)" % [shown])
	_check(is_equal_approx(reacher.get_range_cells(), before_range) and reacher.rank == 0, "previewing leaves the Warden as it was")
	placer.nurture(reacher, Tower.Focus.REACH)
	_check(shown.size() == 1 and is_equal_approx(reacher.get_range_cells(), shown[0][2]),
		"the preview radius is the post-Nurture range (%.2f vs %.2f)" % [shown[0][2] if shown.size() == 1 else -1.0, reacher.get_range_cells()])
	placer.hide_rank_preview()
	_check(placer.rank_preview().is_empty(), "the rings go on hover end")
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
