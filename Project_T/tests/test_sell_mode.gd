extends SceneTree

# Headless test for sell mode (user, maze_feel.md 9356ec5a): X while building switches to sell mode (no ghost); a click
# on a Warden sells it (the refund at the live rate); a Warden hotkey / bar pick goes back to build mode; right-click /
# Esc leaves it; X outside build mode still sells the hovered / selected Warden as before (test_sell_key).
#   godot --headless --path . --script res://tests/test_sell_mode.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_sell_mode_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var map = main.get_node("%MapGenerator")
	var run_state: RunState = main.get_node("%RunState")
	var container: Node = main.get_node("%TowerContainer")
	run_state.dew = 1000
	var wall: TowerData = load("res://resource/tower/thornwall.tres")
	placer.select_tower(wall)
	var cell := _free_cell(map)
	_check(placer._try_build(cell), "(setup) a Thornwall planted")
	var tower: Tower = null
	for t in container.get_children():
		if t is Tower and t.cell == cell:
			tower = t
	_check(placer.build_mode and tower != null, "(setup) still building after the placement")

	# X while building: sell mode, the ghost gone.
	placer._unhandled_input(_action("sell_tower", true))
	await process_frame
	_check(seller.sell_mode and not placer.build_mode and seller.active, "X while building switches to sell mode")

	# A click on the Warden sells it at the live rate.
	var refund := seller.get_refund(tower)
	var dew := run_state.dew
	seller._unhandled_input(_action("clear_obstacle", true))
	seller._press_world = tower.global_position  # (Headless: where the click landed)
	seller._input(_action("clear_obstacle", false))
	await process_frame
	_check(not is_instance_valid(tower) or tower.is_queued_for_deletion(), "a click in sell mode sells the Warden")
	_check(run_state.dew == dew + refund, "…for its refund (+%d, Dew %d -> %d)" % [refund, dew, run_state.dew])
	_check(seller.sell_mode, "sell mode stays on after a sale")

	# A Warden hotkey / bar pick: back to build mode with it.
	placer.select_tower(wall)
	await process_frame
	_check(placer.build_mode and not seller.sell_mode, "picking a Warden goes back to build mode")

	# Esc / right-click leaves sell mode.
	placer._unhandled_input(_action("sell_tower", true))
	await process_frame
	_check(seller.sell_mode, "(again) X while building: sell mode")
	seller._unhandled_input(_action("cancel_build", true))
	await process_frame
	_check(not seller.sell_mode and not placer.build_mode, "right-click / Esc leaves sell mode")

	print("sell mode test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _action(action: String, pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event

func _free_cell(map) -> Vector2:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	for x in range(2, Tower.MAP_GRID.size.x - 2):
		for y in range(2, Tower.MAP_GRID.size.y - 2):
			var c := Vector2(x, y)
			if map.is_buildable(c) and map.can_block(c) and not route.has(Tower.MAP_GRID.calculate_map_position(c)):
				return c
	return Vector2(-1, -1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
