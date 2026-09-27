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
	var spawner = main.get_node("%EnemyContainer")
	var run_state: RunState = main.get_node("%RunState")
	var speed: GameSpeed = main.get_node("%GameSpeed")
	var offers := []
	dreams.offer_ready.connect(func(cards: Array, n: int) -> void: offers.append([cards, n]))
	director.start_next_drift()
	for i in 3000:
		if director.drifts_cleared >= 1:
			break
		for e in spawner.get_enemies():
			e.take_damage(100000)
		await process_frame
	_check(offers.size() == 1 and offers[0][1] == 1, "a Dream after drift 1")
	var ids := (offers[0][0] as Array).map(func(c: UpgradeData) -> String: return c.id)
	ids.sort()
	_check(ids == ["dream_dewdrop", "dream_firefly_jar", "dream_sporeling"], "first Dream offers the 3 base Wardens (%s)" % [ids])
	_check(paused and speed.paused, "the game pauses for a Dream")
	var firefly: UpgradeData = offers[0][0].filter(func(c: UpgradeData) -> bool: return c.id == "dream_firefly_jar")[0]
	dreams.choose(firefly)
	_check(dreams.is_unlocked("firefly_jar") and not dreams.is_offering(), "choosing unlocks Firefly Jar")
	_check(not paused, "the game resumes after the Dream")
	_check(main.get_node("%TowerBar").get_child_count() == 3, "Firefly Jar joins the tower bar")

	# Let it pass
	dreams._pending_drifts.append(3)
	var dew := run_state.dew
	dreams._show_next_offer()
	dreams.skip()
	_check(run_state.dew == dew + 15, "letting a Dream pass gives 15 Dew")

	# Eligibility
	_check(dreams.is_eligible(_card(dreams, "dream_stormcap")), "Stormcap card needs Firefly Jar (owned)")
	_check(not dreams.is_eligible(_card(dreams, "dream_rain_lily")), "Rain Lily card needs Dewdrop (not owned)")
	_check(not dreams.is_eligible(_card(dreams, "dream_firefly_jar")), "no card for a Warden you already have")

	# Boss Dream guarantees Rare+, and pity kicks in after 3 without (Conductive Soil becomes
	# eligible once both Firefly Jar and Dewdrop are owned)
	dreams.take(_card(dreams, "dream_dewdrop"))
	var boss_offer := dreams.make_offer(5)
	_check(boss_offer.any(func(c: UpgradeData) -> bool: return c.is_rare_or_better()), "boss Dream has a Rare+ card")
	var saw_rare_by_4 := true
	for trial in 20:
		dreams._dreams_without_rare = 3
		var offer := dreams.make_offer(3)
		if not offer.any(func(c: UpgradeData) -> bool: return c.is_rare_or_better()):
			saw_rare_by_4 = false
	_check(saw_rare_by_4, "pity: 3 Dreams without Rare+ guarantees one")
	_clear(main)

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
	run_state.leaves = 15
	dreams.take(_card(dreams, "deep_roots"))
	_check(run_state.max_leaves == 22 and run_state.leaves == 17, "Deep Roots: +2 max, regrow 2")
	var dewdrop: TowerData = load("res://resource/tower/dewdrop.tres")
	dreams.take(_card(dreams, "soaked_through"))
	_check(is_equal_approx(dreams.get_status_duration(dewdrop, EnemyStatuses.DAMP), 8.0), "Soaked Through doubles Damp")

func _simulate_storm_grid(main: Node) -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	_reset_dreams(main)
	var director: DriftDirector = main.get_node("%DriftDirector")
	director.drifts = []  # Acts by drift number still work (get_act only needs drifts_per_act)
	var want := ["dream_firefly_jar", "dream_dewdrop", "dream_stormcap", "dream_rain_lily", "dream_thunderhead", "conductive_soil"]
	var runs := 1000
	for weight in [dreams.tag_weight, 3.0, 4.0, 6.0]:
		dreams.tag_weight = weight
		var result := _storm_grid_rate(dreams, want, runs)
		print("Storm Grid simulation, tag weight %.0f× (%d runs, aiming for it): full build %.0f%%, without Thunderhead %.0f%% (target ≈ 33%%)"
			% [weight, runs, 100.0 * result[0] / runs, 100.0 * result[1] / runs])
	dreams.tag_weight = 2.0
	var extra_bases := ["dream_pebbling", "dream_rootling", "dream_acorn"]
	var extra_in_pool: bool = _card(dreams, "dream_pebbling").in_start_pool
	for id in extra_bases:
		_card(dreams, id).in_start_pool = not extra_in_pool
	var other := _storm_grid_rate(dreams, want, runs)
	print("  with Pebbling/Rootling/Acorn cards %s the pool: full build %.0f%%, without Thunderhead %.0f%%"
		% ["added to" if not extra_in_pool else "removed from", 100.0 * other[0] / runs, 100.0 * other[1] / runs])
	for id in extra_bases:
		_card(dreams, id).in_start_pool = extra_in_pool
	var owned_rates: Dictionary = _storm_grid_rate(dreams, want, runs)[2]
	var parts: Array[String] = []
	for id in want:
		parts.append("%s %.0f%%" % [id.trim_prefix("dream_"), 100.0 * owned_rates.get(id, 0) / runs])
	print("  how often each piece is owned by the end: " + ", ".join(parts))

func _storm_grid_rate(dreams: DreamState, want: Array, runs: int) -> Array:
	var full := 0
	var partial := 0
	var owned_count := {}
	for run in runs:
		dreams.stacks.clear()
		dreams.unlocked = {"sprout": true, "thornwall": true}
		dreams.dreams_seen = 0
		dreams._dreams_without_rare = 0
		for drift in dreams.dream_after_drifts:
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
	dreams.unlocks_changed.emit()

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
