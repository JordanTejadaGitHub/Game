extends SceneTree

# Headless test for the Warden panel's Dreamlight unlocks (run_design.md "Dreamlight"): a locked form
# reads "Grow into Driftspore · Unlock with 1 Dreamlight"; with enough Dreamlight the first click asks
# and the second unlocks it; without, the click opens the Remember screen on that form.
#   godot --headless --path . --script res://tests/test_dreamlight_panel.gd --fixed-fps 60

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
	var panel: Node = main.find_child("WardenPanel", true, false)
	var driftspore: TowerData = load("res://resource/tower/driftspore.tres")
	dreams.unlocked["sporeling"] = true
	dreams.unlocks_changed.emit()
	run_state.dew = 1000

	var tower := _build(placer, map_generator, load("res://resource/tower/sporeling.tres"))
	_check(tower != null, "planted a Sporeling")
	seller.select(tower)
	await process_frame
	_check(not dreams.is_unlocked("driftspore"), "Driftspore starts locked")

	# No Dreamlight: the button says what it costs, and opens the Remember screen.
	dreams.dreamlight = 0
	dreams.dreamlight_changed.emit(0)
	await process_frame
	var button := _button(panel, "Grow into Driftspore")
	_check(button != null and "Unlock with 1 Dreamlight" in button.text,
		"a locked form shows its Dreamlight cost (%s)" % (button.text if button else "none"))
	var asked := []
	dreams.remember_requested.connect(func(focus: TowerData) -> void: asked.append(focus))
	button.pressed.emit()
	_check(asked == [driftspore], "without enough Dreamlight it opens the Remember screen on that form")
	var remember := main.find_child("RememberScreen", true, false)
	if remember != null and remember.visible and remember.has_method("close"):
		remember.close()
	elif remember != null:
		remember.visible = false
	main.get_node("%GameSpeed").set_paused(false)

	# With Dreamlight: first click asks, second unlocks (Dew is untouched).
	dreams.dreamlight = 1
	dreams.dreamlight_changed.emit(1)
	await process_frame
	_button(panel, "Grow into Driftspore").pressed.emit()
	await process_frame
	var confirm := _button(panel, "Unlock Driftspore")
	_check(confirm != null and "confirm" in confirm.text.to_lower(), "the first click asks to confirm")
	_check(not dreams.is_unlocked("driftspore"), "nothing is spent yet")
	var dew := run_state.dew
	confirm.pressed.emit()
	await process_frame
	_check(dreams.is_unlocked("driftspore") and dreams.dreamlight == 0 and run_state.dew == dew,
		"the second click spends 1 Dreamlight (not Dew) and unlocks Driftspore")
	var grow := _button(panel, "Grow into Driftspore")
	_check(grow != null and "Dew" in grow.text, "then it offers growing for Dew as usual (%s)" % (grow.text if grow else "none"))

	print("dreamlight panel test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _button(panel: Node, starts_with: String) -> Button:
	for child in panel._buttons.get_children():
		if child is Button and not child.is_queued_for_deletion() and child.text.begins_with(starts_with):
			return child
	return null

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
