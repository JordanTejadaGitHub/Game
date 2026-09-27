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

	TestGrove.force_on = false
	print("test grove test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

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
