extends SceneTree

# Headless late-game test: the Ascended Wardens and the Heartwood Sapling. Run from the project folder:
#   godot --headless --path . --script res://tests/test_late_game.gd --fixed-fps 60

const ASCENDED := {
	"sporemother": "spore", "tidecaller": "water", "stormheart": "light", "old_mountain": "stone",
	"world_root": "root", "great_bell": "song", "grandmother_oak": "acorn", "dawnwing": "wing",
	"tempest": "wind",
}

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_check_data()

	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var map_generator = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var run_state: RunState = main.get_node("%RunState")
	var dream_state: DreamState = main.get_node("%DreamState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	# A Sprout's "Grow into" lists only the families picked this run (screens_ui.md "Grow into").
	var sprout_data: TowerData = load("res://resource/tower/sprout.tres")
	_check(Tower.grow_options(dream_state, sprout_data).is_empty(), "no family picked: a Sprout lists no families")
	dream_state.unlocked["sporeling"] = true
	var picked := Tower.grow_options(dream_state, sprout_data)
	_check(picked.size() == 1 and picked[0][0].get_id() == "sporeling", "one family picked: only it is listed")
	var driftspore_options := Tower.grow_options(dream_state, load("res://resource/tower/sporeling.tres"))
	_check(driftspore_options.any(func(o: Array) -> bool: return not o[1]), "a picked family's locked branches still show")
	dream_state.unlocked.erase("sporeling")
	dream_state.unlock_everything = true
	_check(Tower.grow_options(dream_state, sprout_data).size() == sprout_data.evolves_to.size(),
		"unlock_everything (Test Grove) lists every family")

	# --- Economy pass: pricier ranks and growth ---
	var sprout := _build(placer, map_generator, load("res://resource/tower/sprout.tres"))
	_check(Tower.RANK_COSTS == [25, 40, 60, 90, 135], "Nurture base costs are 25/40/60/90/135")
	var ascended_tower := _build(placer, map_generator, load("res://resource/tower/sprout.tres"))
	ascended_tower.evolve(load("res://resource/tower/stormheart.tres"), 0)
	_check(ascended_tower.get_tier_cost_multiplier() == 4.0, "Ascended Wardens nurture at ×4")
	_check(sprout.get_tier_cost_multiplier() == 0.5, "a Sprout still nurtures at ×0.5")

	# --- The Sapling ---
	director.drifts_started = 50
	TowerPlacer.sapling_enabled = false
	_check(not placer.can_take_sapling(), "switched off (sapling_enabled): never offered")
	TowerPlacer.sapling_enabled = true
	director.drifts_started = 0
	_check(not placer.can_take_sapling(), "no Sapling before drift 50")
	director.drifts_started = 50
	_check(placer.can_take_sapling(), "the Sapling is offered from drift 50")
	placer.take_sapling()
	_check(placer.build_mode and placer.tower_data == placer.sapling, "taking it selects it for planting")
	_check(placer.has_unplanted_sapling() and not placer.can_take_sapling(), "taken once, not yet planted")
	var planted: Array = []
	placer.sapling_planted.connect(func(t) -> void: planted.append(t))
	var origin := _free_square(map_generator)
	_check(origin != Vector2(-1, -1), "found a free 2×2 spot")
	var dew_before := run_state.dew
	_check(placer._try_build(origin), "the Sapling plants on a 2×2 spot")
	_check(run_state.dew == dew_before, "the Sapling is free")
	_check(planted.size() == 1 and not placer.build_mode, "sapling_planted fires and build mode ends")
	var sapling: Tower = planted[0]
	sapling.set_process(false)
	for cell in Tower.footprint_cells(origin, 2):
		_check(not map_generator.is_buildable(cell), "footprint cell %s is blocked" % cell)
		_check(seller.get_tower_at(cell) == sapling, "every footprint cell finds the Sapling")
	_check(sapling.position == Tower.footprint_centre(origin, 2), "the Sapling sits centred on its 2×2")
	_check(not seller.sell(origin), "the Sapling is rooted: it can't be sold")
	_check(not placer.has_unplanted_sapling(), "planted")
	placer.set_build_mode(false)

	# Yields.
	await process_frame
	_check(sapling.get_drift_yield() == 20, "20 Dew per drift at rank 0")
	dew_before = run_state.dew
	director.drift_cleared.emit(51, 0, true)
	_check(run_state.dew == dew_before + 20, "+20 Dew at the end of a drift")
	sapling.rank = 3
	_check(sapling.get_drift_yield() == 50, "+10 Dew per Nurture rank")
	_check(sapling.can_be_nurtured() and not sapling.needs_focus(), "the Sapling nurtures, without a Focus")
	_check(sapling.get_tier_cost_multiplier() == 3.0, "the Sapling nurtures at the final-form price")
	run_state.lose_leaves(2)
	_check(sapling.get_drift_yield() == 45, "each leaf lost withers the yield 5%")
	director.rest_started.emit(11, false, 0, false)
	_check(sapling.get_drift_yield() == 50, "the wither lifts at the rest")
	var light := dream_state.dreamlight
	sapling.rank = 0
	for i in 9:
		director.drift_cleared.emit(52 + i, 0, true)
	_check(dream_state.dreamlight == light + 1, "+1 Dreamlight every 10 drifts")

	# The run save keeps its whole footprint blocked.
	var saver = main.get_node("%RunSaver")
	var saved: Dictionary = saver.to_dict() if saver.has_method("to_dict") else {}
	if not saved.is_empty():
		_check(saved.towers.any(func(t) -> bool: return t.data == sapling.tower_data.resource_path),
			"the Sapling is saved")

	# --- One Ascended form per family on the map (selling it frees the slot) ---
	var bell_data: TowerData = load("res://resource/tower/great_bell.tres")
	var lullaby: TowerData = load("res://resource/tower/lullaby_bell.tres")
	var bell_a := _build(placer, map_generator, lullaby)
	var bell_b := _build(placer, map_generator, lullaby)
	_check(placer.evolve(bell_a, bell_data), "the first Lullaby Bell wakes as The Great Bell")
	_check(placer.ascended_blocker(bell_data) == "The Great Bell is already awake", "the slot is taken")
	_check(not placer.evolve(bell_b, bell_data) and bell_b.tower_data == lullaby, "a second can't wake while it's there")
	var both := [bell_b, _build(placer, map_generator, lullaby)]
	_check(seller.plan_grow(both, bell_data)[0] == 0, "group grow and G grow none")
	var sell_cell: Vector2 = bell_a.cell
	seller.sell(sell_cell)
	await process_frame
	_check(placer.ascended_blocker(bell_data) == "" and seller.plan_grow(both, bell_data)[0] == 1,
		"selling it frees the slot, and group grow wakes only one")

	# --- Ascended: Grandmother Oak's aura, Dawnwing's patrol ---
	var oak := _build(placer, map_generator, load("res://resource/tower/sprout.tres"))
	var neighbour := _build(placer, map_generator, load("res://resource/tower/sprout.tres"))
	var base_damage := neighbour.get_damage()
	oak.evolve(load("res://resource/tower/grandmother_oak.tres"), 0)
	oak.global_position = neighbour.global_position + Vector2(64, 0)
	neighbour._refresh_neighbours()
	_check(is_equal_approx(neighbour.get_damage(), base_damage * 1.4), "Grandmother Oak: +40% damage nearby")

	await process_frame
	paused = false  # The rest above opened a Dream offer, which pauses the run
	var bird := _build(placer, map_generator, load("res://resource/tower/sprout.tres"))
	bird.evolve(load("res://resource/tower/dawnwing.tres"), 0)
	bird.set_process(true)
	await _wait(0.2)
	_check(bird._patrol != null and is_instance_valid(bird._patrol), "Dawnwing sends out its patrol")
	var enemy := _spawn(main, bird._patrol.global_position)
	await _wait(0.5)
	_check(enemy.health < enemy.max_health, "the patrol strikes nightmares it passes")

	print("late game test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check_data() -> void:
	for id in ASCENDED:
		var data: TowerData = load("res://resource/tower/%s.tres" % id)
		_check(data != null and data.tier == 4 and not data.buildable_directly and data.evolve_cost == 400,
			"%s is an Ascended form (tier 4, 400 Dew)" % id)
		_check(data.line == ASCENDED[id], "%s belongs to the %s family" % [id, ASCENDED[id]])
		_check(data.texture != null and data.attack_texture != null and data.sprite_offset == Vector2(0, -24),
			"%s has its Ascended art" % id)
		var card: UpgradeData = load("res://resource/dream/dream_%s.tres" % id)
		_check(card != null and card.unlocks == data and not card.in_start_pool, "%s has its card" % id)
		# Every final form of the family grows into it.
		var finals := 0
		for file in DirAccess.get_files_at("res://resource/tower"):
			if not file.ends_with(".tres"):
				continue
			var other: TowerData = load("res://resource/tower/" + file.trim_suffix(".remap"))
			if other.tier == 3 and other.line == data.line:
				finals += 1
				_check(other.evolves_to.has(data), "%s can ascend into %s" % [other.display_name, id])
		_check(finals > 0, "%s has final forms to grow from" % id)
	for file in DirAccess.get_files_at("res://resource/tower"):
		if not file.ends_with(".tres"):
			continue
		var data: TowerData = load("res://resource/tower/" + file)
		if data.tier == 2 and not data.buildable_directly:
			_check(data.evolve_cost == 80, "%s (branch) grows for 80 Dew" % data.display_name)
		elif data.tier == 3:
			_check(data.evolve_cost == 200, "%s (final form) grows for 200 Dew" % data.display_name)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _spawn(main: Node, at: Vector2) -> Node2D:
	var spawner = main.get_node("%EnemyContainer")
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = at
	enemy.max_health = 100000
	enemy.health = 100000
	return enemy

# A top-left cell whose 2×2 is free and can be blocked without closing the path.
func _free_square(map_generator) -> Vector2:
	for y in Tower.MAP_GRID.size.y:
		for x in Tower.MAP_GRID.size.x:
			var cells := Tower.footprint_cells(Vector2(x, y), 2)
			if map_generator.can_block_cells(cells):
				return Vector2(x, y)
	return Vector2(-1, -1)

# Builds `data` on a free cell beside the path (keeping it open).
func _build(placer: TowerPlacer, map_generator, data: TowerData) -> Tower:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var container: Node = placer.tower_container
	placer.run_state.dew = 10000
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
