extends SceneTree

# Branch expansion in the Warden panel (Spire branch; Roguelite 320b4969, Main 2026-10-02): branches this run didn't
# draw aren't Grow buttons (Tower.grow_options skips them, so Q / E / Z stay on the shown ones); one quiet line,
# "N more not in this dream · Remember", opens Remember on the first of them, where it can be called back. The hover
# card's "Grows into" ends with the same count. Temp profile.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _form(id: String, tier: int) -> TowerData:
	var data := TowerData.new()
	data.id = id
	data.display_name = id
	data.tier = tier
	data.buildable_directly = tier == 1
	data.line = "spore"
	return data

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_branch_panel_%d.json" % OS.get_process_id()
	ResultsScreen.demo_override = 0  # The full game: the expansion is off in the demo
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 777
	root.add_child(main)
	for i in 3:
		await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var panel = main.find_child("WardenPanel", true, false)
	var map = main.get_node("%MapGenerator")

	var base := _form("test_base", 1)
	for i in 5:
		var branch := _form("test_b%d" % (i + 1), 2)
		branch.evolves_to.append(_form("test_f%d" % (i + 1), 3))
		base.evolves_to.append(branch)
	placer.towers.append(base)
	dreams.unlocked[base.get_id()] = true
	dreams.unlocks_changed.emit()  # A family pick: 2 of the 5 drawn
	var offer: Array = dreams.get_branch_offer(base)
	_check(offer.size() == 2, "the run draws 2 of 5 (%s)" % [offer])

	var options := Tower.grow_options(dreams, base)
	_check(options.size() == 2 and options.all(func(o: Array) -> bool: return offer.has(o[0].get_id())),
		"grow_options lists only this run's 2 branches")
	var hidden := Tower.not_in_dream(dreams, base)
	_check(hidden.size() == 3 and hidden.all(func(f: TowerData) -> bool: return not offer.has(f.get_id())),
		"not_in_dream lists the other 3")

	var cell := Vector2(-1, -1)
	for y in range(2, 16):
		for x in range(2, 21):
			if cell.x < 0 and map.is_buildable(Vector2(x, y)) and not map.get_path_if_blocked(Vector2(x, y)).is_empty():
				cell = Vector2(x, y)
	main.get_node("%RunState").dew = 500
	placer.select_tower(base)
	placer._try_build(cell)
	placer.set_build_mode(false)
	var tower := seller.get_tower_at(cell)
	_check(tower != null, "the test Warden is planted")
	seller.select(tower)
	for i in 3:
		await process_frame
	var texts: Array = panel._buttons.get_children().filter(func(c) -> bool: return c is Button and not c.is_queued_for_deletion()).map(
		func(b: Button) -> String: return b.text)
	var grow_lines := texts.filter(func(t: String) -> bool: return t.contains("test_b"))
	_check(grow_lines.size() == 2 and not texts.any(func(t: String) -> bool: return t.contains(DreamState.NOT_IN_DREAM + " (")),
		"the panel shows 2 grow lines, no dead \"not in this dream\" buttons (%s)" % [texts])
	var more: Button = null
	for child in panel._buttons.get_children():
		if child is Button and child.text == "3 more not in this dream · Remember":
			more = child
	_check(more != null and more.tooltip_text.contains(hidden[0].display_name), "one quiet line points at Remember")
	var asked := [null]
	dreams.remember_requested.connect(func(focus: TowerData) -> void: asked[0] = focus)
	if more != null:
		more.pressed.emit()
	_check(asked[0] == hidden[0], "pressing it opens Remember on the first misty branch")

	var header := WardenHeaderView.build(base, tower, dreams)
	var lines: Array = header.growth.get_children().map(func(c: Node) -> String: return c.text if c is Label else "")
	_check(lines.has("3 more not in this dream") and lines.filter(func(t: String) -> bool: return t.contains("test_b")).size() == 2,
		"the hover card lists the 2 and counts the rest (%s)" % [lines])
	header.free()

	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
