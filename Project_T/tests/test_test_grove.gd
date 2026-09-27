extends SceneTree

# Headless test for the Test Grove dev mode (demo_scope.md): every Warden in the bar, every growth
# without its Dream (Dew still applies), no family picks left, +500 Dew, skip to drift N.
#   godot --headless --path . --script res://tests/test_test_grove.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	# Off: a normal run (no saved setting / launch flag in tests)
	TestGrove.force_on = false
	var normal: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(normal)
	await process_frame
	_check(not is_instance_valid(normal.get_node_or_null("TestGrove")) or normal.get_node("TestGrove").is_queued_for_deletion(),
		"Test Grove removes itself when off")
	_check(not normal.get_node("%DreamState").unlock_everything, "a normal run keeps its unlocks")
	normal.free()
	await process_frame

	TestGrove.force_on = true
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var run_state: RunState = main.get_node("%RunState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var grove: TestGrove = main.get_node("%TestGrove")

	_check(TestGrove.is_available(), "Test Grove is available in debug builds")
	_check(placer.get_buildable_towers().size() == placer.towers.size(),
		"every Warden family is in the bar (%d / %d)" % [placer.get_buildable_towers().size(), placer.towers.size()])
	_check(main.get_node("%TowerBar").get_child_count() == placer.towers.size(), "the tower bar shows them all")
	_check(main.get_node("HUD/FamilyPickScreen").get_available().is_empty(), "no family picks left to offer")

	# Grow a base all the way to its final form without Dreams; each step still costs Dew
	var firefly: TowerData = load("res://resource/tower/firefly_jar.tres")
	var stormcap: TowerData = load("res://resource/tower/stormcap.tres")
	var thunderhead: TowerData = load("res://resource/tower/thunderhead.tres")
	run_state.dew = 1000
	placer.tower_data = firefly
	var cell := _free_cell(main.get_node("%MapGenerator"))
	_check(placer._try_build(cell), "plant a Firefly Jar")
	var tower: Tower = main.get_node("%TowerSeller").get_tower_at(cell)
	var dew := run_state.dew
	_check(tower != null and placer.evolve(tower, stormcap) and run_state.dew == dew - dreams.get_evolve_cost(stormcap),
		"grow into Stormcap without its Dream, for Dew")
	_check(placer.evolve(tower, thunderhead), "grow into the Thunderhead final form without its Dream")
	run_state.dew = 0
	_check(not placer.evolve(tower, stormcap), "growing still needs Dew")

	# Tools
	grove.give_dew()
	_check(run_state.dew == 500, "+500 Dew")
	_check(grove.skip_to(20) and director.drifts_started == 19, "skip to drift 20 at a rest")
	director.start_next_drift()
	_check(director.drifts_started == 20, "the next Start begins drift 20")
	_check(not grove.skip_to(30), "no skipping while nightmares walk")
	grove.clear_field()
	_check(main.get_node("%EnemyContainer").get_enemies().is_empty(), "clear the field dispels everything")

	await _test_tools(main, grove)
	TestGrove.force_on = false
	print("test grove test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# Test tools v2: damage attribution (DamageLog), the dummy, meter, Inspect, invulnerable Heartwood.
func _test_tools(main: Node, grove: TestGrove) -> void:
	var damage_log: DamageLog = main.get_node("%DamageLog")
	var run_state: RunState = main.get_node("%RunState")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var spawner = main.get_node("%EnemyContainer")
	_check(DamageLog.instance == damage_log, "the DamageLog is reachable")
	damage_log.reset_drift(1)
	run_state.dew = 10000

	# Plain hit and crit: credited to the Warden, crit share = 1 − 1/crit multiplier
	var sporeling := _build(main, "sporeling")
	var target := _spawn_near(main, sporeling.cell + Vector2(1, 0))
	var events: Array = []
	damage_log.damage_dealt.connect(func(e: DamageLog.Event) -> void: events.append(e))
	sporeling.hit(target, 1.0, false, Tower.NO_CRIT)
	_check(not events.is_empty() and events[0].source == sporeling and events[0].amount > 0.0 and events[0].combos.is_empty(),
		"a hit is credited to its Warden")
	events.clear()
	sporeling.hit(target, 1.0, false, Tower.CRIT)
	var crit_mult: float = sporeling.attack_data.crit_multiplier
	_check(not events.is_empty() and events[0].combos.has(&"crit")
		and is_equal_approx(events[0].combo_amount, events[0].amount * (1.0 - 1.0 / crit_mult)),
		"a crit's extra damage counts as a combo")
	# Status ticks are credited to whoever applied them
	_check(target.statuses.source(EnemyStatuses.SPORED) == sporeling, "Spored remembers the Sporeling")
	events.clear()
	target.take_damage(5.0, "spore", true, false, target.statuses.source(EnemyStatuses.SPORED), &"spored")
	_check(not events.is_empty() and events[0].kind == &"status" and events[0].source == sporeling, "Spored ticks count as its status damage")
	var stats := damage_log.get_tower_stats(sporeling)
	_check(stats.drift > 0.0 and stats.drift_status > 0.0, "per-Warden totals: damage and status damage")

	# Lightning through Damp: jumps beyond the normal count are "conducted"
	_free_enemies(main)
	var storm := _build(main, "stormcap")
	var row: Array[Node2D] = []
	for i in 5:
		var e := _spawn_near(main, storm.cell + Vector2(1, 0), Vector2(0, 64 * i - 128))
		e.apply_status(EnemyStatuses.DAMP)
		row.append(e)
	events.clear()
	storm._chain_strike(row[2])
	var conducted := events.filter(func(e: DamageLog.Event) -> bool: return e.combos.has(&"conducted")).size()
	_check(conducted == 5 - storm.attack_data.chain_targets, "jumps through Damp are tagged conducted (%d)" % conducted)
	var rows := damage_log.get_meter_rows()
	var storm_row: Array = rows.filter(func(r: Dictionary) -> bool: return r.tower == storm)
	_check(not storm_row.is_empty() and storm_row[0].combo_share > 0.0 and storm_row[0].combos.has(&"conducted"),
		"the meter shows Stormcap's combo share")
	_check(grove.get_meter_text().contains("Stormcap"), "meter text lists the Wardens")

	# Inspect
	var inspect := grove.get_inspect_text(row[0])
	_check(inspect.contains(row[0].enemy_data.display_name) and inspect.contains("Damp") and inspect.contains("Last hits"),
		"Inspect shows the nightmare, its statuses and its last hits")
	_check(grove.nightmare_at(row[0].global_position) == row[0], "clicking finds the nightmare under the cursor")
	_free_enemies(main)

	# Target Dummy: never dispelled, loops the route
	var dummy := grove.toggle_dummy(load("res://resource/enemy/leaf_bug.tres") if ResourceLoader.exists("res://resource/enemy/leaf_bug.tres") else null)
	_check(dummy != null and dummy.unkillable and dummy.loops_route, "the Target Dummy spawns")
	dummy.take_damage(1000000.0, "", false, false, storm)
	_check(not dummy.is_cleansed and dummy.health == 1, "the Target Dummy can't be dispelled")
	_check(damage_log.get_dps(null, dummy) > 0.0 and damage_log.get_dps_by_source(dummy).has("Stormcap"),
		"damage per second on the dummy, by Warden")
	dummy.position += Vector2(200, 0)
	dummy._restart_route()
	var map_generator = main.get_node("%MapGenerator")
	_check(dummy.get_current_cell() == map_generator.startPath, "the dummy walks the route again from the start")
	grove.toggle_dummy()
	_check(grove.dummy == null, "the dummy toggles off")

	# Spawn panel, invulnerable Heartwood, damage numbers
	var bug: EnemyData = grove.enemy_types[0]
	var spawned := grove.spawn(bug, 1, true)
	_check(spawned != null and spawned.elite, "spawn an elite nightmare")
	grove.set_invulnerable(true)
	var leaves := run_state.leaves
	run_state.lose_leaves(5)
	_check(run_state.leaves == leaves, "invulnerable Heartwood: no leaves fall")
	grove.set_invulnerable(false)
	grove.set_numbers_mode(DamageLog.NumbersMode.ALL)
	var numbers_before := damage_log.get_child_count()
	storm.hit(spawned)
	_check(damage_log.get_child_count() > numbers_before, "damage numbers appear")
	grove.set_numbers_mode(DamageLog.NumbersMode.OFF)
	grove.clear_field()
	await process_frame

	# The dock sits on the right and never covers the Warden bar, Warden panel or drift controls
	# (at a real screen size: headless windows start tiny)
	root.size = Vector2i(1920, 1080)
	await process_frame
	await process_frame
	var dock: Rect2 = grove._dock.get_global_rect()
	for name in ["TowerBar", "WardenPanel", "DriftPanel", "DewLabel", "LeavesLabel", "PathLabel", "NightmareInfo"]:
		var other := main.get_node("HUD/" + name) as Control
		_check(not dock.intersects(other.get_global_rect()), "the dock doesn't overlap %s (%s vs %s)" % [name, dock, other.get_global_rect()])
	_check(dock.position.x > main.get_viewport().get_visible_rect().size.x / 2,
		"the dock is on the right (%s in %s)" % [dock, main.get_viewport().get_visible_rect()])
	grove.toggle_dock()
	_check(not grove._dock_body.visible, "F10 collapses the dock")
	grove.toggle_dock()

	# Every Dream is in the pool (Grove-only too), and "Take any Dream" applies one now
	var dreams: DreamState = main.get_node("%DreamState")
	var bloom: UpgradeData = null
	for card in dreams.pool:
		if card.id == "chain_bloom":
			bloom = card
	_check(bloom != null and dreams.is_eligible(bloom, 2), "Grove-only Dreams can be offered in Test Grove")
	_check(grove.take_dream(bloom) and dreams.has_rule(&"chain_bloom"), "Take any Dream applies it now")
	_check(not grove.take_dream(bloom), "a once-only Dream can't be taken twice")

func _build(main: Node, id: String) -> Tower:
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	placer.tower_data = load("res://resource/tower/%s.tres" % id)
	var cell := _free_cell(main.get_node("%MapGenerator"))
	_check(placer._try_build(cell), "built %s" % id)
	var tower: Tower = main.get_node("%TowerSeller").get_tower_at(cell)
	tower.set_process(false)
	return tower

func _spawn_near(main: Node, cell: Vector2, offset: Vector2 = Vector2.ZERO) -> Node2D:
	var spawner = main.get_node("%EnemyContainer")
	var enemy = spawner.enemy_scene.instantiate()
	enemy.enemy_data = TestGrove._load_enemy_types()[0]
	spawner.add_child(enemy)
	enemy.position = enemy.grid.calculate_map_position(cell) + offset
	enemy.set_path(PackedVector2Array([enemy.grid.calculate_grid_coordinates(enemy.position)]))
	enemy.set_process(false)
	enemy.max_health = 1000000  # Survives every test hit
	enemy.health = enemy.max_health
	return enemy

func _free_enemies(main: Node) -> void:
	for child in main.get_node("%EnemyContainer").get_children():
		child.free()

func _free_cell(map_generator) -> Vector2:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	for i in range(3, path.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if not path.has(cell) and map_generator.can_block(cell):
				return cell
	return Vector2(-1, -1)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
