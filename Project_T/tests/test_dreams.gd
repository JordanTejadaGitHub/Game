extends SceneTree

# Headless test for status effects, Warden evolutions / attack kinds, and Dreams. Also runs an
# offer simulation that prints how often a Storm Grid build completes (target ≈ 1 run in 3).
#   godot --headless --path . --script res://tests/test_dreams.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_status_numbers()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242  # Same map every run, so failures reproduce
	root.add_child(main)
	await process_frame
	await _test_attacks(main)
	await _test_evolution(main)
	await _test_dream_flow(main)
	_test_card_effects(main)
	_test_new_cards(main)
	_test_clearing_cards(main)
	_simulate_storm_grid(main)
	print("dreams test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _test_status_numbers() -> void:
	var s := EnemyStatuses.new()
	s.apply(EnemyStatuses.DAMP)
	_check(is_equal_approx(s.get_speed_multiplier(), 0.9), "Damp slows 10%")
	s.apply(EnemyStatuses.DROWSY, 3)
	_check(is_equal_approx(s.get_speed_multiplier(), 0.9 - 0.24), "3 Drowsy stacks slow 24% more")
	s.apply(EnemyStatuses.DROWSY, 10)
	_check(s.stacks(EnemyStatuses.DROWSY) == 5, "Drowsy caps at 5")
	s.apply(EnemyStatuses.MARKED)
	_check(is_equal_approx(s.get_damage_taken_multiplier(), 1.25), "Marked: +25% soothe taken")
	var bolt := 0.0
	for i in 4:
		bolt += s.apply(EnemyStatuses.STATIC, 1, 0.0, 10.0)
	_check(bolt == 0.0 and s.stacks(EnemyStatuses.STATIC) == 4, "4 Static charges: no bolt yet")
	bolt = s.apply(EnemyStatuses.STATIC, 1, 0.0, 10.0)
	_check(is_equal_approx(bolt, 30.0) and not s.has(EnemyStatuses.STATIC), "5th Static charge: 3× bolt, reset")
	s.tick(4.1)
	_check(not s.has(EnemyStatuses.DAMP) and not s.has(EnemyStatuses.DROWSY), "Damp and Drowsy wear off")

	var spores := EnemyStatuses.new()
	spores.apply(EnemyStatuses.SPORED, 3, 0.0, 2.0)
	var soothe := spores.tick(1.0)
	_check(is_equal_approx(soothe, 6.0), "3 Spored stacks at potency 2 soothe 6/s (got %s)" % soothe)
	spores.set_in_fog(2.0)
	soothe = spores.tick(1.0)
	_check(is_equal_approx(soothe, 9.0), "Spored ticks +50%% in fog (got %s)" % soothe)

	var boss := EnemyStatuses.new()
	boss.is_boss = true
	boss.apply(EnemyStatuses.DROWSY, 10)
	_check(boss.stacks(EnemyStatuses.DROWSY) == 3, "bosses cap Drowsy at 3")
	var boss_bolt := 0.0
	for i in 5:
		boss_bolt += boss.apply(EnemyStatuses.STATIC, 1, 0.0, 10.0)
	_check(boss_bolt == 0.0, "bosses need 8 Static charges")

func _test_attacks(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	var map_generator = main.get_node("%MapGenerator")
	dreams.unlock_everything = true
	var dewdrop := _build(main, "dewdrop")
	var target := _spawn_near(main, dewdrop.cell + Vector2(1, 0))
	dewdrop._release()
	await _frames(30)
	_check(target.statuses.has(EnemyStatuses.DAMP), "Dewdrop makes creatures Damp")

	# Splash: a Rain Lily projectile landing between two creatures soothes both
	var lily := _build(main, "rain_lily")
	var a := _spawn_near(main, lily.cell + Vector2(1, 0))
	var b := _spawn_near(main, lily.cell + Vector2(1, 0))
	b.position += Vector2(20, 0)
	lily.projectile_landed(a, a.global_position)
	_check(a.health < a.max_health and b.health < b.max_health, "Rain Lily splash hits both")

	# Chain: 5 creatures in a row one cell apart; 3 hits normally, 5 when the first is Damp.
	# Clear earlier creatures first so the lightning can only jump along the row.
	_free_enemies(main)
	var storm := _build(main, "stormcap")
	var row: Array[Node2D] = []
	for i in 5:
		row.append(_spawn_near(main, storm.cell + Vector2(1, 0), Vector2(0, 64 * i - 128)))
	storm._chain_strike(row[2])
	var hit := row.filter(func(e: Node2D) -> bool: return e.health < e.max_health).size()
	_check(hit == 3, "Stormcap chains to 3 (hit %d)" % hit)
	for e in row:
		e.health = e.max_health
		e.apply_status(EnemyStatuses.DAMP)
	storm._chain_strike(row[2])
	hit = row.filter(func(e: Node2D) -> bool: return e.health < e.max_health).size()
	_check(hit == 5, "Stormcap chains 2 further through Damp creatures (hit %d)" % hit)

	# Cloud: Bloomcap's cloud makes creatures in it Drowsy
	_free_enemies(main)
	var bloom := _build(main, "bloomcap")
	var sleepy := _spawn_near(main, bloom.cell + Vector2(1, 0))
	sleepy.set_process(false)
	bloom._drop_cloud(sleepy)
	await _frames(40)
	_check(sleepy.statuses.has(EnemyStatuses.DROWSY), "Bloomcap cloud makes creatures Drowsy")
	_clear(main)
	dreams.unlock_everything = false

func _test_evolution(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	_reset_dreams(main)
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var run_state: RunState = main.get_node("%RunState")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var map_generator = main.get_node("%MapGenerator")
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	run_state.dew = 100
	placer.tower_data = sprout
	var cell := _free_cell(map_generator)
	placer._try_build(cell)
	var tower: Tower = seller.get_tower_at(cell)
	var path_before: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	_check(not placer.evolve(tower, sporeling), "can't grow into a Warden you haven't dreamed of")
	dreams.take(_card(dreams, "dream_sporeling"))
	_check(placer.get_buildable_towers().has(sporeling), "the Sporeling Dream makes it plantable")
	var dew := run_state.dew
	_check(placer.evolve(tower, sporeling), "Sprout grows into a Sporeling")
	_check(run_state.dew == dew - 15 and tower.invested_dew == 25, "growing costs 15 (invested %d)" % tower.invested_dew)
	_check(tower.tower_data == sporeling and tower.sprite.texture == sporeling.texture, "the Warden changes in place")
	_check(map_generator.get_path_from(map_generator.startPath) == path_before, "evolving doesn't change the path")
	var driftspore: TowerData = load("res://resource/tower/driftspore.tres")
	_check(not placer.evolve(tower, driftspore), "branches need their own Dream")
	dreams.take(_card(dreams, "evergreen"))
	dreams.take(_card(dreams, "dream_driftspore"))
	dew = run_state.dew
	_check(placer.evolve(tower, driftspore) and run_state.dew == dew - 34, "Evergreen: branch costs 45 → 34")
	seller.sell(cell)
	_clear(main)
	# Reset the Dream state for the flow test
	dreams.stacks.clear()
	dreams.unlocked = {"sprout": true, "thornwall": true}
	dreams.unlocks_changed.emit()

func _test_dream_flow(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	_reset_dreams(main)
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	var speed: GameSpeed = main.get_node("%GameSpeed")
	var offers := []
	dreams.offer_ready.connect(func(cards: Array, n: int) -> void: offers.append([cards, n]))
	# A rest after drift 5 (the family pick has given Firefly Jar)
	dreams.unlocked["firefly_jar"] = true
	director.drifts_started = 5
	director.rest_started.emit(1, false, 30, true)
	await process_frame
	_check(offers.size() == 1 and offers[0][1] == 5, "a Dream at the rest after drift 5")
	var offer: Array = offers[0][0] if not offers.is_empty() else []
	_check(offer.size() == 3, "a Dream offers 3 cards")
	_check(not offer.any(func(c: UpgradeData) -> bool: return c.kind == UpgradeData.Kind.UNLOCK_WARDEN),
		"Dreams never offer base Wardens (they come from the family pick)")
	_check(paused and speed.paused, "the game pauses for a Dream")
	if not offer.is_empty():
		dreams.choose(offer[0])
	_check(not dreams.is_offering() and not paused, "choosing closes the Dream and resumes")

	# Let it pass
	dreams._pending_drifts.append(10)
	var dew := run_state.dew
	dreams._show_next_offer()
	dreams.skip()
	_check(run_state.dew == dew + 15, "letting a Dream pass gives 15 Dew")

	# Eligibility
	_check(dreams.is_eligible(_card(dreams, "dream_stormcap")), "Stormcap card needs Firefly Jar (owned)")
	_check(not dreams.is_eligible(_card(dreams, "dream_rain_lily")), "Rain Lily card needs Dewdrop (not owned)")
	_check(not dreams.is_eligible(_card(dreams, "dream_sporeling")), "no base Warden cards in Dreams")

	# Boss Dream guarantees Rare+, and pity kicks in after 3 without (Thunderhead is the Rare here)
	dreams.unlocked["dewdrop"] = true
	dreams.take(_card(dreams, "dream_stormcap"))
	var boss_offer := dreams.make_offer(25)
	_check(boss_offer.any(func(c: UpgradeData) -> bool: return c.is_rare_or_better()), "boss Dream has a Rare+ card")
	var saw_rare_by_4 := true
	for trial in 20:
		dreams._dreams_without_rare = 3
		var pity_offer := dreams.make_offer(10)
		if not pity_offer.any(func(c: UpgradeData) -> bool: return c.is_rare_or_better()):
			saw_rare_by_4 = false
	_check(saw_rare_by_4, "pity: 3 Dreams without Rare+ guarantees one")
	director.drifts_started = 0
	_reset_dreams(main)  # The card chosen above was random
	_clear(main)

# Deepened, Entwined and Bittersweet cards (dream_design.md, added 2026-09-27).
func _test_new_cards(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	var run_state: RunState = main.get_node("%RunState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	var dewdrop: TowerData = load("res://resource/tower/dewdrop.tres")
	var driftspore: TowerData = load("res://resource/tower/driftspore.tres")
	var thornwall: TowerData = load("res://resource/tower/thornwall.tres")

	# Deepened: needs the base card; replaces its effect instead of adding to it
	_reset_dreams(main)
	dreams.unlocked["sporeling"] = true
	dreams.unlocked["dewdrop"] = true
	_check(not dreams.is_eligible(_card(dreams, "evergreen_ii")), "Evergreen II needs Evergreen")
	dreams.take(_card(dreams, "evergreen"))
	_check(dreams.is_eligible(_card(dreams, "evergreen_ii")), "Evergreen II offered once Evergreen is owned")
	dreams.take(_card(dreams, "evergreen_ii"))
	_check(dreams.get_evolve_cost(driftspore) == 27, "Evergreen II: 45 → 27, replacing Evergreen (got %d)" % dreams.get_evolve_cost(driftspore))
	_check(not dreams.is_eligible(_card(dreams, "evergreen_ii")), "a card deepens once")
	dreams.take(_card(dreams, "lingering_spores"))
	dreams.take(_card(dreams, "lingering_spores_ii"))
	_check(is_equal_approx(dreams.get_status_duration(sporeling, EnemyStatuses.SPORED), 10.0), "Lingering Spores II: Spored 5 + 5 s")
	_check(dreams.get_status_max_stacks(sporeling, EnemyStatuses.SPORED) == 10, "Lingering Spores II: Spored stacks to 10")
	dreams.take(_card(dreams, "soaked_through"))
	dreams.take(_card(dreams, "soaked_through_ii"))
	_check(is_equal_approx(dreams.get_status_duration(dewdrop, EnemyStatuses.DAMP), 12.0), "Soaked Through II: Damp ×3")
	var soaked := EnemyStatuses.new()
	soaked.apply(EnemyStatuses.DAMP, 1, 0.0, dreams.get_status_strength_multiplier(EnemyStatuses.DAMP))
	_check(is_equal_approx(soaked.get_speed_multiplier(), 0.85), "Soaked Through II: Damp slows 15%")
	dreams.take(_card(dreams, "cozy_corners"))
	_check(dreams.rule_level(&"cozy_corners") == 0, "Cozy Corners starts at its base level")
	dreams.take(_card(dreams, "cozy_corners_ii"))
	_check(dreams.rule_level(&"cozy_corners") == 1 and dreams.has_rule(&"cozy_corners"), "Cozy Corners II deepens the rule")
	var bends: Dictionary = dreams._bend_cells
	dreams._bend_cells = {Vector2(10, 10): true}
	_check(dreams.is_beside_bend(Vector2(12, 10), 2) and not dreams.is_beside_bend(Vector2(12, 10), 1)
		and not dreams.is_beside_bend(Vector2(12, 11), 2), "bend reach counts orthogonal steps")
	dreams._bend_cells = bends

	# Entwined: guaranteed in the next offer once the ingredients come together, then drawn normally
	_reset_dreams(main)
	dreams.unlocked["firefly_jar"] = true
	dreams.unlocked["dewdrop"] = true
	var soil := _card(dreams, "conductive_soil")
	_check(not dreams.is_eligible(soil), "Conductive Soil needs Stormcap + Rain Lily")
	dreams.take(_card(dreams, "dream_stormcap"))
	dreams.take(_card(dreams, "dream_rain_lily"))
	_check(dreams.make_offer(10).has(soil), "Entwined: Conductive Soil guaranteed once both are owned")
	var seen_again := 0
	for i in 30:
		if dreams.make_offer(10).has(soil):
			seen_again += 1
	_check(seen_again < 30, "Entwined: after one pass it's drawn normally (%d/30)" % seen_again)

	# Bittersweet: kept out until enabled, act 2+, at most one per offer, a real cost
	_reset_dreams(main)
	var deep_sleep := _card(dreams, "deep_sleep")
	dreams.allow_bittersweet = false
	_check(not dreams.is_eligible(deep_sleep, 2), "bittersweet cards stay out until enabled")
	dreams.allow_bittersweet = true
	_check(dreams.is_eligible(deep_sleep, 2) and not dreams.is_eligible(deep_sleep, 1), "bittersweet cards: act 2+")
	var most := 0
	for i in 60:
		var offer := dreams.make_offer(30)
		most = maxi(most, offer.filter(func(c: UpgradeData) -> bool: return c.is_bittersweet()).size())
	_check(most <= 1, "at most one bittersweet card per offer (saw %d)" % most)
	run_state.max_leaves = 20
	run_state.leaves = 20
	dreams.take(deep_sleep)
	_check(run_state.max_leaves == 16 and run_state.leaves == 16, "Deep Sleep: −4 max leaves, lose 4 now (%d/%d)" % [run_state.leaves, run_state.max_leaves])
	var sprout_tower := Tower.new()
	sprout_tower.tower_data = load("res://resource/tower/sprout.tres")
	_check(is_equal_approx(dreams.get_soothe_multiplier(sprout_tower), 1.4), "Deep Sleep: +40% soothe")
	sprout_tower.free()
	dreams.stacks.erase("deep_sleep")
	run_state.leaves = 4
	_check(not dreams.is_eligible(deep_sleep, 2), "Deep Sleep never offered when it would end the run")
	run_state.leaves = 16
	dreams.take(_card(dreams, "cheap_hedges"))
	dreams.take(_card(dreams, "hungry_roots"))
	_check(placer.get_cost(thornwall) == 6, "Hungry Roots: Thornwalls cost 6, even with Cheap Hedges")
	dreams.take(_card(dreams, "borrowed_dew"))
	_check(dreams.get_rest_bonus_add() == -15, "Borrowed Dew: rest bonus −15")
	var bug: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var before := director.get_health_scale(bug, 3)
	dreams.take(_card(dreams, "wild_growth"))
	_check(is_equal_approx(director.get_health_scale(bug, 3), before * 1.1), "Wild Growth: creatures +10% health")
	dreams.take(_card(dreams, "overgrown"))
	director.resting = false
	_check(not seller.can_sell(), "Overgrown: no selling while creatures walk")
	director.resting = true
	_check(seller.can_sell(), "Overgrown: selling is fine at a rest")
	dreams.take(_card(dreams, "restless_dreams"))
	_check(not dreams.can_skip(), "Restless Dreams: no Let it pass")
	var rare_runs := 0
	dreams.allow_bittersweet = false
	dreams.unlocked["firefly_jar"] = true
	dreams.take(_card(dreams, "dream_stormcap"))  # So a Rare (Thunderhead) can be offered
	for i in 3:
		if dreams.make_offer(10).any(func(c: UpgradeData) -> bool: return c.is_rare_or_better()):
			rare_runs += 1
	_check(rare_runs == 3, "Restless Dreams: the next 3 Dreams include a Rare+ (%d/3)" % rare_runs)
	run_state.max_leaves = 20
	run_state.leaves = 20
	_reset_dreams(main)

func _test_card_effects(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	var run_state: RunState = main.get_node("%RunState")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	var thornwall: TowerData = load("res://resource/tower/thornwall.tres")
	dreams.take(_card(dreams, "quickened_sap"))
	dreams.take(_card(dreams, "quickened_sap"))
	_check(is_equal_approx(dreams.get_attack_speed_multiplier(sprout), 1.2), "Quickened Sap stacks additively (×1.2)")
	dreams.take(_card(dreams, "sprout_surge"))
	_check(is_equal_approx(dreams.get_range_bonus(sprout), 0.5) and is_equal_approx(dreams.get_range_bonus(thornwall), 0.0),
		"Sprout Surge only affects Sprouts")
	dreams.take(_card(dreams, "cheap_hedges"))
	_check(placer.get_cost(thornwall) == 2, "Cheap Hedges: Thornwalls cost 2")
	var dew := run_state.dew
	dreams.take(_card(dreams, "morning_dew"))
	_check(run_state.dew == dew + 20 and dreams.get_dew_per_clear() == 5, "Morning Dew: +20 now, +5 per clear")
	run_state.max_leaves = 20  # The flow test's random pick may have been Deep Roots already
	run_state.leaves = 15
	dreams.take(_card(dreams, "deep_roots"))
	_check(run_state.max_leaves == 22 and run_state.leaves == 17, "Deep Roots: +2 max, regrow 2")
	var dewdrop: TowerData = load("res://resource/tower/dewdrop.tres")
	dreams.take(_card(dreams, "soaked_through"))
	_check(is_equal_approx(dreams.get_status_duration(dewdrop, EnemyStatuses.DAMP), 8.0), "Soaked Through doubles Damp")

# Clearing cards 54–58 (dream_design.md, "Clearing cards").
func _test_clearing_cards(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	var run_state: RunState = main.get_node("%RunState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var clearer: ObstacleClearer = main.get_node("%ObstacleClearer")
	var map_generator = main.get_node("%MapGenerator")
	var tree: ObstacleData = load("res://resource/obstacle/tree.tres")
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	_reset_dreams(main)

	# Offered only while 8+ obstacles are left
	var ground := _card(dreams, "cleared_ground")
	_check(dreams.is_eligible(ground), "Cleared Ground offered on a full map (%d obstacles)" % dreams.count_obstacles())
	var all_obstacles: Dictionary = map_generator.obstacles
	map_generator.obstacles = {}
	_check(not dreams.is_eligible(ground), "clearing cards need 8+ obstacles left")
	map_generator.obstacles = all_obstacles

	# Cleared Ground: −40% per stack, min 1, through the clearer's one cost function
	dreams.take(ground)
	_check(clearer.get_clear_cost(tree) == 3, "Cleared Ground: tree 5 → 3 Dew (got %d)" % clearer.get_clear_cost(tree))
	dreams.take(ground)
	dreams.take(ground)
	_check(clearer.get_clear_cost(tree) == 1, "Cleared Ground stacks, never below 1 Dew")
	dreams.stacks.erase("cleared_ground")

	# Heartwood's Reach: free clears, still +1 Seed each; II gives 7
	dreams.take(_card(dreams, "heartwoods_reach"))
	_check(run_state.free_clears == 4, "Heartwood's Reach: 4 free clears")
	run_state.dew = 0
	var tended := run_state.obstacles_tended
	var cell: Vector2 = map_generator.obstacles.keys()[0]
	_check(clearer.try_clear(cell) and run_state.free_clears == 3 and run_state.dew == 0,
		"a free clear costs no Dew")
	_check(run_state.obstacles_tended == tended + 1, "free clears still give a Seed")
	_check(dreams.is_eligible(_card(dreams, "heartwoods_reach_ii")), "Heartwood's Reach II once the base is owned")
	dreams.take(_card(dreams, "heartwoods_reach_ii"))
	_check(run_state.free_clears == 6, "Heartwood's Reach II: 7 in all (3 left + 3 more)")
	run_state.add_free_clears(-run_state.free_clears)

	# Reclaimed Earth: +8 Dew per clear, and the cleared cell halves its first Warden
	dreams.take(_card(dreams, "reclaimed_earth"))
	run_state.dew = 100
	cell = map_generator.obstacles.keys()[0]
	var price := clearer.get_clear_cost(map_generator.get_obstacle(cell))
	clearer.try_clear(cell)
	_check(run_state.dew == 100 - price + 8, "Reclaimed Earth: +8 Dew per clear (dew %d)" % run_state.dew)
	_check(run_state.fertile_cells.has(cell) and placer.get_cost(sprout, cell) == 5, "fertile ground: a Sprout costs 5")
	placer.tower_data = sprout
	var dew := run_state.dew
	if placer._try_build(cell):
		_check(run_state.dew == dew - 5 and not run_state.fertile_cells.has(cell), "only the first Warden gets the fertile price")
		main.get_node("%TowerSeller").sell(cell)

	# Tended Forest: +1% damage per clear this run, earlier clears count, max +25%
	var tower := Tower.new()
	tower.tower_data = sprout
	tower.cell = Vector2(-5, -5)
	var clears: int = run_state.tended_cells.size()
	dreams.take(_card(dreams, "tended_forest"))
	_check(is_equal_approx(dreams.get_soothe_multiplier(tower), 1.0 + minf(0.01 * clears, 0.25)),
		"Tended Forest counts the %d earlier clears" % clears)
	run_state.tended_cells.resize(40)
	_check(is_equal_approx(dreams.get_soothe_multiplier(tower), 1.25), "Tended Forest caps at +25%")
	run_state.tended_cells.resize(clears)
	tower.free()

	# Burn Back the Dead Wood: a Grove card; clears every Withered Tree, no Seeds, nightmares +10% speed
	var burn := _card(dreams, "burn_back")
	dreams.allow_bittersweet = true
	_check(not dreams.is_eligible(burn, 2), "Burn Back is a Grove card (not in the start pool)")
	dreams.allow_bittersweet = false
	tended = run_state.obstacles_tended
	var rocks := dreams.count_obstacles(load("res://resource/obstacle/rock.tres"))
	var trees := dreams.count_obstacles(tree)
	clears = run_state.tended_cells.size()
	run_state.fertile_cells.clear()
	dew = run_state.dew
	dreams.take(burn)  # Reclaimed Earth is still owned
	_check(dreams.count_obstacles(tree) == 0 and dreams.count_obstacles() == rocks, "Burn Back clears every Withered Tree, no rocks")
	_check(run_state.obstacles_tended == tended, "Burn Back's clears give no Seeds")
	_check(run_state.dew == dew and run_state.fertile_cells.is_empty(), "Burn Back doesn't trigger Reclaimed Earth")
	_check(run_state.tended_cells.size() == clears + trees, "Burn Back's clears still count for Tended Forest")
	var bug: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	_check(is_equal_approx(director.get_spawn_modifiers(bug, 3).get("speed", 1.0), 1.1), "Burn Back: nightmares +10% speed")
	run_state.fertile_cells.clear()
	_reset_dreams(main)

func _simulate_storm_grid(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	_reset_dreams(main)
	# Dreams at the rests after drifts 5 … 45 (the demo's 9; drift 25 is a boss rest, Rare+). The
	# families are assumed lucky: Firefly Jar picked after drift 1, Dewdrop at the drift-25 boss.
	# That isolates the Dream side; the family picks themselves land ~70% (dream_design.md).
	var want := ["dream_stormcap", "dream_rain_lily", "dream_thunderhead", "conductive_soil"]
	var runs := 1000
	for weight in [dreams.tag_weight, 3.0]:
		dreams.tag_weight = weight
		var result := _storm_grid_rate(dreams, want, runs)
		print("Storm Grid simulation, tag weight %.0f× (%d runs, both families, aiming for it): by drift 50 full build %.0f%%, without Thunderhead %.0f%% (target ≈ 33%% incl. families)"
			% [weight, runs, 100.0 * result[0] / runs, 100.0 * result[1] / runs])
	dreams.tag_weight = 2.0
	var owned_rates: Dictionary = _storm_grid_rate(dreams, want, runs)[2]
	var parts: Array[String] = []
	for id in want:
		parts.append("%s %.0f%%" % [id.trim_prefix("dream_"), 100.0 * owned_rates.get(id, 0) / runs])
	print("  how often each piece is owned by drift 50: " + ", ".join(parts))
	_reset_dreams(main)

func _storm_grid_rate(dreams: DreamState, want: Array, runs: int) -> Array:
	var full := 0
	var partial := 0
	var owned_count := {}
	for run in runs:
		_reset_dreams_quiet(dreams)
		dreams.unlocked["firefly_jar"] = true
		for drift in range(5, 50, 5):
			if drift == 25:
				dreams.unlocked["dewdrop"] = true  # The boss family pick comes before the Dream
			var offer := dreams.make_offer(drift)
			var pick: UpgradeData = null
			for card in offer:
				if want.has(card.id):
					pick = card
					break
			if pick != null:
				dreams.take(pick)
		var owned := want.filter(func(id: String) -> bool: return dreams.has_card(id)).size()
		if owned == want.size():
			full += 1
		if dreams.has_card("dream_stormcap") and dreams.has_card("dream_rain_lily") and dreams.has_card("conductive_soil"):
			partial += 1
		for id in want:
			if dreams.has_card(id):
				owned_count[id] = owned_count.get(id, 0) + 1
	return [full, partial, owned_count]


# --- Helpers --------------------------------------------------------------------------------------

func _card(dreams: DreamState, id: String) -> UpgradeData:
	for card in dreams.pool:
		if card.id == id:
			return card
	_check(false, "card %s exists" % id)
	return null

func _build(main: Node, id: String) -> Tower:
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var map_generator = main.get_node("%MapGenerator")
	main.get_node("%RunState").dew = 10000
	var data: TowerData = load("res://resource/tower/%s.tres" % id)
	placer.tower_data = data
	var cell := _free_cell(map_generator)
	if not placer._try_build(cell):
		var enemy_cells := PackedVector2Array()
		for enemy in main.get_node("%EnemyContainer").get_enemies():
			enemy_cells.append(enemy.get_target_cell())
		_check(false, "built %s at %s (buildable %s, occupied %s, can_block %s, enemies at %s, cost %d)" % [id, cell,
			map_generator.is_buildable(cell), placer._is_occupied_by_enemy(cell),
			map_generator.can_block(cell, enemy_cells), enemy_cells, placer.get_cost()])
	var tower: Tower = main.get_node("%TowerSeller").get_tower_at(cell)
	tower.set_process(false)
	return tower

func _spawn_near(main: Node, cell: Vector2, offset: Vector2 = Vector2.ZERO) -> Node2D:
	var spawner = main.get_node("%EnemyContainer")
	var enemy = spawner.enemy_scene.instantiate()
	enemy.enemy_data = load("res://resource/enemy/bark_beetle.tres")
	spawner.add_child(enemy)
	enemy.position = enemy.grid.calculate_map_position(cell) + offset
	enemy.set_path(PackedVector2Array([enemy.grid.calculate_grid_coordinates(enemy.position)]))
	enemy.set_process(false)
	return enemy

func _free_enemies(main: Node) -> void:
	for child in main.get_node("%EnemyContainer").get_children():
		child.free()

func _reset_dreams(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.unlock_everything = false
	dreams.stacks.clear()
	dreams.unlocked = {"sprout": true, "thornwall": true}
	dreams.dreams_seen = 0
	dreams._dreams_without_rare = 0
	dreams._rare_dreams_left = 0
	dreams._extra_cards_next = 0
	dreams._entwined_offered.clear()
	dreams.unlocks_changed.emit()

# Like _reset_dreams, without signals (the simulation runs thousands of times).
func _reset_dreams_quiet(dreams: DreamState) -> void:
	dreams.stacks.clear()
	dreams.unlocked = {"sprout": true, "thornwall": true}
	dreams.dreams_seen = 0
	dreams._dreams_without_rare = 0
	dreams._rare_dreams_left = 0
	dreams._extra_cards_next = 0
	dreams._entwined_offered.clear()

func _clear(main: Node) -> void:
	for child in main.get_node("%EnemyContainer").get_children():
		child.queue_free()
	var seller: TowerSeller = main.get_node("%TowerSeller")
	for tower in main.get_node("%TowerContainer").get_children():
		seller.sell(tower.cell)

func _free_cell(map_generator) -> Vector2:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	for i in range(3, path.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if not path.has(cell) and map_generator.can_block(cell) and not _near_enemy(map_generator, cell):
				return cell
	return Vector2(-1, -1)

# Keeps test Wardens off cells creatures from earlier checks stand on.
func _near_enemy(map_generator, cell: Vector2) -> bool:
	for enemy in map_generator.get_tree().get_nodes_in_group("enemies"):
		if enemy.get_current_cell().distance_to(cell) < 1.5:
			return true
	return false

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
