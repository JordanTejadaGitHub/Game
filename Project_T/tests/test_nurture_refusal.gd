extends SceneTree

# Nurture / grow hotkeys while short of Dew (user: "still able to press the hotkey for nurture when I don't
# have enough Dew"): R opens no rank choices and spends nothing, 1–4 do nothing, the "can't buy" refusal
# plays instead (dew_short: toast, Dew counter, sound; the Nurture button shakes). Group nurture too; G
# while short spends nothing.

const RUN_PATH := "user://test_nurture_refusal_run_%d.json"
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	RunSaver.file_path = RUN_PATH % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var map_generator = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var run_state: RunState = main.get_node("%RunState")
	var dreams: DreamState = main.get_node("%DreamState")
	var panel := main.find_child("WardenPanel", true, false)
	dreams.unlock_everything = true
	for child in main.get_node("%EnemyContainer").get_children():
		child.queue_free()
	await process_frame
	run_state.dew = 10000
	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	var a := _build(placer, map_generator, sporeling)
	var b := _build(placer, map_generator, sporeling)
	_check(a != null and b != null, "two Wardens planted")
	if a == null or b == null:
		quit(failures)
		return
	var shorts := []
	run_state.dew_short.connect(func(cost: int) -> void: shorts.append(cost))

	# One Warden, too little Dew: R refuses, no menu, nothing spent; 1–4 do nothing.
	seller.select(a)
	await process_frame
	run_state.free_nurtures = 0
	run_state.dew = a.get_nurture_price() - 1
	var dew_before := run_state.dew
	_press(main, KEY_R)
	await process_frame
	_check(not panel._choosing and a.rank == 0 and run_state.dew == dew_before, "R short of Dew opens no rank choices and spends nothing")
	_check(not shorts.is_empty() and shorts[-1] == a.get_nurture_price() and panel.nurture_refused == 1,
		"…it plays the can't-buy refusal (dew_short at the price, the button shakes)")
	for key in [KEY_1, KEY_2, KEY_3, KEY_4]:
		_press(main, key)
		await process_frame
	_check(a.rank == 0 and run_state.dew == dew_before and not panel._choosing, "1–4 do nothing while short (no rank; with no menu they're the Warden bar keys)")
	placer.set_build_mode(false)  # 1–4 picked a Warden to plant: back out, reselect
	seller.select(a)
	await process_frame

	# With the Dew, R opens the choices again (and 1 picks a rank).
	run_state.dew = a.get_nurture_price() + 5
	_press(main, KEY_R)
	await process_frame
	var opened: bool = panel._choosing or a.rank == 1  # A single-choice Warden nurtures at once
	_check(opened, "with the Dew, R opens the rank choices")
	if panel._choosing:
		_press(main, KEY_1)
		await process_frame
	_check(a.rank == 1, "…and a choice takes the rank (%d)" % a.rank)

	# A group, nobody can pay: refused the same way.
	seller.set_selection([a, b])
	await process_frame
	run_state.dew = mini(a.get_nurture_price(), b.get_nurture_price()) - 1
	dew_before = run_state.dew
	var refused_before: int = panel.nurture_refused
	_press(main, KEY_R)
	await process_frame
	_check(not panel._choosing and a.rank == 1 and b.rank == 0 and run_state.dew == dew_before and panel.nurture_refused == refused_before + 1,
		"group R short of Dew: no choices, nothing ranks, the refusal plays")

	# G (grow) while short spends nothing.
	seller.select(a)
	await process_frame
	run_state.dew = 0
	var data_before := a.tower_data
	_press(main, KEY_G)
	await process_frame
	_check(a.tower_data == data_before and run_state.dew == 0, "G short of Dew grows nothing")

	print("nurture refusal test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# A key press and release through the input system (the real hotkey path).
func _press(main: Node, key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = key
		event.keycode = key
		event.pressed = pressed
		Input.parse_input_event(event)
	Input.flush_buffered_events()

func _build(placer: TowerPlacer, map_generator, data: TowerData) -> Tower:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var container: Node = placer.tower_container
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

func _check(condition: bool, label: String) -> void:
	if condition:
		print("ok  " + label)
	else:
		failures += 1
		printerr("FAIL: " + label)
