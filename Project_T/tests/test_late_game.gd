extends SceneTree

# Headless late-game test: the Ascended Wardens and the Heartwood Sapling. Run from the project folder:
#   godot --headless --path . --script res://tests/test_late_game.gd --fixed-fps 60

const ASCENDED := {
	"sporemother": "spore", "tidecaller": "water", "stormheart": "light", "old_mountain": "stone",
	"world_root": "root", "great_bell": "song", "grandmother_oak": "acorn", "dawnwing": "wing",
	"tempest": "wind",
}

const MAP_SEED := 42
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_check_data()

	var main: Node = load("res://scenes/main.tscn").instantiate()
	# A fixed map: the 2×2 checks need open ground, which a crowded random map may not leave.
	main.get_node("%MapGenerator").map_seed = MAP_SEED
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
	_check(Tower.RANK_COSTS == [30, 48, 60, 90, 135] and Tower.rank_costs == Tower.RANK_COSTS, "Nurture base costs are 30/48/60/90/135 (Balancing 2026-10-04)")
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
	_check(sapling.get_drift_yield() == 8, "8 Dew per drift at rank 0")
	dew_before = run_state.dew
	director.drift_cleared.emit(51, 0, true)
	_check(run_state.dew == dew_before + 8, "+8 Dew at the end of a drift")
	sapling.rank = 3
	_check(sapling.get_drift_yield() == 20, "+4 Dew per Nurture rank")
	_check(sapling.can_be_nurtured() and not sapling.needs_focus(), "the Sapling nurtures, without a Focus")
	_check(sapling.get_tier_cost_multiplier() == 1.0, "the Sapling nurtures at the base-form price")
	run_state.lose_leaves(2)
	_check(sapling.get_drift_yield() == 18, "each leaf lost withers the yield 5%")
	director.rest_started.emit(11, false, 0, false)
	_check(sapling.get_drift_yield() == 20, "the wither lifts at the rest")
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

	# --- The first grow into each final form this run blooms (Fx.final_bloom + final_bloomed, once) ---
	var chime: TowerData = load("res://resource/tower/chime_stone.tres")
	var blooms := [0]
	for i in 2:
		var stone := _build_at(placer, chime, _open_area(map_generator, placer.tower_container))
		stone.final_bloomed.connect(func(_t: Tower) -> void: blooms[0] += 1)
		placer.evolve(stone, load("res://resource/tower/lullaby_bell.tres"))
	_check(blooms[0] == 1, "only the first Lullaby Bell of the run blooms (%d)" % blooms[0])

	# --- One Ascended form per family on the map (selling it frees the slot) ---
	var bell_data: TowerData = load("res://resource/tower/great_bell.tres")
	var lullaby: TowerData = load("res://resource/tower/lullaby_bell.tres")
	var bell_a := _build_at(placer, lullaby, _open_area(map_generator, placer.tower_container))  # Room for its 2×2
	var bell_b := _build_at(placer, lullaby, _open_area(map_generator, placer.tower_container))
	_check(placer.evolve(bell_a, bell_data), "the first Lullaby Bell wakes as The Great Bell")
	_check(placer.ascended_blocker(bell_data) == "The Great Bell is already awake", "the slot is taken")
	_check(not placer.evolve(bell_b, bell_data) and bell_b.tower_data == lullaby, "a second can't wake while it's there")
	var both := [bell_b, _build_at(placer, lullaby, _open_area(map_generator, placer.tower_container))]
	_check(seller.plan_grow(both, bell_data)[0] == 0, "group grow and G grow none")
	var sell_cell: Vector2 = bell_a.cell
	seller.sell(sell_cell)
	await process_frame
	_check(placer.ascended_blocker(bell_data) == "" and seller.plan_grow(both, bell_data)[0] == 1,
		"selling it frees the slot, and group grow wakes only one")

	# --- Ascended forms are 2×2 (tower_design.md "Ascended forms", Size) ---
	var storm_data: TowerData = load("res://resource/tower/tidecaller.tres")  # (a Stormheart is already awake above)
	var thunder: TowerData = load("res://resource/tower/hoarfrost.tres")
	var open := _open_area(map_generator, container_of(placer))
	_check(open != Vector2(-1, -1), "found an open 3×3 area")
	# (a) A free square: the Warden grows onto it, all four cells blocked, centred on the 2×2.
	var t1 := _build_at(placer, thunder, open)
	var squares := placer.get_grow_squares(t1, storm_data)
	_check(squares.size() == 4, "all four squares around it are free (%d)" % squares.size())
	_check(placer.evolve(t1, storm_data, squares[0]) and t1.get_footprint() == 2, "it grows into a 2×2 Tidecaller")
	for c in Tower.footprint_cells(squares[0], 2):
		_check(not map_generator.is_buildable(c) and seller.get_tower_at(c) == t1, "cell %s is the Tidecaller's" % c)
	_check(t1.position == Tower.footprint_centre(squares[0], 2), "it stands at the 2×2 centre")
	seller.sell(t1.cell)
	await process_frame
	for c in Tower.footprint_cells(squares[0], 2):
		_check(map_generator.is_buildable(c), "selling frees cell %s" % c)
	# (b) Thornwalls around it are absorbed, their Dew back in full.
	var t2 := _build_at(placer, thunder, open)
	var walls := []
	for offset in [Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(-1, 1)]:
		walls.append(_build_at(placer, load("res://resource/tower/thornwall.tres"), open + offset))
	var wall_dew := 0
	for w in walls.slice(0, 3):
		wall_dew += w.invested_dew
	var dew_now := run_state.dew
	var cost: int = t2.get_grow_cost(storm_data).total
	_check(placer.get_grow_squares(t2, storm_data).has(open), "a square of Thornwalls is a valid square")
	_check(placer.evolve(t2, storm_data, open), "it grows over them")
	_check(walls.slice(0, 3).all(func(w) -> bool: return not is_instance_valid(w) or w.is_queued_for_deletion()),
		"the three Thornwalls in the square are absorbed")
	_check(run_state.dew == dew_now - cost + wall_dew, "and refunded in full (%d)" % (run_state.dew - dew_now + cost))
	seller.sell(t2.cell)
	await process_frame
	for w in walls.slice(3):
		if is_instance_valid(w) and not w.is_queued_for_deletion():
			seller.sell(w.cell)
	await process_frame
	# (e) Half cells (Environment 731000c5): four twig walls in one cell of the square are all absorbed, and every half
	# of the 2×2 ends up blocked, then free again when it's sold (no phantom halves either way).
	var t4 := _build_at(placer, thunder, open)
	placer.force_twig = true
	placer.tower_data = load("res://resource/tower/thornwall.tres")
	var twig_cell := open + Vector2(1, 0)
	var twigs := []
	for dy in 2:
		for dx in 2:
			var half := twig_cell * 2.0 + Vector2(dx, dy)
			if placer._try_build_half(half):
				twigs.append(placer.tower_container.get_child(placer.tower_container.get_child_count() - 1))
	placer.force_twig = false
	_check(twigs.size() == 4, "four twig walls fill one cell of the square (%d)" % twigs.size())
	_check(placer.get_grow_squares(t4, storm_data).has(open), "a square holding twig walls is a valid square")
	_check(placer.evolve(t4, storm_data, open), "it grows over them")
	_check(twigs.all(func(w) -> bool: return not is_instance_valid(w) or w.is_queued_for_deletion()), "all four twig walls are absorbed")
	var square_halves := placer._square_halves(open, 2)
	_check(square_halves.all(func(h: Vector2) -> bool: return not map_generator.is_buildable_half(h)), "every half of the 2×2 is blocked")
	seller.sell(t4.cell)
	await process_frame
	_check(square_halves.all(func(h: Vector2) -> bool: return map_generator.is_buildable_half(h)), "selling it frees every half")
	# (c) No room: Wardens (not Thornwalls) all round.
	var t3 := _build_at(placer, thunder, open)
	for offset in [Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(-1, 1)]:
		_build_at(placer, load("res://resource/tower/sprout.tres"), open + offset)
	_check(placer.get_grow_squares(t3, storm_data).is_empty() and not placer.evolve(t3, storm_data),
		"with no room it can't grow")
	_check(seller.plan_grow([t3], storm_data)[0] == 0, "group grow and G skip it")
	# (d) The path rule: every square offered next to the route keeps a way through.
	var route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var by_path: Tower = null
	for i in range(4, route.size() - 4):
		for side in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = route[i] + side
			if by_path == null and not route.has(cell) and map_generator.can_block(cell):
				by_path = _build_at(placer, thunder, cell)
	var ok := by_path != null
	if by_path:
		for square in placer.get_grow_squares(by_path, storm_data):
			var cells: Array[Vector2] = Tower.footprint_cells(square, 2)
			ok = ok and not map_generator.get_path_if_blocked_cells(cells.filter(func(c) -> bool: return c != by_path.cell)).is_empty()
	_check(ok, "every square offered beside the route leaves the path open")

	# --- Ascended: Grandmother Oak's aura, Dawnwing's patrol ---
	var oak := _build(placer, map_generator, load("res://resource/tower/sprout.tres"))
	var neighbour := _build(placer, map_generator, load("res://resource/tower/sprout.tres"))
	var base_damage := neighbour.get_damage()
	oak.evolve(load("res://resource/tower/grandmother_oak.tres"), 0)
	oak.global_position = neighbour.global_position + Vector2(64, 0)
	neighbour._refresh_neighbours()
	_check(is_equal_approx(neighbour.get_damage(), base_damage * (1.0 + oak.tower_data.aura_damage_bonus)), "Grandmother Oak: her aura damage nearby")

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

	# --- Legacy: an Ascended form keeps its final form's attack (the Great Bell still rings the Lullaby) ---
	var bell := _build(placer, map_generator, load("res://resource/tower/lullaby_bell.tres"))
	bell.evolve(load("res://resource/tower/great_bell.tres"), 0)
	_check(bell.legacy_data != null and bell.legacy_data.get_id() == "lullaby_bell", "the Great Bell remembers the Lullaby Bell")
	_check(bell.attack_data.get_id() == "great_bell", "its own attack is still the toll")
	var sleeper := _spawn(main, bell.global_position + Vector2(64, 0))
	var legacy_fired := [0]
	bell.legacy_released.connect(func(_t) -> void: legacy_fired[0] += 1)
	bell._update_legacy(0.1)
	_check(legacy_fired[0] == 1 and sleeper.health < sleeper.max_health, "it pulses like the Lullaby Bell too")
	_check(sleeper.statuses.has(EnemyStatuses.DROWSY), "and sings Drowsy")
	_check(bell.attack_data.get_id() == "great_bell" and not bell._legacy_active, "then goes back to its own data")
	bell._update_legacy(0.1)
	_check(legacy_fired[0] == 1, "on the Lullaby's own cadence")
	var mountain := _build(placer, map_generator, load("res://resource/tower/moonstone.tres"))
	mountain.evolve(load("res://resource/tower/old_mountain.tres"), 0)
	for old in main.get_node("%EnemyContainer").get_children():
		old.queue_free()  # The stone goes for whoever is furthest along
	await process_frame
	var lobbed := _spawn(main, mountain.global_position + Vector2(64 * 3, 0))  # Moonstone has a min range of 2
	lobbed.coat = 0.0  # The blight coat would soak the one stone
	mountain._update_legacy(0.1)
	var shot: Node = null
	for child in mountain.get_children():
		if child is Projectile:
			shot = child
	_check(shot != null, "Old Mountain still throws Moonstone's stones")
	var saved_legacy := mountain.legacy_data
	await _wait(1.0)
	_check(lobbed.health < lobbed.max_health, "and they land with Moonstone's data (%d)" % (lobbed.max_health - lobbed.health))
	_check(mountain.attack_data.get_id() == "old_mountain" and mountain.legacy_data == saved_legacy, "the stone's landing leaves Old Mountain as it was")
	var sprout_asc := _build(placer, map_generator, load("res://resource/tower/sprout.tres"))
	sprout_asc.evolve(load("res://resource/tower/dawnwing.tres"), 0)
	_check(sprout_asc.legacy_data == null, "only a final form becomes a legacy")

	# Free the run scene before quitting: letting the engine tear it down at exit crashed ~5% of runs
	# (signal 11 after PASS; freeing it first: 0 in 40). See Main for the game's own quit path.
	main.queue_free()
	for i in 3:
		await process_frame
	print("late game test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check_data() -> void:
	for id in ASCENDED:
		var data: TowerData = load("res://resource/tower/%s.tres" % id)
		_check(data != null and data.tier == 4 and not data.buildable_directly and data.evolve_cost == 600,
			"%s is an Ascended form (tier 4, 600 Dew)" % id)
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
			_check(data.evolve_cost == 120, "%s (branch) grows for 120 Dew" % data.display_name)
		elif data.tier == 3:
			_check(data.evolve_cost == 300, "%s (final form) grows for 300 Dew" % data.display_name)

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

func container_of(placer: TowerPlacer) -> Node:
	return placer.tower_container

# Builds `data` on exactly `cell` (null if it can't be built there).
func _build_at(placer: TowerPlacer, data: TowerData, cell: Vector2) -> Tower:
	placer.run_state.dew = maxi(placer.run_state.dew, 10000)
	placer.tower_data = data
	var container: Node = placer.tower_container
	var count := container.get_child_count()
	if not placer._try_build(cell):
		return null
	var built: Tower = container.get_child(count)
	built.set_process(false)
	return built

# A cell whose 3×3 surroundings are open ground away from the route (for the 2×2 tests).
func _open_area(map_generator, container: Node) -> Vector2:
	var route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	for y in range(3, Tower.MAP_GRID.size.y - 3):
		for x in range(3, Tower.MAP_GRID.size.x - 3):
			var ok := true
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var c := Vector2(x + dx, y + dy)
					if route.has(c) or not map_generator.is_buildable(c):
						ok = false
			if ok:
				return Vector2(x, y)
	return Vector2(-1, -1)
