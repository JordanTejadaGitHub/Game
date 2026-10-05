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
	# Short of Dreamlight (user 2026-10-01): E refuses like R; the button shakes, a toast, the counter flashes.
	var dark := []
	dreams.dreamlight_short.connect(func(cost: int) -> void: dark.append(cost))
	var refusals: int = panel.grow_refused
	# The form a Dreamlight unlock opens (E, unless the 2nd is Grove-locked: the branch expansion lists the Grove's
	# hidden branch among this run's, then its key is the next free one).
	var keys := [KEY_Q, KEY_E, KEY_Z]
	var pick := 1
	for i in [1, 2, 0]:
		if i < options.size() and not options[i][1] and dreams.get_unlock_blocker(options[i][0]) == "":
			pick = i
			break
	var key: Key = keys[pick]
	dreams.dreamlight = 0
	_press(seller, key)
	_check(focused[0] == null and dark == [dreams.get_unlock_cost(options[pick][0])] and panel.grow_refused == refusals + 1,
		"%s on a locked form short of Dreamlight opens nothing and refuses (%s)" % [OS.get_keycode_string(key), dark])
	dreams.dreamlight = dreams.get_unlock_cost(options[pick][0])
	_press(seller, key)
	_check(focused[0] == options[pick][0], "with the Dreamlight, %s opens Remember on it (%s)" % [OS.get_keycode_string(key), focused[0]])
	_check(spore.tower_data.get_id() == "sporeling", "and doesn't grow it")
	# Grow hover (story chat 2026-10-01): a locked form shows no ring and no ghost, only where it's unlocked;
	# an unlocked one previews (current range faint, its range bright, its sprite) and names its changes.
	var locked_form: TowerData = options[1][0]
	var locked_button := _grow_button(panel, 1)
	locked_button.mouse_entered.emit()
	_check(not placer.is_previewing_growth(), "hovering a locked form's Grow button previews nothing")
	placer.show_grow_preview([[spore, locked_form]])
	_check(not placer.is_previewing_growth(), "nor does asking the map for it (the grow keys)")
	var grove_locked := dreams.get_unlock_blocker(locked_form) == "Memory Grove"
	_check(locked_button.tooltip_text.ends_with(RememberScreen.UNKNOWN_NAME if grove_locked else WardenHeaderView.LOCKED_FORM_TIP)
		and not locked_button.tooltip_text.contains(IconInfo.format(locked_form.description)),
		"its tooltip only says where it's unlocked (%s)" % locked_button.tooltip_text)
	locked_button.mouse_exited.emit()
	var open_form: TowerData = options[0][0]
	dreams.unlocked[open_form.get_id()] = true
	seller.select(null)
	seller.select(spore)
	await process_frame
	var open_button := _grow_button(panel, 0)
	open_button.mouse_entered.emit()
	_check(placer.is_previewing_growth() and placer._grow_preview == [[spore, open_form]],
		"hovering an unlocked form's Grow button shows its ring and ghost")
	# Windowed playtest bug: the placer was hidden outside build mode, so the preview never drew.
	_check(not placer.build_mode and placer.is_visible_in_tree() and is_equal_approx(spore.sprite.modulate.a, TowerPlacer.PREVIEW_FADE),
		"outside build mode the preview is drawn (placer visible) and the Warden fades under the ghost")
	_check(open_button.tooltip_text.contains(open_form.display_name + ":") and open_button.tooltip_text.contains("→"),
		"its tooltip names the form and its changes (%s)" % open_button.tooltip_text.get_slice("\n", 0))
	open_button.mouse_exited.emit()
	_check(not placer.is_previewing_growth(), "pointer off: the preview goes")
	_check(not placer.visible and is_equal_approx(spore.sprite.modulate.a, 1.0), "and the placer hides again, the Warden back to full")
	# Renamed (user: "rename Grow to Unlock if they haven't unlocked it yet"): locked slots read "Unlock X",
	# the unlocked one "Grow into X"; the onboarding pulse (Main's GrowHints) only touches the Grow ones.
	var slots: Array = panel._buttons.get_children().filter(func(b) -> bool: return b is Button and not b.is_queued_for_deletion() and b.has_meta(&"grow_index"))
	_check(slots.filter(func(b: Button) -> bool: return b.has_meta(&"grow_form")).size() == 1  # Light pass: a form row, under "Grow into"
		and slots.filter(func(b: Button) -> bool: return b.text.begins_with("Unlock ") or b.text.begins_with(RememberScreen.UNKNOWN_NAME)).size() == slots.size() - 1,
		"one Grow into, the locked ones Unlock / ??? (%s)" % [slots.map(func(b: Button) -> String: return b.text)])
	_check(panel.pulse(&"grow") == 1, "pulse(&\"grow\") pulses only the Grow button")
	dreams.unlocked.erase(open_form.get_id())

	# Unlocked: holding E previews (held signal), letting go grows into the 2nd option.
	dreams.unlock_everything = true
	seller.select(null)
	seller.select(spore)
	await process_frame
	var grow_rows: Array = panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.has_meta(&"grow_form"))
	var badges: Array = grow_rows.map(func(b: Button) -> String: return b.text)
	_check(badges.any(func(t: String) -> bool: return t.ends_with("(Q)"))
		and badges.any(func(t: String) -> bool: return t.ends_with("(E)")),
		"the Grow buttons show Q and E (%s)" % [badges])
	var held := []
	seller.grow_option_held.connect(func(i: int, on: bool) -> void: held.append([i, on]))
	var second: TowerData = Tower.grow_options(dreams, spore.tower_data)[1][0]
	var changes := placer.grow_changes(spore, second)
	_check(changes.contains("damage") or changes.contains("range") or changes.contains("adds"),
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
			return b.text.begins_with("%s · " % into.display_name) and b.text.ends_with("(%s)" % key_name))
		_check(sprout_options.size() >= 2 and named.size() == 1, "the %s button names %s (%d options)" % [key_name, into.display_name, sprout_options.size()])
		# A Sprout's family Wardens preview too (user: "it helps decide which Warden to grow into, if the range fits").
		if named.size() == 1:
			named[0].mouse_entered.emit()
			_check(placer._grow_preview == [[sprout, into]] and placer.is_visible_in_tree()
				and is_equal_approx(sprout.sprite.modulate.a, TowerPlacer.PREVIEW_FADE),
				"hovering Grow into %s on a Sprout shows its range and ghost" % into.display_name)
			named[0].mouse_exited.emit()
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
	# One can't-afford style (user 2026-10-01, no "more needed"): "Grow into X · 120 Dew (Q)" with only the cost in POOR;
	# the same for Nurture; live: affordable again, the normal look at once.
	var grow_button: Button = panel._buttons.get_children().filter(func(b) -> bool: return b is Button and b.get_meta(&"grow_index", -1) == 0).front()
	var first_form: TowerData = Tower.grow_options(dreams, poor.tower_data)[0][0]
	var want: int = poor.get_grow_cost(first_form).total
	_check(grow_button.text == "%s · %s Dew (Q)" % [first_form.display_name, BossDossier.thousands(want)]
		and grow_button.get_meta(&"short") and grow_button.has_node("Short"), "a short Grow shows its cost (%s)" % grow_button.text)
	var nurture_button: Button = panel._buttons.get_children().filter(func(b) -> bool: return b is Button and b.text.begins_with("Nurture")).front()
	_check(nurture_button.text.ends_with("· %d Dew (R)" % poor.get_nurture_price()) and nurture_button.get_meta(&"short"),
		"a short Nurture reads the same way (%s)" % nurture_button.text)
	_check(grow_button.tooltip_text.begins_with("Not enough Dew.") and (grow_button.get_node("Short").get_child(1) as Label).get_theme_color("font_color") == UiStyle.POOR, "only the cost in POOR; its tip says why")
	run_state.dew = want
	run_state.dew_changed.emit(want)
	_check(not grow_button.get_meta(&"short") and not grow_button.has_node("Short") and grow_button.text.ends_with("%s Dew (Q)" % BossDossier.thousands(want))
		and grow_button.theme_type_variation == &"RowButton", "affordable: the normal look at once (a row: Nurture is the primary) (%s)" % grow_button.text)
	# G short of Dew: nothing grows, the refusal plays.
	run_state.dew = 1
	run_state.dew_changed.emit(1)
	shorts.clear()
	var refused_before: int = panel.grow_refused
	_check(not seller.grow_selected() and poor.tower_data == poor_data and shorts.size() == 1 and panel.grow_refused == refused_before + 1,
		"G with too little Dew grows nothing and refuses (%s)" % [shorts])

	print("grow keys test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _grow_button(panel: Node, index: int) -> Button:
	return panel._buttons.get_children().filter(func(b) -> bool: return b is Button and not b.is_queued_for_deletion() and b.get_meta(&"grow_index", -1) == index).front()

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
