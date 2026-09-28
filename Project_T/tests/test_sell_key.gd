extends SceneTree

# Headless test for the sell key (screens_ui.md hotkeys): X (or Delete) sells the selected Warden; at a
# rest one press sells, during a drift (confirm_sell on) the first press only arms it and a second
# press within 2 s sells; right-click never sells; nothing happens while typing in a text field.
# Run from the project folder:
#   godot --headless --path . --script res://tests/test_sell_key.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var map_generator = main.get_node("%MapGenerator")
	var container: Node = main.get_node("%TowerContainer")
	main.get_node("%RunState").dew = 1000

	var keys := InputMap.action_get_events("sell_tower").filter(func(e) -> bool: return e is InputEventKey)
	_check(keys.any(func(e) -> bool: return e.physical_keycode == KEY_X), "X sells")
	_check(keys.any(func(e) -> bool: return e.physical_keycode == KEY_DELETE), "Delete still sells")
	_check(not InputMap.action_get_events("sell_tower").any(func(e) -> bool: return e is InputEventMouseButton),
		"right-click never sells")
	_check(seller._sell_key_name() == "X", "the prompt names X (%s)" % seller._sell_key_name())

	# At a rest: one press sells the selected Warden.
	var a := _build(placer, map_generator, container)
	seller.select(a)
	_check(seller.sell_key() and not is_instance_valid(a) or a.is_queued_for_deletion(), "at a rest one press sells")
	await process_frame

	# During a drift: the first press arms, the second sells.
	var b := _build(placer, map_generator, container)
	director.resting = false
	seller.select(b)
	seller.sell_key()
	_check(is_instance_valid(b) and not b.is_queued_for_deletion(), "during a drift the first press doesn't sell")
	_check(seller.get_armed_sell() == [b], "it shows the half refund, waiting for a second press")
	seller.sell_key()
	_check(not is_instance_valid(b) or b.is_queued_for_deletion(), "the second press within 2 s sells")
	await process_frame

	# Typing in a text field: the key does nothing.
	var c := _build(placer, map_generator, container)
	director.resting = true
	seller.select(c)
	var field := LineEdit.new()
	main.add_child(field)
	field.grab_focus()
	var press := InputEventKey.new()
	press.physical_keycode = KEY_X
	press.keycode = KEY_X
	press.pressed = true
	seller._unhandled_input(press)
	_check(is_instance_valid(c) and not c.is_queued_for_deletion(), "not while typing in a text field")
	field.release_focus()
	seller._unhandled_input(press)
	_check(not is_instance_valid(c) or c.is_queued_for_deletion(), "and it sells once the field lets go")

	print("sell key test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _build(placer: TowerPlacer, map_generator, container: Node) -> Tower:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	placer.tower_data = load("res://resource/tower/sprout.tres")
	for i in range(3, path.size() - 3):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if path.has(cell) or not map_generator.can_block(cell):
				continue
			var count := container.get_child_count()
			if placer._try_build(cell):
				return container.get_child(count)
	return null

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
