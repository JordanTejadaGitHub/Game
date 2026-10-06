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
	_test_meta_hooks(main)
	await _test_dreamlight(main)
	_test_passed_over(main)
	_test_few_and_mighty_sim(main)
	_test_stray_dream(main)
	_test_half_dreamed(main)
	await _test_discovery(main)
	_test_grown_needs(main)
	_test_blessing_dream(main)
	_test_run_pool(main)
	_test_offer_shape(main)
	print("dreams test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _test_status_numbers() -> void:
	var s := EnemyStatuses.new()
	s.apply(EnemyStatuses.DAMP)
	_check(is_equal_approx(s.get_speed_multiplier(), 1.0), "Damp no longer slows (status jobs: it conducts)")
	s.apply(EnemyStatuses.DROWSY, 3)
	_check(is_equal_approx(s.get_speed_multiplier(), 1.0 - 0.24), "3 Drowsy stacks slow 24%")
	s.apply(EnemyStatuses.DROWSY, 10)
	_check(s.stacks(EnemyStatuses.DROWSY) == 5, "Drowsy caps at 5")
	s.apply(EnemyStatuses.MARKED)
	_check(is_equal_approx(s.get_damage_taken_multiplier(), 1.25), "Marked: +25% soothe taken")
	# On a Damp nightmare Static never bolts (Thunderclap fires at 3 first; see test_reactions).
	s.remove(EnemyStatuses.DAMP)
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
	# It may stand on an obstacle (no route), which would block every later build: clear it.
	_free_enemies(main)
	await process_frame

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
	_check(hit == storm.attack_data.chain_targets, "Stormcap chains to its chain_targets (%d; hit %d)" % [storm.attack_data.chain_targets, hit])
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
	run_state.dew = 1000  # Sprouts get pricier with every Sprout planted earlier in this test
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
	_check(run_state.dew == dew - 15 and tower.invested_dew == sprout.cost + 15, "growing costs 15 (invested %d)" % tower.invested_dew)
	_check(tower.tower_data == sporeling and tower.sprite.texture == sporeling.texture, "the Warden changes in place")
	_check(map_generator.get_path_from(map_generator.startPath) == path_before, "evolving doesn't change the path")
	var driftspore: TowerData = load("res://resource/tower/driftspore.tres")
	_check(not dreams.is_unlocked("driftspore"), "a branch isn't free: it's bought with Dreamlight (run_design.md Dreamlight, clarified 2026-09-30)")
	dreams.take(_card(dreams, "evergreen"))
	dreams.take(_card(dreams, "dream_driftspore"))
	dew = run_state.dew
	run_state.dew = 1000
	dew = run_state.dew
	var evergreen_cost := roundi(driftspore.get_grow_price() * 0.75)
	_check(placer.evolve(tower, driftspore) and run_state.dew == dew - evergreen_cost, "Evergreen: branch costs 25%% less (%d)" % evergreen_cost)
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
		dreams.choose(offer[-1])  # Not the growth card: the checks below need Stormcap still offered
	_check(not dreams.is_offering() and not paused, "choosing closes the Dream and resumes")

	# Let it pass
	dreams._pending_drifts.append(10)
	var dew := run_state.dew
	dreams._show_next_offer()
	dreams.skip()
	_check(run_state.dew == dew + 15, "letting a Dream pass gives 15 Dew")

	# Eligibility
	_check(not dreams.is_eligible(_card(dreams, "dream_stormcap")), "branch cards aren't Dreams any more (Dreamlight)")
	_check(not dreams.is_eligible(_card(dreams, "dream_sporeling")), "no base Warden cards in Dreams")

	# Boss Dream guarantees Rare+, and pity kicks in after 3 without (Conductive Soil is the Rare here)
	dreams.unlocked["dewdrop"] = true
	dreams.unlocked["stormcap"] = true
	dreams.unlocked["rain_lily"] = true
	var boss_offer := dreams.make_offer(25)
	_check(boss_offer.any(func(c: UpgradeData) -> bool: return c.is_rare_or_better()), "boss Dream has a Rare+ card")
	var saw_rare_by_4 := true
	for trial in 20:
		dreams._dreams_without_rare = 3
		dreams._passed_count.clear()  # Not about the fade: a faded lone Rare falls to Uncommon in act 1
		dreams._passed_at.clear()
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
	_check(dreams.get_evolve_cost(driftspore) == roundi(driftspore.get_grow_price() * 0.6), "Evergreen II: 40%% off, replacing Evergreen (got %d)" % dreams.get_evolve_cost(driftspore))
	_check(not dreams.is_eligible(_card(dreams, "evergreen_ii")), "a card deepens once")
	dreams.take(_card(dreams, "cozy_corners"))
	_check(dreams.rule_level(&"cozy_corners") == 0, "Cozy Corners starts at its base level")
	dreams.take(_card(dreams, "cozy_corners_ii"))
	_check(dreams.rule_level(&"cozy_corners") == 1 and dreams.has_rule(&"cozy_corners"), "Cozy Corners II deepens the rule")
	var bends: Dictionary = dreams._bend_cells
	dreams._bend_cells = {Vector2(10, 10): true}
	_check(dreams.is_beside_bend(Vector2(12, 10), 2) and not dreams.is_beside_bend(Vector2(12, 10), 1)
		and dreams.is_beside_bend(Vector2(12, 12), 2) and not dreams.is_beside_bend(Vector2(13, 10), 2),
		"bend reach is a square (diagonals included): II = the 5×5 around")
	# A U-turn: the path turns at (12, 10) and (12, 12); the Warden inside it at (11, 11) is diagonal
	# to both corners and counts as beside a bend (the user's Dreamcatcher bug).
	dreams._bend_cells = {Vector2(12, 10): true, Vector2(12, 12): true}
	var catcher: TowerData = load("res://resource/tower/sporeling.tres")
	var cozy: Array = dreams.get_card_effects(catcher, Vector2(11, 11)).filter(func(r: Dictionary) -> bool:
		return r.id == "cozy_corners_ii" or r.id == "cozy_corners")
	_check(dreams.is_beside_bend(Vector2(11, 11), 1) and not cozy.is_empty() and cozy[0].active,
		"a Warden inside a U-turn is beside a bend")
	dreams._bend_cells = {}
	cozy = dreams.get_card_effects(catcher, Vector2(11, 11)).filter(func(r: Dictionary) -> bool:
		return r.id == "cozy_corners_ii" or r.id == "cozy_corners")
	_check(not cozy[0].active and "diagonals included" in cozy[0].reason, "…off-reason: %s" % cozy[0].reason)
	dreams._bend_cells = bends

	# Entwined: drawn at normal odds once the ingredients come together (no guaranteed slot)
	_reset_dreams(main)
	dreams.unlocked["firefly_jar"] = true
	dreams.unlocked["dewdrop"] = true
	var soil := _card(dreams, "conductive_soil")
	_check(not dreams.is_eligible(soil), "Conductive Soil needs Stormcap + Rain Lily")
	dreams.take(_card(dreams, "dream_stormcap"))
	dreams.take(_card(dreams, "dream_rain_lily"))
	_check(dreams.is_eligible(soil), "Entwined: Conductive Soil offered at normal odds once both are owned (no guaranteed slot)")
	var seen_again := 0
	for i in 30:
		if dreams.make_offer(10).has(soil):
			seen_again += 1
	_check(seen_again < 30, "Entwined: drawn normally, not every offer (%d/30)" % seen_again)

	# Bittersweet: kept out until enabled, act 2+, at most one per offer, a real cost
	_reset_dreams(main)
	var deep_sleep := _card(dreams, "deep_sleep")
	dreams.allow_bittersweet = false
	# The Grove's Bittersweet Dreams node puts them in the pool
	dreams.grove_cards.assign(["deep_sleep", "restless_dreams"])
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
	dreams.take(deep_sleep)  # dream_design.md e1e39b56: its cost is the rest bonus now, never leaves
	_check(run_state.max_leaves == 20 and run_state.leaves == 20, "Deep Sleep: no leaves lost (%d/%d)" % [run_state.leaves, run_state.max_leaves])
	var rest_director: DriftDirector = main.get_node("%DriftDirector")
	var dew_before := run_state.dew
	var paid: Array = rest_director._pay_rest_bonus()
	_check(not dreams.keeps_rest_bonus() and paid[0] == maxi(dreams.get_dew_per_clear() + dreams.get_rest_bonus_add(), 0)
		and run_state.dew - dew_before == paid[0], "Deep Sleep: no rest bonus, only what Dreams add (%d)" % paid[0])
	var sprout_tower := Tower.new()
	sprout_tower.tower_data = load("res://resource/tower/sprout.tres")
	_check(is_equal_approx(dreams.get_soothe_multiplier(sprout_tower), 1.8), "Deep Sleep: +80% soothe")
	_check((main.get_node("%OmenDirector") as OmenDirector).omens_locked(), "Deep Sleep: Omens can't be faced (the rest skips their offer)")
	sprout_tower.free()
	dreams.stacks.erase("deep_sleep")
	_check(dreams.keeps_rest_bonus(), "…without it the rest bonus is back")
	run_state.leaves = 16
	dreams.take(_card(dreams, "restless_dreams"))
	_check(not dreams.can_skip(), "Restless Dreams: no Let it pass")
	# Waking Dreams (dream_design.md de439ea8): the next Dream offers 3 Legendaries, then every offer shows 2 cards
	_check(dreams.waking_legendaries, "Waking Dreams: the next offer is armed")
	var legends_open := dreams.pool.filter(func(c: UpgradeData) -> bool: return c.rarity == UpgradeData.Rarity.LEGENDARY and dreams.can_offer(c, 2)).size()
	var legend_offer := dreams.make_offer(30)
	_check(legend_offer.filter(func(c: UpgradeData) -> bool: return c.rarity == UpgradeData.Rarity.LEGENDARY).size() >= mini(DreamState.WAKING_LEGENDARIES, legends_open)
		and legend_offer.size() >= DreamState.WAKING_LEGENDARIES and not dreams.waking_legendaries,
		"…3 Legendaries, as many as can be offered (%d open: %s)" % [legends_open, legend_offer.map(func(c: UpgradeData) -> String: return c.id)])
	_check(dreams.make_offer(31).size() == DreamState.WAKING_OFFER_SIZE and dreams.make_offer(32).size() == DreamState.WAKING_OFFER_SIZE,
		"…then every offer shows 2 cards")
	run_state.max_leaves = 15
	run_state.leaves = 14
	dreams.take(_card(dreams, "thin_bark"))  # Thin Bark (de439ea8): max leaves halved, those above lost now
	_check(run_state.max_leaves == 8 and run_state.leaves == 8, "Thin Bark: 15 max leaves become 8, 14 leaves become 8 (%d/%d)" % [run_state.leaves, run_state.max_leaves])
	dreams.stacks.erase("thin_bark")
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
	_check(is_equal_approx(dreams.get_attack_speed_multiplier(sprout), 1.25), "Quickened Sap: one copy, +25% (dream_design.md de439ea8)")
	var dew := run_state.dew
	dreams.take(_card(dreams, "morning_dew"))
	_check(run_state.dew == dew + 20 and dreams.get_dew_per_clear() == 0, "Morning Dew: +20 now, no Dew per clear")
	run_state.max_leaves = 20  # The flow test's random pick may have been Deep Roots already
	run_state.leaves = 15
	dreams.take(_card(dreams, "deep_roots"))
	_check(run_state.max_leaves == 23 and run_state.leaves == 18, "Deep Roots: +3 max, regrow 3")

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

	# Clearing is locked until a clearing card is taken (2026-09-30: any clearing card opens it; Heartwood's
	# Reach is the start-pool one); until then the opener weighs double.
	dreams.clearing_open = false
	run_state.dew = 100
	var locked_cell: Vector2 = map_generator.obstacles.keys()[0]
	_check(clearer.is_locked() and not clearer.try_clear(locked_cell) and run_state.dew == 100,
		"obstacles can't be cleared before a clearing card")
	var opener := _card(dreams, "heartwoods_reach")
	for id in ["heartwoods_reach", "reclaimed_earth", "tended_forest", "tended_stumps", "hollow_ground", "wildwood_reclaimed"]:
		_check(DreamState.unlocks_clearing(_card(dreams, id)), "%s opens clearing (any clearing card does)" % id)
	_check(dreams.can_offer(opener) and dreams.opens_clearing(opener), "Heartwood's Reach is offered, with the Unlocks clearing layout")
	var picks := 0
	var clearing_picks := 0
	var cards_with_one: Array = [opener, _card(dreams, "deeper_calm")]
	for i in 2000:
		if dreams._weighted_pick(cards_with_one) == opener:
			clearing_picks += 1
		picks += 1
	_check(clearing_picks > picks * 0.6, "the opener weighs double while clearing is locked (%d / %d)" % [clearing_picks, picks])
	dreams.take(opener)
	_check(dreams.can_clear() and not clearer.is_locked(), "Heartwood's Reach unlocks clearing")
	_check(not dreams.opens_clearing(opener), "…and no longer says so")
	_check(clearer.try_clear(locked_cell) and run_state.dew < 100 and dreams.free_first_clears == 0, "…and clearing always costs Dew (no free clears)")
	run_state.add_free_clears(-run_state.free_clears)
	var saved := dreams.to_save()
	_reset_dreams(main)
	_check(not dreams.can_clear(), "a new run starts locked")
	dreams.load_save(saved)
	_check(dreams.can_clear(), "the unlock survives a mid-run save (it's in the taken cards)")
	var old := dreams.to_save()
	old.stacks = {"cleared_ground": 2, "heartwoods_reach_ii": 1}
	dreams.load_save(old)
	_check(dreams.card_stacks("heartwoods_reach") >= 1 and dreams.card_stacks("cleared_ground") == 0, "an old save's Cleared Ground / Heartwood's Reach II become Heartwood's Reach")
	_reset_dreams(main)
	dreams.clearing_open = true  # The rest of these checks: clearing open

	# Offered only while 8+ obstacles are left
	_check(dreams.is_eligible(opener), "Heartwood's Reach offered on a full map (%d obstacles)" % dreams.count_obstacles())
	var all_obstacles: Dictionary = map_generator.obstacles
	map_generator.obstacles = {}
	_check(not dreams.is_eligible(opener), "clearing cards need 8+ obstacles left")
	map_generator.obstacles = all_obstacles

	# Heartwood's Reach (absorbed Cleared Ground): −25% per stack (max 2: −50%) through the clearer's one cost
	# function, +3 half-price clears per stack; +1 Dew per clear this run after the discounts. Clearing always
	# costs Dew: never below half the base (tree 12 → 6, boulder 18 → 9).
	var rock: ObstacleData = load("res://resource/obstacle/rock.tres")
	run_state.tended_cells.clear()  # No clears yet: no surcharge
	run_state.add_free_clears(-run_state.free_clears)
	dreams.take(opener)
	_check(clearer.get_clear_cost(tree) == ceili(tree.clear_cost / 2.0) and clearer.get_clear_cost(rock) == ceili(rock.clear_cost / 2.0)
		and run_state.free_clears == 3 and opener.max_stacks == 1,
		"Heartwood's Reach (one copy): half price (tree %d, boulder %d) and 3 half-price clears" % [clearer.get_clear_cost(tree), clearer.get_clear_cost(rock)])
	_check(clearer.get_clear_cost(tree, true) == ceili(tree.clear_cost / 2.0), "…a half-price charge on top still hits the floor")
	run_state.tended_cells.assign([Vector2(-1, -1), Vector2(-2, -2), Vector2(-3, -3)])
	_check(clearer.get_clear_cost(tree) == ceili(tree.clear_cost / 2.0) + 3, "every clear so far adds +1 Dew after the discounts (%d)" % clearer.get_clear_cost(tree))
	run_state.tended_cells.clear()
	_check(tree.clear_cost == 12 and rock.clear_cost == 18, "raised base prices: tree 12, boulder 18")

	# The charges: used first, half price (never free), still +1 Seed each
	run_state.dew = 0
	var tended := run_state.obstacles_tended
	var cell: Vector2 = map_generator.obstacles.keys()[0]
	_check(not clearer.try_clear(cell) and run_state.free_clears == 3, "a charge doesn't make a clear free: no Dew, no clear, charge kept")
	var cost := clearer.get_next_clear_cost(map_generator.get_obstacle(cell))
	_check(cost == ceili(map_generator.get_obstacle(cell).clear_cost / 2.0), "…it halves the price (%d)" % cost)
	run_state.dew = 100
	_check(clearer.try_clear(cell) and run_state.free_clears == 2 and run_state.dew == 100 - cost, "a half-price clear")
	_check(run_state.obstacles_tended == tended + 1, "half-price clears still give a Seed")
	run_state.add_free_clears(-run_state.free_clears)
	dreams.stacks.erase("heartwoods_reach")

	# Reclaimed Earth: refunds 40% of the Dew paid (never a profit), and the cell halves its first Warden
	dreams.take(_card(dreams, "reclaimed_earth"))
	run_state.dew = 100
	cell = map_generator.obstacles.keys()[0]
	var price := clearer.get_clear_cost(map_generator.get_obstacle(cell))
	clearer.try_clear(cell)
	_check(run_state.dew == 100 - price + floori(price * 0.4), "Reclaimed Earth: 40%% of the %d Dew paid back (dew %d)" % [price, run_state.dew])
	_check(100 - run_state.dew > 0, "a clear never returns as much as it cost")
	_check(run_state.fertile_cells.has(cell) and placer.get_cost(sprout, cell) == sprout.cost / 2, "fertile ground: a Sprout at half price")
	placer.tower_data = sprout
	var dew := run_state.dew
	if placer._try_build(cell):
		_check(run_state.dew == dew - sprout.cost / 2 and not run_state.fertile_cells.has(cell), "only the first Warden gets the fertile price")
		main.get_node("%TowerSeller").sell(cell)

	# Tended Forest: +2% damage per clear this run, earlier clears count, max +40%
	var tower := Tower.new()
	tower.tower_data = sprout
	tower.cell = Vector2(-5, -5)
	var clears: int = run_state.tended_cells.size()
	dreams.take(_card(dreams, "tended_forest"))
	_check(is_equal_approx(dreams.get_soothe_multiplier(tower), 1.0 + minf(0.02 * clears, 0.40)),
		"Tended Forest counts the %d earlier clears" % clears)
	run_state.tended_cells.resize(40)
	_check(is_equal_approx(dreams.get_soothe_multiplier(tower), 1.40), "Tended Forest caps at +40%")
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
	run_state.dew = DreamState.BURN_BACK_PER_TREE * trees - 1
	_check(not dreams.can_offer(burn, 2) or dreams.card_stacks("burn_back") > 0, "Burn Back only offered when you can pay 5 Dew per tree")
	run_state.dew = DreamState.BURN_BACK_PER_TREE * trees + 10
	dew = run_state.dew
	dreams.take(burn)  # Reclaimed Earth is still owned
	_check(dreams.count_obstacles(tree) == 0 and dreams.count_obstacles() == rocks, "Burn Back clears every Withered Tree, no rocks")
	_check(run_state.obstacles_tended == tended, "Burn Back's clears give no Seeds")
	_check(run_state.dew == dew - DreamState.BURN_BACK_PER_TREE * trees and run_state.fertile_cells.is_empty(), "Burn Back is free and doesn't trigger Reclaimed Earth")
	_check(run_state.tended_cells.size() == clears + trees, "Burn Back's clears still count for Tended Forest")
	var bug: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	_check(is_equal_approx(director.get_spawn_modifiers(bug, 3).get("speed", 1.0), 1.2), "Burn Back: nightmares +20% speed")
	run_state.fertile_cells.clear()
	_reset_dreams(main)
	dreams.clearing_open = false  # As before the opener: the later simulations were tuned on this pool

# Memory Grove hooks MetaRun sets: Grove cards, family-only evolve discounts, rerolls, banishes,
# Blight Level 8's lean-Common offers, and the save.
func _test_meta_hooks(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	_reset_dreams(main)
	dreams.unlocked["sporeling"] = true
	dreams.unlocked["firefly_jar"] = true

	# Grove cards only once owned
	var grove_card := UpgradeData.new()
	grove_card.id = "test_grove_card"
	grove_card.in_start_pool = false
	_check(not dreams.is_eligible(grove_card), "a Grove card stays out until owned")
	dreams.grove_cards.assign(["test_grove_card"])
	_check(dreams.is_eligible(grove_card), "grove_cards puts it in the pool")
	dreams.grove_cards.clear()

	# Chain Bloom: a Grove card, Entwined (Puffball + Mistveil)
	var bloom := _card(dreams, "chain_bloom")
	dreams.unlocked["puffball"] = true
	dreams.unlocked["mistveil"] = true
	dreams.grown_wardens["puffball"] = true  # Grown this run too (round 5)
	dreams.grown_wardens["mistveil"] = true
	_check(bloom.entwined and bloom.rule_id == &"chain_bloom" and bloom.in_start_pool and Array(bloom.discovered_by) == ["event:puff_in_fog"],
		"Chain Bloom: start pool, discovered by a Puffball puff in Mistveil's fog")
	dreams.unlocked.erase("mistveil")
	_check(not dreams.is_eligible(bloom), "Chain Bloom needs Mistveil too")
	dreams.unlocked["mistveil"] = true
	# No guaranteed slot (dream_design.md "Combo cards are choices, not musts"): eligible, drawn at normal odds
	var bloom_offers := 0
	for i in 30:
		if dreams.make_offer(10).has(bloom):
			bloom_offers += 1
	_check(dreams.is_eligible(bloom) and bloom_offers < 30, "Chain Bloom is offered at normal odds once Puffball and Mistveil are owned (%d of 30 offers)" % bloom_offers)
	dreams.take(bloom)
	_check(dreams.has_rule(&"chain_bloom"), "taking it switches on the chain_bloom rule")
	dreams.stacks.erase("chain_bloom")
	dreams.grove_cards.clear()
	dreams._offer_drift = 0
	dreams._declined_families.clear()
	dreams._passed_count.clear()
	dreams._passed_at.clear()
	dreams.unlocked.erase("puffball")
	dreams.unlocked.erase("mistveil")

	# A family Blessing's evolve discount only covers its own line
	var blessing := UpgradeData.new()
	blessing.id = "test_blessing_spore"
	blessing.stat_line = "spore"
	blessing.evolve_discount = 0.25
	blessing.max_stacks = 0
	dreams.pool.append(blessing)
	var driftspore: TowerData = load("res://resource/tower/driftspore.tres")
	var stormcap: TowerData = load("res://resource/tower/stormcap.tres")
	var spore_before := dreams.get_evolve_cost(driftspore)
	var storm_before := dreams.get_evolve_cost(stormcap)
	dreams.take(blessing)
	_check(dreams.get_evolve_cost(driftspore) < spore_before and dreams.get_evolve_cost(stormcap) == storm_before,
		"a line-limited evolve discount only covers that family")
	dreams.pool.erase(blessing)
	dreams.stacks.erase(blessing.id)

	# Reroll: same Dream (counters unchanged), new cards; banish: gone for the run, replaced
	dreams.rerolls_left = 1
	dreams.banishes_left = 1
	dreams._pending_drifts.append(10)
	dreams._show_next_offer()
	var seen := dreams.dreams_seen
	_check(dreams.reroll() and dreams.rerolls_left == 0 and dreams.dreams_seen == seen and dreams.is_offering(),
		"a reroll re-deals the same Dream")
	_check(not dreams.reroll(), "no rerolls left")
	var size := dreams.current_offer.size()
	var gone: UpgradeData = dreams.current_offer[0]
	_check(dreams.banish(gone) and not dreams.current_offer.has(gone) and dreams.current_offer.size() == size,
		"Let Go replaces the card")
	_check(not dreams.is_eligible(gone), "a banished card never comes back this run")
	var saved := dreams.to_save()
	dreams._banished.clear()
	dreams.load_save(saved)
	_check(not dreams.is_eligible(gone) and dreams.banishes_left == 0, "banishes and counts survive a save")
	dreams.skip()
	dreams._banished.clear()

	# Lean Common: fewer Rare+ rolls
	var rare_normal := 0
	var rare_lean := 0
	for i in 4000:
		rare_normal += 1 if dreams._roll_rarity(2, false) >= UpgradeData.Rarity.RARE else 0
	dreams.lean_common = true
	for i in 4000:
		rare_lean += 1 if dreams._roll_rarity(2, false) >= UpgradeData.Rarity.RARE else 0
	dreams.lean_common = false
	_check(rare_lean < rare_normal * 0.7, "lean_common halves Rare+ (%d → %d)" % [rare_normal, rare_lean])
	_reset_dreams(main)

# Dreamlight (run_design.md): branches, finals and wall growths are unlocked with it, not Dreams.
func _test_dreamlight(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	_reset_dreams(main)
	var stormcap: TowerData = load("res://resource/tower/stormcap.tres")
	var thunderhead: TowerData = load("res://resource/tower/thunderhead.tres")
	var bramble: TowerData = load("res://resource/tower/bramble.tres")
	var rain_lily: TowerData = load("res://resource/tower/rain_lily.tres")
	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	for card in dreams.pool:
		if card.kind == UpgradeData.Kind.UNLOCK_EVOLUTION and dreams.is_eligible(card, 2):
			_check(false, "%s is still a Dream card" % card.id)

	# The first family pick (run_design.md "Dreamlight", clarified 2026-09-30): the family and +1 Dreamlight (user 2026-10-01, was 2);
	# branches cost 1 and finals 2 (no Grove node for either), bought on the Remember screen
	dreams.dreamlight = 0
	director.family_pick_requested.emit(&"first")
	dreams.unlocked["firefly_jar"] = true  # What FamilyPickScreen.choose does
	dreams.unlocks_changed.emit()
	var sunpetal: TowerData = load("res://resource/tower/sunpetal.tres")
	_check(dreams.dreamlight == DreamState.FIRST_PICK_DREAMLIGHT and DreamState.FIRST_PICK_DREAMLIGHT == 1, "+1 Dreamlight with the first family pick")
	_check(not dreams.is_unlocked("stormcap") and not dreams.is_unlocked("lanternmoth"), "owning Firefly Jar doesn't unlock its branches")
	_check(dreams.get_unlock_cost(stormcap) == 1 and dreams.can_unlock(stormcap) and dreams.get_unlock_blocker(thunderhead) == "needs Stormcap",
		"a branch costs 1 Dreamlight (can unlock now); its final waits for it")
	_check(dreams.get_unlock_cost(sunpetal) == 1 and dreams.get_unlock_blocker(sunpetal) == "Memory Grove", "the hidden branch keeps its Grove node and 1 Dreamlight")
	# An old save with a branch granted free (a75b5770) keeps it; nothing is taken away
	var old := dreams.to_save()
	(old["unlocked"] as Array).append("lanternmoth")
	dreams.load_save(old)
	_check(dreams.is_unlocked("lanternmoth") and dreams.dreamlight == DreamState.FIRST_PICK_DREAMLIGHT, "an old save keeps a branch it was given")
	dreams.dreamlight = 1
	var remembers := []
	dreams.remember_requested.connect(func(focus: TowerData) -> void: remembers.append(focus))
	director.drifts_started = 25
	director.rest_started.emit(5, true, 0, true)
	_check(dreams.dreamlight == 1 + DreamState.BOSS_DREAMLIGHT and remembers.size() == 1, "+3 at a boss rest, and Remember opens")
	dreams.dreamlight = 4  # The spending checks below start from 4
	_check(not dreams.is_offering() and dreams.has_pending_offer(), "the Dream waits for Remember")
	dreams.remember_closed()
	await process_frame
	_check(dreams.is_offering(), "…and follows once it closes")
	dreams.skip()
	director.drifts_started = 0

	# Costs: branch 1, final 2 (needs its branch), wall growth 1; base families never
	_check(dreams.get_unlock_cost(stormcap) == 1 and dreams.get_unlock_cost(thunderhead) == 2 and dreams.get_unlock_cost(bramble) == 1,
		"costs: branch 1, final form 2, wall growth 1")
	_check(not dreams.can_unlock(rain_lily), "no branches for a family you don't own")
	_check(dreams.get_unlock_blocker(sporeling) == "family pick", "base families only come from the family pick")
	_check(dreams.unlock_with_dreamlight(stormcap) and dreams.is_unlocked("stormcap") and dreams.dreamlight == 3, "unlocking Stormcap spends 1")
	_check(dreams.unlock_with_dreamlight(thunderhead) and dreams.dreamlight == 1, "then Thunderhead for 2")
	_check(dreams.unlock_with_dreamlight(bramble) and dreams.dreamlight == 0, "Bramble for 1")
	dreams.dreamlight = 0
	var moth_final: TowerData = (load("res://resource/tower/lanternmoth.tres") as TowerData).evolves_to[0]
	_check(not dreams.unlock_with_dreamlight(moth_final), "not without Dreamlight")
	var trees := dreams.get_remember_trees()
	_check(trees.any(func(t: Array) -> bool: return t[0].get_id() == "firefly_jar")
		and trees.any(func(t: Array) -> bool: return t[0].get_id() == "thornwall"), "Remember shows owned families and walls")

	# Cards and the save
	dreams.take(_card(dreams, "sudden_insight"))
	_check(dreams.dreamlight == 2, "Sudden Insight: +2 Dreamlight")
	var saved := dreams.to_save()
	dreams.dreamlight = 0
	dreams.load_save(saved)
	_check(dreams.dreamlight == 2, "Dreamlight survives the save")
	run_state.max_leaves = 20
	_reset_dreams(main)
	dreams.dreamlight = 0

# --- Helpers --------------------------------------------------------------------------------------

# Passed-over cards fade (dream_design.md "How Dream offers work"): skip the same offers again and
# again and count how often one Common card comes back.
func _test_passed_over(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	_reset_dreams(main)
	var watched: UpgradeData = null
	for card in dreams.pool:
		if card.rarity == UpgradeData.Rarity.COMMON and dreams.is_eligible(card, 1) and card.rule_id == &"":
			watched = card
			break
	_check(watched != null, "a plain Common card to watch")
	if watched == null:
		return
	# Rules on one card
	dreams._note_passed([watched] as Array[UpgradeData], dreams.dreams_seen)
	dreams.dreams_seen += 1
	_check(dreams.get_passed_weight(watched) == 0.0, "passed over: left out of the next offer")
	dreams.dreams_seen += 1
	_check(is_equal_approx(dreams.get_passed_weight(watched), 0.6), "…then back at ×0.6")
	dreams._note_passed([watched] as Array[UpgradeData], dreams.dreams_seen)
	dreams.dreams_seen += 2
	_check(is_equal_approx(dreams.get_passed_weight(watched), 0.36), "…×0.6 per time passed (0.36)")
	for i in 5:
		dreams._note_passed([watched] as Array[UpgradeData], dreams.dreams_seen)
	dreams.dreams_seen += 2
	_check(dreams.times_passed(watched.id) == 7 and is_equal_approx(dreams.get_passed_weight(watched), 0.1),
		"…never below ×0.1")
	var saved := dreams.to_save()
	_reset_dreams(main)
	dreams.load_save(JSON.parse_string(JSON.stringify(saved)))
	_check(dreams.times_passed(watched.id) == 7 and is_equal_approx(dreams.get_passed_weight(watched), 0.1),
		"passed-over counters survive a save")
	dreams.take(watched)
	_check(dreams.times_passed(watched.id) == 0 and dreams.get_passed_weight(watched) == 1.0,
		"taking a card resets its fade")

	# The playtest case: take some other card at every offer, always pass over the watched one. Target
	# (dream_design.md): after its second pass it's in at most about 1 offer in 4.
	var rates := []  # Share of offers with it, after its second pass (200 runs of 20 Dreams)
	var back_to_back := 0
	for fading in [false, true]:
		var offers := 0
		var with_it := 0
		dreams._rng.seed = 7  # Same draws both ways, so the numbers never flake
		for run in 80:  # Trimmed for the suite's time (fixed seed: no flake)
			_reset_dreams_quiet(dreams)
			var passes := 0
			var last := false
			for i in 20:
				dreams.current_offer = dreams.make_offer(2)
				var has_it := dreams.current_offer.has(watched)
				if passes >= 2:
					offers += 1
					with_it += 1 if has_it else 0
				if fading and has_it and last:
					back_to_back += 1
				last = has_it
				passes += 1 if has_it else 0
				var other: Array = dreams.current_offer.filter(func(c: UpgradeData) -> bool: return c != watched)
				if other.is_empty():
					dreams.skip()
				else:
					dreams.choose(other[0])
				dreams.stacks.clear()  # Keep the pool as it was
				dreams.picks_left = 1
				dreams.current_offer = []
				if not fading:
					dreams._passed_count.clear()
					dreams._passed_at.clear()
		rates.append(float(with_it) / maxi(offers, 1))
	print("passed-over: after 2 passes %s is in %.0f%% of offers without fading, %.0f%% with" % [watched.id,
		rates[0] * 100, rates[1] * 100])
	_check(back_to_back == 0, "a passed-over card never comes back in the very next offer")
	_check(rates[1] <= 0.25 and rates[1] < rates[0], "after 2 passes: at most ~1 offer in 4 (%.2f)" % rates[1])

	# A reroll passes over every card it replaced.
	_reset_dreams(main)
	dreams.rerolls_left = 1
	dreams._before_offer = dreams._offer_counters()
	dreams.current_offer = dreams.make_offer(2)
	var first := dreams.current_offer.duplicate()
	dreams.reroll()
	_check(first.all(func(c: UpgradeData) -> bool: return dreams.times_passed(c.id) == 1 and dreams.get_passed_weight(c) == 0.0),
		"a reroll counts as passing over the cards it replaced")
	_check(not dreams.current_offer.any(func(c: UpgradeData) -> bool:
		return c.rarity == UpgradeData.Rarity.COMMON and first.has(c)), "…and the new offer leaves them out")
	dreams.choose(dreams.current_offer[0])
	_check(dreams.times_passed(dreams.get_taken_cards()[0].id) == 0, "a taken card isn't passed over")
	_reset_dreams(main)

# The playtest case (design chat, 2026-09-28): a Thornwall maze with 10 attacking Wardens meets Few and
# Mighty's Need all run; the player keeps taking other (non-narrow) cards. How often is it offered
# by drift 35 and 50, with and without fading? Target: after its 2nd pass, about 1 offer in 4 at most.
func _test_few_and_mighty_sim(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	var container: Node = main.get_node("%TowerContainer")
	var few := _card(dreams, "few_and_mighty")
	var planted: Array[Tower] = []
	for i in 16:
		var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
		tower.tower_data = load("res://resource/tower/%s.tres" % ("sporeling" if i < 10 else "thornwall"))
		tower.cell = Vector2(100 + i, 100)  # Off the map: only counted
		container.add_child(tower)
		tower.set_process(false)
		planted.append(tower)
	# Eligible Rares on an act 1 board (this one: 10 attackers, 6 Thornwalls) with each starting family
	# (dream_design.md "Generic Rares": target ~5–7). Drawable = hard Needs met; full = soft Needs too.
	for family in ["sporeling", "firefly_jar", "dewdrop"]:
		_reset_dreams_quiet(dreams)
		dreams.unlocked[family] = true
		var drawable: Array = dreams.pool.filter(func(c: UpgradeData) -> bool:
			return c.rarity == UpgradeData.Rarity.RARE and dreams.can_offer(c, 1) and not c.id.begins_with("blessing_"))  # Generic Rares (a family's Blessing isn't one)
		var full := drawable.filter(func(c: UpgradeData) -> bool: return dreams.is_eligible(c, 1))
		print("act 1 Rares with %s: %d drawable, %d with every Need met (%s)" % [family, drawable.size(), full.size(),
			", ".join(drawable.map(func(c: UpgradeData) -> String: return c.id))])
		# The lean starting pool (2026-09-30): 10 Rares on a fresh account, a few need families or discovery
		_check(full.size() >= 3 and full.size() <= 8, "act 1 board with %s: 3–8 eligible generic Rares (%d)" % [family, full.size()])
	const RUNS := 120  # Trimmed for the suite's time (fixed seed)
	var results := []  # Per mode: [offers by 35, by 50, offers after 2nd pass, of them with it]
	for fading in [false, true]:
		var r := [0, 0, 0, 0]
		dreams._rng.seed = 11
		for run in RUNS:
			_reset_dreams_quiet(dreams)
			dreams._passed_count.clear()
			dreams._passed_at.clear()
			dreams.unlocked["sporeling"] = true
			var passes := 0
			for drift in range(5, 51, 5):
				dreams.current_offer = dreams.make_offer(drift)
				var has_it := dreams.current_offer.has(few)
				if passes >= 2:
					r[2] += 1
					r[3] += 1 if has_it else 0
				if has_it:
					passes += 1
					r[0] += 1 if drift <= 35 else 0
					r[1] += 1
				var other: Array = dreams.current_offer.filter(func(c: UpgradeData) -> bool:
					return c != few and not c.tags.has("narrow"))
				if other.is_empty():
					dreams._close_offer()
				else:
					dreams.choose(other[0])
				if dreams.is_offering():  # Lucid Dreaming's second pick
					dreams._close_offer()
				if not fading:
					dreams._passed_count.clear()
					dreams._passed_at.clear()
		results.append(r)
	# An act 1 forced-Rare offer (owed one, drift 20: the boss rest after 25 belongs to act 2 now, 495076d2) with every
	# Rare faded: never a Legendary (none in act 1); without a Rare the
	# next offer owes one.
	var legendary := 0
	dreams._rng.seed = 5
	var fell := 0
	var owed := 0
	for i in 100:
		_reset_dreams_quiet(dreams)
		dreams._passed_count.clear()
		dreams._passed_at.clear()
		dreams.unlocked["sporeling"] = true
		for card in dreams.pool:  # Every Rare faded ×0.22 (passed 3 times, not just now)
			if card.rarity == UpgradeData.Rarity.RARE:
				dreams._passed_count[card.id] = 3
				dreams._passed_at[card.id] = -5
		dreams._rare_dreams_left = 1
		var offer := dreams.make_offer(20)
		legendary += 1 if offer.any(func(c: UpgradeData) -> bool: return c.rarity == UpgradeData.Rarity.LEGENDARY) else 0
		if not offer.any(func(c: UpgradeData) -> bool: return c.rarity == UpgradeData.Rarity.RARE):
			fell += 1
			owed += 1 if dreams._rare_dreams_left == 1 else 0
	print("act 1 forced Rare with every Rare faded ×0.22: fell to Uncommon in %d of 100" % fell)
	_check(legendary == 0, "act 1: a faded forced Rare slot never falls to Legendary")
	_check(fell > 70 and owed == fell, "…one chance per offer (~22%): it falls to Uncommon and the next offer tries for a Rare again")
	for tower in planted:
		tower.free()
	_reset_dreams(main)
	for i in 2:
		var r: Array = results[i]
		print("few and mighty (%s fading): offered %.2f times by drift 35, %.2f by 50; after its 2nd pass in %.0f%% of offers" % [
			"with" if i == 1 else "without", float(r[0]) / RUNS, float(r[1]) / RUNS, 100.0 * r[3] / maxi(r[2], 1)])
	# It's the only eligible Rare here, so this needs the fade to reach across rarities.
	var faded: Array = results[1]
	# Its effect: once passed twice it rarely comes back (the totals are within noise of each other).
	_check(float(faded[3]) / maxi(faded[2], 1) < float(results[0][3]) / maxi(results[0][2], 1) + 0.001 and faded[1] <= results[0][1] * 1.15,
		"Few and Mighty: fading lowers how often it comes back after being passed over")
	_check(float(faded[3]) / maxi(faded[2], 1) <= 0.25, "Few and Mighty: after its 2nd pass at most ~1 offer in 4")

# "Adapt, don't get handed" (dream_design.md): the Stray Dream slot, and how much of an offer is
# your build. Target: an out-of-build card in ≥ ~70% of offers. The own-family share is printed for
# reference only ("Your Dreams steer your Dreams, not your family picks": no target).
func _test_stray_dream(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	_reset_dreams(main)
	dreams.unlocked = {"sprout": true, "thornwall": true, "sporeling": true, "firefly_jar": true}
	dreams.make_offer(5)
	_check(dreams.current_stray == null, "Stray: none before drift 10")
	dreams.make_offer(25)
	_check(dreams.current_stray == null, "…none at a boss rest")
	var offer := dreams.make_offer(15)
	_check(dreams.current_stray != null and offer.has(dreams.current_stray) and dreams.is_stray(dreams.current_stray),
		"…one Stray slot from drift 10")
	# Weighting turned around: build cards ×0.25, soft Needs ignored
	var in_build := _card(dreams, "cozy_corners")
	dreams.take(_card(dreams, "crossroads"))  # Its archetype ("maze") joins the build
	var plain := _card(dreams, "deeper_calm")
	var build_picks := 0
	var soft_picks := 0
	var soft := _card(dreams, "many_hands")  # Soft Need unmet (15 attackers)
	for i in 2000:
		build_picks += 1 if dreams._weighted_pick([in_build, plain], true) == in_build else 0
		soft_picks += 1 if dreams._weighted_pick([soft, plain], true) == soft else 0
	_check(build_picks > 300 and build_picks < 500, "Stray: build cards ×0.25 (%d / 2000)" % build_picks)
	_check(soft_picks > 900 and soft_picks < 1100, "Stray: soft Needs ignored (%d / 2000)" % soft_picks)
	# No Entwined slot any more (dream_design.md "Combo cards are choices, not musts"): an offer with Conductive Soil
	# eligible is still Stray + normal cards, Soil not forced first
	_reset_dreams(main)
	dreams.unlocked = {"sprout": true, "thornwall": true, "stormcap": true, "rain_lily": true}
	var soil := _card(dreams, "conductive_soil")
	var soil_first := 0
	for i in 20:
		offer = dreams.make_offer(15)
		if offer[0] == soil:
			soil_first += 1
	_check(offer.size() == 3 and soil_first < 20, "Entwined isn't forced into the offer (%d of 20 led by it)" % soil_first)

	# The measurement: Sporeling + Firefly Jar, 10 attackers, 400 offers per case.
	var planted: Array[Tower] = []
	for i in 10:
		var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
		tower.tower_data = load("res://resource/tower/sporeling.tres")
		tower.cell = Vector2(100 + i * 3, 100)  # Off the map: only counted
		main.get_node("%TowerContainer").add_child(tower)
		tower.set_process(false)
		planted.append(tower)
	var family_lines := {"sprout": true, "wall": true}
	for card in dreams.pool:
		if card.unlocks != null:
			family_lines[card.unlocks.line] = true
	var build_tags := family_lines.duplicate()
	for tag in DreamState.DIRECTION_TAGS + DreamState.ARCHETYPE_TAGS:
		build_tags[tag] = true
	for card in dreams.pool:
		if card.rarity == UpgradeData.Rarity.LEGENDARY:
			for tag in card.tags:
				build_tags[tag] = true
	for direction in ["", "seedfall"]:
		for drift in [5, 15, 35]:
			_reset_dreams(main)
			dreams.unlocked = {"sprout": true, "thornwall": true, "sporeling": true, "firefly_jar": true}
			if direction != "":
				dreams.take(_card(dreams, direction))
			var own_lines := {}  # The owned families' lines (families no longer count as build tags)
			for id in dreams.unlocked:
				if dreams._line_of(id) != "":
					own_lines[dreams._line_of(id)] = true
			var shown := 0
			var own_family := 0
			var offers_out := 0
			dreams._rng.seed = 3
			for i in 200:
				dreams.dreams_seen = 0
				dreams._passed_count.clear()
				dreams._passed_at.clear()
				var any_out := false
				for card in dreams.make_offer(drift):
					shown += 1
					# Own-family: an owned family tag (a half-dreamed combo's family tags don't count yet)
					if not dreams.is_half_dreamed(card) and card.tags.any(func(t: String) -> bool: return family_lines.has(t) and own_lines.has(t)):
						own_family += 1
					# Out of build: points at a family / direction / archetype you don't have, or its soft Need is unmet
					if not dreams.is_in_build(card) and (card.tags.any(func(t: String) -> bool: return build_tags.has(t))
							or not dreams.soft_needs_met(card)):
						any_out = true
				offers_out += 1 if any_out else 0
			var family_share := float(own_family) / shown
			var out_share := offers_out / 200.0
			print("adapt: %s, drift %d: own-family %d%% of cards, an out-of-build card in %d%% of offers" % [
				direction if direction != "" else "no direction", drift, roundi(family_share * 100), roundi(out_share * 100)])
			if drift >= DreamState.STRAY_FROM_DRIFT:
				_check(out_share >= 0.7, "an out-of-build card in ≥ 70%% of offers (%.2f)" % out_share)
	for tower in planted:
		tower.free()
	_reset_dreams(main)

# Half-dreamed combo cards (dream_design.md "Adapt, don't get handed" 5).
# Half-dreamed combo cards (dream_design.md "Adapt, don't get handed" 5).
func _test_half_dreamed(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	var screen = main.get_node("%FamilyPickScreen")
	_reset_dreams(main)
	dreams.unlocked["firefly_jar"] = true
	var thunder := _card(dreams, "rolling_thunder")  # Needs Stormcap (Firefly Jar's) + Dewdrop
	dreams._offer_drift = 10
	_check(Array(dreams.half_dreamed_missing(thunder)) == ["dewdrop"], "half-dreamed: owns Firefly Jar (Stormcap counts), Dewdrop pickable")
	_check(dreams.can_offer(thunder) and not dreams.is_eligible(thunder), "…can be offered, but isn't whole")
	var text := dreams.half_dreamed_text(thunder)
	print("half-dreamed text: " + text)
	_check(text.begins_with("Needs Soaked: a family that brings it may come after") and "(drift 25)" in text and not text.contains("Dewdrop"),
		"…says the missing status and when, never the Warden")
	dreams._offer_drift = 80
	_check(not dreams.is_half_dreamed(thunder), "…never after the drift 75 family pick")
	dreams._offer_drift = 25  # The boss rest: the next pick (drift 50) is 25 drifts away
	_check(not dreams.is_half_dreamed(thunder), "…only when the next family pick is at most 20 drifts away")
	dreams._offer_drift = 30
	_check(dreams.is_half_dreamed(thunder), "…(drift 30: 20 away, yes)")
	dreams._offer_drift = 10
	var soil := _card(dreams, "conductive_soil")  # Rare, half-dreamed here too (Stormcap + Rain Lily)
	var forced_soil := 0
	for i in 300:
		forced_soil += 1 if dreams._draw_card(1, [], true) == soil else 0
	_check(dreams.is_half_dreamed(soil) and forced_soil == 0, "…never in a guaranteed Rare slot")
	# Declined: Dewdrop was offered at the last pick and not taken → ×0.3 instead of ×0.6
	var plain := _card(dreams, "deeper_calm")
	var shares := []
	for declined in [false, true]:
		dreams.note_family_pick(["dewdrop", "sporeling"] if declined else [], "sporeling")
		var picks := 0
		for i in 1500:
			picks += 1 if dreams._weighted_pick([thunder, plain]) == thunder else 0
		shares.append(picks / 1500.0)
	_check(shares[1] < shares[0] * 0.75 and shares[1] > 0.2, "…×0.3 after its family was declined at a pick (%.2f vs %.2f)" % [shares[1], shares[0]])
	dreams.note_family_pick([], "")
	dreams.unlocked.erase("firefly_jar")
	_check(not dreams.is_half_dreamed(thunder), "…needs one of its families already yours")
	dreams.unlocked["firefly_jar"] = true
	dreams.take(thunder)
	_check(dreams.is_dormant(thunder) and not dreams.has_rule(thunder.rule_id) and dreams.get_taken_cards().has(thunder),
		"taken half-dreamed: asleep (no effect), still listed")
	_check(dreams.not_active_reason(thunder).begins_with("Not active yet: needs a") and dreams.not_active_reason(thunder).ends_with("Warden"),
		"…Dreams this run says why on hover (%s)" % dreams.not_active_reason(thunder))
	var saved := dreams.to_save()
	dreams.load_save(JSON.parse_string(JSON.stringify(saved)))
	# Picks stay pure (user, dream_design.md "Picks stay pure"): the card sleeps through a save, and no family pick is
	# made to include its missing family
	_check(dreams.is_dormant(thunder), "…still asleep after a save")
	_check(not dreams.has_method("take_owed_families"), "…and no family is owed to the next pick")
	dreams.unlocked["dewdrop"] = true
	_check(dreams.is_dormant(thunder), "…still asleep without Stormcap itself")
	dreams.unlocked["stormcap"] = true
	_check(not dreams.is_dormant(thunder) and dreams.has_rule(thunder.rule_id), "…and wakes once it's all yours")
	_check(dreams.not_active_reason(thunder) == "", "…and no longer says it's waiting")
	_reset_dreams(main)

	# How often one is offered per run, for each starting family, with the family picks at 25 and 50:
	# half the time the player takes a half-dreamed card, and takes the owed family at the next pick
	# half the time (else a random offered one).
	var rng := RandomNumberGenerator.new()
	for start in ["sporeling", "firefly_jar", "dewdrop"]:
		const RUNS := 60  # Trimmed for the suite's time (fixed seeds)
		var before_pick := 0
		var through_70 := 0
		dreams._rng.seed = 21
		rng.seed = 5
		seed(9)  # The family pick's shuffle
		for run in RUNS:
			_reset_dreams_quiet(dreams)
			dreams._passed_count.clear()
			dreams._passed_at.clear()
			dreams._declined_families.clear()
			dreams.unlocked[start] = true
			for drift in range(5, 75, 5):
				if drift % 25 == 0:  # The boss's family pick comes before its rest
					var owed: Array = []  # Picks no longer include a half-dreamed card's family
					screen.show_pick(&"boss")
					var families: Array = screen.offer.filter(func(d) -> bool: return d is TowerData)
					if not families.is_empty():
						var pick: TowerData = families[rng.randi_range(0, families.size() - 1)]
						for data in families:
							if owed.has(data.get_id()) and rng.randf() < 0.5:
								pick = data
						dreams.unlocked[pick.get_id()] = true
						dreams.note_family_pick(families.map(func(d: TowerData) -> String: return d.get_id()), pick.get_id())
					screen.offer = []
					screen.visible = false
				dreams._offer_drift = drift
				var offer := dreams.make_offer(drift)
				var half := offer.filter(func(c: UpgradeData) -> bool: return dreams.is_half_dreamed(c))
				before_pick += half.size() if drift < 25 else 0
				through_70 += half.size()
				var other := offer.filter(func(c: UpgradeData) -> bool: return not dreams.is_half_dreamed(c))
				if not half.is_empty() and (other.is_empty() or rng.randf() < 0.5):
					dreams.take(half[0])
				elif not other.is_empty():
					dreams.take(other[0])
		main.get_node("%GameSpeed").set_paused(false)
		print("half-dreamed (start %s): %.2f offered per run before the drift 25 pick, %.2f through drift 70" % [
			start, float(before_pick) / RUNS, float(through_70) / RUNS])
		_check(float(before_pick) / RUNS >= 0.4, "half-dreamed cards: at least 0.4 per run before the drift 25 pick (start %s: %.2f)" % [start, float(before_pick) / RUNS])
	_reset_dreams(main)


# Discovery unlocks (dream_design.md): combo, Kinship and Warden cards wait until seen once; a
# discovery mid-run lets them in at once.
func _test_discovery(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	_reset_dreams(main)
	var feedback := root.get_tree().get_first_node_in_group(ComboFeedback.GROUP) as ComboFeedback
	var run_counts: Dictionary = feedback.run_counts.duplicate() if feedback != null else {}
	if feedback != null:
		feedback.run_counts.clear()
	var tracker := root.get_tree().get_first_node_in_group(ReactionTracker.GROUP) as ReactionTracker
	var chain := tracker.longest_chain if tracker != null else 0
	if tracker != null:
		tracker.longest_chain = 0
	dreams._built_this_run.clear()
	dreams.discovery_profile = {"seen": [], "wardens_built": [], "best_chain": 0}
	var waiting := dreams.pool.filter(func(c: UpgradeData) -> bool: return not dreams.discovery_keys(c).is_empty())
	_check(waiting.size() >= 31, "discovery cards in the pool (%d)" % waiting.size())
	_check(waiting.all(func(c: UpgradeData) -> bool: return not dreams.can_offer(c, 4)),
		"a fresh profile is never offered a discovery card")
	var thunder := _card(dreams, "rolling_thunder")
	_check(not dreams.discovery_met(thunder), "Rolling Thunder waits for Thunderclap")
	if feedback != null:
		feedback.run_counts[&"thunderclap"] = 1
		_check(dreams.discovery_met(thunder), "…and counts the moment Thunderclap fires this run")
		var quick := _card(dreams, "quick_reactions")
		_check(not dreams.discovery_met(quick), "Quick Reactions needs 2 Reactions")
		feedback.run_counts[&"drown"] = 1
		_check(dreams.discovery_met(quick), "…two found")
		_check(not dreams.discovery_met(_card(dreams, "eye_of_the_tempest")), "a Woven card waits for its Crowned Reaction")
	dreams.discovery_profile["seen"] = [String(Kinships.KINSHIPS.keys()[0])]
	_check(dreams.discovery_met(_card(dreams, "extended_family")), "any Kinship lets the Kinship cards in")
	_check(dreams.discovery_met(_card(dreams, "grove_of_kin")), "…Grove of Kin too (a Legendary with an explicit trigger)")
	_check(not dreams.discovery_met(_card(dreams, "dawnbreak")), "Dawnbreak waits for a ×10 chain")
	_check(not dreams._key_met("chain:5", []), "a ×5 chain key waits…")
	dreams.discovery_profile["best_chain"] = 5
	_check(dreams._key_met("chain:5", []), "…the profile's best chain counts")
	dreams.discovery_profile["best_chain"] = 10
	_check(dreams.discovery_met(_card(dreams, "dawnbreak")), "…and comes with the first ×10")
	# The discovery moments (2026-09-30): a crit on a Marked nightmare, a Puffball puff in Mistveil's fog
	dreams._events_this_run.clear()
	var starlit := _card(dreams, "starlit_aim")
	var fog_card := _card(dreams, "chain_bloom")
	_check(starlit.in_start_pool and not dreams.discovery_met(starlit) and not dreams.discovery_met(fog_card),
		"Starlit Aim and Chain Bloom are start pool, waiting for their moments")
	var crit := DamageLog.Event.new()
	crit.combos.assign([&"crit"])
	dreams._on_damage_dealt(crit)
	_check(not dreams.event_discovered("crit_marked"), "a plain crit isn't it")
	crit.combos.assign([&"crit", &"marked"])
	dreams._on_damage_dealt(crit)
	_check(dreams.event_discovered("crit_marked") and dreams._key_met("event:crit_marked", []), "a crit on a Marked nightmare discovers Starlit Aim")
	dreams.note_discovery(DreamState.EVENT_PUFF_IN_FOG)  # Tower Code calls this when a puff lands in Mistveil's fog
	_check(dreams.event_discovered("puff_in_fog"), "a Puffball puff in Mistveil's fog discovers Chain Bloom")
	var cache := _card(dreams, "warm_hearth")  # Needs an Acorn (Acorn Cache was cut)
	_check(not dreams.discovery_met(cache), "Warm Hearth waits for an Acorn to be built")
	var before: Array[UpgradeData] = [cache]  # A Grove card: not in this run's pool
	var acorn := _build(main, "acorn")
	_check(dreams.discovery_met(cache) and dreams.newly_discovered(before).has(cache.display_name),
		"building an Acorn lets its cards in at once")
	# Half-dreamed cards skip the Warden gate (keep a Reaction gate); whole again, it applies.
	dreams.unlocked["firefly_jar"] = true
	dreams._offer_drift = 10
	var beaks := _card(dreams, "static_bloom")  # Stormcap (Firefly Jar's) + Bloomcap
	_check(not dreams.discovery_met(beaks), "Charged Bloom waits for Charged + Drowsy on one nightmare")
	dreams.note_discovery(DreamState.EVENT_CHARGED_DROWSY)
	_check(dreams.is_half_dreamed(beaks) and dreams.discovery_met(beaks), "a half-dreamed card skips the Warden gate (%s)" % [dreams.half_dreamed_missing(beaks)])
	for family in dreams.half_dreamed_missing(beaks):
		dreams.unlocked[family] = true
	_check(not dreams.is_half_dreamed(beaks) and not dreams.discovery_met(beaks), "…whole again, it waits for its Wardens")
	dreams._offer_drift = 0
	acorn.queue_free()
	dreams.discovery_profile = null
	dreams._built_this_run.clear()
	dreams._events_this_run.clear()
	if feedback != null:
		feedback.run_counts = run_counts
	if tracker != null:
		tracker.longest_chain = chain
	_check(dreams.discovery_met(thunder), "tests without a profile have everything discovered")

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

# Each run draws its own pool (dream_design.md "Exact rules"): seeded by the map, floors per rarity, nothing pulled
# in by taking a card, family picks and discoveries add; offers always fill on a fresh profile.
func _test_run_pool(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	_reset_dreams(main)
	dreams.run_pool_forced = true
	dreams.discovery_profile = {"seen": [], "wardens_built": [], "best_chain": 0}  # A fresh account
	dreams.grove_cards.clear()
	dreams.unlocked["sporeling"] = true
	dreams.build_run_pool(11)
	var first := dreams.run_pool.keys()
	dreams.build_run_pool(11)
	var again := dreams.run_pool.keys()
	dreams.build_run_pool(12)
	var other := dreams.run_pool.keys()
	first.sort()
	again.sort()
	other.sort()
	_check(first == again and first != other, "same map seed, same pool; another seed, another pool")
	_check(first.has("quickened_sap") and first.has("morning_dew"), "the core: the basics")
	# A held family's cards are not core (user: "there shouldn't always be a family card"): a seeded ~60%, never all
	var spore_cards := _family_cards(dreams, "sporeling")
	var spore_in := spore_cards.filter(func(c: UpgradeData) -> bool: return dreams.run_pool.has(c.id) or dreams._run_pool_waiting.has(c.id)).size()
	_check(spore_cards.size() < 5 or (spore_in < spore_cards.size() and spore_in >= floori(spore_cards.size() * 0.4)),
		"Sporeling's cards: about 60%% drawn, never all (%d of %d)" % [spore_in, spore_cards.size()])
	var family_draws := {}
	var seed_before: int = dreams.map_generator.map_seed
	for s in [11, 12, 13, 14, 15]:
		dreams.map_generator.map_seed = s
		dreams.build_run_pool(s)
		var drawn_ids: Array = []
		for c in spore_cards:
			if dreams.run_pool.has(c.id) or dreams._run_pool_waiting.has(c.id):
				drawn_ids.append(c.id)
		family_draws[",".join(drawn_ids)] = true
	_check(family_draws.size() > 1, "…a different family sample on another map seed (%d different over 5 seeds)" % family_draws.size())
	dreams.map_generator.map_seed = seed_before
	dreams.build_run_pool(11)
	var available := {}
	for card in dreams.pool:
		if card.in_start_pool and dreams._card_family(card) == "" and not DreamState.RUN_POOL_BASICS.has(card.id) and dreams.discovery_met(card) \
				and card.kind != UpgradeData.Kind.UNLOCK_WARDEN and card.kind != UpgradeData.Kind.UNLOCK_EVOLUTION and card.id != "heartwoods_reach":
			available[card.rarity] = int(available.get(card.rarity, 0)) + 1
	for rarity in DreamState.RUN_POOL_FLOORS:
		var drawn := dreams.pool.filter(func(c: UpgradeData) -> bool:
			return c.rarity == rarity and dreams.run_pool.has(c.id) and dreams._card_family(c) == "" \
				and not DreamState.RUN_POOL_BASICS.has(c.id) and c.id != "heartwoods_reach").size()
		_check(drawn >= mini(DreamState.RUN_POOL_FLOORS[rarity], int(available.get(rarity, 0))),
			"rarity %d: %d drawn, floor %d of %d available" % [rarity, drawn, DreamState.RUN_POOL_FLOORS[rarity], int(available.get(rarity, 0))])
	var before := dreams.run_pool.size()
	var tagged: UpgradeData = dreams.pool.filter(func(c: UpgradeData) -> bool: return dreams.run_pool.has(c.id) and c.tags.has("maze")).front()
	dreams.take(tagged)
	_check(dreams.run_pool.size() == before, "taking a maze card adds nothing to the pool")
	dreams.unlocked["dewdrop"] = true  # A family pick
	dreams.in_run_pool(tagged)
	var dew_cards := _family_cards(dreams, "dewdrop")
	var dew_in := dew_cards.filter(func(c: UpgradeData) -> bool: return dreams.run_pool.has(c.id) or dreams._run_pool_waiting.has(c.id)).size()
	_check(dew_in > 0 and (dew_cards.size() < 5 or dew_in < dew_cards.size()),  # Drawn (or waiting for discovery)
		"a family pick adds a sample of its family cards, never all (%d of %d)" % [dew_in, dew_cards.size()])
	var waiting: Array = dreams._run_pool_waiting.keys()
	if not waiting.is_empty():
		var card := _card(dreams, waiting[0])
		_check(not dreams.in_run_pool(card), "an undiscovered card waits outside the pool")
		dreams.discovery_profile = null  # Everything discovered
		_check(dreams.in_run_pool(card), "…and joins the moment it's discovered")
		dreams.discovery_profile = {"seen": [], "wardens_built": [], "best_chain": 0}
	var saved := dreams.to_save()
	dreams.run_pool.clear()
	dreams.load_save(JSON.parse_string(JSON.stringify(saved)))
	_check(dreams.run_pool.has(tagged.id) and dreams.run_pool.size() >= before, "the run's pool is saved")
	# 19 Dreams on a fresh profile: every offer shows 3 different cards
	_reset_dreams(main)
	dreams.unlocked["sporeling"] = true
	dreams.build_run_pool(7)
	var short := 0
	for drift in range(5, 100, 5):
		var offer := dreams.make_offer(drift)
		var unique := {}
		for c in offer:
			unique[c.id] = true
		if offer.size() < 3 or unique.size() != offer.size():
			short += 1
		dreams._note_passed(offer, drift / 5)  # Passed over: the fade and "not in the next offer" apply
	_check(short == 0, "19 offers on a fresh profile: never fewer than 3 cards, never a repeat (%d short)" % short)
	dreams.run_pool_forced = false
	dreams.run_pool.clear()
	dreams.discovery_profile = null
	_reset_dreams(main)

# Family Blessings are Rare Dream cards now (meta_design.md "Replaced 2026-09-30"): offered once you own the
# family (and a Warden of it has stood on the map), never before; one per family.
func _test_blessing_dream(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	_reset_dreams(main)
	for card in MetaRun.load_blessings():  # MetaRun puts them in the pool at run start
		if not dreams.pool.any(func(c: UpgradeData) -> bool: return c.id == card.id):
			dreams.pool.append(card)
	var blessing := _card(dreams, "blessing_sporeling")
	_check(blessing != null and blessing.rarity == UpgradeData.Rarity.RARE and blessing.max_stacks == 1 and blessing.tags == ["spore"],
		"the Sporeling Blessing: Rare, one per run, the family line tag")
	_check(not dreams.can_offer(blessing, 2), "…not offered without the Sporeling family")
	dreams.unlocked["sporeling"] = true
	dreams.grown_wardens["sporeling"] = true
	dreams.unlocks_changed.emit()
	_check(dreams.can_offer(blessing, 2), "…offered once you own Sporeling")
	var seen := false
	for i in 200:
		dreams.dreams_seen = 0
		if dreams.make_offer(30).has(blessing):  # Act 2 (Blessings may wait for it, Meta)
			seen = true
			break
	_check(seen, "a Blessing can turn up as a Dream")
	dreams.take(blessing)
	_check(not dreams.can_offer(blessing, 2), "…and only once")
	_reset_dreams(main)

# Round 5 (dream_design.md "Round 4 measured"): a Warden a card names must have been built or grown this
# run; unlocked (a free branch) isn't enough, and selling it later doesn't un-meet it.
func _test_grown_needs(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	_reset_dreams(main)
	dreams.grown_wardens.clear()
	dreams.unlocked["firefly_jar"] = true
	dreams.unlocked["stormcap"] = true  # Unlocked with Dreamlight, not grown yet
	dreams.unlocked["dewdrop"] = true
	dreams.unlocks_changed.emit()
	var thunder := _card(dreams, "rolling_thunder")  # Stormcap + any Dewdrop
	_check(dreams.is_unlocked("stormcap") and not dreams.grown_needs_met(thunder) and not dreams.can_offer(thunder, 2),
		"a Stormcap card isn't offered after the first pick (Stormcap only unlocked)")
	var planted: Array[Tower] = []
	for id in ["stormcap", "dewdrop"]:
		var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
		tower.tower_data = load("res://resource/tower/%s.tres" % id)
		tower.cell = Vector2(120 + planted.size() * 3, 120)
		main.get_node("%TowerContainer").add_child(tower)
		tower.set_process(false)
		planted.append(tower)
	_check(dreams.grown_needs_met(thunder), "…once a Stormcap (and a Dewdrop) has stood on the map it is")
	for tower in planted:
		tower.free()
	_check(dreams.grown_needs_met(thunder), "…and stays offered after they're sold")
	var saved := dreams.to_save()
	dreams.grown_wardens.clear()
	dreams.load_save(JSON.parse_string(JSON.stringify(saved)))
	_check(dreams.grown_wardens.has("stormcap"), "grown Wardens survive a save")
	dreams.unlock_everything = true
	dreams.grown_wardens.clear()
	_check(dreams.grown_needs_met(thunder), "Test Grove: no need to grow anything")
	_reset_dreams(main)


# Fewer family boosters, more build shapes (dream_design.md 21ac910b): at most 1 family card (needs a Warden) and 1 plain
# stat card per offer, with several families owned.
func _test_offer_shape(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	_reset_dreams(main)
	for family in ["sporeling", "dewdrop", "firefly_jar", "pebbling", "rootling", "acorn"]:
		dreams.unlocked[family] = true
	dreams.unlocks_changed.emit()
	_check(dreams.is_family_card(_card(dreams, "spore_cascade")) and not dreams.is_family_card(_card(dreams, "deeper_calm")),
		"a family card needs a Warden (Spore Cascade); Deeper Calm doesn't")
	var most_family := 0
	var most_plain := 0
	for i in 120:
		dreams._passed_count.clear()
		var offer := dreams.make_offer(12 + i % 60)
		most_family = maxi(most_family, offer.filter(dreams.is_family_card).size())
		most_plain = maxi(most_plain, offer.filter(func(c: UpgradeData) -> bool: return DreamState.PLAIN_STAT_CARDS.has(c.id)).size())
	_check(most_family <= 1, "at most 1 family card per offer (saw %d)" % most_family)
	_check(most_plain <= 1, "at most 1 plain stat card per offer (saw %d)" % most_plain)
	# Build-defining cards (dream_design.md de439ea8 "B"): from drift 26 every offer holds an unowned defining card
	_check(dreams.is_defining(_card(dreams, "solitude")) and dreams.is_defining(_card(dreams, "thorny_walls"))
		and not dreams.is_defining(_card(dreams, "deeper_calm")), "defining: Solitude and Thorny Walls yes, Deeper Calm no")
	var without_defining := 0
	for i in 60:
		dreams._passed_count.clear()
		var late := dreams.make_offer(25 + i % 40)
		if not late.any(func(c: UpgradeData) -> bool: return dreams.is_defining(c) and not dreams.has_card(c.id)):
			without_defining += 1
	_check(without_defining == 0, "from the act 2 rest (after drift 25) every offer shows an unowned defining card (%d without)" % without_defining)
	var early_without := 0
	for i in 60:
		dreams._passed_count.clear()
		if not dreams.make_offer(15).any(dreams.is_defining):
			early_without += 1
	_check(early_without > 0, "before drift 25 there's no such rule (%d of 60 offers had none)" % early_without)
	# Legendaries as high points (dream_design.md 495076d2): a boss rest belongs to the next act, has a Legendary slot
	# when one can be offered, and its other slots are Rare+
	var legend_open := dreams.pool.filter(func(c: UpgradeData) -> bool: return c.rarity == UpgradeData.Rarity.LEGENDARY and dreams.can_offer(c, 2)).size()
	var boss_offer := dreams.make_offer(25)
	_check(boss_offer.all(func(c: UpgradeData) -> bool: return c.is_rare_or_better()), "a boss rest: every slot Rare+ (%s)" % [boss_offer.map(func(c: UpgradeData) -> String: return c.id)])
	_check(legend_open == 0 or boss_offer.any(func(c: UpgradeData) -> bool: return c.rarity == UpgradeData.Rarity.LEGENDARY),
		"…and a Legendary when one can be offered (%d open, act 2 at the rest after drift 25)" % legend_open)
	_reset_dreams(main)
func _reset_dreams(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.free_first_clears = 0
	dreams.unlock_everything = false
	dreams.stacks.clear()
	var run_state: RunState = main.get_node("%RunState")
	run_state.add_free_clears(-run_state.free_clears)  # A random Dream pick may have been Heartwood's Reach
	dreams.unlocked = {"sprout": true, "thornwall": true}
	dreams.dreams_seen = 0
	dreams._dreams_without_rare = 0
	dreams._rare_dreams_left = 0
	dreams._extra_cards_next = 0
	dreams._offer_drift = 0
	dreams._declined_families.clear()
	dreams._passed_count.clear()
	dreams._passed_at.clear()
	dreams.unlocks_changed.emit()

# Like _reset_dreams, without signals (the simulation runs thousands of times).
func _reset_dreams_quiet(dreams: DreamState) -> void:
	dreams.stacks.clear()
	dreams.unlocked = {"sprout": true, "thornwall": true}
	dreams.dreams_seen = 0
	dreams._dreams_without_rare = 0
	dreams._rare_dreams_left = 0
	dreams._extra_cards_next = 0
	dreams._offer_drift = 0
	dreams._declined_families.clear()
	dreams._passed_count.clear()
	dreams._passed_at.clear()

func _clear(main: Node) -> void:
	for child in main.get_node("%EnemyContainer").get_children():
		child.queue_free()
	var seller: TowerSeller = main.get_node("%TowerSeller")
	for tower in main.get_node("%TowerContainer").get_children():
		seller.sell(tower.cell)

func _free_cell(map_generator) -> Vector2:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	# Also keep every creature's way out open (the placement rule), or the build is refused. Test
	# creatures placed where no route exists can't be cut off, so they don't count.
	var enemy_cells := PackedVector2Array()
	for enemy in map_generator.get_node("%EnemyContainer").get_maze_walkers():
		if not map_generator.get_path_from(enemy.get_target_cell()).is_empty():
			enemy_cells.append(enemy.get_target_cell())
	var cells := Tower.route_cells(path)  # Half cells: route points are x.25 / x.75; the whole cells they pass over
	var route := {}
	for c in cells:
		route[c] = true
	for i in range(3, cells.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = cells[i] + offset
			if route.has(cell):
				continue  # Whole cells off the route only
			if map_generator.can_block(cell, enemy_cells) and not _near_enemy(map_generator, cell):
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

# A family's cards in the start pool (the run pool samples ~60% of them when the family is held).
func _family_cards(dreams: DreamState, family: String) -> Array:
	var out: Array = []
	for c in dreams.pool:
		if dreams._card_family(c) == family and c.in_start_pool and c.kind != UpgradeData.Kind.UNLOCK_WARDEN \
				and c.kind != UpgradeData.Kind.UNLOCK_EVOLUTION:
			out.append(c)
	return out
