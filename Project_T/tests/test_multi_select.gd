extends SceneTree

# Headless test for selecting several Wardens (screens_ui.md, "Selecting several Wardens"): box and
# same-kind selection, group grow (total cost, partial affordability, closest to the Heartwood first)
# and Sell all. Run from the project folder:
#   godot --headless --path . --script res://tests/test_multi_select.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var map_generator = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var run_state: RunState = main.get_node("%RunState")
	var dreams: DreamState = main.get_node("%DreamState")
	var drifts: DriftDirector = main.get_node("%DriftDirector")
	var panel: Node = main.find_child("WardenPanel", true, false)
	dreams.unlock_everything = true
	for child in main.get_node("%EnemyContainer").get_children():
		child.queue_free()
	await process_frame
	_check(drifts.is_build_phase(), "the test starts in the build phase (full refunds)")

	# Five Sprouts and a Thornwall beside the path.
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	var thornwall: TowerData = load("res://resource/tower/thornwall.tres")
	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	run_state.dew = 10000
	var sprouts: Array[Tower] = []
	for i in 5:
		sprouts.append(_build(placer, map_generator, sprout))
	var wall := _build(placer, map_generator, thornwall)
	_check(sprouts.all(func(t: Tower) -> bool: return t != null) and wall != null, "built 5 Sprouts and a Thornwall")

	# Box select: Thornwalls only when nothing else is in the box.
	var everything := Rect2(Vector2(-10000, -10000), Vector2(20000, 20000))
	var boxed := seller.get_towers_in_rect(everything)
	_check(boxed.size() == 5 and not boxed.has(wall), "a box over the maze picks the Wardens, not the hedges")
	var wall_box := Rect2(wall.position - Vector2(8, 8), Vector2(16, 16))
	_check(seller.get_towers_in_rect(wall_box) == [wall], "a box with only a Thornwall selects it")
	_check(seller.get_same_kind(sprout, true).size() == 5, "Ctrl + double-click: every Sprout on the map")

	# Group grow: total cost, and partial affordability grows the ones nearest the Heartwood first.
	seller.set_selection(sprouts)
	_check(seller.selected == sprouts[0] and seller.selection.size() == 5, "five selected")
	var groups := seller.get_selection_groups()
	_check(groups.size() == 1 and groups[0][0] == sprout and groups[0][1].size() == 5, "grouped by kind")
	var cost := dreams.get_evolve_cost(sporeling)
	run_state.dew = cost * 3 + cost / 2
	_check(seller.count_affordable(sprouts, sporeling) == 3, "can afford 3 of 5")
	run_state.dew_changed.emit(run_state.dew)  # Setting dew directly skips the signal the panel listens to
	await process_frame
	var grow_text := _button_texts(panel).filter(func(t: String) -> bool:
		return t.begins_with("Grow 3 of 5 Sprouts into Sporeling"))
	_check(grow_text.size() == 1 and ("%d Dew" % (cost * 3)) in grow_text[0],
		"the panel offers \"Grow 3 of 5 … · %d Dew\" (%s)" % [cost * 3, grow_text])
	var nearest: Array = seller.sort_by_heartwood(sprouts).slice(0, 3)
	var grown := seller.grow_group(sprouts, sporeling)
	_check(grown == 3 and run_state.dew == cost / 2, "grew 3 and spent %d Dew" % (cost * 3))
	_check(nearest.all(func(t: Tower) -> bool: return t.tower_data == sporeling), "the 3 nearest the Heartwood grew")
	_check(seller.get_selection_groups().size() == 2, "the selection now shows two kinds")

	run_state.dew = 10000
	var rest: Array = sprouts.filter(func(t: Tower) -> bool: return t.tower_data == sprout)
	_check(seller.grow_group(rest, sporeling) == 2 and sprouts.all(func(t: Tower) -> bool: return t.tower_data == sporeling),
		"with enough Dew, the whole group grows")
	await process_frame
	_check(panel._title.text == "5 Wardens selected", "the panel title counts the selection")

	# Sell all: normal refund rules (the resting share of everything invested, 75% since difficulty v1).
	var refund := seller.get_selection_refund()
	var expected := 0
	for tower in sprouts:
		expected += int(tower.invested_dew * seller.build_phase_refund)
	_check(refund == expected, "Sell all refunds the resting share of everything invested (%d)" % refund)
	var dew := run_state.dew
	_check(seller.sell_selection() == refund and run_state.dew == dew + refund, "Sell all pays the refund")
	await process_frame
	_check(sprouts.all(func(t) -> bool: return not is_instance_valid(t) or t.is_queued_for_deletion()),
		"every selected Warden is gone")
	_check(seller.selection.is_empty() and seller.get_tower_at(wall.cell) == wall, "the unselected Thornwall stays")

	print("multi-select test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

# Builds `data` on a free cell beside the path (keeping it open). Returns the new Warden or null.
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
				return container.get_child(count)
	return null

func _button_texts(panel: Node) -> Array:
	var texts := []
	for button in panel._buttons.get_children():
		if button is Button and not button.is_queued_for_deletion():
			texts.append(button.text)
	return texts
