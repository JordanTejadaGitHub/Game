extends SceneTree

# Headless test for the generic Dream cards 142–168 (dream_design.md "Generic Commons and
# Uncommons" and "Generic cards, second batch"): the parts DreamState owns (stat and per-hit rules,
# economy hooks in RunState / TowerSeller / DriftDirector, rest rules, Needs). Tower / Enemy / HUD
# hooks (Sudden Bloom, Watchful Rest, Skyward range, Tangled, trample, glows) are tested there.
#   godot --headless --path . --script res://tests/test_generic_cards.gd --fixed-fps 60

const IDS := ["gathered_dew", "fair_trade", "call_of_the_wild", "mending_bark", "lasting_dreams", "short_roots",
	"forests_edge", "crowded_path", "crowded_path_ii", "lone_hunter", "lone_hunter_ii", "skyward_gaze",
	"fresh_growth", "fresh_growth_ii", "underdog", "underdog_ii", "weathered_walls", "heavy_air",
	"wandering_mind", "winding_path", "shelter_of_stones", "cliffside", "thick_bark", "thick_bark_ii",
	"sudden_bloom", "last_breath", "last_breath_ii", "tangled", "watchful_rest", "watchful_rest_ii",
	"glimmering_hunt", "straightaway", "straightaway_ii", "heart_of_the_maze", "echoing_steps"]

var failures := 0
var main: Node
var dreams: DreamState
var run_state: RunState
var map_generator

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	run_state = main.get_node("%RunState")
	map_generator = main.get_node("%MapGenerator")
	_test_pool()
	_test_economy()
	_test_stat_rules()
	_test_hit_rules()
	_test_rest_rules()
	_test_map_rules()
	print("generic cards test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _test_pool() -> void:
	for id in IDS:
		var card := _card(id)
		if card:
			_check(card.in_start_pool == (id != "wandering_mind"), "%s: pool" % id)
	_check(_card("skyward_gaze").min_act == 2 and _card("glimmering_hunt").min_act == 2, "Skyward Gaze / Glimmering Hunt from act 2")
	_reset()
	_check(not dreams.is_eligible(_card("heavy_air")) and dreams.is_eligible(_card("tangled")),
		"Heavy Air needs a Warden that slows; Tangled any status (Spored)")
	dreams.unlocked["dewdrop"] = true
	_check(dreams.is_eligible(_card("heavy_air")), "…Dewdrop (Soaked) is enough")
	_check(dreams.is_eligible(_card("short_roots")) == dreams.owns_range_at_most(2.0), "Short Roots needs a Warden with range 2 or less")

func _test_economy() -> void:
	_reset()
	run_state._dispel_dew_carry = 0.0
	var plain := run_state._scaled_dispel_dew(100)
	dreams.take(_card("gathered_dew"))
	dreams.take(_card("gathered_dew"))
	run_state._dispel_dew_carry = 0.0
	_check(run_state._scaled_dispel_dew(100) == roundi(plain * 1.2), "Gathered Dew ×2: +20% dispel Dew (%d vs %d)" % [run_state._scaled_dispel_dew(100), plain])
	var seller = main.get_node("%TowerSeller")
	var tower := _plant("sporeling", Vector2(100, 100))
	tower.invested_dew = 100
	_check(seller.get_refund(tower) == 75, "no Fair Trade: 75% at a rest")
	dreams.take(_card("fair_trade"))
	_check(seller.get_refund(tower) == 85, "Fair Trade: 85% at a rest")
	dreams.take(_card("fair_trade"))
	dreams.take(_card("fair_trade"))
	_check(seller.get_refund(tower) == 100 and is_equal_approx(dreams.get_refund_share(0.5, false), 0.75), "…stacks to 100% / 75%")
	_check(dreams.get_call_early_bonus(7, 10) == 7, "call early: plain")
	dreams.take(_card("call_of_the_wild"))
	_check(dreams.get_call_early_bonus(7, 10) == 14 and dreams.get_call_early_bonus(30, 10) == 20, "Call of the Wild: double, up to 20")
	dreams.take(_card("winding_path"))
	_check(dreams.get_rest_bonus_add() == dreams.path_length / 10, "Winding Path: +1 Dew per 10 path tiles (%d tiles)" % dreams.path_length)
	var rerolls := dreams.rerolls_left
	dreams.take(_card("wandering_mind"))
	_check(dreams.rerolls_left == rerolls + 2, "Wandering Mind: +2 rerolls")
	dreams.take(_card("weathered_walls"))
	var wall: TowerData = load("res://resource/tower/thornwall.tres")
	dreams._walls_planted = 9
	_check(dreams.get_build_cost_at(wall, Vector2(3, 3)) == 0, "Weathered Walls: the 10th Thornwall is free")
	dreams._walls_planted = 10
	_check(dreams.get_build_cost_at(wall, Vector2(3, 3)) > 0, "…the 11th isn't")
	_clear()

func _test_stat_rules() -> void:
	_reset()
	var dewdrop: TowerData = load("res://resource/tower/dewdrop.tres")
	var damp := dreams.get_status_duration(dewdrop, EnemyStatuses.DAMP)
	dreams.take(_card("lasting_dreams"))
	dreams.take(_card("lasting_dreams"))
	_check(is_equal_approx(dreams.get_status_duration(dewdrop, EnemyStatuses.DAMP), damp + 2.0), "Lasting Dreams ×2: +2 s")
	dreams.take(_card("heavy_air"))
	_check(is_equal_approx(dreams.get_status_strength_multiplier(EnemyStatuses.DAMP), 1.2)
		and dreams.get_status_strength_multiplier(EnemyStatuses.MARKED) == 1.0, "Heavy Air: slows 20% stronger, nothing else")
	# Short Roots and Forest's Edge
	dreams.take(_card("short_roots"))
	dreams.take(_card("forests_edge"))
	var short: TowerData = null
	var long: TowerData = null
	for data in main.get_node("%TowerPlacer").towers:
		if data.can_attack and data.attack_range <= 2.0 and short == null:
			short = data
		elif data.can_attack and data.attack_range > 2.0 and long == null:
			long = data
	var far := Vector2(100, 100)
	if short:
		_check(_row(short, far).active, "Short Roots: on for %s (range %.1f)" % [short.display_name, short.attack_range])
	if long:
		_check(not _row(long, far, "short_roots").active, "…off for range %.1f" % long.attack_range)
	var start: Vector2 = map_generator.startPath
	_check(_row(long if long else short, start + Vector2(2, 2), "forests_edge").active
		and not _row(long if long else short, start + Vector2(4, 0), "forests_edge").active, "Forest's Edge: within 3 cells of the start")
	# Fresh Growth: planted during a drift, until the next rest
	dreams.take(_card("fresh_growth"))
	var director: DriftDirector = main.get_node("%DriftDirector")
	var tower := _plant("sporeling", Vector2(100, 100))
	director.resting = false
	dreams._mark_fresh(tower)
	director.resting = true
	var base := dreams.get_soothe_multiplier(tower)
	_check(dreams.is_fresh(tower) and _row(tower.tower_data, tower.cell, "fresh_growth", tower).active, "Fresh Growth: planted during a drift")
	dreams._rest_rules(false)
	_check(not dreams.is_fresh(tower) and is_equal_approx(base - dreams.get_soothe_multiplier(tower), 0.30), "…+30% until the next rest")
	# Underdog: the least soothing attackers of the block
	dreams.take(_card("underdog"))
	var others: Array[Tower] = []
	for i in 4:
		others.append(_plant("sporeling", Vector2(102 + i * 3, 100)))
	var log := DamageLog.instance
	for i in others.size():
		log._row(others[i])["block"] = 100.0 * (i + 1)
	log._row(tower)["block"] = 1000.0
	dreams._pick_underdogs()
	_check(dreams.is_underdog(others[0]) and dreams.is_underdog(others[2]) and not dreams.is_underdog(others[3])
		and not dreams.is_underdog(tower), "Underdog: the 3 that soothed least")
	_check(_row(others[0].tower_data, others[0].cell, "underdog", others[0]).active, "…get their bonus")
	_clear()

func _test_hit_rules() -> void:
	_reset()
	var tower := _plant("sporeling", Vector2(100, 100))
	var a := _spawn(map_generator.startPath + Vector2(0, 0))
	_check(dreams.on_hit_multiplier(tower, a) == 1.0, "no card: ×1")
	dreams.take(_card("lone_hunter"))
	_check(is_equal_approx(dreams.on_hit_multiplier(tower, a), 1.3), "Lone Hunter: +30% alone")
	var b := _spawn(map_generator.startPath, Vector2(40, 0))
	_check(dreams.on_hit_multiplier(tower, a) == 1.0, "…not with a nightmare within 2 cells")
	# Crowded Path counts both in range
	dreams.take(_card("crowded_path"))
	var near := _plant("sporeling", map_generator.startPath + Vector2(1, 1))
	_check(dreams.count_in_range(near) == 2 and _row(near.tower_data, near.cell, "crowded_path", near).damage > 0.05,
		"Crowded Path: +3% per nightmare in range (%d)" % dreams.count_in_range(near))
	# Last Breath: the neighbour takes 10% of the dispelled one's max health, no chain
	dreams.take(_card("last_breath"))
	var before: float = b.health
	a.take_damage(a.health + 1.0, "", false, false, null, &"")
	dreams._last_breath(a)  # Test nightmares aren't wired to the spawner's enemy_cleansed
	_check(b.health < before and is_equal_approx(before - b.health, a.max_health * 0.1) or b.is_cleansed,
		"Last Breath: 10%% of its max health on the nightmare beside it (%.1f)" % (before - b.health))
	# Glimmering Hunt: elites drop a shard 10% of the time
	dreams.take(_card("glimmering_hunt"))
	dreams._glimmer_rng.seed = 3
	var shards := dreams.dreamlight_shards
	var elite := _spawn(map_generator.startPath + Vector2(0, 2))
	elite.elite = true
	for i in 200:
		dreams._glimmer(elite)
	var dropped := dreams.dreamlight_shards - shards
	_check(dropped > 5 and dropped < 40, "Glimmering Hunt: ~10%% of elites drop a shard (%d / 200)" % dropped)
	_free_enemies()
	_clear()

func _test_rest_rules() -> void:
	_reset()
	run_state.max_leaves = 15
	run_state.leaves = 10
	dreams.take(_card("mending_bark"))
	dreams._rest_rules(true)
	_check(run_state.leaves == 11, "Mending Bark: a perfect block regrows a leaf")
	dreams._rest_rules(false)
	_check(run_state.leaves == 11, "…not an imperfect one")
	dreams.take(_card("thick_bark"))
	_check(dreams.bark_charges == 1, "Thick Bark: ready")
	run_state.lose_leaves(5)
	_check(run_state.leaves == 11 and dreams.bark_charges == 0, "…saves the first leak whole (a boss's 5)")
	run_state.lose_leaves(1)
	_check(run_state.leaves == 10, "…then leaks cost leaves")
	dreams.take(_card("thick_bark_ii"))
	dreams._rest_rules(false)
	_check(dreams.bark_charges == 2, "Thick Bark II: 2 per block, refilled at the rest")
	run_state.leaves = 15

func _test_map_rules() -> void:
	_reset()
	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	# Cliffside: touching the island's edge
	dreams.take(_card("cliffside"))
	_check(is_equal_approx(dreams.get_range_bonus_at(sporeling, Vector2(1, 6)), 1.0)
		and dreams.get_range_bonus_at(sporeling, Vector2(5, 6)) == 0.0, "Cliffside: +1 range beside the edge")
	# Shelter of Stones: touching an obstacle
	dreams.take(_card("shelter_of_stones"))
	var obstacle: Vector2 = map_generator.obstacles.keys()[0]
	_check(_row(sporeling, obstacle + Vector2(1, 0), "shelter_of_stones").active
		and not _row(sporeling, Vector2(100, 100), "shelter_of_stones").active, "Shelter of Stones: beside an obstacle")
	# Straightaway: beside a straight stretch of 5+
	dreams.take(_card("straightaway"))
	var straight: Array = dreams._straight_cells.keys()
	_check(not straight.is_empty(), "the map has straight stretches (%d tiles)" % straight.size())
	if not straight.is_empty():
		var beside: Vector2 = straight[0] + Vector2(1, 1)
		var row := _row(sporeling, beside, "straightaway")
		_check(row.active and is_equal_approx(row.damage, 0.15) and is_equal_approx(row.range, 0.5), "Straightaway: +15% and +0.5 range")
	# Heart of the Maze: furthest along the path from the others
	dreams.take(_card("heart_of_the_maze"))
	var route: Array = dreams._path_index.keys()
	route.sort_custom(func(x: Vector2, y: Vector2) -> bool: return dreams._path_index[x] < dreams._path_index[y])
	var early := _plant("sporeling", route[2])
	_plant("sporeling", route[5])
	var far := _plant("sporeling", route[route.size() - 3])
	_check(dreams.get_heart_of_maze() == far and _row(sporeling, far.cell, "heart_of_the_maze", far).active
		and not _row(sporeling, early.cell, "heart_of_the_maze", early).active, "Heart of the Maze: the furthest one")
	_clear()
	# Echoing Steps: real route changes while nightmares walk
	dreams.take(_card("echoing_steps"))
	var director: DriftDirector = main.get_node("%DriftDirector")
	var walker := _spawn(map_generator.startPath)
	director.resting = false
	dreams._last_route = PackedVector2Array([Vector2.ZERO])
	dreams._last_echo = -INF
	dreams._update_bends()
	director.resting = true
	_check(is_equal_approx(dreams.get_echo_bonus(), 0.05), "Echoing Steps: +5% per route change this drift")
	dreams._update_bends()
	_check(is_equal_approx(dreams.get_echo_bonus(), 0.05), "…an unchanged route doesn't count")
	dreams._on_drift_started(2)
	_check(dreams.get_echo_bonus() == 0.0, "…until the drift ends")
	walker.free()

# --- Helpers ------------------------------------------------------------------------------------------

func _reset() -> void:
	_clear()
	dreams.stacks.clear()
	dreams.unlock_everything = false
	dreams.unlocked = {"sprout": true, "thornwall": true, "sporeling": true}
	dreams._walls_planted = 0
	dreams._refill_bark()

func _card(id: String) -> UpgradeData:
	for card in dreams.pool:
		if card.id == id:
			return card
	_check(false, "card %s exists" % id)
	return null

func _row(data: TowerData, cell: Vector2, id: String = "short_roots", tower: Tower = null) -> Dictionary:
	for row in dreams.get_card_effects(data, cell, tower):
		if row.id == id or row.id == id + "_ii":
			return row
	return {"active": false, "damage": 0.0, "range": 0.0}

func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = tower.MAP_GRID.calculate_map_position(cell)
	main.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	return tower

func _clear() -> void:
	for tower in main.get_node("%TowerContainer").get_children():
		tower.free()

func _spawn(cell: Vector2, offset: Vector2 = Vector2.ZERO) -> Node2D:
	var spawner = main.get_node("%EnemyContainer")
	var enemy = spawner.enemy_scene.instantiate()
	enemy.enemy_data = TestGrove._load_enemy_types()[0]
	spawner.add_child(enemy)
	enemy.position = enemy.grid.calculate_map_position(cell) + offset
	enemy.set_path(PackedVector2Array([enemy.grid.calculate_grid_coordinates(enemy.position)]))
	enemy.set_process(false)
	return enemy

func _free_enemies() -> void:
	for child in main.get_node("%EnemyContainer").get_children():
		child.free()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
