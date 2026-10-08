extends SceneTree

# Headless test for the attack tracker (story chat; the user: "every 4th pulse Roots on the Warden, they need a
# tracker then"): a Rootling's pips count its pulses and empty on the 4th (the one that Roots), timed forms get a ring,
# and Wardens with no counted trigger get no tracker at all.
#   godot --headless --path . --script res://tests/test_count_tracker.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_count_tracker_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var spawner = main.get_node("%EnemyContainer")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	var rootling := _plant(placer, "rootling", Vector2(3, 3))
	var tracker := rootling.get_node_or_null("CountTracker") as CountTracker
	_check(tracker != null, "a Rootling has a tracker over its head")
	var every := int(rootling.get_count_tracker()[1])
	_check(every == 4, "…counting to its pulse_hold_every (%d)" % every)
	for i in 3:
		rootling._release()
	await process_frame
	_check(int(rootling.get_count_tracker()[0]) == 3, "3 pulses: 3 pips (%d)" % rootling.get_count_tracker()[0])
	_check(tracker != null and tracker._count == 3 and tracker._count == tracker._every - 1, "…and the row glows: the next pulse Roots")
	rootling._release()
	await process_frame
	_check(int(rootling.get_count_tracker()[0]) == 0, "the 4th pulse resets it (%d)" % rootling.get_count_tracker()[0])
	_check(tracker != null and tracker._flash > 0.0, "…with a flash")

	var thunderhead := _plant(placer, "thunderhead", Vector2(6, 3))
	_check(int(thunderhead.get_count_tracker()[1]) == thunderhead.tower_data.storm_every, "Thunderhead counts to its storm")
	var sporeling := _plant(placer, "sporeling", Vector2(9, 3))
	_check(sporeling.get_node_or_null("CountTracker") == null, "a Sporeling has nothing to count: no tracker")
	var rootcurl := _plant(placer, "rootcurl", Vector2(12, 3))
	var timed := rootcurl.get_timer_tracker()
	_check(int(rootcurl.get_count_tracker()[1]) == 0 and is_equal_approx(float(timed[1]), rootcurl.tower_data.ability_every)
		and rootcurl.get_node_or_null("CountTracker") != null, "Rootcurl's timed pull gets a ring (%.1f s)" % timed[1])
	# Growing into a form without a trigger drops the tracker.
	rootling.tower_data = load("res://resource/tower/tangleroot.tres")
	rootling._apply_data()
	await process_frame
	await process_frame
	var still := rootling.get_node_or_null("CountTracker")
	_check(still != null and float(rootling.get_timer_tracker()[1]) > 0.0, "grown into Tangleroot: the pips become its hold ring")

	print("count tracker test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _plant(placer: TowerPlacer, id: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = Tower.MAP_GRID.calculate_map_position(cell)
	placer.tower_container.add_child(tower)
	tower.set_process(false)
	return tower

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
