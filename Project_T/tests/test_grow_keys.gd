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

	# A Sprout with two families picked: each key grows it into the form its button names, charges the
	# button's price, and the panel follows (playtest bug: the panel kept showing the Sprout).
	dreams.unlock_everything = false
	dreams.unlocked[&"pebbling"] = true
	dreams.unlocked[&"acorn"] = true
	for index in 2:
		var sprout := _build(placer, map, load("res://resource/tower/sprout.tres"))
		seller.set_selection([sprout])
		await process_frame
		var sprout_options := Tower.grow_options(dreams, sprout.tower_data)
		var into: TowerData = sprout_options[index][0]
		var key_name := TowerSeller.key_name(TowerSeller.GROW_OPTION_ACTIONS[index])
		var named: Array = panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool:
			return b.text.begins_with("Grow into %s" % into.display_name) and b.text.ends_with("(%s)" % key_name))
		_check(sprout_options.size() >= 2 and named.size() == 1, "the %s button names %s (%d options)" % [key_name, into.display_name, sprout_options.size()])
		var price: int = sprout.get_grow_cost(into).total
		var dew_before := run_state.dew
		_press(seller, [KEY_Q, KEY_E][index])
		_check(sprout.tower_data == into, "%s grows it into %s (got %s)" % [key_name, into.display_name, sprout.tower_data.display_name])
		_check(dew_before - run_state.dew == price, "charged the button's price (%d, spent %d)" % [price, dew_before - run_state.dew])
		for i in 12:
			await process_frame
		_check(panel._title.text.begins_with(into.display_name), "the panel shows the new form (%s)" % panel._title.text)

	# Nurture v3 playtest fix (warden_stats.md): one Nurture button; R opens the choices, 2 picks Swift and
	# the Warden bar doesn't take the key.
	dreams.unlock_everything = true
	var nursling := _build(placer, map, load("res://resource/tower/sporeling.tres"))
	seller.select(nursling)
	await process_frame
	var nurture_buttons: Array = panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool:
		return b.text.begins_with("Nurture to rank"))
	_check(nurture_buttons.size() == 1 and nurture_buttons[0].text.ends_with("(R)"), "one Nurture button (%s)" % [nurture_buttons.map(func(b: Button) -> String: return b.text)])
	_check(not panel.find_children("*", "Button", true, false).any(func(b: Button) -> bool: return b.get_meta(&"choice", -1) >= 0),
		"the choices stay closed until asked")
	var bar_before: TowerData = placer.tower_data
	var building_before := placer.build_mode
	_push(KEY_R)
	await process_frame
	var rows: Array = panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.get_meta(&"choice", -1) >= 0)
	_check(rows.size() == 4, "R opens the four choices (%d)" % rows.size())
	if rows.size() == 4:
		var edges: Array = rows.map(func(b: Button) -> float: return b.get_child(0).get_child(2).position.x)
		_check(edges.all(func(x: float) -> bool: return is_equal_approx(x, edges[0])), "the price column lines up (%s)" % [edges])
	var options_now := nursling.focus_options()
	_push(KEY_2)
	await process_frame
	_check(nursling.rank == 1 and nursling.rank_choices.back() == options_now[1] and options_now[1] == Tower.Focus.SWIFT,
		"2 picks Swift (rank %d, %s)" % [nursling.rank, nursling.rank_choices])
	_check(placer.tower_data == bar_before and placer.build_mode == building_before, "the Warden bar didn't take the 2")
	_push(KEY_R)
	await process_frame
	_push(KEY_ESCAPE)
	await process_frame
	_check(not panel._choosing and seller.selected == nursling, "Esc closes the choices and keeps the selection")

	# Can't afford (user, 2026-10-01: "still able to press the hotkey for nurture when I don't have enough
	# Dew"): R opens no choices; it plays the refusal (dew_short) and changes nothing. Same for a grow key.
	var shorts: Array = []
	run_state.dew_short.connect(func(cost: int) -> void: shorts.append(cost))
	run_state.dew = 1
	var rank_before := nursling.rank
	seller.select(null)
	seller.select(nursling)
	await process_frame
	_push(KEY_R)
	await process_frame
	var poor_rows: Array = panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.get_meta(&"choice", -1) >= 0)
	_check(poor_rows.is_empty() and shorts.size() == 1, "R short of Dew opens no choices and plays the refusal (%d rows, %s)" % [poor_rows.size(), shorts])
	_check(run_state.dew == 1 and nursling.rank == rank_before, "Dew and the rank unchanged (%d Dew, rank %d)" % [run_state.dew, nursling.rank])
	shorts.clear()
	run_state.dew = 10000
	var poor := _build(placer, map, load("res://resource/tower/sporeling.tres"))
	run_state.dew = 1
	seller.select(poor)
	await process_frame
	var poor_data := poor.tower_data
	_press(seller, KEY_Q)
	_check(poor.tower_data == poor_data and run_state.dew == 1 and shorts.size() == 1,
		"Q with too little Dew doesn't grow it and plays the refusal (%s)" % [shorts])

	print("grow keys test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

# A real key press through the viewport (the panel's _input, then the HUD and TowerSeller).
func _push(key: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = key
		event.keycode = key
		event.pressed = down
		root.push_input(event)

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
