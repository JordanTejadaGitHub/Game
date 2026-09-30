extends SceneTree

# Headless test for the Q / E / Z grow keys (screens_ui.md hotkeys): the selection grows into the Warden
# panel's 1st / 2nd / 3rd option, a locked option opens the Remember tree on that form, and the Grow
# buttons show their key. Run from the project folder:
#   godot --headless --path . --script res://tests/test_grow_keys.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var map = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var run_state: RunState = main.get_node("%RunState")
	var dreams: DreamState = main.get_node("%DreamState")
	var panel: Node = main.find_child("WardenPanel", true, false)
	for child in main.get_node("%EnemyContainer").get_children():
		child.queue_free()
	await process_frame
	run_state.dew = 10000
	_check(InputMap.has_action(&"grow_option_1") and TowerSeller.key_name(&"grow_option_1") == "Q"
		and TowerSeller.key_name(&"grow_option_2") == "E" and TowerSeller.key_name(&"grow_option_3") == "Z",
		"grow_option_1..3 exist, on Q / E / Z by default")

	# Locked: E opens the Remember tree on the 2nd option.
	dreams.unlock_everything = false
	dreams.unlocked[&"sporeling"] = true
	var spore := _build(placer, map, load("res://resource/tower/sporeling.tres"))
	seller.select(spore)
	await process_frame
	var options := Tower.grow_options(dreams, spore.tower_data)
	_check(options.size() >= 2 and not options[1][1], "a fresh run: the Sporeling's forms are still locked")
	var focused := [null]
	dreams.remember_requested.connect(func(form) -> void: focused[0] = form)
	_press(seller, KEY_E)
	_check(focused[0] == options[1][0], "E on a locked form opens Remember on it (%s)" % focused[0])
	_check(spore.tower_data.get_id() == "sporeling", "and doesn't grow it")

	# Unlocked: holding E previews (held signal), letting go grows into the 2nd option.
	dreams.unlock_everything = true
	seller.select(null)
	seller.select(spore)
	await process_frame
	var badges: Array = panel.find_children("*", "Button", true, false).map(func(b: Button) -> String: return b.text)
	_check(badges.any(func(t: String) -> bool: return t.begins_with("Grow into") and t.ends_with("(Q)"))
		and badges.any(func(t: String) -> bool: return t.begins_with("Grow into") and t.ends_with("(E)")),
		"the Grow buttons show Q and E (%s)" % [badges])
	var held := []
	seller.grow_option_held.connect(func(i: int, on: bool) -> void: held.append([i, on]))
	var second: TowerData = Tower.grow_options(dreams, spore.tower_data)[1][0]
	var changes := placer.grow_changes(spore, second)
	_check(changes.contains("Damage") or changes.contains("Range") or changes.contains("adds"),
		"the Grow tooltip lists the stat changes (%s)" % changes)
	_key(seller, KEY_E, true)
	_check(placer.is_previewing_growth(), "holding E previews the new form on the map")
	_key(seller, KEY_E, false)
	_check(not placer.is_previewing_growth(), "letting go ends the preview")
	_check(held == [[1, true], [1, false]], "E held then let go: preview on, off (%s)" % [held])
	_check(spore.tower_data == second, "and it grows into the 2nd option (%s)" % spore.tower_data.get_id())

	# A group: Q grows each into its 1st option.
	var a := _build(placer, map, load("res://resource/tower/sporeling.tres"))
	var b := _build(placer, map, load("res://resource/tower/sporeling.tres"))
	seller.set_selection([a, b])
	var first: TowerData = Tower.grow_options(dreams, a.tower_data)[0][0]
	_press(seller, KEY_Q)
	_check(a.tower_data == first and b.tower_data == first, "Q grows the whole group into the 1st option")

	print("grow keys test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _press(seller: TowerSeller, key: Key) -> void:
	_key(seller, key, true)
	_key(seller, key, false)

func _key(seller: TowerSeller, key: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = down
	seller._unhandled_input(event)

func _build(placer: TowerPlacer, map, data: TowerData) -> Tower:
	placer.tower_data = data
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	for i in range(3, route.size() - 3):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = route[i] + offset
			if map.is_buildable(cell) and placer._try_build(cell):
				return placer.get_tower_at(cell) if placer.has_method("get_tower_at") else _last(placer)
	return null

func _last(placer: TowerPlacer) -> Tower:
	var container := placer.get_node("%TowerContainer")
	return container.get_child(container.get_child_count() - 1)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
